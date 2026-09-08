# Translation draft review queue — 2026-09-08

All non-English text remains draft. No fluent-speaker review or voice support is claimed.

Added Assamese and Bengali drafts for greetings, version placeholders, sync and doctor labels, and notification metadata. Please review all additions before deployment, particularly the gentle-reminder idiom, session/sync terminology, observed measures (Bengali), and level-change grammar around placeholders. Existing game instructions also need semantic review for omitted help/direction instructions.

Meitei, Khasi and Mizo remain partial with explicit English fallback: no additional wording was added without sufficient confidence. A fluent speaker must supply/review these drafts; percentages are not a release criterion. No languages were added for the four uncovered regions.

The exact English attribution remains unchanged. Notification bodies retain caregiver-entered wording; translation must never silently rewrite a personal reminder. Caregivers should enter reminders in the patient's language.

## Update — later on 2026-09-08 (speech pass)

Assamese and Bengali are now at 100% of translatable keys. **They are still
drafts.** Nothing here has been read by a fluent speaker, and a test now
enforces that full coverage cannot present itself as reviewed.

Added 32 speech strings per language (read-aloud controls, listening states,
permission and unavailable-language messages, the Settings speech section), plus
the previously missing Assamese and Bengali strings for sign-in configuration,
Marble Maze tilt/touch instructions, doctor labels and the observed-measures
disclaimer.

Please review with particular care:

* **`voiceNeedsConfirmation`** — "Nothing is saved until you choose Use this."
  This is a safety promise. If the translation is ambiguous about *when*
  saving happens, it is wrong even if the words are fine.
* **`speechUnavailableForLanguage` / `voiceLanguageUnavailable`** — these must
  read as "this phone cannot do it in your language", never as "your language
  is not supported by this app" and never as blaming the user.
* **`speechDraftWarning`** — must not sound like a defect warning.
* Assamese `decisionApproved` / `decisionModified` — caregiver decision wording.
* Assamese `textSizeHelp` — the phrase for Android's own text-size setting.
* Both: the Marble Maze tilt instruction is long; check it still reads calmly.

`appName` and `builtBy` are deliberately absent from every translation file and
are now marked `x-untranslatable` in `app_en.arb`. The attribution must appear
in exactly its English wording in every language; a test fails if any locale
overrides it.

Meitei, Khasi and Mizo were **not** expanded. Their percentages fell from
9/10/10 to 8/8/8 purely because the English string set grew. No wording was
invented for them. A fluent speaker must supply these drafts.

Translated text is still not voice support. See `NER_SPEECH_MATRIX.md`: on
current documentation only Bengali has a documented Google voice or recogniser,
and no language has been tested on a device or reviewed by a speaker.
