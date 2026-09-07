import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

void main() {
  group('GameStrings', () {
    test('text() returns a known value', () {
      const strings = GameStrings(
        helpButtonLabel: 'Help',
        breakButtonLabel: 'Break',
        pausedTitle: 'Taking a break',
        pausedBody: 'Take your time',
        resumeButtonLabel: 'Continue',
        finishNowButtonLabel: 'Finish for now',
        values: <String, String>{'destination_reached_body': 'You made it!'},
      );

      expect(strings.text('destination_reached_body'), 'You made it!');
    });

    test('text() asserts on a missing key, so a missing translation is caught in debug', () {
      const strings = GameStrings(
        helpButtonLabel: 'Help',
        breakButtonLabel: 'Break',
        pausedTitle: 'Taking a break',
        pausedBody: 'Take your time',
        resumeButtonLabel: 'Continue',
        finishNowButtonLabel: 'Finish for now',
      );

      // flutter test runs with assertions enabled, so a miss throws here —
      // this is the debug-mode half of the contract. The release half (an
      // empty string instead of the raw key, once asserts are stripped) is
      // exercised by inspection, not by this suite: an assert firing is,
      // definitionally, code the release build never reaches.
      expect(() => strings.text('missing_key'), throwsA(isA<AssertionError>()));
    });
  });
}
