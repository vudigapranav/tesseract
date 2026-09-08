/// The narrow seam between this app and the phone's speech engines.
///
/// Everything above this file is ordinary Dart that a widget test can drive.
/// Everything below it is a platform channel. Keeping the seam this thin is
/// what lets the routing, permission, cancellation and fallback rules be
/// tested for real instead of mocked at the service level and hoped for.
library;

import 'package:flutter/foundation.dart';

/// Why a listen attempt ended without a usable transcript.
enum VoiceInputFailure {
  /// The user has not granted microphone access, or denied it at the prompt.
  permissionDenied,

  /// The user denied it permanently; only Settings can undo this.
  permissionPermanentlyDenied,

  /// No recogniser on the device at all.
  recognitionUnavailable,

  /// A recogniser exists but not for the language asked for. Never resolved
  /// by substituting another language.
  languageUnavailable,

  /// Listening started but nothing intelligible arrived in time.
  timeout,

  /// The user pressed cancel.
  cancelled,

  /// The recogniser needs the network and it was not there.
  network,

  /// Anything else the engine reported.
  engineError,
}

/// A finished listen attempt.
@immutable
class VoiceInputResult {
  const VoiceInputResult.heard(this.transcript, {this.confidence})
      : failure = null;

  const VoiceInputResult.failed(this.failure)
      : transcript = '',
        confidence = null;

  /// What the recogniser thought it heard. Shown to the user for
  /// confirmation, never acted on by itself.
  final String transcript;

  final double? confidence;

  final VoiceInputFailure? failure;

  bool get ok => failure == null && transcript.trim().isNotEmpty;
}

/// Text-to-speech, reduced to what this app needs.
abstract class TtsEngine {
  /// BCP-47 tags this engine can speak. May be empty on a bare device.
  Future<List<String>> languages();

  /// Bind the engine to [tag]. Returns false when the engine refuses, which
  /// the caller treats as unavailable — it never speaks with a wrong voice.
  Future<bool> setLanguage(String tag);

  /// Speak [text], completing when the utterance finishes or is stopped.
  Future<void> speak(String text);

  /// Stop immediately. Safe to call when nothing is speaking.
  Future<void> stop();

  /// Identifier of the engine answering, when it offers one.
  Future<String?> engineName();

  Future<void> setSpeechRate(double rate);
}

/// Speech-to-text, reduced to what this app needs.
abstract class SttEngine {
  /// Bring the recogniser up. False when the device has none.
  Future<bool> initialize();

  /// Locale ids the recogniser offers.
  Future<List<String>> locales();

  /// Whether microphone permission is already held.
  Future<bool> hasPermission();

  /// Ask for microphone permission at the point of use.
  Future<bool> requestPermission();

  /// Listen once in [localeId] and resolve when the user stops, the engine
  /// finalises, [listenFor] elapses, or [cancel] is called.
  Future<VoiceInputResult> listenOnce({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
  });

  /// Abandon the current listen and discard whatever was heard.
  Future<void> cancel();

  bool get isListening;
}
