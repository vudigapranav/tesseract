import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

GameStrings _strings() => const GameStrings(
  helpButtonLabel: 'Help',
  breakButtonLabel: 'Break',
  pausedTitle: 'Taking a break',
  pausedBody: 'Take your time',
  resumeButtonLabel: 'Continue',
  finishNowButtonLabel: 'Finish for now',
);

GameConfig _configWith({required String inputMode}) => GameConfig(
  gameId: 'route_quest',
  gameVersion: '1.0.0',
  schemaVersion: '1',
  configVersion: '1',
  contentVersion: '1',
  metricVersion: '1',
  level: 1,
  difficultyParams: const <String, Object?>{'nodeCount': 3},
  items: const <GameItem>[],
  strings: _strings(),
  textScale: 1.0,
  inputMode: inputMode,
  showLabels: true,
  locale: 'en',
);

void main() {
  group('GameConfig', () {
    test('accepts a valid inputMode', () {
      expect(() => _configWith(inputMode: GameInputMode.touch), returnsNormally);
      expect(() => _configWith(inputMode: GameInputMode.tilt), returnsNormally);
    });

    test('throws ArgumentError, not an assert, for an invalid inputMode', () {
      // In every build mode, not only debug — this is a release invariant.
      expect(() => _configWith(inputMode: 'joystick'), throwsArgumentError);
    });

    test('carries actual difficulty settings, not just the level number', () {
      final config = _configWith(inputMode: GameInputMode.touch);
      expect(config.level, 1);
      expect(config.difficultyParams, <String, Object?>{'nodeCount': 3});
    });

    test('does not constrain level to any fixed range', () {
      // Level range is a per-game decision, not something this package
      // hardcodes.
      expect(
        () => GameConfig(
          gameId: 'route_quest',
          gameVersion: '1.0.0',
          schemaVersion: '1',
          configVersion: '1',
          contentVersion: '1',
          metricVersion: '1',
          level: 7,
          difficultyParams: const <String, Object?>{},
          items: const <GameItem>[],
          strings: _strings(),
          textScale: 1.0,
          inputMode: GameInputMode.touch,
          showLabels: true,
          locale: 'en',
        ),
        returnsNormally,
      );
    });
  });
}
