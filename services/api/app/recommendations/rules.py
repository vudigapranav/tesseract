"""Deterministic, explainable activity rules.

No model, no scoring function, no hidden state. Given the same sessions these
functions return the same proposal, and every proposal carries the observed
values and the thresholds that produced it.

Guardrails that hold by construction:

* A proposal is produced only *between* sessions, on completion.
* Missing data, assisted play or interrupted sessions never promote.
* Speed alone never promotes — no duration term appears in any promotion test.
* Level is clamped to the game's registered floor and ceiling.
* ``hold`` is a valid, expected outcome, not a failure.
* Nothing here writes an activity setting. A caregiver decision does that.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from ..analytics.comparability import largest_series
from ..games import at_ceiling, at_floor, clamp_level
from ..models import Session, SessionMetric
from .settings import THRESHOLDS, thresholds_block

# The metric that means "the patient achieved the game's objective". Named per
# game because there is no universal completion metric across nine games.
OBJECTIVE_METRIC = {
    "route_quest": "route_completed",
    "marble_maze": "goal_reached",
}


@dataclass
class Proposal:
    action: str  # 'promote' | 'ease' | 'hold'
    reason_code: str
    summary: str
    observed: dict[str, Any]
    thresholds_used: dict[str, Any]
    proposed_level: int | None = None

    @property
    def is_change(self) -> bool:
        return self.action in ("promote", "ease") and self.proposed_level is not None


def _hold(code: str, summary: str, observed: dict[str, Any], used: dict[str, Any]) -> Proposal:
    return Proposal("hold", code, summary, observed, used)


def evaluate(
    game_id: str,
    current_level: int,
    sessions: list[Session],
    metrics_by_session: dict[Any, SessionMetric],
) -> Proposal:
    """Decide what, if anything, to propose for ``game_id`` at ``current_level``."""
    objective = OBJECTIVE_METRIC.get(game_id)
    if objective is None:
        return _hold(
            "no_objective_metric",
            f"No completion metric is defined for {game_id}, so no change is proposed.",
            {"game_id": game_id},
            {},
        )

    at_level = [s for s in sessions if s.game_id == game_id and s.level == current_level]

    # --- easing looks at everything recent, including assisted and stopped
    # sessions: repeated help is exactly where difficulty shows up, and those
    # sessions are excluded from the comparable series by design.
    ease = _consider_easing(game_id, current_level, at_level, metrics_by_session, objective)
    if ease is not None:
        return ease

    # --- promotion uses the strict comparable series only.
    series = largest_series(at_level)
    used = {
        "min_comparable_sessions": THRESHOLDS.min_comparable_sessions,
        "promote_required_completions": THRESHOLDS.promote_required_completions,
        "promote_max_hints_total": THRESHOLDS.promote_max_hints_total,
        "promote_max_wrong_interactions_per_session": (
            THRESHOLDS.promote_max_wrong_interactions_per_session
        ),
    }

    if len(series) < THRESHOLDS.min_comparable_sessions:
        return _hold(
            "insufficient_data",
            (
                f"{len(series)} comparable session(s) recorded; "
                f"{THRESHOLDS.min_comparable_sessions} are needed before suggesting a change."
            ),
            {"comparable_sessions": len(series)},
            used,
        )

    recent = series[-THRESHOLDS.promote_required_completions :]
    observed = _observe(recent, metrics_by_session, objective)

    if at_ceiling(game_id, current_level):
        return _hold(
            "at_ceiling",
            "This activity is already at its highest configured level.",
            observed,
            used,
        )

    if None in observed["objective_reached"]:
        return _hold(
            "missing_metric",
            "At least one recent session has no recorded completion metric, so no change "
            "is proposed.",
            observed,
            used,
        )

    all_completed = all(observed["objective_reached"])
    hints_total = sum(observed["hints_used"])
    wrong_ok = all(
        w <= THRESHOLDS.promote_max_wrong_interactions_per_session
        for w in observed["wrong_interactions"]
    )

    if all_completed and hints_total <= THRESHOLDS.promote_max_hints_total and wrong_ok:
        return Proposal(
            action="promote",
            reason_code="consistent_success",
            summary=(
                f"The last {len(recent)} comparable sessions were completed without help. "
                "Suggesting the next level up for review."
            ),
            observed=observed,
            thresholds_used=used,
            proposed_level=clamp_level(game_id, current_level + 1),
        )

    return _hold(
        "mixed_performance",
        "Recent sessions do not consistently meet the review thresholds, so the current "
        "activity stays as it is.",
        observed,
        used,
    )


def _consider_easing(
    game_id: str,
    current_level: int,
    at_level: list[Session],
    metrics_by_session: dict[Any, SessionMetric],
    objective: str,
) -> Proposal | None:
    used = {
        "ease_min_incomplete_sessions": THRESHOLDS.ease_min_incomplete_sessions,
        "ease_min_hint_sessions": THRESHOLDS.ease_min_hint_sessions,
    }
    window = THRESHOLDS.ease_min_incomplete_sessions + THRESHOLDS.ease_min_hint_sessions
    recent = sorted(at_level, key=lambda s: (s.completed_at or s.created_at))[-window:]
    if len(recent) < THRESHOLDS.ease_min_incomplete_sessions:
        return None

    observed = _observe(recent, metrics_by_session, objective)
    incomplete = sum(1 for reached in observed["objective_reached"] if reached is False)
    hinted = sum(1 for hints in observed["hints_used"] if hints > 0)

    triggered = (
        incomplete >= THRESHOLDS.ease_min_incomplete_sessions
        or hinted >= THRESHOLDS.ease_min_hint_sessions
    )
    if not triggered:
        return None

    observed = {**observed, "incomplete_sessions": incomplete, "sessions_with_hints": hinted}

    if at_floor(game_id, current_level):
        return _hold(
            "at_floor",
            "This activity is already at its gentlest level; additional support is a "
            "caregiver decision rather than a level change.",
            observed,
            used,
        )

    return Proposal(
        action="ease",
        reason_code="repeated_difficulty",
        summary=(
            "Recent sessions were repeatedly left unfinished or needed help. "
            "Suggesting one easier level for review."
        ),
        observed=observed,
        thresholds_used=used,
        proposed_level=clamp_level(game_id, current_level - 1),
    )


def _observe(
    sessions: list[Session], metrics_by_session: dict[Any, SessionMetric], objective: str
) -> dict[str, Any]:
    objective_reached: list[bool | None] = []
    hints: list[int] = []
    wrong: list[int] = []
    for session in sessions:
        metric = metrics_by_session.get(session.id)
        values = metric.values if metric else {}
        raw = values.get(objective)
        objective_reached.append(bool(raw) if isinstance(raw, bool) else None)
        hints.append(int(values.get("hints_used", 0) or 0))
        wrong.append(int(values.get("wrong_interactions", 0) or 0))
    return {
        "session_ids": [str(s.id) for s in sessions],
        "objective_metric": objective,
        "objective_reached": objective_reached,
        "hints_used": hints,
        "wrong_interactions": wrong,
    }


def build_reason(proposal: Proposal) -> dict[str, Any]:
    return {
        "code": proposal.reason_code,
        "summary": proposal.summary,
        "observed": proposal.observed,
        **thresholds_block(proposal.thresholds_used),
    }
