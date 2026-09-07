# Tesseract build handbook

## Tesseract | Revised build plan

SIH26003 - Revision 2 - 6 September 2026

### What changed

The build plan now covers all nine games, patient P1-P9, caregiver C1-C7 and doctor D1-D8. Aryan owns five games, Ruthika two and Pranav two. Reminders are required and independent of games. Coloring uses broad swipes to reveal original colors. The doctor portal includes multiple assigned patients, analytics, reports and notes.

### Decisions and planning assumptions

The 5/2/2 counts and screen structure are user requirements. Exact game mapping below is the working proposal from the product guide, adopted for scheduling without claiming explicit approval of each individual assignment. Technical stack details, numerical presets, report-generation service and doctor decision authority remain proposals. Shared architecture ownership stays fixed.

### Scope and evidence

This is the active build plan, replacing the earlier conditional catalogue and dated upgrade plan. The first working loop remains an intermediate gate; the full release requires nine games and all requested screens. No new delivery deadline is invented. Earlier September 5-8 and September 9-10 windows are historical targets requiring rescheduling against member availability.

Initial backend packaging/environment setup was previously started. No working game, complete API, passing application suite or integrated release is established in the project record. All acceptance packages remain NOT STARTED / not accepted until evidence exists. Updating this document does not complete application work.

### Related records

PS003_MASTER_CONTEXT.md is the entry point. PS003_ORIGINAL_TEAM_BRIEF.md preserves the original request. PS003_GAME_ASSIGNMENTS_AND_UI.md contains detailed screen/game briefs and the six-slide PPT explanation. PS003_PATIENT_EXPERIENCE.md preserves patient interaction decisions. PS003_ROADMAP.md is the authoritative 40-package tracker; S01-S30 IDs are retained and S31-S40 make expanded scope explicit. The supplied PPT remains unchanged.

## Solution review

My assessment: a credible product direction with an oversized initial scope.

### What deserves to stay

Know Me gives activities meaningful context. The caregiver is a realistic continuous-management user. A gentle patient interface, common game telemetry and explainable adaptation fit together. Clinical stage remains caregiver-entered context rather than a difficulty setting.

### What needs stronger justification

Nine games are a catalogue, not evidence of effectiveness. The strongest demonstration is that a personal profile changes content, observed play changes support, and the caregiver can understand and override the recommendation. Uniqueness is a hypothesis until competitor research compares those exact capabilities.

### Where the reasoning overreaches

Accuracy and speed mix cognition with literacy, vision, motor ability, familiarity, assistance and fatigue. A weighted formula does not establish a validated memory or executive-function score. Start with observable game metrics and within-person comparisons; defer domain scores until their mapping has evidence.

### Evidence boundary [1, 2]

The cited prevalence study supports the scale of the problem, not demand for this app. The Cochrane review supports small short-term benefits from cognitive stimulation programmes; much of the evidence concerns group delivery. It does not validate Tesseract, its games, or disease-progression measurement.

### Validation to earn next

Kovid and Ruthika should maintain a claim-to-source register. Maharshitha and Aryan should seek feedback on onboarding and caregiver effort. Any future work with patients needs an appropriate supervised process; the hackathon can use synthetic profiles and usability feedback without claiming clinical efficacy.

## Scope and release gates

### Phase A - Shared foundation

S01-S09 establish scope, assignments, design, event/API contracts, shell, QA process, identity and profile services. Shanks supplies one game-host example before individual contributors build modules. Pranav supplies versioned config and API fixtures. Doctor assignment and reminder schemas are part of these contracts, not later surprises.

### Phase B - First integrated loop

S10-S18 connect C1-C5 and the patient play path to Reveal Match, local persistence, metrics, a provisional reference and reviewed recommendations. S18 passes only when a real session changes the approved next-activity state. Additional game prototypes may use frozen fixtures, but their integration must use this same pipeline.

### Phase C - Required support and interim demo

