# Apnapan — demo runbook

Written 2026-09-08. Prototype demonstration, not a production release.

## Start it

```bash
cd /Users/pranav07vudiga/.codex/worktrees/4fa8/pranav07vudiga/tesseract/Apnapan/tesseract-expo
npx expo start --lan --port 8081
```

A dev server is **already running** from that directory as this was written.

## Connect a phone

Phone and laptop must be on the **same Wi-Fi**.

1. Install **Expo Go** from the App Store / Play Store.
2. Point the phone at the QR code in the terminal, **or** open this directly:

```
exp://192.168.31.215:8081
```

Android users can paste that into Expo Go's "Enter URL manually".

If the LAN address changes (different Wi-Fi), re-read it with
`ipconfig getifaddr en0` and substitute it. If LAN is blocked by the network
(common on guest/college Wi-Fi), fall back to:

```bash
npx expo start --tunnel
```

Tunnel is slower to start and slower to load; only use it if LAN fails.

## The 3-minute sequence

1. **Opening screen** — the Apnapan logo holds for about a second. Point out
   that the branding is in-app: in Expo Go the home-screen icon is Expo Go's,
   not ours, because that belongs to an installed binary.
2. **Language** — tap the language control on sign-in. Show the seven
   languages, each in its own script. Point out that every non-English one is
   labelled a **draft awaiting native review**, with its measured coverage.
   Switch to हिन्दी and show the interface change without a restart. Switch back.
3. **Enter the demonstration** — use the explicitly labelled preview entry on
   the sign-in screen. It has its own storage scope and its own outbox, so it
   cannot mix with a real caregiver's data. Say that out loud; do not present
   it as a real sign-in.
4. **Caregiver home** — show the preview banner, the patient, and the setup
   entries (basics, Know Me, reminders, settings).
5. **Hand over** — go through hand-over into patient mode.
6. **Play one activity** — Picture Pairs, Route Quest or Word Search read best
   on a phone. Picture Pairs is the newly ported one.
   Show **Help** and **Break**, then finish. Make the point that a wrong action
   shows the patient nothing: no score, no failure state, no red.
7. **Return** — come back through the protected caregiver gate. Show that
   patient mode has no ordinary route back.
8. **Settings → About Apnapan** — attribution and the per-language coverage
   table.

## What can truthfully be claimed

- Six activities are registered and playable: Route Quest, Marble Maze, Word
  Search, Daily Routine Recall, Picture Pairs (Aryan's Reveal Match, ported),
  and Picture Sorting as an extra.
- **Five of the nine required games ship.** Trace, Coloring, Spot Difference
  and Picture Recall are **not implemented** — Aryan's Flutter source is staged
  for porting but those four are not ported. Do not imply otherwise; the
  registry states this in its header and `MISSING_REQUIRED_GAME_IDS` counts it
  in code.
- Gemini-assisted analysis is wired through the backend and was verified live
  against synthetic data. The phone never holds the key and never calls Google.
  Every failure falls back to the app's own wording, and the screen names which
  one you are reading.
- Seven languages ship. Only English is reviewed; the rest are drafts.
- Text scaling is capped per tier so large system font sizes do not burst
  layouts, while still scaling for low vision.

## What must NOT be claimed

- Any on-device behaviour. Nothing was run on a phone or simulator this
  session. Notifications, speech, motion/tilt and biometric gate are
  **NOT TESTED**.
- Speech in Hindi or any NE language. Text being translated is not speech
  support, and no provider was exercised.
- Real authentication. Preview mode is synthetic and labelled.

## If something fails

| Symptom | Fix |
|---|---|
| Expo Go shows a red error | Shake the phone → Reload. If it persists, restart the server and reconnect. |
| "Something went wrong" / cannot connect | Same Wi-Fi? Then `npx expo start --tunnel`. |
| Port 8081 already in use | `lsof -ti:8081 \| xargs kill`, then restart. A stale server from the pre-rename `code/` path caused exactly this today. |
| Bundle is slow the first time | Expected. The first bundle is ~3s server-side plus download; later reloads are fast. |
| Phone shows an old version | Shake → Reload, or fully close and reopen Expo Go. |

Worst case, the demo runs on the laptop: press `w` in the Expo terminal for
web. Web is a fallback only — motion, notifications and secure storage behave
differently there, so do not use it to claim device behaviour.
