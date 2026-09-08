# Ruthika's games — integration notes

Written 2026-09-08 for Ruthika, by Claude on Pranav's instruction.
**Nobody has been contacted about this.** These are notes prepared for her
review, not an agreed change.

## What was found

Source: `https://github.com/ruthikareddy678/GAMES`, commit
`a504486376011539489a5155425223d6f478ca79`. Cloned read-only for reference;
the repository was not modified and is not vendored into this project.

It contains two games, as **HTML/CSS/JavaScript** — not Flutter packages:

| Path | Game | Lines of JS |
|---|---|---|
| `game1/` | Picture Sorting | 1229 |
| `game2/` | Daily Routine Recall | 1746 |

Two things follow from that, and both need Ruthika's agreement:

1. **There is no Word Search in the repository.** Her assigned G7 is
   Personalized Word Search. It does not exist in this source.
2. **Picture Sorting is not one of the nine catalogue games.** Her assigned
   games are G7 Word Search and G8 Daily Routine Recall. Picture Sorting is
   not Picture Recall (G9, Aryan's).

A web game cannot be dropped into the host: every game must implement
`TesseractGame` from `tesseract_game_contract`, and games may not take a
network, database or auth dependency. Integration therefore meant **porting
the mechanics to Flutter**, not importing a package. The mechanics are hers;
the Dart is new.

## What was decided, and by whom

Pranav was asked and chose: port both of her games, and build Word Search as
well. All three are now registered and playable.

| Game | Package | Status |
|---|---|---|
| Daily Routine Recall (G8) | `Apnapan/games/routine_recall` | Ported from `game2` |
| Picture Sorting (extra) | `Apnapan/games/picture_sorting` | Ported from `game1` |
| Personalized Word Search (G7) | `Apnapan/games/word_search` | Written new |

Picture Sorting is registered as an **extra activity beyond the nine-game
catalogue**, at Pranav's explicit request. It has not been silently swapped in
for any of the nine.

## Changes made to Ruthika's mechanics, and why

These are deliberate and reviewable. Each one is also recorded in the doc
comment at the top of the ported game.

### Both ported games

- **No score, no high score, no stars.** `game1` counted a live score and
  persisted a high score to `localStorage`; `game2` showed a score-dependent
  star rating. Tesseract patient screens carry no score, ranking or streak —
  this is a product rule, not a preference. A wrong answer now simply invites
  another try.
- **Answers compare stable opaque ids, not names.** `game2` compared step
  *names*. That breaks when two steps share a label — her own default routine
  has "Eating lunch" and "Eating dinner" — and it would put personal text into
  telemetry. Only `GameItem.id` ever reaches a payload now, and there is a
  test in each package asserting the labels never appear.
- **Content comes from the host** through `GameConfig.items`, rather than
  being hardcoded in the game. This is what makes the activity personal.
- **A wrong answer can be retried**, and the attempt number is recorded, so
  first-attempt accuracy stays separable from eventual completion — which is
  what the S31 analytics acceptance asks for.

### Daily Routine Recall specifically

- **The default routine was not imported.** Her `DEFAULT_ROUTINE` includes a
  "Taking morning medicine" step. Presenting medication as part of everyone's
  routine would be showing medical content the caregiver never entered. The
  routine now comes from the **caregiver's own reminders**, in time order,
  falling back to a neutral day with no medicine step.
- **No speech synthesis.** The original used the browser speech API for
  "read the routine aloud" and answer feedback. Audio is a host-level setting
  and no audio is implemented yet, so the port is silent rather than
  pretending to speak. If read-aloud matters to her, it should be raised as a
  host feature, not re-added per game.
- Her ≥3-step minimum is kept, and a shorter routine shows a plain message
  instead of an empty board.

### Picture Sorting specifically

- **Her hand-drawn SVG artwork was not ported.** ~600 lines of inline SVG
  icons. The port uses emoji supplied by the host as a placeholder. Real
  illustrations are a design asset for Maharshitha and Ruthika to supply, and
  this is flagged as placeholder in the code.
- The original advanced after 900 ms without guarding further category taps
  (a double tap could skip an item). The port has no timed transition: the
  patient taps Continue when ready.

## Word Search (G7), newly written

Not a port — there was no source. Built to the same contract.

- Content is the caregiver's **familiar words** from Know Me, which makes it
  the most personal activity in the catalogue.
- Interaction is **tap the first letter, then tap the last letter**, not a
  drag. Dragging a precise path across small cells is hard with tremor; two
  taps are forgiving, cancellable and reachable by screen reader.
- Placement is deterministic per level, so a level is reproducible and
  testable.
- **Script limitation, needs a native reviewer:** words are split by Unicode
  code point (`runes`), not by grapheme cluster. Latin script is safe.
  Devanagari conjuncts and other combining-mark scripts would need a real
  segmenter before this game is offered in those languages.
- A word that cannot fit the grid is **reported, not silently dropped**: the
  game emits `content_unavailable` with the word ids so the caregiver can be
  told which of their words did not fit.

## New event types — Pranav needs to see these

These games emit types that do not yet have a backend calculator. The backend
accepts unknown types and falls back to `generic_v1`, so ingestion works
today, but no game-specific metric is computed until Pranav adds calculators.

| Game | Events |
|---|---|
| Routine Recall | `step_presented {stepId}`, `attempt_resolved {stepId, chosenId, correct, attempt}`, `routine_completed` |
| Word Search | `word_found {wordId}`, `selection_rejected {cellCount}`, `all_words_found`, `content_unavailable {reason, wordIds}` |
| Picture Sorting | `item_sorted {itemId, categoryId, correct, attempt}`, `sorting_completed` |

All three also emit the shared lifecycle events unchanged: `session_started`,
`hint_requested`, `paused`, `resumed`, `session_finished`.

`attempt` is included precisely so first-attempt accuracy can be computed
server-side without the game asserting an accuracy figure of its own.

## Shared change

`tesseract_game_contract` gained one **additive, optional** widget,
`TesseractGameScaffold`, holding the Help/Break controls and pause overlay.
Route Quest and Marble Maze draw their own and are **unchanged**. No existing
event name, payload or type was touched.

## What is verified, and what is not

Verified: 44 automated tests across the three new packages
(word_search 24, routine_recall 11, picture_sorting 9), covering event
sequencing, exactly-once finalisation, Help/Break, retry attempts, empty
content, and that no personal text reaches a payload. All three render inside
the real host — screenshots are in `Apnapan/host/test/goldens/`.

**Not verified:** none of this has run on a physical Android device. Emoji
render as placeholder boxes in the golden environment because no emoji font is
loaded there; on Android the system font should supply them, and every item
also shows a text label so the games remain usable either way. That needs
confirming on a real phone.

## Open questions for Ruthika

1. Are these changes to her mechanics acceptable, particularly removing the
   score/stars and dropping the medicine step from the default routine?
2. Does she want to own these Flutter packages going forward, or review only?
3. Should Picture Sorting stay as an extra activity, or be dropped?
4. Read-aloud: worth adding as a host-level feature for all games?