S20-S25 finish independent local reminders, offline replay, access checks, patient rest/progress states and accessibility. S24 is an interim demo of the proven subset, not full product completion. S25 finishes offline testing before S24. A patient can receive reminders without ever opening a game.

### Phase D - Nine-game catalogue

S19, S26, S28, S29 and S31-S35 deliver the remaining games and approved content. Aryan integrates Coloring, Spot Difference, Picture Recall and Trace after Reveal Match. Ruthika delivers Routine Recall and Word Search after the shared metric foundation. Pranav delivers Route Quest then Maze while reserving integration time. These are required full-release packages; build order is adjustable, scope is not silently removed.

### Phase E - Doctor portal

S27 and S36-S38 deliver assignment-controlled access, all D1-D8 screens, comparable trends, grounded generated reports and attributed notes. Contract/design work can start in Phase A. Portal implementation can proceed alongside catalogue work when dependencies pass. A responsive web portal is proposed; its frontend technology is unresolved.

### Phase F - Full release

S39 verifies nine games and all 24 screens in one integrated system, including offline/sync and access behavior. S30 aligns the pitch with that evidence. S40 releases only after those gates pass. An incomplete full catalogue can still have a labelled interim demo, but cannot be marked a completed full product.

### Scheduling and capacity

Packages are bounded work units, not forty calendar sprints. Use dependencies and daily owner capacity to assign dates at kickoff. Game counts do not imply equal effort. Protect two integration/review windows for Pranav and sequence each contributor's work to avoid simultaneous unfinished modules. Full offline support and reminders no longer wait for a post-demo upgrade window.

## Six members, clear ownership

### Pranav - architecture, backend, AI and two games

Own API/database contracts, identity/access architecture, recommendations, doctor backend and release integration. Proposed games: G2 Memory/Route Quest (S26) and G3 Marble Maze (S28). Keep the first route map small and maze controls forgiving. Shanks reviews his Flutter work; a peer reviews lead-authored changes. Claude Pro.

### Shanks - frontend architecture and integration

Own Flutter shell, navigation, state, game host, shared lifecycle, telemetry adapter, offline repository and frontend integration. Own P1-P9 integration and protected caregiver handover. Review all nine game contributions instead of being assigned all nine implementations. Lead the proposed doctor frontend after its technology is decided. Gemini Pro.

### Maharshitha - UI/UX and bounded screens

Own design tokens, Figma, caregiver C1-C7 components, reminder/settings views and content assets under Shanks's structure. Provide doctor screen designs/components under his review, plus research and PPT design. Do not independently establish another frontend architecture. Gemini Pro.

### Ruthika - analytics support and two games

Proposed games: G7 Personalized Word Search (S19) and G8 Daily Routine Recall (S31). Own bounded session ingestion and deterministic metric fixtures under Pranav. Shared analytics work precedes heavy puzzle work; game owners contribute their own expected fixtures. Pranav retains backend and AI architecture. Gemini Pro availability unconfirmed.

### Aryan - five game modules and product narrative

Proposed games: G1 Reveal Match (S11), G5 swipe-to-reveal Coloring (S32), G6 Spot Difference (S33), G9 Picture Recall (S34), G4 Trace (S35). Build in Shanks's host using approved contracts and assets. Retain pitch, synthetic seeds and smoke tests, but defer unrelated backend help while five-game delivery is active. ChatGPT Plus.

### Kovid - research and manual QA

Maintain claim sources, regional content needs, accessibility cases, bug triage and integrated evidence. Use a mobile-friendly checklist with build, device, expected/actual result and severity. Teammates perform device-only tests when needed. No coding requirement.

### Each game handoff

Deliver one module, approved content, versioned configuration, game events, expected metric fixtures, pause/help/exit behavior and device QA evidence. Frontend review: Shanks. Backend/AI review: Pranav. Kovid coordinates integrated QA. No separate game app, database or authentication flow.

## Proposed architecture

One repository, one Flutter architecture, one modular backend.

### Application boundary

