"""Test harness.

Runs against a real PostgreSQL database (``tesseract_test``) rather than a
mock or SQLite, so the constraints, JSONB behaviour and unique indexes under
test are the ones that will run in the application.

All data here is synthetic.
"""

from __future__ import annotations

import os
import uuid
from pathlib import Path

import pytest

os.environ.setdefault("APP_ENV", "test")
os.environ.setdefault(
    "DATABASE_URL", "postgresql+psycopg://pranav07vudiga@localhost:5432/tesseract_test"
)
os.environ.setdefault("AUTH_MODE", "demo")
os.environ.setdefault("MEDIA_ROOT", "./var/test-media")
os.environ.setdefault("LLM_ENABLED", "false")

from fastapi.testclient import TestClient  # noqa: E402

from app import config as config_module  # noqa: E402
from app.db import get_engine, get_session_factory  # noqa: E402
from app.main import create_app  # noqa: E402
from app.models import Base  # noqa: E402

TEST_ENV_FILE = Path(__file__).resolve().parent / "does-not-exist.env"


@pytest.fixture(scope="session", autouse=True)
def _settings():
    # Load from the process environment above, not the developer's local .env.
    config_module._settings = config_module.load_settings(env_file=TEST_ENV_FILE)
    return config_module._settings


@pytest.fixture(scope="session", autouse=True)
def _schema(_settings):
    """Build the test database from the real migrations.

    Using ``create_all`` here would let a broken migration pass the suite. The
    schema under test is the one Alembic actually produces.
    """
    from alembic import command
    from alembic.config import Config
    from sqlalchemy import text

    engine = get_engine()
    with engine.begin() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public;"))

    root = Path(__file__).resolve().parents[1]
    alembic_cfg = Config(str(root / "alembic.ini"))
    alembic_cfg.set_main_option("script_location", str(root / "migrations"))
    command.upgrade(alembic_cfg, "head")
    yield


@pytest.fixture(autouse=True)
def _clean_tables(_schema):
    from sqlalchemy import text

    engine = get_engine()
    names = ", ".join(f'"{t.name}"' for t in reversed(Base.metadata.sorted_tables))
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE {names} RESTART IDENTITY CASCADE"))
    yield


@pytest.fixture
def app(_settings):
    return create_app(_settings)


@pytest.fixture
def client(app):
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def db():
    session = get_session_factory()()
    try:
        yield session
        session.commit()
    finally:
        session.close()


def auth(uid: str) -> dict[str, str]:
    """Headers for a synthetic caregiver identity."""
    return {"Authorization": f"Bearer demo:{uid}"}


@pytest.fixture
def caregiver() -> dict[str, str]:
    return auth("caregiver-a")


@pytest.fixture
def other_caregiver() -> dict[str, str]:
    return auth("caregiver-b")


@pytest.fixture
def patient_id(client, caregiver) -> str:
    response = client.post(
        "/v1/patients",
        headers=caregiver,
        json={"display_name": "Synthetic Patient A", "language": "en"},
    )
    assert response.status_code == 201, response.text
    return response.json()["patient_id"]


def new_uuid() -> str:
    return str(uuid.uuid4())
