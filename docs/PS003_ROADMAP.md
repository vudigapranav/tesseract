# PS003 shared roadmap

Revision 2 - 6 September 2026. This is the active 40-package plan. S01-S30 IDs are retained with revised scope; S31-S40 cover explicit additional games, doctor screens and full release. Supersedes previous dated/conditional assignments. Dates will be set from capacity; phases A-F are dependency milestones, not calendar promises.

Status: all packages NOT STARTED / not accepted. Initial backend setup was previously begun, but S08 acceptance is unverified. Documentation completion does not establish application completion. Confirmed game counts: Aryan 5, Ruthika 2, Pranav 2. Exact mapping below is the working proposal. Shanks retains frontend architecture/integration; Pranav retains backend/AI architecture.

Common definition of done: reviewed, merged, documented, integrated and tested with build/device/session evidence. Shanks reviews frontend, Pranav backend/AI, and peers review lead-authored code. Kovid coordinates manual QA. Every game package includes its calculator/fixture integration into S13's registry and its contribution to the approved activity loop. Dependencies are acceptance gates; fixture-based design can start earlier. Required full-release work cannot be silently reclassified as optional.

## S01 - Scope, assignment and claim register

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Pranav
- Collaborators: Aryan, Kovid, Shanks
- Dependencies: none
- Modules: docs/product, docs/research
- Deliverable: Record 5/2/2 counts, full P/C/D scope and exact mapping proposal; choose portal direction and schedule assumptions.
- Acceptance / integration: Confirmed requirements and proposals distinguished; member capacity and unresolved dates visible.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S02 - Repository and review rules

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Aryan
- Dependencies: S01
- Modules: repository, docs/workflow
- Deliverable: Set branch protection, PR checklist and shared contribution boundaries.
- Acceptance / integration: No direct main pushes; frontend/backend reviewers defined; module owners can follow one setup.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S03 - Accessible design system and screen map

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Maharshitha
- Collaborators: Shanks, Kovid
- Dependencies: S01
- Modules: Figma, mobile shared widgets, portal design
- Deliverable: Design P1-P9, C1-C7 and D1-D8 plus empty/error/offline states.
- Acceptance / integration: All 24 IDs mapped; large controls, text scaling, help/break and protected handover specified.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S04 - Nine-game event and metric contract

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Ruthika
- Collaborators: Pranav, Shanks, game owners
- Dependencies: S01
- Modules: docs/contracts, analytics fixtures
- Deliverable: Define common envelope/config and G1-G9 events, denominators and sample fixtures.
- Acceptance / integration: Null/assisted/interrupted cases defined; coloring has no accuracy; Pranav reviews versions.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S05 - Database and API contracts

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Pranav
- Collaborators: Ruthika, Shanks
- Dependencies: S04
- Modules: docs/contracts, API schemas
- Deliverable: Freeze identity, membership, profile, session, metrics, decisions, reminders, doctor notes/report fixtures.
- Acceptance / integration: Errors, deduplication, final_seq, config conflicts and assignment permissions specified.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S06 - Flutter shell and common game host

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Shanks
- Collaborators: Maharshitha, Pranav
- Dependencies: S02, S03, S05
- Modules: apps/mobile/lib/core, shared game host
- Deliverable: Create navigation, lifecycle, telemetry adapter and a runnable fixture game example.
- Acceptance / integration: Owners use the same host; pause/background/finish state is shared; target-phone launch verified.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S07 - QA setup and regional evidence

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Kovid
- Collaborators: Aryan, Maharshitha
- Dependencies: S01
- Modules: docs/qa, docs/research
- Deliverable: Create mobile-friendly checklist, source register and content-language review process.
- Acceptance / integration: Build/device/evidence fields present; synthetic profiles labelled; native reviewer need recorded.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S08 - Backend skeleton and identity

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Pranav
- Collaborators: Ruthika, Aryan
- Dependencies: S02, S05
- Modules: services/api/app/auth, migrations
- Deliverable: Review initial packaging; build health/migrations and verified identity with patient membership.
- Acceptance / integration: Real health/migration evidence; missing identity and cross-patient requests rejected.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S09 - Patient and Know Me services

