import 'package:flutter/foundation.dart';

/// 'completed' | 'stopped_by_user' | 'interrupted'.
abstract final class GameResultStatus {
  /// The game's own objective was reached.
  static const String completed = 'completed';

  /// The patient used Break/Finish (or an equivalent host control) to end
  /// the session before completion.
  static const String stoppedByUser = 'stopped_by_user';

  /// The session ended without an explicit finish — for example the host
  /// was killed while backgrounded.
  static const String interrupted = 'interrupted';

  /// Every valid value, for validation.
  static const List<String> values = <String>[completed, stoppedByUser, interrupted];
}

/// Reported exactly once per session, when a [TesseractGame] calls its
/// `onFinish` callback.
///
/// Not a `const`-constructible class: construction validates [status] and
/// throws [ArgumentError] on an invalid value, in every build mode.
@immutable
class GameResult {
  GameResult({
    required this.status,
    required this.finalSeq,
    required this.assisted,
  }) {
    if (!GameResultStatus.values.contains(status)) {
      throw ArgumentError.value(status, 'status', 'must be one of GameResultStatus');
    }
  }

  /// See [GameResultStatus].
  final String status;

  /// The `seq` of the last [GameEvent] emitted this session (the
  /// `session_finished` event, if the session finished normally).
  final int finalSeq;

  /// True if Help was used at any point this session.
  final bool assisted;
}
