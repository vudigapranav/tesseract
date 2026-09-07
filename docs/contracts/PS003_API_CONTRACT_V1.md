# Tesseract API contract v1

Roadmap package: **S05 - Database and API contracts**. Owner: Pranav.
Primary consumer: Shanks (Flutter shell, telemetry adapter, offline outbox).
Written 2026-09-07. Status: **v1 draft, implemented in `services/api`, not yet
reviewed by Shanks or Ruthika.**

This document is the integration surface. It is deliberately split into
**Confirmed** (already true in committed code or in an approved document —
changing it breaks something that exists) and **Proposed** (my decision, open
to review — say so now, not after you have written against it).

---

## 1. What is already fixed, and why

### 1.1 Confirmed - game event names

The nine games emit event types defined in
`code/packages/tesseract_game_contract`. **The API does not rename any of
them.** Verbatim, from `lib/src/event_recorder.dart` and the two built games:

| Source | Event types |
|---|---|
| Shared lifecycle (all nine games) | `session_started`, `tutorial_started`, `tutorial_completed`, `hint_requested`, `support_changed`, `paused`, `resumed`, `session_finished` |
| Route Quest (G2) | `location_entered`, `destination_reached`, `item_collected`, `return_completed`, `wrong_interaction` |
| Marble Maze (G3) | `collision`, `dead_end_entered`, `goal_reached` |

The server accepts any `type` string and stores it. It does **not** reject
unknown types — a new game must be able to upload before its calculator
exists. Unknown types are simply not consumed by any metric calculator.

### 1.2 Confirmed - sequencing guarantees the device already enforces

From `TesseractEventRecorder`, enforced with real throws in every build mode:

- `seq` starts at 1, increments by exactly 1, never reused, never skipped.
- `elapsed_ms` is monotonic and excludes paused **and backgrounded** time.
- `session_finished` fires exactly once; no event follows it.
- Payloads carry opaque IDs only — no names, labels, image paths or raw
  coordinates.

The server re-validates all of this rather than trusting it (see §6.3).

### 1.3 Confirmed - result statuses

`completed` | `stopped_by_user` | `interrupted`. From
`GameResultStatus.values`. Any other value is a 422.

### 1.4 Confirmed - conventions

UUIDv4 generated on the device; all timestamps UTC ISO-8601 with `Z`; all
durations in integer milliseconds; `schema_version` on every envelope.

---

## 2. Proposed - decisions that need your review

These are mine. Each one is a real choice with a real alternative.

### P1. Field naming is `snake_case` everywhere, including inside the event

**This needs a small host change.** `SessionController.recordEvent` currently
does `...event.toJson()`, and `GameEvent.toJson()` emits **`elapsedMs`**
(camelCase) — so today's snapshot mixes `event_id`/`session_id` (snake) with
`elapsedMs` (camel) in one object.

The API takes **`elapsed_ms`**. The fix belongs in the host adapter, not in
the game contract — no game code changes, no event renaming:

```dart
final Map<String, Object?> json = event.toJson();
_wrappedEvents.add(<String, Object?>{
  'event_id': generateUuidV4(_random),
  'session_id': sessionId,
  'occurred_at': DateTime.now().toUtc().toIso8601String(),
  'type': json['type'],
  'seq': json['seq'],
  'elapsed_ms': json['elapsedMs'],   // <- the only rename
  'payload': json['payload'],
});
```

Alternative if you prefer: the server accepts `elapsedMs` as an alias. Say the
word and I will add it. I would rather not — one wire name is easier to keep
honest across nine games.

### P2. `patient_id` is **not** carried on each event

`GameEvent`'s doc comment lists `patient_id` among host-added fields, but
`SessionController` does not actually add it, and the session already binds a
patient server-side. Sending it per-event is redundant and adds a way for the
two to disagree.

**Decision: events carry no `patient_id`.** If present it is ignored, not
rejected. The session's patient is authoritative.

### P3. `game_id` / `game_version` / `schema_version` live on the session,
not on every event