Use Flutter for the Android patient and caregiver experience initially. Share widgets and contracts; role-specific navigation must be backed by server permissions. The full scope includes a doctor portal for multiple explicitly assigned patients. A responsive web frontend is proposed, with technology selected in S01/S06 and the same backend and metric contracts. Patient mode uses a restricted caregiver-mediated device session.

### Game boundary

Use Flutter components for the shared game catalogue; add Flame only where its game loop helps Route Quest or Maze. Defer Phaser/Godot to avoid embedding, lifecycle and telemetry integration work during the core window.

### Backend and data

FastAPI modules for patients, sessions, analytics and recommendations with PostgreSQL as server truth. Python metric functions are independent of route handlers. No microservices or training pipeline in the MVP. Lock dependencies after a small setup smoke test rather than inventing versions here.

### Local and identity

Choose SQLite for the proposed persistent outbox and cached profile/content. Firebase Authentication provides caregiver identity; FastAPI verifies identity and caregiver-patient membership. Use a caregiver-mediated patient device session. Firebase messaging is optional network delivery, not the offline reminder mechanism.

### Data flow

Caregiver profile -> cached content/config -> game -> local session/events -> authenticated upload -> PostgreSQL -> metric calculation -> pending recommendation -> caregiver decision -> next activity. Patient mode consumes approved activity settings.

### Proposed module ownership

apps/mobile/lib/core: Shanks. features/profile and shared widgets: Maharshitha, reviewed by Shanks. game host and repositories: Shanks; game modules: Aryan five, Ruthika two, Pranav two according to the working mapping. services/api/app/{auth,patients}: Pranav. {sessions,analytics}: Ruthika, reviewed by Pranav. recommendations and migrations: Pranav. services/api/tests: module owners with Aryan on smoke tests and synthetic seeds. Doctor frontend: Shanks with Maharshitha; doctor backend: Pranav. docs/research and docs/qa: Kovid.

## Screen and analytics coverage

### Patient P1-P9

S06 establishes routes and shared state. S10 integrates P1 Home, P2 Choose Activity and P7 Personalized Activity. S11/S18 integrate P3 How to Play, P4 Game, P5 Break and P6 Finished. S15/S18 complete P8 Rest and P9 Simple Progress. Shanks owns integration, with Maharshitha's visual components. Break preserves a live session; rest has no active game. Tutorial, skip, help, larger text, backgrounding and saved-state recovery must work across every game.

### Caregiver C1-C7

S08/S10 connect C1 Sign In, C2 Basics and C3 Know Me. S15/S18 deliver C4 Home, observations and accept/modify/reject decisions, plus C5 protected handover. S20 delivers C6 Reminders independently of games. S14/S25 integrate C7 Settings/Sync, permissions, pending uploads and stale/conflict states. Clinical type/stage is optional entered context. Personal words target 15-20 with fewer/skip supported.

### Doctor D1-D8

S27 implements verified identity and assignment access. S36 delivers D1 Sign In, D2 My Patients, D3 Overview and D4 Session History. S37 delivers D5 Cognitive Analytics, D6 Trends and D7 Generated Report. S38 delivers D8 Notes/Recommendations. Pranav owns server access; Shanks owns frontend integration with Maharshitha. Test direct session/report IDs as well as patient lists.

### Per-game metric acceptance

Reveal Match: matched pair attempts / resolved attempts; zero attempts is null. Route Quest: destination/return status, traversed distance and shortest-valid-route ratio. Maze: debounced contact episodes and mode-specific path efficiency. Trace: unique path coverage and normalized deviation. Coloring: unique manual reveal coverage and support, no accuracy. Spot Difference: discovery and selection precision with repeat taps excluded. Word Search: discovery and valid-selection accuracy with script-safe content. Routine Recall and Picture Recall: first-attempt accuracy separate from eventual completion/help. See G1-G9 in the product guide for exact formulas and fixtures.

### Comparable trends and reports

