"""Doctor-side boundaries.

Assignment is the only access path — including for a direct session, report or
media id, which is where this kind of thing actually leaks.

These are plain JSON endpoints. The doctor frontend's platform (mobile screens
vs. a separate responsive web app) is an open decision in the product docs, and
nothing here assumes either.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..analytics.router import build_patient_summary
from ..auth.dependencies import (
    caregiver_has_access,
    current_user,
    doctor_has_access,
    require_doctor,
    require_patient_access,
)
from ..config import Settings, get_settings
from ..db import get_db
from ..errors import no_patient_access, not_found
from ..llm.providers import provider_for
from ..llm.summarize import summarize
from ..models import DoctorAssignment, DoctorNote, GeneratedReport, Patient, User
from ..schemas import NoteIn, NoteOut, ReportOut, ReportRequestIn

router = APIRouter(prefix="/v1", tags=["doctor"])


@router.get("/doctor/patients")
def list_assigned_patients(
    doctor: User = Depends(require_doctor),
    db: DbSession = Depends(get_db),
) -> dict:
    rows = db.execute(
        select(Patient, DoctorAssignment.assigned_at)
        .join(DoctorAssignment, DoctorAssignment.patient_id == Patient.id)
        .where(
            DoctorAssignment.doctor_user_id == doctor.id,
            DoctorAssignment.revoked_at.is_(None),
        )
        .order_by(Patient.display_name)
    ).all()
    return {
        "items": [
            {
                "patient_id": str(patient.id),
                "display_name": patient.display_name,
                "language": patient.language,
                "assigned_at": assigned_at.isoformat(),
            }
            for patient, assigned_at in rows
        ]
    }


@router.get("/doctor/patients/{patient_id}/summary")
def doctor_summary(
    patient_id: uuid.UUID,
    window_days: int = Query(default=30, ge=1, le=365),
    doctor: User = Depends(require_doctor),
    db: DbSession = Depends(get_db),
) -> dict:
    if not doctor_has_access(db, doctor, patient_id):
        raise no_patient_access()
    return build_patient_summary(db, patient_id, window_days, None).model_dump(mode="json")


# ---------------------------------------------------------------------------
# Notes - attributed, immutable, and kept separate from any generated draft
# ---------------------------------------------------------------------------


@router.post("/patients/{patient_id}/notes", response_model=NoteOut, status_code=201)
def create_note(
    body: NoteIn,
    patient: Patient = Depends(require_patient_access),
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> NoteOut:
    note = DoctorNote(patient_id=patient.id, author_user_id=user.id, body=body.body)
    db.add(note)
    db.flush()
    return NoteOut(
        note_id=note.id,
        patient_id=note.patient_id,
        author_user_id=note.author_user_id,
        body=note.body,
        created_at=note.created_at,
    )


@router.get("/patients/{patient_id}/notes", response_model=list[NoteOut])
def list_notes(
    patient: Patient = Depends(require_patient_access),
    db: DbSession = Depends(get_db),
) -> list[NoteOut]:
    rows = db.scalars(
        select(DoctorNote)
        .where(DoctorNote.patient_id == patient.id)
        .order_by(DoctorNote.created_at.desc())
    ).all()
    return [
        NoteOut(
            note_id=r.id,
            patient_id=r.patient_id,
            author_user_id=r.author_user_id,
            body=r.body,
            created_at=r.created_at,
        )
        for r in rows
    ]


# ---------------------------------------------------------------------------
# Generated reports - grounded in stored sessions, never free-standing text
# ---------------------------------------------------------------------------


@router.post("/patients/{patient_id}/reports", response_model=ReportOut, status_code=201)
def create_report(
    body: ReportRequestIn,
    patient: Patient = Depends(require_patient_access),
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> ReportOut:
    summary = build_patient_summary(db, patient.id, body.window_days, None).model_dump(
        mode="json"
    )
    source_ids = [
        uuid.UUID(session["session_id"])
        for game in summary["games"]
        for session in game["recent_sessions"]
    ]

    # provider_for returns None whenever summaries are off or unconfigured,
    # and summarize() falls back to the deterministic template either way.
    text = summarize(summary, settings, provider_for(settings))

    report = GeneratedReport(
        patient_id=patient.id,
        requested_by_user_id=user.id,
        window_days=body.window_days,
        status="draft",
        generator=text.generator,
        generator_version=text.generator_version,
        source_session_ids=[str(s) for s in source_ids],
        content={
            "narrative": text.text,
            "fallback_reason": text.fallback_reason,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "window_days": body.window_days,
            # Every number in the narrative reconciles to this block.
            "summary": summary,
            "limitations": [
                "Observed application-performance signals only.",
                "Not a diagnosis, cognitive score, or measure of disease progression.",
                "Recommendation thresholds are unreviewed prototype settings.",
                "Some metrics are not measured by the current games; see "
                "unavailable_metrics per session.",
            ],
            "review_state": "unreviewed_draft",
        },
    )
    db.add(report)
    db.flush()
    return _report_out(report)


@router.get("/reports/{report_id}", response_model=ReportOut)
def get_report(
    report_id: uuid.UUID,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> ReportOut:
    report = db.get(GeneratedReport, report_id)
    if report is None:
        raise not_found("Report")
    allowed = (
        doctor_has_access(db, user, report.patient_id)
        if user.role == "doctor"
        else caregiver_has_access(db, user, report.patient_id)
    )
    if not allowed:
        raise no_patient_access()
    return _report_out(report)


def _report_out(report: GeneratedReport) -> ReportOut:
    return ReportOut(
        report_id=report.id,
        patient_id=report.patient_id,
        window_days=report.window_days,
        status=report.status,
        generator=report.generator,
        generator_version=report.generator_version,
        source_session_ids=[uuid.UUID(s) for s in report.source_session_ids],
        content=report.content,
        created_at=report.created_at,
    )