The host currently repeats all three on every event. They are identical for
every event in a session by construction. **The session record holds them;
per-event copies are ignored if sent.** Sending them is harmless — keep or
drop whichever is easier for the outbox.

### P4. Requested vs. actual input mode are separate fields

Marble Maze is configured `tilt` but silently falls back to touch when no
gyroscope is present. If we store one field we cannot tell a tilt session from
a touch session, and comparability (S17) breaks.

**Session carries both `requested_input_mode` and `actual_input_mode`.** The
host must set `actual_input_mode` from what the device really used. Only
`actual_input_mode` is used for comparability. If you send only
`requested_input_mode`, actual defaults to it and the session is flagged
`input_mode_unverified: true` in summaries.

### P5. Session ID is the device-generated client UUID

`PUT /v1/sessions/{session_id}` where `session_id` is the UUID the device
already made in `SessionController`. No server-issued ID, no mapping table.
Idempotent by construction: replaying the PUT with identical content is a
200, not a duplicate.

### P6. Auth is a Firebase ID token; there is a separate, explicitly-enabled demo mode

`Authorization: Bearer <firebase-id-token>`. Production verifies against
Firebase Admin and **fails closed** — if credentials are absent or invalid the
service refuses to start. See §3.

### P7. Pagination is opaque-cursor, not offset

`?limit=50&cursor=<opaque>` → `{"items": [...], "next_cursor": "..." | null}`.
Offsets shift under concurrent inserts; sessions are append-heavy.

---

## 3. Authentication and access

### 3.1 Modes

`AUTH_MODE` is a required environment variable with exactly two values:

| `AUTH_MODE` | Behavior |
|---|---|
| `firebase` | Verifies the bearer token with Firebase Admin. **Required in production.** Startup fails if credentials are missing/unreadable. |
| `demo` | Accepts synthetic tokens `demo:<auth_uid>` for local development and the hackathon demo. |

**Fail-closed rule:** `demo` is rejected at startup when `APP_ENV=production`.
The service exits with a configuration error rather than starting insecurely.
There is no default, no fallback and no "if firebase is unavailable, allow" path.

Every `demo`-mode response carries the header `X-Tesseract-Demo-Mode: true`,
and `GET /v1/health` reports `"auth_mode": "demo"`, so a demo backend cannot
be mistaken for a real one from the client side.

### 3.2 Identity

First authenticated request for an unseen `auth_uid` creates a `users` row
(`role='caregiver'` by default). Doctors are provisioned separately — a
caregiver cannot self-promote (see §10).

### 3.3 Membership

**Every** patient-scoped route resolves the patient through the caller's
membership before doing anything else:

- Caregiver: needs a `caregiver_patients` row for that patient.
- Doctor: needs a non-revoked `doctor_assignments` row.
- No row → **403 `no_patient_access`**. Never 404 — a 404 would leak whether
  the patient ID exists.

This is enforced by one dependency (`app/auth/dependencies.py`), not
re-implemented per route, so a new route cannot forget it.

---

## 4. Errors

Every error response, without exception:

```json
{
  "error": {
    "code": "no_patient_access",
    "message": "You do not have access to this patient.",
    "request_id": "018f...",
    "details": {}
  }
}
```

`code` is stable and machine-readable — branch on it, never on `message`.
`request_id` is echoed in the `X-Request-ID` response header and appears in
server logs.

| HTTP | `code` | When |
|---|---|---|
| 401 | `identity_required` | Missing/malformed/expired bearer token |
| 403 | `no_patient_access` | Authenticated, but not this patient's caregiver/doctor |
| 404 | `not_found` | Resource does not exist *and* the caller could have accessed it |
| 409 | `revision_conflict` | `If-Match`/`version` mismatch on a profile write |
| 409 | `session_conflict` | Session exists with different immutable fields |
| 409 | `completion_conflict` | Session already completed with different `final_seq`/`status` |
| 422 | `invalid_data` | Schema violation; `details` names the field |
| 422 | `sequence_gap` | Completion requested while events are missing (§6.3) |
| 429 | `rate_limited` | Reserved; not implemented in the prototype |
| 503 | `dependency_unavailable` | Database unreachable |

