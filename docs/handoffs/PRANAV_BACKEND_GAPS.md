# Backend handoff for Pranav — 2026-09-08

Two gaps, verified against the code in `services/api` on this date, not
inherited from an older note. Pranav owns the API contract and every analytics
decision here; this file states exactly what the client already sends and what
it currently cannot do, and proposes nothing that changes an existing contract.

Nothing in this file has been implemented. No route or calculator was added,
renamed or redefined by the client work.

---

## Gap 1 — no patient-basics update endpoint

**Verified.** `services/api/app/patients/router.py` has:

```
POST   /patients                              create
GET    /patients                              list
GET    /patients/{patient_id}                 read
GET    /patients/{patient_id}/personalization
PUT    /patients/{patient_id}/personalization
GET    /patients/{patient_id}/activity
```

There is no `PATCH`/`PUT /patients/{patient_id}`. A caregiver can create a
patient and can update personalization, but cannot change the patient's basics
afterwards.

**Client behaviour today.** Patient Basics edits are kept on the device and are
labelled local-only in the UI. They are not uploaded and are not described as
synced. That stays true until an endpoint exists — the client will not invent a
write path.

**What the client would send, if you add one.** Same field names as
`PatientCreate` already accepts, so no new vocabulary:

```http
PATCH /patients/{patient_id}
Content-Type: application/json
If-Match: "<profile_revision the client last read>"

{ "display_name": "...", "language": "bn", "notes": "..." }
```

Two requests, both matching how personalization already behaves so the client
needs no new conflict logic:

* Optimistic concurrency on the existing `profile_revision`, with **409** when
  the client's revision is stale. The client already handles a 409 on
  personalization by keeping local edits and offering an explicit review — it
  would reuse that exact path. Please do not resolve conflicts last-write-wins.
* **403**, not 404, when the caller may not access that patient, consistent
  with the existing access checks.

**Open question for you:** whether `language` belongs in basics at all, or
whether patient language should stay a device preference. The client currently
treats it as both — it is sent at creation and also stored locally. Your call.

---

## Gap 2 — eight event types have no calculator

**Verified.** None of these eight strings appears anywhere under
`services/api/app/`. Sessions carrying them upload and store correctly, and
then produce no game-specific metric.

These are emitted by three already-integrated games. Payloads below are copied
from the emitting line, not from memory. **Every id is opaque** — no word,
name, or routine text is in any of them, and each game package has a test that
keeps it that way.

### Daily Routine Recall (`routine_recall`)

| Event | Payload | Emitted when |
|---|---|---|
| `step_presented` | `{"stepId": "<id>"}` | a routine step is shown |
| `attempt_resolved` | `{"stepId": "<id>", "chosenId": "<id>", "correct": bool, "attempt": int}` | the person picks an option; `attempt` is 1-based within the step |

### Word Search (`word_search`)

| Event | Payload | Emitted when |
|---|---|---|
| `word_found` | `{"wordId": "<id>"}` | a word is correctly selected |
| `selection_rejected` | `{"cellCount": int}` | a drag matched no word |
| `all_words_found` | *(none)* | last word found; session completes |
| `content_unavailable` | `{"reason": "word_does_not_fit_grid", "wordIds": ["<id>", …]}` | a caregiver's word could not be placed |

### Picture Sorting (`picture_sorting`)

| Event | Payload | Emitted when |
|---|---|---|
| `item_sorted` | `{"itemId": "<id>", "categoryId": "<id>", "correct": bool, "attempt": int}` | a picture is placed in a category |
| `sorting_completed` | *(none)* | every picture sorted |

### What the client asks for, and what it does not

The client needs **nothing** to keep working — these sessions already upload.
What it cannot do today is show a caregiver anything specific about these three
games.

Deliberately **not** proposed here: any metric name, formula, threshold, or
clinical interpretation. Defining what "first-attempt accuracy" means, whether
`selection_rejected` counts against anything, and whether any of it may inform
a recommendation are all yours. The client will not invent them, and it will
not render a metric it has not been given.

Until a calculator exists, the caregiver UI shows these measures as
**unavailable**. It does not show zero. A fabricated zero reads as "they got
none right", which is a clinically misleading statement about a real person.

### Test fixtures

A session that exercises all eight, ready to POST through the existing
create → events → complete calls:

```json
[
  {"type": "step_presented",     "seq": 1, "elapsed_ms": 0,     "payload": {"stepId": "s1"}},
  {"type": "attempt_resolved",   "seq": 2, "elapsed_ms": 2400,  "payload": {"stepId": "s1", "chosenId": "o2", "correct": false, "attempt": 1}},
  {"type": "attempt_resolved",   "seq": 3, "elapsed_ms": 5100,  "payload": {"stepId": "s1", "chosenId": "o1", "correct": true,  "attempt": 2}},
  {"type": "selection_rejected", "seq": 4, "elapsed_ms": 7000,  "payload": {"cellCount": 4}},
  {"type": "word_found",         "seq": 5, "elapsed_ms": 9300,  "payload": {"wordId": "w1"}},
  {"type": "content_unavailable","seq": 6, "elapsed_ms": 9310,  "payload": {"reason": "word_does_not_fit_grid", "wordIds": ["w7"]}},
  {"type": "all_words_found",    "seq": 7, "elapsed_ms": 12000, "payload": {}},
  {"type": "item_sorted",        "seq": 8, "elapsed_ms": 14000, "payload": {"itemId": "i1", "categoryId": "c2", "correct": true, "attempt": 1}},
  {"type": "sorting_completed",  "seq": 9, "elapsed_ms": 16000, "payload": {}}
]
```

Worth covering when you write the calculators: `attempt` greater than 1,
`all_words_found` absent (session ended early via Break → Finish now), and
`content_unavailable` with several `wordIds`.

---

## Also worth knowing

**Firebase is now real.** Project `tesseract-3ac5a` has Email/Password enabled
and a registered Web app as of 2026-09-08, and the client's sign-in and token
refresh were verified live against `identitytoolkit.googleapis.com` and
`securetoken.googleapis.com`. The API can therefore be moved to
`AUTH_MODE=firebase` whenever you want — it needs `FIREBASE_PROJECT_ID` and a
service-account file placed outside the repository, which is yours to download.
Nobody has pasted or stored a private key.

**The client requires HTTPS.** `IdentityService.configured` demands
`TESSERACT_API_URL` start with `https://`, so a plain `http://localhost` backend
is refused by design. Verifying the full client → Firebase → API path needs
either an HTTPS deployment or an HTTPS tunnel to a local instance.
