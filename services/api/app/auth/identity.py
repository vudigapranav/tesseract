"""Identity verification.

Two modes, chosen by configuration and never by a request:

* ``firebase`` — verifies a real Firebase ID token.
* ``demo``     — accepts ``demo:<auth_uid>``, for local development and the
  synthetic demo. Refused outright when ``APP_ENV=production`` (see
  ``config.load_settings``), so it cannot be reached by accident.

A token is never logged, echoed in an error, or included in an LLM prompt.
"""

from __future__ import annotations

from dataclasses import dataclass

from ..config import Settings
from ..errors import identity_required


@dataclass(frozen=True)
class VerifiedIdentity:
    auth_uid: str
    display_name: str | None
    source: str


class IdentityVerifier:
    def verify(self, bearer_token: str) -> VerifiedIdentity:  # pragma: no cover - interface
        raise NotImplementedError


class DemoIdentityVerifier(IdentityVerifier):
    """Synthetic identities. Development and demo only."""

    PREFIX = "demo:"

    def verify(self, bearer_token: str) -> VerifiedIdentity:
        if not bearer_token.startswith(self.PREFIX):
            raise identity_required(
                "Demo mode expects a token of the form 'demo:<auth_uid>'."
            )
        auth_uid = bearer_token[len(self.PREFIX) :].strip()
        if not auth_uid:
            raise identity_required("Demo token is missing an auth uid.")
        return VerifiedIdentity(auth_uid=f"demo-{auth_uid}", display_name=auth_uid, source="demo")


class FirebaseIdentityVerifier(IdentityVerifier):
    def __init__(self, settings: Settings) -> None:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.firebase_credentials_file)
            firebase_admin.initialize_app(cred)

    def verify(self, bearer_token: str) -> VerifiedIdentity:
        from firebase_admin import auth as firebase_auth

        try:
            decoded = firebase_auth.verify_id_token(bearer_token)
        except Exception as exc:  # noqa: BLE001 - provider raises several types
            # The token itself is never included in the message.
            raise identity_required(
                f"Identity token could not be verified ({type(exc).__name__})."
            ) from exc
        uid = decoded.get("uid")
        if not uid:
            raise identity_required("Identity token contained no uid.")
        return VerifiedIdentity(
            auth_uid=uid, display_name=decoded.get("name"), source="firebase"
        )


def build_verifier(settings: Settings) -> IdentityVerifier:
    if settings.auth_mode == "firebase":
        return FirebaseIdentityVerifier(settings)
    if settings.auth_mode == "demo":
        if settings.is_production:  # defence in depth; config already refuses this
            raise RuntimeError("Demo identity verifier requested in production.")
        return DemoIdentityVerifier()
    raise RuntimeError(f"Unsupported auth mode {settings.auth_mode!r}.")
