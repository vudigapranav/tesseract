"""What the optional LLM path may and may not do.

These tests are the enforcement, not the documentation. If someone later wires
a real provider in, these still hold.
"""

from __future__ import annotations

import json

import pytest

from app.config import load_settings
from app.llm.payload import assert_deidentified, build_facts
from app.llm.summarize import render_template, summarize, validate_llm_text


@pytest.fixture
def summary_with_identifying_data() -> dict:
    return {
        "patient_id": "6d3f5a2e-0c1b-4d6a-9f21-8c2f4b7a10de",
        "note": "Observed application-performance signals.",
        "games": [
            {
                "game_id": "route_quest",
                "sessions_total": 3,
                "sessions_comparable": 3,
                "baseline": {"state": "established", "values": {"moves_made_median": 6.0}},
                "excluded": {"tutorial": 1},
                "recent_sessions": [
                    {
                        "session_id": "1f0a0000-0000-0000-0000-000000000001",
                        "level": 1,
                        "status": "completed",
                        "assisted": False,
                        "is_tutorial": False,
                        "actual_input_mode": "touch",
                        "metrics": {
                            "route_completed": True,
                            "moves_made": 6,
                            "hints_used": 0,
                            # Things that must never reach a model:
                            "patient_display_name": "Ramesh Kumar",
                            "personal_words": ["chai", "garden"],
                            "photo_url": "/v1/media/abc",
                        },
                        "unavailable_metrics": {"route_efficiency": {}},
                    }
                ],
            }
        ],
    }


class TestPayloadDeidentification:
    def test_names_words_and_media_are_stripped(self, summary_with_identifying_data):
        facts = build_facts(summary_with_identifying_data)
        blob = json.dumps(facts)
        assert "Ramesh" not in blob
        assert "chai" not in blob
        assert "garden" not in blob
        assert "/v1/media/" not in blob

    def test_the_patient_id_is_not_sent(self, summary_with_identifying_data):
        facts = build_facts(summary_with_identifying_data)
        assert summary_with_identifying_data["patient_id"] not in json.dumps(facts)

    def test_only_allow_listed_metrics_survive(self, summary_with_identifying_data):
        facts = build_facts(summary_with_identifying_data)
        metrics = facts["games"][0]["sessions"][0]["metrics"]
        assert set(metrics) == {"route_completed", "moves_made", "hints_used"}

    def test_the_payload_passes_its_own_guard(self, summary_with_identifying_data):
        assert_deidentified(build_facts(summary_with_identifying_data))

    def test_the_guard_catches_an_identifying_field_added_later(self):
        with pytest.raises(ValueError, match="Refusing to build"):
            assert_deidentified({"games": [{"display_name": "Ramesh"}]})


class TestOutputValidation:
    def _facts(self, summary) -> dict:
        return build_facts(summary)

    def test_an_invented_number_is_rejected(self, summary_with_identifying_data):
        facts = self._facts(summary_with_identifying_data)
        # 87 appears nowhere in the supplied facts.
        assert validate_llm_text(
            "Accuracy improved to 87 percent this week.", facts
        ) == "unsupported_number:87"

    def test_a_supplied_number_is_accepted(self, summary_with_identifying_data):
        facts = self._facts(summary_with_identifying_data)
        assert validate_llm_text("There were 3 recorded sessions.", facts) is None

    @pytest.mark.parametrize(
        "text",
        [
            "This suggests a diagnosis of early dementia.",
            "The results indicate cognitive decline.",
            "Disease progression appears to be accelerating.",
            "Consider adjusting their medication.",
            "A different treatment may help.",
        ],
    )
    def test_clinical_language_is_rejected(self, text, summary_with_identifying_data):
        rejection = validate_llm_text(text, self._facts(summary_with_identifying_data))
        assert rejection is not None and rejection.startswith("forbidden_phrase:")

    def test_an_empty_response_is_rejected(self, summary_with_identifying_data):
        rejection = validate_llm_text("   ", self._facts(summary_with_identifying_data))
        assert rejection == "empty_response"