- Status: NOT STARTED
- Milestone: Phase A (date unscheduled)
- Primary owner: Pranav
- Collaborators: Ruthika, Aryan
- Dependencies: S08
- Modules: services/api/app/patients, content
- Deliverable: Implement owned patient profile, optional clinical fields and versioned approved personal content.
- Acceptance / integration: Create/read/edit real records; fewer words/skip supported; private assets respect membership.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S10 - Profile, patient home and handover screens

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Maharshitha
- Collaborators: Shanks, Pranav
- Dependencies: S03, S06, S09
- Modules: mobile features/profile, home, caregiver
- Deliverable: Build C1-C3 and C5 components; connect P1/P2/P7 selection using approved content.
- Acceptance / integration: Real profile save and protected handover; empty/offline/missing content handled.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S11 - G1 Reveal Match

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Aryan
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S04, S06
- Modules: mobile games/reveal_match
- Deliverable: Deliver 2/3/4-pair presets, gentle matching, hints, tutorial and shared events.
- Acceptance / integration: 4 matches / 6 attempts = 66.7%; zero attempts null; double taps ignored; pause state retained.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S12 - Session and event ingestion

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Ruthika
- Collaborators: Pranav
- Dependencies: S05, S08
- Modules: API sessions, events
- Deliverable: Persist idempotent sessions/batches and completion with final_seq.
- Acceptance / integration: Retry dedupes; gaps block final metrics; conflicting IDs/payloads rejected.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S13 - Versioned game calculators

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Ruthika
- Collaborators: Pranav, game owners
- Dependencies: S04, S12
- Modules: API analytics, tests
- Deliverable: Build calculator registry starting with G1; each game owner supplies fixtures for its module.
- Acceptance / integration: G1 hand calculations pass; additional calculators accepted with corresponding game package; support and missing data preserved.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S14 - Persistent outbox and sync UI

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Shanks
- Collaborators: Pranav, Ruthika
- Dependencies: S06, S12
- Modules: mobile core/storage, repositories, C7
- Deliverable: Persist events before upload; show pending queue, last sync and expired identity.
- Acceptance / integration: Restart retains IDs/events; create-batch-complete order honored; no silent pending-data deletion.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S15 - Caregiver home and simple progress

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Maharshitha
- Collaborators: Shanks, Pranav
- Dependencies: S06, S10, S13
- Modules: mobile caregiver, progress, rest
- Deliverable: Deliver C4 history/observations/alerts and P8 rest/P9 simple progress.
- Acceptance / integration: No-data/stale states and basic alerts accurate; patient progress has no clinical scoreboard.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S16 - Recommendation and configuration engine

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Pranav
- Collaborators: Ruthika
- Dependencies: S12, S13
- Modules: API recommendations
- Deliverable: Implement reviewed versioned proposals and per-level G1 eligibility from the updated guide.
- Acceptance / integration: Hold on insufficient data; 2/3-pair perfect starter progression test; ceilings and conflicts tested; no speed-only progression.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S17 - Provisional reference and comparable series

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Ruthika
- Collaborators: Pranav, Shanks
- Dependencies: S13, S14
- Modules: analytics baseline, summaries
- Deliverable: Use first three eligible comparable sessions; stratify level, mode, support and content/task version.
- Acceptance / integration: Tutorial excluded; changed configuration splits series; insufficient-data label; percentage-point calculations verified.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S18 - Patient lifecycle and caregiver decision loop

- Status: NOT STARTED
- Milestone: Phase B (date unscheduled)
- Primary owner: Shanks
- Collaborators: Pranav, Maharshitha, Aryan
- Dependencies: S10, S11, S12, S13, S14, S15, S16, S17
- Modules: mobile P1-P9, C4/C5, API decisions
- Deliverable: Integrate P3-P6 tutorial/play/break/finish and complete reviewed next-activity loop.
- Acceptance / integration: Real session -> metrics -> pending decision -> approved next activity passes; P5 paused game differs from P8 rest.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S19 - G7 Personalized Word Search

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Ruthika
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S18, S29
- Modules: mobile games/word_search, analytics
- Deliverable: Generate small reproducible grids using approved personal words and supported scripts.
- Acceptance / integration: Few/duplicate/long words handled; grapheme-safe placements verified; valid-selection fixture reaches stored metrics.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S20 - Required independent reminders