S13 calculates versioned metrics. S17 creates a provisional reference from three eligible comparable sessions, excluding tutorials and separating assistance, input mode, level and task/content complexity. S37 presents 7/30-day windows with sample counts, gaps and last sync. Memory/Attention/Recognition/Language are observation groupings, not validated clinical scores. Reports cite source sessions, versions, dates, limitations and review state. Template generation is the first proposed implementation; an LLM is optional and cannot invent metrics or change difficulty.

### Required reminder behavior

Caregiver schedules are cached locally. Games never gate delivery. Store prompted, acknowledged, postponed, cancelled and caregiver-confirmed states separately. Test permission denial, restart, background delivery, edits, time-zone changes and duplicate prompts. Acknowledgement is not medication adherence; the app does not generate/change prescriptions or doses.

## Contracts before parallel coding

These are proposed v0.1 interfaces. Pranav owns approval and later version changes.

### Core tables

users(id, auth_uid); patients(id, display_name, language, known_type, known_stage, accessibility, version); caregiver_patients(user_id, patient_id, role); personal_words(id, patient_id, text, locale); sessions(id, patient_id, game_id, game_version, difficulty, input_mode, status); events(event_id, session_id, seq, type, elapsed_ms, payload); session_metrics(session_id, metric_version, values); recommendations(id, patient_id, source_session_id, rule_version, proposed_config, reason, status, decided_by). Required full-scope tables: reminders, reminder_occurrences, observations, content_packs, doctor_assignments, doctor_notes and generated_reports. Include version, ownership, review status and audit timestamps where applicable.

### Enrolment and configuration

POST /v1/patients -> patient_id and version. PUT /v1/patients/{id}/personalization -> words and preferences. GET /v1/patients/{id}/activity -> approved configuration or safe default. Clinical fields support unknown/not provided; 15–20 words is a target, with skip and fewer-word support.

### Sessions and metrics

PUT /v1/sessions/{client_uuid} creates an idempotent session. POST /v1/sessions/{id}/events:batch accepts a batch and returns accepted, duplicate and rejected event IDs. POST /v1/sessions/{id}/complete includes final_seq and status; analytics waits for all events through final_seq. GET /v1/patients/{id}/summary returns game metrics, sample counts, comparability filters and last sync time.

### Human review

GET /v1/patients/{id}/recommendations -> pending/current records. POST /v1/recommendations/{id}/decision accepts accept/modify/reject, reviewer ID from authentication, and optional modified configuration. The patient uses the last approved configuration while a proposal is pending.

### Doctor and reminder additions

Proposed doctor endpoints: GET /v1/doctor/patients; assigned-patient session/history reads; POST /v1/patients/{id}/reports; GET report status/content; POST /v1/patients/{id}/notes. Reminder CRUD includes schedule version, target-device delivery state and cancelled occurrences. Pranav freezes payloads and patient membership rules in S05. Generated reports and notes remain separate records.

### Recommendation authority

Proposed default: caregiver confirmation activates the next activity, including doctor-originated suggestions. Store pending/accepted/modified/rejected/expired/superseded status, source sessions, rule version, reviewer and config version. Recheck version on approval so an old proposal cannot overwrite a newer one. The final doctor authority policy remains a planning decision.

### Contract rules

UUIDs on device; timestamps in UTC; durations in milliseconds; deterministic sequence numbers; schema_version on envelopes; stable enums and metric definitions. Common errors include 401 identity required, 403 no patient access, 409 revision conflict and 422 invalid data. Return a stable code, safe message and request ID. Example fixtures are committed before UI and API implementation.

## Telemetry, baseline and adaptation

Observable performance first; clinical interpretation remains outside the MVP.

### Event envelope

event_id, schema_version, session_id, patient_id, game_id, game_version, seq, occurred_at, elapsed_ms, input_mode, difficulty, assisted, event_type, payload. Reveal Match events include session_started, card_revealed, pair_resolved, hint_requested, paused, resumed and session_finished. Do not put patient names, personal words or photo URLs into telemetry.

