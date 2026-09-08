/// The real Android engines, behind the [TtsEngine] / [SttEngine] seam.
///
/// These are the only files in the speech layer that touch a platform
/// channel, and they contain no policy: no fallback decisions, no permission
/// choreography, no language substitution. All of that lives above, where it
/// is testable. This file's whole job is to make the plugins look like the
/// interfaces and to fail honestly when they cannot.
///
/// Nothing here sends audio anywhere. Both plugins wrap the engine already
/// installed on the phone; no account, key or network call of this app's
/// making is involved. Whether the *engine* itself needs the network to
/// recognise a given language is the engine's business and is surfaced as
/// [VoiceInputFailure.network], not hidden.
library;

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_engine.dart';

/// A stand-in for a platform with no speech at all.
///
/// Used on the web preview, where neither plugin has an implementation. It
/// reports honestly rather than pretending: the UI then shows "this device
/// has no voice installed" instead of a control that does nothing.
class UnavailableTtsEngine implements TtsEngine {
  const UnavailableTtsEngine();

  @override
  Future<List<String>> languages() async => const <String>[];

  @override
  Future<bool> setLanguage(String tag) async => false;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<String?> engineName() async => null;

  @override
  Future<void> setSpeechRate(double rate) async {}
}

class UnavailableSttEngine implements SttEngine {
  const UnavailableSttEngine();

  @override
  bool get isListening => false;

  @override
  Future<bool> initialize() async => false;

  @override
  Future<List<String>> locales() async => const <String>[];

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<VoiceInputResult> listenOnce({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
  }) async =>
      const VoiceInputResult.failed(VoiceInputFailure.recognitionUnavailable);

  @override
  Future<void> cancel() async {}
}

class PlatformTtsEngine implements TtsEngine {
  PlatformTtsEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    // Makes `speak` resolve when the utterance actually finishes rather than
    // when it is handed to the engine. The no-overlap rule in
    // SpeechOutputService depends on that being true.
    //
    // Guarded because this is a platform call in a constructor: on a host
    // without the plugin registered — a widget test, or the web preview —
    // it raises MissingPluginException asynchronously, which would surface as
    // an unhandled error from whatever screen happened to build the engine.
    // Failing quietly here is correct: every other method already reports the
    // engine as offering nothing, so the app shows "no voice installed"
    // rather than breaking a screen that only wanted to draw a button.
    // Attached directly to the plugin's own future rather than wrapped in
    // `Future(...)`, which would schedule a Timer and leave widget tests
    // asserting on a pending timer after teardown.
    unawaited(_tts.awaitSpeakCompletion(true).catchError((Object _) => null));
  }

  final FlutterTts _tts;

  @override
  Future<List<String>> languages() async {
    try {
      final dynamic raw = await _tts.getLanguages;
      if (raw is List) {
        return raw.map((dynamic e) => '$e').toList(growable: false);
      }
    } catch (_) {
      // An engine that cannot enumerate is treated as offering nothing, which
      // routes every language to the explicit "speech unavailable" path.
    }
    return const <String>[];
  }

  @override
  Future<bool> setLanguage(String tag) async {
    try {
      final dynamic available = await _tts.isLanguageAvailable(tag);
      if (available != true) return false;
      await _tts.setLanguage(tag);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.speak(text);
    } catch (_) {
      // A failed utterance must not take the screen down with it. The caller
      // reports "could not speak"; the text is still on screen either way.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Future<String?> engineName() async {
    try {
      final dynamic e = await _tts.getDefaultEngine;
      return e == null ? null : '$e';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {}
  }
}

class PlatformSttEngine implements SttEngine {
  PlatformSttEngine([SpeechToText? speech])
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  String? _lastErrorId;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (SpeechRecognitionError e) => _lastErrorId = e.errorMsg,
        onStatus: (String _) {},
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<List<String>> locales() async {
    if (!await initialize()) return const <String>[];
    try {
      final List<LocaleName> found = await _speech.locales();
      return found.map((LocaleName l) => l.localeId).toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      return await Future<bool>.value(_speech.hasPermission);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    // `initialize` is what triggers the platform microphone prompt, and it is
    // only called from a user-initiated tap. There is no path in this app
    // that asks for the microphone before the user has asked to speak.
    final bool ok = await initialize();
    if (!ok) return false;
    return hasPermission();
  }

  @override
  Future<VoiceInputResult> listenOnce({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
  }) async {
    if (!await initialize()) {
      return const VoiceInputResult.failed(
          VoiceInputFailure.recognitionUnavailable);
    }
    _lastErrorId = null;
    final Completer<VoiceInputResult> done = Completer<VoiceInputResult>();
    String heard = '';
    double? confidence;

    void finish(VoiceInputResult r) {
      if (!done.isCompleted) done.complete(r);
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          heard = r.recognizedWords;
          confidence = r.confidence;
          if (r.finalResult) {
            finish(heard.trim().isEmpty
                ? const VoiceInputResult.failed(VoiceInputFailure.timeout)
                : VoiceInputResult.heard(heard, confidence: confidence));
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
          // Not forced on-device: an engine that can only do a language over
          // the network would otherwise fail outright, and the honest
          // behaviour is to try and report a network failure if it happens.
          onDevice: false,
        ),
      );
    } catch (_) {
      return const VoiceInputResult.failed(VoiceInputFailure.engineError);
    }

    // Backstop. The engine normally finalises well before this; without it a
    // recogniser that goes quiet would leave the listening sheet up forever.
    unawaited(Future<void>.delayed(listenFor + const Duration(seconds: 2))
        .then((_) async {
      if (done.isCompleted) return;
      await _speech.stop();
      finish(heard.trim().isEmpty
          ? VoiceInputResult.failed(_mapError(_lastErrorId))
          : VoiceInputResult.heard(heard, confidence: confidence));
    }));

    return done.future;
  }

  @override
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  VoiceInputFailure _mapError(String? id) {
    switch (id) {
      case 'error_network':
      case 'error_network_timeout':
        return VoiceInputFailure.network;
      case 'error_speech_timeout':
      case 'error_no_match':
        return VoiceInputFailure.timeout;
      case 'error_permission':
      case 'error_audio_error':
        return VoiceInputFailure.permissionDenied;
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return VoiceInputFailure.languageUnavailable;
      case null:
        return VoiceInputFailure.timeout;
      default:
        return VoiceInputFailure.engineError;
    }
  }
}
