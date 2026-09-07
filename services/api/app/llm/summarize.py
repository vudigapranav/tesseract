"""Caregiver/doctor summary text.

The deterministic template is the implementation. An LLM, when enabled, may
only rephrase the same already-computed facts, and its output is validated
before use. Any failure — disabled, timeout, transport error, failed validation
— falls back to the template, and the response records which was used.

The model cannot invent a metric (it receives numbers and the output is checked
against them), cannot diagnose or discuss progression (validation rejects that
vocabulary), and cannot change a setting (there is no write path from here).
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any, Protocol

from ..config import Settings
from .payload import assert_deidentified, build_facts

GENERATOR_VERSION = "report-v1"

# Vocabulary a generated caregiver summary must not contain. This is a product
# rule from PS003_MASTER_CONTEXT: no diagnosis, no progression inference, no
# treatment advice.
FORBIDDEN_PHRASES = (
    "diagnos",
    "alzheimer",
    "dementia stage",
    "progression",
    "deteriorat",
    "decline in cognition",
    "cognitive decline",
    "prescrib",
    "medication",
    "dose",
    "treatment",
    "therapy should",
    "worsening",
)


@dataclass
class SummaryText:
    text: str
    generator: str  # 'template' | 'llm'
    generator_version: str
    fallback_reason: str | None = None


class LlmProvider(Protocol):
    def complete(self, system: str, user: str, timeout_seconds: int) -> str: ...


def render_template(facts: dict[str, Any]) -> str:
    """Deterministic, always available, never wrong about the numbers."""
    games = facts.get("games", [])
    if not games:
        return (
            "There are no recorded sessions yet, so there is nothing to summarise. "
            "This is not a finding about the person — it only means the app has no data."
        )

    lines: list[str] = []
    for game in games:
        total = game.get("sessions_total", 0)
        comparable = game.get("sessions_comparable", 0)
        name = str(game.get("game_id", "activity")).replace("_", " ")
        line = f"{name}: {total} recorded session(s), {comparable} directly comparable."

        if game.get("baseline_state") == "established":
            line += (
                " A provisional reference has been established from the first three"
                " comparable sessions."
            )
        else:
            line += (
                " Not enough comparable sessions yet for a provisional reference "
                "(three are needed)."
            )

        excluded = {k: v for k, v in (game.get("excluded") or {}).items() if v}
        if excluded:
            parts = ", ".join(f"{v} {k.replace('_', ' ')}" for k, v in sorted(excluded.items()))
            line += f" Set aside from comparison: {parts}."

        unavailable = sorted(
            {
                metric
                for session in game.get("sessions", [])
                for metric in session.get("unavailable_metrics", [])
            }
        )
        if unavailable:
            line += (
                " Not measured in this activity: "
                + ", ".join(m.replace("_", " ") for m in unavailable)
                + "."
            )
        lines.append(line)

    lines.append(
        "These are observations of how the activities were used. They are not "
        "cognitive scores and not a medical assessment."
    )
    return " ".join(lines)


def validate_llm_text(text: str, facts: dict[str, Any]) -> str | None:
    """Return a rejection reason, or None when the text is acceptable."""
    if not text or not text.strip():
        return "empty_response"
    if len(text) > 4000:
        return "too_long"

    lowered = text.lower()
    for phrase in FORBIDDEN_PHRASES:
        if phrase in lowered:
            return f"forbidden_phrase:{phrase}"

    # Every number in the generated text must be a number we actually supplied.
    # This is what stops the model inventing or "improving" a metric.
    allowed_numbers = _numbers_in(facts)
    for token in re.findall(r"\d+(?:\.\d+)?", text):
        if token not in allowed_numbers:
            return f"unsupported_number:{token}"
    return None


def _numbers_in(node: Any, found: set[str] | None = None) -> set[str]:
    found = found if found is not None else set()
    if isinstance(node, bool):
        return found
    if isinstance(node, (int, float)):
        found.add(str(node))
        if isinstance(node, float) and node.is_integer():
            found.add(str(int(node)))
        found.add(f"{node:.2f}" if isinstance(node, float) else str(node))
    elif isinstance(node, dict):
        for value in node.values():
            _numbers_in(value, found)
    elif isinstance(node, list):
        for value in node:
            _numbers_in(value, found)
    return found


SYSTEM_PROMPT = (
    "You rewrite pre-computed app-usage observations into two or three plain, "
    "calm sentences for a family caregiver. Rules: use only the numbers given; "
    "never introduce a number, statistic or fact that is not in the input; never "
    "diagnose; never mention dementia stage, disease progression, decline, "
    "medication or treatment; never suggest changing an activity setting. If the "
    "input says something was not measured, say it was not measured."
)


def summarize(
    summary: dict[str, Any], settings: Settings, provider: LlmProvider | None = None
) -> SummaryText:
    facts = build_facts(summary)
    assert_deidentified(facts)
    template = render_template(facts)

    if not settings.llm_enabled or provider is None:
        return SummaryText(template, "template", GENERATOR_VERSION, "llm_disabled")

    try:
        import json

        raw = provider.complete(
            SYSTEM_PROMPT,
            json.dumps(facts, sort_keys=True, default=str),
            settings.llm_timeout_seconds,
        )
    except Exception as exc:  # noqa: BLE001 - any provider failure falls back
        return SummaryText(
            template, "template", GENERATOR_VERSION, f"provider_error:{type(exc).__name__}"
        )

    rejection = validate_llm_text(raw, facts)
    if rejection:
        return SummaryText(template, "template", GENERATOR_VERSION, rejection)
    return SummaryText(raw.strip(), "llm", GENERATOR_VERSION)