- Status: NOT STARTED
- Milestone: Phase C (date unscheduled)
- Primary owner: Maharshitha
- Collaborators: Shanks, Pranav, Kovid
- Dependencies: S06, S09, S14
- Modules: mobile reminders C6, API reminders
- Deliverable: Build reminder editor/cards; Shanks owns local scheduler and Pranav reminder persistence.
- Acceptance / integration: Works without games; permission/restart/time-zone/edit/cancel cases pass; acknowledge differs from completion.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S21 - Interim end-to-end QA and seeds

- Status: NOT STARTED
- Milestone: Phase C (date unscheduled)
- Primary owner: Kovid
- Collaborators: Aryan, all owners
- Dependencies: S18, S20
- Modules: docs/qa, synthetic seeds
- Deliverable: Run patient/caregiver loop, independent reminders and metric evidence on target build.
- Acceptance / integration: Real device/build/session IDs recorded; synthetic trend labels; defects assigned.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S22 - Replay and access hardening

- Status: NOT STARTED
- Milestone: Phase C (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Ruthika, Kovid
- Dependencies: S14, S18, S21
- Modules: sync, API authorization
- Deliverable: Harden duplicate/reordered uploads, interrupted sessions and direct-ID access checks.
- Acceptance / integration: One correct session after retries; unauthorized patient writes/reads rejected; finalization conflicts tested.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S23 - Patient usability and language verification

- Status: NOT STARTED
- Milestone: Phase C (date unscheduled)
- Primary owner: Maharshitha
- Collaborators: Shanks, Kovid
- Dependencies: S18, S20, S21
- Modules: shared widgets, content packs
- Deliverable: Verify larger text, controls, contrast, calm copy, skip/help and pilot script/audio.
- Acceptance / integration: Chosen phone evidence; unsupported/unreviewed language and voice claims labelled.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S24 - Interim demo checkpoint

- Status: NOT STARTED
- Milestone: Phase C (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Aryan, Kovid
- Dependencies: S22, S23, S25
- Modules: release, docs/demo
- Deliverable: Tag and rehearse the verified patient/caregiver subset with required reminders.
- Acceptance / integration: Two repeatable demo runs; remaining games/portal explicitly planned; not full-release completion.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S25 - Complete offline replay and settings

- Status: NOT STARTED
- Milestone: Phase C (date unscheduled)
- Primary owner: Shanks
- Collaborators: Pranav, Kovid
- Dependencies: S14, S20, S22
- Modules: mobile sync, C7, API ingestion
- Deliverable: Finish cached-content replay, settings/conflicts and local reminder recovery.
- Acceptance / integration: Airplane play -> restart -> reconnect twice creates one session; reminders independent; pending/synced state correct.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S26 - G2 Memory / Route Quest

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S18, S29
- Modules: mobile games/route_quest, analytics
- Deliverable: Small 2D destination/flag/return map with touch controls and route-help events.
- Acceptance / integration: Shortest 12 / actual 18 = 66.7% on completed round trip; partial efficiency null; return requires flag.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S27 - Doctor identity and assignment services

- Status: NOT STARTED
- Milestone: Phase E (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Ruthika, Kovid
- Dependencies: S05, S08, S09
- Modules: API doctor assignments, reviewer access
- Deliverable: Provision verified doctor membership and assigned-patient list/detail permissions.
- Acceptance / integration: Multiple assigned patients supported; unassigned direct session/report/media access denied; revocation behavior defined.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S28 - G3 Marble Maze

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S26
- Modules: mobile games/marble_maze, analytics
- Deliverable: Forgiving maze with touch and optional calibrated tilt; versioned physics/path events.
- Acceptance / integration: No-gyro touch fallback; continuous contact counts once; 100/125 = 80%; input modes separated.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S29 - Shared approved game content packs

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Maharshitha
- Collaborators: Shanks, Kovid, game owners
- Dependencies: S03, S06, S09
- Modules: content packs, shared asset loader
- Deliverable: Prepare approved images, masks, target regions, routines and question templates for all games.
- Acceptance / integration: Opaque IDs/versions; private content preview/remove/skip; missing content fallback; language/font checks.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S30 - Final evidence and pitch alignment

- Status: NOT STARTED
- Milestone: Phase F (date unscheduled)
- Primary owner: Aryan
- Collaborators: Pranav, Maharshitha, Kovid
- Dependencies: S39
- Modules: docs/demo, claim register
- Deliverable: Reconcile pitch/demo narrative against tested full-build features and remaining limitations.
- Acceptance / integration: Every offline/game/report claim maps to evidence; synthetic data labelled; PPT edits require separate user request.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S31 - G8 Daily Routine Recall

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Ruthika
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S18, S29
- Modules: mobile games/routine_recall, analytics
- Deliverable: Caregiver-defined 2-4-step routine with picture choices and replay support.
- Acceptance / integration: 2 first-correct / 3 questions = 66.7% despite later correction; edits version answer key; independent reminders preserved.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S32 - G5 Swipe-to-reveal Coloring

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Aryan
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S18, S29
- Modules: mobile games/coloring, analytics
- Deliverable: Broad strokes reveal original colors; save mask; show-picture/help/skip controls.
- Acceptance / integration: Repeat strokes do not raise unique coverage; manual/help coverage separate; no palette, accuracy or forced completion.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S33 - G6 Spot Difference

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Aryan
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S32
- Modules: mobile games/spot_difference, analytics
- Deliverable: 1-3 obvious differences with generous hit regions and hints.
- Acceptance / integration: Two correct/one false = 66.7% precision; repeated found-region taps excluded; unique discovery separate.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S34 - G9 Picture Recall

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Aryan
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S33
- Modules: mobile games/picture_recall, analytics
- Deliverable: Approved image/question pairs, patient-controlled preview and show-again support.
- Acceptance / integration: First-attempt accuracy preserved; re-show flags supported responses; no live AI identity guesses.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S35 - G4 Trace

- Status: NOT STARTED
- Milestone: Phase D (date unscheduled)
- Primary owner: Aryan
- Collaborators: Shanks, Pranav, Maharshitha, Kovid
- Dependencies: S34
- Modules: mobile games/trace, analytics
- Deliverable: Broad corridor paths, short strokes, guide support and normalized geometry.
- Acceptance / integration: 8/10 unique bins = 80%; retracing adds none; pause state and size normalization verified.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S36 - Doctor portal D1-D4

- Status: NOT STARTED
- Milestone: Phase E (date unscheduled)
- Primary owner: Shanks
- Collaborators: Maharshitha, Pranav, Kovid
- Dependencies: S03, S13, S27
- Modules: doctor frontend, API history
- Deliverable: Build sign-in, assigned caseload, overview and session history with Maharshitha components.
- Acceptance / integration: Multiple assigned patients; dates/game/config/status filters; no-data/stale/error states; real API permissions.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S37 - Doctor analytics, trends and report D5-D7

- Status: NOT STARTED
- Milestone: Phase E (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Ruthika, Maharshitha
- Dependencies: S16, S17, S36
- Modules: API analytics/reports, doctor views
- Deliverable: Deliver observation groupings, comparable 7/30-day series and sourced generated draft; Shanks integrates views.
- Acceptance / integration: Sample count/freshness and source IDs present; no invented clinical scores; report numbers reconcile to sessions.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S38 - Doctor notes and recommendations D8

- Status: NOT STARTED
- Milestone: Phase E (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Maharshitha, Kovid
- Dependencies: S16, S36
- Modules: API notes/decisions, doctor D8
- Deliverable: Persist attributed notes and versioned suggestions, using the recorded application-authority policy.
- Acceptance / integration: Notes separate from AI draft; audit/reviewer status retained; stale proposal cannot overwrite newer config.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S39 - Full catalogue and portal regression

- Status: NOT STARTED
- Milestone: Phase F (date unscheduled)
- Primary owner: Kovid
- Collaborators: All owners
- Dependencies: S19, S24, S25, S28, S31, S35, S37, S38
- Modules: docs/qa, integrated mobile/API/portal
- Deliverable: Run all nine games and all P1-P9/C1-C7/D1-D8 screens through real persistence and access boundaries.
- Acceptance / integration: Each game fixture passes; offline retry, pause/help, reminders, doctor assignments and reviewed decisions pass; no release blockers.
- Review / QA: common definition of done above; attach verified evidence before acceptance.

## S40 - Full product release and handoff

- Status: NOT STARTED
- Milestone: Phase F (date unscheduled)
- Primary owner: Pranav
- Collaborators: Shanks, Aryan, Kovid
- Dependencies: S30, S39
- Modules: release, docs/status
- Deliverable: Tag reproducible mobile/backend/portal release with setup, evidence, limitations and recovery instructions.
- Acceptance / integration: All required scope accounted for; final regression/build links and two rehearsals recorded; continuity updated.
- Review / QA: common definition of done above; attach verified evidence before acceptance.
