"""Doctor access boundaries.

Assignment is the only path in — including for a direct session, report or
media id, which is where this kind of thing actually leaks.
"""

from __future__ import annotations

from sqlalchemy import select

from app.models import DoctorAssignment, User
from tests.conftest import auth
from tests.helpers import play_full_session


def _make_doctor(db, uid: str) -> User:
    """Provisioning is server-side only; no endpoint does this."""
    user = db.scalar(select(User).where(User.auth_uid == uid))
    if user is None:
        user = User(auth_uid=uid, role="doctor", display_name="Synthetic Doctor")
        db.add(user)
    else:
        user.role = "doctor"
    db.commit()
    return user


def _assign(db, doctor: User, patient_id: str) -> DoctorAssignment:
    assignment = DoctorAssignment(doctor_user_id=doctor.id, patient_id=patient_id)
    db.add(assignment)
    db.commit()
    return assignment


def test_an_unassigned_doctor_sees_nothing(client, db, patient_id):
    _make_doctor(db, "demo-doctor-a")
    listed = client.get("/v1/doctor/patients", headers=auth("doctor-a")).json()
    assert listed["items"] == []


def test_an_assigned_doctor_sees_the_patient(client, db, patient_id):
    doctor = _make_doctor(db, "demo-doctor-a")
    _assign(db, doctor, patient_id)
    listed = client.get("/v1/doctor/patients", headers=auth("doctor-a")).json()
    assert [item["patient_id"] for item in listed["items"]] == [patient_id]


def test_multiple_assigned_patients_are_supported(client, db, caregiver):
    doctor = _make_doctor(db, "demo-doctor-a")
    ids = []
    for name in ("Synthetic One", "Synthetic Two"):
        created = client.post("/v1/patients", headers=caregiver, json={"display_name": name})
        ids.append(created.json()["patient_id"])
        _assign(db, doctor, ids[-1])
    listed = client.get("/v1/doctor/patients", headers=auth("doctor-a")).json()
    assert len(listed["items"]) == 2


def test_an_unassigned_doctor_cannot_read_a_summary_by_direct_id(client, db, patient_id):
    _make_doctor(db, "demo-doctor-a")
    response = client.get(
        f"/v1/doctor/patients/{patient_id}/summary", headers=auth("doctor-a")
    )
    assert response.status_code == 403


def test_an_unassigned_doctor_cannot_read_a_session_by_direct_id(
    client, db, caregiver, patient_id
):
    session_id = play_full_session(client, caregiver, patient_id)
    _make_doctor(db, "demo-doctor-a")
    response = client.get(f"/v1/sessions/{session_id}", headers=auth("doctor-a"))
    assert response.status_code == 403


def test_a_revoked_assignment_removes_access(client, db, patient_id):
    from datetime import datetime, timezone

    doctor = _make_doctor(db, "demo-doctor-a")
    assignment = _assign(db, doctor, patient_id)
    assert client.get("/v1/doctor/patients", headers=auth("doctor-a")).json()["items"]

    assignment.revoked_at = datetime.now(timezone.utc)
    db.commit()

    assert client.get("/v1/doctor/patients", headers=auth("doctor-a")).json()["items"] == []
    assert (
        client.get(
            f"/v1/doctor/patients/{patient_id}/summary", headers=auth("doctor-a")
        ).status_code
        == 403
    )


def test_a_doctor_cannot_record_gameplay_for_a_patient(client, db, patient_id):
    import uuid

    from tests.helpers import session_body

    doctor = _make_doctor(db, "demo-doctor-a")
    _assign(db, doctor, patient_id)
    response = client.put(
        f"/v1/sessions/{uuid.uuid4()}",
        headers=auth("doctor-a"),
        json=session_body(patient_id),
    )
    assert response.status_code == 403


class TestNotes:
    def test_a_note_is_attributed_to_its_author(self, client, db, caregiver, patient_id):
        doctor = _make_doctor(db, "demo-doctor-a")
        _assign(db, doctor, patient_id)

        created = client.post(
            f"/v1/patients/{patient_id}/notes",
            headers=auth("doctor-a"),
            json={"body": "Discussed the activity routine with the family."},
        )
        assert created.status_code == 201
        assert created.json()["author_user_id"] == str(doctor.id)

    def test_an_unassigned_doctor_cannot_write_a_note(self, client, db, patient_id):
        _make_doctor(db, "demo-doctor-a")
        response = client.post(
            f"/v1/patients/{patient_id}/notes",
            headers=auth("doctor-a"),
            json={"body": "Should not be possible."},
        )
        assert response.status_code == 403


class TestReports:
    def test_a_report_cites_its_sources_and_states_its_limits(
        self, client, caregiver, patient_id
    ):
        play_full_session(client, caregiver, patient_id)
        created = client.post(
            f"/v1/patients/{patient_id}/reports", headers=caregiver, json={"window_days": 30}
        )
        assert created.status_code == 201
        report = created.json()

        assert report["generator"] == "template"
        assert len(report["source_session_ids"]) == 1
        assert report["content"]["review_state"] == "unreviewed_draft"
        limitations = " ".join(report["content"]["limitations"]).lower()
        assert "not a diagnosis" in limitations
        assert "prototype" in limitations

    def test_report_numbers_reconcile_to_the_stored_summary(
        self, client, caregiver, patient_id
    ):
        play_full_session(client, caregiver, patient_id)
        report = client.post(
            f"/v1/patients/{patient_id}/reports", headers=caregiver, json={"window_days": 30}
        ).json()
        summary = report["content"]["summary"]
        assert summary["games"][0]["sessions_total"] == 1

    def test_another_caregiver_cannot_read_the_report(
        self, client, caregiver, other_caregiver, patient_id
    ):
        play_full_session(client, caregiver, patient_id)
        report = client.post(
            f"/v1/patients/{patient_id}/reports", headers=caregiver, json={"window_days": 30}
        ).json()
        response = client.get(f"/v1/reports/{report['report_id']}", headers=other_caregiver)
        assert response.status_code == 403
