"""Metric calculator fixtures.

Hand-checked expectations against synthetic sessions. The point of these is
that a number is either right or explicitly absent — never quietly zero.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from app.analytics.calculators import (
    CONTACT_DEBOUNCE_MS,
    calculate,
    marble_maze_v1,
    reveal_match_v1,
    route_quest_v1,
)
from tests.helpers import marble_maze_events, play_full_session, route_quest_events


@dataclass
class FakeEvent:
    seq: int
    type: str
    elapsed_ms: int
    payload: dict = field(default_factory=dict)


@dataclass
class FakeSession:
    game_id: str = "route_quest"
    game_version: str = "1.0.0"
    level: int = 1
    difficulty_params: dict = field(default_factory=lambda: {"requiresReturn": True})
    is_tutorial: bool = False
    assisted: bool = False
    status: str = "completed"
    metric_version: str = "1"
    actual_input_mode: str = "touch"


def _events(raw: list[dict[str, Any]]) -> list[FakeEvent]:
    return [
        FakeEvent(e["seq"], e["type"], e["elapsed_ms"], e.get("payload", {})) for e in raw
    ]


class TestRouteQuest:
    def test_a_completed_round_trip(self):
        result = route_quest_v1(FakeSession(), _events(route_quest_events()))
        assert result.values["route_completed"] is True
        assert result.values["destination_reached"] is True
        assert result.values["return_completed"] is True
        assert result.values["moves_made"] == 6
        assert result.values["unique_locations_visited"] == 4  # n1,n2,n3,n0
        assert result.values["wrong_interactions"] == 0
        assert result.values["hints_used"] == 0

    def test_an_unfinished_route_is_not_completed(self):
        result = route_quest_v1(
            FakeSession(status="stopped_by_user"),
            _events(route_quest_events(completed=False)),
        )
        assert result.values["route_completed"] is False
        assert result.values["destination_reached"] is False

    def test_help_marks_the_session_assisted(self):
        result = route_quest_v1(FakeSession(), _events(route_quest_events(hints=2)))
        assert result.values["hints_used"] == 2
        assert result.values["assisted"] is True

    def test_wrong_interactions_are_counted(self):
        result = route_quest_v1(FakeSession(), _events(route_quest_events(wrong=3)))
        assert result.values["wrong_interactions"] == 3

    def test_route_efficiency_is_unavailable_with_a_reason(self):
        # The game computes a BFS shortest path but does not export it, so the
        # server cannot compute efficiency without reimplementing the map.
        # Reporting 0, or omitting it silently, would both be wrong.
        result = route_quest_v1(FakeSession(), _events(route_quest_events()))
        assert "route_efficiency" not in result.values
        entry = result.unavailable["route_efficiency"]
        assert entry["reason"] == "missing_game_export"
        assert entry["needs"] == ["shortest_path_length"]


class TestMarbleMaze:
    def test_a_continuous_scrape_counts_as_one_contact(self):
        # Three collisions against w1 within the debounce window, then one
        # against w2 well after it: two episodes, not four.
        result = marble_maze_v1(FakeSession(game_id="marble_maze"), _events(marble_maze_events()))
        assert result.values["contact_events_raw"] == 4
        assert result.values["contact_episodes"] == 2
        assert result.values["contact_debounce_ms"] == CONTACT_DEBOUNCE_MS

    def test_the_same_dead_end_is_counted_once(self):
        result = marble_maze_v1(FakeSession(game_id="marble_maze"), _events(marble_maze_events()))
        assert result.values["dead_ends_entered"] == 1

    def test_goal_reached_is_recorded(self):
        result = marble_maze_v1(FakeSession(game_id="marble_maze"), _events(marble_maze_events()))
        assert result.values["goal_reached"] is True

    def test_path_efficiency_is_unavailable_not_fabricated(self):
        result = marble_maze_v1(FakeSession(game_id="marble_maze"), _events(marble_maze_events()))
        assert "path_efficiency" not in result.values
        entry = result.unavailable["path_efficiency"]
        assert entry["reason"] == "missing_game_export"
        assert set(entry["needs"]) == {"distance_travelled_units", "shortest_path_units"}


class TestCommonRules:
    def test_active_duration_comes_from_the_session_clock(self):
        events = _events(route_quest_events())
        result = route_quest_v1(FakeSession(), events)
        assert result.values["active_duration_ms"] == max(e.elapsed_ms for e in events)

    def test_a_session_with_only_a_start_event_has_no_invented_numbers(self):
        result = route_quest_v1(FakeSession(), [FakeEvent(1, "session_started", 0)])
        assert result.values["moves_made"] == 0
        assert result.values["route_completed"] is False
        assert result.values["active_duration_ms"] == 0

    def test_an_unregistered_game_still_gets_common_metrics(self):
        result = calculate(FakeSession(game_id="word_search"), _events(route_quest_events()))
        assert result.calculator_id == "generic_v1"
        assert result.values["events_total"] > 0
        assert result.unavailable["game_specific_metrics"]["reason"] == "no_calculator"


class TestMetricsThroughTheApi:
    def test_metrics_are_stored_on_completion(self, client, caregiver, patient_id):
        session_id = play_full_session(client, caregiver, patient_id)
        response = client.get(f"/v1/sessions/{session_id}/metrics", headers=caregiver)
        assert response.status_code == 200
        body = response.json()
        assert body["calculator_id"] == "route_quest_v1"
        assert body["available"]["route_completed"] is True
        assert "route_efficiency" in body["unavailable"]

    def test_marble_maze_reports_unavailable_through_the_api(
        self, client, caregiver, patient_id
    ):
        session_id = play_full_session(
            client,
            caregiver,
            patient_id,
            events=marble_maze_events(),
            game_id="marble_maze",
            requested_input_mode="tilt",
            actual_input_mode="tilt",
            difficulty_params={"corridorWidth": 3, "turnCount": 4, "deadEndCount": 2},
        )
        body = client.get(f"/v1/sessions/{session_id}/metrics", headers=caregiver).json()
        assert body["available"]["contact_episodes"] == 2
        assert body["unavailable"]["path_efficiency"]["reason"] == "missing_game_export"


class TestRevealMatch:
    """Reveal Match (G1) — descriptive counts only."""

    @staticmethod
    def _session(**over):
        return FakeSession(
            game_id="reveal_match",
            difficulty_params={"pairCount": 2, "resolutionMs": 1600},
            **over,
        )

    @staticmethod
    def _attempt(seq: int, at: int, gap: int, matched: bool, ids: tuple[str, str]):
        """One attempt: two reveals `gap` ms apart, then its resolution."""
        return [
            FakeEvent(seq, "card_revealed", at, {"cardId": ids[0]}),
            FakeEvent(seq + 1, "card_revealed", at + gap, {"cardId": ids[1]}),
            FakeEvent(
                seq + 2,
                "pair_resolved",
                at + gap,
                {"attemptId": f"attempt-{seq}", "matched": matched, "cardIds": list(ids)},
            ),
        ]

    def test_a_cleared_board(self):
        events = [FakeEvent(1, "session_started", 0)]
        events += self._attempt(2, 500, 400, False, ("card-0-0", "card-1-0"))
        events += self._attempt(5, 3000, 600, True, ("card-0-0", "card-0-1"))
        events += self._attempt(8, 6000, 200, True, ("card-1-0", "card-1-1"))
        events.append(FakeEvent(11, "board_cleared", 6300))

        result = reveal_match_v1(self._session(), events)
        assert result.values["cards_revealed"] == 6
        assert result.values["resolution_attempts"] == 3
        assert result.values["pairs_matched"] == 2
        assert result.values["mismatches"] == 1
        assert result.values["pair_match_ratio"] == 2 / 3
        assert result.values["board_cleared"] is True
        # Latencies 400, 600, 200 -> median 400.
        assert result.values["median_second_card_latency_ms"] == 400
        assert result.values["second_card_latencies_counted"] == 3
        assert result.values["configured_pair_count"] == 2

    def test_no_attempts_reports_none_not_zero(self):
        result = reveal_match_v1(
            self._session(status="stopped_by_user"),
            [FakeEvent(1, "session_started", 0), FakeEvent(2, "session_finished", 900)],
        )
        assert result.values["resolution_attempts"] == 0
        # The distinction the whole module rests on: nothing observed is not
        # the same as everything wrong.
        assert result.values["pair_match_ratio"] is None
        assert result.values["median_second_card_latency_ms"] is None
        assert result.values["board_cleared"] is False

    def test_an_even_number_of_latencies_is_averaged_at_the_middle(self):
        events = self._attempt(1, 0, 100, False, ("card-0-0", "card-1-0"))
        events += self._attempt(4, 2000, 300, False, ("card-0-1", "card-1-1"))
        result = reveal_match_v1(self._session(), events)
        assert result.values["median_second_card_latency_ms"] == 200

    def test_an_unpaired_reveal_does_not_invent_a_latency(self):
        # A first card turned over, then the session ends. That reveal must not
        # be paired with anything.
        events = self._attempt(1, 0, 250, True, ("card-0-0", "card-0-1"))
        events.append(FakeEvent(4, "card_revealed", 5000, {"cardId": "card-1-0"}))
        events.append(FakeEvent(5, "session_finished", 5200))
        result = reveal_match_v1(self._session(status="stopped_by_user"), events)
        assert result.values["cards_revealed"] == 3
        assert result.values["second_card_latencies_counted"] == 1
        assert result.values["median_second_card_latency_ms"] == 250

    def test_board_size_is_unavailable_when_the_snapshot_lacks_it(self):
        result = reveal_match_v1(
            FakeSession(game_id="reveal_match", difficulty_params={}),
            [FakeEvent(1, "session_started", 0)],
        )
        assert "configured_pair_count" not in result.values
        assert result.unavailable["configured_pair_count"]["reason"] == "missing_game_export"

    def test_the_registry_routes_reveal_match_to_its_own_calculator(self):
        result = calculate(self._session(), [FakeEvent(1, "session_started", 0)])
        assert result.calculator_id == "reveal_match_v1"
