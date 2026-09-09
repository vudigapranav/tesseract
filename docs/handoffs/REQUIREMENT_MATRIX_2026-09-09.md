# Requirement → files → checks → limitation

Written 2026-09-09, for the patient-experience and nine-game pass.
Branch `codex/patient-caregiver-integration`. Nothing committed or pushed.

**How to read the Checks column.** "Automated" means a test in the suite.
"Rendered" means the screen was opened in a browser at 375×812 and looked at.
A test passing is not evidence a screen works, and a bundle that builds is not
evidence of either. Nothing in this pass was run on a physical phone or an
emulator, so every row's device behaviour is **NOT TESTED**.

---

## 1 — Make the app feel primarily for the patient

| Requirement | Files | Checks | Limitation |
|---|---|---|---|
| Familiar image, short greeting, one clear Start | `src/screens/PatientScreens.tsx` (`PatientHomeScreen`) | Rendered | The home image is a fixed catalogue scene, not caregiver-chosen |
| Picture-led activity cards, a manageable selection | `src/screens/PatientScreens.tsx` (`ChooseActivityScreen`, `ActivityCard`), `src/content/ActivityPreview.tsx` | Rendered — 4 per page, "Show me more" cycles 3 pages | Previews are illustrations of each activity, not live screenshots |
| One short instruction + repeatable visual demonstration | `HowToPlayScreen`; `howToPlay*` keys in `Apnapan/host/lib/l10n/app_*.arb` | Rendered | The "demonstration" is a static illustration that re-mounts, not an animation |
| Generous play area, reachable Help/Break/Finish | `src/games/GameScaffold.tsx` (unchanged) | Automated — every registered game pauses, resumes and exits | — |
| Gentle completion, Rest, recent activity | `PatientScreens.tsx` (pre-existing) | Not re-examined this pass | Recent-activity view was not improved |
| Caregiver/doctor stay behind protected access | `src/Navigation.tsx`, `PatientGateScreen` (unchanged) | Rendered — patient mode has no ordinary route back | — |
| Remove jargon, oversized notices, paragraphs | Instruction strings shortened to one sentence in en/hi/as/bn | Rendered | Caregiver screens still carry longer explanatory text (correct — that is where it belongs) |
| No stage labels, scores or failure summaries in patient mode | All ten games; `PictureRecallGame` shows a neutral acknowledgement | Automated + rendered | — |

## 2 — Reduce visual bulk

| Requirement | Files | Checks | Limitation |
|---|---|---|---|
| Headings ~26–28, sections ~20–22, body ~16, patient instruction ~18 | `src/design/tokens.ts` (`type`), `src/design/components.tsx` | Automated (`fontScaling.test.tsx` holds the new floors) + rendered | Values verified at 375×812 only |
| Central density change | `components.tsx` — card padding 20→16, section padding 20→14, pill label 18→17 | Rendered | — |
| Keep targets, contrast, OS scaling, larger-text option | `spacing.patientTarget` 64 and `minTarget` 48 unchanged; `fontScaleCaps` unchanged | Automated — a test asserts type shrank and targets did not | Contrast not re-measured with a tool this pass |
| Compact secondary controls | `PillButton` gains `compact`; `SpeakButton` uses it | Rendered — fixed four stacked full-width pills | — |

## 3 — All nine required games

**Nine of nine are registered and playable**, plus Picture Sorting as an extra
(ten total). `MISSING_REQUIRED_GAME_IDS` is empty and a test asserts it.

| Game | Owner | Files | Checks | Limitation |
|---|---|---|---|---|
| G1 Reveal Match | Aryan | `src/games/revealMatch/*` | Automated (27 model + host) | Card faces now use catalogue artwork; a caregiver's own Know Me picture is still a word, since there is no drawing for it |
| G2 Route Quest | Ruthika | `src/games/routeQuest/*` | Automated | **Not improved this pass** — still an abstract node layout, not a scene with landmarks |
| G3 Marble Maze | Ruthika | `src/games/marbleMaze/*` | Automated | **Not improved this pass** — collision, corridors and dead ends were not re-inspected or reworked |
| G4 Trace | Aryan | `src/games/trace/*` | Automated (model + host) | Three shapes; corridor narrows per level |
| G5 Coloring | Aryan | `src/games/coloring/*` | Automated (model + host) | Swipe-to-reveal via an SVG mask; progress is not persisted across an app restart |
| G6 Spot Difference | Aryan | `src/games/spotDifference/*` | Automated + rendered | Two authored pairs only (one and two differences) |
| G7 Word Search | Ruthika | `src/games/wordSearch/*` | Automated | **Not improved this pass** — presentation and selection feedback unchanged |
| G8 Routine Recall | Ruthika | `src/games/routineRecall/*` | Automated | **Not improved this pass** — still text-led, not image-led |
| G9 Picture Recall | Aryan | `src/games/pictureRecall/*` | Automated + rendered end-to-end | Two authored scenes with two questions each |

Shared, for every game: real per-level settings (a test asserts level 1 and
level max differ), caregiver-set difficulty with no automatic escalation, no
countdown or score, exactly-once completion, and the shared config/event/finish
contract with no game-owned network, storage or navigation.

