"""Identity, membership and the fail-closed configuration rule."""

from __future__ import annotations

import uuid

import pytest

from app.config import ConfigError, load_settings
from tests.conftest import auth
from tests.helpers import play_full_session, session_body


def test_health_needs_no_identity(client):
    response = client.get("/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["auth_mode"] == "demo"


def test_demo_mode_is_advertised_in_a_header(client):
    # A demo backend must never be mistakable for a real one client-side.
    assert client.get("/v1/health").headers["X-Tesseract-Demo-Mode"] == "true"


def test_missing_token_is_rejected(client):
    response = client.get("/v1/patients")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "identity_required"


def test_malformed_token_is_rejected(client):
    response = client.get("/v1/patients", headers={"Authorization": "Bearer not-a-demo-token"})
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "identity_required"


def test_wrong_auth_scheme_is_rejected(client, caregiver):
    response = client.get("/v1/patients", headers={"Authorization": "Basic demo:caregiver-a"})
    assert response.status_code == 401


def test_every_error_carries_a_stable_code_and_request_id(client):
    response = client.get("/v1/patients")
    error = response.json()["error"]
    assert set(error) == {"code", "message", "request_id", "details"}
    assert response.headers["X-Request-ID"] == error["request_id"]


class TestCrossPatientAccess:
    def test_another_caregiver_cannot_read_the_patient(
        self, client, patient_id, other_caregiver
    ):
        response = client.get(f"/v1/patients/{patient_id}", headers=other_caregiver)
        assert response.status_code == 403
        assert response.json()["error"]["code"] == "no_patient_access"

    def test_another_caregiver_cannot_write_personalization(
        self, client, patient_id, other_caregiver
    ):
        response = client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=other_caregiver,
            json={"version": 1, "personal_words": [{"text": "chai"}]},
        )
        assert response.status_code == 403

    def test_another_caregiver_cannot_create_a_session_for_the_patient(
        self, client, patient_id, other_caregiver
    ):
        response = client.put(
            f"/v1/sessions/{uuid.uuid4()}",
            headers=other_caregiver,
            json=session_body(patient_id),
        )
        assert response.status_code == 403

    def test_another_caregiver_cannot_read_a_session_by_its_direct_id(
        self, client, patient_id, caregiver, other_caregiver
    ):
        # Direct-id access is where this kind of thing actually leaks.
        session_id = play_full_session(client, caregiver, patient_id)
        response = client.get(f"/v1/sessions/{session_id}", headers=other_caregiver)
        assert response.status_code == 403

    def test_another_caregiver_cannot_read_session_metrics_directly(
        self, client, patient_id, caregiver, other_caregiver
    ):
        session_id = play_full_session(client, caregiver, patient_id)
        response = client.get(f"/v1/sessions/{session_id}/metrics", headers=other_caregiver)
        assert response.status_code == 403

    def test_another_caregiver_cannot_read_the_summary(
        self, client, patient_id, other_caregiver
    ):
        response = client.get(f"/v1/patients/{patient_id}/summary", headers=other_caregiver)
        assert response.status_code == 403

    def test_unknown_patient_returns_403_not_404(self, client, caregiver):
        # A 404 here would let a caller enumerate which patient ids exist.
        response = client.get(f"/v1/patients/{uuid.uuid4()}", headers=caregiver)
        assert response.status_code == 403


def test_patient_list_is_scoped_to_the_caller(client, patient_id, caregiver, other_caregiver):
    assert len(client.get("/v1/patients", headers=caregiver).json()) == 1
    assert client.get("/v1/patients", headers=other_caregiver).json() == []


def test_a_caregiver_cannot_promote_themselves_to_doctor(client, caregiver):
    # There is no endpoint that grants the doctor role; provisioning is
    # server-side only.
    response = client.get("/v1/doctor/patients", headers=caregiver)
    assert response.status_code == 403


def test_new_identities_get_separate_users(client):
    client.post("/v1/patients", headers=auth("x"), json={"display_name": "P1"})
    client.post("/v1/patients", headers=auth("y"), json={"display_name": "P2"})
    assert len(client.get("/v1/patients", headers=auth("x")).json()) == 1
    assert len(client.get("/v1/patients", headers=auth("y")).json()) == 1


class TestFailClosedConfiguration:
    def test_demo_auth_is_refused_in_production(self, monkeypatch, tmp_path):
        monkeypatch.setenv("APP_ENV", "production")
        monkeypatch.setenv("AUTH_MODE", "demo")
        monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u@localhost/x")
        with pytest.raises(ConfigError, match="refused when APP_ENV=production"):
            load_settings(env_file=tmp_path / "absent.env")

    def test_firebase_mode_requires_a_credentials_file(self, monkeypatch, tmp_path):
        monkeypatch.setenv("APP_ENV", "production")
        monkeypatch.setenv("AUTH_MODE", "firebase")
        monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u@localhost/x")
        monkeypatch.delenv("FIREBASE_CREDENTIALS_FILE", raising=False)
        with pytest.raises(ConfigError, match="FIREBASE_CREDENTIALS_FILE"):
            load_settings(env_file=tmp_path / "absent.env")

    def test_missing_database_url_is_a_startup_error(self, monkeypatch, tmp_path):
        monkeypatch.setenv("APP_ENV", "development")
        monkeypatch.setenv("AUTH_MODE", "demo")
        monkeypatch.delenv("DATABASE_URL", raising=False)
        with pytest.raises(ConfigError, match="DATABASE_URL"):
            load_settings(env_file=tmp_path / "absent.env")

    def test_enabling_the_llm_without_a_key_is_a_startup_error(self, monkeypatch, tmp_path):
        monkeypatch.setenv("APP_ENV", "development")
        monkeypatch.setenv("AUTH_MODE", "demo")
        monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u@localhost/x")
        monkeypatch.setenv("LLM_ENABLED", "true")
        monkeypatch.delenv("LLM_API_KEY", raising=False)
        with pytest.raises(ConfigError, match="LLM_MODEL and LLM_API_KEY"):
            load_settings(env_file=tmp_path / "absent.env")
