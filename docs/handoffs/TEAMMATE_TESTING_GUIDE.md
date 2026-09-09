# Apnapan — running it yourself

Written 2026-09-08. Prototype. Nothing here is a clinical tool.

You need the phone app to try the activities. You only need the backend if you
want the **Activity analysis** screen, which is where Gemini is wired in.

---

## Part 1 — the phone app (10 minutes, no backend)

### Get the code

```bash
git clone https://github.com/vudigapranav/tesseract.git
cd tesseract
```

The current work sits on the branch `codex/patient-caregiver-integration`, so
check that out rather than `main`:

```bash
git checkout codex/patient-caregiver-integration
```

> If that branch is missing or the games below are absent, the work has not
> been pushed yet — ask Pranav to push it. Nothing in this guide can conjure
> commits that are not on the remote.

### Run it

```bash
cd Apnapan/tesseract-expo
npm ci
npx expo start --lan
```

Install **Expo Go** on your phone, put the phone on the **same Wi-Fi** as the
laptop, and scan the QR code in the terminal.

If your network blocks LAN (common on college and guest Wi-Fi):

```bash
npx expo start --tunnel
```

If the tunnel starts successfully, share its generated URL. Keep the laptop awake and Metro running. Tunnel service availability and compatible Expo Go versions are required. iPhone: scan with Camera; Android: scan in Expo Go. Physical-device compatibility is not yet verified.

### What to try

1. **Language** — the control on the sign-in screen. Seven languages. Every one
   except English is labelled a draft awaiting native review, with its measured
   coverage. Switch to हिन्दी and back; no restart needed.
2. **Enter the demonstration** — the clearly-labelled preview entry on sign-in.
   It has its own storage scope and its own outbox, so it cannot mix with a
   real caregiver's data. It is not a real sign-in and does not pretend to be.
3. **Caregiver home** → hand over → patient mode.
4. **Play the activities.** Ten are registered — all nine required, plus one
   extra. The chooser shows four at a time; press **Show me more**.

   | Activity | Owner | What it is |
   |---|---|---|
   | Route Quest | Ruthika | tap the next connected place, then go home |
   | Marble Maze | Ruthika | tilt, or use a finger |
   | Word Search | Ruthika | tap a word's first letter, then its last |
   | Daily Routine | Ruthika | choose what comes next |
   | Picture Pairs | Aryan | turn two cards over and match them |
   | **Picture Questions** | **Aryan** | **look at a scene, then answer about it** |
   | **Find the Change** | **Aryan** | **two pictures, tap what differs** |
   | **Bring Back the Colours** | **Aryan** | **sweep a finger to reveal colour** |
   | **Follow the Line** | **Aryan** | **trace a shape from the green dot** |
   | Picture Sorting | Ruthika | extra, not one of the nine |

   The four in bold were ported on 2026-09-09 and have had the least use.

5. **Picture Pairs specifically.** Level 1 opens with every card face-up: look,
   then press **I am ready**. Tap two cards. A match stays; a mismatch turns
   back over after about a second and a half. Check that:
   - a wrong pair shows you *nothing* — no cross, no sound, no score;
   - **Help** highlights a pair but never plays it for you;
   - **Break** freezes the mismatch countdown, so a card you were still
     looking at is still there when you continue;
   - the activity finishes once, when the last pair is found.
6. **Return** through the protected caregiver gate. Patient mode has no
   ordinary way back.
7. **Settings → About Apnapan** — attribution and the per-language coverage table.

---

## Part 2 — the backend and the Gemini analysis

Only needed for the **Activity analysis** screen. Skip this if you just want to
play the activities.

### You need

- Python 3.11+
- PostgreSQL running locally
- A Gemini API key of your own — **do not ask for Pranav's, and do not paste
  any key into chat, a commit, or a screenshot.** Manage a key and check quota/billing at
  <https://aistudio.google.com/apikey>.

### Set it up

```bash
cd ../../services/api
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
cp -n .env.example .env
```

Open `.env` and set:

```
DATABASE_URL=postgresql+psycopg://localhost/apnapan
AUTH_MODE=demo
LLM_ENABLED=true
LLM_PROVIDER=gemini
LLM_MODEL=YOUR_SUPPORTED_GEMINI_MODEL
LLM_API_KEY=your-own-key-here
LLM_TIMEOUT_SECONDS=20
```

`.env` is git-ignored. Keep it that way. The key must never appear in an
`EXPO_PUBLIC_` variable, the mobile bundle, a log, or a commit — the phone app
never talks to Google, only to this backend.

### Check the key works before anything else

```bash
.venv/bin/python scripts/check_llm.py
```

It sends a handful of invented numbers — no patient, no session, nothing from
the database — through the exact prompt and validation the real report uses.
`PASS` means the whole path works, not just the network. It prints no secrets.

Select a model supported by your account using Google’s official documentation. Never print keys or put them into shell command arguments.

A timeout is not a crash. Every failure — no key, wrong key, timeout, rejected
output — falls back to the app's built-in wording, and the screen says which
one you are reading.

### Run it

```bash
.venv/bin/alembic upgrade head
.venv/bin/uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000
```

