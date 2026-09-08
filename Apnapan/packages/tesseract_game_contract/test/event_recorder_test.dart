import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

void main() {
  group('TesseractEventRecorder', () {
    test('seq starts at 1, increments by 1, and is never skipped', () {
      final recorder = TesseractEventRecorder();

      final events = <GameEvent>[
        recorder.sessionStarted(),
        recorder.custom('location_entered', {'nodeId': 'n1'}),
        recorder.hintRequested(),
        recorder.custom('location_entered', {'nodeId': 'n2'}),
        recorder.sessionFinished(GameResultStatus.completed),
      ];

      expect(events.map((e) => e.seq).toList(), <int>[1, 2, 3, 4, 5]);
      expect(recorder.lastSeq, 5);
    });

    test('lifecycle events use the documented type strings', () {
      final recorder = TesseractEventRecorder();

      expect(recorder.sessionStarted().type, 'session_started');
      expect(recorder.tutorialStarted().type, 'tutorial_started');
      expect(recorder.tutorialCompleted().type, 'tutorial_completed');
      expect(recorder.paused().type, 'paused');
      expect(recorder.resumed().type, 'resumed');
      expect(recorder.hintRequested().type, 'hint_requested');
      expect(recorder.supportChanged(setting: 'guide_overlay_on').type,
          'support_changed');
      expect(recorder.sessionFinished(GameResultStatus.completed).type,
          'session_finished');
    });

    test('supportChanged carries the setting that changed', () {
      final recorder = TesseractEventRecorder();
      recorder.sessionStarted();
      final event = recorder.supportChanged(setting: 'guide_overlay_on');
      expect(event.payload['setting'], 'guide_overlay_on');
    });

    test('paused time is excluded from elapsedMs', () async {
      final recorder = TesseractEventRecorder();
      recorder.sessionStarted();

      await Future<void>.delayed(const Duration(milliseconds: 120));
      recorder.paused(reason: 'break');
      final int elapsedAtPause = recorder.elapsedMs;

      // Time passes while paused; none of it should be counted.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(recorder.elapsedMs, elapsedAtPause);

      recorder.resumed();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      recorder.sessionFinished(GameResultStatus.completed);

      // Total active time is ~240ms, not ~440ms. Generous tolerance keeps
      // this test stable under load.
      expect(recorder.elapsedMs, greaterThanOrEqualTo(elapsedAtPause));
      expect(recorder.elapsedMs, lessThan(elapsedAtPause + 200));
    });

    test('hintRequested marks the session assisted; without it, it is not', () {
      final assistedRecorder = TesseractEventRecorder();
      assistedRecorder.sessionStarted();
      expect(assistedRecorder.assisted, isFalse);
      assistedRecorder.hintRequested();
      expect(assistedRecorder.assisted, isTrue);

      final unassistedRecorder = TesseractEventRecorder();
      unassistedRecorder.sessionStarted();
      unassistedRecorder.sessionFinished(GameResultStatus.completed);
      expect(unassistedRecorder.assisted, isFalse);
    });

    test('finishing early still produces a valid, terminal result', () {
      final recorder = TesseractEventRecorder();
      recorder.sessionStarted();
      recorder.custom('location_entered', {'nodeId': 'n1'});
      final finishEvent =
          recorder.sessionFinished(GameResultStatus.stoppedByUser);

      final result = GameResult(
        status: GameResultStatus.stoppedByUser,
        finalSeq: recorder.lastSeq,
        assisted: recorder.assisted,
      );

      expect(finishEvent.payload['status'], GameResultStatus.stoppedByUser);
      expect(result.finalSeq, recorder.lastSeq);
      expect(recorder.isFinished, isTrue);
      // A finished session is not a paused one, even though both stop the
      // clock.
      expect(recorder.isPaused, isFalse);
    });
  });

  group('TesseractEventRecorder invariants (real throws, not asserts)', () {
    test('sessionStarted() twice throws StateError', () {
      final recorder = TesseractEventRecorder();
      recorder.sessionStarted();
      expect(recorder.sessionStarted, throwsStateError);
    });

    test(
        'sessionStarted() after another event has already fired throws StateError',
        () {
      final recorder = TesseractEventRecorder();
      recorder.tutorialStarted();
      expect(recorder.sessionStarted, throwsStateError);
    });

    test('sessionFinished() twice throws StateError', () {
      final recorder = TesseractEventRecorder();
      recorder.sessionStarted();
      recorder.sessionFinished(GameResultStatus.completed);
      expect(() => recorder.sessionFinished(GameResultStatus.completed),
          throwsStateError);
    });

    test('any event emitted after sessionFinished() throws StateError', () {
      final recorder = TesseractEventRecorder();
      recorder.sessionStarted();
      recorder.sessionFinished(GameResultStatus.completed);

      expect(() => recorder.custom('goal_reached'), throwsStateError);
      expect(recorder.hintRequested, throwsStateError);
      expect(recorder.resumed, throwsStateError);
      expect(() => recorder.paused(), throwsStateError);
    });

    test('sessionFinished() with an invalid status throws ArgumentError', () {
      final recorder = TesseractEventRecorder();
      recorder.sessionStarted();
      expect(() => recorder.sessionFinished('won'), throwsArgumentError);
    });
  });
}
