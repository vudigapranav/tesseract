"""Vercel serverless entry point for the Tesseract API.

Vercel's Python runtime looks for a module-level ASGI application called
``app``. Everything else about the service is unchanged — this file adds a way
to *host* the existing app, not a second version of it.

Read `../VERCEL.md` before deploying. There are real constraints: the service
expects a PostgreSQL database and a Firebase service-account file, and neither
is satisfied by dropping this on Vercel without configuration.
"""

from __future__ import annotations

import sys
from pathlib import Path

# The function's working directory is not the project root, so the package the
# app lives in has to be findable explicitly.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import create_app  # noqa: E402

app = create_app()
