# Claude work file — Tesseract (SIH26003)

Last updated: 2026-09-05. Owner of this file: Claude (working with Pranav).

## What Claude owns in this project

Frontend design only, so far. Claude has produced the screen-level design
specification for the patient and caregiver experiences. Claude has written
**no application code** in this repository and has not edited any file
outside this `By claude/` folder.

Backend implementation in `services/` is being done by Astra (see
`../Astra.md`). Claude has not modified it and will not without being asked.

## Deliverable in this folder

- `Tesseract_Frontend_Design.pdf` — 33 pages, A4 landscape. Every screen of
  both modes with callouts, interaction rules, state coverage, data contracts,
  and a screen-to-owner-to-work-package table.
- `STATE.md` — what has been done, against the S-numbers in `../docs/PS003_ROADMAP.md`.

## Scope of the design spec

21 screens: 8 patient mode (P1–P8), 13 caregiver mode (C1–C13). Two of them
(P7 Personalized Word Search, C11 Routine reminders) are conditional and ship
only if the Sep 7 gate passes.

Conventions used throughout:

- Every measurement inside a phone frame is real Android **dp**; frames are
  360 × 740 dp.
- Sample content uses one synthetic family — Kamala (72, patient) and her
  daughter Bidisha (caregiver). No real patient data anywhere.
- Product rules from `../PS003_MASTER_CONTEXT.md` are treated as binding:
  no diagnosis, no inferred stage, no cognitive-domain scores, caregiver
  approves every adaptive change, gentle language with no failure scoreboard.

## Rules the design treats as release blockers

A screen that scores the patient. A chart of a cognitive domain. A difficulty
that changes without a caregiver decision. A language claimed as supported
without a native reviewer. Any of these is a blocker, not a preference.

## What Claude needs from the backend pass to go further

1. Generated OpenAPI for the v0.1 endpoints.
2. The base URL the Flutter app should hit on Sep 6, and how to run it locally.
3. One example Reveal Match session — request and response JSON for
   `PUT /v1/sessions/{client_uuid}`, `POST /v1/sessions/{id}/events:batch`,
   `POST /v1/sessions/{id}/complete`, and `GET /v1/patients/{id}/summary`.
4. Confirmation of the recommendation decision payload shape used by C8/C9.

The endpoint and table names quoted in the design PDF were taken from
`../docs/PS003_BUILD_HANDBOOK.md`. If the implemented contract differs, the
implementation wins and the PDF should be corrected, not the other way round.

## Still-open decisions that block frontend work

- Flutter state-management approach (unchosen).
- Backend base URL reachable from the test device.
- Whether v0.1 contracts exist as committed JSON fixtures rather than prose.

## Ground rules Claude is following in this folder

- Non-code deliverables go in `By claude/`. Nothing else in the project is
  touched without being asked.
- The supplied six-slide SIH PPT is left unchanged.
- Nothing planned is described as implemented.
