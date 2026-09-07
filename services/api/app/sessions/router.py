"""The session loop: create, ingest events, complete."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..analytics.service import compute_and_store, metrics_for_sessions
from ..auth.dependencies import caregiver_has_access, current_user, doctor_has_access
from ..db import get_db
from ..errors import no_patient_access, not_found
from ..models import Patient, Session, SessionMetric, User
from ..recommendations.service import evaluate_after_session
from ..schemas import (
    EventBatchIn,
    EventBatchOut,
    MetricsOut,
    SessionCompleteIn,
    SessionCompleteOut,
    SessionCreate,
    SessionOut,
)
from .service import (
    complete_session,
    create_or_get_session,
    ingest_events,
    session_event_count,
)

router = APIRouter(prefix="/v1", tags=["sessions"])


def _require_access(db: DbSession, user: User, patient_id: uuid.UUID) -> Patient:
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise no_patient_access()
    if user.role == "doctor":
        if not doctor_has_access(db, user, patient_id):
            raise no_patient_access()
        return patient
    if not caregiver_has_access(db, user, patient_id):
        raise no_patient_access()
    return patient


def _load_session_for_caregiver(
    db: DbSession, user: User, session_id: uuid.UUID
) -> Session:
    session = db.get(Session, session_id)
    if session is None:
        raise not_found("Session")
    # Access is resolved through the session's patient, so a direct session id
    # is exactly as protected as a patient list.
    if not caregiver_has_access(db, user, session.patient_id):
        raise no_patient_access()
    return session


def _session_out(db: DbSession, session: Session, created: bool) -> SessionOut:
    return SessionOut(
        session_id=session.id,
        patient_id=session.patient_id,
        game_id=session.game_id,
        game_version=session.game_version,
        level=session.level,
        is_tutorial=session.is_tutorial,
        requested_input_mode=session.requested_input_mode,
        actual_input_mode=session.actual_input_mode,
        input_mode_unverified=session.input_mode_unverified,
        status=session.status,
        created=created,
        events_received=session_event_count(db, session.id),
        final_seq=session.final_seq,
        created_at=session.created_at,
    )


@router.put("/sessions/{session_id}", response_model=SessionOut)
def put_session(
    session_id: uuid.UUID,
    body: SessionCreate,
    response: Response,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> SessionOut:
    """Idempotent create. 201 on first call, 200 on an identical replay."""
    # Access first: the patient binding is checked before anything is written.
    _require_access(db, user, body.patient_id)
    if user.role == "doctor":
        # A doctor reads; a doctor does not record play for a patient.
        raise no_patient_access()

    session, created = create_or_get_session(db, session_id, body, user)
    response.status_code = 201 if created else 200
    return _session_out(db, session, created)


@router.get("/sessions/{session_id}", response_model=SessionOut)
def get_session(
    session_id: uuid.UUID,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> SessionOut:
    session = _load_session_for_caregiver(db, user, session_id)
    return _session_out(db, session, created=False)


@router.post("/sessions/{session_id}/events:batch", response_model=EventBatchOut)
def post_events(
    session_id: uuid.UUID,
    body: EventBatchIn,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> EventBatchOut:
    """Accept a batch of events.

    Per-event verdicts, never an all-or-nothing failure: one malformed event
    must not discard the good events uploaded alongside it. Re-sending an
    already-accepted batch is safe and changes no totals.
    """
    session = _load_session_for_caregiver(db, user, session_id)
    outcome = ingest_events(db, session, body.events)
    return EventBatchOut(**outcome)


@router.post("/sessions/{session_id}/complete", response_model=SessionCompleteOut)
def post_complete(
    session_id: uuid.UUID,
    body: SessionCompleteIn,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> SessionCompleteOut:
    session = _load_session_for_caregiver(db, user, session_id)
    created = complete_session(
        db, session, body.status, body.final_seq, body.assisted, body.ended_at
    )

    result = compute_and_store(db, session)
    recommendation = evaluate_after_session(db, session) if created else None

    return SessionCompleteOut(
        session_id=session.id,
        status=session.status,
        final_seq=session.final_seq or 0,
        created=created,
        metrics=MetricsOut(
            metric_version=result.metric_version,
            calculator_id=result.calculator_id,
            available=result.values,
            unavailable=result.unavailable,
        ),
        recommendation_id=recommendation.id if recommendation else None,
    )


@router.get("/sessions/{session_id}/metrics", response_model=MetricsOut)
def get_metrics(
    session_id: uuid.UUID,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> MetricsOut:
    session = _load_session_for_caregiver(db, user, session_id)
    row = db.get(SessionMetric, session.id)
    if row is None:
        raise not_found("Metrics for this session")
    return MetricsOut(
        metric_version=row.metric_version,
        calculator_id=row.calculator_id,
        available=row.values,
        unavailable=row.unavailable,
    )


@router.get("/patients/{patient_id}/sessions")
def list_sessions(
    patient_id: uuid.UUID,
    limit: int = Query(default=50, ge=1, le=200),
    cursor: str | None = None,
    game_id: str | None = None,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> dict:
    _require_access(db, user, patient_id)

    query = select(Session).where(Session.patient_id == patient_id)
    if game_id:
        query = query.where(Session.game_id == game_id)
    if cursor:
        try:
            query = query.where(Session.created_at < _decode_cursor(cursor))
        except ValueError:
            raise not_found("Cursor") from None
    rows = list(db.scalars(query.order_by(Session.created_at.desc()).limit(limit + 1)).all())

    has_more = len(rows) > limit
    rows = rows[:limit]
    metrics = metrics_for_sessions(db, [r.id for r in rows])

    return {
        "items": [
            {
                "session_id": str(r.id),
                "game_id": r.game_id,
                "game_version": r.game_version,
                "level": r.level,
                "is_tutorial": r.is_tutorial,
                "assisted": r.assisted,
                "actual_input_mode": r.actual_input_mode,
                "input_mode_unverified": r.input_mode_unverified,
                "status": r.status,
                "final_seq": r.final_seq,
                "created_at": r.created_at.isoformat(),
                "completed_at": r.completed_at.isoformat() if r.completed_at else None,
                "metrics": (
                    {
                        "metric_version": metrics[r.id].metric_version,
                        "available": metrics[r.id].values,
                        "unavailable": metrics[r.id].unavailable,
                    }
                    if r.id in metrics
                    else None
                ),
            }
            for r in rows
        ],
        "next_cursor": _encode_cursor(rows[-1].created_at) if has_more and rows else None,
    }


def _encode_cursor(value) -> str:
    return value.isoformat()


def _decode_cursor(cursor: str):
    from datetime import datetime

    return datetime.fromisoformat(cursor)
