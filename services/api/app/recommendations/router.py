"""Caregiver review of proposed activity changes."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..auth.dependencies import caregiver_has_access, current_user, require_patient_access
from ..db import get_db
from ..errors import ApiError, invalid_data, no_patient_access, not_found, revision_conflict
from ..models import Patient, Recommendation, User
from ..schemas import DecisionIn, RecommendationListOut, RecommendationOut
from .service import apply_decision, current_config

router = APIRouter(prefix="/v1", tags=["recommendations"])


def _out(row: Recommendation) -> RecommendationOut:
    return RecommendationOut(
        recommendation_id=row.id,
        patient_id=row.patient_id,
        status=row.status,
        rule_version=row.rule_version,
        proposed_config=row.proposed_config,
        current_config=row.current_config,
        reason=row.reason,
        based_on_config_version=row.based_on_config_version,
        created_at=row.created_at,
        decided_at=row.decided_at,
    )


@router.get("/patients/{patient_id}/recommendations", response_model=RecommendationListOut)
def list_recommendations(
    status: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    patient: Patient = Depends(require_patient_access),
    db: DbSession = Depends(get_db),
) -> RecommendationListOut:
    query = select(Recommendation).where(Recommendation.patient_id == patient.id)
    if status:
        query = query.where(Recommendation.status == status)
    rows = db.scalars(query.order_by(Recommendation.created_at.desc()).limit(limit)).all()
    return RecommendationListOut(items=[_out(r) for r in rows], next_cursor=None)


@router.post("/recommendations/{recommendation_id}/decision", response_model=RecommendationOut)
def decide(
    recommendation_id: uuid.UUID,
    body: DecisionIn,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
) -> RecommendationOut:
    """Accept, modify or reject a proposal.

    The reviewer is taken from the authenticated identity, never from the body.
    """
    recommendation = db.get(Recommendation, recommendation_id)
    if recommendation is None:
        raise not_found("Recommendation")

    # A doctor may suggest; only a caregiver activates. Recorded as an open
    # planning decision in the handbook, implemented conservatively here.
    if not caregiver_has_access(db, user, recommendation.patient_id):
        raise no_patient_access()

    if recommendation.status != "pending":
        raise ApiError(
            409,
            "already_decided",
            "This recommendation was already decided.",
            {"status": recommendation.status},
        )

    if body.decision == "modify" and not body.modified_config:
        raise invalid_data("A 'modify' decision must include modified_config.")

    # Guard against a stale proposal overwriting a newer approved configuration.
    _, config_version = current_config(db, recommendation.patient_id)
    if body.expected_config_version is not None and body.expected_config_version != config_version:
        raise revision_conflict(expected=config_version, received=body.expected_config_version)

    patient = db.get(Patient, recommendation.patient_id)
    if patient is None:  # pragma: no cover - FK guarantees this
        raise not_found("Patient")

    apply_decision(db, recommendation, patient, user, body.decision, body.modified_config)
    return _out(recommendation)