### Reveal Match definitions

A pair attempt is a pair_resolved event. Accuracy = matched pair attempts / all pair attempts; zero attempts gives null, never zero accuracy. Mismatches count unsuccessful attempts. Active duration excludes explicit pauses/background time. Completion is separate from accuracy. Include hint count, assisted flag and game configuration with every summary.

### Baseline proposal

Use a tutorial, then the first three valid comparable sessions to establish a provisional reference such as median accuracy and active duration. Three is an engineering starting assumption, not a validated clinical protocol. Show insufficient data before enough sessions. Compare the same game/version, level and interaction mode. A changed configuration starts a separate comparison series.

### Example rule proposal

Proposed revised rule: after three comparable unassisted completed sessions with resolved attempts at least equal to the configured number of pairs in each: if accuracy is at least 0.85 in each and hints are zero, suggest one higher level. If accuracy is below 0.50 in two comparable sessions or help is repeatedly requested, suggest one easier level or additional support. Otherwise hold. This per-level minimum replaces the old fixed four-attempt minimum, which blocked perfect two/three-pair starter boards. Thresholds require usability testing; speed alone never increases difficulty. Hold at the configured ceiling. Coloring uses preferences/support, with no automatic difficulty promotion; other games require their own rules and fixtures.

### Explanation and guardrails

Store rule version, source sessions, observed values and reason. Missing data, assisted play or interrupted sessions prevent automatic progression. Pause/stop is always available. A break suggestion need not infer disease change. Adapt only between sessions, and apply new difficulty after caregiver approval. No LLM is needed for the scoring or recommendation loop.

## Offline, accessibility and personal data

Design the boundaries now; demonstrate only the behavior that passes testing.

### Minimum offline foundation [3]

Write a session and its events to SQLite before upload; bundle the first game assets. An enrolled device can use cached approved settings. First enrolment and first authentication may require connectivity. Keep the last approved activity when the server cannot be reached. Display pending uploads and last successful sync to caregivers.

### Replay and conflict handling

Retain events until acknowledged; retry transient failures with backoff. Dedupe server-side by event_id and enforce unique session_id + seq. Session creation precedes events, then completion. Replaying a batch after an app restart must not change totals. Profiles use version checks and explicit conflict resolution rather than silent overwrites.

### Reminders and deletion

Schedule local reminders on the device and test permission denial, restart and time-zone change. Keep caregiver-entered routine text distinct from medical advice. Define deletion for server records, photos and cached copies; use tombstones to prevent a reconnect from restoring deleted data. Define deletion propagation and revocation behavior before any real-data rollout; its unverified state must remain visible. Required offline replay cannot restore deleted content.

### Protection

Use synthetic data for the demo. For a real deployment, minimize clinical fields, use TLS, enforce patient access in every route, protect tokens with platform secure storage and choose an explicit at-rest encryption solution. SQLite/Hive or HTTPS alone does not prove encrypted local storage. Exclude private patient data and secrets from Git and AI prompts.

### Patient interface and language [4]

Proposed UI targets: large readable text, at least 48 logical-pixel controls where practical, generous spacing, no timed pressure, pause/repeat/exit and text plus icons. Validate contrast and text scaling; WCAG is a reference, not a certification. Pilot one locally reviewed language pack with real script shaping and audio checks. Use image-based alternatives for users for whom word puzzles are unsuitable.

## Team workflow and integration

Shared contracts let the team work in parallel without waiting for every implementation.

### Daily rhythm

One short kickoff with the day’s shared milestone; asynchronous updates using DONE / IN PROGRESS / BLOCKED / NEED FROM / BRANCH-PR. Escalate blocks after about 30 minutes. Two planned integration windows let Pranav review in batches. End the day with an installed-build demonstration, not isolated screenshots.

### GitHub path

