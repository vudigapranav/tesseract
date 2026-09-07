"""Media storage adapter.

Private patient media (Know Me photos). One interface, one prototype
implementation on the local filesystem. Whatever the implementation, the
membership check happens in the route on **both** upload and read — there is no
public URL and no unauthenticated path to a file.
"""

from __future__ import annotations

import hashlib
import uuid
from pathlib import Path
from typing import Protocol


class MediaStorage(Protocol):
    def put(self, patient_id: uuid.UUID, content: bytes, content_type: str) -> str: ...

    def get(self, storage_key: str) -> bytes: ...

    def delete(self, storage_key: str) -> None: ...


def content_sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


class LocalMediaStorage:
    """Files under ``MEDIA_ROOT``, partitioned by patient.

    Not a production store. It is here so the Know Me flow is real end to end
    without pretending an object store or at-rest encryption exists.
    """

    def __init__(self, root: Path) -> None:
        self._root = root

    def _path(self, storage_key: str) -> Path:
        # storage_key is server-generated ("<patient_uuid>/<uuid>"), never
        # client-supplied, so it cannot escape the root.
        return self._root / storage_key

    def put(self, patient_id: uuid.UUID, content: bytes, content_type: str) -> str:
        storage_key = f"{patient_id}/{uuid.uuid4()}"
        path = self._path(storage_key)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        return storage_key

    def get(self, storage_key: str) -> bytes:
        return self._path(storage_key).read_bytes()

    def delete(self, storage_key: str) -> None:
        self._path(storage_key).unlink(missing_ok=True)
