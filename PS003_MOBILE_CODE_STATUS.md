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

## 2026-09-08 Claude — verification and repair of the Codex integration pass

Resumed the paused Codex work in the nested clone (branch
`codex/patient-caregiver-integration`). Full detail in Brain.md; what matters
for anyone reading `code/`:

### The shared lifecycle defect is fixed and tested

`TesseractGameStateMixin` was advancing `seq` for backgrounding
`paused`/`resumed` and then **discarding both events**. Every background
excursion punched a permanent hole in the uploaded sequence, which the backend
correctly refuses to complete over (`422 sequence_gap`). The mixin now forwards
both recorder-returned events to `widget.onEvent`. Verified by the contract
package's 3 mixin tests plus a host test asserting the pair reaches storage
with a contiguous sequence.

**No game package was modified.** This was a shared-layer fix inside
`tesseract_game_contract`.

### Durable local data is partitioned by caregiver identity

Previously all caregivers shared one settings row and unowned sessions, and a
mismatched patient silently fell back to `patients.first`. On a shared device
that leaked one caregiver's patient name, Know Me content, reminders and
history to the next. Now: schema v2 with a `sessions.scope` column and per-scope
`meta` table, every read/write scoped, provider `uid` as the partition key, no
silent patient adoption, and sign-out that hides data without deleting it.

### Host boundary status

`SessionController` writes each event durably as it arrives, maps the game's
`elapsedMs` to the API's `elapsed_ms`, enforces contiguous `seq` and
exactly-once finalisation, and **does not fabricate `actual_input_mode`** for
tilt sessions the host cannot observe. `SessionOutbox` uploads
create → batches of ≤500 → complete, treats duplicates as success, and retains
rejected sessions for review rather than deleting recorded play.

### Current automated evidence

- `flutter analyze`: clean on host and contract.
- Tests: contract 22, route_quest 16, marble_maze 17, host 56 — **111 passing**
  (host was 21; 35 new tests cover durability, identity isolation, outbox
  replay/dedup and the session pipeline).
- `flutter build apk --debug`: **succeeds**. `aapt2` confirms the gyroscope
  stays `not-required`, so gyroscope-less phones still install and fall back to
  touch.
- `flutter_secure_storage` pinned to `^9.2.4`: 11.x needs compileSdk 37 and this
  machine's only API-37 platform reports a malformed `ApiLevel=37.0`.

### Still NOT TESTED — do not treat as working

**No Android device or emulator is connected** (`adb devices` empty). Every
Android runtime behaviour is unverified: notifications (delivery, permission
denial, reboot, time zone, duplicates), the biometric/PIN caregiver gate, and
Marble Maze tilt feel. **Firebase has never been validated against a real
project** — no project, provider or HTTPS backend URL has been supplied, so
real sign-in cannot run. The outbox has never contacted the live backend; its
tests use a mocked client shaped to the contract.

### Unfinished

Caregiver dashboard accept/modify/reject UI, server patient creation/selection,
personalization upload, Know Me → `GameItem` wiring, notification tap routing,
a patient reminder view, live-reactive text/motion preferences, and the
patient/caregiver visual pass. Doctor D1-D8 platform remains unanswered.
Session `config_version`/`content_version` are still hardcoded '1'.

## 2026-09-08 Claude — five games registered, doctor screens, design applied

### `code/` now holds eight packages

```
code/packages/tesseract_game_contract/   shared contract (+ optional scaffold)
code/games/route_quest/                  G2, Pranav
code/games/marble_maze/                  G3, Pranav
code/games/word_search/                  G7, newly written
code/games/routine_recall/               G8, ported from Ruthika's JS
code/games/picture_sorting/              extra activity, ported from Ruthika's JS
code/harness/                            dev tool
code/host/                               the app
```

**Ruthika's repository contains HTML/CSS/JS, not Flutter, and contains no Word
Search.** Her two games were ported by rewriting the mechanics in Dart against
`TesseractGame`; Word Search was written from scratch. Authorship, every
deliberate change to her mechanics, and the open questions for her are in
`docs/handoffs/RUTHIKA_GAME_INTEGRATION.md`. **Four of the nine catalogue games
are still not implemented** (Aryan's G1, G4, G5, G6, G9 — five, of which none
exist yet). Nothing here should be read as the catalogue being complete.

