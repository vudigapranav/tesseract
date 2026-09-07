"""Reminder definitions and the occurrence/acknowledgement log.

Independent of gameplay by design: nothing in this module reads a session, and
a patient who never opens a game still receives reminders.

Division of labour with the Flutter side: the **device** schedules and fires
local notifications, and owns permission handling, restart recovery and
time-zone changes. The **server** owns definitions and the occurrence log, and
is not required to be reachable for a reminder to fire.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..auth.dependencies import caregiver_has_access, current_user, require_patient_access
from ..db import get_db
from ..errors import no_patient_access, not_found
from ..models import Patient, Reminder, ReminderOccurrence, User
from ..schemas import (
    AcknowledgeIn,
    OccurrenceIn,
    OccurrenceOut,
    ReminderIn,
    ReminderOut,
)

router = APIRouter(prefix="/v1", tags=["reminders"])


def _out(row: Reminder) -> ReminderOut:
    return ReminderOut(
        reminder_id=row.id,
        patient_id=row.patient_id,
        title=row.title,
        body=row.body,
        schedule=row.schedule,
        schedule_version=row.schedule_version,
        active=row.active,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


def _occurrence_out(row: ReminderOccurrence) -> OccurrenceOut:
    return OccurrenceOut(
        occurrence_id=row.id,
        reminder_id=row.reminder_id,
        scheduled_for=row.scheduled_for,
        schedule_version=row.schedule_version,
        state=row.state,
        acknowledgement_state=row.acknowledgement_state,
        acknowledged_at=row.acknowledged_at,
    )


def _load_reminder(db: DbSession, user: User, reminder_id: uuid.UUID) -> Reminder:
    reminder = db.get(Reminder, reminder_id)
    if reminder is None:
        raise not_found("Reminder")
    if not caregiver_has_access(db, user, reminder.patient_id):
        raise no_patient_access()
    return reminder


@router.post("/patients/{patient_id}/reminders", response_model=ReminderOut, status_code=201)
def create_reminder(
    body: ReminderIn,
    patient: Patient = Depends(require_patient_access),
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> ReminderOut:
    reminder = Reminder(
        patient_id=patient.id,
        title=body.title,
        body=body.body,
        schedule=body.schedule.model_dump(),
        schedule_version=1,
        active=body.active,
        created_by_user_id=user.id,
    )
    db.add(reminder)
    db.flush()
    return _out(reminder)


@router.get("/patients/{patient_id}/reminders", response_model=list[ReminderOut])
def list_reminders(
    patient: Patient = Depends(require_patient_access),
    db: DbSession = Depends(get_db),
) -> list[ReminderOut]:
    rows = db.scalars(
        select(Reminder)
        .where(Reminder.patient_id == patient.id)
        .order_by(Reminder.created_at)
    ).all()
    return [_out(r) for r in rows]


@router.put("/reminders/{reminder_id}", response_model=ReminderOut)
def update_reminder(
    reminder_id: uuid.UUID,
    body: ReminderIn,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> ReminderOut:
    reminder = _load_reminder(db, user, reminder_id)
    reminder.title = body.title
    reminder.body = body.body
    reminder.schedule = body.schedule.model_dump()
    reminder.active = body.active
    # Bumped on every edit so a device that was offline can tell its cached
    # schedule is stale and reschedule its local notifications.
    reminder.schedule_version += 1
    db.flush()
    return _out(reminder)


@router.delete("/reminders/{reminder_id}", status_code=204)
def delete_reminder(
    reminder_id: uuid.UUID,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> None:
    reminder = _load_reminder(db, user, reminder_id)
    db.delete(reminder)
    db.flush()


@router.post("/reminders/{reminder_id}/occurrences", response_model=OccurrenceOut, status_code=201)
def record_occurrence(
    reminder_id: uuid.UUID,
    body: OccurrenceIn,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> OccurrenceOut:
    """The device reports an occurrence it actually scheduled or fired.

    Idempotent on (reminder, scheduled_for): a device that reports the same
    occurrence twice after a restart does not create a duplicate.
    """
    reminder = _load_reminder(db, user, reminder_id)
    existing = db.scalar(
        select(ReminderOccurrence).where(
            ReminderOccurrence.reminder_id == reminder.id,
            ReminderOccurrence.scheduled_for == body.scheduled_for,
        )
    )
    if existing is not None:
        existing.state = body.state
        db.flush()
        return _occurrence_out(existing)

    occurrence = ReminderOccurrence(
        reminder_id=reminder.id,
        patient_id=reminder.patient_id,
        scheduled_for=body.scheduled_for,
        schedule_version=body.schedule_version,
        state=body.state,
        device_id=body.device_id,
    )
    db.add(occurrence)
    db.flush()
    return _occurrence_out(occurrence)


@router.get("/patients/{patient_id}/reminders/occurrences", response_model=list[OccurrenceOut])
def list_occurrences(
    limit: int = Query(default=100, ge=1, le=500),
    patient: Patient = Depends(require_patient_access),
    db: DbSession = Depends(get_db),
) -> list[OccurrenceOut]:
    rows = db.scalars(
        select(ReminderOccurrence)
        .where(ReminderOccurrence.patient_id == patient.id)
        .order_by(ReminderOccurrence.scheduled_for.desc())
        .limit(limit)
    ).all()
    return [_occurrence_out(r) for r in rows]


@router.post("/reminder-occurrences/{occurrence_id}/acknowledge", response_model=OccurrenceOut)
def acknowledge(
    occurrence_id: uuid.UUID,
    body: AcknowledgeIn,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> OccurrenceOut:
    """Record that a prompt was seen and answered.

    This is NOT medication adherence. The field is `acknowledgement_state`, and
    the API has no concept of a dose, a prescription or whether anything was
    actually taken.
    """
    occurrence = db.get(ReminderOccurrence, occurrence_id)
    if occurrence is None:
        raise not_found("Reminder occurrence")
    if not caregiver_has_access(db, user, occurrence.patient_id):
        raise no_patient_access()

    occurrence.acknowledgement_state = body.acknowledgement_state
    occurrence.acknowledged_at = datetime.now(timezone.utc)
    db.flush()
    return _occurrence_out(occurrence)
