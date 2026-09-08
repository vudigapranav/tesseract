import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';
import 'package:tesseract_host/games/game_registry.dart';
import 'package:tesseract_host/src/session_controller.dart';

void main() {
  test('host selects touch for Route Quest and tilt for Marble Maze', () {
    final GameConfig route = SessionController(
      registration: gameRegistry.first,
      level: 1,
      isTutorial: false,
    ).buildConfig(textScale: 1);
    final GameConfig maze = SessionController(
      registration: gameRegistry.elementAt(1),
      level: 1,
      isTutorial: false,
    ).buildConfig(textScale: 1);

    expect(route.inputMode, GameInputMode.touch);
    expect(maze.inputMode, GameInputMode.tilt);
  });
}
