# PS003 Master Context

Updated: 2026-09-06. Project: Tesseract. User-supplied SIH26003, AI-Based Cognitive Gaming and Memory Assistance Platform for Elderly Dementia Patients in the North Eastern Region. Official listing not independently verified.

## Read this first

Latest user clarification (2026-09-06): confirmed game counts are Aryan five, Ruthika two, Pranav two. Read `docs/PS003_GAME_ASSIGNMENTS_AND_UI.md` for the requested P1-P9 / C1-C7 / D1-D8 screen model, proposed exact game assignments, per-game analytics/difficulty and complete PPT explanation. Exact game mapping, numerical presets and doctor portal technology remain proposals. Shanks retains shared Flutter architecture and frontend integration; Pranav retains backend/AI architecture. This documentation request does not authorize new app coding. Read `docs/PS003_PATIENT_EXPERIENCE.md` for swipe-to-reveal coloring and required main-app reminders. Supportive, personal experiences and routine assistance are central; do not promise memory recovery or guaranteed happiness.

The team brief is authoritative for fixed requirements and ownership. Proposed narrowing and architecture decisions below are recommendations from the initial review, not a claim of user approval. Do not start application coding until requested. Maintain one product and shared contracts; never independently redesign a member’s module.

## Persistent project records

- `docs/PS003_ORIGINAL_TEAM_BRIEF.md`: complete original context, including all nine games, patient profile domains and AI-tool preferences.
- `docs/PS003_BUILD_HANDBOOK.md`: full review, proposed architecture, schema, API/event contracts, analytics, workflow, scope gates and PPT corrections.
- `docs/PS003_ROADMAP.md`: 40 shared work packages with owner, collaborators, dependencies, module boundaries and acceptance criteria.
- `output/pdf/Tesseract_Build_Plan_and_Review.pdf`: shareable handbook.
- Existing six-slide PPT remains unchanged.

## Fixed team ownership

Pranav: two game modules plus technical lead, backend AND AI/analytics architecture, database/contracts, review and final integration; Claude Pro. Do not make him code every module.
Shanks: primary Flutter architect, patient frontend, shared game host and frontend integration; Gemini Pro.
Maharshitha: design system, Figma, bounded screens/components under Shanks, research and PPT; Gemini Pro.
Ruthika: two game modules plus bounded backend/session/analytics modules under Pranav, metric fixtures and research; Gemini Pro unconfirmed.
Aryan: five game modules, pitch/product, truthful claims, synthetic seed data and API smoke tests; defer unrelated backend help during game delivery; ChatGPT Plus.
Kovid: research, regional needs, ethics, manual QA and documentation through mobile-friendly tools; no coding requirement.

## Product rules

Caregiver manages profile; patient feels supported. Known dementia type/stage is optional clinical context, not inferred from games. Support Alzheimer’s, frontotemporal, Lewy body, vascular, mixed/other/unknown as entered. Personalisation uses people, places, interests and a target of 15–20 meaningful words. Allow skipped/fewer words.

Required full catalogue includes Reveal Match, Memory/Route Quest, Marble Maze with touch option, Trace, Coloring, Spot Difference, Personalized Word Search, Daily Routine Recall and Picture Recall. Long-term cognitive/functional areas include memory, attention, executive, visuospatial, language, processing speed, motor interaction and engagement. These are not validated scores simply because the product names them.

No diagnosis, cure or disease-progression inference. Observable game metrics first. A baseline means provisional individual app performance. Gentle language, readable controls, pause and exit, no failure scoreboard. Recommendations are explained and accepted/modified by a caregiver or assigned healthcare worker. No patient information or secrets in AI prompts.

## Proposed implementation default

Single Android-first Flutter app with patient/caregiver modes; Flutter games, Flame only when needed. FastAPI modular backend; PostgreSQL; SQLite local outbox/cache; Firebase caregiver identity with backend verification and patient access checks. Local scheduling for offline reminders. Required doctor portal D1-D8 supports multiple assigned patients, history, analytics, reports and notes through the same API. Responsive web frontend and its technology remain proposed. Defer another game engine, microservices and trained ML. See handbook for schemas and API contracts; no implementation or dependency versions are frozen yet.

Doctor assignments, notes, reports, reminders and observations belong in the required full-scope schema.

Proposed folders: `apps/mobile/lib/core`, `apps/mobile/lib/features`, `apps/mobile/lib/games`, `services/api/app/{auth,patients,sessions,analytics,recommendations}`, `services/api/tests`, `docs/{contracts,research,qa}`. These are planned module boundaries, not existing application folders.

## Active build plan and milestones

