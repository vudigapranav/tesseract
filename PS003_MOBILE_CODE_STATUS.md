# PS003 mobile code status

Updated 2026-09-07 by Claude. This is the entry point for anything under `code/`.
Backend agents: this file tells you what the Flutter side actually is right now, so
you do not have to read the Dart. Nothing under `code/` reaches into `services/`.
The wire contract between the two is `docs/contracts/PS003_API_CONTRACT_V1.md`;
the backend that implements it is `services/api` (see its README for status).

## What exists

`code/` holds the Flutter mobile side. Five packages. No third-party dependencies
anywhere in the games or the contract — only `flutter`, `flutter_test`,
`flutter_lints`, and path dependencies between our own packages. (The host's
Android build itself needs no extra pub dependency either — Marble Maze's tilt
reads a native Kotlin sensor bridge in the host's own `android/`, not a plugin.)

- `code/packages/tesseract_game_contract` — the shared contract. **Every one of the
  nine games implements this.** Aryan's five and Ruthika's two must use it unchanged.
- `code/games/route_quest` — G2, Pranav. Node-graph world, BFS shortest path, route
  efficiency, illustrated visual redesign, fixed-timestep animation. Built.
- `code/games/marble_maze` — G3, Pranav. Grid collision, touch input, Android
  fused-gyroscope tilt with touch fallback. Built; native build verified, physical
  device feel not yet.
- `code/harness` — a developer app for running the two games with fake content.
  Has Android + web platform folders and runs.
- `code/host` — the real app shell. Has Android + web platform folders and runs.
  Now covers the **full decided frontend skeleton**: patient P1-P9 and caregiver
  C1-C7, connected end to end (sign-in through hand-over through play through the
  protected caregiver-return gate). Structural skeleton, not final visual design —
  see `code/host/README.md`. Doctor portal (D1-D8) is deliberately not built here;
  the docs mark its platform as an open decision.

## The contract, for backend readers

A game is a self-contained widget. It never touches network, database, auth,
storage or navigation. It receives `GameConfig` and reports through
`onEvent(GameEvent)` and `onFinish(GameResult)`.

**Field ownership at the boundary — this is what the backend needs:**

- The **game** supplies: `type`, `seq`, `elapsedMs`, `payload`.
- The **host** must add when wrapping: `event_id`, `session_id`, `patient_id`,
  `occurred_at` (UTC), `game_id`, `game_version`, `schema_version`.

Guarantees the game side already enforces, in every build mode (real throws, not
asserts — a release build cannot silently break these):

- `seq` starts at 1, increments by 1, is never reused or skipped.
- `elapsedMs` is monotonic and excludes paused **and backgrounded** time.
- `session_finished` fires exactly once. A second call throws.
- No event can be emitted after the session finishes.
- Payloads carry opaque IDs only — no names, labels, image paths or coordinates.

Lifecycle event types, matching `docs/PS003_GAME_ASSIGNMENTS_AND_UI.md`:
`session_started`, `tutorial_started`, `tutorial_completed`, `hint_requested`,
`support_changed`, `paused`, `resumed`, `session_finished`.

`GameConfig` carries the real session snapshot fields the analytics need:
`schemaVersion`, `configVersion`, `contentVersion`, `metricVersion`, `isTutorial`,
and **`difficultyParams`** — the actual settings for the level, not just the number.
Each game declares its own params so the host records what was really used rather
than an Easy/Medium/Hard label.

## Game-specific events

**Route Quest (G2):** `location_entered {nodeId}`, `destination_reached`,
`item_collected`, `return_completed`, `wrong_interaction {objectId}`.
`difficultyParams`: nodeCount, branchCount, requiresReturn.
Route efficiency = BFS shortest path / actual path, completed routes only.

**Marble Maze (G3):** `collision {wallId}`, `dead_end_entered {cellId}`,
`goal_reached`. `difficultyParams`: corridorWidth, turnCount, deadEndCount.
Path efficiency = shortest grid path / actual path travelled.

## Known gaps — do not treat these as done

1. **Interactive target not yet verified.** `code/host` now has Android and web
   platform folders and can be used for the integrated preview. The older harness
   still lacks platform folders. The redesigned games have not yet been inspected
   running on a physical phone or in a browser.
2. **Android tilt is implemented and the native build is verified; physical-device
   tuning is the only thing still pending.** The Android host uses the fused
   game-rotation sensor, calibrates the resting phone angle, smooths motion and
   selects `inputMode: 'tilt'` for Marble Maze. Touch is retained as the no-sensor
   fallback and for explicit touch-mode configurations. `flutter build apk --debug`
   succeeded (Kotlin sensor bridge compiles, manifest correctly declares the
   gyroscope optional) — see Brain.md for the exact evidence. What remains is
   feel: sensor direction/sensitivity/dead-zone tuning needs a real phone. No
   agent in this environment has a connected Android device or emulator; web and
   widget tests cannot validate physical gyroscope feel either.
3. **Host now covers the full P1-P9 + C1-C7 skeleton, but everything in it is a
   placeholder.** Sign-in, patient basics, Know Me, reminders, settings and
   hand-over are all real, connected screens with no real auth, no persistence,
   and no notification scheduling — all state is in-memory and resets on
   restart. Know Me content is captured but not wired into any game's
   `GameItem`s. The doctor portal (D1-D8) has not been started at all; its
   platform (mobile vs. separate web) is still an open decision.
4. **No backend connection from this side yet.** No game writes anywhere. The
   event sink is still a callback, and `SessionController` still only prints
   its snapshot. **The backend it will talk to now exists** — a runnable
   FastAPI + PostgreSQL service in `services/api`, with the wire contract in
   `docs/contracts/PS003_API_CONTRACT_V1.md`. Writing the SQLite outbox against
   that contract is the next integration step and has not started.

   Two things in that contract need a **host-side** change (neither touches a
   game or the contract package): `GameEvent.toJson()` emits `elapsedMs` but the
   API takes `elapsed_ms`, so `SessionController` must map it; and the host
   should report `actual_input_mode` (what the device really used) separately
   from the requested mode, because Marble Maze falls back to touch with no
   gyroscope and comparability depends on knowing which actually happened.

5. **Neither game exports what its efficiency metric needs.** This is a real
   game-side gap, found while writing the metric calculators:

   - **Marble Maze** emits `collision`, `dead_end_entered` and `goal_reached`
     only. Path efficiency needs `distance_travelled_units` and
     `shortest_path_units`.
   - **Route Quest** computes a BFS shortest path at level load
     (`RouteGraph.shortestPathLength`) but never exports it. Route efficiency
     needs `shortest_path_length`.

   Both values are already known inside the games — this is an export, not a
   new computation. Until they are added, the backend reports both metrics as
   **unavailable with a reason**, never as 0, and caregiver/doctor views must
   show "not measured". Adding them is a deliberate contract change for the
   game owner (Pranav), not something to slip in silently.
6. **`PS003_ADDITIONS.md` is unapproved.** In particular the `hit_offset_dp` field
   on `attempt_resolved` (accessibility calibration) is **not** in the contract yet
   and must be added before the tap-based games G1, G6, G8, G9 are written, if it
   is approved at all.

## What the other seven games must do

Aryan (G1, G4, G5, G6, G9) and Ruthika (G7, G8) depend on
`code/packages/tesseract_game_contract` by path and implement `TesseractGame`.
They add no dependencies, hardcode no display text (everything via `GameStrings`),
never set their own level, and use `TesseractGameStateMixin` so backgrounding
pauses the session clock the same way in every game.

Any change to the contract affects all nine and needs Pranav's approval.

## Status

Contract and two games: written, `flutter analyze` clean, unit and widget tests
passing. **Not verified on a device, not connected to anything, not demonstrated
end to end.** No claim of a working application is supported by this folder yet.

## 2026-09-06 Codex game-feel milestone

Route Quest and Marble Maze received a first visual-polish pass without changing
their event contracts or difficulty metrics. Route Quest now uses an illustrated
landscape, recognisable home/flag landmarks, layered roads, a moving traveller,
target emphasis and calm flag-collected feedback. Marble Maze now uses a tactile
wooden board, recessed channels, a dimensional marble, an illuminated goal and a
visible shortest-path Help guide.

Verified on Flutter 3.47.2 / Dart 3.13.2:

- analysis of both game packages and `code/host`: no issues
- Route Quest: 16 tests passed
- Marble Maze: 16 tests passed
- Host and golden screenshots: 19 tests passed
- total: 51 passing automated tests
- visually inspected both level 1 and level 3 boards, both pause states, Route
  Quest's return state, Marble Maze's Help state and the 2x text-scale host state

This evidence covers local analysis, widget behavior and fixed-size rendered
screenshots. It does not replace Android device QA, browser interaction QA,
performance measurement, backend/outbox integration or clinical validation.

## 2026-09-06 Codex motion-control milestone

- Removed the developer event-log control from the patient play surface; events
  still flow through the unchanged callback and session envelope.
- Added Android fused-gyroscope tilt for Marble Maze through a native event
  channel, with neutral calibration, smoothing, a dead zone and no new package
  dependency. The host now configures Marble Maze as tilt-first. Touch remains the
  automatic no-sensor fallback.
- Added gentle haptic acknowledgement for valid Route Quest movement, Help,
  collision contact and completion, plus a calm game-specific finish mark and
  transition. Reduced-motion settings stop decorative ambient animation.
- Flutter analysis was clean before the final native gyroscope-availability guard
  and host configuration test. Route Quest remains 16/16. Marble Maze is now
  17/17, including an injected fused-motion test. The refreshed host/golden suite
  is 20/20, for 53 passing tests total. Updated browser QA confirms the patient
  play surface exposes only Help and Break.
- Android NDK 28.2.13676358 and Build Tools 36 installed successfully. The first
  Gradle assemble was manually stopped at the user's request before producing an
  APK, so Kotlin/native compilation and physical-phone direction/sensitivity
  remain unverified. Rerun analysis, tests and `flutter build apk --debug` first.

## 2026-09-06 Claude build-verification milestone

Independently re-ran everything above from scratch rather than trusting Codex's
numbers, then completed the one step Codex had explicitly deferred.

- `flutter analyze`: clean on all five packages (contract, route_quest,
  marble_maze, harness, host).
- Tests: contract 22/22, route_quest 16/16, marble_maze 17/17, host 21/21 real
  tests (a new `session_controller_test.dart` plus 20 golden screenshots) — 76
  automated tests passing project-wide. Visually inspected every new/changed
  golden; no defects.
- `flutter build apk --debug` **succeeded** (792s) —
  `code/host/build/app/outputs/flutter-apk/app-debug.apk`. This is the first
  real compile of the native Kotlin gyroscope bridge. Confirmed via
  `aapt dump badging` that the merged manifest still declares
  `android.hardware.sensor.gyroscope` as not required, so the app installs on
  gyroscope-less phones too.
- Fixed one stale doc comment (`play_screen.dart` still described the removed
  event-log panel).

Still not done, and not claimed as done: physical tilt feel, direction and
sensitivity. No Android device or emulator is connected in this environment.
Installing `app-debug.apk` on the actual phone and judging tilt by feel is the
only remaining step — see Brain.md's Next action for the specific constants to
adjust (`_tiltDeadZone`, calibration sample count, the low-pass lerp factor,
`_tiltGridUnitsPerSecond`) if it drifts or feels off.

Also worth knowing: the harness's tilt option for Marble Maze will silently
behave as touch, since only `code/host` has the native
`org.tesseract/marble_tilt` channel. Acceptable for a dev tool, not a defect —
just don't spend time debugging it there.

## 2026-09-07 Claude host frontend skeleton milestone

Built the full decided frontend skeleton into `code/host`: patient P1-P9 and
caregiver C1-C7, as structure only — visual design is deliberately
unfinished; the frontend team redesigns it next. Doctor portal (D1-D8)
confirmed out of scope pending its own platform decision. Full detail,
file list and the exact live-QA walkthrough are in Brain.md; summary here:

- 9 new screens: C1-C7 (`lib/src/caregiver/`) plus P7 Personalized Activity
  and P9 Simple Progress. Plus `CaregiverReturnGate`, the placeholder
  "protected return flow" from patient mode back to caregiver mode.
- The app now starts at C1 Sign In, not Home directly — matching the real
  product structure (caregiver sets up, then hands the device over).
- `HostFlowState` expanded to carry caregiver sign-in, patient basics, Know
  Me content, the caregiver-approved activity/level, reminders, settings and
  full activity history — all in-memory, all placeholder, none of it real
  caregiver data yet.
- Home's Start now branches to P7 when a caregiver approved an activity at
  Hand Over, else P2 — the actual "Start to P2 or approved P7" rule, not
  just P2 every time.
- `flutter analyze` clean on all five packages; host tests still 21/21 (no
  new goldens — see the reasoning in `code/host/README.md` and Brain.md).
  Correctness of the 9 new screens was verified by one continuous live
  click-through in the web preview: sign in, fill in patient basics and Know
  Me, hand over an activity, play into it from Home through P7, stop the
  session, and confirm the caregiver-return gate lands back on Caregiver
  Home showing the real session that was just played. Every step in that
  chain is real, not mocked.
- Know Me content is captured but **not** wired into any game's content yet
  — that connection is separate integration work, not claimed as done here.
  Companion/"together" mode was not added to Hand Over, since
  `PS003_ADDITIONS.md` remains unapproved.
