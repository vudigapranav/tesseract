"""One error shape for the whole API.

Clients branch on `code`, never on `message`. Every response carries the
request id, which also appears in the server log line for that request.
"""

from __future__ import annotations

from typing import Any

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class ApiError(Exception):
    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.code = code
        self.message = message
        self.details = details or {}


def identity_required(message: str = "A valid identity token is required.") -> ApiError:
    return ApiError(401, "identity_required", message)


def no_patient_access() -> ApiError:
    # Deliberately identical whether or not the patient exists: a 404 here
    # would let a caller enumerate patient ids.
    return ApiError(403, "no_patient_access", "You do not have access to this patient.")


def not_found(what: str = "Resource") -> ApiError:
    return ApiError(404, "not_found", f"{what} was not found.")


def invalid_data(message: str, details: dict[str, Any] | None = None) -> ApiError:
    return ApiError(422, "invalid_data", message, details)


def revision_conflict(expected: int, received: int) -> ApiError:
    return ApiError(
        409,
        "revision_conflict",
        "This record changed since you last read it. Re-read and retry.",
        {"expected": expected, "received": received},
    )


def _payload(code: str, message: str, request_id: str, details: dict[str, Any]) -> dict[str, Any]:
    return {
        "error": {
            "code": code,
            "message": message,
            "request_id": request_id,
            "details": details,
        }
    }


def _request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "unknown")


async def api_error_handler(request: Request, exc: ApiError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=_payload(exc.code, exc.message, _request_id(request), exc.details),
        headers={"X-Request-ID": _request_id(request)},
    )


async def validation_error_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    fields = [
        {"field": ".".join(str(p) for p in err.get("loc", ())), "problem": err.get("msg", "")}
        for err in exc.errors()
    ]
    return JSONResponse(
        status_code=422,
        content=_payload(
            "invalid_data",
            "The request body did not match the expected schema.",
            _request_id(request),
            {"fields": fields},
        ),
        headers={"X-Request-ID": _request_id(request)},
    )


async def http_error_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    code = {401: "identity_required", 403: "no_patient_access", 404: "not_found"}.get(
        exc.status_code, "request_failed"
    )
    return JSONResponse(
        status_code=exc.status_code,
        content=_payload(code, str(exc.detail), _request_id(request), {}),
        headers={"X-Request-ID": _request_id(request)},
    )
