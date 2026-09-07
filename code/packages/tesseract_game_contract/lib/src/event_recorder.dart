import 'game_event.dart';
import 'game_result.dart';

/// Lifecycle event type constants shared by every game. A game adds its own
/// types on top of these by calling [TesseractEventRecorder.custom].
abstract final class GameLifecycleEvent {
  static const String sessionStarted = 'session_started';
  static const String tutorialStarted = 'tutorial_started';
  static const String tutorialCompleted = 'tutorial_completed';
  static const String hintRequested = 'hint_requested';
  static const String supportChanged = 'support_changed';
  static const String paused = 'paused';
  static const String resumed = 'resumed';
  static const String sessionFinished = 'session_finished';
}

/// The single shared implementation of the event rules every game must
/// follow:
///
///  * `seq` starts at 1, increments by 1, and is never reused or skipped.
///  * `elapsedMs` is a monotonic session clock that excludes paused and
///    backgrounded time.
///  * Using Help always emits `hint_requested` and marks the session
///    assisted.
///  * A session finalizes exactly once.
///
/// These are release-mode invariants, not developer-only sanity checks —
/// they are enforced with real exceptions ([StateError] / [ArgumentError]),
/// not `assert`, because a duplicated `session_finished` reaching the
/// backend violates "only one finalization is accepted" regardless of build
/// mode.
///
/// A game creates exactly one recorder per session, calls [sessionStarted]
/// when play begins, [paused]/[resumed] around breaks and backgrounding (see
/// `TesseractGameStateMixin` for backgrounding specifically),
/// [hintRequested] when the Help control is used, its own events through
/// [custom], and [sessionFinished] exactly once when the session ends —
/// then builds its [GameResult] from [lastSeq] and [assisted].
class TesseractEventRecorder {
  TesseractEventRecorder({Stopwatch? clock}) : _clock = clock ?? Stopwatch();

  final Stopwatch _clock;
  int _seq = 0;
  bool _assisted = false;
  bool _finished = false;

  /// Milliseconds elapsed on the session clock so far, excluding any time
  /// spent paused.
  int get elapsedMs => _clock.elapsedMilliseconds;

  /// The `seq` of the most recently emitted event, or 0 if none has been
  /// emitted yet.
  int get lastSeq => _seq;

  /// Whether [hintRequested] has been called at any point this session.
  bool get assisted => _assisted;

  /// Whether the session clock is currently paused (as opposed to not yet
  /// started, or already finished).
  bool get isPaused => !_clock.isRunning && _seq > 0 && !_finished;

  /// Whether [sessionFinished] has already been called. Emitting further
  /// events after this throws — a session finalizes exactly once.
  bool get isFinished => _finished;

  /// Starts the session clock and emits `session_started`. Must be called
  /// exactly once, before any other event.
  ///
  /// Throws [StateError] if an event has already been emitted this session.
  GameEvent sessionStarted() {
    if (_seq != 0) {
      throw StateError('sessionStarted() must be the first event emitted, and called exactly once');
    }
    _clock
      ..reset()
      ..start();
    return _emit(GameLifecycleEvent.sessionStarted);
  }

  /// Emits `tutorial_started`. For the "How to Play" walkthrough, distinct
  /// from normal scored play.
  GameEvent tutorialStarted() => _emit(GameLifecycleEvent.tutorialStarted);

  /// Emits `tutorial_completed`.
  GameEvent tutorialCompleted() => _emit(GameLifecycleEvent.tutorialCompleted);

  /// Emits `support_changed` for a caregiver/host-driven support setting
  /// change mid-session (for example a guide overlay being toggled).
  /// [setting] is an opaque, host-defined description of what changed.
  GameEvent supportChanged({required String setting}) {
    return _emit(GameLifecycleEvent.supportChanged, <String, Object?>{'setting': setting});
  }

  /// Stops the session clock (so paused time is excluded from [elapsedMs])
  /// and emits `paused`. [reason] is an opaque, host-defined string such as
  /// `'break'` or `'backgrounded'`.
  GameEvent paused({String? reason}) {
    final GameEvent event = _emit(
      GameLifecycleEvent.paused,
      reason == null ? const <String, Object?>{} : <String, Object?>{'reason': reason},
    );
    _clock.stop();
    return event;
  }

  /// Restarts the session clock and emits `resumed`.
  GameEvent resumed() {
    final GameEvent event = _emit(GameLifecycleEvent.resumed);
    _clock.start();
    return event;
  }

  /// Emits `hint_requested` and marks the session assisted. Never shown to
  /// the patient as a failure — that is a presentation rule for the game and
  /// host, not something this recorder enforces.
  GameEvent hintRequested() {
    final GameEvent event = _emit(GameLifecycleEvent.hintRequested);
    _assisted = true;
    return event;
  }

  /// Emits a game-defined event type with [payload]. [payload] must carry
  /// opaque ids only.
  GameEvent custom(String type, [Map<String, Object?> payload = const <String, Object?>{}]) {
    return _emit(type, payload);
  }

  /// Stops the session clock and emits `session_finished`. Must be called
  /// exactly once.
  ///
  /// Throws [ArgumentError] if [status] is not one of [GameResultStatus],
  /// and [StateError] if the session has already finished.
  GameEvent sessionFinished(String status) {
    if (!GameResultStatus.values.contains(status)) {
      throw ArgumentError.value(status, 'status', 'must be one of GameResultStatus');
    }
    final GameEvent event = _emit(
      GameLifecycleEvent.sessionFinished,
      <String, Object?>{'status': status},
    );
    _clock.stop();
    _finished = true;
    return event;
  }

  GameEvent _emit(String type, [Map<String, Object?> payload = const <String, Object?>{}]) {
    if (_finished) {
      throw StateError("cannot emit '$type': session already finished (sessionFinished() was already called)");
    }
    _seq += 1;
    return GameEvent(type: type, seq: _seq, elapsedMs: elapsedMs, payload: payload);
  }
}
