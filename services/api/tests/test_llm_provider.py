"""Gemini provider.

Offline. Every test stubs the HTTP call, so the suite never spends a token,
never needs a key, and never depends on Google being reachable.

What is checked here is the part that can hurt someone: that the key travels in
a header rather than a URL, that no error message can carry it, and that an
unusual response becomes a loud failure instead of silently empty text.
"""

from __future__ import annotations

import io
import json
import urllib.error

import pytest

from app.llm import providers
from app.llm.providers import (
    GeminiProvider,
    LlmAuthError,
    LlmProviderError,
    LlmRequestError,
    LlmResponseError,
    provider_for,
)

KEY = "synthetic-not-a-real-key"


class FakeSettings:
    def __init__(self, **over):
        self.llm_enabled = True
        self.llm_provider = "gemini"
        self.llm_model = "some-model"
        self.llm_api_key = KEY
        self.llm_timeout_seconds = 8
        self.__dict__.update(over)


def _reply(payload: dict) -> io.BytesIO:
    body = io.BytesIO(json.dumps(payload).encode("utf-8"))
    body.__enter__ = lambda: body  # type: ignore[attr-defined]
    body.__exit__ = lambda *a: None  # type: ignore[attr-defined]
    return body


def _ok(text: str = "Three sessions were recorded.") -> dict:
    return {"steps": [{"type": "model_output", "content": [{"type": "text", "text": text}]}]}


def _capture(monkeypatch, payload: dict | None = None, error: Exception | None = None):
    """Stubs urlopen and hands back the request object the provider built."""
    seen: dict = {}

    def fake_urlopen(request, timeout=None):
        seen["request"] = request
        seen["timeout"] = timeout
        if error is not None:
            raise error
        return _reply(payload if payload is not None else _ok())

    monkeypatch.setattr(providers.urllib.request, "urlopen", fake_urlopen)
    return seen


class TestTheRequest:
    def test_the_key_goes_in_a_header_and_never_in_the_url(self, monkeypatch):
        seen = _capture(monkeypatch)
        GeminiProvider(KEY, "some-model").complete("system", "user", 8)

        request = seen["request"]
        # A key in a query string ends up in access logs and proxy history.
        assert KEY not in request.full_url
        assert "?" not in request.full_url
        assert request.get_header("X-goog-api-key") == KEY

    def test_the_model_comes_from_configuration(self, monkeypatch):
        seen = _capture(monkeypatch)
        GeminiProvider(KEY, "configured-model-id").complete("s", "u", 8)
        body = json.loads(seen["request"].data.decode("utf-8"))
        assert body["model"] == "configured-model-id"

    def test_the_prompts_are_sent_where_the_api_expects_them(self, monkeypatch):
        seen = _capture(monkeypatch)
        GeminiProvider(KEY, "m").complete("SYSTEM RULES", "{\"facts\": 1}", 8)

        body = json.loads(seen["request"].data.decode("utf-8"))
        assert body["system_instruction"] == "SYSTEM RULES"
        assert body["input"] == "{\"facts\": 1}"
        # Rephrasing needs no deliberation, and thinking is what made the call
        # exceed its timeout in practice.
        assert body["generation_config"]["thinking_level"] == "low"

    def test_the_configured_timeout_is_applied(self, monkeypatch):
        seen = _capture(monkeypatch)
        GeminiProvider(KEY, "m").complete("s", "u", 3)
        assert seen["timeout"] == 3

    def test_the_text_is_returned_unchanged(self, monkeypatch):
        _capture(monkeypatch, _ok("Two sessions."))
        assert GeminiProvider(KEY, "m").complete("s", "u", 8) == "Two sessions."

    def test_multiple_text_items_are_joined(self, monkeypatch):
        _capture(
            monkeypatch,
            {
                "steps": [
                    {
                        "type": "model_output",
                        "content": [
                            {"type": "text", "text": "One. "},
                            {"type": "text", "text": "Two."},
                        ],
                    }
                ]
            },
        )
        assert GeminiProvider(KEY, "m").complete("s", "u", 8) == "One. Two."

    def test_the_model_s_private_reasoning_is_left_out(self, monkeypatch):
        # Observed for real: on the older endpoint a Gemini 3 model's drafting
        # came back mixed into the answer and truncated mid-sentence. Thought
        # steps must never reach a caregiver, or the number validator.
        _capture(
            monkeypatch,
            {
                "steps": [
                    {
                        "type": "thought",
                        "content": [{"type": "text", "text": "Draft 1: maybe 99 sessions?"}],
                    },
                    {
                        "type": "model_output",
                        "content": [{"type": "text", "text": "Four sessions were recorded."}],
                    },
                ]
            },
        )
        assert GeminiProvider(KEY, "m").complete("s", "u", 8) == "Four sessions were recorded."