---

## 5. Patients and Know Me

### 5.1 `POST /v1/patients`

```json
{
  "display_name": "Synthetic Patient A",
  "language": "en",
  "known_type": null,
  "known_stage": null,
  "accessibility": {"text_scale": 1.5, "reduced_motion": false}
}
```

→ `201`

```json
{
  "patient_id": "6d3f5a2e-0c1b-4d6a-9f21-8c2f4b7a10de",
  "version": 1,
  "display_name": "Synthetic Patient A",
  "language": "en",
  "known_type": null,
  "known_stage": null,
  "accessibility": {"text_scale": 1.5, "reduced_motion": false},
  "created_at": "2026-09-07T09:14:02.113Z"
}
```

The creating caregiver is inserted into `caregiver_patients` with
`role='owner'` in the same transaction.

**Clinical fields are optional and stay optional.** `known_type` and
`known_stage` accept `null` and the literal string `"unknown"`. They are
caregiver-entered context. They are never inputs to difficulty, metrics or
recommendations — enforced by the recommendation engine ignoring them entirely.

### 5.2 `PUT /v1/patients/{patient_id}/personalization`

Know Me content. Optimistic concurrency: send the `version` you last read.

```json
{
  "version": 1,
  "personal_words": [
    {"text": "chai", "locale": "en"},
    {"text": "garden", "locale": "en"}
  ],
  "people_places": [
    {"kind": "person", "label": "Daughter", "media_asset_id": null},
    {"kind": "place",  "label": "Temple",   "media_asset_id": "e1b2..."}
  ],
  "preferences": {"prefers_images_over_words": true}
}
```

→ `200 {"patient_id": "...", "version": 2, "personal_words_count": 2, "people_places_count": 2}`

Version mismatch → `409 revision_conflict` with
`details: {"expected": 2, "received": 1}`. **No silent overwrite.**

**Word count: 15-20 is a target, not a rule.** Zero words is valid. One word is
valid. The server never rejects a personalization write for having too few
words. `GET /v1/patients/{id}/activity` reports
`content_sufficiency: {"personal_words": 2, "sufficient_for_word_games": false}`
so the client can explain the consequence instead of the server blocking it.

### 5.3 Media

`POST /v1/patients/{patient_id}/media` (multipart) → `{"media_asset_id", "url"}`.
Storage goes through `app/media/storage.py`, an adapter interface with one
implementation in the prototype: `LocalMediaStorage`, writing under
`MEDIA_ROOT` with membership checked on **both** upload and read. No public
bucket, no unauthenticated URL, no CDN. `GET /v1/media/{id}` streams the bytes
only to a caller who passes the same membership check as the owning patient.

Uploads are content-hashed; re-uploading identical bytes for the same patient
returns the existing `media_asset_id` rather than a second copy.

---

## 6. The session loop

This is the part you are integrating against. Three calls, in order.

### 6.1 `PUT /v1/sessions/{session_id}` - create (idempotent)

`session_id` is the device UUID.

```json
{
  "patient_id": "6d3f5a2e-0c1b-4d6a-9f21-8c2f4b7a10de",
  "game_id": "route_quest",
  "game_version": "1.0.0",
  "schema_version": "1",
  "config_version": "1",
  "content_version": "1",
  "metric_version": "1",
  "level": 2,
  "difficulty_params": {"nodeCount": 7, "branchCount": 2, "requiresReturn": true},
  "requested_input_mode": "touch",
  "actual_input_mode": "touch",
  "is_tutorial": false,
  "text_scale": 1.0,
  "locale": "en",
  "started_at": "2026-09-07T09:20:00.000Z"
}
```

→ `201` on first call, `200` on an identical replay:

