/// Optional tap-to-speak input.
///
/// The rules this file exists to enforce:
///
/// * **Nothing listens until the user taps.** There is no wake word, no
///   ambient capture, no listening that outlives a single explicit request.
/// * **Nothing is saved or executed from a transcript alone.** The recognised
///   text is returned to the caller to *show* the user; the caller then needs
///   a separate, explicit confirmation before anything changes.
/// * **The microphone is requested at the point of use**, not at startup.
/// * **A language with no recogniser fails as unavailable**, never by
///   listening in a different language.
/// * **Recognised words never reach analytics or logs.** They are personal by
///   nature — a patient's own sentence, a caregiver's reminder wording — and
///   this service holds them only long enough to hand them back to the UI.
library;

import 'package:flutter/foundation.dart';

import 'speech_capability.dart';
import 'speech_engine.dart';

/// Where a voice session currently is, for the listening indicator.
enum VoicePhase {
  /// Nothing is happening. The only resting state.
  idle,

  /// Asking for the microphone.
  requestingPermission,

  /// Actively listening. The UI must show this unmistakably.
  listening,

  /// Recognition finished; the transcript is waiting for confirmation.
  awaitingConfirmation,

  /// It did not work; [VoiceInputController.failure] says why.
  failed,
}

/// Drives one tap-to-speak interaction.
///
/// Held by the widget that offered the microphone, disposed with it. That
/// lifetime is deliberate: a controller cannot outlive its screen, so a
/// listen cannot survive navigation.
class VoiceInputController extends ChangeNotifier {
  VoiceInputController({
    required SttEngine engine,
    this.listenFor = const Duration(seconds: 12),
    this.pauseFor = const Duration(seconds: 3),
  }) : _engine = engine;

  final SttEngine _engine;

  /// Hard ceiling on one listen. Short on purpose: an open microphone is not
  /// something to leave running while someone thinks.
  final Duration listenFor;

  /// Silence after speech that ends the turn.
  final Duration pauseFor;

  VoicePhase _phase = VoicePhase.idle;
  String _transcript = '';
  VoiceInputFailure? _failure;
  bool _disposed = false;

  VoicePhase get phase => _phase;

  /// What was heard, pending the user's confirmation. Empty at every other
  /// phase.
  String get transcript => _transcript;

  VoiceInputFailure? get failure => _failure;

  bool get isListening => _phase == VoicePhase.listening;

  /// Probe whether [code] can be recognised on this device.
  Future<SpeechProbe> probe(String code) async {
    final List<String> wanted = SpeechMatrix.tagsFor(code);
    if (wanted.isEmpty) {
      return SpeechProbe.unavailable(code, SpeechDirection.input);
    }
    if (!await _engine.initialize()) {
      return SpeechProbe.unavailable(code, SpeechDirection.input);
    }
    final List<String> offered = await _engine.locales();
    for (final String tag in wanted) {
      final String? match = resolveEngineTag(tag, offered);
      if (match != null) {
        return SpeechProbe(
          code: code,
          direction: SpeechDirection.input,
          available: true,
          resolvedTag: match,
        );
      }
    }
    return SpeechProbe.unavailable(code, SpeechDirection.input);
  }

  /// Start one listen in [languageCode]. Only ever called from a tap.
  ///
  /// On success the phase becomes [VoicePhase.awaitingConfirmation] and
  /// [transcript] holds what was heard. **That is the end of this service's
  /// job.** It does not save, submit, navigate or act.
  Future<void> start(String languageCode) async {
    if (_phase == VoicePhase.listening ||
        _phase == VoicePhase.requestingPermission) {
      return;
    }
    _transcript = '';
    _failure = null;

    _set(VoicePhase.requestingPermission);

    if (!await _engine.initialize()) {
      _fail(VoiceInputFailure.recognitionUnavailable);
      return;
    }

    if (!await _engine.hasPermission()) {
      final bool granted = await _engine.requestPermission();
      if (!granted) {
        _fail(VoiceInputFailure.permissionDenied);
        return;
      }
    }

    // Resolved before listening so an unsupported language fails cleanly
    // instead of the engine quietly choosing its default locale.
    final SpeechProbe p = await probe(languageCode);
    if (!p.available) {
      _fail(VoiceInputFailure.languageUnavailable);
      return;
    }

    _set(VoicePhase.listening);
    final VoiceInputResult result = await _engine.listenOnce(
      localeId: p.resolvedTag!,
      listenFor: listenFor,
      pauseFor: pauseFor,
    );

    // The user cancelled, or the screen went away, while the engine was busy.
    if (_disposed || _phase != VoicePhase.listening) return;

    if (!result.ok) {
      _fail(result.failure ?? VoiceInputFailure.engineError);
      return;
    }

    _transcript = result.transcript.trim();
    _set(VoicePhase.awaitingConfirmation);
  }

  /// Abandon the current listen and forget anything heard.
  Future<void> cancel() async {
    await _engine.cancel();
    _transcript = '';
    _failure = VoiceInputFailure.cancelled;
    _set(VoicePhase.idle);
  }

  /// The user rejected the transcript. Same effect as never having spoken.
  void discard() {
    _transcript = '';
    _failure = null;
    _set(VoicePhase.idle);
  }

  /// The user confirmed. Returns the text and clears it from this controller,
  /// so a transcript cannot be replayed into a second action by accident.
  String confirm() {
    final String text = _transcript;
    _transcript = '';
    _failure = null;
    _set(VoicePhase.idle);
    return text;
  }

  void _set(VoicePhase p) {
    if (_disposed) return;
    _phase = p;
    notifyListeners();
  }

  void _fail(VoiceInputFailure f) {
    if (_disposed) return;
    _failure = f;
    _transcript = '';
    _phase = VoicePhase.failed;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // Anything still open is torn down with the screen; a listen never
    // outlives the widget that asked for it.
    _engine.cancel();
    _transcript = '';
    super.dispose();
  }
}
