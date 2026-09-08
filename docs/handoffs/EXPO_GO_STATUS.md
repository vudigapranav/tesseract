# Expo Go build — status and setup

Created 2026-09-08. The Flutter application in `code/host` is **unchanged** and
remains the reference implementation and the working fallback. This is an
additional frontend in `code/tesseract-expo`, built so the app can be opened on
an iPhone through Expo Go without a custom native build.

## Run it

```bash
cd code/tesseract-expo
cp .env.example .env      # fill in the public Firebase key
npx expo start
```

Scan the QR with the iPhone **Camera** app; it opens Expo Go. Phone and Mac must
be on the same Wi-Fi. The Mac must stay running — Expo Go loads the JavaScript
bundle from Metro on this machine; it is not installed on the phone.

If the LAN does not work (guest Wi-Fi, client isolation, VPN):
`npx expo start --tunnel`. Slower, but it routes over the internet instead.

## SDK and Expo Go compatibility

| | |
|---|---|
| Expo SDK | **57.0.20** |
| React Native | 0.86.3 · React 19.2.3 |
| App Store Expo Go | **57.0.9**, released 2026-09-02 |
| `npx expo-doctor` | **21/21 checks passed** |

SDK 57 is correct and required. Expo Go runs **only** the newest SDK, and the
App Store build supports 57 as of 2026-09-02. (The SDK 57 changelog still says
iOS approval was pending; that was written at release and has since shipped —
the App Store listing is the current fact.)

Every dependency is either bundled in Expo Go or pure JavaScript. Nothing needs
prebuild, a config plugin with native changes, or a development client:

`expo-speech` · `expo-sensors` · `expo-notifications` · `expo-secure-store` ·
`expo-sqlite` · `expo-font` · `expo-localization` · `expo-application` ·
`expo-constants` · `expo-crypto` · `expo-device` ·
`@react-native-async-storage/async-storage` · `react-native-svg` ·
`react-native-gesture-handler` · `react-native-safe-area-context` ·
`react-native-screens` · `@react-navigation/*` · `firebase` (JS SDK, unused at
runtime — identity goes over the REST endpoints the Flutter client already
verified).

## What is implemented and verified

**Verified by automated test and typecheck** (`npm test`, `npm run typecheck`):

- **The shared game contract.** `seq` 1-based and gap-free, paused time excluded
  from the clock, Help marking a session assisted permanently, exactly one
  finalization, invalid statuses rejected. 9 tests.
- **All five activities**, ported with rules, event names, sequencing and
  difficulty settings unchanged: Route Quest, Marble Maze, Word Search, Daily
  Routine Recall, Picture Sorting. Full play-throughs asserted, including
  Route Quest completing and Picture Sorting finishing exactly once. 20 tests.
- **Opaque-id-only payloads.** Every gameplay test asserts that no caregiver
  word, place name, routine step or person's name reaches an event payload.
- **The outbox**: ordered `create → events → complete`, session and event ids
  stable across retries, 500-event batch cap (asserted with a 1200-event
  session splitting 500/500/200 in order), permanent 4xx stopping retries while
  keeping the data, 401 pausing rather than losing anything, and recovery of a
  session interrupted mid-upload after a restart. 9 tests.
- **`elapsedMs` → `elapsed_ms`** renamed only at the API boundary.
- **Localisation coverage** recomputed from the ARBs.

**38 tests passing. TypeScript strict: clean. expo-doctor: 21/21.**

**Verified by building the real bundle:** `GET /index.bundle?platform=ios`
returns HTTP 200 and 5.3 MB with every module present. The app compiles for
iOS.

## What is NOT verified

**Nothing has run on the iPhone yet.** A built bundle is not a device test.
Until the QR is scanned, all of this is **NOT TESTED**: app start in Expo Go,
navigation, language switching, the caregiver → hand-over → play → return loop,
storage across restarts, offline behaviour, VoiceOver, Dynamic Type, safe areas,
motion input in Marble Maze, and every speech behaviour.

## Localisation

Ported directly from the Flutter ARBs by `tools/sync-l10n.mjs`, so the two apps
cannot drift. `npm run l10n:check` fails if they do.

| Language | Coverage | Review |
|---|---|---|
| English | 100% | source |
| Assamese | 100% | **draft — not reviewed** |
| Bengali | 100% | **draft — not reviewed** |
| Meitei | 8% | draft — not reviewed |
| Khasi | 8% | draft — not reviewed |
| Mizo | 8% | draft — not reviewed |

167 translatable keys (169 minus `appName` and `builtBy`, which must render in
exact English everywhere). No language has been reviewed by a fluent speaker.

**A stated gap:** the game-specific in-game wording (`gameText.ts`) is
English-only. The Flutter build has the same gap — it localises only the six
shared control labels. Rather than invent ARB keys and inflate the coverage
figures, the same boundary is kept and written down.