class TestFallback:
    def test_the_template_is_used_when_the_llm_is_disabled(
        self, summary_with_identifying_data, monkeypatch, tmp_path
    ):
        monkeypatch.setenv("APP_ENV", "test")
        monkeypatch.setenv("AUTH_MODE", "demo")
        monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u@localhost/x")
        monkeypatch.setenv("LLM_ENABLED", "false")
        settings = load_settings(env_file=tmp_path / "absent.env")

        result = summarize(summary_with_identifying_data, settings)
        assert result.generator == "template"
        assert result.fallback_reason == "llm_disabled"
        assert result.text

    def test_a_provider_failure_falls_back_to_the_template(
        self, summary_with_identifying_data, monkeypatch, tmp_path
    ):
        monkeypatch.setenv("APP_ENV", "test")
        monkeypatch.setenv("AUTH_MODE", "demo")
        monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u@localhost/x")
        monkeypatch.setenv("LLM_ENABLED", "true")
        monkeypatch.setenv("LLM_MODEL", "placeholder-model")
        monkeypatch.setenv("LLM_API_KEY", "placeholder-key")
        monkeypatch.setenv("LLM_PROVIDER", "gemini")
        settings = load_settings(env_file=tmp_path / "absent.env")

        class ExplodingProvider:
            def complete(self, system, user, timeout_seconds):
                raise TimeoutError("provider timed out")

        result = summarize(summary_with_identifying_data, settings, ExplodingProvider())
        assert result.generator == "template"
        assert result.fallback_reason == "provider_error:TimeoutError"

    def test_an_invalid_llm_response_falls_back_to_the_template(
        self, summary_with_identifying_data, monkeypatch, tmp_path
    ):
        monkeypatch.setenv("APP_ENV", "test")
        monkeypatch.setenv("AUTH_MODE", "demo")
        monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u@localhost/x")
        monkeypatch.setenv("LLM_ENABLED", "true")
        monkeypatch.setenv("LLM_MODEL", "placeholder-model")
        monkeypatch.setenv("LLM_API_KEY", "placeholder-key")
        monkeypatch.setenv("LLM_PROVIDER", "gemini")
        settings = load_settings(env_file=tmp_path / "absent.env")

        class DiagnosingProvider:
            def complete(self, system, user, timeout_seconds):
                return "This indicates cognitive decline consistent with progression."

        result = summarize(summary_with_identifying_data, settings, DiagnosingProvider())
        assert result.generator == "template"
        assert result.fallback_reason.startswith("forbidden_phrase:")

    def test_the_provider_never_receives_identifying_data(
        self, summary_with_identifying_data, monkeypatch, tmp_path
    ):
        monkeypatch.setenv("APP_ENV", "test")
        monkeypatch.setenv("AUTH_MODE", "demo")
        monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u@localhost/x")
        monkeypatch.setenv("LLM_ENABLED", "true")
        monkeypatch.setenv("LLM_MODEL", "placeholder-model")
        monkeypatch.setenv("LLM_API_KEY", "placeholder-key")
        monkeypatch.setenv("LLM_PROVIDER", "gemini")
        settings = load_settings(env_file=tmp_path / "absent.env")

        seen: dict[str, str] = {}

        class RecordingProvider:
            def complete(self, system, user, timeout_seconds):
                seen["system"] = system
                seen["user"] = user
                return "There were 3 recorded sessions."

        summarize(summary_with_identifying_data, settings, RecordingProvider())
        prompt = seen["system"] + seen["user"]
        assert "Ramesh" not in prompt
        assert "chai" not in prompt
        assert summary_with_identifying_data["patient_id"] not in prompt


class TestTemplate:
    def test_it_says_when_there_is_no_data_without_guessing(self):
        text = render_template({"games": []})
        assert "no recorded sessions" in text
        assert "not a finding about the person" in text

    def test_it_reports_unmeasured_metrics_as_unmeasured(
        self, summary_with_identifying_data
    ):
        text = render_template(build_facts(summary_with_identifying_data))
        assert "Not measured" in text
        assert "route efficiency" in text

    def test_it_always_states_these_are_not_cognitive_scores(
        self, summary_with_identifying_data
    ):
        text = render_template(build_facts(summary_with_identifying_data))
        assert "not cognitive scores" in text
