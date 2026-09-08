#!/usr/bin/env python3
"""One synthetic round-trip against the configured LLM provider.

Run this after setting ``LLM_PROVIDER``, ``LLM_MODEL`` and ``LLM_API_KEY`` in
``services/api/.env``, to find out whether the credentials work *before*
switching ``LLM_ENABLED`` on for real traffic.

    .venv/bin/python scripts/check_llm.py

It sends a small set of made-up counts — no patient, no session, nothing from
the database — through exactly the prompt and validation the real report path
uses, so a pass here means the report path works, not merely that the network
is up.

Nothing secret is printed. Not the key, not any part of it, not the request,
not the provider's raw error body. The output is a verdict, a reason, and the
generated sentence.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import os  # noqa: E402

from app.config import _load_dotenv  # noqa: E402
from app.llm.providers import PROVIDERS  # noqa: E402
from app.llm.summarize import SYSTEM_PROMPT, render_template, validate_llm_text  # noqa: E402

# Shaped like build_facts() output, with invented numbers. Deliberately not
# loaded from the database: a connectivity check must never send real data.
SYNTHETIC_FACTS = {
    "window_days": 7,
    "games": [
        {
            "game_id": "reveal_match",
            "sessions_total": 4,
            "sessions_comparable": 3,
            "baseline_state": "established",
            "excluded": {"different_level": 1},
            "sessions": [{"unavailable_metrics": ["configured_pair_count"]}],
        }
    ],
}


def main() -> int:
    # Only the LLM settings are read. Full settings would demand DATABASE_URL
    # and the rest, and this check has nothing to do with the database — it
    # must be runnable on a laptop with no Postgres.
    _load_dotenv(Path(__file__).resolve().parents[1] / ".env")
    provider_name = os.environ.get("LLM_PROVIDER", "").strip()
    model = os.environ.get("LLM_MODEL", "").strip()
    api_key = os.environ.get("LLM_API_KEY", "").strip()
    enabled = os.environ.get("LLM_ENABLED", "").strip().lower() in {"1", "true", "yes", "on"}
    timeout = int(os.environ.get("LLM_TIMEOUT_SECONDS", "8"))

    print(f"provider   : {provider_name or '(unset)'}")
    print(f"model      : {model or '(unset)'}")
    print(f"api key    : {'present' if api_key else 'MISSING'}")
    print(f"LLM_ENABLED: {enabled}")
    print(f"timeout    : {timeout}s")
    print()

    if not (provider_name and model and api_key):
        print("SKIPPED — provider, model and key must all be set to run the check.")
        return 2

    factory = PROVIDERS.get(provider_name.lower())
    if factory is None:
        print(f"FAIL — no provider implemented for {provider_name!r}.")
        return 1
    provider = factory(api_key, model)

    import json

    try:
        raw = provider.complete(
            SYSTEM_PROMPT,
            json.dumps(SYNTHETIC_FACTS, sort_keys=True),
            timeout,
        )
    except Exception as exc:  # noqa: BLE001 - the point is to report any failure
        print(f"FAIL — {type(exc).__name__}: {exc}")
        print("\nThe report endpoint would fall back to the deterministic template.")
        return 1

    rejection = validate_llm_text(raw, SYNTHETIC_FACTS)
    print("--- model output " + "-" * 40)
    print(raw.strip())
    print("-" * 56)

    if rejection:
        # A reachable model whose output the guardrails reject. Worth knowing:
        # real reports would silently fall back to the template.
        print(f"\nREACHABLE, OUTPUT REJECTED — {rejection}")
        print("The API works. Reports would use the template until this is addressed.")
        return 1

    print("\nPASS — the provider answered and the output passed validation.")
    print("For comparison, the template for the same facts reads:")
    print(f"  {render_template(SYNTHETIC_FACTS)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
