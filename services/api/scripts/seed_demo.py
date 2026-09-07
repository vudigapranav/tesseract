"""Seed a synthetic caregiver, patient and session history.

Everything created here is synthetic. It exists so the demo can show a real
recommendation produced by real stored sessions, rather than a mock.

    .venv/bin/python scripts/seed_demo.py
"""

from __future__ import annotations

import sys
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.main import create_app  # noqa: E402

CAREGIVER_TOKEN = "demo:demo-caregiver"
HEADERS = {"Authorization": f"Bearer {CAREGIVER_TOKEN}"}


def _event(seq: int, type_: str, elapsed_ms: int, payload: dict | None = None) -> dict:
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


def _route_quest_events() -> list[dict]:
    events = [_event(1, "session_started", 0)]
    seq, elapsed = 2, 0
    for node in ("n1", "n2", "n3"):
        elapsed += 1200
        events.append(_event(seq, "location_entered", elapsed, {"nodeId": node}))
        seq += 1
    elapsed += 300
    events.append(_event(seq, "destination_reached", elapsed))
    seq += 1
    events.append(_event(seq, "item_collected", elapsed))
    seq += 1
    for node in ("n2", "n1", "n0"):
        elapsed += 1100
        events.append(_event(seq, "location_entered", elapsed, {"nodeId": node}))
        seq += 1
    events.append(_event(seq, "return_completed", elapsed))
    seq += 1
    events.append(_event(seq, "session_finished", elapsed, {"status": "completed"}))
    return events


def main() -> None:
    settings = get_settings()
    if settings.is_production:
        raise SystemExit("Refusing to seed synthetic demo data into a production environment.")

    with TestClient(create_app(settings)) as client:
        patient = client.post(
            "/v1/patients",
            headers=HEADERS,
            json={
                "display_name": "Synthetic Demo Patient",
                "language": "en",
                "accessibility": {"text_scale": 1.5, "reduced_motion": False},
            },
        )
        patient.raise_for_status()
        patient_id = patient.json()["patient_id"]

        client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=HEADERS,
            json={
                "version": 1,
                "personal_words": [
                    {"text": word} for word in ("chai", "garden", "temple", "radio")
                ],
                "people_places": [
                    {"kind": "person", "label": "Synthetic Daughter"},
                    {"kind": "place", "label": "Synthetic Market"},
                ],
                "preferences": {"prefers_images_over_words": True},
            },
        ).raise_for_status()

        client.post(
            f"/v1/patients/{patient_id}/reminders",
            headers=HEADERS,
            json={
                "title": "Afternoon walk",
                "body": "A short walk after tea.",
                "schedule": {
                    "kind": "daily",
                    "times": ["16:00"],
                    "weekdays": [],
                    "timezone": "Asia/Kolkata",
                },
                "active": True,
            },
        ).raise_for_status()

        for index in range(3):
            session_id = str(uuid.uuid4())
            events = _route_quest_events()
            client.put(
                f"/v1/sessions/{session_id}",
                headers=HEADERS,
                json={
                    "patient_id": patient_id,
                    "game_id": "route_quest",
                    "game_version": "1.0.0",
                    "level": 1,
                    "difficulty_params": {
                        "nodeCount": 5, "branchCount": 1, "requiresReturn": True
                    },
                    "requested_input_mode": "touch",
                    "actual_input_mode": "touch",
                    "is_tutorial": False,
                    "started_at": datetime.now(timezone.utc).isoformat(),
                },
            ).raise_for_status()
            client.post(
                f"/v1/sessions/{session_id}/events:batch",
                headers=HEADERS,
                json={"events": events},
            ).raise_for_status()
            client.post(
                f"/v1/sessions/{session_id}/complete",
                headers=HEADERS,
                json={
                    "status": "completed",
                    "final_seq": max(e["seq"] for e in events),
                    "assisted": False,
                    "ended_at": datetime.now(timezone.utc).isoformat(),
                },
            ).raise_for_status()
            print(f"  seeded session {index + 1}: {session_id}")

        pending = client.get(
            f"/v1/patients/{patient_id}/recommendations?status=pending", headers=HEADERS
        ).json()["items"]

    print()
    print("Synthetic demo data seeded.")
    print(f"  patient_id : {patient_id}")
    print(f"  token      : {CAREGIVER_TOKEN}")
    print(f"  pending recommendations: {len(pending)}")
    if pending:
        proposal = pending[0]
        print(f"  proposal   : level {proposal['current_config']['level']} "
              f"-> {proposal['proposed_config']['level']} ({proposal['reason']['code']})")
        print(f"  decide with: POST /v1/recommendations/{proposal['recommendation_id']}/decision")


if __name__ == "__main__":
    main()
