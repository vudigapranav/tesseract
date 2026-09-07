"""Comparable history and provisional app-performance references."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..auth.dependencies import require_patient_access
from ..db import get_db
from ..models import Patient, Session
from ..recommendations.settings import THRESHOLDS
from ..schemas import BaselineOut, GameSummaryOut, MetricsOut, PatientSummaryOut
from .comparability import EXCLUSION_REASONS, build_baseline, exclusion_reason, largest_series
from .service import metrics_for_sessions

router = APIRouter(prefix="/v1", tags=["analytics"])

# Said in the response itself, so a screen cannot present these as clinical
# scores by omission.
SUMMARY_NOTE = (
    "These are observed application-performance signals from gameplay. They are "
    "not cognitive scores, not a diagnosis, and not a measure of disease progression."
)


def build_patient_summary(
    db: DbSession, patient_id: uuid.UUID, window_days: int | None, game_id: str | None
) -> PatientSummaryOut:
    query = select(Session).where(
        Session.patient_id == patient_id, Session.status != "open"
    )
    if game_id:
        query = query.where(Session.game_id == game_id)
    sessions = list(db.scalars(query.order_by(Session.created_at)).all())

    if window_days:
        cutoff = datetime.now(timezone.utc).timestamp() - window_days * 86400
        sessions = [s for s in sessions if (s.completed_at or s.created_at).timestamp() >= cutoff]

    metrics = metrics_for_sessions(db, [s.id for s in sessions])

    by_game: dict[str, list[Session]] = {}
    for session in sessions:
        by_game.setdefault(session.game_id, []).append(session)

    games: list[GameSummaryOut] = []
    for gid, rows in sorted(by_game.items()):
        excluded = {reason: 0 for reason in EXCLUSION_REASONS}
        for row in rows:
            reason = exclusion_reason(row)
            if reason:
                excluded[reason] += 1

        series = largest_series(rows)
        baseline = build_baseline(series, metrics, THRESHOLDS.baseline_session_count)

        games.append(
            GameSummaryOut(
                game_id=gid,
                sessions_total=len(rows),
                sessions_comparable=len(series),
                baseline=BaselineOut(**baseline),
                excluded=excluded,
                recent_sessions=[
                    {
                        "session_id": str(r.id),
                        "level": r.level,
                        "status": r.status,
                        "assisted": r.assisted,
                        "is_tutorial": r.is_tutorial,
                        "actual_input_mode": r.actual_input_mode,
                        "completed_at": (
                            r.completed_at.isoformat() if r.completed_at else None
                        ),
                        "metrics": (
                            metrics[r.id].values if r.id in metrics else None
                        ),
                        "unavailable_metrics": (
                            metrics[r.id].unavailable if r.id in metrics else None
                        ),
                    }
                    for r in sorted(
                        rows, key=lambda s: (s.completed_at or s.created_at), reverse=True
                    )[:10]
                ],
            )
        )

    last_session_at = max(
        (s.completed_at or s.created_at for s in sessions), default=None
    )
    return PatientSummaryOut(
        patient_id=patient_id,
        generated_at=datetime.now(timezone.utc),
        last_session_at=last_session_at,
        games=games,
        note=SUMMARY_NOTE,
    )


@router.get("/patients/{patient_id}/summary", response_model=PatientSummaryOut)
def get_summary(
    window_days: int | None = Query(default=None, ge=1, le=365),
    game_id: str | None = None,
    patient: Patient = Depends(require_patient_access),
    db: DbSession = Depends(get_db),
) -> PatientSummaryOut:
    return build_patient_summary(db, patient.id, window_days, game_id)


__all__ = ["router", "build_patient_summary", "MetricsOut"]