### Contract change — additive only

`TesseractGameScaffold` was added to `tesseract_game_contract`: the permanent
Help/Break controls and the pause overlay. **Optional.** Route Quest and
Marble Maze draw their own and were not modified. No event name, payload
shape or type was changed by any of this work.

### New event types with no calculator yet

`step_presented`, `attempt_resolved`, `word_found`, `selection_rejected`,
`all_words_found`, `content_unavailable`, `item_sorted`, `sorting_completed`.

The backend accepts unknown types and falls back to `generic_v1`, so these
sessions **upload and store correctly but produce no game-specific metric**
until Pranav writes calculators. `attempt` is carried deliberately so
first-attempt accuracy can be computed server-side without a game asserting an
accuracy figure of its own.

### Content boundary

`code/host/lib/src/content/know_me_content.dart` maps caregiver content to
each game: places for Route Quest, the caregiver's **familiar words** for Word
Search, the caregiver's **reminders in time order** for Daily Routine, and a
neutral built-in set for Picture Sorting. Ids are positional and opaque
(`word_2`, `step_3`), so personal text never enters a payload — asserted by a
test in each game package.

### Doctor D1-D8

Built as **mobile screens** (the platform decision the user made on
2026-09-08: doctor sign-in in this app, no web portal). Sign-in offers
Caregiver or Doctor; the role only chooses a screen and grants nothing,
because the backend scopes every read by assignment. The doctor view computes
nothing itself and shows "not measured" wherever the backend reports a metric
unavailable. No doctor action approves an activity — caregiver approval
remains the only path.

### Current automated evidence

- `flutter analyze`: clean on host, contract and all five games.
- Tests: contract 22, route_quest 16, marble_maze 17, word_search 24,
  routine_recall 11, picture_sorting 9, host 76 — **175 passing**.
- `flutter build apk --debug` succeeds.
- Goldens regenerated; new screenshots for all three new games and the role
  sign-in are in `code/host/test/goldens/`.

### Still NOT TESTED

**No Android device or emulator is connected.** Notifications, reboot and
time-zone behaviour, the biometric caregiver gate, Marble Maze tilt feel, and
real emoji rendering are all unverified. **Firebase has never been validated
against a real project**, so neither caregiver nor doctor sign-in has run end
to end, and the doctor screens have never been rendered against live data.

## 2026-09-08 Claude — localization (en, as, bn, mni, kha, lus)

Approved list confirmed by the user: English, Assamese, Bengali, Meitei,
Khasi, Mizo. **Covers 4 of 8 NE states**; Nagaland, Tripura, Arunachal Pradesh
and Sikkim have no language and this is stated in the app and asserted by a
test.

`flutter_localizations` + `gen_l10n`; ARB files in `code/host/lib/l10n/`.
`NotoSansBengali` and `NotoSansMeeteiMayek` bundled under SIL OFL and wired as
theme `fontFamilyFallback`.

Measured coverage: en 100%, as 73%, bn 73%, mni/kha/lus 10%. **Every
non-English language is a machine draft awaiting fluent-speaker review**,
labelled as such in the selector and by a persistent banner, with English
fallback disclosed. A test recomputes coverage from the ARB files so the
published figures cannot drift.

Interface language and patient language are separate settings. Game
Help/Break and per-game instructions resolve in the **patient's** language
through the existing `GameConfig`/`GameStrings` boundary — games gained no new
dependency. Language is selectable before sign-in, changeable in Settings,
applies without restart or losing form entry, and persists per caregiver.

Settings → About Tesseract shows the activity mark (no approved logo exists),
the description, "Built and developed by the Tesseract Team.", real
version/build from package metadata, and the coverage table.

Host tests 109 passing; 208 project-wide. Debug APK builds with fonts and
localizations.

**NOT TESTED:** no Android device. Script rendering, glyph coverage, wrapping,
TalkBack in non-Latin scripts and localized notifications are unverified on a
phone. Reminder notification bodies are still untranslated literals in
`ReminderService`. **No voice/audio support exists in any language.**


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


## 2026-09-08 — speech implemented, live Firebase auth, as/bn translation complete

### Implemented this pass