```json
{
  "session_id": "1f0a...",
  "patient_id": "6d3f...",
  "status": "open",
  "created": true,
  "events_received": 0,
  "final_seq": null
}
```

**Immutable after creation:** `patient_id`, `game_id`, `game_version`, `level`,
`difficulty_params`, `is_tutorial`, `config_version`, `content_version`,
`metric_version`. Replaying with any of these changed → `409 session_conflict`,
`details.conflicting_fields` lists them. Mutable: `actual_input_mode` (the
device may discover the gyroscope is missing after creation).

The full config snapshot is stored verbatim. Analytics reads the snapshot, never
today's defaults — a session stays interpretable after the presets change.

### 6.2 `POST /v1/sessions/{session_id}/events:batch`

Batch of up to 500. Order within the batch does not matter; `seq` does.

```json
{
  "events": [
    {"event_id": "a1...", "seq": 1, "type": "session_started",
     "elapsed_ms": 0, "occurred_at": "2026-09-07T09:20:00.010Z", "payload": {}},
    {"event_id": "a2...", "seq": 2, "type": "location_entered",
     "elapsed_ms": 3120, "occurred_at": "2026-09-07T09:20:03.130Z",
     "payload": {"nodeId": "n3"}}
  ]
}
```

→ `200`

```json
{
  "accepted":  ["a1...", "a2..."],
  "duplicate": [],
  "rejected":  [],
  "highest_seq": 2,
  "missing_seqs": []
}
```

**Deduplication (this is what makes your retry safe):**

- Same `event_id` **and** identical content → `duplicate`. Not an error.
- Same `event_id`, *different* content → `rejected`, reason
  `event_id_conflict`. This catches a real bug (ID reuse), so it is loud.
- Same `(session_id, seq)` with a different `event_id` → `rejected`, reason
  `seq_conflict`.
- Events after `session_finished`'s seq → `rejected`, reason `after_final_seq`.
- Batch to a completed session: duplicates still return `duplicate` (a retry of
  an already-delivered batch must stay safe); genuinely new events are
  `rejected` with `session_closed`.

**A 200 with a non-empty `rejected` list is not a failure to retry.** Retry only
on 5xx or a transport error. Re-sending a fully-accepted batch is always safe
and always yields the same totals — this is the "replay after restart must not
change totals" requirement from the handbook.

### 6.3 `POST /v1/sessions/{session_id}/complete`

```json
{"status": "completed", "final_seq": 42, "assisted": false,
 "ended_at": "2026-09-07T09:26:31.402Z"}
```

Server checks, in order:

1. `final_seq` must equal the max stored `seq`, and seqs `1..final_seq` must all
   be present. A gap → **422 `sequence_gap`**, `details.missing_seqs: [17, 18]`.
   The session stays `open`. Upload the missing events and call complete again.
2. Already completed with the **same** `status` + `final_seq` → `200`,
   `"created": false`. Idempotent.
3. Already completed with **different** values → **409 `completion_conflict`**.
4. `status` outside the three legal values → 422.

On success the session moves to `completed` and metric calculation runs
synchronously (prototype choice — it is fast, and it makes the demo
deterministic).

```json
{
  "session_id": "1f0a...",
  "status": "completed",
  "final_seq": 42,
  "metrics": {
    "metric_version": "1",
    "calculator_id": "route_quest_v1",
    "available": {
      "active_duration_ms": 391402,
      "route_completed": true,
      "destination_reached": true,
      "return_completed": true,
      "moves_made": 18,
      "unique_locations_visited": 7,
      "wrong_interactions": 3,
      "hints_used": 0,
      "assisted": false
    },
    "unavailable": {
      "route_efficiency": {
        "reason": "missing_game_export",
        "detail": "route_quest does not export the BFS shortest-path length for the level it generated.",
        "needs": ["shortest_path_length"]
      }
    }
  },
  "recommendation_id": null
}
```

