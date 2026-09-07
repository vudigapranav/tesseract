"""What an external model is allowed to see.

An allow-list, not a deny-list. Only the named computed fields are copied into
the payload; anything not listed cannot leak by being added to a model later.

Never included, by construction:
  * patient or caregiver names, or any free-text label
  * personal words and Know Me content
  * media, or any reference to media
  * raw clinical fields (known_type, known_stage)
  * identity tokens or credentials

Patient and session identifiers are replaced with per-report opaque labels, so
the payload cannot be joined back to a person by whoever receives it.
"""

from __future__ import annotations

from typing import Any

# The only metric names that may be sent. Extending this list is a deliberate
# act with a review attached; forgetting to extend it merely omits a number.
ALLOWED_METRIC_FIELDS = frozenset(
    {
        "active_duration_ms",
        "hints_used",
        "pauses",
        "assisted",
        "is_tutorial",
        "completion_status",
        "events_total",
        "moves_made",
        "destination_reached",
        "item_collected",
        "return_completed",
        "route_completed",
        "wrong_interactions",
        "unique_locations_visited",
        "goal_reached",
        "contact_episodes",
        "dead_ends_entered",
    }
)

# Matched against underscore-separated segments of a key, not as raw
# substrings: "median" must not trip the "media" rule.
FORBIDDEN_KEY_SEGMENTS = frozenset(
    {
        "name",
        "names",
        "word",
        "words",
        "label",
        "labels",
        "photo",
        "photos",
        "image",
        "images",
        "media",
        "known",
        "email",
        "phone",
        "address",
        "token",
    }
)


def build_facts(summary: dict[str, Any]) -> dict[str, Any]:
    """Reduce a patient summary to de-identified, computed facts."""
    games: list[dict[str, Any]] = []
    for index, game in enumerate(summary.get("games", []), start=1):
        sessions = []
        for order, session in enumerate(game.get("recent_sessions", []), start=1):
            metrics = session.get("metrics") or {}
            sessions.append(
                {
                    "session_ref": f"session_{index}_{order}",
                    "level": session.get("level"),
                    "status": session.get("status"),
                    "assisted": session.get("assisted"),
                    "is_tutorial": session.get("is_tutorial"),
                    "input_mode": session.get("actual_input_mode"),
                    "metrics": {
                        k: v for k, v in metrics.items() if k in ALLOWED_METRIC_FIELDS
                    },
                    "unavailable_metrics": sorted(
                        (session.get("unavailable_metrics") or {}).keys()
                    ),
                }
            )
        baseline = game.get("baseline", {})
        games.append(
            {
                "game_id": game.get("game_id"),
                "sessions_total": game.get("sessions_total"),
                "sessions_comparable": game.get("sessions_comparable"),
                "baseline_state": baseline.get("state"),
                "baseline_values": baseline.get("values", {}),
                "excluded": game.get("excluded", {}),
                "sessions": sessions,
            }
        )

    return {
        "subject_ref": "the person using the app",
        "window_note": summary.get("note"),
        "games": games,
    }


def assert_deidentified(facts: dict[str, Any]) -> None:
    """Belt and braces: refuse to send anything that smells identifying.

    The allow-list above already prevents this; this raises loudly if a future
    change gets around it.
    """
    def walk(node: Any, path: str) -> None:
        if isinstance(node, dict):
            for key, value in node.items():
                segments = set(str(key).lower().replace("-", "_").split("_"))
                if segments & FORBIDDEN_KEY_SEGMENTS:
                    raise ValueError(
                        f"Refusing to build an LLM payload containing {path}.{key!r}."
                    )
                walk(value, f"{path}.{key}")
        elif isinstance(node, list):
            for i, value in enumerate(node):
                walk(value, f"{path}[{i}]")

    walk(facts.get("games", []), "games")
