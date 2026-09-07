"""Server truth. PostgreSQL schema for Tesseract.

Naming follows the API contract (docs/contracts/PS003_API_CONTRACT_V1.md) so a
column and its wire field never drift apart.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


def _uuid_pk() -> Mapped[uuid.UUID]:
    return mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)


def _created_at() -> Mapped[datetime]:
    return mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class User(Base):
    """A caregiver or doctor, keyed by their verified identity-provider UID."""

    __tablename__ = "users"

    id: Mapped[uuid.UUID] = _uuid_pk()
    auth_uid: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    role: Mapped[str] = mapped_column(String(32), nullable=False, default="caregiver")
    display_name: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = _created_at()

    __table_args__ = (
        CheckConstraint("role in ('caregiver', 'doctor')", name="ck_users_role"),
    )


class Patient(Base):
    __tablename__ = "patients"

    id: Mapped[uuid.UUID] = _uuid_pk()
    display_name: Mapped[str] = mapped_column(String(255), nullable=False)
    language: Mapped[str] = mapped_column(String(16), nullable=False, default="en")

    # Caregiver-entered clinical context. Optional, always. Never an input to
    # difficulty, metrics or recommendations.
    known_type: Mapped[str | None] = mapped_column(String(64))
    known_stage: Mapped[str | None] = mapped_column(String(64))

    accessibility: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    preferences: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)

    # Bumped on every personalization write; clients send it back for
    # optimistic concurrency so a stale editor cannot silently overwrite.
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    created_at: Mapped[datetime] = _created_at()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


class CaregiverPatient(Base):
    """Membership. The only thing that grants a caregiver access to a patient."""

    __tablename__ = "caregiver_patients"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("patients.id", ondelete="CASCADE"), primary_key=True
    )
    role: Mapped[str] = mapped_column(String(32), nullable=False, default="owner")
    created_at: Mapped[datetime] = _created_at()

    __table_args__ = (
        CheckConstraint("role in ('owner', 'member')", name="ck_caregiver_patients_role"),
    )


class DoctorAssignment(Base):
    """Assignment is the only path by which a doctor may read a patient."""

    __tablename__ = "doctor_assignments"

    id: Mapped[uuid.UUID] = _uuid_pk()
    doctor_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False
    )
    assigned_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    assigned_at: Mapped[datetime] = _created_at()
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    __table_args__ = (
        UniqueConstraint("doctor_user_id", "patient_id", name="uq_doctor_assignment"),
    )


class PersonalWord(Base):
    __tablename__ = "personal_words"

    id: Mapped[uuid.UUID] = _uuid_pk()
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    text: Mapped[str] = mapped_column(String(128), nullable=False)
    locale: Mapped[str] = mapped_column(String(16), nullable=False, default="en")
    position: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = _created_at()


class KnownEntry(Base):
    """Know Me people and places."""

    __tablename__ = "known_entries"

    id: Mapped[uuid.UUID] = _uuid_pk()
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    kind: Mapped[str] = mapped_column(String(32), nullable=False)
    label: Mapped[str] = mapped_column(String(255), nullable=False)
    media_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("media_assets.id", ondelete="SET NULL")
    )
    position: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = _created_at()

    __table_args__ = (
        CheckConstraint("kind in ('person', 'place')", name="ck_known_entries_kind"),
    )


class MediaAsset(Base):
    """Patient-owned private media. Never served without a membership check."""

    __tablename__ = "media_assets"

    id: Mapped[uuid.UUID] = _uuid_pk()
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    storage_key: Mapped[str] = mapped_column(String(512), nullable=False)
    content_type: Mapped[str] = mapped_column(String(128), nullable=False)
    byte_size: Mapped[int] = mapped_column(BigInteger, nullable=False)
    content_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    uploaded_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = _created_at()

    __table_args__ = (
        UniqueConstraint("patient_id", "content_sha256", name="uq_media_patient_content"),
    )


class Session(Base):
    """One play session. `id` is the UUID the device generated."""

    __tablename__ = "sessions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    game_id: Mapped[str] = mapped_column(String(64), nullable=False)
    game_version: Mapped[str] = mapped_column(String(32), nullable=False)
    schema_version: Mapped[str] = mapped_column(String(16), nullable=False, default="1")
    config_version: Mapped[str] = mapped_column(String(16), nullable=False, default="1")
    content_version: Mapped[str] = mapped_column(String(16), nullable=False, default="1")
    metric_version: Mapped[str] = mapped_column(String(16), nullable=False, default="1")

    level: Mapped[int] = mapped_column(Integer, nullable=False)
    # The settings actually used, not an Easy/Medium/Hard label. Analytics reads
    # this snapshot, never today's presets.
    difficulty_params: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)

    # Requested vs. actual matter: Marble Maze asks for tilt and silently falls
    # back to touch with no gyroscope. Comparability uses actual only.
    requested_input_mode: Mapped[str] = mapped_column(String(16), nullable=False)
    actual_input_mode: Mapped[str] = mapped_column(String(16), nullable=False)
    input_mode_unverified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    is_tutorial: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    assisted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    text_scale: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    locale: Mapped[str] = mapped_column(String(16), nullable=False, default="en")

    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    final_seq: Mapped[int | None] = mapped_column(Integer)

    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = _created_at()
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    events: Mapped[list["Event"]] = relationship(
        back_populates="session", cascade="all, delete-orphan"
    )

    __table_args__ = (
        CheckConstraint(
            "status in ('open', 'completed', 'stopped_by_user', 'interrupted')",
            name="ck_sessions_status",
        ),
        CheckConstraint(
            "requested_input_mode in ('touch', 'tilt')", name="ck_sessions_requested_input"
        ),
        CheckConstraint("actual_input_mode in ('touch', 'tilt')", name="ck_sessions_actual_input"),
        Index("ix_sessions_patient_game", "patient_id", "game_id", "created_at"),
    )


class Event(Base):
    __tablename__ = "events"

    event_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    seq: Mapped[int] = mapped_column(Integer, nullable=False)
    type: Mapped[str] = mapped_column(String(64), nullable=False)
    elapsed_ms: Mapped[int] = mapped_column(Integer, nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    received_at: Mapped[datetime] = _created_at()

    # Lets a replayed batch tell "same event again" from "different event, same
    # id", which is a real client bug worth surfacing loudly.
    content_hash: Mapped[str] = mapped_column(String(64), nullable=False)

    session: Mapped[Session] = relationship(back_populates="events")

    __table_args__ = (
        UniqueConstraint("session_id", "seq", name="uq_events_session_seq"),
        CheckConstraint("seq >= 1", name="ck_events_seq_positive"),
        CheckConstraint("elapsed_ms >= 0", name="ck_events_elapsed_non_negative"),
    )


class SessionMetric(Base):
    __tablename__ = "session_metrics"

    session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sessions.id", ondelete="CASCADE"), primary_key=True
    )
    metric_version: Mapped[str] = mapped_column(String(16), nullable=False)
    calculator_id: Mapped[str] = mapped_column(String(64), nullable=False)
    # Computed values.
    values: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    # Metrics that could NOT be computed, each with a machine-readable reason.
    # Never fabricate a value here; an absent metric stays absent.
    unavailable: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    computed_at: Mapped[datetime] = _created_at()


class ActivitySetting(Base):
    """The single place an approved activity configuration lives."""

    __tablename__ = "activity_settings"

    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("patients.id", ondelete="CASCADE"), primary_key=True
    )
    game_id: Mapped[str] = mapped_column(String(64), nullable=False)
    level: Mapped[int] = mapped_column(Integer, nullable=False)
    input_mode: Mapped[str] = mapped_column(String(16), nullable=False, default="touch")
    config: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    config_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    approved_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    approved_at: Mapped[datetime] = _created_at()


class Recommendation(Base):
    __tablename__ = "recommendations"

    id: Mapped[uuid.UUID] = _uuid_pk()
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    source_session_ids: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    rule_version: Mapped[str] = mapped_column(String(32), nullable=False)
    proposed_config: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    current_config: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    # Observed values, thresholds used and their review status. Every
    # recommendation must be able to explain itself without recomputation.
    reason: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    based_on_config_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    decided_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    applied_config: Mapped[dict | None] = mapped_column(JSONB)
    created_at: Mapped[datetime] = _created_at()

    __table_args__ = (
        CheckConstraint(
            "status in ('pending', 'accepted', 'modified', 'rejected', 'expired', 'superseded')",
            name="ck_recommendations_status",
        ),
    )


class Reminder(Base):
    """Independent of gameplay. A patient who never opens a game still gets these."""

    __tablename__ = "reminders"

    id: Mapped[uuid.UUID] = _uuid_pk()
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str | None] = mapped_column(Text)
    schedule: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    # Lets a device that was offline detect that the definition changed.
    schedule_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = _created_at()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


class ReminderOccurrence(Base):
    """One scheduled instance. Acknowledgement is NOT medication adherence."""

    __tablename__ = "reminder_occurrences"

    id: Mapped[uuid.UUID] = _uuid_pk()
    reminder_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("reminders.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    scheduled_for: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    schedule_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    state: Mapped[str] = mapped_column(String(32), nullable=False, default="scheduled")
    acknowledgement_state: Mapped[str | None] = mapped_column(String(32))
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    device_id: Mapped[str | None] = mapped_column(String(128))
    created_at: Mapped[datetime] = _created_at()

    __table_args__ = (
        UniqueConstraint("reminder_id", "scheduled_for", name="uq_occurrence_reminder_time"),
        CheckConstraint(
            "state in ('scheduled', 'prompted', 'cancelled')", name="ck_occurrence_state"
        ),
        CheckConstraint(
            "acknowledgement_state is null or acknowledgement_state in "
            "('acknowledged', 'postponed', 'cancelled')",
            name="ck_occurrence_ack_state",
        ),
    )


class DoctorNote(Base):
    """Attributed and immutable. Kept separate from any generated draft."""

    __tablename__ = "doctor_notes"

    id: Mapped[uuid.UUID] = _uuid_pk()
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    author_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
    body: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = _created_at()


class GeneratedReport(Base):
    __tablename__ = "generated_reports"

    id: Mapped[uuid.UUID] = _uuid_pk()
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    requested_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    window_days: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    # 'template' or 'llm'. Recorded so a reader always knows how text was made.
    generator: Mapped[str] = mapped_column(String(32), nullable=False, default="template")
    generator_version: Mapped[str] = mapped_column(String(32), nullable=False, default="report-v1")
    source_session_ids: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    content: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    created_at: Mapped[datetime] = _created_at()
