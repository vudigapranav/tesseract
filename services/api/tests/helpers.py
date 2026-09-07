"""Synthetic session builders. No real patient data anywhere in the suite."""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone


def session_body(patient_id: str, **overrides) -> dict:
    body = {
        "patient_id": patient_id,
        "game_id": "route_quest",
        "game_version": "1.0.0",
        "schema_version": "1",
        "config_version": "1",
        "content_version": "1",
        "metric_version": "1",
        "level": 1,
        "difficulty_params": {"nodeCount": 5, "branchCount": 1, "requiresReturn": True},
        "requested_input_mode": "touch",
        "actual_input_mode": "touch",
        "is_tutorial": False,
        "text_scale": 1.0,
        "locale": "en",
        "started_at": datetime.now(timezone.utc).isoformat(),
    }
    body.update(overrides)
    return body


def event(seq: int, type_: str, elapsed_ms: int, payload: dict | None = None) -> dict:
    return {
        "event_id": str(uuid.uuid4()),
        "seq": seq,
        "type": type_,
        "elapsed_ms": elapsed_ms,
        "occurred_at": (
            datetime.now(timezone.utc) + timedelta(milliseconds=elapsed_ms)
        ).isoformat(),
        "payload": payload or {},
    }


def route_quest_events(*, completed: bool = True, hints: int = 0, wrong: int = 0) -> list[dict]:
    """A plausible Route Quest session, in the game's real event vocabulary."""
    events = [event(1, "session_started", 0)]
    seq = 2
    elapsed = 0

    for _ in range(hints):
        elapsed += 500
        events.append(event(seq, "hint_requested", elapsed))
        seq += 1

    for _ in range(wrong):
        elapsed += 400
        events.append(event(seq, "wrong_interaction", elapsed, {"objectId": "n9"}))
        seq += 1

    for node in ("n1", "n2", "n3"):
        elapsed += 1200
        events.append(event(seq, "location_entered", elapsed, {"nodeId": node}))
        seq += 1

    if completed:
        elapsed += 300
        events.append(event(seq, "destination_reached", elapsed))
        seq += 1
        events.append(event(seq, "item_collected", elapsed))
        seq += 1
        for node in ("n2", "n1", "n0"):
            elapsed += 1100
            events.append(event(seq, "location_entered", elapsed, {"nodeId": node}))
            seq += 1
        events.append(event(seq, "return_completed", elapsed))
        seq += 1

    events.append(
        event(
            seq,
            "session_finished",
            elapsed,
            {"status": "completed" if completed else "stopped_by_user"},
        )
    )
    return events


def marble_maze_events() -> list[dict]:
    """Includes a continuous scrape against one wall, which must debounce to
    a single contact episode."""
    return [
        event(1, "session_started", 0),
        event(2, "collision", 1000, {"wallId": "w1"}),
        event(3, "collision", 1150, {"wallId": "w1"}),
        event(4, "collision", 1300, {"wallId": "w1"}),
        event(5, "collision", 4000, {"wallId": "w2"}),
        event(6, "dead_end_entered", 5000, {"cellId": "c7"}),
        event(7, "dead_end_entered", 5200, {"cellId": "c7"}),
        event(8, "goal_reached", 9000),
        event(9, "session_finished", 9000, {"status": "completed"}),
    ]


def play_full_session(
    client,
    headers: dict,
    patient_id: str,
    *,
    events: list[dict] | None = None,
    status: str = "completed",
    assisted: bool = False,
    **session_overrides,
) -> str:
    """Create -> events -> complete. Returns the session id."""
    session_id = str(uuid.uuid4())
    body = session_body(patient_id, **session_overrides)

    created = client.put(f"/v1/sessions/{session_id}", headers=headers, json=body)
    assert created.status_code in (200, 201), created.text

    payload = events if events is not None else route_quest_events()
    batch = client.post(
        f"/v1/sessions/{session_id}/events:batch", headers=headers, json={"events": payload}
    )
    assert batch.status_code == 200, batch.text

    done = client.post(
        f"/v1/sessions/{session_id}/complete",
        headers=headers,
        json={
            "status": status,
            "final_seq": max(e["seq"] for e in payload),
            "assisted": assisted,
            "ended_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    assert done.status_code == 200, done.text
    return session_id