**Interrupted sessions.** If the app dies mid-session, complete is never called
and the session stays `open`. On next launch, upload whatever events you have
and call complete with `status: "interrupted"` and `final_seq` = your highest
seq. Interrupted sessions are stored, are visible in history, and are
**excluded from baselines and recommendations** (§8).

### 6.4 Ordering rule

Create → events → complete. Events for an unknown session → `404 not_found`
(create it first). This is deliberate: it keeps the patient binding, and
therefore the access check, ahead of any data write.

---

## 7. Metrics

`GET /v1/sessions/{session_id}/metrics` → the object shown in §6.3.

Metrics are versioned (`metric_version`) and computed by pure functions in
`app/analytics/calculators.py` that take stored events + the config snapshot and
return values. No route handler computes anything.

### 7.1 Available vs. unavailable - and the two efficiency metrics we cannot compute

Every calculator returns two maps. `available` holds computed values.
`unavailable` holds metrics that **could not** be computed, each with a machine
reason and the exact fields it would need. A metric is never silently zero, and
never fabricated.

**Both efficiency metrics are currently `unavailable`.** I checked the game
sources rather than assuming, and neither game exports what its efficiency
formula needs:

| Game | Metric | Why it cannot be computed | Fields the game must add |
|---|---|---|---|
| Route Quest (G2) | `route_efficiency` | The game *does* compute a BFS shortest path at level load (`RouteGraph.shortestPathLength`) but never exports it. `difficultyParams` carries only `nodeCount`, `branchCount`, `requiresReturn`. | `shortest_path_length` |
| Marble Maze (G3) | `path_efficiency` | The game emits `collision`, `dead_end_entered` and `goal_reached` only — no travelled distance and no shortest grid path. | `distance_travelled_units`, `shortest_path_units` |

```json
"unavailable": {
  "route_efficiency": {
    "reason": "missing_game_export",
    "detail": "route_quest does not export the BFS shortest-path length for the level it generated.",
    "needs": ["shortest_path_length"]
  }
}
```

**The server deliberately does not re-derive these.** It could reimplement
`RouteTopology.forLevel` and the BFS in Python and get a number — and that
number would silently become wrong the first time anyone edits the map without
bumping a version. Duplicated game logic on the server is worse than an honest
gap.

**Game-contract dependency, for a later and separate change — I have not
touched any game code:** each game should carry its own shortest-path figure in
its `session_finished` payload (or in `difficultyParams`, which is already a
frozen config snapshot). Both values are already known inside the games; this is
an export, not a new computation. Until then, caregiver and doctor views must
show **"not measured"** for these two, never 0%.

What the games *do* report today:

- **Route Quest:** `route_completed`, `destination_reached`, `item_collected`,
  `return_completed`, `moves_made`, `unique_locations_visited`,
  `wrong_interactions`, `hints_used`, `active_duration_ms`.
- **Marble Maze:** `goal_reached`, `contact_episodes` (debounced — a continuous
  scrape along one wall counts once, per the S28 acceptance criterion),
  `contact_events_raw`, `dead_ends_entered`, `active_duration_ms`.

The recommendation rules in §9 use only these available metrics. They do not
wait on the missing exports.

### 7.2 Zero is not the same as null

Zero attempts → `null` accuracy, never `0.0`. This is in every calculator and
in the fixtures.

---

## 8. History, baselines and comparability

`GET /v1/patients/{patient_id}/summary?game_id=&window_days=30`

```json
{
  "patient_id": "6d3f...",
  "generated_at": "2026-09-07T10:00:00.000Z",
  "last_session_at": "2026-09-07T09:26:31.402Z",
  "games": [{
    "game_id": "route_quest",
    "sessions_total": 7,
    "sessions_comparable": 4,
    "baseline": {
      "state": "established",
      "rule_version": "baseline-v1",
      "basis": "Median of the first 3 comparable sessions. Engineering starting assumption, not a validated clinical protocol.",
      "from_session_ids": ["...", "...", "..."],
      "values": {
        "moves_made_median": 6.0,
        "wrong_interactions_median": 1.0,
        "active_duration_ms_median": 402000.0
      }
    },
    "excluded": {"tutorial": 1, "assisted": 1, "interrupted": 1, "config_changed": 0}
  }]
}
```

