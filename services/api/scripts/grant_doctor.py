"""Provision a doctor and assign them a patient.

Deliberately a script and not an endpoint: nothing in the API can promote a
caller to the doctor role or grant itself access to a patient.

    .venv/bin/python scripts/grant_doctor.py <auth_uid> [patient_id ...]

In demo mode the auth_uid for a token "demo:doctor-a" is "demo-doctor-a".
"""

from __future__ import annotations

import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import select  # noqa: E402

from app.db import get_session_factory  # noqa: E402
from app.models import DoctorAssignment, Patient, User  # noqa: E402


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2

    auth_uid, patient_ids = argv[0], argv[1:]
    session = get_session_factory()()
    try:
        user = session.scalar(select(User).where(User.auth_uid == auth_uid))
        if user is None:
            user = User(auth_uid=auth_uid, role="doctor")
            session.add(user)
            session.flush()
            print(f"created doctor user {user.id} for auth_uid={auth_uid}")
        else:
            user.role = "doctor"
            print(f"promoted existing user {user.id} to doctor")

        for raw in patient_ids:
            patient_id = uuid.UUID(raw)
            if session.get(Patient, patient_id) is None:
                print(f"  skipped {patient_id}: no such patient")
                continue
            existing = session.scalar(
                select(DoctorAssignment).where(
                    DoctorAssignment.doctor_user_id == user.id,
                    DoctorAssignment.patient_id == patient_id,
                )
            )
            if existing is not None:
                existing.revoked_at = None
                print(f"  assignment to {patient_id} already present (revocation cleared)")
                continue
            session.add(DoctorAssignment(doctor_user_id=user.id, patient_id=patient_id))
            print(f"  assigned patient {patient_id}")

        session.commit()
    finally:
        session.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
