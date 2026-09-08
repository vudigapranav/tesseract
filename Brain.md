# Tesseract Shared Brain

Last updated: 2026-09-07 (Codex, confirmed product-quality requirement)

This file is the short, shared continuity log for work performed by Codex, Claude, and the Tesseract team. Update it after every meaningful project change. Record decisions, files changed, checks actually run, remaining limitations, and the next action. Do not record credentials, patient information, private media, or unverified claims.

## Project identity

- Team: Tesseract
- Problem statement: SIH26003
- Product: AI-based cognitive gaming and memory assistance for elderly people with dementia in the North Eastern Region
- Current mobile stack: Flutter, with self-contained game packages behind `tesseract_game_contract`
- Patient principle: calm, respectful, untimed play with permanent Help and Break controls, no lives, leaderboards, failure sounds, or clinical claims

## Standing quality requirement — confirmed 2026-09-07

The user requires a polished, fully functional, production-quality Tesseract app
that stands out to judges among eight other teams. Every future project prompt,
plan and team handoff must explicitly carry this quality target and measurable
acceptance criteria. A skeleton or demonstration-only implementation is an interim
step, never the finished deliverable. This supersedes the earlier prompt wording
that framed the final target as a prototype.

- Use the supplied healthcare UI reference as visual inspiration: warm cream and
  peach, coral accents, rounded white cards, strong typography, black pill buttons
  and generous spacing. Adapt it to Tesseract; patient accessibility remains a
  requirement. The reference does not add appointments, payments or vital signs
  to the product scope.
- Completion requires functional authenticated workflows, durable data, reliable
  offline recovery/sync, working reminders, meaningful measured insights,
  caregiver-controlled recommendations, smooth performance and verified builds.
  Include real integration/device evidence appropriate to each task; keep absent
  services, unfinished features and synthetic data explicitly identified.
- Judge-facing differentiation should be demonstrated through coherent design,
  personalization, reliable end-to-end behavior and a rehearsed product story.
  Do not promise a judging outcome or invent clinical/performance claims.
- Current sequencing: prepare non-game backend/AI and Shanks's frontend work;
  integrate teammates' remaining games later. Preserve team ownership and package
  boundaries. This quality decision does not itself start implementation, approve
  paid services/deployment, settle the doctor-platform choice or approve proposed
  additions.

Recorded by Codex in Brain.md and AGENTS.md. Checks: read the continuity/master
context and relevant handbook/release-roadmap sections; verified the saved text.
Documentation-only change; no application code, tests or build status changed.
Next action: carry this requirement into the next requested prompts and resolve
the outstanding service/platform choices before dependent implementation.

## Ownership snapshot

- Pranav: Route Quest, Marble Maze, backend and AI/analytics architecture, integration review
- Shanks: shared Flutter architecture, patient shell, game host, frontend integration
- Maharshitha: design system, patient-friendly assets, bounded frontend components
- Aryan: Reveal Match, Coloring, Spot Difference, Picture Recall, Trace
- Ruthika: Personalized Word Search, Daily Routine Recall
- Kovid: research, ethics, manual QA, documentation support

Exact game mapping remains the working proposal recorded in the project documents. Confirmed count is Aryan 5, Ruthika 2, Pranav 2.

## Source material reviewed

- `Tesseract_Updated_Plan_With_Additions.pdf`: reviewed all 39 pages
- `Tesseract_Frontend_Design.pdf`: reviewed all 33 pages
- `Cognitive_Gaming_for_Elderly_Dementia_-_Tesseract-5.pptx`: reviewed all 6 slides; source deck unchanged
- `PS003_MASTER_CONTEXT.md`, relevant handbook sections, and S26/S28 roadmap entries reviewed before implementation

## Active task

### Game-feel redesign for Pranav's two games

Status: MOTION CONTROL IMPLEMENTED AND BUILD-VERIFIED; PHYSICAL-DEVICE TUNING STILL PENDING

Goal: make Route Quest and Marble Maze feel like cohesive, polished games for the SIH demo while preserving the patient-safe interaction model and existing analytics contracts.

Direction:

- Route Quest becomes the judge-facing flagship: illustrated landscape, recognisable landmarks, layered roads, animated traveller, calm destination feedback, and a visible Help route.
- Marble Maze shares the warm material style: tactile wooden board, recessed corridors, dimensional glass marble, illuminated goal, useful route Help, and gentle motion feedback.
- Keep Flutter-native rendering and the existing dependency boundary. Do not add network, database, authentication, or third-party game-engine dependencies inside either game.
- Do not change event names, difficulty metrics, pause timing, completion rules, or patient-facing safety principles for cosmetic polish.

Files changed:

- `code/games/route_quest/lib/src/route_map_painter.dart`
- `code/games/route_quest/lib/src/route_map_view.dart`
- `code/games/route_quest/lib/src/route_quest_game.dart`
- `code/games/marble_maze/lib/src/maze_level.dart`
- `code/games/marble_maze/lib/src/maze_painter.dart`
- `code/games/marble_maze/lib/src/maze_view.dart`
- `code/games/marble_maze/lib/src/marble_maze_game.dart`
- `code/games/marble_maze/test/marble_maze_game_test.dart`
- `code/host/test/golden_test.dart`
- Game golden screenshots under `code/host/test/goldens/`
- `AGENTS.md`, `Brain.md`, and `PS003_MOBILE_CODE_STATUS.md`

## Verified evidence

- Flutter 3.47.2 / Dart 3.13.2.
- `flutter analyze code/games/route_quest code/games/marble_maze code/host`: no issues.
- Route Quest package: 16 tests passed.
- Marble Maze package: 16 tests passed, including visible Help-state coverage.
- Host/golden suite: 19 tests passed.
- Total automated checks: 51 passing tests.
- Visually inspected Route Quest levels 1 and 3, flag-collected return state, pause state, and 2x text-scale host state.
- Visually inspected Marble Maze levels 1 and 3, visible Help path, and pause state.

## Decisions from the first pass

- Judge-facing quality will come from visual storytelling, material depth, responsive motion and demonstrable analytics, not from making the patient interaction harder.
- Route Quest remains the flagship because its destination, flag and return loop explains the product's route observations clearly.
- Marble Maze remains the tactile companion game. Its Help button now draws a real shortest-path guide while still recording the existing assisted-session event.
- Flutter-native `CustomPainter` and animation remain sufficient for this scope. No Flame, Godot, Phaser or third-party assets were added.
- Existing event names, event order, difficulty parameters, pause timing, touch fallback and completion rules remain unchanged.

## Known limitations

- The repository sits inside a broader home-directory Git worktree, so project files are not currently tracked as an isolated clean repository.
- Tilt control is implemented and build-verified (see the 2026-09-06 entries below) but not yet felt on a real phone. Touch remains the fallback whenever the sensor channel is unavailable.
- Full device QA (beyond the build itself), backend connection, offline outbox integration, and end-to-end clinical workflow remain outside this work.

## Next action

Install `code/host/build/app/outputs/flutter-apk/app-debug.apk` on the chosen
physical Android phone and check Marble Maze's tilt direction, neutral
calibration and sensitivity by feel — no automated check can substitute for
this. If the marble drifts at rest, tighten `_tiltDeadZone` (currently 0.035)
or the neutral-calibration sample count (currently 12) in
`marble_maze_game.dart`. If motion feels laggy or twitchy, adjust the
low-pass lerp factor (0.22) or `_tiltGridUnitsPerSecond` (2.65). No agent in
this environment has a connected device or emulator to do this step.

## 2026-09-06 Codex motion-control update

User decision: do not expose developer audit/event logging in the patient UI;
Marble Maze must use the phone gyroscope rather than swipe as its primary control.

Changed files so far:

- `code/games/marble_maze/lib/src/marble_tilt_input.dart`
- `code/games/marble_maze/lib/src/marble_maze_game.dart`
- `code/games/marble_maze/lib/src/maze_view.dart`
- `code/games/marble_maze/test/marble_maze_game_test.dart`
- `code/games/marble_maze/README.md`
- `code/games/marble_maze/pubspec.yaml`
- `code/games/route_quest/lib/src/route_quest_game.dart`
- `code/games/route_quest/lib/src/route_map_view.dart`
- `code/games/route_quest/lib/src/route_map_painter.dart`
- `code/host/android/app/src/main/kotlin/com/example/tesseract_host/MainActivity.kt`
- `code/host/lib/src/session_controller.dart`
- `code/host/lib/src/play_screen.dart`
- `code/host/lib/src/finished_screen.dart`
- `code/host/test/golden_test.dart`
- `PS003_MOBILE_CODE_STATUS.md`
- `Brain.md`

Decisions and behavior:

- Android uses `TYPE_GAME_ROTATION_VECTOR` (gyroscope-led sensor fusion) over a
  Flutter event channel. The game still has no sensor plugin or prohibited
  network/database/auth dependency.
- The first 12 samples calibrate the resting phone angle. A low-pass filter and
  small dead zone keep motion calm. The host selects tilt for Marble Maze; touch
  is used only for explicit touch mode or when the sensor channel is unavailable.
