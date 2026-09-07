import 'package:flutter/foundation.dart';

import 'game_item.dart';
import 'game_strings.dart';

/// 'touch' | 'tilt'. Kept as a plain string (not an enum) to match the
/// contract exactly; games should compare against these constants rather
/// than string literals.
abstract final class GameInputMode {
  static const String touch = 'touch';
  static const String tilt = 'tilt';

  /// Every valid value, for validation.
  static const List<String> values = <String>[touch, tilt];
}

/// Everything a [TesseractGame] needs to run one session, frozen at level
/// load time. A game never fetches or mutates any of this itself.
///
/// This is the mobile-side half of the session configuration snapshot
/// described in "Shared session and event contract" — `session_id` and
/// `patient_id` are host/backend concerns and never reach the game.
///
/// Not a `const`-constructible class: construction validates [inputMode] and
/// throws [ArgumentError] on an invalid value, in every build mode (not just
/// debug), because a bad input mode reaching a game is a contract violation,
/// not a developer typo to catch only in debug.
@immutable
class GameConfig {
  GameConfig({
    required this.gameId,
    required this.gameVersion,
    required this.schemaVersion,
    required this.configVersion,
    required this.contentVersion,
    required this.metricVersion,
    required this.level,
    required this.difficultyParams,
    required this.items,
    required this.strings,
    required this.textScale,
    required this.inputMode,
    required this.showLabels,
    required this.locale,
    this.isTutorial = false,
  }) {
    if (!GameInputMode.values.contains(inputMode)) {
      throw ArgumentError.value(inputMode, 'inputMode', "must be one of GameInputMode ('touch' or 'tilt')");
    }
  }

  /// Stable identifier for the game (for example `'route_quest'`).
  final String gameId;

  /// Version of this game's own logic/content, recorded for telemetry.
  final String gameVersion;

  /// Version of the shared event/config schema this session was built
  /// against.
  final String schemaVersion;

  /// Version of the difficulty/config preset resolved into [level] and
  /// [difficultyParams].
  final String configVersion;

  /// Version of the content pack [items] was drawn from.
  final String contentVersion;

  /// Version of the metric-calculation rules that will interpret this
  /// session's events.
  final String metricVersion;

  /// Difficulty level. Range and meaning (what counts as 1 vs 3) is a
  /// per-game decision — this package does not constrain it.
  final int level;

  /// The actual settings [level] resolves to for this game — for example
  /// `{'nodeCount': 5, 'branches': 1}` — never just the level number. Per
  /// "store actual settings, not just an Easy/Medium/Hard label."
  ///
  /// Each game exposes its own `difficultyParamsForLevel(level)` (a static
  /// method on the game's widget class — Dart cannot express a static
  /// method in an interface, so this is a documented convention every game
  /// must follow, not something this package can enforce at compile time)
  /// that the host calls to populate this field, so a session snapshot
  /// always records real settings rather than a difficulty label.
  final Map<String, Object?> difficultyParams;

  /// Content for this session, in host-defined order.
  final List<GameItem> items;

  /// Every display string this session may need.
  final GameStrings strings;

  /// The platform/user text scale in effect. A game's layout must survive
  /// 2.0 without clipping or overflow.
  final double textScale;

  /// 'touch' or 'tilt' — see [GameInputMode].
  final String inputMode;

  /// Whether item labels should be shown alongside images.
  final bool showLabels;

  /// BCP-47 locale tag, for a game's own locale-sensitive decisions (for
  /// example date/number formatting). Display text itself always comes from
  /// [strings], never from formatting against this value.
  final String locale;

  /// Whether this session is a tutorial/"how to play" run rather than a
  /// normal one. A game still emits its normal events either way; keeping
  /// tutorial sessions out of comparability series is a host/metrics
  /// concern, not this package's.
  final bool isTutorial;
}