class TestFailures:
    """Every failure must be reportable without leaking anything."""

    @pytest.mark.parametrize("code", [401, 403])
    def test_a_rejected_key_is_an_auth_error_that_does_not_quote_it(self, monkeypatch, code):
        _capture(
            monkeypatch,
            error=urllib.error.HTTPError(
                "https://example.invalid", code, "Forbidden", {}, io.BytesIO(b"API key invalid")
            ),
        )
        with pytest.raises(LlmAuthError) as exc:
            GeminiProvider(KEY, "m").complete("s", "u", 8)
        assert KEY not in str(exc.value)

    def test_a_server_error_reports_only_the_status(self, monkeypatch):
        _capture(
            monkeypatch,
            error=urllib.error.HTTPError(
                "https://example.invalid", 503, "Unavailable", {}, io.BytesIO(b"details")
            ),
        )
        with pytest.raises(LlmRequestError, match="503"):
            GeminiProvider(KEY, "m").complete("s", "u", 8)

    def test_an_unreachable_host_is_a_request_error(self, monkeypatch):
        _capture(monkeypatch, error=urllib.error.URLError("no route"))
        with pytest.raises(LlmRequestError):
            GeminiProvider(KEY, "m").complete("s", "u", 8)

    def test_a_response_with_no_steps_raises_rather_than_returning_nothing(self, monkeypatch):
        # Silently returning '' here would be validated as empty_response and
        # fall back, hiding a real integration problem behind a working report.
        _capture(monkeypatch, {"status": "failed", "steps": []})
        with pytest.raises(LlmResponseError, match="failed"):
            GeminiProvider(KEY, "m").complete("s", "u", 8)

    def test_an_unfamiliar_body_raises(self, monkeypatch):
        _capture(monkeypatch, {"unexpected": True})
        with pytest.raises(LlmResponseError):
            GeminiProvider(KEY, "m").complete("s", "u", 8)

    def test_thinking_that_produced_no_answer_raises(self, monkeypatch):
        _capture(
            monkeypatch,
            {"steps": [{"type": "thought", "content": [{"type": "text", "text": "hmm"}]}]},
        )
        with pytest.raises(LlmResponseError, match="thought"):
            GeminiProvider(KEY, "m").complete("s", "u", 8)

    def test_a_provider_cannot_be_built_without_a_key_or_model(self):
        with pytest.raises(LlmProviderError):
            GeminiProvider("", "m")
        with pytest.raises(LlmProviderError):
            GeminiProvider(KEY, "")


class TestSelection:
    def test_disabled_means_no_provider_and_therefore_the_template(self):
        assert provider_for(FakeSettings(llm_enabled=False)) is None

    def test_a_missing_key_is_not_an_error_it_is_just_no_provider(self):
        assert provider_for(FakeSettings(llm_api_key=None)) is None
        assert provider_for(FakeSettings(llm_model=None)) is None

    def test_an_unknown_provider_name_is_loud(self):
        with pytest.raises(LlmProviderError, match="not implemented"):
            provider_for(FakeSettings(llm_provider="something-nobody-wrote"))

    def test_gemini_is_selected_when_configured(self):
        assert isinstance(provider_for(FakeSettings()), GeminiProvider)


def test_the_provider_satisfies_the_contract_summarize_expects(monkeypatch):
    """It must be usable as the LlmProvider protocol, not just look like it."""
    from app.llm.summarize import summarize

    _capture(monkeypatch, _ok("There are no recorded sessions yet."))
    result = summarize({"games": []}, FakeSettings(), provider_for(FakeSettings()))
    assert result.generator == "llm"
    assert result.text == "There are no recorded sessions yet."