Optional spoken output and optional tap-to-speak input, entirely in the host
layer (`code/host/lib/src/speech/`). No game gained a network, database, auth or
speech dependency. Spoken: game instructions, host Help text, reminder content,
in the patient's selected language. Not spoken: the in-game pause overlay, which
is drawn inside the game packages — speaking it would breach the contract
boundary, so it is deliberately excluded rather than quietly worked around.

Voice input is explicitly activated, shows a listening indicator, requests the
microphone at point of use, offers stop/cancel, handles denial, timeout,
missing recogniser, unsupported language and network loss, shows what it heard,
and **requires confirmation before anything is saved**. No always-on listening,
no automatic submission, no bypass of caregiver authentication. Recognised text
is never written to event payloads or logs.

Settings → "Speaking and listening" probes the engines actually installed on the
phone, per language, in both directions separately.

### Files changed

`code/host/lib/src/speech/` (new: `speech_capability.dart`,
`speech_engine.dart`, `platform_speech_engine.dart`,
`speech_output_service.dart`, `voice_input_service.dart`, `speak_button.dart`,
`voice_input_sheet.dart`, `speech_settings_section.dart`);
`main.dart` (lifecycle stop); `host_flow_state.dart` (injectable engines,
`setAudioEnabled`, language-change rebinding); `how_to_play_screen.dart`,
`patient_reminders_screen.dart`, `caregiver/reminders_screen.dart`,
`caregiver/settings_screen.dart`; `l10n/app_en.arb` (+31 keys, 2 marked
`x-untranslatable`), `app_as.arb` (+43), `app_bn.arb` (+39);
`src/l10n/language_catalogue.dart`; `android/.../AndroidManifest.xml`
(`RECORD_AUDIO`, TTS/recogniser package queries); `pubspec.yaml`
(`flutter_tts`, `speech_to_text`, `permission_handler`).

New docs: `docs/handoffs/NER_SPEECH_MATRIX.md`,
`docs/handoffs/PRANAV_BACKEND_GAPS.md`.

### Tests actually run

`flutter analyze` clean across host, contract, five games and harness.
`dart format` clean. `flutter test`: **255 passing** — host 156, contract 22,
Route Quest 16, Marble Maze 17, Word Search 24, Routine Recall 11, Picture
Sorting 9. Of those, 28 new speech behaviour tests, 4 speech UI/golden tests,
4 new localization tests.

`flutter build apk --debug` succeeds → `code/host/build/app/outputs/flutter-apk/
app-debug.apk` (183 MB debug). `aapt2 dump badging` confirms `RECORD_AUDIO`.

Goldens regenerated and visually inspected: `how_to_play_speech.png`,
`how_to_play_speech_unavailable.png`, `how_to_play_speech_bengali_2x.png`,
plus the three existing localization goldens.

### Translation coverage

| Language | Coverage | Review |
|---|---|---|
| English | 100% | source |
| Assamese | **100%** (was 90%) | **draft — not reviewed** |
| Bengali | **100%** (was 93%) | **draft — not reviewed** |
| Meitei | 8% (was 9%) | draft — not reviewed |
| Khasi | 8% (was 10%) | draft — not reviewed |
| Mizo | 8% (was 10%) | draft — not reviewed |

Measured over 167 translatable keys (169 English keys minus `appName` and
`builtBy`, which must stay exact English). The three low figures fell because
the English set grew, not because anything was removed; no low-confidence
wording was invented to raise them. 100% means every string is written and says
nothing about quality — a test enforces that full coverage still presents as a
draft.

### Speech coverage

Implementation status is "routed" for all six languages: the app asks the
engine, uses it only if the engine really offers that language, and otherwise
says speech is unavailable **in that language** while keeping text and touch
fully working. It never substitutes another language.

Actual availability is **NOT TESTED** for every language — no Android device was
connected (`adb devices` empty). On current Google documentation, only Bengali
is documented for either direction; Assamese, Meitei, Khasi and Mizo are not.
Full matrix, sources and the on-device procedure: `docs/handoffs/NER_SPEECH_MATRIX.md`.

No language is speech-verified. No fluent speaker has reviewed any language.

### Live API evidence

