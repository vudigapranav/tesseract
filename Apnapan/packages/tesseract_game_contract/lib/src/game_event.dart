import 'package:flutter/foundation.dart';

/// One telemetry event. Always create these through a
/// [TesseractEventRecorder], never by hand, so `seq` and `elapsedMs` stay
/// correct — see that class for the sequencing rules.
///
/// [payload] carries opaque ids only: never a name, a label, an image path,
/// or raw coordinates.
///
/// Field ownership — this matters at integration, across nine games with
/// different owners:
///
///  * The **game** supplies everything on this class: [type], [seq],
///    [elapsedMs] and [payload]. This is the entire envelope a
///    [TesseractGame] ever sees or produces.
///  * The **host** wraps each [GameEvent] with the fields it alone knows
///    when persisting/uploading it: `event_id` (a fresh device-generated
///    UUID per event), `session_id`, `patient_id`, `occurred_at` (UTC wall
///    clock, read at wrap time), `game_id`, `game_version` and
///    `schema_version` (both copied from the [GameConfig] the host itself
///    built). A game never sees or sets any of these six fields.
@immutable
class GameEvent {
  const GameEvent({
    required this.type,
    required this.seq,
    required this.elapsedMs,
    this.payload = const <String, Object?>{},
  });

  /// Event type, for example `session_started` or a game-defined type such
  /// as `location_entered`.
  final String type;

  /// 1-based, gap-free, session-unique sequence number.
  final int seq;

  /// Milliseconds on the session's monotonic clock, excluding paused and
  /// backgrounded time.
  final int elapsedMs;

  /// Opaque-id-only event data.
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type,
        'seq': seq,
        'elapsedMs': elapsedMs,
        'payload': payload,
      };

  @override
  String toString() => 'GameEvent(${toJson()})';
}