- Existing event types/order, difficulty metrics, fixed timestep, pause timing,
  completion rules and Help behavior are unchanged.
- The patient-facing event-log button was removed. Telemetry still records through
  the host callback; this was a presentation change, not a contract change.
- Valid moves, Help, collision episodes and completion receive gentle platform
  haptics. Finished-screen transitions and marks are cosmetic. Decorative ambient
  animation respects the OS reduced-motion setting.

Checks actually run:

- `flutter analyze code/games/route_quest code/games/marble_maze code/host`: no issues.
- Route Quest package: 16 tests passed.
- Marble Maze package: 17 tests passed, including synthetic fused-tilt movement
  after neutral calibration and the no-sensor touch fallback.
- Live browser touch QA before the gyro change: Route Quest valid movement and
  Marble Maze's full three-segment level-1 route completed in the 360x740 host;
  pause/finish navigation worked. This is browser evidence only.

Additional checks and evidence after that checkpoint:

- Refreshed and visually inspected the clean Route Quest/Marble Maze play goldens
  and the new route/maze completion marks. The developer event-log control is not
  present.
- Host/golden suite: 20 tests passed, including the new Marble Maze completion
  screenshot. Combined verified suite at this checkpoint: 53 tests (16 Route
  Quest + 17 Marble Maze + 20 host/golden).
- Relaunched the updated host in the 360x740 web preview and verified through its
  accessibility tree and screenshot that Marble Maze play exposes only Help and
  Break. Web correctly has no gyroscope and therefore uses the touch fallback.
- Android NDK 28.2.13676358 and Build Tools 36 installed successfully. The Gradle
  build then continued for setup/assembly but was manually stopped after 1011.7s
  at the user's request; no APK or Android compile success is claimed.

Remaining limitations: the last small native manifest/hardware-gyroscope guard
and host input-mode test were added after the most recent clean analysis run, so
Claude must rerun analysis/tests. Android Kotlin compilation and real-phone
gyroscope direction/sensitivity remain unverified. The two incomplete NDK folders
moved aside during repair remain recoverable at
`/private/tmp/tesseract-incomplete-ndk-28.2.13676358` and
`/private/tmp/tesseract-stalled-ndk-28.2.13676358` until the OS clears temporary
storage.

## 2026-09-06 Claude build-verification pass

User decision: continue Claude's queued work from this file (re-verify Codex's
motion-control changes, then run the deferred Android build).

Independently re-derived everything below from scratch — did not take Codex's
self-reported numbers on faith. They matched.

Files reviewed line-by-line (not just diffed): `marble_tilt_input.dart`,
`marble_maze_game.dart`, `maze_view.dart`, `MainActivity.kt`,
`AndroidManifest.xml`, `session_controller.dart`, `play_screen.dart`,
`finished_screen.dart`, `route_map_view.dart`, both updated test files, and
the new `session_controller_test.dart` (added by Codex after its last
recorded checkpoint, so this was its first verification).

Checks run and exact results:

- `flutter analyze` on all five packages (contract, route_quest, marble_maze,
  harness, host): no issues, all five.
- `dart run tool/generate_test_report.dart` (drives `flutter test` under the
  hood): contract 22/22, route_quest 16/16, marble_maze 17/17 (including the
  synthetic fused-tilt test against a fake `MarbleTiltInput`), host 23/23
  JSON-reporter entries (21 real tests: the new `session_controller_test.dart`
  plus 20 golden screenshots, including the new "Finished after Marble Maze"
  completion mark) — 76 real automated tests passing project-wide.
- Visually inspected every new/changed golden PNG (both completion marks,
  the textScale-clamped Route Quest labels, Marble Maze's board and Help
  path). No defects found.
- `flutter build apk --debug` from `code/host`: **succeeded**, 792s,
  producing `code/host/build/app/outputs/flutter-apk/app-debug.apk` (150MB —
  normal for an unstripped multi-ABI debug build). This is the first real
  compile of the native Kotlin sensor bridge; it was not verified before now.
- Inspected the built APK's merged manifest with `aapt dump badging`:
  confirmed `uses-feature-not-required: android.hardware.sensor.gyroscope`
  survived merging, `minSdkVersion 24` / `targetSdkVersion 36`. The only
  permission is `INTERNET`, which is Flutter's own debug-build/observatory
  default, not anything the app or any game requests.
- Fixed one stale doc comment in `play_screen.dart` that still described the
  removed event-log panel; re-ran `flutter analyze` on host afterward (clean).

Not verified, and no claim is made otherwise:

- Physical tilt feel, direction and sensitivity. No Android device or
  emulator is connected in this environment — `adb devices` returns empty
  and no emulator is installed. This absolutely requires Pranav's phone; see
  Next action.
- The harness's own tilt option for Marble Maze will silently behave as
  touch, because only `code/host`'s `MainActivity.kt` implements the native
  `org.tesseract/marble_tilt` channel — the harness has no native code of its
  own. This is an acceptable gap for a dev tool, not a defect, but worth
  knowing before someone spends time debugging "tilt does nothing" on the
  harness specifically.

## 2026-09-07 Claude host frontend skeleton pass

User decision: build the full decided frontend skeleton (P1-P9 patient +
C1-C7 caregiver) into `code/host` now, as structure only — the frontend team
redesigns the actual visuals later. Doctor portal (D1-D8) confirmed out of
scope for this pass; the docs mark its platform (mobile vs. separate web) as
an open decision, and building it into this mobile skeleton would presume
that decision. Games section stays exactly as-is (the registry pattern
already handles "fewer games registered" gracefully) until Aryan/Ruthika
finish theirs.

Files added:

- `lib/src/caregiver/sign_in_screen.dart` (C1)
- `lib/src/caregiver/patient_basics_screen.dart` (C2)
- `lib/src/caregiver/know_me_screen.dart` (C3)
- `lib/src/caregiver/caregiver_home_screen.dart` (C4)
- `lib/src/caregiver/hand_over_screen.dart` (C5)
- `lib/src/caregiver/reminders_screen.dart` (C6)
- `lib/src/caregiver/settings_screen.dart` (C7)
- `lib/src/personalized_activity_screen.dart` (P7)
- `lib/src/progress_screen.dart` (P9)
- `lib/src/caregiver_return_gate.dart` — the "protected return flow" back
  into caregiver mode from patient mode; today a confirmation dialog, not
  real authentication

Files changed:

- `lib/main.dart` — app now starts at C1 Sign In, not P1 Home directly
- `lib/src/host_flow_state.dart` — expanded with caregiver sign-in,
  patient basics, Know Me content, approved activity/level, reminders,
  settings, and full activity history (all in-memory, all placeholder)