**Content and provenance.** `src/content/catalog_v1.json` is Aryan's original
vector artwork, copied from `tmp/incoming/aryan/extracted/assets/demo/`. Ten
pictures drawn as coloured primitives — no licence to honour, no remote URL, no
photograph of a real person. A test asserts no `http(s)://` appears anywhere in
the catalogue and that every referenced picture exists.

## 4 — Kamala's demo data

| Requirement | Files | Checks | Limitation |
|---|---|---|---|
| One consistent synthetic patient and caregiver | `src/data/demoSeed.ts` — Kamala (72) and Bidisha, the project's established sample family | Rendered — preview opens with Kamala selected | Caregiver name is recorded but not yet shown on screen |
| Coherent familiar-content pack | 20 Know Me entries: courtyard, tulsi, kitchen, morning tea, rice, verandah | Rendered | English only; the pack is not translated |
| Isolated and idempotent | Seeds only when `store.scope === 'preview'`; a version marker stops re-seeding; existing entries always win | Code-level guard | No automated test for the idempotence guard this pass |
| Seeded history distinct from real play | **No sessions are seeded at all** | — | A demo therefore starts with an empty history, which is the honest state |
| Empty analysis stays empty | Nothing seeds observations or analysis | — | — |

## 5 — Supporting non-AI flows

**Audited, not completed.** The existing caregiver screens (patient basics,
Know Me, reminders, settings, About, recommendations) and doctor screens
(assigned list, detail, notes, reports) were left as they were, apart from the
analysis screen and the typography change that reaches every screen.

| Item | Status |
|---|---|
| Caregiver patient create/select/edit, Know Me, reminders, settings, About | Pre-existing; **not re-audited against P1–P9 / C1–C7 this pass** |
| Doctor list, detail, notes, reports, server-side assignment enforcement | Pre-existing and tested server-side (`services/api/tests/test_doctor.py`) |
| Session history with game/date/status/support filters | **Not implemented** |
| Descriptive observations and comparable trends in the doctor UI | Partial — the analysis screen shows per-game counts; no trend view |

## 6 — The seven PDF additions

**None of A1–A7 were implemented in this pass.** They are listed here so they
are not quietly dropped:

| Addition | Status |
|---|---|
| A1 Conversation prompts | Not started |
| A2 Played together | Not started |
| A3 Content curation counts | Not started |
| A4 Accessibility fitting | Not started |
| A5 Reminder bridge | Not started |
| A6 Daypart preferences | Not started |
| A7 Appointment one-pager | Not started |

The work went to the nine games and the patient experience, which were ranked
above the additions in the request. No roadmap entry has been marked complete
for any of them.

## 7 — Languages and audio

| Requirement | Files | Checks | Limitation |
|---|---|---|---|
| Seven languages preserved | `Apnapan/host/lib/l10n/app_*.arb` → `src/l10n/*.ts` via `tools/sync-l10n.mjs` | Automated (`src/l10n`) | — |
| New controls and instructions localised | 30+ new keys in en/hi/as/bn | Automated | **hi/as/bn are drafts written by this assistant, not native-reviewed** |
| Coverage stays measured, not claimed | `src/l10n/languages.ts` updated to the measured figures | Automated | Meitei fell 8%→6%, Khasi and Mizo 8%→7% as English grew — the honest direction |
| Reduce reading via visuals | `ActivityPreview`, picture-led choices and cards | Rendered | — |
| No new speech provider | Untouched | — | Speech in Hindi and NE languages remains **NOT TESTED** |

## 8 — Verification actually performed

Automated, on this machine, this pass:

- Expo: **230 tests, 12 suites, all passing** (`npx jest`), including 122 game
  tests of which 58 are the new Aryan-game model and host-integration tests.
- Expo: `npx tsc --noEmit` clean.
- Backend: **159 tests passing** (`.venv/bin/python -m pytest`), `ruff` clean.
- Localisation: `node tools/sync-l10n.mjs` regenerates cleanly; coverage
  figures re-measured and written back.

Rendered and looked at, in a browser at 375×812 (Expo web):

- Sign-in, language control, synthetic preview entry
- Caregiver home with Kamala seeded and selected
- Patient home, activity chooser (all three pages), instruction screen
- Picture Recall played end to end; Spot Difference started

Two real defects were found by looking rather than by tests, and fixed:

1. The second answer choice in Picture Recall was laid out below the first and
   clipped out of the board — the patient saw one answer where there were two.
   Cause: a `Settle` animation wrapper is itself a flex container, so `flex: 1`
   on the card applied inside the wrapper instead of to it.
2. `expo-secure-store` has no web implementation, so the first write on web
   threw and the app could not save anything at all — which also meant the
   documented web fallback never worked. Now routed through
   `src/data/secureKeyStore.ts`, which uses the Keychain on device and
   `localStorage` on web, and says which one via `isSecure`.

**Not done:** no physical phone, no emulator, no Android bundle check, no
larger-text sweep, no Indic-script layout pass, no offline/queued-session
replay run, no reminder-permission test.
