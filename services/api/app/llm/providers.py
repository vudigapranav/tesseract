"""LLM providers.

A provider does one thing: turn a system prompt and a user prompt into text.
It has no opinion about what the text means. Everything that matters — that the
facts are de-identified, that the model may only rephrase numbers we supplied,
that any failure falls back to the deterministic template — lives in
``summarize.py`` and applies to every provider equally.

Credentials
-----------
The key is read from ``LLM_API_KEY`` on the server and never leaves it. It is
sent in the ``x-goog-api-key`` header rather than a query string, so it cannot
end up in an access log or a proxy's URL history. No error raised here carries
a response body, a URL with parameters, or the key: callers get an exception
type and, at most, an HTTP status class.
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from typing import Any

from ..config import Settings

# Google's Interactions API — the surface their current documentation uses for
# the Gemini 3 family. Chosen over models.generateContent for one concrete
# reason: it returns the model's reasoning as separate ``thought`` steps, so
# the answer can be read without the drafting attached. On generateContent, a
# Gemini 3 model's internal drafting arrived mixed into the text and was
# truncated mid-sentence by the output cap.
#
# The version is pinned deliberately: a silent upgrade would change model
# behaviour under reports that have already been shown to a doctor.
GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/interactions"


class LlmProviderError(RuntimeError):
    """Base for provider failures. Its message is safe to record."""


class LlmAuthError(LlmProviderError):
    """The key was rejected. Never says which key, or any part of it."""


class LlmRequestError(LlmProviderError):
    """Transport, timeout, or a non-2xx that is not an auth failure."""


class LlmResponseError(LlmProviderError):
    """A 2xx whose body was not the shape the API documents."""


class GeminiProvider:
    """Google Gemini via the documented ``models.generateContent`` endpoint.

    The model id is configuration (``LLM_MODEL``), not a constant here, so the
    deployment picks a model that is current at the time it runs rather than a
    model that was current when this file was written.

    Only ``urllib`` is used, so enabling summaries adds no dependency to the
    service. The call is blocking; FastAPI runs the report endpoint in a
    threadpool, so it does not occupy the event loop.
    """

    def __init__(self, api_key: str, model: str) -> None:
        if not api_key or not model:
            raise LlmProviderError("GeminiProvider requires both an API key and a model id.")
        self._api_key = api_key
        self._model = model

    def complete(self, system: str, user: str, timeout_seconds: int) -> str:
        body = json.dumps(
            {
                "model": self._model,
                "system_instruction": system,
                "input": user,
                "generation_config": {
                    # Low temperature: the task is rephrasing supplied facts,
                    # not writing. Anything inventive gets rejected downstream
                    # anyway, and a rejection costs the caregiver their summary.
                    "temperature": 0.2,
                    # Rephrasing three sentences needs no deliberation, and
                    # thinking is what pushed this call past its timeout.
                    "thinking_level": "low",
                    "max_output_tokens": 1024,
                },
            }
        ).encode("utf-8")

        request = urllib.request.Request(
            GEMINI_ENDPOINT,
            data=body,
            method="POST",
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": self._api_key,
            },
        )

        try:
            with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
                payload = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            # The body may quote the request, so it is not repeated. Status
            # alone is enough to tell a bad key from an outage.
            if exc.code in (401, 403):
                raise LlmAuthError(
                    "The LLM provider rejected the configured credentials."
                ) from None
            raise LlmRequestError(f"The LLM provider returned HTTP {exc.code}.") from None
        except urllib.error.URLError as exc:
            raise LlmRequestError(
                f"Could not reach the LLM provider: {type(exc).__name__}."
            ) from None
        except json.JSONDecodeError:
            raise LlmResponseError("The LLM provider returned a body that was not JSON.") from None
        except TimeoutError:
            raise LlmRequestError("The LLM provider did not respond in time.") from None

        return _model_output_text(payload)


def _model_output_text(payload: dict[str, Any]) -> str:
    """Pulls the answer out of an Interactions response.

    Only ``model_output`` steps count. ``thought`` steps are the model's
    private reasoning: including them would put half-finished drafting in front
    of a caregiver, and would feed stray numbers to the validator.

    Raises rather than returning '' when the shape is unfamiliar. An empty
    string would be rejected downstream as ``empty_response`` and quietly fall
    back to the template — hiding a real integration problem behind a feature
    that still appears to work.
    """
    steps = payload.get("steps")
    if not isinstance(steps, list) or not steps:
        status = payload.get("status")
        raise LlmResponseError(f"The LLM provider returned no steps (status={status}).")

    chunks: list[str] = []
    for step in steps:
        if not isinstance(step, dict) or step.get("type") != "model_output":
            continue
        for item in step.get("content") or []:
            if isinstance(item, dict) and item.get("type") == "text":
                chunks.append(str(item.get("text", "")))

    text = "".join(chunks)
    if not text.strip():
        kinds = sorted({s.get("type") for s in steps if isinstance(s, dict)})
        raise LlmResponseError(
            f"The LLM provider returned no model output (steps present: {kinds})."
        )
    return text


PROVIDERS = {"gemini": GeminiProvider}


def provider_for(settings: Settings) -> Any | None:
    """The configured provider, or None to use the deterministic template.

    Returns None — rather than raising — whenever summaries are switched off or
    unconfigured, because a missing summary provider must never turn into a
    failed report. An unknown ``LLM_PROVIDER`` while ``LLM_ENABLED=true`` does
    raise: that is a deployment mistake, and silently producing template text
    under a configuration that asked for a model would hide it.
    """
    if not settings.llm_enabled:
        return None
    if not (settings.llm_api_key and settings.llm_model):
        return None

    name = (settings.llm_provider or "").lower()
    factory = PROVIDERS.get(name)
    if factory is None:
        raise LlmProviderError(
            f"LLM_ENABLED=true but LLM_PROVIDER={settings.llm_provider!r} is not implemented. "
            f"Known providers: {', '.join(sorted(PROVIDERS))}."
        )
    return factory(settings.llm_api_key, settings.llm_model)