Revision 2 (2026-09-06) replaces stale conditional catalogue/reminder scope and dated upgrade promises. Phase A: foundation S01-S09. B: first integrated loop S10-S18. C: required support, offline and interim demo S20-S25. D: remaining catalogue S19/S26/S28/S29/S31-S35. E: doctor services/screens S27/S36-S38. F: full regression S39, pitch S30, release S40. The roadmap defines exact dependencies; task number does not imply execution order.

S01-S30 IDs are retained, with S31-S40 added for explicit games/doctor/full-release work. S24 is an interim demo, not full completion. S25 replay must pass before S24. Nine games, reminders and all 24 requested screens are required for S40. Prior September 5-10 dates are historical targets; a new completion date needs member availability and capacity. No milestone is marked implemented by planning.

Working exact game mapping: Aryan Reveal Match/Coloring/Spot Difference/Picture Recall/Trace; Ruthika Word Search/Routine Recall; Pranav Route Quest/Marble Maze. Counts are confirmed; exact mapping remains proposed. Shanks retains shared Flutter ownership. The build handbook and 40-package roadmap now use this mapping consistently.

## Integration rules

One repo, main/develop, small feature branches, PR review, integrated QA. No direct main pushes. Shanks reviews frontend, Pranav backend/AI, peers review lead-authored work. Kovid coordinates manual cases. Task contracts include exact scope, fixtures, allowed files, dependencies, acceptance and reviewer. Context/schema updates accompany contract changes. Code alone is not done: merged + tested + documented + integrated + end-to-end verified.

## Current status

2026-09-06 additions-only delivery: at the user's clarification, created `Tesseract_Additions_Only.pdf` directly in the project root. It preserves full reviewed detail for A1-A7 and their screen/contract/build impacts without reproducing the full existing specification. All 14 pages rendered and visually inspected; A1-A7 presence checked. The longer root PDF is preserved. This is documentation only; no application status changed.

2026-09-06 additions-review PDF milestone: reviewed `PS003_ADDITIONS.md` and created the requested root-level `Tesseract_Updated_Plan_With_Additions.pdf`. It contains the existing product specification plus all seven additions, corrected event/accessibility/comparability assumptions, screen deltas and proposed S41-S47 handoffs. All 39 pages were rendered and visually inspected; screen/game/addition identifiers checked. This is an integrated planning proposal, not application implementation or blanket acceptance of experimental rules. The active roadmap remains the 40-package revision until adoption scope is recorded; the supplied PPT, original additions file and existing PDFs were preserved.

2026-09-06 build-plan revision milestone: rewrote the active handbook and roadmap for the 5/2/2 catalogue, all P/C/D screens, required reminders, shared metrics/difficulty, doctor access/reports/notes, and staged release gates. Expanded to 40 packages while retaining S01-S30 IDs. Regenerated `output/pdf/Tesseract_Build_Plan_and_Review.pdf`. Verified documentation evidence: nine game tasks with owner counts 5/2/2; all 40 task IDs present; dependency graph valid and acyclic; all 35 PDF pages rendered and visually inspected. No application tests or implementation completion are claimed.

2026-09-06 documentation milestone: created `docs/PS003_GAME_ASSIGNMENTS_AND_UI.md` and the 25-page PDF `output/pdf/Tesseract_Product_UI_and_Nine_Game_Assignments.pdf`. Confirmed the 5/2/2 counts with the user. Read all six supplied PPT slides; PPT unchanged. Rendered and visually inspected all 25 PDF pages. No application work package is completed by this documentation milestone. Exact game mapping remains proposed. PDF QA is document evidence, not application test evidence.

Current work package: S01 planning prepared, awaiting team kickoff/decisions; not marked complete.
Completed in this planning pass: full original brief preserved, PPT content reviewed, relevant sources checked, proposed handbook and roadmap created.
Application work: implementation was authorized, and initial backend packaging/environment setup plus `Astra.md` were started before the user redirected the conversation to game allocation and patient experience. No working game, API implementation or passing application tests are established. The current request updates the build plan; no application code is being generated in this pass.

## Open decisions

Official PS URL/template rules, member availability, pilot language/native reviewer, test Android device, deployment account/budget and clinical feedback access. Proposed architecture defaults need lead confirmation before coding. Never treat unconfirmed services, encrypted storage, translations or device compatibility as implemented.

## Update protocol

After each milestone, update current S-number, status, completed work, real test evidence, outstanding bugs and next dependency-ready task. Preserve the original brief and record decisions with date and rationale. Ask for the relevant task when implementation begins; do not regenerate the whole architecture each turn.
