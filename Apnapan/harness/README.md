# Harness

Runnable demo app for Route Quest and Marble Maze — no backend, no storage.

1. Setup screen — pick game, level (1/2/3), input mode (touch/tilt), text
   scale (1.0/2.0), then Play.
2. Play screen — the chosen game renders inside a fixed 360x740 dp
   phone-shaped frame, centred and dimmed around, next to an event log panel
   that prints every `GameEvent` as JSON as it arrives (also to the console).
   The harness owns the how-to-play and finished screens around the game;
   the game itself only ever draws its own pause overlay.

Supplies fake `GameItem`s and a fully populated fake `GameStrings` — no real
caregiver content, no personalisation.

This is a developer tool for exercising one game in isolation; it is not the
product shell. See `Apnapan/host/` for the real app (Home through Rest) that
P1-P9 grows into.

## Run

```
cd Apnapan/harness
flutter pub get
flutter run
```

Android and web (for local preview only — same caveat as the host: final QA
is always on the phone). No ios/macos/windows/linux.
