# Tesseract host

The real app shell — the full frontend skeleton from the decided P1-P9 /
C1-C7 screen model, that every game plugs into. Not the developer harness
(`Apnapan/harness/`), which stays a separate, simpler demo tool.

**This is a structural skeleton, not final visual design.** Every screen is
real and navigable, but layout/styling is deliberately plain — the frontend
team owns the actual visual redesign next. Nothing here should be read as
"this is what it will look like."

**Doctor portal (D1-D8) is out of scope here on purpose.** The product docs
mark its platform (mobile vs. a separate web app) as an open decision — see
`docs/PS003_GAME_ASSIGNMENTS_AND_UI.md`. Building it into this mobile skeleton
would be presuming that decision.

## Platforms

Android and web only — no ios/macos/windows/linux.

**Web is a development preview, not a product target.** It exists so
Pranav can see the app in Chrome without an emulator. Web rendering differs
from Android in real, visible ways (text metrics, scrolling, input), so
**final QA is always on the phone.** A banner says this on the Home screen
whenever the app is running as a web build.

## Adding a game

Open [`lib/games/game_registry.dart`](lib/games/game_registry.dart) and
append one `GameRegistration` entry. Nothing else in the host changes — see
the doc comment at the top of that file. Only Route Quest and Marble Maze
are registered today; the other seven games plug in here once their owners
finish them.

## Flow

The app now starts at caregiver sign-in, matching the product's real
structure — a caregiver sets things up and hands the device over; the
patient never sees caregiver screens directly.

```
C1 Sign in -> C4 Caregiver home -> C5 Hand over -> P1 Home
                 |         ^                          |
                 |         |  (protected return gate)  v
        C2/C3/C6/C7   <----+------------------- P2/P7 -> P3 -> P4 -> P6 -> P1/P8/P9
```

- **Caregiver (`lib/src/caregiver/`)**: C1 Sign In, C2 Patient Basics, C3
  Know Me, C4 Caregiver Home, C5 Hand Over, C6 Reminders, C7 Settings/Sync.
  All placeholders backed by in-memory `HostFlowState` — no real auth, no
  persistence, no notification scheduling. C3's Know Me content is not yet
  wired into any game's `GameItem`s.
- **Patient (`lib/src/`)**: P1 Home, P2 Choose Activity, P3 How to Play, P4
  Play, P6 Finished, P7 Personalized Activity, P8 Rest, P9 Simple Progress.
  P5 (Taking a Break) is not a separate screen — each game draws its own
  pause overlay, per the contract.
- Home's Start button goes to **P7** when a caregiver picked an activity at
  Hand Over (C5), otherwise to **P2** — matching "Start to P2 or approved P7"
  in the product spec.
- `CaregiverReturnGate` (a small shield icon on Home and Rest) is the
  "protected return flow" back into caregiver mode — today just a
  confirmation dialog, not real authentication. Replace before this ships.
- Every finished session appends to `HostFlowState.activityHistory`
  regardless of how it ended, which is what both **P9 Simple Progress** and
  **C4 Caregiver Home**'s "last activity" read from.
- Companion ("playing together") mode is deliberately not offered at Hand
  Over: it's proposed in `PS003_ADDITIONS.md`, which is not yet approved.

Level selection and "is this a tutorial run" remain simple placeholders —
see the doc comments on `HowToPlayScreen` and `SessionController` for what a
real implementation needs to replace.

## SessionController

Builds each session's `GameConfig`, wraps every `GameEvent` with the
host-side envelope fields a game never sees (`event_id`, `session_id`,
`occurred_at`, `game_id`, `game_version`, `schema_version`), and assembles
the full session snapshot as JSON on finish. No backend, no database, no
http — it currently only prints the snapshot and keeps it in memory; the
outbox that uploads it is wired in separately.

## Running

Android:

```
flutter run
```

Web preview:

```
flutter run -d chrome
```

or headlessly (useful in a sandboxed/CI shell):

```
flutter run -d web-server --web-port=8765
```

## Tests

```
flutter test
```

- `test/golden_test.dart` renders every host screen and both games at
  360x740 dp and writes PNGs to `test/goldens/` — one golden per screen,
  each game at level 1 and level 3, each game's pause overlay, and every
  host screen at textScale 2.0. `test/test_helpers.dart` loads real Roboto
  and Material Icons font files (copied from the Flutter SDK into
  `test/fonts/` — no added dependency) so the goldens show real glyphs, not
  boxes.
- The new caregiver screens (C1-C7) and P7/P9 deliberately have no golden
  tests yet — they're a structural skeleton the frontend team will redesign
  soon, so pixel-exact regression tests would just need regenerating again
  almost immediately. Their correctness was verified by live click-through
  (Sign In through Hand Over through Play through Finished through the
  caregiver return gate) instead. Add goldens once the visual design settles.
- To regenerate goldens after an intentional visual change:
  `flutter test --update-goldens`.
- `dart run tool/generate_test_report.dart` runs the suite and writes
  `test_report.html` — a pass/fail table plus every golden PNG shown inline
  in a phone-shaped frame. Plain HTML/CSS, no build step: open it with a
  double-click.
