"""Validated configuration, loaded once at import.

Fails closed: an invalid or unsafe combination raises at startup rather than
degrading into an insecure default at request time.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

APP_VERSION = "0.1.0"

_ENVS = ("development", "test", "production")
# Providers implemented in app/llm/providers.py. Kept here as literals so
# configuration can be validated at startup without importing the provider
# module (which imports this one).
_LLM_PROVIDERS = ("gemini",)

_AUTH_MODES = ("firebase", "demo")


class ConfigError(RuntimeError):
    """Raised when the environment cannot produce a safe configuration."""


def _load_dotenv(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def _require(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise ConfigError(
            f"{name} is required. Copy services/api/.env.example to .env and set it."
        )
    return value


def _choice(name: str, allowed: tuple[str, ...], default: str | None = None) -> str:
    value = os.environ.get(name, default or "").strip()
    if value not in allowed:
        raise ConfigError(f"{name} must be one of {allowed}, got {value!r}.")
    return value


def _bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None or not raw.strip():
        return default
    return raw.strip().lower() in ("1", "true", "yes", "on")


def _int(name: str, default: int) -> int:
    raw = os.environ.get(name, "").strip()
    if not raw:
        return default
    try:
        return int(raw)
    except ValueError as exc:
        raise ConfigError(f"{name} must be an integer, got {raw!r}.") from exc


@dataclass(frozen=True)
class Settings:
    app_env: str
    database_url: str
    auth_mode: str
    firebase_credentials_file: str | None
    firebase_project_id: str | None
    media_root: Path
    media_max_bytes: int
    llm_enabled: bool
    llm_provider: str | None
    llm_model: str | None
    llm_api_key: str | None
    llm_timeout_seconds: int
    log_level: str

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def is_demo_auth(self) -> bool:
        return self.auth_mode == "demo"


def load_settings(env_file: Path | None = None) -> Settings:
    _load_dotenv(env_file or Path(__file__).resolve().parents[1] / ".env")

    app_env = _choice("APP_ENV", _ENVS, "development")
    auth_mode = _choice("AUTH_MODE", _AUTH_MODES)

    # Fail closed. Synthetic identities must never be reachable in production.
    if app_env == "production" and auth_mode == "demo":
        raise ConfigError(
            "AUTH_MODE=demo is refused when APP_ENV=production. "
            "Demo mode accepts synthetic tokens and grants access without "
            "verifying identity. Set AUTH_MODE=firebase."
        )

    firebase_credentials_file = os.environ.get("FIREBASE_CREDENTIALS_FILE", "").strip() or None
    firebase_project_id = os.environ.get("FIREBASE_PROJECT_ID", "").strip() or None
    if auth_mode == "firebase" and not firebase_credentials_file:
        raise ConfigError(
            "AUTH_MODE=firebase requires FIREBASE_CREDENTIALS_FILE "
            "(path to a service-account JSON kept outside the repository)."
        )
    if firebase_credentials_file and not Path(firebase_credentials_file).is_file():
        raise ConfigError(
            f"FIREBASE_CREDENTIALS_FILE points at {firebase_credentials_file!r}, "
            "which does not exist or is not readable."
        )

    llm_enabled = _bool("LLM_ENABLED", False)
    llm_api_key = os.environ.get("LLM_API_KEY", "").strip() or None
    llm_model = os.environ.get("LLM_MODEL", "").strip() or None
    llm_provider = os.environ.get("LLM_PROVIDER", "").strip() or None
    if llm_enabled and not (llm_api_key and llm_model):
        raise ConfigError("LLM_ENABLED=true requires LLM_MODEL and LLM_API_KEY.")
    # Checked at startup rather than at request time: a deployment that asks
    # for a provider nobody implemented should fail to boot, not quietly serve
    # template text under a configuration that says otherwise.
    if llm_enabled and (llm_provider or "").lower() not in _LLM_PROVIDERS:
        raise ConfigError(
            f"LLM_ENABLED=true requires LLM_PROVIDER to be one of "
            f"{', '.join(sorted(_LLM_PROVIDERS))} (got {llm_provider!r})."
        )

    media_root = Path(os.environ.get("MEDIA_ROOT", "./var/media").strip()).resolve()

    return Settings(
        app_env=app_env,
        database_url=_require("DATABASE_URL"),
        auth_mode=auth_mode,
        firebase_credentials_file=firebase_credentials_file,
        firebase_project_id=firebase_project_id,
        media_root=media_root,
        media_max_bytes=_int("MEDIA_MAX_BYTES", 5 * 1024 * 1024),
        llm_enabled=llm_enabled,
        llm_provider=llm_provider,
        llm_model=llm_model,
        llm_api_key=llm_api_key,
        llm_timeout_seconds=_int("LLM_TIMEOUT_SECONDS", 20),
        log_level=os.environ.get("LOG_LEVEL", "INFO").strip().upper(),
    )


_settings: Settings | None = None


def get_settings() -> Settings:
    global _settings
    if _settings is None:
        _settings = load_settings()
    return _settings


def reset_settings_cache() -> None:
    """Test hook. Not used by application code."""
    global _settings
    _settings = None
