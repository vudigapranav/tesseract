import 'package:flutter/material.dart';
import 'package:marble_maze/marble_maze.dart';
import 'package:route_quest/route_quest.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// To Aryan and Ruthika, when your games are ready:
///
/// Adding a game to the host is appending ONE [GameRegistration] entry to
/// [gameRegistry] below. Nothing else in the host changes — not Home, not
/// Choose Activity (it reads this list), not the session plumbing. If
/// wiring your game in seems to need touching any other host file, that's a
/// bug in this registry, not a requirement of your game.
///
/// You need, from your own package: your `TesseractGame` widget's
/// constructor, and your `difficultyParamsForLevel` static method (every
/// game exposes one — see the doc comment on `TesseractGame` in
/// `tesseract_game_contract` if that's new to you).
class GameRegistration {
  const GameRegistration({
    required this.gameId,
    required this.gameVersion,
    required this.displayNameKey,
    required this.icon,
    required this.builder,
    required this.difficultyParamsFor,
    required this.supportedLocales,
  });

  /// Stable identifier, matches `GameConfig.gameId`.
  final String gameId;

  /// Recorded in `GameConfig.gameVersion` and every wrapped event.
  final String gameVersion;

  /// A key into `HostStrings.displayName` — not a hardcoded literal, so a
  /// real localisation source can replace the lookup later without
  /// touching this registry.
  final String displayNameKey;

  /// Shown on the Choose Activity card and the How to Play screen.
  final IconData icon;

  /// Builds this game's widget. Almost always just the constructor itself,
  /// for example `RouteQuestGame.new`.
  final TesseractGame Function({
    required GameConfig config,
    required void Function(GameEvent event) onEvent,
    required void Function(GameResult result) onFinish,
  }) builder;

  /// The game's own `difficultyParamsForLevel` static method — the host
  /// calls this to record real settings in the session snapshot, never
  /// just the level number.
  final Map<String, Object?> Function(int level) difficultyParamsFor;

  /// BCP-47 locale tags this game has content/strings for.
  final List<String> supportedLocales;
}

/// Route Quest and Marble Maze are the first two entries. Append; don't
/// rewire.
const List<GameRegistration> gameRegistry = <GameRegistration>[
  GameRegistration(
    gameId: 'route_quest',
    gameVersion: '0.1.0',
    displayNameKey: 'route_quest_name',
    icon: Icons.route,
    builder: RouteQuestGame.new,
    difficultyParamsFor: RouteQuestGame.difficultyParamsForLevel,
    supportedLocales: <String>['en'],
  ),
  GameRegistration(
    gameId: 'marble_maze',
    gameVersion: '0.1.0',
    displayNameKey: 'marble_maze_name',
    icon: Icons.circle,
    builder: MarbleMazeGame.new,
    difficultyParamsFor: MarbleMazeGame.difficultyParamsForLevel,
    supportedLocales: <String>['en'],
  ),
];
