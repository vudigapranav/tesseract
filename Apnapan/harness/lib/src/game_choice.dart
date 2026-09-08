import 'package:flutter/widgets.dart';
import 'package:marble_maze/marble_maze.dart';
import 'package:route_quest/route_quest.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Everything the harness needs to know about a game to list it, build its
/// [GameConfig.difficultyParams], and instantiate it — the one place that
/// knows about both concrete game packages.
enum GameChoice {
  routeQuest('route_quest', 'Route Quest', '0.1.0'),
  marbleMaze('marble_maze', 'Marble Maze', '0.1.0');

  const GameChoice(this.gameId, this.displayName, this.gameVersion);

  final String gameId;
  final String displayName;
  final String gameVersion;

  Map<String, Object?> difficultyParamsForLevel(int level) {
    return switch (this) {
      GameChoice.routeQuest => RouteQuestGame.difficultyParamsForLevel(level),
      GameChoice.marbleMaze => MarbleMazeGame.difficultyParamsForLevel(level),
    };
  }

  Widget build({
    required GameConfig config,
    required void Function(GameEvent) onEvent,
    required void Function(GameResult) onFinish,
  }) {
    return switch (this) {
      GameChoice.routeQuest => RouteQuestGame(config: config, onEvent: onEvent, onFinish: onFinish),
      GameChoice.marbleMaze => MarbleMazeGame(config: config, onEvent: onEvent, onFinish: onFinish),
    };
  }
}
