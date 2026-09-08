import 'package:flutter/widgets.dart';

import 'game_config.dart';
import 'game_event.dart';
import 'game_result.dart';

/// Base class every Tesseract game implements.
///
/// A game is a self-contained widget. It never touches network, database,
/// auth, storage, navigation or shared preferences — it receives everything
/// through [config] and reports everything through [onEvent] and [onFinish].
///
/// A game draws its own pause overlay (triggered by its own Break control,
/// or by [TesseractGameStateMixin] on backgrounding); the host owns
/// how-to-play and finished screens around it.
///
/// A game implementation must also expose a static
/// `Map<String, Object?> difficultyParamsForLevel(int level)` that the host
/// calls to populate [GameConfig.difficultyParams] — Dart has no way to
/// require a static method through an abstract class, so this is a
/// documented convention, not something the type system enforces.
abstract class TesseractGame extends StatefulWidget {
  const TesseractGame({
    super.key,
    required this.config,
    required this.onEvent,
    required this.onFinish,
  });

  /// This session's frozen configuration.
  final GameConfig config;

  /// Called for every [GameEvent] this session emits, in emission order.
  final void Function(GameEvent event) onEvent;

  /// Called exactly once, when the session ends.
  final void Function(GameResult result) onFinish;
}
