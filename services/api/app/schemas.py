"""Wire shapes. Field names match docs/contracts/PS003_API_CONTRACT_V1.md."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

INPUT_MODES = ("touch", "tilt")
RESULT_STATUSES = ("completed", "stopped_by_user", "interrupted")


class Strict(BaseModel):
    model_config = ConfigDict(extra="ignore")


# --------------------------------------------------------------------------
# Patients and Know Me
# --------------------------------------------------------------------------


class PatientCreate(Strict):
    display_name: str = Field(min_length=1, max_length=255)
    language: str = Field(default="en", max_length=16)
    # Optional always. Caregiver-entered context, never a difficulty input.
    known_type: str | None = Field(default=None, max_length=64)
    known_stage: str | None = Field(default=None, max_length=64)
    accessibility: dict[str, Any] = Field(default_factory=dict)


class PatientOut(Strict):
    patient_id: uuid.UUID
    display_name: str
    language: str
    known_type: str | None
    known_stage: str | None
    accessibility: dict[str, Any]
    version: int
    created_at: datetime


class PersonalWordIn(Strict):
    text: str = Field(min_length=1, max_length=128)
    locale: str = Field(default="en", max_length=16)


class KnownEntryIn(Strict):
    kind: Literal["person", "place"]
    label: str = Field(min_length=1, max_length=255)
    media_asset_id: uuid.UUID | None = None


class PersonalizationIn(Strict):
    version: int = Field(ge=1)
    # Fewer words, or none at all, is valid. 15-20 is a product target the
    # client explains; the server does not enforce it.
    personal_words: list[PersonalWordIn] = Field(default_factory=list, max_length=200)
    people_places: list[KnownEntryIn] = Field(default_factory=list, max_length=200)
    preferences: dict[str, Any] = Field(default_factory=dict)


class PersonalizationOut(Strict):
    patient_id: uuid.UUID
    version: int
    personal_words_count: int
    people_places_count: int


class ContentSufficiency(Strict):
    personal_words: int
    people_places: int
    sufficient_for_word_games: bool
    target_personal_words: str


class ActivityOut(Strict):
    patient_id: uuid.UUID
    game_id: str
    level: int
    input_mode: str
    config: dict[str, Any]
    config_version: int
    source: Literal["approved", "safe_default"]
    approved_at: datetime | None
    content_sufficiency: ContentSufficiency


# --------------------------------------------------------------------------
# Sessions
# --------------------------------------------------------------------------


class SessionCreate(Strict):
    patient_id: uuid.UUID
    game_id: str = Field(min_length=1, max_length=64)
    game_version: str = Field(min_length=1, max_length=32)
    schema_version: str = Field(default="1", max_length=16)
    config_version: str = Field(default="1", max_length=16)
    content_version: str = Field(default="1", max_length=16)
    metric_version: str = Field(default="1", max_length=16)
    level: int = Field(ge=1, le=99)
    difficulty_params: dict[str, Any] = Field(default_factory=dict)
    requested_input_mode: Literal["touch", "tilt"]
    # Optional: when absent the session is flagged input_mode_unverified and
    # actual is assumed equal to requested. See contract P4.
    actual_input_mode: Literal["touch", "tilt"] | None = None
    is_tutorial: bool = False
    text_scale: float = Field(default=1.0, ge=0.5, le=4.0)
    locale: str = Field(default="en", max_length=16)
    started_at: datetime | None = None


class SessionOut(Strict):
    session_id: uuid.UUID
    patient_id: uuid.UUID
    game_id: str
    game_version: str
    level: int
    is_tutorial: bool
    requested_input_mode: str
    actual_input_mode: str
    input_mode_unverified: bool
    status: str
    created: bool
    events_received: int
    final_seq: int | None
    created_at: datetime


class EventIn(Strict):
    event_id: uuid.UUID
    seq: int = Field(ge=1)
    type: str = Field(min_length=1, max_length=64)
    elapsed_ms: int = Field(ge=0)
    occurred_at: datetime
    payload: dict[str, Any] = Field(default_factory=dict)

    @field_validator("payload")
    @classmethod
    def _payload_is_object(cls, value: dict[str, Any]) -> dict[str, Any]:
        return value or {}


class EventBatchIn(Strict):
    events: list[EventIn] = Field(min_length=1, max_length=500)


class RejectedEvent(Strict):
    event_id: uuid.UUID
    reason: str
    detail: str | None = None


class EventBatchOut(Strict):
    accepted: list[uuid.UUID]
    duplicate: list[uuid.UUID]
    rejected: list[RejectedEvent]
    highest_seq: int | None
    missing_seqs: list[int]


class SessionCompleteIn(Strict):
    status: Literal["completed", "stopped_by_user", "interrupted"]
    final_seq: int = Field(ge=0)
    assisted: bool = False
    ended_at: datetime | None = None


class MetricsOut(Strict):
    metric_version: str
    calculator_id: str
    available: dict[str, Any]
    unavailable: dict[str, Any]


class SessionCompleteOut(Strict):
    session_id: uuid.UUID
    status: str
    final_seq: int
    created: bool
    metrics: MetricsOut | None
    recommendation_id: uuid.UUID | None


# --------------------------------------------------------------------------
# Summary and recommendations
# --------------------------------------------------------------------------


class BaselineOut(Strict):
    state: Literal["insufficient_data", "established"]
    rule_version: str
    basis: str
    from_session_ids: list[uuid.UUID]
    values: dict[str, Any]


class GameSummaryOut(Strict):
    game_id: str
    sessions_total: int
    sessions_comparable: int
    baseline: BaselineOut
    excluded: dict[str, int]
    recent_sessions: list[dict[str, Any]]


class PatientSummaryOut(Strict):
    patient_id: uuid.UUID
    generated_at: datetime
    last_session_at: datetime | None
    games: list[GameSummaryOut]
    note: str


class RecommendationOut(Strict):
    recommendation_id: uuid.UUID
    patient_id: uuid.UUID
    status: str
    rule_version: str
    proposed_config: dict[str, Any]
    current_config: dict[str, Any]
    reason: dict[str, Any]
    based_on_config_version: int
    created_at: datetime
    decided_at: datetime | None


class RecommendationListOut(Strict):
    items: list[RecommendationOut]
    next_cursor: str | None


class DecisionIn(Strict):
    decision: Literal["accept", "modify", "reject"]
    modified_config: dict[str, Any] | None = None
    expected_config_version: int | None = None


# --------------------------------------------------------------------------
# Reminders
# --------------------------------------------------------------------------


class ReminderScheduleIn(Strict):
    kind: Literal["daily", "weekly", "once"]
    times: list[str] = Field(default_factory=list, max_length=24)
    weekdays: list[int] = Field(default_factory=list, max_length=7)
    date: str | None = None
    timezone: str = Field(default="UTC", max_length=64)


class ReminderIn(Strict):
    title: str = Field(min_length=1, max_length=255)
    body: str | None = None
    schedule: ReminderScheduleIn
    active: bool = True


class ReminderOut(Strict):
    reminder_id: uuid.UUID
    patient_id: uuid.UUID
    title: str
    body: str | None
    schedule: dict[str, Any]
    schedule_version: int
    active: bool
    created_at: datetime
    updated_at: datetime


class OccurrenceIn(Strict):
    scheduled_for: datetime
    schedule_version: int = Field(default=1, ge=1)
    state: Literal["scheduled", "prompted", "cancelled"] = "prompted"
    device_id: str | None = Field(default=None, max_length=128)


class OccurrenceOut(Strict):
    occurrence_id: uuid.UUID
    reminder_id: uuid.UUID
    scheduled_for: datetime
    schedule_version: int
    state: str
    # Deliberately not "taken"/"completed": this is not medication adherence.
    acknowledgement_state: str | None
    acknowledged_at: datetime | None


class AcknowledgeIn(Strict):
    acknowledgement_state: Literal["acknowledged", "postponed", "cancelled"]


# --------------------------------------------------------------------------
# Doctor
# --------------------------------------------------------------------------


class NoteIn(Strict):
    body: str = Field(min_length=1, max_length=8000)


class NoteOut(Strict):
    note_id: uuid.UUID
    patient_id: uuid.UUID
    author_user_id: uuid.UUID
    body: str
    created_at: datetime


class ReportRequestIn(Strict):
    window_days: int = Field(default=30, ge=1, le=365)


class ReportOut(Strict):
    report_id: uuid.UUID
    patient_id: uuid.UUID
    window_days: int
    status: str
    generator: str
    generator_version: str
    source_session_ids: list[uuid.UUID]
    content: dict[str, Any]
    created_at: datetime
