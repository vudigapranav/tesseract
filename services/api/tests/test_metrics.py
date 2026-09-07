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
