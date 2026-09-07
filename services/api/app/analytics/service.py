"""Storing and reading computed metrics."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..models import Event, Session, SessionMetric
from .calculators import MetricResult, calculate


def session_events(db: DbSession, session_id: uuid.UUID) -> list[Event]:
    return list(
        db.scalars(
            select(Event).where(Event.session_id == session_id).order_by(Event.seq)
        ).all()
    )


def compute_and_store(db: DbSession, session: Session) -> MetricResult:
    result = calculate(session, session_events(db, session.id))
    row = db.get(SessionMetric, session.id)
    if row is None:
        row = SessionMetric(session_id=session.id)
        db.add(row)
    row.metric_version = result.metric_version
    row.calculator_id = result.calculator_id
    row.values = result.values
    row.unavailable = result.unavailable
    db.flush()
    return result


def metrics_for_sessions(
    db: DbSession, session_ids: list[uuid.UUID]
) -> dict[uuid.UUID, SessionMetric]:
    if not session_ids:
        return {}
    rows = db.scalars(
        select(SessionMetric).where(SessionMetric.session_id.in_(session_ids))
    ).all()
    return {row.session_id: row for row in rows}
