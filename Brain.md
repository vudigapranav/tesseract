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
