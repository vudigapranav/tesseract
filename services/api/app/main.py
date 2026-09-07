"""Application factory."""

from __future__ import annotations

import logging
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from sqlalchemy import text
from starlette.exceptions import HTTPException as StarletteHTTPException

from .analytics.router import router as analytics_router
from .auth.identity import build_verifier
from .config import APP_VERSION, Settings, get_settings
from .db import get_engine
from .doctor.router import router as doctor_router
from .errors import ApiError, api_error_handler, http_error_handler, validation_error_handler
from .media.router import router as media_router
from .patients.router import router as patients_router
from .recommendations.router import router as recommendations_router
from .reminders.router import router as reminders_router
from .sessions.router import router as sessions_router

logger = logging.getLogger("tesseract.api")


@asynccontextmanager
async def _lifespan(app: FastAPI):
    settings: Settings = app.state.settings
    # Built once at startup, so a missing/invalid credential is a startup
    # failure rather than a per-request surprise.
    app.state.identity_verifier = build_verifier(settings)
    if settings.is_demo_auth:
        logger.warning(
            "AUTH_MODE=demo: synthetic identities are accepted. "
            "Development and demo only; refused when APP_ENV=production."
        )
    yield


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    logging.basicConfig(level=getattr(logging, settings.log_level, logging.INFO))

    app = FastAPI(
        title="Tesseract API",
        version=APP_VERSION,
        lifespan=_lifespan,
    )
    app.state.settings = settings

    app.add_exception_handler(ApiError, api_error_handler)
    app.add_exception_handler(RequestValidationError, validation_error_handler)
    app.add_exception_handler(StarletteHTTPException, http_error_handler)

    @app.middleware("http")
    async def _request_context(request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        if settings.is_demo_auth:
            # A demo backend must be obvious from the client side.
            response.headers["X-Tesseract-Demo-Mode"] = "true"
        return response

    @app.get("/v1/health")
    def health() -> dict[str, object]:
        database = "ok"
        revision = None
        try:
            with get_engine().connect() as conn:
                conn.execute(text("select 1"))
                try:
                    revision = conn.exec_driver_sql(
                        "select version_num from alembic_version"
                    ).scalar()
                except Exception:  # noqa: BLE001
                    # No migration table yet. The database is reachable, which
                    # is what this check is for; the revision is just unknown.
                    revision = None
        except Exception as exc:  # noqa: BLE001
            logger.error("health check database failure: %s", type(exc).__name__)
            database = "unavailable"

        if database != "ok":
            raise ApiError(
                503, "dependency_unavailable", "The database is not reachable.",
                {"database": database},
            )

        return {
            "status": "ok",
            "version": APP_VERSION,
            "app_env": settings.app_env,
            "auth_mode": settings.auth_mode,
            "database": database,
            "migration_revision": revision,
        }

    app.include_router(patients_router)
    app.include_router(media_router)
    app.include_router(sessions_router)
    app.include_router(analytics_router)
    app.include_router(recommendations_router)
    app.include_router(reminders_router)
    app.include_router(doctor_router)
    return app
