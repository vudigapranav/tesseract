"""Patient profiles and Know Me content."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Response
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session as DbSession

from ..auth.dependencies import current_user, require_caregiver_access, require_patient_access
from ..db import get_db
from ..errors import revision_conflict
from ..games import SAFE_DEFAULT_GAME_ID, SAFE_DEFAULT_LEVEL, get_spec
from ..models import ActivitySetting, CaregiverPatient, KnownEntry, Patient, PersonalWord, User
from ..schemas import (
    ActivityOut,
    ContentSufficiency,
    PatientCreate,
    PatientOut,
    PersonalizationIn,
    PersonalizationOut,
)

router = APIRouter(prefix="/v1", tags=["patients"])

# A product target, not a validation rule. Reported to the client so it can
# explain the consequence; never used to reject a write.
PERSONAL_WORD_TARGET = "15-20"
WORD_GAME_MINIMUM = 8


def _patient_out(patient: Patient) -> PatientOut:
    return PatientOut(
        patient_id=patient.id,
        display_name=patient.display_name,
        language=patient.language,
        known_type=patient.known_type,
        known_stage=patient.known_stage,
        accessibility=patient.accessibility,
        version=patient.version,
        created_at=patient.created_at,
    )


@router.post("/patients", response_model=PatientOut, status_code=201)
def create_patient(
    body: PatientCreate,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> PatientOut:
    patient = Patient(
        display_name=body.display_name,
        language=body.language,
        known_type=body.known_type,
        known_stage=body.known_stage,
        accessibility=body.accessibility,
        preferences={},
        version=1,
    )
    db.add(patient)
    db.flush()
    # Membership in the same transaction: a patient is never left unowned.
    db.add(CaregiverPatient(user_id=user.id, patient_id=patient.id, role="owner"))
    db.flush()
    return _patient_out(patient)


@router.get("/patients", response_model=list[PatientOut])
def list_patients(
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> list[PatientOut]:
    rows = db.scalars(
        select(Patient)
        .join(CaregiverPatient, CaregiverPatient.patient_id == Patient.id)
        .where(CaregiverPatient.user_id == user.id)
        .order_by(Patient.created_at)
    ).all()
    return [_patient_out(p) for p in rows]


@router.get("/patients/{patient_id}", response_model=PatientOut)
def get_patient(patient: Patient = Depends(require_patient_access)) -> PatientOut:
    return _patient_out(patient)


@router.get("/patients/{patient_id}/personalization")
def get_personalization(
    patient: Patient = Depends(require_patient_access),
    db: DbSession = Depends(get_db),
) -> dict:
    words = db.scalars(
        select(PersonalWord)
        .where(PersonalWord.patient_id == patient.id)
        .order_by(PersonalWord.position)
    ).all()
    entries = db.scalars(
        select(KnownEntry)
        .where(KnownEntry.patient_id == patient.id)
        .order_by(KnownEntry.position)
    ).all()
    return {
        "patient_id": str(patient.id),
        "version": patient.version,
        "personal_words": [{"text": w.text, "locale": w.locale} for w in words],
        "people_places": [
            {
                "kind": e.kind,
                "label": e.label,
                "media_asset_id": str(e.media_asset_id) if e.media_asset_id else None,
            }
            for e in entries
        ],
        "preferences": patient.preferences,
    }


@router.put("/patients/{patient_id}/personalization", response_model=PersonalizationOut)
def put_personalization(
    body: PersonalizationIn,
    patient: Patient = Depends(require_caregiver_access),
    db: DbSession = Depends(get_db),
) -> PersonalizationOut:
    # Optimistic concurrency: an editor working from a stale read is refused
    # rather than silently overwriting the newer content.
    if body.version != patient.version:
        raise revision_conflict(expected=patient.version, received=body.version)

    db.execute(delete(PersonalWord).where(PersonalWord.patient_id == patient.id))
    db.execute(delete(KnownEntry).where(KnownEntry.patient_id == patient.id))

    for position, word in enumerate(body.personal_words):
        db.add(
            PersonalWord(
                patient_id=patient.id, text=word.text, locale=word.locale, position=position
            )
        )
    for position, entry in enumerate(body.people_places):
        db.add(
            KnownEntry(
                patient_id=patient.id,
                kind=entry.kind,
                label=entry.label,
                media_asset_id=entry.media_asset_id,
                position=position,
            )
        )

    patient.preferences = body.preferences
    patient.version += 1
    db.flush()

    return PersonalizationOut(
        patient_id=patient.id,
        version=patient.version,
        personal_words_count=len(body.personal_words),
        people_places_count=len(body.people_places),
    )


def content_sufficiency(db: DbSession, patient_id: uuid.UUID) -> ContentSufficiency:
    word_count = (
        db.scalar(
            select(func.count())
            .select_from(PersonalWord)
            .where(PersonalWord.patient_id == patient_id)
        )
        or 0
    )
    entry_count = (
        db.scalar(
            select(func.count()).select_from(KnownEntry).where(KnownEntry.patient_id == patient_id)
        )
        or 0
    )
    return ContentSufficiency(
        personal_words=word_count,
        people_places=entry_count,
        sufficient_for_word_games=word_count >= WORD_GAME_MINIMUM,
        target_personal_words=PERSONAL_WORD_TARGET,
    )


@router.get("/patients/{patient_id}/activity", response_model=ActivityOut)
def get_activity(
    response: Response,
    patient: Patient = Depends(require_patient_access),
    db: DbSession = Depends(get_db),
) -> ActivityOut:
    """The caregiver-approved configuration, or a safe default.

    A pending recommendation never appears here. The patient plays the last
    approved configuration until a caregiver decides.
    """
    setting = db.get(ActivitySetting, patient.id)
    sufficiency = content_sufficiency(db, patient.id)

    if setting is None:
        spec = get_spec(SAFE_DEFAULT_GAME_ID)
        return ActivityOut(
            patient_id=patient.id,
            game_id=SAFE_DEFAULT_GAME_ID,
            level=SAFE_DEFAULT_LEVEL,
            input_mode=spec.default_input_mode if spec else "touch",
            config={},
            config_version=0,
            source="safe_default",
            approved_at=None,
            content_sufficiency=sufficiency,
        )

    return ActivityOut(
        patient_id=patient.id,
        game_id=setting.game_id,
        level=setting.level,
        input_mode=setting.input_mode,
        config=setting.config,
        config_version=setting.config_version,
        source="approved",
        approved_at=setting.approved_at,
        content_sufficiency=sufficiency,
    )