Noto fonts for Bengali-Assamese and Meetei Mayek are **not yet bundled** in this
build, so those scripts fall back to iOS system fonts. iOS ships Bengali
coverage; Meetei Mayek may render as boxes. Needs a device check.

## Speech

**Reading aloud works.** `expo-speech` is in Expo Go. Per-language probing,
one-utterance-at-a-time, stop/replay, audio-preference gating, stop on
backgrounding and on language change — all ported. When a language has no
voice, the app names that language and stays quiet; it never reads Mizo or
Khasi aloud with an English voice because both use Latin letters.

**Speaking to the app does not work, and cannot, in Expo Go.**

This is a property of the runtime, not a missing feature. iOS speech
recognition is `SFSpeechRecognizer`, a native API. Every React Native binding
(`expo-speech-recognition`, `@react-native-voice/voice`) ships a config plugin
that modifies the native iOS project, and Expo Go runs a fixed App Store binary
that cannot load a module it was not compiled with. The library's own docs say
it "does not work in Expo Go" and requires a development build.

What was done instead: the full tap-to-speak contract — explicit activation,
permission at point of use, listening state, cancel, and **confirmation before
anything is saved** — is implemented and typed against a `SpeechRecognizer`
interface, with `ExpoGoUnavailableRecognizer` as the implementation this runtime
actually has. It reports a distinct `recognitionUnavailableInExpoGo` reason so
the UI explains the *runtime* limitation rather than blaming the language. Every
text and touch path is untouched. Swapping in a real recogniser later is a
one-file change.

Two ways to actually get voice input, neither taken without a decision:
1. A development or TestFlight build with `expo-speech-recognition`. Audio stays
   on the device. Costs the Expo Go workflow the user asked for.
2. Record in Expo Go (`expo-audio` works) and transcribe on the backend. Sends a
   patient's voice to a third party; needs provider choice, a server-side
   credential, and a cost conversation — and for four of the five NER languages
   no major provider lists support anyway.

### Per-language speech matrix

| Language | TTS documented | STT documented | Device TTS | Device STT | Expo Go STT |
|---|---|---|---|---|---|
| English | Yes | Yes | **NOT TESTED** | — | **Impossible** |
| Bengali | Yes | Yes | **NOT TESTED** | — | **Impossible** |
| Assamese | No | No | **NOT TESTED** | — | **Impossible** |
| Meitei | No | No | **NOT TESTED** | — | **Impossible** |
| Khasi | No | No | **NOT TESTED** | — | **Impossible** |
| Mizo | No | No | **NOT TESTED** | — | **Impossible** |

No language is speech-verified. None has had fluent-speaker review.

## Games

**Four of the nine required games, plus one extra** — the same count as Flutter.
Registered: Route Quest (G2), Marble Maze (G3), Word Search (G7), Daily Routine
Recall (G8), and Picture Sorting as an extra.

**Still missing**, owned by Aryan and not stubbed or approximated here: Reveal
Match (G1), Trace (G4), Coloring (G5), Spot Difference (G6), Picture Recall
(G9). `MISSING_REQUIRED_GAME_IDS` names them in code and a test asserts the
list, so the catalogue cannot quietly claim completeness. Repository URLs needed
before integration.

Marble Maze stays motion-first via `expo-sensors` `DeviceMotion` (in Expo Go),
calibrating to however the phone is being held rather than to flat, with a real
touch fallback always available. **The reported input mode is the mode actually
used** — never fabricated. Motion behaviour on the iPhone is NOT TESTED.

## API and identity

Identity uses the same Firebase REST endpoints the Flutter client verified live
against project `tesseract-3ac5a` (Email/Password, enabled 2026-09-08). No
synthetic fallback: a failed sign-in stays failed, and the preview is a
separate, explicitly chosen, visibly labelled path.

`EXPO_PUBLIC_TESSERACT_API_URL` is **empty**, because no HTTPS backend is
deployed. The API layer is written against Pranav's contract but has not run
against a live server from this client. With no API configured the app keeps
everything on the device and says so — it never shows a false "synced".

One deliberate difference from Flutter: sign-in requires only the Firebase key,
not also an HTTPS API URL. Identity and the API are separate services, and
refusing sign-in for a missing backend would report an identity problem that
does not exist.

## Not implemented in this build

Honestly listed rather than stubbed behind plausible-looking empty screens
(these screens say outright that they are not built):

- Know Me personalization editing and conflict handling.
- Reminders: create/edit/cancel/postpone/acknowledge, notification scheduling.
- Caregiver recommendations and the accept / modify / reject decision loop.
- Doctor screens (assigned patients, history, observations, reports, notes).
- Biometric gate on the caregiver return.
- Bundled Noto fonts.

The Flutter build has all of these. This is a first working port, not parity.
