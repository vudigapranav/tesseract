import 'package:flutter/foundation.dart';

/// Every user-facing string a game may need to display, already localised by
/// the host. Games must never hardcode display text — every label, prompt or
/// button caption a game shows comes from here.
///
/// A small set of strings is named directly because every game needs them
/// (the Help and Break controls, and the pause overlay each game draws for
/// itself). Everything else a specific game needs — instructions, per-level
/// prompts, and so on — is looked up by key through [text], so this package
/// does not need to know each game's vocabulary in advance.
@immutable
class GameStrings {
  const GameStrings({
    required this.helpButtonLabel,
    required this.breakButtonLabel,
    required this.pausedTitle,
    required this.pausedBody,
    required this.resumeButtonLabel,
    required this.finishNowButtonLabel,
    this.values = const <String, String>{},
  });

  /// Label for the permanently visible Help control.
  final String helpButtonLabel;

  /// Label for the permanently visible Break control.
  final String breakButtonLabel;

  /// Heading a game's own pause overlay shows.
  final String pausedTitle;

  /// Body copy a game's own pause overlay shows.
  final String pausedBody;

  /// Label for the control that resumes a paused game.
  final String resumeButtonLabel;

  /// Label for the control that ends the session early from the pause
  /// overlay, without completing it.
  final String finishNowButtonLabel;

  /// Every other display string a specific game needs, keyed by a name that
  /// game defines (for example `'destination_reached_body'`).
  final Map<String, String> values;

  /// Looks up a game-specific string by [key]. In debug builds, a missing
  /// key asserts, so a missing translation is caught during development. In
  /// release — where asserts are stripped — a miss returns an empty string
  /// rather than the raw key: showing a patient a string like
  /// `"destination_reached_body"` is worse than showing nothing.
  String text(String key) {
    final String? value = values[key];
    assert(value != null, 'GameStrings is missing a value for "$key"');
    return value ?? '';
  }
}
