"""Versioned metric calculators.

Pure functions over (session snapshot, stored events). No database, no HTTP, no
current-defaults lookup — a session stays interpretable after the presets change
because everything a calculator needs was frozen on the session row.

Two rules hold everywhere:

1. **Zero is not null.** No attempts means ``None``, never ``0.0``.
2. **Never fabricate.** A metric that cannot be computed from what the game
   actually exports goes in ``unavailable`` with a machine-readable reason and
   the exact fields it would need. It does not appear in ``values`` at all.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable, Protocol

METRIC_VERSION = "1"

# Two collision events against the same wall, closer together than this on the
# session clock, are one contact episode. A patient resting the marble against a
# wall must not read as hundreds of separate contacts.
# Prototype value, not tuned against real play.
CONTACT_DEBOUNCE_MS = 400


class EventLike(Protocol):
    seq: int
    type: str
    elapsed_ms: int
    payload: dict


class SessionLike(Protocol):
    game_id: str
    game_version: str
    level: int
    difficulty_params: dict
    is_tutorial: bool
    assisted: bool
    status: str
    metric_version: str


@dataclass
class MetricResult:
    calculator_id: str
    metric_version: str
    values: dict[str, Any] = field(default_factory=dict)
    unavailable: dict[str, Any] = field(default_factory=dict)

    def mark_unavailable(self, metric: str, reason: str, detail: str, needs: list[str]) -> None:
        self.unavailable[metric] = {"reason": reason, "detail": detail, "needs": needs}


def _count(events: list[EventLike], type_: str) -> int:
    return sum(1 for e in events if e.type == type_)


def _active_duration_ms(events: list[EventLike]) -> int:
    """The session clock at the last event.

    ``elapsed_ms`` already excludes paused and backgrounded time — the device
    guarantees it (TesseractEventRecorder), so there is nothing to subtract here.
    """
    return max((e.elapsed_ms for e in events), default=0)


def _common(session: SessionLike, events: list[EventLike]) -> dict[str, Any]:
    return {
        "events_total": len(events),
        "active_duration_ms": _active_duration_ms(events),
        "hints_used": _count(events, "hint_requested"),
        "pauses": _count(events, "paused"),
        "assisted": bool(session.assisted or _count(events, "hint_requested") > 0),
        "is_tutorial": bool(session.is_tutorial),
        "completion_status": session.status,
        "tutorial_completed": _count(events, "tutorial_completed") > 0,
    }


# ---------------------------------------------------------------------------
# Route Quest (G2)
# ---------------------------------------------------------------------------


def route_quest_v1(session: SessionLike, events: list[EventLike]) -> MetricResult:
    result = MetricResult("route_quest_v1", METRIC_VERSION, dict(_common(session, events)))

    moves = _count(events, "location_entered")
    destination_reached = _count(events, "destination_reached") > 0
    return_completed = _count(events, "return_completed") > 0
    requires_return = bool(session.difficulty_params.get("requiresReturn", True))

    result.values.update(
        {
            "moves_made": moves,
            "destination_reached": destination_reached,
            "item_collected": _count(events, "item_collected") > 0,
            "return_completed": return_completed,
            "route_completed": destination_reached and (return_completed or not requires_return),
            "wrong_interactions": _count(events, "wrong_interaction"),
            "unique_locations_visited": len(
                {
                    e.payload.get("nodeId")
                    for e in events
                    if e.type == "location_entered" and e.payload.get("nodeId") is not None
                }
            ),
        }
    )

    # Route efficiency = shortest valid route / actual route. The game computes
    # the BFS shortest path at level load (RouteGraph.shortestPathLength) but
    # does not export it: difficultyParams carries only nodeCount, branchCount
    # and requiresReturn. The server will not re-derive the topology to guess
    # it — that would duplicate game logic and drift the moment the map changes.
    result.mark_unavailable(
        "route_efficiency",
        "missing_game_export",
        "route_quest does not export the BFS shortest-path length for the level "
        "it generated, so actual/shortest cannot be computed without "
        "reimplementing the game's map on the server.",
        ["shortest_path_length"],
    )
    return result


# ---------------------------------------------------------------------------
# Marble Maze (G3)
# ---------------------------------------------------------------------------


def _contact_episodes(events: list[EventLike]) -> int:
    """Debounced wall contact.

    Consecutive collisions against the *same* wall within
    ``CONTACT_DEBOUNCE_MS`` are one episode — a continuous scrape is one
    contact, per the S28 acceptance criterion.
    """
    episodes = 0
    last_wall: object | None = None
    last_ms: int | None = None
    for event in sorted(events, key=lambda e: e.seq):
        if event.type != "collision":
            continue
        wall = event.payload.get("wallId")
        same_wall = wall is not None and wall == last_wall
        within_window = last_ms is not None and (event.elapsed_ms - last_ms) <= CONTACT_DEBOUNCE_MS
        if not (same_wall and within_window):
            episodes += 1
        last_wall = wall
        last_ms = event.elapsed_ms
    return episodes


def marble_maze_v1(session: SessionLike, events: list[EventLike]) -> MetricResult:
    result = MetricResult("marble_maze_v1", METRIC_VERSION, dict(_common(session, events)))

    result.values.update(
        {
            "goal_reached": _count(events, "goal_reached") > 0,
            "contact_episodes": _contact_episodes(events),
            "contact_events_raw": _count(events, "collision"),
            "contact_debounce_ms": CONTACT_DEBOUNCE_MS,
            "dead_ends_entered": len(
                {
                    e.payload.get("cellId")
                    for e in events
                    if e.type == "dead_end_entered" and e.payload.get("cellId") is not None
                }
            ),
            "input_mode": getattr(session, "actual_input_mode", None),
        }
    )

    # Path efficiency = shortest grid path / distance actually travelled. The
    # game emits collision, dead_end_entered and goal_reached only — neither
    # quantity is exported. Reporting 0, or inferring distance from collision
    # counts, would be inventing a number. It stays unavailable.
    result.mark_unavailable(
        "path_efficiency",
        "missing_game_export",
        "marble_maze does not export distance travelled or the shortest grid "
        "path length, so path efficiency cannot be computed from its events.",
        ["distance_travelled_units", "shortest_path_units"],
    )
    return result



# ---------------------------------------------------------------------------
# Reveal Match (G1)
# ---------------------------------------------------------------------------


def _median(values: list[int]) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    mid = len(ordered) // 2
    if len(ordered) % 2 == 1:
        return float(ordered[mid])
    return (ordered[mid - 1] + ordered[mid]) / 2


def reveal_match_v1(session: SessionLike, events: list[EventLike]) -> MetricResult:
    """Descriptive counts for the card-pair activity.

    Everything here is a plain count, a ratio of counts, or a time difference
    between two of the game's own events. Nothing is a clinical score, and
    nothing is named as though it were one.
    """
    result = MetricResult("reveal_match_v1", METRIC_VERSION, dict(_common(session, events)))

    ordered = sorted(events, key=lambda e: e.seq)
    resolutions = [e for e in ordered if e.type == "pair_resolved"]
    attempts = len(resolutions)
    matched = sum(1 for e in resolutions if e.payload.get("matched") is True)

    # Time from turning the first card of an attempt to turning the second.
    # Taken from the game's own clock, which already excludes paused time, and
    # only for attempts where both reveals are present.
    latencies: list[int] = []
    pending: int | None = None
    for event in ordered:
        if event.type == "card_revealed":
            if pending is None:
                pending = event.elapsed_ms
            else:
                latencies.append(event.elapsed_ms - pending)
                pending = None
        elif event.type == "pair_resolved" and pending is not None:
            # A reveal without its partner: drop it rather than pair it with
            # the next attempt's first card, which would invent a latency.
            pending = None

    result.values.update(
        {
            "cards_revealed": _count(events, "card_revealed"),
            "resolution_attempts": attempts,
            "pairs_matched": matched,
            "mismatches": attempts - matched,
            # None, not 0.0: no attempt is "not observed", not "all wrong".
            "pair_match_ratio": (matched / attempts) if attempts else None,
            "board_cleared": _count(events, "board_cleared") > 0,
            "median_second_card_latency_ms": _median(latencies),
            "second_card_latencies_counted": len(latencies),
        }
    )

    # The game does not export how many pairs the board held, so an attempt
    # count cannot be compared against a theoretical minimum. difficultyParams
    # does carry pairCount, but it is the caller's snapshot rather than
    # something the session proved, so it is reported as configuration only.
    pair_count = session.difficulty_params.get("pairCount")
    if isinstance(pair_count, int):
        result.values["configured_pair_count"] = pair_count
    else:
        result.mark_unavailable(
            "configured_pair_count",
            "missing_game_export",
            "The session snapshot does not carry pairCount, so the board size "
            "this session actually used is unknown.",
            ["difficulty_params.pairCount"],
        )
    return result


# ---------------------------------------------------------------------------
# Games without a calculator yet
# ---------------------------------------------------------------------------


def generic_v1(session: SessionLike, events: list[EventLike]) -> MetricResult:
    """Ingestion must work before a game's calculator exists.

    Common lifecycle metrics only, and an explicit note that game-specific
    metrics are absent because nobody has written them — not because the
    session was bad.
    """
    result = MetricResult("generic_v1", METRIC_VERSION, dict(_common(session, events)))
    result.mark_unavailable(
        "game_specific_metrics",
        "no_calculator",
        f"No versioned calculator is registered for game_id={session.game_id!r} "
        f"at metric_version={METRIC_VERSION}.",
        [f"calculator for {session.game_id}"],
    )
    return result


Calculator = Callable[[SessionLike, list[EventLike]], MetricResult]

REGISTRY: dict[tuple[str, str], Calculator] = {
    ("route_quest", METRIC_VERSION): route_quest_v1,
    ("marble_maze", METRIC_VERSION): marble_maze_v1,
    ("reveal_match", METRIC_VERSION): reveal_match_v1,
}


def calculate(session: SessionLike, events: list[EventLike]) -> MetricResult:
    calculator = REGISTRY.get((session.game_id, session.metric_version))
    if calculator is None:
        return generic_v1(session, events)
    return calculator(session, events)
