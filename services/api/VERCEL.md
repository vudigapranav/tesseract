# Deploying the Tesseract API to Vercel

Prepared and tested locally on 2026-09-08. **Nothing has been deployed.**
Deploying needs the decisions below and explicit approval.

## What is here

| File | Purpose |
|---|---|
| `api/index.py` | Exports the existing FastAPI app as the module-level `app` Vercel's Python runtime looks for. It does not fork or reimplement the service. |
| `vercel.json` | Builds `api/index.py` with `@vercel/python` and rewrites every path to it, so FastAPI keeps doing its own routing. |
| `requirements.txt` | Vercel installs from this, not from `pyproject.toml`. Keep the two in step. |

## What was actually verified locally

Against the real app through `api/index.py`, in a clean virtualenv:

* The entry point imports and produces a `FastAPI` instance.
* All **25** routes are served, under the `/v1` prefix.
* `GET /v1/health` → **200**, `{"status":"ok", ..., "database":"ok"}`.

That proves the packaging is correct. It does not prove the service runs well
on Vercel, because of the following.

## Blockers before this can be deployed

**1. Media storage will not work.** `MEDIA_ROOT` is a local-filesystem adapter.
Vercel functions have an ephemeral, read-only-ish filesystem and no shared disk
between invocations, so anything uploaded is gone on the next request. Patient
media would need an object store (S3, R2, Vercel Blob) — a change to
`services/api`, which is Pranav's to make.

**2. Firebase credentials are read from a file path.**
`FirebaseIdentityVerifier` calls `credentials.Certificate(settings.firebase_credentials_file)`.
There is no file to point at on Vercel. This needs the service account supplied
as an environment variable holding the JSON, and a small change in
`app/auth/identity.py` to accept it. Also Pranav's call. **Do not commit the
service-account JSON, and do not paste it into chat** — it goes straight into
Vercel's encrypted environment variables.

**3. An external Postgres is required.** `DATABASE_URL` must point at a managed
database (Neon, Supabase, Vercel Postgres). Serverless functions also open a
connection per cold start, so a pooled connection string is strongly preferred.

**4. Migrations do not run themselves.** `alembic upgrade head` has to be run
against the database out of band before the first request. The health endpoint
reports `migration_revision: null` when this has not happened.

**5. Cold starts.** `firebase-admin` plus SQLAlchemy is a heavy import for a
serverless function. Expect noticeable first-request latency.

## Honest recommendation

Vercel is a poor fit for this service. It is a stateful FastAPI app with a
filesystem media adapter and a long-lived database connection — the three
things serverless is worst at. A container host (Railway, Render, Fly.io) would
run it as-is, with no code changes and no media rework, and would still give the
HTTPS URL the Flutter client requires.

The one thing Vercel would genuinely solve is the HTTPS requirement:
`IdentityService.configured` refuses any `TESSERACT_API_URL` that is not
`https://`, which is why a local `http://localhost` backend cannot complete the
end-to-end auth path. For *testing* that path today, an ngrok/cloudflared tunnel
in front of the local API is faster than any deployment.

## If you deploy anyway

```bash
cd services/api
vercel link
vercel env add DATABASE_URL production
vercel env add AUTH_MODE production          # firebase
vercel env add FIREBASE_PROJECT_ID production
# plus whatever mechanism blocker 2 is resolved with
vercel deploy                                 # preview first, never straight to prod
```

Check `GET /v1/health` on the preview URL before promoting anything, and confirm
`migration_revision` is not null.
