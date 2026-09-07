"""Producing and applying recommendations."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..analytics.service import metrics_for_sessions
from ..games import SAFE_DEFAULT_GAME_ID, SAFE_DEFAULT_LEVEL, get_spec
from ..models import ActivitySetting, Patient, Recommendation, Session, User
from . import rules
from .settings import RULE_VERSION


def current_config(db: DbSession, patient_id: uuid.UUID) -> tuple[dict, int]:
    setting = db.get(ActivitySetting, patient_id)
    if setting is None:
        spec = get_spec(SAFE_DEFAULT_GAME_ID)
        return (
            {
                "game_id": SAFE_DEFAULT_GAME_ID,
                "level": SAFE_DEFAULT_LEVEL,
                "input_mode": spec.default_input_mode if spec else "touch",
            },
            0,
        )
    return (
        {
            "game_id": setting.game_id,
            "level": setting.level,
            "input_mode": setting.input_mode,
        },
        setting.config_version,
    )


def _patient_sessions(db: DbSession, patient_id: uuid.UUID, game_id: str) -> list[Session]:
    return list(
        db.scalars(
            select(Session)
            .where(
                Session.patient_id == patient_id,
                Session.game_id == game_id,
                Session.status != "open",
            )
            .order_by(Session.created_at)
        ).all()
    )


def evaluate_after_session(
    db: DbSession, session: Session
) -> Recommendation | None:
    """Run the rules after a session completes.

    Adaptation happens between sessions only; this is the single call site.
    Returns a pending recommendation, or None when the rules hold.
    """
    config, config_version = current_config(db, session.patient_id)

    # Only evaluate the game the patient just played, at the level currently
    # approved. A session at a different level does not move the approved one.
    if config["game_id"] != session.game_id:
        return None

    sessions = _patient_sessions(db, session.patient_id, session.game_id)
    metrics = metrics_for_sessions(db, [s.id for s in sessions])

    proposal = rules.evaluate(session.game_id, config["level"], sessions, metrics)
    if not proposal.is_change:
        return None

    # A still-undecided proposal for the same patient is superseded rather than
    # left to pile up; the caregiver should see one current suggestion.
    pending = db.scalars(
        select(Recommendation).where(
            Recommendation.patient_id == session.patient_id,
            Recommendation.status == "pending",
        )
    ).all()
    for old in pending:
        old.status = "superseded"

    proposed_config = {**config, "level": proposal.proposed_level}
    if proposed_config == config:
        return None

    recommendation = Recommendation(
        patient_id=session.patient_id,
        source_session_ids=proposal.observed.get("session_ids", []),
        rule_version=RULE_VERSION,
        proposed_config=proposed_config,
        current_config=config,
        reason=rules.build_reason(proposal),
        status="pending",
        based_on_config_version=config_version,
    )
    db.add(recommendation)
    db.flush()
    return recommendation


def apply_decision(
    db: DbSession,
    recommendation: Recommendation,
    patient: Patient,
    user: User,
    decision: str,
    modified_config: dict | None,
) -> dict | None:
    """Record the caregiver's decision and, if approved, write the activity.

    ``ActivitySetting`` is the only place an approved configuration is written,
    and it is only ever written from here.
    """
    recommendation.status = {"accept": "accepted", "modify": "modified", "reject": "rejected"}[
        decision
    ]
    recommendation.decided_by_user_id = user.id
    recommendation.decided_at = datetime.now(timezone.utc)

    if decision == "reject":
        recommendation.applied_config = None
        db.flush()
        return None

    config = dict(recommendation.proposed_config)
    if decision == "modify" and modified_config:
        config.update(modified_config)

    setting = db.get(ActivitySetting, patient.id)
    if setting is None:
        setting = ActivitySetting(patient_id=patient.id, config_version=0)
        db.add(setting)

    setting.game_id = config.get("game_id", setting.game_id)
    setting.level = int(config.get("level", setting.level))
    setting.input_mode = config.get("input_mode", setting.input_mode or "touch")
    setting.config = config
    setting.config_version += 1
    setting.approved_by_user_id = user.id
    setting.approved_at = datetime.now(timezone.utc)

    recommendation.applied_config = config
    db.flush()
    return config
