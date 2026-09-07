"""Which sessions may be compared with which.

Comparing a level-1 touch tutorial against a level-3 tilt session would produce
a confident, meaningless trend. Everything that changes the task forms part of
the series key, so changing any of it starts a *new* series rather than
extending the old one.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any

from ..models import Session, SessionMetric
from ..recommendations.settings import BASELINE_VERSION

# Reasons a session is kept out of a comparable series. Reported per patient so
# a caregiver screen can say why a number is missing.
EXCLUSION_REASONS = (
    "tutorial",
    "assisted",
    "not_completed",
    "input_mode_unverified",
)


def comparability_key(session: Session) -> tuple:
    """Same task, same conditions. Anything here changing splits the series."""
    return (
        session.game_id,
        session.game_version,
        session.level,
        json.dumps(session.difficulty_params, sort_keys=True, default=str),
        session.actual_input_mode,
        session.content_version,
        session.metric_version,
    )


def exclusion_reason(session: Session) -> str | None:
    if session.is_tutorial:
        return "tutorial"
    if session.status != "completed":
        return "not_completed"
    if session.assisted:
        return "assisted"
    if session.input_mode_unverified:
        return "input_mode_unverified"
    return None


def is_comparable(session: Session) -> bool:
    return exclusion_reason(session) is None


@dataclass
class Series:
    key: tuple
    sessions: list[Session]


def group_comparable(sessions: list[Session]) -> dict[tuple, list[Session]]:
    grouped: dict[tuple, list[Session]] = {}
    for session in sessions:
        if not is_comparable(session):
            continue
        grouped.setdefault(comparability_key(session), []).append(session)
    for rows in grouped.values():
        rows.sort(key=lambda s: (s.completed_at or s.created_at))
    return grouped


def largest_series(sessions: list[Session]) -> list[Session]:
    """The series with the most sessions; ties broken by the most recent."""
    grouped = group_comparable(sessions)
    if not grouped:
        return []
    return max(
        grouped.values(),
        key=lambda rows: (len(rows), max((r.completed_at or r.created_at) for r in rows)),
    )


def _median(values: list[float]) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return float(ordered[middle])
    return float((ordered[middle - 1] + ordered[middle]) / 2)


def build_baseline(
    series: list[Session],
    metrics_by_session: dict[Any, SessionMetric],
    required: int,
) -> dict[str, Any]:
    """A provisional reference from the first ``required`` comparable sessions.

    ``required`` is an engineering starting assumption from the handbook, not a
    validated clinical protocol. The response says so.
    """
    basis = (
        f"Median of the first {required} comparable sessions. "
        "Engineering starting assumption, not a validated clinical protocol."
    )

    if len(series) < required:
        return {
            "state": "insufficient_data",
            "rule_version": BASELINE_VERSION,
            "basis": basis,
            "from_session_ids": [],
            "values": {"sessions_available": len(series), "sessions_required": required},
        }

    used = series[:required]
    numeric: dict[str, list[float]] = {}
    for session in used:
        metric = metrics_by_session.get(session.id)
        if metric is None:
            continue
        for name, value in metric.values.items():
            if isinstance(value, bool) or not isinstance(value, (int, float)):
                continue
            numeric.setdefault(name, []).append(float(value))

    medians = {f"{name}_median": _median(values) for name, values in sorted(numeric.items())}
    return {
        "state": "established",
        "rule_version": BASELINE_VERSION,
        "basis": basis,
        "from_session_ids": [s.id for s in used],
        "values": medians,
    }
