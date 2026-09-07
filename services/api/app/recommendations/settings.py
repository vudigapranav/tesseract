"""Recommendation thresholds.

Every number the rules use lives here, is versioned, and is tagged with its
review status. Nothing is hardcoded inside a rule.

    THESE NUMBERS ARE UNREVIEWED PROTOTYPE SETTINGS.

They are engineering starting points chosen so the loop can be demonstrated.
They have not been usability tested, clinically reviewed, or validated against
real play by anyone. ``status`` is echoed in every recommendation's
``reason.thresholds_status`` so a caregiver-facing screen cannot present them as
established. Changing a value means publishing a new ``RULE_VERSION``; existing
recommendations keep the version they were decided under.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass

RULE_VERSION = "rules-v1"
BASELINE_VERSION = "baseline-v1"

STATUS = "prototype_unreviewed"


@dataclass(frozen=True)
class Thresholds:
    # How many comparable sessions before any proposal is made at all.
    min_comparable_sessions: int = 3

    # Sessions used to establish a provisional reference. Carried over from the
    # handbook. An engineering assumption, not a clinical protocol.
    baseline_session_count: int = 3

    # Promotion requires every one of the last N comparable sessions to have
    # completed the game's objective with no help.
    promote_required_completions: int = 3
    promote_max_hints_total: int = 0
    promote_max_wrong_interactions_per_session: int = 2

    # Easing requires repeated difficulty, not one bad day.
    ease_min_incomplete_sessions: int = 2
    ease_min_hint_sessions: int = 2

    def as_dict(self) -> dict:
        return asdict(self)


THRESHOLDS = Thresholds()


def thresholds_block(used: dict) -> dict:
    """The explanation block attached to every recommendation."""
    return {
        "rule_version": RULE_VERSION,
        "thresholds_used": used,
        "thresholds_status": STATUS,
        "thresholds_note": (
            "Prototype values. Not usability tested, not clinically reviewed. "
            "Require review before any real-world use."
        ),
    }