Issue -> branch -> small change -> checks -> PR -> review -> develop -> integrated QA -> release PR -> main. Nobody pushes directly to main. Protect main and develop. Shanks reviews frontend; Pranav reviews backend/AI; Shanks reviews Pranav’s integration changes with Aryan running smoke tests. Kovid records manual QA evidence. Use feature/* branches for the team; Codex-created branches default to codex/*.

### Task contract

Every task names objective, primary owner, collaborators, dependencies, allowed modules, request/response examples, acceptance criteria and reviewer. Contract changes require an updated schema and fixture first, then coordinated client/server changes. No independently invented database or Flutter architecture.

### AI task prompt

Read PS003_MASTER_CONTEXT.md and task Sxx. Work only in the assigned modules using the agreed contracts and fixtures. State assumptions and dependencies. Implement the acceptance criteria; report changed files, checks and remaining limitations. Ask the architecture owner before changing shared interfaces. Never paste patient information, credentials or private photos into the prompt.

### Definition of done

Merged code, appropriate checks, documented contract/behavior, installable integration build and passed end-to-end acceptance. A game is complete only when its session reaches storage, its defined metrics match fixtures, and the reviewed activity pipeline can select it with the correct settings. A hold/no-change decision is valid; coloring need not generate a difficulty change.

### Sources of truth

GitHub holds code, issues and reviewed technical documents. Figma holds approved design. Discord coordinates work but decisions are copied to the repository. Kovid can report through a shared mobile document; Aryan transfers actionable findings into issues. Update master context at each merged milestone.

## Quality gates and demo evidence

Engineering checks demonstrate reliability; they do not establish clinical effectiveness.

### Required automated checks

Metric fixtures: zero attempts, correct/mismatch counts, pause subtraction, interrupted and assisted sessions. API: invalid identity, cross-patient access denied, duplicate replay, missing event sequence and conflicting completion. Recommendation: insufficient data, threshold edges, allowed range, rejected proposal and approved next activity.

### Kovid’s manual checklist

Create a patient with optional clinical fields empty; skip or edit personal words; play and exit safely; request hints; enlarge text; verify calm feedback and caregiver return. Confirm history and next activity. Test airplane mode, force-close/reopen, reconnect twice and verify one session total. Record actual device, OS, build ID and evidence; mark unsupported tests NOT TESTED.

### Bug severity and freeze

Block release for crashes in the core flow, lost/duplicated data, unauthorized access or misleading medical claims. Major usability issues are fixed before adding games. Cosmetic issues can remain in a known-issues list if they do not obstruct the demo. Pranav decides release readiness using QA evidence.

### Demonstration sequence

Aryan introduces a synthetic caregiver and patient. Show personal words and Reveal Match. Complete a session; show its actual metrics and an explained recommendation. Accept or modify it; return to patient mode to show the new activity. Show an offline replay only if verified. Mark any seeded historical trend as synthetic demonstration data.

### Evidence of completion

Capture the release tag, APK, backend deployment details, configuration instructions, a clean seed/reset procedure, smoke-test results and Kovid’s checklist. Rehearse twice on the chosen Android phone. Keep a recorded backup and avoid describing a mock as a working integration.

## Review of the supplied six-slide PPT

Content corrections preserve your template; the original PPT is left unchanged.

### Slide 1 | title and identity

The problem ID/title are consistent with your brief. Fill Team ID when assigned. I could not independently verify SIH26003 from the official site search, so treat the ID/title as user-supplied. Template compliance cannot be certified without the official template or submission rules.

### Slide 2 | idea

Change “nine games run offline” to a planned catalogue with current demo games identified. Replace “gameplay is the measurement instrument” with “gameplay provides app-performance signals.” Resolve the baseline contradiction with: “Initial supported gameplay establishes a provisional app baseline; no diagnostic test is administered.”

### Slide 3 | technical approach

Commit to Flutter/FastAPI/PostgreSQL for the proposal. Show SQLite as the selected local design and defer the second game engine. Include backend upload/storage between logger and analytics. Distinguish local reminders from Firebase messaging, and show pending recommendation -> caregiver decision -> approved activity.

### Slide 4 | feasibility

“Shippable in one hackathon cycle” must refer only to the verified demo subset, not a promise that all nine games and the portal fit the earlier dates. Entry-level device support, ten-minute enrolment, encrypted queue and script/voice support need measured evidence. Content packs still require font, script, layout, audio and device testing; a new language may require code changes. ASHA assistance is a proposed workflow, not an established partnership.

### Slide 5 | benefits

Describe better engagement and reduced caregiver effort as intended outcomes, not measured impact. Label 7-/30-day charts synthetic or planned unless backed by actual data. NPHCE alignment does not imply deployment, endorsement or integration. Every-recommendation review needs a pending/accept/modify implementation.

### Slide 6 | references [1, 2]

The 7.4% national figure is supported as an estimate in the 2023 publication using earlier study data. Table 2 reports 7.35% for NE states excluding Assam; its prevalence estimate also excludes Sikkim. Add those limits, full links and evidence caveats. Research on cognitive stimulation does not validate this application’s domain scores.

## Decisions and first assignments

### First dependency-ready work

S01: Pranav records the confirmed counts/screen scope and reviews the working exact mapping with the team. S02/S03/S07 then establish repository workflow, full screen design and QA evidence. S04/S05 freeze cross-game config, event, access, reminder and report contracts. S06 supplies the host example. Do not generate independent modules against invented interfaces.

### First game and support handoffs

Aryan takes S11 Reveal Match once S04/S06 pass. Ruthika supplies S12/S13 ingestion and calculator fixtures. Shanks integrates the host, P1-P9 lifecycle and local queue. Maharshitha builds C1-C7 components and content. Pranav completes services/recommendations before taking on Route Quest movement complexity. Kovid verifies the installed flow.

### Open planning choices

Exact game mapping remains the working proposal. Confirm availability and new release dates, doctor portal frontend technology, assignment provisioning and activity-decision authority, target device, pilot language/native reviewer and deployment budget. These do not prevent documentation or contract design. No unconfirmed service, encryption, translation or device behavior is treated as implemented.

### Evidence update rule

Record build/commit, device/OS, session IDs, metric fixtures, test result and reviewer after each milestone. Change package status only when its acceptance criteria pass. Preserve original requirements and retain task IDs for continuity. The canonical task details follow in the roadmap; the PDF includes the same records.

## Sources and evidence limits

Accessed 5 September 2026. Sources support only the associated statements.

### [1] India dementia prevalence

Lee J. et al. (2023), Prevalence of dementia in India: National and state estimates from a nationwide study. DOI: 10.1002/alz.12928. Table 2 and its footnotes support the regional qualification. https://alz-journals.onlinelibrary.wiley.com/doi/full/10.1002/alz.12928

### [2] Cognitive stimulation

Woods B. et al. (2023), Cognitive stimulation to improve cognitive functioning in people with dementia. Cochrane, CD005562.pub3. https://www.cochrane.org/evidence/CD005562_can-cognitive-stimulation-benefit-people-dementia

### [3] Flutter architecture

Official offline-first support guidance describes local/remote data handling and synchronisation choices. The proposed outbox, conflict rules and release scope in this handbook are engineering recommendations. https://docs.flutter.dev/app-architecture/design-patterns/offline-first

### [4] Accessibility reference

W3C WCAG 2.2 target-size guidance. The handbook’s larger mobile target is a proposed product choice, not a claim of WCAG certification. https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum/

### User-provided materials

Complete team/development brief preserved at docs/PS003_ORIGINAL_TEAM_BRIEF.md. Existing six-slide presentation: Cognitive_Gaming_for_Elderly_Dementia_-_Tesseract-5.pptx. Team assignments, dates and intended features come from those materials.

### Limitations

No clinical effectiveness, device performance, user testing, deployment, official SIH template compliance, programme partnership or completed software is established by this review. This is a proposed development plan and evidence-aware content review, not a clinical evaluation.