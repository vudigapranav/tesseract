"""Access control, in one place.

Every patient-scoped route depends on :func:`require_patient_access` (or the
doctor variant). Routes do not re-implement the check, so a new route cannot
quietly omit it.
"""

from __future__ import annotations

import uuid

from fastapi import Depends, Request
from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..config import Settings, get_settings
from ..db import get_db
from ..errors import identity_required, no_patient_access
from ..models import CaregiverPatient, DoctorAssignment, Patient, User
from .identity import IdentityVerifier, VerifiedIdentity


def get_verifier(request: Request) -> IdentityVerifier:
    verifier = getattr(request.app.state, "identity_verifier", None)
    if verifier is None:  # pragma: no cover - app always sets this at startup
        raise RuntimeError("Identity verifier was not configured.")
    return verifier


def _bearer_token(request: Request) -> str:
    header = request.headers.get("Authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise identity_required("Authorization header must be 'Bearer <token>'.")
    return token.strip()


def current_identity(
    request: Request, verifier: IdentityVerifier = Depends(get_verifier)
) -> VerifiedIdentity:
    return verifier.verify(_bearer_token(request))


def current_user(
    identity: VerifiedIdentity = Depends(current_identity),
    db: DbSession = Depends(get_db),
) -> User:
    """The authenticated user, created on first sight of a verified uid.

    Role is always ``caregiver`` on creation. Nothing in the API promotes a
    caller to ``doctor``; that is a server-side provisioning step.
    """
    user = db.scalar(select(User).where(User.auth_uid == identity.auth_uid))
    if user is None:
        user = User(
            auth_uid=identity.auth_uid,
            role="caregiver",
            display_name=identity.display_name,
        )
        db.add(user)
        db.flush()
    return user


def require_doctor(user: User = Depends(current_user)) -> User:
    if user.role != "doctor":
        raise no_patient_access()
    return user


def _load_patient(db: DbSession, patient_id: uuid.UUID) -> Patient:
    patient = db.get(Patient, patient_id)
    if patient is None:
        # Same error as "exists but not yours" — see errors.no_patient_access.
        raise no_patient_access()
    return patient


def caregiver_has_access(db: DbSession, user: User, patient_id: uuid.UUID) -> bool:
    return (
        db.scalar(
            select(CaregiverPatient.user_id).where(
                CaregiverPatient.user_id == user.id,
                CaregiverPatient.patient_id == patient_id,
            )
        )
        is not None
    )


def doctor_has_access(db: DbSession, user: User, patient_id: uuid.UUID) -> bool:
    return (
        db.scalar(
            select(DoctorAssignment.id).where(
                DoctorAssignment.doctor_user_id == user.id,
                DoctorAssignment.patient_id == patient_id,
                DoctorAssignment.revoked_at.is_(None),
            )
        )
        is not None
    )


def require_patient_access(
    patient_id: uuid.UUID,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> Patient:
    """Caregiver membership, or a live doctor assignment. Nothing else."""
    patient = _load_patient(db, patient_id)
    if user.role == "doctor":
        if not doctor_has_access(db, user, patient_id):
            raise no_patient_access()
        return patient
    if not caregiver_has_access(db, user, patient_id):
        raise no_patient_access()
    return patient


def require_caregiver_access(
    patient_id: uuid.UUID,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> Patient:
    """Writes that only a caregiver may perform (a doctor may not play a session)."""
    patient = _load_patient(db, patient_id)
    if not caregiver_has_access(db, user, patient_id):
        raise no_patient_access()
    return patient


def settings_dependency() -> Settings:
    return get_settings()