**A session is comparable only if all of these hold:** not a tutorial, not
assisted, status `completed`, and same `game_id` + `game_version` + `level` +
`difficulty_params` + `actual_input_mode` + `content_version` as the series.
Change any of those and a **new series** starts — the old one is not extended.

`baseline.state` is `insufficient_data` until **three** comparable sessions
exist, and then `established`. Three is an engineering starting assumption
carried over from the handbook, **not a validated clinical protocol**, and it is
labelled that way in the response and in the settings file.

These are **app-performance observations**, not cognitive scores. The response
has no field named for a cognitive domain, on purpose.

---

## 9. Recommendations

`GET /v1/patients/{patient_id}/recommendations` → pending + recent decided.

```json
{
  "items": [{
    "recommendation_id": "9c2e...",
    "status": "pending",
    "rule_version": "rules-v1",
    "created_at": "2026-09-07T09:26:31.500Z",
    "proposed_config": {"game_id": "route_quest", "level": 3},
    "current_config":  {"game_id": "route_quest", "level": 2},
    "reason": {
      "code": "consistent_success",
      "summary": "The last 3 comparable sessions were completed without help. Suggesting the next level up for review.",
      "observed": {
        "session_ids": ["...", "...", "..."],
        "objective_metric": "route_completed",
        "objective_reached": [true, true, true],
        "hints_used": [0, 0, 0],
        "wrong_interactions": [1, 0, 2]
      },
      "rule_version": "rules-v1",
      "thresholds_used": {
        "min_comparable_sessions": 3,
        "promote_required_completions": 3,
        "promote_max_hints_total": 0,
        "promote_max_wrong_interactions_per_session": 2
      },
      "thresholds_status": "prototype_unreviewed",
      "thresholds_note": "Prototype values. Not usability tested, not clinically reviewed. Require review before any real-world use."
    }
  }],
  "next_cursor": null
}
```

`POST /v1/recommendations/{id}/decision`

```json
{"decision": "modify", "modified_config": {"game_id": "route_quest", "level": 2},
 "expected_config_version": 4}
```

- `accept` | `modify` | `reject`. Reviewer is taken from the **auth token**, not
  the body.
- `expected_config_version` guards against a stale proposal overwriting a newer
  approved config → `409 revision_conflict`. Straight from the handbook's
  "recheck version on approval".
- Until a caregiver decides, **the patient keeps the last approved config.** A
  pending proposal changes nothing. There is no auto-apply path in the code.
- Applying a decision only ever writes `activity_settings`; it is the single
  place approved config changes, and it always records who approved it.

### 9.1 Thresholds are settings, not constants

Every number lives in `app/recommendations/settings.py`, versioned as
`rules-v1`, and every one is tagged `"status": "prototype_unreviewed"`. They are
echoed in each recommendation's `thresholds_used`. They have not been usability
tested and must not be described as validated. Changing them creates
`rules-v2`; old recommendations keep the version they were made under.

### 9.2 Hard guardrails in code

- Recommendations are produced **between** sessions only, on completion.
- Missing data, assisted play or interrupted sessions → `hold`, never promote.
- Speed alone never raises difficulty.
- Level is clamped to the game's configured ceiling and floor.
- A `hold` with no change is a valid, expected outcome.

---

## 10. Reminders (independent of gameplay)

Reminders must work for a patient who never opens a game. Nothing in this
section touches sessions.

- `POST/GET/PATCH/DELETE /v1/patients/{id}/reminders` — definitions:
  `{title, body, schedule: {kind: "daily"|"weekly"|"once", times: ["08:00"], weekdays: [1,3,5], timezone: "Asia/Kolkata"}, active}`.
  Each write bumps `schedule_version`.
