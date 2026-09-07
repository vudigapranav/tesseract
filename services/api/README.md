# Tesseract API

FastAPI + PostgreSQL. Caregiver identity, patient profiles and Know Me content,
the session/event/completion loop, versioned metrics, reviewed recommendations,
reminders, and doctor-side boundaries.

The wire contract lives in
[`docs/contracts/PS003_API_CONTRACT_V1.md`](../../docs/contracts/PS003_API_CONTRACT_V1.md).
Read that before integrating; this file is only how to run the thing.

Roadmap packages: S05, S08, S09, S12, S13, S16, S17, S20, S27 (partial).

## What actually works right now

Verified on this machine, 2026-09-07 (Python 3.13.7, PostgreSQL 15):

- 130 automated tests pass against a real PostgreSQL database.
- The schema is built by Alembic, and the test suite runs those same migrations
  rather than `create_all`, so a broken migration fails the suite.
- One complete session loop — create, upload events, complete, read metrics,
  produce an explained recommendation, decide it, see the approved activity
  change — runs end to end over HTTP.

Not done, and not claimed: no deployment, no Flutter client is connected to
this, nothing has run on a device. See the checklist at the bottom.

## Setup

Requires Python 3.11+ and a running PostgreSQL.

```bash
cd services/api
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

Create the databases:

```bash
createdb tesseract
createdb tesseract_test
```

Configure. **Never commit the filled-in `.env`** — it is gitignored:

```bash
cp .env.example .env
```

Then edit `.env` and set `DATABASE_URL` to your own database. Everything in
`.env.example` is a placeholder; no credential is committed anywhere in this
repository.

Apply the schema:

```bash
.venv/bin/alembic upgrade head
```

Run it:

```bash
.venv/bin/uvicorn app.main:create_app --factory --reload --port 8000
```

Check it is alive:

```bash
curl -s localhost:8000/v1/health
```

Interactive API docs, once running: <http://localhost:8000/docs>

## Demo data

Seeds one synthetic caregiver, one synthetic patient, and three completed
Route Quest sessions — enough to produce a real recommendation:

```bash
.venv/bin/python scripts/seed_demo.py
```

It prints the patient id and the demo token to use. All data is synthetic.

To give an account the doctor role (there is no endpoint that does this):

```bash
.venv/bin/python scripts/grant_doctor.py demo-doctor-a <patient-id>
```

## Tests

```bash
.venv/bin/python -m pytest
```

They run against `tesseract_test` and truncate it between tests. Override with
`DATABASE_URL` if your local role differs from the default in `tests/conftest.py`.

Lint:

```bash
.venv/bin/ruff check app tests
```

## Authentication

Two modes, set by `AUTH_MODE`.

**`demo`** — accepts `Authorization: Bearer demo:<any-uid>`. Each distinct uid
is a separate caregiver. For local development and the synthetic demo only.

**`firebase`** — verifies a real Firebase ID token. Requires
`FIREBASE_CREDENTIALS_FILE` pointing at a service-account JSON kept **outside**
this repository.

The service **refuses to start** with `AUTH_MODE=demo` and `APP_ENV=production`.
There is no fallback path from firebase to demo. While in demo mode every
response carries `X-Tesseract-Demo-Mode: true` and `/v1/health` reports
`"auth_mode": "demo"`, so a demo backend cannot be mistaken for a real one.

## Layout

```
app/
  config.py          validated settings; fails closed at startup
  models.py          PostgreSQL schema
  errors.py          one error envelope, stable codes, request ids
  games.py           server-side game catalogue (level floors/ceilings)
  auth/              identity verification + the single access-check dependency
  patients/          profiles, Know Me content, approved activity
  media/             private patient media + storage adapter
  sessions/          create / events:batch / complete, and the dedup rules
  analytics/         versioned calculators, comparability, baselines
  recommendations/   thresholds (settings.py), rules, caregiver decisions
  reminders/         definitions and the occurrence/acknowledgement log
  doctor/            assignment-scoped reads, notes, generated reports
  llm/               optional, off by default; allow-listed de-identified facts
migrations/          Alembic
tests/               synthetic fixtures only
```

Two things worth knowing before changing code here:

1. **Access control lives in `app/auth/dependencies.py` only.** Routes depend on
   `require_patient_access` / `require_caregiver_access`; they do not
   re-implement the check. Adding a route without one is the bug to look for.
2. **Recommendation thresholds live in `app/recommendations/settings.py` only.**
   They are versioned and tagged `prototype_unreviewed`. No rule hardcodes a
   number.

## Honest status

| Area | State |
|---|---|
| Runnable service, migrations, health | Done, verified locally |
| Caregiver identity + membership enforcement | Done; demo mode verified, **Firebase path never run against a real project** |
| Patient profile + Know Me + media | Done, verified locally |
| Session create / events / complete, idempotent retries | Done, verified locally |
| Versioned metric calculators + fixtures | Done for G2 and G3; the other seven games have no calculator |
| Comparable history + provisional baselines | Done, verified locally |
| Recommendations + caregiver decision | Done, verified locally |
| Reminders + occurrences | Done, verified locally |
| Doctor boundaries, notes, reports | Done, verified locally |
| Optional LLM text | Adapter + guardrails + tests; **no provider is wired in** |
| Flutter integration | **Not started.** No client calls this. |
| Deployment | **None.** Localhost only. |
| Device testing | **None.** |

Two metrics are deliberately unavailable rather than guessed —
`route_efficiency` and `path_efficiency` — because neither game exports the
shortest-path figure its formula needs. See §7.1 of the contract for the exact
fields the games must add.
