import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

void main() {
  group('GameResult', () {
    test('accepts every documented status', () {
      for (final status in GameResultStatus.values) {
        expect(
          () => GameResult(status: status, finalSeq: 1, assisted: false),
          returnsNormally,
        );
      }
    });

    test('throws ArgumentError, not an assert, for an invalid status', () {
      // In every build mode, not only debug.
      expect(
        () => GameResult(status: 'won', finalSeq: 1, assisted: false),
        throwsArgumentError,
      );
    });
  });
}