The app requires an HTTPS backend URL configured at build time, not a Settings server-address field. In `Apnapan/tesseract-expo/.env`, configure:

```dotenv
EXPO_PUBLIC_TESSERACT_API_URL=https://YOUR_REACHABLE_BACKEND
EXPO_PUBLIC_FIREBASE_API_KEY=YOUR_FIREBASE_PUBLIC_CLIENT_KEY
```

Restart Metro after configuration changes. A Metro tunnel exposes the JavaScript server only, not the API. The API needs its own reachable HTTPS deployment/tunnel and matching Firebase authentication for real mobile sign-in. Backend demo tokens can be exercised through the API docs with synthetic data, but the app's isolated preview does not provide authenticated server access. Thus the phone-to-Gemini flow is blocked until those services are configured; preview activities can be tested without them.

Create the local `apnapan` database before migrating (`createdb apnapan` with PostgreSQL installed and running). Set database credentials for your machine. For local synthetic API testing keep `APP_ENV=development` and `AUTH_MODE=demo`; never expose demo auth as production authentication.

### What to try

Once HTTPS and matching real identity are configured, play an activity, let it sync, then open **Activity analysis** from caregiver
home. Press **Generate analysis**. You should see:

- a short paragraph, followed by a line saying whether a language model or the
  app's built-in wording wrote it;
- the activity counts the paragraph is based on — every number in the text has
  to appear in these, or the model's version is thrown away;
- anything the activity does not measure, listed as *not measured* rather than
  shown as a zero;
- what this is not: an unreviewed draft, not a diagnosis.

**Worth breaking on purpose:** stop the backend and press Generate. You should
get a plain failure and a Try again, not a spinner forever. Set a wrong
`LLM_API_KEY` and restart — the report still generates, using the built-in
wording, and says so.

### Doctor access

Sign in as a doctor and you will see an empty patient list. That is correct.
Choosing "Doctor" in the UI grants nothing; access needs an assignment created
on the server:

```bash
.venv/bin/python scripts/grant_doctor.py --help
```

Without one, the server returns 403 for that patient's summary, sessions and
reports — including by direct id. The analysis screen shows the refusal rather
than working around it.

---

## What is honestly true right now

- **All nine required games ship**, plus one extra. `MISSING_REQUIRED_GAME_IDS`
  is empty in code and a test asserts it.
- Every activity picture is original vector artwork bundled with the app —
  offline, nothing to download, nothing that can break.
- The demonstration profile is Kamala (72) and her daughter Bidisha. It seeds
  her places, routine and words, and **no session history at all** — so the
  analysis screen is empty until someone actually plays. That is correct.
- Gemini provider code is present. A prior session reported a live synthetic check; this publishing task did not repeat it. No full phone-to-server analysis verification is claimed.
- Seven languages ship. Only English is reviewed; the rest are drafts. Meitei,
  Khasi and Mizo cover about 7% of the interface and fall back to English,
  which the app discloses.
- Publishing check: **170 app tests pass**, TypeScript clean. Prior backend test claims are not fresh verification for this publishing task.

## What is NOT tested

- **Anything on a physical phone or a simulator.** Nothing was run on a device
  in the session that wrote this. Notifications, speech, tilt/motion and the
  biometric gate are **NOT TESTED**.
- Speech in Hindi or any North-Eastern language. Translated text is not speech
  support.
- Real authentication. `AUTH_MODE=demo` accepts synthetic identities and the
  server refuses to start in that mode with `APP_ENV=production`.
- Gemini under load, on a slow network, or with any real patient data.

## If something breaks

| Symptom | Fix |
|---|---|
| Expo Go shows a red error | Shake → Reload. Then restart the server. |
| Cannot connect | Same Wi-Fi? Otherwise `npx expo start --tunnel`. |
| Port 8081 in use | Stop your own previous Metro terminal, or choose a different port. |
| Phone shows an old version | Shake → Reload, or fully close Expo Go. |
| Analysis says "no server is configured" | Configure the HTTPS EXPO_PUBLIC_TESSERACT_API_URL and restart Metro. |
| Analysis is always the built-in wording | Run `scripts/check_llm.py`; the reason is printed on the screen too. |
| `alembic upgrade head` fails | Postgres is not running, or `DATABASE_URL` is wrong. |

Web is not a verified fallback; use the supported native testing path.

## Report bugs
Use synthetic data only. Send phone model/OS, language, activity, exact reproduction steps, expected versus actual behavior, and a screenshot without personal data. Test launch, language changes, all six registered activities, Help, Break/resume, exit, completion and the protected caregiver return. Missing required games: Trace, Coloring, Spot Difference, Picture Recall.


## Android retest after 2026-09-09 fixes
Pull the testing branch, run npm ci, then restart with npx expo start --clear --tunnel (or --lan on the same Wi-Fi). Close and reopen Expo Go and scan the new QR. Do not clear app data or reinstall to fix saving: existing encrypted records are preserved by the byte-conversion fix. Test patient create/save, reopen, edit, change patient language, then close/reopen the app and verify persistence. Local-only notification imports avoid remote push registration at startup. Physical Android confirmation remains pending.
