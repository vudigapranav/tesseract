"""The session loop: idempotency, duplicates, gaps and conflicting completion.

This is the behaviour the offline outbox depends on. A retry after a restart
must never change totals.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from tests.helpers import event, route_quest_events, session_body


def _complete_body(events: list[dict], status: str = "completed") -> dict:
    return {
        "status": status,
        "final_seq": max(e["seq"] for e in events),
        "assisted": False,
        "ended_at": datetime.now(timezone.utc).isoformat(),
    }


class TestSessionCreation:
    def test_first_put_creates_and_replay_is_idempotent(self, client, caregiver, patient_id):
        session_id = str(uuid.uuid4())
        body = session_body(patient_id)

        first = client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=body)
        assert first.status_code == 201
        assert first.json()["created"] is True

        replay = client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=body)
        assert replay.status_code == 200
        assert replay.json()["created"] is False
        assert replay.json()["session_id"] == session_id

    def test_changing_an_immutable_field_conflicts(self, client, caregiver, patient_id):
        session_id = str(uuid.uuid4())
        client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=session_body(patient_id))

        changed = client.put(
            f"/v1/sessions/{session_id}",
            headers=caregiver,
            json=session_body(patient_id, level=3),
        )
        assert changed.status_code == 409
        error = changed.json()["error"]
        assert error["code"] == "session_conflict"
        assert "level" in error["details"]["conflicting_fields"]

    def test_actual_input_mode_stays_mutable(self, client, caregiver, patient_id):
        # The device may only discover there is no gyroscope after creating the
        # session, so this one field can still be corrected.
        session_id = str(uuid.uuid4())
        client.put(
            f"/v1/sessions/{session_id}",
            headers=caregiver,
            json=session_body(
                patient_id, game_id="marble_maze", requested_input_mode="tilt",
                actual_input_mode="tilt",
            ),
        )
        corrected = client.put(
            f"/v1/sessions/{session_id}",
            headers=caregiver,
            json=session_body(
                patient_id, game_id="marble_maze", requested_input_mode="tilt",
                actual_input_mode="touch",
            ),
        )
        assert corrected.status_code == 200
        assert corrected.json()["actual_input_mode"] == "touch"

    def test_omitting_actual_input_mode_flags_the_session(self, client, caregiver, patient_id):
        session_id = str(uuid.uuid4())
        body = session_body(patient_id, requested_input_mode="tilt")
        body.pop("actual_input_mode")
        response = client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=body)
        assert response.json()["input_mode_unverified"] is True
        assert response.json()["actual_input_mode"] == "tilt"


class TestEventIngestion:
    def _open_session(self, client, caregiver, patient_id) -> str:
        session_id = str(uuid.uuid4())
        client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=session_body(patient_id))
        return session_id

    def test_events_for_an_unknown_session_are_rejected(self, client, caregiver):
        response = client.post(
            f"/v1/sessions/{uuid.uuid4()}/events:batch",
            headers=caregiver,
            json={"events": [event(1, "session_started", 0)]},
        )
        assert response.status_code == 404

    def test_resending_the_same_batch_marks_duplicates_not_errors(
        self, client, caregiver, patient_id
    ):
        session_id = self._open_session(client, caregiver, patient_id)
        events = route_quest_events()

        first = client.post(
            f"/v1/sessions/{session_id}/events:batch", headers=caregiver, json={"events": events}
        ).json()
        assert len(first["accepted"]) == len(events)
        assert first["duplicate"] == []

        second = client.post(
            f"/v1/sessions/{session_id}/events:batch", headers=caregiver, json={"events": events}
        ).json()
        assert second["accepted"] == []
        assert len(second["duplicate"]) == len(events)
        assert second["rejected"] == []

        # The whole point: totals are unchanged after the replay.
        assert client.get(f"/v1/sessions/{session_id}", headers=caregiver).json()[
            "events_received"
        ] == len(events)

    def test_same_event_id_with_different_content_is_rejected_loudly(
        self, client, caregiver, patient_id
    ):
        session_id = self._open_session(client, caregiver, patient_id)
        original = event(1, "session_started", 0)
        client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [original]},
        )

        tampered = {**original, "type": "goal_reached", "elapsed_ms": 999}
        response = client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [tampered]},
        ).json()
        assert response["accepted"] == []
        assert response["rejected"][0]["reason"] == "event_id_conflict"

    def test_two_different_events_claiming_one_seq_conflict(
        self, client, caregiver, patient_id
    ):
        session_id = self._open_session(client, caregiver, patient_id)
        client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [event(1, "session_started", 0)]},
        )
        response = client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [event(1, "hint_requested", 10)]},
        ).json()
        assert response["rejected"][0]["reason"] == "seq_conflict"

    def test_a_duplicate_seq_inside_one_batch_is_rejected(self, client, caregiver, patient_id):
        session_id = self._open_session(client, caregiver, patient_id)
        response = client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [event(1, "session_started", 0), event(1, "hint_requested", 5)]},
        ).json()
        assert len(response["accepted"]) == 1
        assert response["rejected"][0]["reason"] == "seq_conflict"

    def test_a_gap_is_reported_before_completion(self, client, caregiver, patient_id):
        session_id = self._open_session(client, caregiver, patient_id)
        response = client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [event(1, "session_started", 0), event(3, "hint_requested", 20)]},
        ).json()
        assert response["missing_seqs"] == [2]
        assert response["highest_seq"] == 3

    def test_one_bad_event_does_not_discard_the_good_ones(self, client, caregiver, patient_id):
        session_id = self._open_session(client, caregiver, patient_id)
        good = event(1, "session_started", 0)
        client.post(
            f"/v1/sessions/{session_id}/events:batch", headers=caregiver, json={"events": [good]}
        )
        mixed = client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [{**good, "type": "changed"}, event(2, "hint_requested", 10)]},
        ).json()
        assert len(mixed["accepted"]) == 1
        assert len(mixed["rejected"]) == 1


class TestCompletion:
    def _session_with(self, client, caregiver, patient_id, events) -> str:
        session_id = str(uuid.uuid4())
        client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=session_body(patient_id))
        client.post(
            f"/v1/sessions/{session_id}/events:batch", headers=caregiver, json={"events": events}
        )
        return session_id

    def test_missing_events_block_completion(self, client, caregiver, patient_id):
        events = [event(1, "session_started", 0), event(3, "session_finished", 500)]
        session_id = self._session_with(client, caregiver, patient_id, events)

        response = client.post(
            f"/v1/sessions/{session_id}/complete",
            headers=caregiver,
            json={"status": "completed", "final_seq": 3, "assisted": False},
        )
        assert response.status_code == 422
        error = response.json()["error"]
        assert error["code"] == "sequence_gap"
        assert error["details"]["missing_seqs"] == [2]

        # The session stays open so the client can upload what is missing.
        stored = client.get(f"/v1/sessions/{session_id}", headers=caregiver).json()
        assert stored["status"] == "open"

    def test_uploading_the_gap_then_completing_succeeds(self, client, caregiver, patient_id):
        events = [event(1, "session_started", 0), event(3, "session_finished", 500)]
        session_id = self._session_with(client, caregiver, patient_id, events)
        client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [event(2, "location_entered", 200, {"nodeId": "n1"})]},
        )
        response = client.post(
            f"/v1/sessions/{session_id}/complete",
            headers=caregiver,
            json={"status": "completed", "final_seq": 3, "assisted": False},
        )
        assert response.status_code == 200
        assert response.json()["status"] == "completed"

    def test_final_seq_must_match_the_highest_stored_seq(self, client, caregiver, patient_id):
        events = route_quest_events()
        session_id = self._session_with(client, caregiver, patient_id, events)
        response = client.post(
            f"/v1/sessions/{session_id}/complete",
            headers=caregiver,
            json={"status": "completed", "final_seq": 2, "assisted": False},
        )
        assert response.status_code == 422
        assert response.json()["error"]["code"] == "invalid_data"

    def test_repeating_the_same_completion_is_idempotent(self, client, caregiver, patient_id):
        events = route_quest_events()
        session_id = self._session_with(client, caregiver, patient_id, events)

        first = client.post(
            f"/v1/sessions/{session_id}/complete", headers=caregiver, json=_complete_body(events)
        )
        assert first.status_code == 200
        assert first.json()["created"] is True

        second = client.post(
            f"/v1/sessions/{session_id}/complete", headers=caregiver, json=_complete_body(events)
        )
        assert second.status_code == 200
        assert second.json()["created"] is False

    def test_conflicting_completion_is_refused(self, client, caregiver, patient_id):
        events = route_quest_events()
        session_id = self._session_with(client, caregiver, patient_id, events)
        client.post(
            f"/v1/sessions/{session_id}/complete", headers=caregiver, json=_complete_body(events)
        )

        conflicting = client.post(
            f"/v1/sessions/{session_id}/complete",
            headers=caregiver,
            json=_complete_body(events, status="interrupted"),
        )
        assert conflicting.status_code == 409
        assert conflicting.json()["error"]["code"] == "completion_conflict"

    def test_a_completed_session_takes_no_new_events_but_still_absorbs_retries(
        self, client, caregiver, patient_id
    ):
        events = route_quest_events()
        session_id = self._session_with(client, caregiver, patient_id, events)
        client.post(
            f"/v1/sessions/{session_id}/complete", headers=caregiver, json=_complete_body(events)
        )

        # A retry of a batch that was already delivered must stay safe...
        retry = client.post(
            f"/v1/sessions/{session_id}/events:batch", headers=caregiver, json={"events": events}
        ).json()
        assert len(retry["duplicate"]) == len(events)
        assert retry["rejected"] == []

        # ...but a genuinely new event after finalisation is refused.
        late = client.post(
            f"/v1/sessions/{session_id}/events:batch",
            headers=caregiver,
            json={"events": [event(len(events) + 5, "hint_requested", 99999)]},
        ).json()
        assert late["rejected"][0]["reason"] == "after_final_seq"

    def test_a_session_with_no_events_cannot_be_completed(self, client, caregiver, patient_id):
        session_id = str(uuid.uuid4())
        client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=session_body(patient_id))
        response = client.post(
            f"/v1/sessions/{session_id}/complete",
            headers=caregiver,
            json={"status": "completed", "final_seq": 0, "assisted": False},
        )
        assert response.status_code == 422

    def test_an_invalid_status_is_refused(self, client, caregiver, patient_id):
        events = route_quest_events()
        session_id = self._session_with(client, caregiver, patient_id, events)
        response = client.post(
            f"/v1/sessions/{session_id}/complete",
            headers=caregiver,
            json={"status": "finished", "final_seq": max(e["seq"] for e in events)},
        )
        assert response.status_code == 422

    def test_an_interrupted_session_is_stored_and_visible(self, client, caregiver, patient_id):
        events = route_quest_events(completed=False)
        session_id = self._session_with(client, caregiver, patient_id, events)
        response = client.post(
            f"/v1/sessions/{session_id}/complete",
            headers=caregiver,
            json=_complete_body(events, status="interrupted"),
        )
        assert response.status_code == 200
        history = client.get(f"/v1/patients/{patient_id}/sessions", headers=caregiver).json()
        assert history["items"][0]["status"] == "interrupted"


def test_restart_replay_produces_exactly_one_session(client, caregiver, patient_id):
    """Airplane mode -> restart -> reconnect twice must yield one session."""
    session_id = str(uuid.uuid4())
    body = session_body(patient_id)
    events = route_quest_events()

    for _ in range(3):  # the device retries the whole sequence three times
        client.put(f"/v1/sessions/{session_id}", headers=caregiver, json=body)
        client.post(
            f"/v1/sessions/{session_id}/events:batch", headers=caregiver, json={"events": events}
        )
        client.post(
            f"/v1/sessions/{session_id}/complete", headers=caregiver, json=_complete_body(events)
        )

    history = client.get(f"/v1/patients/{patient_id}/sessions", headers=caregiver).json()
    assert len(history["items"]) == 1
    assert history["items"][0]["final_seq"] == max(e["seq"] for e in events)
    assert (
        client.get(f"/v1/sessions/{session_id}", headers=caregiver).json()["events_received"]
        == len(events)
    )
