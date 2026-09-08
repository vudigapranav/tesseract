/// Optional spoken output, in the patient's own language or not at all.
///
/// The rules this file exists to enforce:
///
/// * **Never speak the wrong language.** If the engine has no voice for the
///   patient's language, the app says so in text and stays quiet. It does not
///   read Mizo aloud with an English voice because both use Latin letters.
/// * **Never speak over itself.** One utterance at a time; a new request
///   replaces the old one rather than layering on top of it.
/// * **Never speak when the caregiver turned audio off.**
/// * **Never keep speaking into the background.**
/// * Speech is an addition. Every word it reads is already on the screen and
///   every action is still reachable by touch.
library;

import 'package:flutter/foundation.dart';

import 'speech_capability.dart';
import 'speech_engine.dart';

/// Why the app is not speaking, in terms a caregiver can act on.
enum SpeechUnavailableReason {
  /// The caregiver switched sound off in Settings.
  audioOff,

  /// This device has no text-to-speech engine at all.
  noEngine,

  /// The engine works but has no voice for this language. The important one:
  /// this is a real gap for most North Eastern Region languages and is
  /// reported, not worked around.
  noVoiceForLanguage,

  /// The engine accepted the language but the utterance failed.
  engineError,
}

/// What the UI needs to draw a speak control.
@immutable
class SpeechAvailability {
  const SpeechAvailability.available(this.resolvedTag)
      : isAvailable = true,
        reason = null;

  const SpeechAvailability.unavailable(this.reason)
      : isAvailable = false,
        resolvedTag = null;

  final bool isAvailable;
  final SpeechUnavailableReason? reason;

  /// The exact tag the engine accepted, for the capability matrix.
  final String? resolvedTag;
}

/// Speaks short pieces of already-visible text.
///
/// Deliberately not a general TTS wrapper: it takes text the caller already
/// localised, so there is no way for this class to invent wording, and it
/// never receives a patient's personal reminder body without the caller
/// having decided that is appropriate.
class SpeechOutputService extends ChangeNotifier {
  SpeechOutputService({
    required TtsEngine engine,
    required bool Function() audioEnabled,
  })  : _engine = engine,
        _audioEnabled = audioEnabled;

  final TtsEngine _engine;
  final bool Function() _audioEnabled;

  /// Probe results per language code, filled lazily and then reused. Keyed by
  /// the app's language code, not by engine tag.
  final Map<String, SpeechProbe> _probes = <String, SpeechProbe>{};

  bool _speaking = false;
  String? _currentLanguage;
  int _generation = 0;

  /// True while an utterance is in flight, so the control can show Stop.
  bool get isSpeaking => _speaking;

  /// The probe results gathered so far, for the settings/diagnostics view and
  /// for the speech matrix. Read-only.
  Map<String, SpeechProbe> get probes =>
      Map<String, SpeechProbe>.unmodifiable(_probes);

  /// Ask the engine, once per language, whether it can speak [code].
  ///
  /// Answers from the engine on this device — never from the documented
  /// expectations in [SpeechMatrix], which exist only to set reviewer
  /// expectations.
  Future<SpeechProbe> probe(String code) async {
    final SpeechProbe? cached = _probes[code];
    if (cached != null) return cached;

    final List<String> wanted = SpeechMatrix.tagsFor(code);
    if (wanted.isEmpty) {
      // A language the app ships but the matrix does not describe. Refusing
      // is right: guessing a tag is how you end up speaking the wrong
      // language.
      return _probes[code] =
          SpeechProbe.unavailable(code, SpeechDirection.output);
    }

    final List<String> offered = await _engine.languages();
    for (final String tag in wanted) {
      final String? match = resolveEngineTag(tag, offered);
      if (match == null) continue;
      // Enumeration and reality disagree on some engines, so confirm the
      // engine will actually bind to it before calling it available.
      if (!await _engine.setLanguage(match)) continue;
      return _probes[code] = SpeechProbe(
        code: code,
        direction: SpeechDirection.output,
        available: true,
        resolvedTag: match,
        engine: await _engine.engineName(),
      );
    }
    return _probes[code] =
        SpeechProbe.unavailable(code, SpeechDirection.output);
  }

  /// Whether a speak control should be offered for [code], and if not, why.
  Future<SpeechAvailability> availability(String code) async {
    if (!_audioEnabled()) {
      return const SpeechAvailability.unavailable(
          SpeechUnavailableReason.audioOff);
    }
    final List<String> offered = await _engine.languages();
    if (offered.isEmpty) {
      return const SpeechAvailability.unavailable(
          SpeechUnavailableReason.noEngine);
    }
    final SpeechProbe p = await probe(code);
    return p.available
        ? SpeechAvailability.available(p.resolvedTag!)
        : const SpeechAvailability.unavailable(
            SpeechUnavailableReason.noVoiceForLanguage);
  }

  /// Speak [text] in [languageCode].
  ///
  /// Returns the availability that was applied, so a caller can show the
  /// reason inline when nothing was spoken. A repeat call while speaking
  /// stops the previous utterance first — that is the replay behaviour, and
  /// it is also what keeps two utterances off the speaker at once.
  Future<SpeechAvailability> speak(String text,
      {required String languageCode}) async {
    final SpeechAvailability a = await availability(languageCode);
    if (!a.isAvailable) {
      await stop();
      return a;
    }

    await stop();
    final int generation = ++_generation;

    if (_currentLanguage != languageCode) {
      if (!await _engine.setLanguage(a.resolvedTag!)) {
        return const SpeechAvailability.unavailable(
            SpeechUnavailableReason.engineError);
      }
      _currentLanguage = languageCode;
    }

    _speaking = true;
    notifyListeners();
    await _engine.speak(text);

    // A newer utterance, a stop, or a screen teardown may have happened while
    // that awaited. Only the generation that is still current may clear the
    // flag, otherwise the control flickers back to "play" under a live
    // utterance.
    if (generation == _generation) {
      _speaking = false;
      notifyListeners();
    }
    return a;
  }

  /// Stop at once. Safe to call repeatedly and when nothing is speaking.
  Future<void> stop() async {
    _generation++;
    await _engine.stop();
    if (_speaking) {
      _speaking = false;
      notifyListeners();
    }
  }

  /// Called when the app leaves the foreground or the patient session ends.
  ///
  /// Speech must not continue out of a backgrounded app: it would talk over
  /// whatever the person opened next, and a reminder read aloud after handover
  /// could be heard by someone the caregiver did not intend.
  Future<void> handleAppBackgrounded() => stop();

  /// Called when the selected language changes, so the next utterance rebinds
  /// rather than continuing in the previous voice.
  Future<void> handleLanguageChanged() async {
    _currentLanguage = null;
    await stop();
  }

  @override
  void dispose() {
    _generation++;
    _engine.stop();
    super.dispose();
  }
}
