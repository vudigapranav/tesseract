"""Reminders, which must work for a patient who never opens a game."""

from __future__ import annotations

from datetime import datetime, timezone


def _definition(**overrides) -> dict:
    body = {
        "title": "Afternoon walk",
        "body": "A short walk after tea.",
        "schedule": {
            "kind": "daily",
            "times": ["16:00"],
            "weekdays": [],
            "timezone": "Asia/Kolkata",
        },
        "active": True,
    }
    body.update(overrides)
    return body


def _create(client, headers, patient_id, **overrides) -> dict:
    response = client.post(
        f"/v1/patients/{patient_id}/reminders", headers=headers, json=_definition(**overrides)
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_a_reminder_needs_no_session_or_gameplay(client, caregiver, patient_id):
    # This patient has never played anything. Reminders must still work.
    reminder = _create(client, caregiver, patient_id)
    assert reminder["schedule_version"] == 1
    assert reminder["active"] is True

    listed = client.get(f"/v1/patients/{patient_id}/reminders", headers=caregiver).json()
    assert len(listed) == 1


def test_editing_bumps_the_schedule_version(client, caregiver, patient_id):
    # An offline device compares this to know its cached schedule is stale.
    reminder = _create(client, caregiver, patient_id)
    updated = client.put(
        f"/v1/reminders/{reminder['reminder_id']}",
        headers=caregiver,
        json=_definition(title="Evening walk"),
    ).json()
    assert updated["schedule_version"] == 2
    assert updated["title"] == "Evening walk"


def test_deactivating_is_kept_distinct_from_deleting(client, caregiver, patient_id):
    reminder = _create(client, caregiver, patient_id)
    updated = client.put(
        f"/v1/reminders/{reminder['reminder_id']}",
        headers=caregiver,
        json=_definition(active=False),
    ).json()
    assert updated["active"] is False
    assert len(client.get(f"/v1/patients/{patient_id}/reminders", headers=caregiver).json()) == 1


def test_another_caregiver_cannot_read_or_edit(
    client, caregiver, other_caregiver, patient_id
):
    reminder = _create(client, caregiver, patient_id)
    assert (
        client.get(f"/v1/patients/{patient_id}/reminders", headers=other_caregiver).status_code
        == 403
    )
    assert (
        client.put(
            f"/v1/reminders/{reminder['reminder_id']}",
            headers=other_caregiver,
            json=_definition(),
        ).status_code
        == 403
    )


class TestOccurrences:
    def _occurrence(self, client, caregiver, reminder_id, when: str):
        return client.post(
            f"/v1/reminders/{reminder_id}/occurrences",
            headers=caregiver,
            json={"scheduled_for": when, "schedule_version": 1, "state": "prompted",
                  "device_id": "synthetic-device"},
        )

    def test_reporting_the_same_occurrence_twice_does_not_duplicate(
        self, client, caregiver, patient_id
    ):
        # A device that restarts and re-reports must not create a second row.
        reminder = _create(client, caregiver, patient_id)
        when = datetime.now(timezone.utc).isoformat()

        first = self._occurrence(client, caregiver, reminder["reminder_id"], when).json()
        self._occurrence(client, caregiver, reminder["reminder_id"], when)

        listed = client.get(
            f"/v1/patients/{patient_id}/reminders/occurrences", headers=caregiver
        ).json()
        assert len(listed) == 1
        assert listed[0]["occurrence_id"] == first["occurrence_id"]

    def test_acknowledgement_is_recorded_and_is_not_adherence(
        self, client, caregiver, patient_id
    ):
        reminder = _create(client, caregiver, patient_id)
        when = datetime.now(timezone.utc).isoformat()
        occurrence = self._occurrence(client, caregiver, reminder["reminder_id"], when).json()

        acknowledged = client.post(
            f"/v1/reminder-occurrences/{occurrence['occurrence_id']}/acknowledge",
            headers=caregiver,
            json={"acknowledgement_state": "acknowledged"},
        ).json()

        assert acknowledged["acknowledgement_state"] == "acknowledged"
        assert acknowledged["acknowledged_at"] is not None
        # The API has no concept of a dose or of whether anything was taken.
        assert "taken" not in acknowledged
        assert "adherence" not in acknowledged

    def test_postponed_and_cancelled_are_distinct_states(self, client, caregiver, patient_id):
        reminder = _create(client, caregiver, patient_id)
        for index, state in enumerate(("postponed", "cancelled")):
            when = datetime(2026, 9, 7, 10 + index, 0, tzinfo=timezone.utc).isoformat()
            occurrence = self._occurrence(client, caregiver, reminder["reminder_id"], when).json()
            result = client.post(
                f"/v1/reminder-occurrences/{occurrence['occurrence_id']}/acknowledge",
                headers=caregiver,
                json={"acknowledgement_state": state},
            ).json()
            assert result["acknowledgement_state"] == state

    def test_another_caregiver_cannot_acknowledge(
        self, client, caregiver, other_caregiver, patient_id
    ):
        reminder = _create(client, caregiver, patient_id)
        when = datetime.now(timezone.utc).isoformat()
        occurrence = self._occurrence(client, caregiver, reminder["reminder_id"], when).json()
        response = client.post(
            f"/v1/reminder-occurrences/{occurrence['occurrence_id']}/acknowledge",
            headers=other_caregiver,
            json={"acknowledgement_state": "acknowledged"},
        )
        assert response.status_code == 403
