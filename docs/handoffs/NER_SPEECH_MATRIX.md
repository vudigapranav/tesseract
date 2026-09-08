# North Eastern Region speech capability matrix — 2026-09-08

Status of speech **output** (text-to-speech) and speech **input** (recognition)
for the five NER languages this build ships.

Read the column headings literally. "Documented" is a claim by a vendor.
"Device" is what an engine on a real phone reported. They are different things,
and only the second one decides what the app does.

## The matrix

| Language | Code | Script | Tags tried | TTS documented | STT documented | Device TTS | Device STT | Engine | Offline | Implementation | Fluent review |
|---|---|---|---|---|---|---|---|---|---|---|---|
| English | `en` | Latin | `en-IN`, `en-US`, `en` | Yes | Yes | **NOT TESTED** | **NOT TESTED** | — | Usually, after voice download | Routed | n/a (source language) |
| Bengali | `bn` | Bengali-Assamese | `bn-IN`, `bn-BD`, `bn` | **Yes** | **Yes** | **NOT TESTED** | **NOT TESTED** | — | TTS likely after download; STT likely needs network | Routed | **Not reviewed** |
| Assamese | `as` | Bengali-Assamese | `as-IN`, `as` | No | Unclear | **NOT TESTED** | **NOT TESTED** | — | Unknown | Routed, expected unavailable | **Not reviewed** |
| Meitei | `mni` | Meetei Mayek | `mni-IN`, `mni` | No | No | **NOT TESTED** | **NOT TESTED** | — | n/a | Routed, expected unavailable | **Not reviewed** |
| Khasi | `kha` | Latin | `kha-IN`, `kha` | No | No | **NOT TESTED** | **NOT TESTED** | — | n/a | Routed, expected unavailable | **Not reviewed** |
| Mizo | `lus` | Latin | `lus-IN`, `lus` | No | No | **NOT TESTED** | **NOT TESTED** | — | n/a | Routed, expected unavailable | **Not reviewed** |

"Routed" means the app asks the engine for that language, uses it if the engine
really offers it, and otherwise tells the user speech is unavailable **in that
language**. It does not mean speech works.

Every Device column says NOT TESTED because no Android phone was connected
during this work (`adb devices` was empty). Nothing in this table may be
upgraded from a device column without an actual run on actual hardware.

## Sources consulted (2026-09-08)

* Google, *Languages supported by TalkBack* — the official Google
  text-to-speech voice list. Indian entries are Bangla (Bangladesh), Bangla
  (India), Gujarati, Hindi, Kannada, Malayalam, Marathi, Punjabi, Tamil,
  Telugu. **Assamese, Meitei, Khasi and Mizo are absent.**
* Google, Gboard voice-typing documentation. Voice typing is a different
  capability from Gboard's *typing* language list.
* Google Translate's 2022 additions of Assamese, Meiteilon and Mizo.

## The trap this table exists to avoid

Assamese, Meitei and Mizo are all easy to *believe* are supported, because they
appear in Google Translate and in Gboard's typing languages, and those are the
lists people find first. Neither one is a voice or a recogniser. Translation
support says nothing about speech.

Mizo and Khasi make it worse: both are written in Latin script, so an English
engine will accept their text and read it out as mangled English rather than
failing. A naive implementation would sound like it works. `resolveEngineTag`
refuses cross-language matches specifically so this cannot happen, and there is
a test that walks every NER tag against an English-only engine list and asserts
no match.

## Verification status

**Automated (done, this session).** 28 tests in `Apnapan/host/test/speech_test.dart`
cover tag resolution, cross-language refusal, unavailable-language routing,
audio-preference gating, no-overlap, background stop, language rebinding,
permission request-at-point-of-use, permission denial, missing recogniser,
timeout, network failure, cancellation, disposal, and confirmation-before-use.
Three goldens in `speech_golden_test.dart` show the control present, the
unavailable-language message, and the Bengali large-text layout.

These verify **routing and behaviour**. They say nothing about whether a voice
is intelligible or a recogniser understands anyone. That is the next column.

**On-device (not started).** Needs a phone. For each language: install/enable
the engine, probe, then play a real instruction and a real reminder.

**Fluent-speaker review (not started).** Needs a named speaker per language.
Automated tests cannot substitute, and no language may be marked speech-verified
without it.

## What to do when a phone is available

1. `adb devices`, then install the debug APK.
2. Settings → Speaking and listening → "Check what this phone supports". This
   probes the real engines and fills the Device columns.
3. Record engine name and version, Android version, and whether voice data had
   to be downloaded.
4. Play instructions and one reminder per language that probes available.
5. Repeat with the phone in aeroplane mode to separate offline from online.

## Blockers

1. **No device.** Every device result is unmeasured.
2. **No fluent speakers identified** for any of the five languages.
3. **Expected provider gap.** On current documentation, four of the five NER
   languages have no Google voice and no Google recogniser. This is a real
   limitation of available engines, not something the app can implement around.
   The app's answer is to say so in the patient's own language and keep every
   text and touch control working. Closing it would need a different provider
   or a third-party engine, which is a scope and cost decision, not a coding
   one.
