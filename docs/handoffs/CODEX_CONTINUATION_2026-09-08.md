# Codex continuation — paused 2026-09-08

Paused at the user's request. Work is **committed and clean**, not pushed.

## Workspace

```
/Users/pranav07vudiga/.codex/worktrees/4fa8/pranav07vudiga/tesseract
branch: codex/patient-caregiver-integration
HEAD:   b160220
```

Nested isolated clone. The parent directory is an unrelated UserProfileApp
repo — do not touch it. The original checkout at
`Desktop/Projects/Hackathon/SIH` does **not** contain any of this. Do not push.

Commits this session, on top of backend `00f5cc9`:

| Commit | What |
|---|---|
| `fcf15c4` | Identity-partitioned durable storage, outbox hardening, lifecycle fix verified |
| `c82917f` | Caregiver decision loop (accept/modify/reject), reusable design system |
| `1fc5809` | Know Me content into games, patient reminder view, patient screen pass |
| `10a4afe` | Word Search + Routine Recall + Picture Sorting, doctor D1-D8, design pass |
| `b160220` | Localization (6 languages) and About Tesseract |

## Current verified state

- `flutter analyze`: clean on host, contract, and all five game packages.
- Tests **208 passing**: contract 22, route_quest 16, marble_maze 17,
  word_search 24, routine_recall 11, picture_sorting 9, host 109.
- `flutter build apk --debug` succeeds →
  `code/host/build/app/outputs/flutter-apk/app-debug.apk` (191 MB debug).
- Goldens regenerated and visually inspected, in `code/host/test/goldens/`.

## What works

Five games registered (Route Quest, Marble Maze, Word Search, Daily Routine
Recall, Picture Sorting). Caregiver dashboard with real history and working
accept / choose-level / keep-as-is against the recommendations endpoint.
Doctor D1-D8 as mobile screens behind role sign-in. Durable SQLite partitioned
by caregiver identity, session outbox with retry/dedup/restart recovery.
Patient path on the design system. Six languages with measured coverage.

## Blockers — cannot be closed without these

1. **No Android device** (`adb devices` empty). Everything on-device is
   NOT TESTED: notifications (delivery, permission denial, reboot, time zone,
   duplicates), biometric caregiver gate, Marble Maze tilt feel, script
   rendering and glyph coverage for Bengali/Assamese/Meetei Mayek, emoji in
   Routine Recall and Picture Sorting, real text wrapping. **Needs a phone.**
2. **Firebase unconfigured.** No project, provider or HTTPS backend URL was
   supplied. `IdentityService.configured` is false, so **no sign-in path —
   caregiver or doctor — has ever run**, and the doctor screens have never
   rendered against live data. Needs the public Web API key + HTTPS backend
   URL as `--dart-define`. Never request or embed a service-account key.
3. **Backend calculators missing** (Pranav). Eight new event types have no
   calculator, so those sessions upload and store but produce no
   game-specific metric: `step_presented`, `attempt_resolved`, `word_found`,
   `selection_rejected`, `all_words_found`, `content_unavailable`,
   `item_sorted`, `sorting_completed`.
4. **No fluent-speaker review** of any translation. All five non-English
   languages are machine drafts.
5. **Patient-basics update endpoint absent** from the backend. Local edits are
   not synced and must not be described as synced.

## Highest-value remaining work

1. **Translation coverage.** as/bn are 73%, mni/kha/lus are **10%** — only
   strings with genuine confidence were drafted. Raise coverage, then get a
   fluent speaker per language and flip `ReviewStatus.draft` → `native` in
   `code/host/lib/src/l10n/language_catalogue.dart`. A test recomputes
   coverage from the ARB files, so update the ARBs and the number together.
2. **Localize reminder notification text.** `ReminderService.schedule` still
   builds `'A gentle reminder'` and the body from untranslated literals. It
   must use the patient's language.
3. **Four NE states have no language**: Nagaland, Tripura, Arunachal Pradesh,
   Sikkim. Listed in `LanguageCatalogue.uncoveredRegions`. Adding any needs a
   scope decision, not a silent addition.
4. **Aryan's five games** (G1 Reveal Match, G4 Trace, G5 Coloring, G6 Spot
   Difference, G9 Picture Recall) do not exist. The catalogue is 5 of 9 plus
   one extra. Do not describe it as complete.
5. **Ruthika must review** `docs/handoffs/RUTHIKA_GAME_INTEGRATION.md` — her
   score/stars were removed, answers now compare opaque ids not names, and the
   medicine step was dropped from the default routine.
6. Server patient creation/selection UI, personalization upload, config/content
   versions still hardcoded `'1'`, save-error retry states.

## Rules that must not be broken

- Games take no network, database or auth dependency. Content reaches them
  only through `GameConfig`/`GameItem`.
- Only opaque ids in event payloads — never names, words or routine text.
  Each game package has a test asserting this; keep it passing.
- Never fall back from a failed real sign-in to synthetic access.
  `TESSERACT_ALLOW_PREVIEW` is the only fixture path and is visibly labelled.
- Never mark an unreviewed language as reviewed, or an untranslated screen as
  supported. Translated text is **not** voice support.
- Do not fabricate `actual_input_mode` or unavailable efficiency metrics.
- Caregiver approval is the only path that changes a patient's activity.
- Do not modify the submitted PPT, invent team-member names, or add
  appointments/payments/vitals/disease scores.