- `lib/src/home_screen.dart` — Start branches to P7 when a caregiver
  approved an activity at Hand Over, else P2 (matches "Start to P2 or
  approved P7"); added the caregiver return gate and a Progress link
- `lib/src/rest_screen.dart` — added the caregiver return gate
- `lib/src/how_to_play_screen.dart` — takes an optional `level` now, so P7
  can pass through the caregiver-picked level (host still sets it, never
  the game)
- `lib/src/play_screen.dart` — records every finished session (regardless
  of outcome) into `HostFlowState.activityHistory`, which C4 and P9 both
  read from; fixed a stale doc comment left over from the removed event-log
  panel

Decisions and honesty boundaries kept:

- Companion ("playing together") mode is not offered at Hand Over —
  `PS003_ADDITIONS.md` is not approved.
- Know Me content (C3) is collected but not wired into any game's
  `GameItem`s yet — that's later integration work, not claimed as done.
- P5 (Taking a Break) is not a new screen — each game's own pause overlay
  already covers it, per the existing contract.
- Nothing here persists past an app restart. No real auth, no notification
  scheduling, no backend call anywhere in the new screens.

Checks run and exact results:

- `flutter analyze` on all five packages: no issues.
- `flutter test` in `code/host`: 21/21 (unchanged real-test count — no new
  goldens were added; see below for why).
- 4 existing goldens needed regenerating (`home*`, `rest*` — both gained a
  visible new element) after visually confirming the diff was exactly the
  caregiver-return-gate icon and the new Progress link, nothing else.
- **No goldens were added for the 9 new screens.** They're a structural
  skeleton due for a visual redesign soon; pixel-regression tests would need
  regenerating again almost immediately, so the verification investment
  went into a full live click-through instead (see below), not screenshots.
- Live click-through in the 360x740 web preview, one continuous session:
  C1 Sign In (typed a name) -> C4 Caregiver Home ("No patient set up yet")
  -> C2 Patient Basics (entered "Radha") -> C3 Know Me (added a person chip)
  -> Continue back to C4 (now shows "Radha") -> C5 Hand Over (picked Marble
  Maze, level 2) -> Enter patient mode -> P1 Home (now suggests "Marble
  Maze", shield icon present) -> Start -> **P7** (confirms the P2/P7 branch
  works) -> How to Play (level 2's board loaded, confirming the level
  actually passed through) -> Break -> "Finish for now" -> P6 Finished
  (Marble Maze completion mark, "Activities today: 0" — correct, since
  "stopped by user" isn't a completion) -> Rest -> tapped the shield icon ->
  confirmed the dialog -> landed back on **C4 Caregiver Home**, which now
  read "Last activity: Marble Maze (stopped by user)". Every link in that
  chain is real, not mocked.
- Did not verify the marble-drag-to-goal path live in this pass (the
  browser automation tool's single-jump drag doesn't generate the
  intermediate pointer events Flutter's pan recognizer expects) — the
  drag-to-move mechanic itself is already covered by Marble Maze's own 17
  passing widget tests, which call the real `onDrag` callback directly, so
  this is a tooling gap in live QA, not an unverified app behavior.

Remaining limitations:

- Visual design is intentionally unfinished — this is the point of a
  skeleton pass, not an oversight.
- No real auth, persistence, notification scheduling, or Know Me -> game
  content wiring yet.
- Doctor portal not started; platform decision still open.
- Physical Android tilt tuning (from the previous pass) is still the only
  device-dependent item nobody in this environment can complete.

## 2026-09-07 Claude backend foundation (services/api)

**Actor:** Claude. **Request:** build Tesseract's non-game backend, analytics
and recommendation foundation for a working prototype, starting from an
integration contract for Shanks, without touching game code, the PPT or
teammates' repositories.

### Repository boundary problem, found and fixed first

Before writing anything I checked repository boundaries as instructed, and
found a real problem: **the git repository was rooted at the user's home
directory** (`/Users/pranav07vudiga`), with `origin` pointing at
`https://github.com/vudigapranav/UserProfileApp.git` — an unrelated repo. Only
22 files had ever been committed, in one commit on `codex/marble-gyro-polish`.
Everything else — all planning docs, `docs/`, `services/`, most of `code/`,
both game packages — had never been tracked at all. A `git add -A` there would
have swept in `.ssh/`, shell history and unrelated projects.

Pranav chose to re-initialise scoped to the project. Done:

- new repository at `Desktop/Projects/Hackathon/SIH/` only; the home-directory
  repository and its remote were left untouched, not deleted;
- `.gitignore` extended with `.claude/`; verified nothing matching common
  credential patterns was staged; 210 files / 11.1 MB baseline commit;
- work branch `feature/backend-foundation`, per the handbook's `feature/*`
  convention. **Nothing pushed** — there is no remote on the new repository yet.

### Verified starting state

`services/api` was exactly what Pranav said: a `pyproject.toml` and an empty
`app/__init__.py`. No app code, no migrations, no tests. `docs/contracts` and
`docs/qa` were empty directories.

### Files added

- `docs/contracts/PS003_API_CONTRACT_V1.md` — the integration contract for
  Shanks. Splits **Confirmed** (already true in committed code) from
  **Proposed** (my decisions, P1-P7, each with its alternative), and ends with
  four open questions for him.
- `services/api/` — full service: `config.py`, `models.py`, `errors.py`,
  `games.py`, `main.py`, and modules `auth/`, `patients/`, `media/`,
  `sessions/`, `analytics/`, `recommendations/`, `reminders/`, `doctor/`,
  `llm/`; Alembic `migrations/`; `scripts/seed_demo.py`,
  `scripts/grant_doctor.py`; `.env.example`; `README.md`; 130 tests.

**No game code, no Flutter code, no PPT, no teammate repository was touched.**
No game event name was changed.

### Checks run, exact results

- `pytest`: **130 passed** (4.8s), against a real PostgreSQL 15 database.
- The suite builds its schema by running the **real Alembic migrations**, not
  `create_all`, so a broken migration fails the suite.
- `ruff check app tests scripts`: **All checks passed.**
- `alembic upgrade head` on a clean database: applied revision `9592999903e3`.
- **Live HTTP run** against `uvicorn` on port 8077 (not the test client):
  health ok with migration revision reported; created a patient; wrote Know Me
  content with only 2 words (accepted, with `sufficient_for_word_games: false`);
  played **three full sessions** (create 201 -> 11 events accepted -> complete);
  a recommendation appeared on exactly the third; `activity` still read
  `level 1 / safe_default` while it was pending; caregiver accepted; `activity`
  then read `level 2 / approved / config_version 1`. Cross-patient reads
  returned 403 `no_patient_access`, no token returned 401. Replaying session 3's
  own batch returned `duplicate 11, accepted 0, rejected 0`; replaying complete
  returned `created: false`; a *differing* completion returned 409
  `completion_conflict`; session count stayed 3. Doctor token was 403 until
  `grant_doctor.py` provisioned it, then listed exactly its one assigned
  patient and 403'd on an unassigned one. A generated report cited 3 source
  sessions, `generator: template`, `review_state: unreviewed_draft`.

### Finding that affects the games — needs a later, separate change

**Neither game exports what its efficiency metric needs.** I checked the
sources rather than assuming:

- **Marble Maze** emits `collision`, `dead_end_entered`, `goal_reached` only —
  no travelled distance, no shortest grid path. Needs
  `distance_travelled_units` and `shortest_path_units`.
- **Route Quest** *does* compute a BFS shortest path at level load
  (`RouteGraph.shortestPathLength`) but never exports it; `difficultyParams`
  carries only `nodeCount`, `branchCount`, `requiresReturn`. Needs
  `shortest_path_length`.

Both therefore report their efficiency as **`unavailable`** with a machine
reason and the exact fields required — never 0, never guessed. The server
deliberately does **not** reimplement `RouteTopology.forLevel` in Python to
derive it; that number would silently go wrong the first time the map changes.
Recommendation rules were written to use only the metrics that do exist
(objective completion, hints, wrong interactions), so nothing waits on this.

### Remaining limitations

- **Nothing is deployed and nothing is integrated.** No Flutter code calls this
  service. `SessionController` still only prints its snapshot.
- The **Firebase path has never been run against a real project** — only the
  demo verifier is exercised. Fail-closed config is unit-tested, not
  production-proven.
- **No LLM provider is wired in.** The adapter, allow-list, output validation
  and fallback all exist and are tested with fake providers; `LLM_ENABLED` is
  false and there is no provider implementation.
- Recommendation thresholds in `app/recommendations/settings.py` are
  **unreviewed prototype values**, tagged `prototype_unreviewed` in every
  response. Not usability tested, not clinically reviewed.
- Only G2 and G3 have calculators; the other seven ingest fine and report
  common metrics with `no_calculator` noted.
- Media storage is a local-filesystem adapter. No object store, no at-rest
  encryption — and the README does not pretend otherwise.
- Contract §2 P1 needs a small **host-side** change: `GameEvent.toJson()` emits
  `elapsedMs`, the API takes `elapsed_ms`. That is an adapter rename in
  `SessionController`, not a game or contract change.

### Next dependency-ready action

Shanks reviews `docs/contracts/PS003_API_CONTRACT_V1.md` and answers its four
open questions (§14) — especially P1 (`elapsed_ms` naming) and P4 (can the host
report `actual_input_mode` after the gyroscope check). Then the SQLite outbox in
`code/host` can be written against a contract that will not move under it.

## Update template

When continuing work, append or revise the relevant section with:

- Date and actor
- User request or decision
- Files changed
- Checks run and exact result
- Screenshots/device evidence, if any
- Remaining limitations
- Next dependency-ready action


## 2026-09-07 Codex non-game integration — STOPPED BY USER

User explicitly requested: stop all implementation, report completed work and provide a Claude continuation prompt, including this record in project files. Implementation is paused at the user's request, not complete or production-ready. Do not resume unless asked. No commits or pushes were made in this pass.

### Critical workspace location

This task initially opened in an unrelated UserProfileApp worktree at `/Users/pranav07vudiga/.codex/worktrees/4fa8/pranav07vudiga`. The actual Tesseract repository is `/Users/pranav07vudiga/Desktop/Projects/Hackathon/SIH` on `feature/backend-foundation`, at `00f5cc9`, with an uncommitted AGENTS.md quality update. To preserve it, Codex cloned that repository into `/Users/pranav07vudiga/.codex/worktrees/4fa8/pranav07vudiga/tesseract`, then created branch `codex/patient-caregiver-integration`. ALL implementation changes and this stop/handoff record are in that nested clone, uncommitted. The original SIH checkout is untouched. Its AGENTS.md update was copied into the clone. Do not look for this work in the original checkout or accidentally stage the parent home/UserProfileApp repo.

### Code written (not accepted as verified behavior)

- Shared lifecycle mixin now forwards recorder-returned `paused` and `resumed` events to `widget.onEvent`; its test gained sink type/sequence assertions. The discovered original defect advanced seq but dropped both events.
- Added `code/host/lib/src/data/local_repository.dart`: SQLite tables for settings, sessions/events, immutable local completion checking and interrupted-session recovery.
- Added `data/api_client.dart` and `data/session_outbox.dart`: bearer-token HTTP adapter; session create → batches of at most 500 → complete; stable event IDs; accepted/duplicate checks; retain permanent errors instead of deleting data. These are not verified against the live backend.
- `session_controller.dart`: elapsedMs → elapsed_ms mapping, sequence/finalization guards, queued durable writes and flush, frozen config, explicit touch preference, omission of unknown actual tilt mode, removal of printed session JSON.
- `host_flow_state.dart`: settings serialization/restore, saved-history loading, identity/API references and initial sync/config/recommendation fetch plumbing.
- `play_screen.dart`: flush before finish navigation, duplicate callback guard, safe area, explicit system-back guidance to use Break/Finish, reduced-motion finish transition.
- Added `data/identity_service.dart`: optional Firebase email/password REST adapter using public build config, refresh token in flutter_secure_storage, local_auth device gate. Replaced fake password/name sign-in with configuration/error/loading states; synthetic preview is explicitly build-gated. Protected return and handover use device authentication. Real Firebase project/provider remains unconfirmed and UNTESTED.
- Added `design_system.dart`: cream/peach/coral/ink tokens, rounded white cards, pill buttons, typography and Flutter-native Tesseract activity illustration. Applied app theme/onboarding; no settled-design screenshot acceptance yet.
- Basics/Know Me/handover gained save calls. Settings gained persistent text/audio/reduced-motion preferences, sign-out and initial sync status. How-to-play gained game-specific instructions. Most caregiver dashboard/patient visual work remains unfinished.
- Added `data/reminder_service.dart` and rewrote reminders screen: daily local scheduling adapter, permission handling, persisted IDs, reconciliation, editing/enabling/removal, 15-minute postponement and acknowledgement. Android receiver/desugaring/permissions added. This was the last code written and has NOT been analyzed, built or exercised.
- Android MainActivity switched to FlutterFragmentActivity for local_auth while preserving tilt bridge; styles changed to AppCompat; backup disabled. Platform compilation pending.
- Host dependencies resolved: sqflite, path_provider, http, flutter_secure_storage, local_auth, flutter_local_notifications, timezone, flutter_timezone; sqflite_common_ffi for future tests. Some dependencies may be unused and need review.
- `docs/handoffs/SHANKS_API_REVIEW.md` records draft P1–P7/§14 responses, conflicts, design handoff and independent doctor scope. Prepared notes only: nobody was contacted and no contract was approved/frozen.

### Evidence actually obtained in this pass

- Actual repository HEAD inspected: 00f5cc9. Backend routes/contract inspected; patient create/read exist, but patient-basics update route was not found in `services/api/app/patients/router.py`.
- Reference PNG was available and visually inspected: `/var/folders/4_/rgvg3fz13bj3f8wmgvvwklmr0000gn/T/codex-clipboard-b477698e-8ccb-42f6-a215-f0a05380e5ac.png`.
- Flutter dependency resolution succeeded (required SDK/package-cache sandbox escalation).
- One interim `flutter analyze` in host passed before later identity/UI/reminder edits.
- A second interim `flutter analyze` returned exit 1 with two `prefer_single_quotes` info findings in patient_basics_screen.dart and play_screen.dart. No compile/analyzer errors were reported at that checkpoint. The final reminder/platform changes came AFTER that run, so this is not a final clean-analysis claim.
- No flutter tests were run. New lifecycle assertion is written, NOT executed. No new persistence/outbox/identity/reminder behavioral tests have yet been authored.
- No current APK build, browser walkthrough, golden regeneration or new screenshots. Physical-device checks NOT TESTED; connected-device inventory was not run this pass. Historical test/build figures above are not current verification.
- Required guidance was read via command output, but several combined outputs were truncated. Claude must re-read any relevant unobserved portions rather than assuming complete review from this pass.

### Known unfinished integration and review risks — start here on continuation

1. New code is rough, unformatted and unverified. Run formatting, analysis, focused tests and Android compilation before making any functionality claim.
2. Outbox has no periodic/backoff/reconnect driver, last-success timestamp is not persisted, and sessions created with zero events remain open on recovery. Async event writes can be lost if the process dies before the queue drains; do not claim crash-proof capture. Test actual SQLite transactions/restart and lost-response replay. Reject mismatched/duplicate IDs and sequence gaps; protect concurrent finalization.
3. Profile/session cache is not partitioned by caregiver identity. `connect()` selects the first accessible patient if no matching patient exists and can leave prior local content/history mixed. This is a blocking access/privacy issue to fix before real-user use. Do not enable real use yet.
4. New-patient server creation, server patient selection, personalization upload/version conflict handling, server history pagination and reminder API occurrence/definition synchronization are not wired to screens. Local basics edit cannot be described as synced: backend currently lacks its update endpoint. Do not independently change backend contracts.
5. Recommendations are fetched only; caregiver dashboard accept/modify/reject UI and applied config version propagation are unfinished. Session config/content versions remain hardcoded '1'. Handover still permits local game/level changes without server approval/version reconciliation. Resolve with Pranav, preserve approved offline config, and do not mislabel local changes as backend-approved.
6. Know Me data is not yet converted to stable approved GameItems in PlayScreen. Future-game adapters are unfinished. No games were edited/imported; both existing registry games remain.
7. Notification plugin configuration/scheduling is untested. Notification taps are not routed to the reminder view; patient home does not yet expose the new patient reminder view. Time-zone changes during an already-running process are not reconciled. Occurrence records are only latest local timestamps, not full server-compatible occurrence history. ID collision avoidance, cancellation of stale postponed alarms after edit, and sound-change rescheduling need fixes/tests. Android reboot/time-zone/permission/duplicate behavior needs device evidence.
8. Device gate uses OS biometric/PIN credentials, not backend caregiver identity. Security policy needs review; on devices without a configured screen lock it fails closed. Protected-return save errors and other unhandled save failures need usable retry UI. Sign-in provider/project still requires user choice; HTTPS endpoint/public client config are missing. Never ask for Admin credentials or AI keys in chat.
9. Large-text/reduced-motion preferences are not live-reactive (root state does not listen); settings explain reopen for text size. Golden layouts, smaller screens, TalkBack, navigation and all patient/caregiver flows still need work. Existing fixed-height/row layouts may overflow. Check system-back behavior rather than claiming a verified pause experience.
10. Stale comments/pubspec description still call implemented scaffolding in-memory-only or say backend is absent. Update them after verification to precise current capability, without overstating completion.
11. Doctor D1–D8 required, platform still unanswered. No doctor frontend built. Original prompt's other seven games, device checks, public Firebase setup, and production acceptance remain explicit external/deferred dependencies.

Full continuation instruction: `docs/handoffs/CLAUDE_CONTINUATION.md`. Next action is user-authorized continuation in this clone, followed by review/fixes and truthful verification. No task scope is marked complete by this paused milestone.


### 2026-09-08 stop follow-up

An automatic continuation fired during the stop handoff. The explicit user stop remains in effect; no implementation resumed. The `complete-tesseract-non-game-frontend` heartbeat was paused through the Codex automation tool. Resume only on a new user instruction.

## 2026-09-08 Claude — resumed Codex integration: verification and repair

**Actor:** Claude, in the nested clone
`/Users/pranav07vudiga/.codex/worktrees/4fa8/pranav07vudiga/tesseract`, branch
`codex/patient-caregiver-integration`. Resumed on explicit user instruction
following the stop record above. All uncommitted Codex work was preserved; the
original SIH checkout and the unrelated parent repo were not touched.

### What the stop record left unverified, and what is now actually true

Codex had run only dependency resolution and two interim analyses. No tests, no
APK, no formatting. That is now resolved:

- `dart format` applied to host lib, contract lib and contract tests (27 files
  changed). The new data layer was dense single-line code and unreviewable.
- `flutter analyze`: **clean, no issues**, on `code/host` and on
  `tesseract_game_contract`. This is the first clean analysis that *includes*
  the reminder/platform code Codex wrote after its last analysis run.
- **The lifecycle fix is real and now tested.** `TesseractGameStateMixin` had
  been advancing `seq` for backgrounding `paused`/`resumed` while discarding
  both returned events. Codex's one-line-each fix forwards them to
  `widget.onEvent`; I verified the diff and ran its 3 tests (pass). I added a
  host-level test proving the pair reaches durable storage with a contiguous
  sequence, because the practical consequence of the old behaviour was a
  permanent `sequence_gap` rejection at `POST /complete`.
- **`flutter build apk --debug` now SUCCEEDS** (193s) —
  `code/host/build/app/outputs/flutter-apk/app-debug.apk`, 167 MB debug. This
  is the first compile of the FlutterFragmentActivity switch, core-library
  desugaring, notification receivers and local_auth. `aapt2 dump badging`
  confirms `android.hardware.sensor.gyroscope` is still **not-required** (the
  touch fallback survives), plus POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED,
  VIBRATE and USE_BIOMETRIC.

### Build blocker found and fixed

The first APK attempt failed: `flutter_secure_storage` 11.x declares
compileSdk 37, and the only API-37 platform on this machine reports a
malformed `AndroidVersion.ApiLevel=37.0`, which AGP cannot resolve to the
`android-37` hash string. I did not hand-edit the user's Android SDK. Pinned
`flutter_secure_storage` to `^9.2.4` (same read/write/delete API, builds
against API 36) with the reason recorded in `pubspec.yaml`.

### Blocking privacy defect fixed — durable data is now identity-partitioned

Stop-record risk 3 was real and is the most important repair in this pass.
`saveSettings` wrote a single fixed row `'profile'` shared by every caregiver,
sessions and events carried no owner, and `connect()` fell back to
`patients.first` when the remembered patient did not match. On a shared device
a second caregiver would have inherited the first one's patient name, Know Me
content, reminders and session history — and could have had their own play
attached to a stranger's patient.

- `LocalRepository` schema v2: `sessions.scope` column, per-scope `meta` table,
  scope index, migration from v1 that leaves unattributable rows on the
  anonymous scope rather than handing them to whoever signs in next.
- Every read and write is scoped: settings, sessions, events (joined through
  session ownership), metadata, `markSynced`, `markError`, `recoverInterrupted`.
- `useScope` / `readActiveScope` / `clearActiveScope`. The active-scope pointer
  stores an identity key only, never patient content.
- `IdentityService` now surfaces the provider `uid` (`localId` on sign-in,
  `user_id` on refresh) as the partition key.
- `connect()` no longer adopts a stranger's patient: a stale selection is
  cleared and `availablePatients` is exposed for explicit choice. A single
  accessible patient is still adopted automatically.
- Sign-out saves into the caregiver's own partition, then drops the active
  pointer. Their data is retained for sign-in again, not deleted.
- `main.dart` reopens the last active partition on launch.

### Other repairs

- Zero-event sessions were left open forever and retried on every launch;
  `recoverInterrupted` now drops them (nothing to upload, nothing to complete).
- `lastSuccessfulSync` is persisted per scope and restored via
  `SessionOutbox.restore()`, so sync status survives a restart instead of
  reading as "never synced".
- Corrected the `SessionController` doc comment and the `pubspec` description,
  both of which still claimed there was no backend, database or persistence.

### Tests written this pass — 35 new, all passing

`code/host/test/data/`:

- `local_repository_test.dart` (16): reopen durability for settings and for a
  completed session's events; four identity-isolation cases; sign-out keeps
  data but hides it; per-scope metadata isolation; identical completion
  accepted and differing completion refused; interrupted recovery for terminal,
  mid-play, assisted, zero-event, repeated-launch and wrong-scope cases.
- `session_outbox_test.dart` (11): create→batch→complete ordering; replay after
  a lost response; duplicate-only acknowledgement still completes; a rejected
  event is retained not deleted; an unacknowledged event is a failure not a
  success; 500 retryable leaves the session pending; 401 stops without
  discarding; offline keeps data; 1201 events upload in 3 ordered batches;
  last-sync time survives restart; another caregiver's session is never sent.
- `session_pipeline_test.dart` (8): contiguous sequence storage; backgrounding
  yields a gap-free uploadable session; a dropped event is refused rather than
  written as a gap; `elapsed_ms` on the wire and no `elapsedMs`; no double
  finalisation; tilt sessions do not claim an observed input mode; explicit
  touch preference is recorded; interrupted recovery invents no finish event.

### Checks actually run, exact results

- `flutter analyze` host: **No issues found.** contract: **No issues found.**
- `flutter test` — contract 22, route_quest 16, marble_maze 17, host 56.
  **111 passing project-wide** (host was 21 before this pass).
- Two HowToPlay goldens were stale because Codex added game-specific
  instructions; regenerated deliberately, whole golden suite 20/20.
- `flutter build apk --debug`: **success**, manifest verified with `aapt2`.
- Device inventory run: `flutter devices` shows iOS simulator, a wireless
  iPhone, macOS and Chrome. `adb devices` is **empty**.

### NOT TESTED — no evidence exists for these

- **No Android phone or emulator is connected**, so every Android device
  behaviour is NOT TESTED: notification delivery, permission denial, reboot
  restoration, time-zone change, duplicate scheduling, biometric/PIN gate,
  Marble Maze tilt feel, and real-device performance.
- **Firebase is unverified against any real project.** No project, provider
  choice or HTTPS backend URL has been supplied; `IdentityService.configured`
  is false without them, so real sign-in cannot be exercised at all.
- **The outbox has never talked to the live backend.** All 11 outbox tests use
  a mocked HTTP client shaped to the contract, not the running service.
- No browser walkthrough or new screenshots this pass.

### Remaining unfinished work

Stop-record items 4, 5, 6, 7, 9 and 11 are largely untouched: server patient
creation/selection and personalization upload are not wired to screens; the
caregiver dashboard still lacks accept/modify/reject UI and config-version
propagation; Know Me content is not yet converted into approved `GameItem`s;
notification taps are not routed and the patient reminder view does not exist;
large-text/reduced-motion are not live-reactive; the caregiver dashboard and
patient screens have not had the visual pass; doctor D1-D8 platform is still
unanswered. Session `config_version`/`content_version` remain hardcoded '1'.

### Next action

Wire the caregiver dashboard: pending recommendations with accept/modify/reject
against `POST /v1/recommendations/{id}/decision`, applied config version
propagation, and real session history — then the patient-facing visual pass.
Ask the user for the Firebase project/provider choice and HTTPS backend URL,
and for an Android device for the reminder and tilt checks that cannot be
verified in this environment.

### 2026-09-08 Claude — second pass: caregiver decision loop and design system

Continued in the same clone after the verification/repair pass above.

**Reusable design system before applying it.** `design_system.dart` gained
tokens (`inkSoft`, `pageGradient`, `gutter`, `cardRadius`, `patientTarget` at
64dp) and components: `TesseractBackground`, `TesseractCard` (with a peach
`accent` variant), `SectionHeading`, `PillButton`, `StatusNote` and
`BigPatientAction`. Coral stays decorative: `StatusNote` and the activity rows
carry meaning in icon **and** words, so nothing depends on colour alone.

**C4 Caregiver Home rebuilt** (`caregiver_home_screen.dart`, was untouched
skeleton): real recent activity from stored sessions, truthful sync status,
a preview-data warning when synthetic, storage-error surfacing, and the
**pending recommendation card with accept / choose level / keep as is**, wired
to `POST /v1/recommendations/{id}/decision` through the new
`HostFlowState.decideRecommendation`. `expected_config_version` is always sent
so a stale proposal cannot overwrite newer approved config; a 409 surfaces to
the caregiver as "nothing was changed" instead of being retried silently. The
card states in plain words that the thresholds are still being tested and that
the caregiver decides.

**Two real defects found by looking at the generated screenshots, not by
assuming they were fine:**

1. Filled button labels rendered as blank white blocks. `ThemeData.fontFamily`
   reaches `textTheme` but not a raw `TextStyle` inside `filledButtonTheme`, so
   every black pill button in the app was drawing `.notdef` boxes. Fixed by
   naming the family in both places.
2. Game names displayed as raw ids (`route_quest`). The registry stores
   `route_quest_name`; the recommendation card was passing the bare `game_id`.
   Added `HostStrings.gameName()` for the API's id form. Also replaced a `→`
   glyph (no glyph in the loaded faces, drew as a box) with the words "from
   level 1 to level 2", which also reads correctly aloud.

Also fixed: the golden helper rendered every screenshot with an old green
placeholder theme that no screen uses, so goldens did not show the shipping
design. It now uses `TesseractDesign.theme`; all goldens regenerated.

**Checks run:** `flutter analyze` clean. Host suite **71 passing** (56 → 71:
12 caregiver-decision behavioural tests plus 3 caregiver goldens). Whole
project **126 passing** (contract 22, route_quest 16, marble_maze 17, host 71).
`flutter build apk --debug` succeeds against the current code. Screenshots
inspected directly: caregiver home at 1x and 2x text scale (wraps cleanly, no
overflow, no clipping) and patient home.

**Still NOT TESTED and unchanged from above:** no Android device is connected,
so notifications, the biometric gate and tilt remain unverified; Firebase has
never run against a real project; the outbox has never reached the live
backend. The decision loop is proven against a mocked client shaped to the
contract, not against the running service.

### 2026-09-08 Claude — three games integrated, doctor screens, design applied

Continued in the same clone on explicit authorisation to resume. Decisions the
user made when asked: port **both** of Ruthika's games **and** build Word
Search; doctor D1-D8 as **mobile screens, no web portal** (doctor signs in,
caregiver signs in, caregiver hands over to the patient); Firebase left
**unconfigured and clearly labelled**.

#### Ruthika's repository — what is actually there

Cloned read-only at commit `a504486` from `github.com/ruthikareddy678/GAMES`.
It holds **HTML/CSS/JavaScript only**: `game1` Picture Sorting (1229 lines JS)
and `game2` Daily Routine Recall (1746 lines JS). **There is no Word Search**,
which is her assigned G7, and Picture Sorting is not one of the nine catalogue
games. A web game cannot implement `TesseractGame`, so integration meant
porting the mechanics to Flutter, not importing a package. Full detail,
authorship and every deliberate change are in
`docs/handoffs/RUTHIKA_GAME_INTEGRATION.md`.

#### Three new game packages, all registered and playable

- `code/games/routine_recall` (G8) — ported from `game2`.
- `code/games/picture_sorting` — ported from `game1`, registered as an **extra**
  activity beyond the nine, at the user's explicit request.
- `code/games/word_search` (G7) — newly written; there was no source.

Changes to her mechanics, each deliberate: no score/high-score/stars; answers
compare **opaque ids** instead of names (her original compared step names,
which breaks on duplicate labels and would leak personal text); the default
routine with its medicine step was **not** imported — the routine is built from
the caregiver's own reminders in time order, falling back to a neutral day;
no browser speech; wrong answers are retryable with the attempt number
recorded so first-attempt accuracy stays separable.

Word Search uses the caregiver's familiar words, so it is the most personal
activity in the catalogue. Interaction is tap-first-letter/tap-last-letter
rather than a drag, which is far more forgiving with tremor. A word that will
not fit the grid emits `content_unavailable` with ids rather than vanishing.

**New event types** (`step_presented`, `attempt_resolved`, `word_found`,
`selection_rejected`, `all_words_found`, `content_unavailable`, `item_sorted`,
`sorting_completed`) have **no backend calculator yet**; the backend accepts
unknown types and falls back to `generic_v1`, so ingestion works but no
game-specific metric is computed. That is a bounded request for Pranav,
listed in the handoff.

#### Shared contract — one additive change

`tesseract_game_contract` gained `TesseractGameScaffold`: the Help/Break
controls and pause overlay, so three new games do not each reimplement patient
safety furniture. **Optional and additive** — Route Quest and Marble Maze draw
their own and are untouched. No event name, payload or type changed.

#### Doctor D1-D8, in the mobile app

`data/doctor_service.dart`, `doctor/doctor_patients_screen.dart`,
`doctor/doctor_patient_detail_screen.dart`. Sign-in now offers Caregiver or
Doctor; the role only decides which screen opens and grants nothing, since the
backend scopes everything by assignment. The detail screen shows observed
measures with sample counts, session history with tutorial/assisted/unverified
flags, a generated draft report with its provenance and limitations, and
attributed notes. It computes **nothing** of its own, so doctor and caregiver
can never see different numbers for the same sessions, and it renders
"not measured" where the backend reports a metric unavailable. There is no
method by which a doctor approves an activity: caregiver approval remains the
only path.

#### Other work this pass

Know Me content now reaches every game through a per-game content seam; the
patient path (home, choose activity, personalized activity, finished, rest,
progress, reminders) uses the design system; per-game instructions replaced a
two-way ternary; text size and reduced motion apply immediately.

#### Checks actually run

- `flutter analyze`: **clean** on host, contract and all five game packages.
- Tests: contract 22, route_quest 16, marble_maze 17, **word_search 24**,
  **routine_recall 11**, **picture_sorting 9**, host 76 — **175 passing**
  (was 126). The new game tests assert event sequencing, exactly-once
  finalisation, Help/Break, retry attempts, empty content, and that no
  personal label ever reaches a payload.
- All goldens regenerated after the redesign; 12 stale ones were pixel diffs
  from intentional change, with no exceptions or overflow errors.
- Screenshots inspected directly. Word Search's generated grid was verified by
  reading it: GARDEN down column 2, TEMPLE across row 5, CHAI across row 4.
- `flutter build apk --debug`: **succeeds**,
  `code/host/build/app/outputs/flutter-apk/app-debug.apk` (190 MB debug).

#### NOT TESTED

`adb devices` is **empty** — no Android phone or emulator. Every device
behaviour remains unverified: notifications, reboot/time-zone, the biometric
gate, Marble Maze tilt, and real emoji rendering (goldens have no emoji font,
so pictures show as boxes there; every item also carries a text label, so the
games stay usable either way, but this needs a phone to confirm). Firebase has
never run against a real project, so no sign-in path — caregiver or doctor —
has been executed end to end. The doctor screens have therefore never been
rendered against live data.

#### Next action

Ruthika reviews `docs/handoffs/RUTHIKA_GAME_INTEGRATION.md`. Pranav adds
backend calculators for the eight new event types. Someone runs the APK on a
real phone. Public Firebase config + HTTPS backend URL remain the blocker for
every authenticated path.

### 2026-09-08 Claude — North Eastern Region localization + About Tesseract

**Confirmed language list.** The records named Assamese, Bengali, Meitei, Khasi
and Mizo — but in a *review of the PPT's risk slide*, not as an approved list,
and `PS003_MASTER_CONTEXT.md` still lists "pilot language/native reviewer" as
unconfirmed. Asked the user; they confirmed **English + those five**, shipped
as clearly-labelled drafts. Recorded here as the approved list.

**These five cover only 4 of the 8 NE states.** Nagaland, Tripura, Arunachal
Pradesh and Sikkim have no language at all. That gap is named in
`LanguageCatalogue.uncoveredRegions`, shown on the About screen, and asserted
by a test so it cannot quietly disappear.

#### What was built

- `flutter_localizations` + `gen_l10n`. ARB files in `code/host/lib/l10n/` for
  en, as, bn, mni, kha, lus. 135 translatable keys.
- `src/l10n/language_catalogue.dart` — endonym, English name, script, region,
  measured coverage and review status per language.
- `src/l10n/language_selector.dart` — selector plus `DraftLanguageBanner`.
- `src/caregiver/about_screen.dart` — About Tesseract.
- Bundled `NotoSansBengali` and `NotoSansMeeteiMayek` (SIL OFL, licence in
  `code/host/fonts/LICENSE-NOTO.txt`) and wired `fontFamilyFallback`, because
  an entry-level Android device may not ship those scripts.

#### Measured coverage — not claimed, computed

| Language | Script | Coverage | Review |
|---|---|---|---|
| English | Latin | 100% | source |
| অসমীয়া Assamese | Bengali-Assamese | 73% | draft, awaiting native review |
| বাংলা Bengali | Bengali-Assamese | 73% | draft, awaiting native review |
| ꯃꯤꯇꯩꯂꯣꯟ Meitei | Meetei Mayek | 10% | draft, awaiting native review |
| Ka Ktien Khasi | Latin | 10% | draft, awaiting native review |
| Mizo ṭawng | Latin | 10% | draft, awaiting native review |

Meitei, Khasi and Mizo are deliberately low: only strings I had genuine
confidence in were drafted. Fabricating the rest would have looked complete
and been worse. A test recomputes every figure from the ARB files, so the
catalogue cannot drift into overclaiming.

**No language has been reviewed by a fluent speaker.** Every non-English
option is labelled draft with its coverage in the selector, carries a
persistent banner while in use, and states that untranslated text falls back
to English.

#### Behaviour

- Selector on the sign-in screen, usable **before** authentication; each
  language shown in its own script.
- Also in Settings, with **interface language and patient language separate** —
  the patient's follows the setup language until set, then stays put when the
  caregiver changes their own.
- Switching applies immediately: no restart, no sign-out, no lost form entry
  (asserted by a test that types an email, switches language, and checks it
  survived).
- Both persist per caregiver scope and survive restart.
- Game Help/Break/pause text and per-game instructions are looked up in the
  **patient's** language through `localizedGameStrings` /
  `localizedInstructions`, so the game boundary carries localized strings
  without games gaining any new dependency.
- About Tesseract: activity mark (**no approved logo exists** in the records,
  so none was invented), description, the exact line "Built and developed by
  the Tesseract Team.", real version/build read from package metadata with a
  bounded timeout, and the per-language coverage table.

#### Checks actually run

- `flutter analyze`: clean.
- Host tests **109 passing** (was 76; +28 localization, +5 l10n goldens).
  Other packages unchanged this pass: contract 22, route_quest 16,
  marble_maze 17, word_search 24, routine_recall 11, picture_sorting 9 —
  **208 project-wide**.
- Goldens regenerated and **inspected**. The first Bengali/Assamese/Meitei
  render showed **tofu boxes** — widget tests do not auto-load pubspec fonts.
  Loading the bundled Noto faces in the golden harness fixed it, which is real
  evidence the theme's font fallback works rather than an assumption.
- `flutter build apk --debug` **succeeds** with fonts and localizations
  included: `code/host/build/app/outputs/flutter-apk/app-debug.apk`, 191 MB.

#### NOT TESTED

No Android device (`adb devices` empty). Script rendering, missing glyphs,
text wrapping, TalkBack in non-Latin scripts, **localized notification text**,
and language switching on a real phone are all unverified. Goldens are not
device evidence. **Voice/audio is not implemented in any language** —
translated text is not a voice capability. Reminder bodies are still built in
`ReminderService` from untranslated literals.


## 2026-09-08 Codex continuation — translation milestone

Inspected clean HEAD `2d425b16cbae609d9b4d58eeff2abbfd6e868bb0` on
`codex/patient-caregiver-integration` in the requested nested clone. It is the
handoff-only commit after `b160220`; the handoff's older HEAD is reconciled.
Original Desktop checkout and unrelated parent repository remain untouched.

Expanded Assamese/Bengali ARB drafts and added notification localization keys.
Measured key coverage now: English 100%, Assamese 90%, Bengali 93%, Meitei 9%,
Khasi 10%, Mizo 10%. Meitei's rounded percentage decreased because the English
key set grew; no translations were removed. No low-confidence strings were
invented to raise Meitei/Khasi/Mizo coverage. All non-English languages remain
draft with English fallback; none is natively reviewed or voice-enabled.
See `docs/handoffs/TRANSLATION_REVIEW_2026-09-08.md` for wording needing review.
The exact attribution is preserved.

Regenerated localization sources/report and the three affected goldens
(Bengali sign-in, large Assamese sign-in, language selector). Visually inspected
all three: bundled script rendering is present, content scrolls at large text.
The first host run reported 107 passes and 3 expected changed-golden failures;
after regeneration the host run passed 110 tests including notification lookup.
This is automated rendering evidence, not phone/TalkBack validation.

Actual registry: Route Quest (G2), Marble Maze (G3), Word Search (G7), Routine
Recall (G8), Picture Sorting (extra). Therefore **four of nine required games
plus one extra**, five registered total; Aryan's G1/G4/G5/G6/G9 are missing.
Earlier statements '5 of 9 plus one extra' and 'four missing' were incorrect.

Next: finish notification/patient integration regression and record final build.


## 2026-09-08 Codex continuation — patient integration and final checks

Implemented in host only; no API contract, backend, game dependency or event
payload changes. Translation milestone committed as `8d72e4c`.

- `ReminderService.schedule` resolves notification title/channel metadata from
  patient language, passed by startup, reminder editing, postponement and
  language-change rescheduling. Untranslated keys fall back to English;
  caregiver-written reminder bodies are preserved verbatim. Scheduling errors
  retain preferences and expose retry status. Android channel metadata updates,
  delivery, denial, reboot/time zone and cancellation remain device-unverified.
- Caregiver home loads the authorized server patient list and offers explicit
  selection/creation. Patient Basics creates using existing POST contract and
  remembers the returned id. Age is local-only; existing basics edits are
  explicitly local-only because no update endpoint exists. Failed creation
  preserves form input; after an ambiguous network response check the refreshed
  list before retrying because the backend has no creation idempotency key.
- `HostFlowState` keeps durable patient snapshots inside the caregiver partition,
  preserving offline edits, activity selection/level, patient language, profile
  and config versions. Switching fetches access-controlled data before changing
  selection; history is filtered by patient id. Interface language remains
  separate. Server refresh does not silently replace an existing local activity
  choice; explicit recommendation acceptance refreshes approved activity.
- Know Me provides explicit version-checked personalization upload. Person/place
  kind is chosen rather than inferred from names; legacy untyped entries must be
  classified. Existing media references, preferences and retained word locales
  round-trip. A 409 leaves edits and the original version intact; no blind retry
  with a newer version. Review server copy shows local/remote text; only an
  explicit choice replaces local personalization, retaining a pre-reload backup
  in repository meta (`personalization_backup:<patient_id>`). No backup-restore
  UI is implemented. Legacy offline profiles lacking a content baseline must
  review the server copy before upload.
- `PlayScreen` supplies actual activity config_version/config parameters when
  game and level match the server activity. Local preset configurations use
  `local-v1`, not a fabricated server version. Content uses the returned profile
  revision for clean server content and a persisted local revision for changed
  content or local reminders. `SessionController` freezes these values for the
  session instead of hardcoding config/content version '1'. Schema and metric
  versions are unchanged. Personal words/names remain outside event payloads.

### Fresh verification (this continuation)

- `flutter analyze`: clean for host, contract, all five games and harness.
- `flutter test`: host **120**, contract **22**, Route Quest **16**, Marble Maze
  **17**, Word Search **24**, Routine Recall **11**, Picture Sorting **9** —
  **219 passing**. Harness has no test directory; no harness tests claimed.
- Ten new integration regressions cover patient switching/restart isolation,
  retained API fields, stale upload retries, access/fetch failure, creation,
  untyped legacy entries, explicit server review/backups, large-text patient form
  to Know Me, and frozen session versions/parameters. Added notification-locale
  fallback coverage; measured language coverage now requires exact rounding.
- `flutter build apk --debug`: success; APK at
  `code/host/build/app/outputs/flutter-apk/app-debug.apk`. Build emits a plugin
  Kotlin migration warning but completes. `git diff --check` clean.
- Three updated localization goldens inspected; patient creation widget tested
  with 2x text. These are automated checks, not live API/device evidence.
- `adb devices` outside sandbox: empty device list. All on-device behavior,
  TalkBack, biometrics, tilt feel, notification delivery, real wrapping/glyphs
  remain **NOT TESTED**. No live Firebase or backend sign-in path validated.

### Confirmed configuration and remaining dependencies

User confirmed Firebase project **tesseract-3ac5a**, provider **Email/Password**.
Public `FIREBASE_API_KEY` and HTTPS `TESSERACT_API_URL` will be supplied later.
No credentials or private keys were requested/stored. Real authentication was
not replaced with synthetic access. Paused automation remains paused.

All non-English translations remain draft; fluent-speaker review is required,
especially for Meitei/Khasi/Mizo expansion. No languages added for uncovered
regions, no voice support claimed. Backend still needs calculators for
step_presented, attempt_resolved, word_found, selection_rejected,
all_words_found, content_unavailable, item_sorted, sorting_completed; and a
patient-basics update endpoint. Ruthika review and five missing required games
remain outstanding. Next action: supply public config and a phone, then run real
sign-in, patient creation/selection/upload/conflict and offline reminder checks.
No push; original Desktop/SIH and unrelated parent repository untouched.


## 2026-09-08 user-confirmed remaining scope and NER speech requirements

Documentation-only update requested by the user: include all five existing unfinished areas plus spoken output/input, per-language verification and explicit fallback in a reusable continuation prompt. No application code changed, no speech implementation or new verification claimed, and the paused automation remains paused.

Existing gaps remain: Assamese 90%, Bengali 93%, Meitei 9%, Khasi 10%, Mizo 10% recorded text coverage; no non-English native review; real Firebase/backend sign-in configuration/verification; physical Android checks NOT TESTED; missing backend event calculators and patient-basics update endpoint; five missing required games (four of nine required plus Picture Sorting extra currently registered). Recompute and inspect before treating these figures as current in a later task.

New required functionality: optional spoken instructions, Help and reminders in patient language; optional tap-to-speak commands/dictation with explicit confirmation before saving/acting; independent TTS/STT and pronunciation/recognition verification for Assamese, Bengali, Meitei, Khasi and Mizo; clear text/touch fallback with NO silent language substitution. Speech input/output are NOT IMPLEMENTED as of this record. Translated text and notification sounds are not speech support.

Acceptance requires current provider/device capability checks per language, fluent-speaker review, permission/denial/offline/cancel/error/lifecycle handling, audio preference, no overlapping speech, and preservation of caregiver access controls. Do not promise all-language offline speech or mark unavailable engines as supported. Paid/cloud service choices and external audio processing need explicit approval; credentials stay server-side. Personal speech/text must not leak into event payloads or logs. Preserve language selection before sign-in/in Settings and About Tesseract attribution.

Full reusable implementation prompt and detailed verification requirements: `docs/handoffs/REMAINING_WORK_AND_NER_VOICE_PROMPT.md`. Pranav retains backend/API/analytics ownership; teammates retain game ownership. Missing repository/service/provider decisions remain explicit dependencies.

Checks in this documentation pass: inspected clean Git status and latest continuity tail; wrote the prompt and appended this requirement record to Brain.md and PS003_MOBILE_CODE_STATUS.md. No application tests/builds were run because no application code was changed.


## 2026-09-08 Claude continuation — speech, live Firebase, translation completion

Worktree `/Users/pranav07vudiga/.codex/worktrees/4fa8/.../tesseract`, branch
`codex/patient-caregiver-integration`, from clean HEAD `9aad482`. Original
Desktop/SIH checkout and the unrelated parent repo untouched.

### Live Firebase — a recorded fact was wrong

The record said project `tesseract-3ac5a` with Email/Password was "confirmed".
Inspecting the console showed otherwise: **no app was registered and
Authentication had never been enabled** (it still showed "Get started"). No
sign-in had ever been possible, and no Web API key existed to make one possible.

With the user's explicit approval, and after they signed in to the console
themselves in the browser: Email/Password was enabled, and a Web app was
registered (App ID `1:122183355821:web:4e5e5942e5d696fb02a524`, project number
122183355821), which produced the public Web API key.

**Verified live**, against the exact endpoints `IdentityService` calls:

| Call | Result |
|---|---|
| `accounts:signUp` (test caregiver) | 200, `localId` returned |
| `accounts:signInWithPassword` | 200, idToken + refreshToken, `expiresIn` 3600 |
| same, wrong password | 400 `INVALID_LOGIN_CREDENTIALS` |
| `securetoken/v1/token` refresh | 200, same uid, new id_token |
| same, invalid refresh token | 400 `INVALID_REFRESH_TOKEN` |

That is real identity verification, not a mock. The API key and the disposable
test account live in a chmod-600 file **outside the repository**; nothing was
committed, and no service-account key was requested, seen or stored.

**Still not verified end to end.** The backend's `FirebaseIdentityVerifier`
needs a service-account file the user must download themselves, and
`IdentityService.configured` requires `TESSERACT_API_URL` to start with
`https://`, so a local `http://localhost` API is refused by design. Client →
Firebase is proven; client → Firebase → API is not.

Vercel was inspected and is **not relevant**: no frontend, no `vercel.json`, no
deployment config. The FastAPI service was not moved there.

### Translations

Recomputed from the ARBs before touching anything; the recorded 90/93/9/10/10
matched the test's metric. Then:

* Assamese and Bengali completed: **100% each** (167/167 translatable keys),
  including 32 new speech strings. Meitei 8%, Khasi 8%, Mizo 8% — these *fell*
  only because the English set grew from 138 to 169 keys. **No wording was
  invented for them**; I do not have the confidence, and guessing to raise a
  percentage is the failure mode this project has been explicit about.
* The denominator is now honest. `appName` and `builtBy` are marked
  `x-untranslatable` in `app_en.arb` and excluded: the product name and the
  fixed attribution must render in exact English everywhere, so their absence
  from a translation file is correct, not missing.
* The coverage test got stricter, and these are new failures it can now catch:
  a translation that is a **verbatim copy of English** (the easiest way to fake
  coverage — two genuine Mizo loanwords are allow-listed by name), a locale
  that **overrides an untranslatable key**, a **dropped `{placeholder}`**, and a
  **stale key** propping up a percentage.
* **100% is still `ReviewStatus.draft`.** A test now asserts exactly that: full
  text coverage must not imply fluent-speaker review. No language has been
  reviewed by a fluent speaker. That remains the top translation blocker.

### Speech — implemented, in the host layer only

New `code/host/lib/src/speech/`. No game gained a network, database, auth or
speech dependency; the contract boundary is intact.

* `speech_capability.dart` — the per-language matrix, with vendor
  documentation and device probe results as **separate** concepts. Only the
  probe decides behaviour. `resolveEngineTag` normalises case/separator and
  allows a bare tag to match a region, but **never matches across languages**.
* `speech_engine.dart` / `platform_speech_engine.dart` — a thin seam over
  `flutter_tts` and `speech_to_text`, plus `Unavailable*` engines for web. All
  policy lives above the seam, so it is genuinely testable.
* `speech_output_service.dart` — optional spoken instructions and reminders in
  the patient's language. One utterance at a time, stop/replay, gated on the
  audio preference, stopped on background and on language change.
* `voice_input_service.dart` + `voice_input_sheet.dart` — tap-to-speak. No
  always-on listening, microphone requested at point of use, transcript shown
  and **confirmed before anything is saved**. Dictation appends to the reminder
  field rather than overwriting it, and Save is still a separate press.
* `speech_settings_section.dart` — Settings → "Speaking and listening" probes
  the real engines on the phone, per language, **in both directions
  separately**, and says "not checked on this phone yet" until asked.

The honest-fallback rule is the point of the whole thing: when a language has
no voice, the app names that language and stays quiet. It never reads Mizo or
Khasi aloud with an English voice because both use Latin letters — there is a
test that walks every NER tag against an English-only engine list and asserts
no match, and a golden showing the message a Mizo patient actually sees.

**Not spoken:** the in-game pause overlay. That text is drawn inside the game
packages, and speaking it would require giving games a speech dependency, which
the contract forbids. Host-level instructions, Help text and reminders are
spoken; the overlay is not, deliberately.

### NER speech capability

Researched against Google's official TalkBack voice list and Gboard voice-typing
docs. **Only Bengali is documented by Google for either direction.** Assamese,
Meitei, Khasi and Mizo appear in Google *Translate* and Gboard *typing*, which
is a different capability entirely — the trap this work is built to avoid.
Full matrix and sources: `docs/handoffs/NER_SPEECH_MATRIX.md`.

Every device column reads **NOT TESTED**. `adb devices` was empty all session.

### Backend gaps — still real, handoff prepared

Both verified in code, not inherited: there is **no** `PATCH /patients/{id}`,
and **none** of the eight event types has a calculator. Exact payloads copied
from the emitting lines, plus a nine-event fixture, are in
`docs/handoffs/PRANAV_BACKEND_GAPS.md`. No contract was redefined and no metric
invented — those are Pranav's. Patient-basics edits stay labelled local-only;
unavailable metrics stay unavailable, never zero.

### Games

Registry unchanged and re-verified: Route Quest, Marble Maze, Word Search,
Routine Recall, Picture Sorting — **four of the nine required, plus one extra**.
Aryan's Reveal Match, Trace, Coloring, Spot Difference and Picture Recall do not
exist here; the user confirmed no repositories are available yet.

### Verification actually run

* `flutter analyze`: clean on host, contract, all five games, harness.
* `dart format`: clean.
* `flutter test`: host **156**, contract 22, Route Quest 16, Marble Maze 17,
  Word Search 24, Routine Recall 11, Picture Sorting 9 — **255 passing**.
  New: 28 speech tests, 4 speech UI/golden tests, 4 new localization tests.
* Goldens regenerated and **visually inspected**: `how_to_play_speech.png`
  (Read aloud control on-design between instruction and Begin),
  `how_to_play_speech_unavailable.png` (names Mizo, text stays, Begin works),
  Bengali 2× large text, language selector, Assamese/Bengali sign-in.
* `flutter build apk --debug`: success, 183 MB, at
  `code/host/build/app/outputs/flutter-apk/app-debug.apk`. `aapt2` confirms
  `RECORD_AUDIO` is in the built manifest.

Two real bugs were found and fixed by this work, not papered over: the
`flutter_tts` constructor made an unguarded platform call that threw on any
host without the plugin, and its replacement scheduled a Timer that leaked past
widget-test teardown.

### Blockers

1. **No Android device.** All on-device behaviour — speech quality, engine
   availability, notifications, biometrics, gyroscope, glyphs, TalkBack —
   is NOT TESTED.
2. **No fluent speaker** for any of the five languages. Nothing is reviewed.
3. **Expected provider gap**: four of five NER languages have no documented
   Google voice or recogniser. A limitation to report, not to code around.
4. **Backend**: service-account file + an HTTPS API URL to finish the
   end-to-end auth path; the two gaps above.
5. **Five required games** absent.


## 2026-09-08 Expo Go port — React Native frontend alongside Flutter

User asked for an Expo Go-compatible React Native build so the app can be run
on an **iPhone** by scanning a QR. Flutter is untouched and remains the
reference implementation; the new app is `code/tesseract-expo`.

Context for why: `adb devices` was empty all session and the user has no Android
phone. The Flutter host has **no iOS target at all** (`code/host` has `android/`
and `web/` only), and its remaining checklist is Android-specific, so an iPhone
could not validate it.

### Compatibility decisions, checked not assumed

- **Expo SDK 57.** App Store Expo Go is **57.0.9** (2026-09-02) and Expo Go runs
  only the newest SDK. The SDK 57 changelog still says iOS approval was pending
  — written at release; the store listing is the current fact.
- **`expo-doctor`: 21/21 passed.** Every dependency is Expo Go-bundled or pure
  JS. No prebuild, no development client, no native config plugin.
- **Speech recognition is impossible in Expo Go**, and this is documented, not
  worked around. `expo-speech-recognition` states it requires a development
  build; Expo Go runs a fixed App Store binary that cannot load a native module
  it was not compiled with. `expo-speech` (TTS) *is* bundled and works.

### Built and verified

- Design tokens and components ported from `TesseractDesign` — cream ground,
  coral accents, white rounded cards, black pill buttons, 64pt patient targets,
  accessibility roles and labels throughout.
- Localisation **generated from the Flutter ARBs** by `tools/sync-l10n.mjs`, so
  the two apps cannot drift. `npm run l10n:check` fails if they do. Same
  measured coverage: en/as/bn 100%, mni/kha/lus 8%, all non-English **draft**.
- TypeScript game contract with the same invariants as the Dart one, enforced
  by throws rather than asserts.
- All five activities ported with rules, events, sequencing and difficulty
  settings unchanged, attributed to Ruthika.
- Outbox with ordered create → events → complete, stable ids across retries,
  500-event batch cap, permanent-4xx stop, 401 pause, restart recovery.
- Identity over the same Firebase REST endpoints already verified live. No
  synthetic fallback.
- Caregiver dashboard, patient basics, hand-over, patient home, choose activity,
  instructions with Read aloud, play, finished, rest, settings with the speech
  probe and About.

**38 tests passing** (contract 9, games 20, outbox 9). TypeScript strict clean.
`expo-doctor` 21/21. **iOS bundle builds: HTTP 200, 5.3 MB.**

### Not verified, and not claimed

**Nothing has run on the iPhone.** A built bundle is not a device test. App
start, navigation, language switching, the full loop, storage across restarts,
offline, VoiceOver, Dynamic Type, motion input and all speech behaviour are
**NOT TESTED** until the QR is scanned.

### Deliberately not built yet, and said so on screen

Know Me editing, reminders, the recommendation decision loop, doctor screens,
the biometric gate, and bundled Noto fonts. Those screens state outright that
they are not built rather than showing plausible-looking empty states. The
Flutter build has all of them; this is a first working port, not parity.

Also stated: in-game wording is English-only, matching Flutter's existing gap,
rather than inventing ARB keys to inflate coverage.

Full detail, setup and the per-language speech matrix:
`docs/handoffs/EXPO_GO_STATUS.md`.