- `GET /v1/patients/{id}/reminders/occurrences?from=&to=` — the server's view.
- `POST /v1/reminders/{id}/occurrences` — the device reports an occurrence it
  actually scheduled/fired, with `scheduled_for` and `state`.
- `POST /v1/reminder-occurrences/{id}/acknowledge` — `acknowledged` |
  `postponed` | `cancelled`.

**Division of labour with Shanks:** the *device* owns scheduling and firing
(local notifications, permission handling, restart recovery, time-zone changes).
The *server* owns definitions and the occurrence/acknowledgement log. The server
never delivers a notification and is not required to be reachable for a reminder
to fire. `schedule_version` lets the device detect that a definition changed
while it was offline and reschedule.

**Acknowledgement is not medication adherence.** The field is
`acknowledgement_state`, deliberately not `taken`/`completed`. The API has no
concept of a dose, a prescription or adherence.

---

## 11. Doctor boundaries

Scope per the roadmap (S27/S36-S38). **Frontend platform is undecided** — these
are plain JSON endpoints and assume nothing about mobile vs. web.

- `GET /v1/doctor/patients` — only non-revoked assignments.
- `GET /v1/doctor/patients/{id}/sessions` — paginated history.
- `GET /v1/doctor/patients/{id}/summary` — same shape as §8.
- `POST /v1/patients/{id}/notes`, `GET /v1/patients/{id}/notes` — attributed to
  the authenticated doctor, immutable once written.
- `POST /v1/patients/{id}/reports`, `GET /v1/reports/{id}` — generated draft,
  citing source session IDs, versions and limitations.

**Assignment is the only access path.** Direct session/report/media IDs are
checked the same way as list routes — tested explicitly, because that is how
this kind of thing actually leaks. Doctor role is provisioned server-side only
(`scripts/grant_doctor.py`); no endpoint promotes a caller to doctor.

Per the handbook, **caregiver confirmation still activates any change**,
including a doctor-originated suggestion. Final authority remains an open
planning decision and is *not* silently settled by this implementation.

---

## 12. Optional LLM text - what it may and may not do

Off by default (`LLM_ENABLED=false`). It is a **server-side adapter**
(`app/llm/`), never called from the device.

**May:** phrase an already-computed, already-approved set of facts into a
caregiver-readable sentence.

**Must not, and cannot by construction:**
- invent, adjust or recompute a metric — it receives numbers, and the response
  is validated against those exact numbers before use;
- diagnose, or state/predict disease progression;
- recommend treatment or medication;
- change any activity setting — it has no write path;
- receive patient names, personal words, media, or raw clinical fields. The
  payload builder allow-lists de-identified computed values only, and a test
  asserts that a patient's name never appears in a built prompt.

Deterministic template text is the primary implementation; the LLM is an
optional rewrite. On timeout, error, or failed validation the template text is
used and the response is marked `"generator": "template"`. Insufficient data
produces an explicit insufficient-data message, never a guess.

---

## 13. Health and setup

`GET /v1/health` → `{"status": "ok", "app_env", "auth_mode", "database": "ok", "migration_revision": "0001", "version"}`.
No authentication. Never returns 200 when the database is unreachable.

Setup, environment template and migrations: `services/api/README.md` and
`services/api/.env.example`. **No credential is committed.** All fixtures are
synthetic.

---

## 14. Open questions for Shanks

1. **P1** — do you want the host to send `elapsed_ms`, or should the server
   accept `elapsedMs` as an alias? Cheap either way, but pick one now.
2. **P4** — can the host reliably report `actual_input_mode` after the
   gyroscope check? If not, tell me and I will treat every Marble Maze session
   as `input_mode_unverified`.
3. Outbox batch size — I capped a batch at 500 events. A whole Route Quest
   session is well under that; confirm nothing on your side wants larger.
4. Do you want `PUT /v1/sessions/{id}` to accept an already-complete session in
   one call (create + events + complete), for a short offline session? It is not
   implemented; the three-call order is currently required.

Send corrections to Pranav before writing the telemetry adapter against this.