Firebase project `tesseract-3ac5a`: Email/Password enabled and a Web app
registered on 2026-09-08 with the user's explicit approval — **neither existed
before**, contrary to the earlier record. Sign-in, wrong-password rejection,
token refresh and invalid-refresh rejection were all verified live against the
exact endpoints `IdentityService` calls. Credentials are held outside the
repository; no service-account key was requested or stored.

Client → Firebase is proven. Client → Firebase → API is **not**: the backend
needs a service-account file the user must place, and the client requires an
`https://` API URL, so a local HTTP backend is refused by design.

### Device status

**NOT TESTED**, all of it: notification delivery/permission/reboot/time-zone/
duplicates, biometric gate, Marble Maze gyroscope feel, script rendering and
glyph coverage, large text on real hardware, TalkBack, smaller screens, and
every speech behaviour. No device model, Android version or build can be
recorded because no device was connected.

### Remaining blockers

1. No Android device.
2. No fluent-speaker review of any language.
3. Expected provider gap for four of five NER languages (report, not a bug).
4. Backend: no `PATCH /patients/{id}`; no calculator for the eight event types;
   service-account file and HTTPS URL needed for end-to-end auth.
5. Five of the nine required games absent (Reveal Match, Trace, Coloring, Spot
   Difference, Picture Recall) — no repositories available.


## 2026-09-08 — Expo Go React Native frontend added (Flutter preserved)

New app at `code/tesseract-expo`. Flutter `code/host` untouched and still the
reference build. Reason: the user has an iPhone, `code/host` has no iOS target,
and no Android device was available all session.

**Expo SDK 57** (App Store Expo Go 57.0.9). `expo-doctor` 21/21. Every package
is Expo Go-bundled or pure JS — no prebuild, no development client.

Implemented: design system, localisation generated from the Flutter ARBs, the
TS game contract, all five activities, the session outbox, Firebase identity,
and the caregiver → hand-over → play → return path plus settings and About.

Verified: **38 tests passing**, TypeScript strict clean, iOS bundle builds
(HTTP 200, 5.3 MB). Coverage unchanged from Flutter: en/as/bn 100%,
mni/kha/lus 8%, all non-English draft, none fluent-reviewed.

**NOT TESTED:** everything on the iPhone. Nothing has run on a device yet.

**Hard Expo Go limitation:** speech recognition cannot work — it needs a native
module Expo Go does not contain. Reading aloud (`expo-speech`) does work. The
tap-to-speak contract including confirmation-before-saving is implemented
against an interface so a real recogniser is a one-file swap.

**Not built yet** (stated on screen, not stubbed): Know Me, reminders,
recommendation decisions, doctor screens, biometric gate, bundled Noto fonts.

Game catalogue unchanged: four of nine required plus one extra. Reveal Match,
Trace, Coloring, Spot Difference and Picture Recall still missing.

Detail: `docs/handoffs/EXPO_GO_STATUS.md`.


## 2026-09-08 — Apnapan branding and remaining Expo features

Product renamed **Apnapan** (अपनापन); attribution unchanged. Flutter untouched.

Assets: approved logo verbatim at `assets/branding/apnapan-logo.png`; icon
derivatives composed from the symbol band only (wordmarks excluded by
construction) with explicit safe margins.

In-app opening screen (~1s) with logo, localised tagline and attribution.
Reopen logic distinguishes a genuine background from `inactive` (biometrics,
permission sheets, notification shade) and requires 90s away; shown as an
overlay so route/auth/game state and timing survive.

Expo Go: top-level `splash` is legacy in SDK 57 (caught by expo-doctor) — now
uses the `expo-splash-screen` plugin. Since SDK 52 Expo Go shows its own icon
rather than the splash, so the Apnapan home-screen icon and native launch
require a separately installed build. Expo Go remains the container.

Completed: Know Me (feeding real content into games), reminders with local
notifications, recommendations with accept/modify/reject, doctor screens,
biometric caregiver gate, bundled Noto fonts, clean first-run language picker.

Verified: TypeScript clean, **50 tests**, expo-doctor 21/21, iOS bundle builds,
opening screen + sign-in captured on **iOS Simulator** (iPhone 17 Pro, iOS 26.5,
Expo Go 57.0.9). **No iPhone hardware verification has been performed.**
