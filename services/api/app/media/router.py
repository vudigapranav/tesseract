"""Private patient media. Membership-checked on upload and on every read."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import Response
from sqlalchemy import select
from sqlalchemy.orm import Session as DbSession

from ..auth.dependencies import (
    caregiver_has_access,
    current_user,
    doctor_has_access,
    require_caregiver_access,
)
from ..config import Settings, get_settings
from ..db import get_db
from ..errors import invalid_data, no_patient_access, not_found
from ..models import MediaAsset, Patient, User
from .storage import LocalMediaStorage, content_sha256

router = APIRouter(prefix="/v1", tags=["media"])

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


def _storage(settings: Settings) -> LocalMediaStorage:
    return LocalMediaStorage(settings.media_root)


@router.post("/patients/{patient_id}/media", status_code=201)
async def upload_media(
    file: UploadFile = File(...),
    patient: Patient = Depends(require_caregiver_access),
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict:
    content = await file.read()
    if not content:
        raise invalid_data("The uploaded file is empty.")
    if len(content) > settings.media_max_bytes:
        raise invalid_data(
            "The uploaded file is too large.",
            {"max_bytes": settings.media_max_bytes, "received_bytes": len(content)},
        )
    content_type = (file.content_type or "").split(";")[0].strip()
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise invalid_data(
            "Unsupported media type.",
            {"allowed": sorted(ALLOWED_CONTENT_TYPES), "received": content_type},
        )

    digest = content_sha256(content)
    # Re-uploading identical bytes for the same patient returns the existing
    # asset rather than storing a second copy.
    existing = db.scalar(
        select(MediaAsset).where(
            MediaAsset.patient_id == patient.id, MediaAsset.content_sha256 == digest
        )
    )
    if existing is not None:
        return {
            "media_asset_id": str(existing.id),
            "url": f"/v1/media/{existing.id}",
            "duplicate": True,
        }

    storage_key = _storage(settings).put(patient.id, content, content_type)
    asset = MediaAsset(
        patient_id=patient.id,
        storage_key=storage_key,
        content_type=content_type,
        byte_size=len(content),
        content_sha256=digest,
        uploaded_by_user_id=user.id,
    )
    db.add(asset)
    db.flush()
    return {"media_asset_id": str(asset.id), "url": f"/v1/media/{asset.id}", "duplicate": False}


@router.get("/media/{media_asset_id}")
def get_media(
    media_asset_id: uuid.UUID,
    user: User = Depends(current_user),
    db: DbSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> Response:
    asset = db.get(MediaAsset, media_asset_id)
    if asset is None:
        raise not_found("Media asset")

    # The same membership rule as every other patient-scoped route. A direct
    # asset id is not a bypass.
    allowed = (
        doctor_has_access(db, user, asset.patient_id)
        if user.role == "doctor"
        else caregiver_has_access(db, user, asset.patient_id)
    )
    if not allowed:
        raise no_patient_access()

    try:
        content = _storage(settings).get(asset.storage_key)
    except FileNotFoundError:
        raise not_found("Media file") from None

    return Response(
        content=content,
        media_type=asset.content_type,
        headers={"Cache-Control": "private, no-store"},
    )
