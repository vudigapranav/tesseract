"""Session creation, event ingestion and completion.

Kept out of the route handlers so the retry/duplicate/gap rules can be tested
without going through HTTP.
"""

from __future__ import annotations

import hashlib
import json
import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session as DbSession

from ..errors import ApiError, invalid_data
from ..models import Event, Session, User
from ..schemas import EventIn, SessionCreate

# Fields frozen at creation. A replay that changes any of them is a client bug
# worth surfacing, not something to silently accept.
IMMUTABLE_FIELDS = (
    "patient_id",
    "game_id",
    "game_version",
    "level",
    "is_tutorial",
    "config_version",
    "content_version",
    "metric_version",
)


def event_content_hash(seq: int, type_: str, elapsed_ms: int, payload: dict) -> str:
    """Identity of an event's *meaning*.

    Only the four fields the game itself produced. ``occurred_at`` is host-added
    wall clock and is deliberately excluded: a retry of the same event must hash
    the same, and re-serialisation must not manufacture a conflict.
    """
    canonical = json.dumps(
        {"seq": seq, "type": type_, "elapsed_ms": elapsed_ms, "payload": payload},
        sort_keys=True,
        separators=(",", ":"),
        default=str,
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _now() -> datetime:
    return datetime.now(timezone.utc)


def session_conflict(fields: list[str]) -> ApiError:
    return ApiError(
        409,
        "session_conflict",
        "This session id already exists with different immutable fields.",
        {"conflicting_fields": fields},
    )


def completion_conflict(stored_status: str, stored_final_seq: int | None) -> ApiError:
    return ApiError(
        409,
        "completion_conflict",
        "This session was already completed with different values.",
        {"stored_status": stored_status, "stored_final_seq": stored_final_seq},
    )


def sequence_gap(missing: list[int], highest: int | None) -> ApiError:
    return ApiError(
        422,
        "sequence_gap",
        "Events are missing. Upload them and call complete again.",
        {"missing_seqs": missing, "highest_stored_seq": highest},
    )


def create_or_get_session(
    db: DbSession, session_id: uuid.UUID, body: SessionCreate, user: User
) -> tuple[Session, bool]:
    """Idempotent create. Returns (session, created)."""
    existing = db.get(Session, session_id)
    if existing is not None:
        incoming = {
            "patient_id": body.patient_id,
            "game_id": body.game_id,
            "game_version": body.game_version,
            "level": body.level,
            "is_tutorial": body.is_tutorial,
            "config_version": body.config_version,
            "content_version": body.content_version,
            "metric_version": body.metric_version,
        }
        conflicting = [f for f in IMMUTABLE_FIELDS if getattr(existing, f) != incoming[f]]
        if conflicting:
            raise session_conflict(conflicting)

        # The device may only discover the gyroscope is missing after the
        # session was created, so actual input mode stays mutable.
        if body.actual_input_mode is not None:
            existing.actual_input_mode = body.actual_input_mode
            existing.input_mode_unverified = False
            db.flush()
        return existing, False

    actual = body.actual_input_mode or body.requested_input_mode
    session = Session(
        id=session_id,
        patient_id=body.patient_id,
        created_by_user_id=user.id,
        game_id=body.game_id,
        game_version=body.game_version,
        schema_version=body.schema_version,
        config_version=body.config_version,
        content_version=body.content_version,
        metric_version=body.metric_version,
        level=body.level,
        difficulty_params=body.difficulty_params,
        requested_input_mode=body.requested_input_mode,
        actual_input_mode=actual,
        # Flagged when the device did not tell us what it really used, so
        # comparability can exclude it rather than silently assuming.
        input_mode_unverified=body.actual_input_mode is None,
        is_tutorial=body.is_tutorial,
        text_scale=body.text_scale,
        locale=body.locale,
        status="open",
        started_at=body.started_at,
    )
    db.add(session)
    db.flush()
    return session, True


def _existing_events(db: DbSession, session_id: uuid.UUID) -> tuple[dict, dict]:
    rows = db.scalars(select(Event).where(Event.session_id == session_id)).all()
    return ({e.event_id: e for e in rows}, {e.seq: e for e in rows})


def ingest_events(
    db: DbSession, session: Session, events: list[EventIn]
) -> dict[str, object]:
    """Accept a batch. Never raises for a per-event problem — each event gets a
    verdict so one bad event cannot discard a good batch."""
    by_id, by_seq = _existing_events(db, session.id)

    accepted: list[uuid.UUID] = []
    duplicate: list[uuid.UUID] = []
    rejected: list[dict] = []
    seen_in_batch: dict[int, uuid.UUID] = {}

    for item in events:
        content_hash = event_content_hash(item.seq, item.type, item.elapsed_ms, item.payload)

        prior = by_id.get(item.event_id)
        if prior is not None:
            if prior.content_hash == content_hash:
                duplicate.append(item.event_id)
            else:
                # Same id, different meaning: real client bug, stays loud.
                rejected.append(
                    {
                        "event_id": item.event_id,
                        "reason": "event_id_conflict",
                        "detail": "This event id is already stored with different content.",
                    }
                )
            continue

        seq_holder = by_seq.get(item.seq)
        if seq_holder is not None:
            rejected.append(
                {
                    "event_id": item.event_id,
                    "reason": "seq_conflict",
                    "detail": f"seq {item.seq} is already held by another event id.",
                }
            )
            continue

        if item.seq in seen_in_batch:
            rejected.append(
                {
                    "event_id": item.event_id,
                    "reason": "seq_conflict",
                    "detail": f"seq {item.seq} appears twice in this batch.",
                }
            )
            continue

        # A finalised session takes no new events. Duplicates were already
        # answered above, so a retry of a delivered batch still succeeds.
        if session.status != "open":
            after_final = session.final_seq is not None and item.seq > session.final_seq
            rejected.append(
                {
                    "event_id": item.event_id,
                    "reason": "after_final_seq" if after_final else "session_closed",
                    "detail": f"Session was finalised at seq {session.final_seq}.",
                }
            )
            continue

        row = Event(
            event_id=item.event_id,
            session_id=session.id,
            seq=item.seq,
            type=item.type,
            elapsed_ms=item.elapsed_ms,
            payload=item.payload,
            occurred_at=item.occurred_at,
            content_hash=content_hash,
        )
        db.add(row)
        by_id[item.event_id] = row
        by_seq[item.seq] = row
        seen_in_batch[item.seq] = item.event_id
        accepted.append(item.event_id)

    db.flush()

    highest = max(by_seq) if by_seq else None
    missing = missing_seqs(set(by_seq), highest) if highest else []
    return {
        "accepted": accepted,
        "duplicate": duplicate,
        "rejected": rejected,
        "highest_seq": highest,
        "missing_seqs": missing,
    }


def missing_seqs(present: set[int], upto: int) -> list[int]:
    return [s for s in range(1, upto + 1) if s not in present]


def complete_session(
    db: DbSession, session: Session, status: str, final_seq: int, assisted: bool,
    ended_at: datetime | None,
) -> bool:
    """Finalise. Returns True when this call performed the completion.

    Idempotent for an identical repeat; a differing repeat is a conflict.
    """
    if session.status != "open":
        if session.status == status and session.final_seq == final_seq:
            return False
        raise completion_conflict(session.status, session.final_seq)

    stored_seqs = set(
        db.scalars(select(Event.seq).where(Event.session_id == session.id)).all()
    )
    highest = max(stored_seqs) if stored_seqs else 0

    if final_seq == 0 or not stored_seqs:
        raise invalid_data(
            "A session cannot be completed with no events.",
            {"stored_events": len(stored_seqs)},
        )

    gaps = missing_seqs(stored_seqs, final_seq)
    if gaps:
        raise sequence_gap(gaps, highest or None)

    if final_seq != highest:
        raise invalid_data(
            "final_seq must equal the highest stored seq.",
            {"final_seq": final_seq, "highest_stored_seq": highest},
        )

    session.status = status
    session.final_seq = final_seq
    session.assisted = assisted
    session.ended_at = ended_at
    session.completed_at = _now()
    db.flush()
    return True


def session_event_count(db: DbSession, session_id: uuid.UUID) -> int:
    return (
        db.scalar(select(func.count()).select_from(Event).where(Event.session_id == session_id))
        or 0
    )
