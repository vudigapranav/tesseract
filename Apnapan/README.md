# Tesseract — mobile (code/)

This is the Flutter mobile side of Tesseract. `services/` (backend) is owned
separately; nothing here talks to it, directly or indirectly — see
[Contract](#contract) below.

## Layout

```
code/
  packages/tesseract_game_contract/   # shared contract — no deps beyond flutter
  games/route_quest/                  # G2 — Memory / Route Quest
  games/marble_maze/                  # G3 — Marble Maze
  harness/                            # small dev tool: pick a game/level/mode, play it
  host/                               # the real app shell — Home through Rest, P1-P9
```

`harness/` and `host/` are both real Flutter apps (Android + web) that
depend on the games; `harness/` is a developer tool for exercising a game in
isolation, `host/` is what P1-P9 actually grows into. Games and the contract
package are pure Dart packages with no platform folders of their own — they
don't need to run standalone.

Every package under `games/` depends only on `tesseract_game_contract`. No
game may add a network, database or auth dependency.

## Status

- `packages/tesseract_game_contract` — built, signed off.
- `harness/` — built and runnable (Android + web platform folders).
- `games/route_quest/` — built: node-graph model, BFS shortest path computed
  at level load, its own pause overlay, widget tests.
- `games/marble_maze/` — built: grid-collision model, fixed-timestep touch
  drag, its own pause overlay, widget tests.
- `host/` — built: the full decided frontend skeleton, patient (P1-P9) and
  caregiver (C1-C7) — sign-in through Hand Over through Play through the
  protected caregiver-return gate, all connected. Structural skeleton, not
  final visual design; the doctor portal (D1-D8) is deliberately out of
  scope pending its own platform decision. `SessionController` wraps events
  with host-side fields and prints the session snapshot (no backend yet);
  golden screenshot tests for the games/patient-play screens + an HTML test
  report; the new caregiver/P7/P9 screens were verified by live
  click-through instead (see `host/README.md`).
- All five packages: `flutter analyze` clean, `flutter test` passing.

## Contract

A game is a self-contained `StatefulWidget` (`TesseractGame`). It never
touches network, database, auth, storage, navigation or shared preferences.
It receives a frozen `GameConfig` (content, strings, level + actual
difficulty settings, input mode, text scale, locale, schema/config/content/
metric versions) and reports back through two callbacks: `onEvent` for every
`GameEvent` as it happens, and `onFinish` once, with a `GameResult`.

Both games share one `TesseractEventRecorder` implementation
(`packages/tesseract_game_contract/lib/src/event_recorder.dart`) so the event
rules can't drift between them:

- `seq` starts at 1, increments by 1, and is never reused or skipped.
- `elapsedMs` is a monotonic session clock that excludes paused and
  backgrounded time.
- Using Help always emits `hint_requested` and marks the session assisted.
- A session finalizes exactly once — `sessionStarted()` out of order,
  `sessionFinished()` called twice, or any event emitted after
  `sessionFinished()`, throws `StateError`/`ArgumentError` in every build
  mode, not just debug.

Backgrounding is handled once, not per game: `TesseractGameStateMixin` (also
in the contract package) observes `AppLifecycleState` and calls the
recorder's `paused(reason: 'backgrounded')` / `resumed()` automatically,
without disturbing a pause the game's own Break control already started.

### Event envelope field ownership

A `GameEvent` as a game sees it carries only `type`, `seq`, `elapsedMs` and
`payload` — that's the whole contract-level object. The **host** wraps each
one with the fields only it knows, when persisting/uploading it:
`event_id` (fresh UUID per event), `session_id`, `patient_id`, `occurred_at`
(UTC, read at wrap time), `game_id`, `game_version` and `schema_version`
(the latter two copied from the `GameConfig` the host built). A game never
sees or sets any of those six.

See [packages/tesseract_game_contract](packages/tesseract_game_contract) for
the full type definitions.

## Running the harness

```
cd Apnapan/harness
flutter pub get
flutter run
```

Pick a game, level (1/2/3), input mode (touch/tilt) and text scale (1.0/2.0),
then Play. The chosen game renders inside a fixed 360x740 dp phone frame,
centred and dimmed around; every `GameEvent` prints as JSON to an on-screen
log panel and to the console as it arrives. The harness supplies fake
`GameItem`s and a fully populated fake `GameStrings` — no backend, no
storage. Android only; no web or desktop target.

## Event reference

Every game also emits the shared lifecycle events from
`TesseractEventRecorder`: `session_started`, `tutorial_started`,
`tutorial_completed`, `hint_requested`, `support_changed {setting}`,
`paused {reason?}`, `resumed`, `session_finished {status}`.

### Route Quest (G2)

| type | payload | when |
|---|---|---|
| `location_entered` | `{nodeId}` | the patient taps an adjacent location and moves to it |
| `destination_reached` | — | arriving at the destination node, outbound |
| `item_collected` | — | immediately after `destination_reached` |
| `return_completed` | — | arriving back at the home node, on the return leg |
| `wrong_interaction` | `{objectId}` | tapping a non-adjacent location (or the current one) — the move is ignored |

### Marble Maze (G3)

| type | payload | when |
|---|---|---|
| `collision` | `{wallId}` | drag would move the marble into a wall (or off the grid edge); movement along that axis simply stops — no sound, no penalty, no counter shown to the patient |
| `dead_end_entered` | `{cellId}` | the marble's centre enters a dead-end branch's tip cell, once per cell per session |
| `goal_reached` | — | the marble's centre enters the goal cell; the session finishes immediately after |
