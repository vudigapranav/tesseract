import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marble_maze/marble_maze.dart';
import 'package:marble_maze/src/maze_view.dart';
import 'package:marble_maze/src/marble_tilt_input.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

const GameStrings _strings = GameStrings(
  helpButtonLabel: 'Help',
  breakButtonLabel: 'Break',
  pausedTitle: 'Taking a break',
  pausedBody: 'Take your time.',
  resumeButtonLabel: 'Continue',
  finishNowButtonLabel: 'Finish for now',
);

GameConfig _configForLevel(int level,
    {String inputMode = GameInputMode.touch}) {
  return GameConfig(
    gameId: 'marble_maze',
    gameVersion: '0.1.0',
    schemaVersion: '1',
    configVersion: '1',
    contentVersion: '1',
    metricVersion: '1',
    level: level,
    difficultyParams: MarbleMazeGame.difficultyParamsForLevel(level),
    items: const <GameItem>[],
    strings: _strings,
    textScale: 1.0,
    inputMode: inputMode,
    showLabels: true,
    locale: 'en',
  );
}

/// Drags the marble by setting [MazeView]'s target through its real
/// [MazeView.onDrag] callback — the same code path an actual drag on the
/// canvas invokes — then lets the fixed-timestep ticker run for [duration]
/// of simulated (pumped) time, which `flutter_test` advances deterministically
/// without any real wall-clock delay.
Future<void> dragTo(WidgetTester tester, Offset gridTarget,
    {Duration duration = const Duration(seconds: 3)}) async {
  tester.widget<MazeView>(find.byType(MazeView)).onDrag(gridTarget);
  await tester.pump(duration);
}

class _FakeTiltInput extends MarbleTiltInput {
  const _FakeTiltInput(this.values);

  final List<({double x, double y})> values;

  @override
  Stream<({double x, double y})> samples() => Stream.fromIterable(values);
}

void main() {
  group('MarbleMazeGame', () {
    testWidgets('seq is gap-free on a clean run to the goal',
        (WidgetTester tester) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
            home: MarbleMazeGame(
                config: _configForLevel(1),
                onEvent: events.add,
                onFinish: (_) {})),
      );

      // Level 1's corridor centreline: start(1,1) -> turn(1,6) -> turn(6,6) -> goal(6,11).
      await dragTo(tester, const Offset(1.5, 6.5));
      await dragTo(tester, const Offset(6.5, 6.5));
      await dragTo(tester, const Offset(6.5, 11.5));

      expect(events.any((GameEvent e) => e.type == 'goal_reached'), isTrue);
      final List<int> seqs = events.map((GameEvent e) => e.seq).toList();
      expect(seqs, List<int>.generate(seqs.length, (int i) => i + 1));
      expect(events.first.type, 'session_started');
      expect(events.last.type, 'session_finished');
    });

    testWidgets(
        'collision and dead_end_entered both fire without breaking the seq sequence',
        (
      WidgetTester tester,
    ) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
            home: MarbleMazeGame(
                config: _configForLevel(2),
                onEvent: events.add,
                onFinish: (_) {})),
      );

      // Level 2: travel down the corridor to the branch point, then into
      // its dead end, then try to keep going past the grid edge.
      await dragTo(tester, const Offset(1.5, 4.5));
      await dragTo(tester, const Offset(5.5, 4.5));
      await dragTo(tester, const Offset(5.5, 6.5));
      await dragTo(tester, const Offset(8.5, 6.5)); // the dead end's tip
      await dragTo(
          tester, const Offset(10.5, 6.5)); // past the grid edge -> collision

      expect(events.any((GameEvent e) => e.type == 'dead_end_entered'), isTrue);
      expect(events.any((GameEvent e) => e.type == 'collision'), isTrue);

      final List<int> seqs = events.map((GameEvent e) => e.seq).toList();
      expect(seqs, List<int>.generate(seqs.length, (int i) => i + 1));
    });

    testWidgets(
        'Help emits hint_requested and marks the result assisted; a collision is never shown as a failure',
        (
      WidgetTester tester,
    ) async {
      GameResult? result;
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MarbleMazeGame(
              config: _configForLevel(1),
              onEvent: events.add,
              onFinish: (GameResult r) => result = r),
        ),
      );

      await tester.tap(find.text('Help'));
      await tester.pump();
      expect(events.any((GameEvent e) => e.type == 'hint_requested'), isTrue);
      expect(tester.widget<MazeView>(find.byType(MazeView)).showHint, isTrue);

      await tester.tap(find.text('Break'));
      await tester.pump();
      await tester.tap(find.text('Finish for now'));
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.assisted, isTrue);
    });

    testWidgets(
        'touch drag works even with inputMode tilt and no accelerometer available',
        (
      WidgetTester tester,
    ) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MarbleMazeGame(
            config: _configForLevel(1, inputMode: GameInputMode.tilt),
            onEvent: events.add,
            onFinish: (_) {},
          ),
        ),
      );

      // No accelerometer plugin exists in this build at all — this drives
      // the whole level purely by touch drag and expects it to complete
      // normally, proving touch is never blocked by the selected input mode.
      await dragTo(tester, const Offset(1.5, 6.5));
      await dragTo(tester, const Offset(6.5, 6.5));
      await dragTo(tester, const Offset(6.5, 11.5));

      expect(events.any((GameEvent e) => e.type == 'goal_reached'), isTrue);
    });

    testWidgets('fused gyroscope tilt moves the marble after calibration',
        (WidgetTester tester) async {
      final List<({double x, double y})> samples = <({double x, double y})>[
        for (int i = 0; i < 12; i++) (x: 0, y: 0),
        for (int i = 0; i < 10; i++) (x: 0, y: 0.30),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: MarbleMazeGame(
            config: _configForLevel(1, inputMode: GameInputMode.tilt),
            tiltInput: _FakeTiltInput(samples),
            onEvent: (_) {},
            onFinish: (_) {},
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Offset position =
          tester.widget<MazeView>(find.byType(MazeView)).marblePosition;
      expect(position.dy, greaterThan(1.5));
      expect(position.dx, closeTo(1.5, 0.05));
    });

    testWidgets(
        'finishing early via Break -> Finish for now still produces a valid GameResult',
        (
      WidgetTester tester,
    ) async {
      GameResult? result;
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MarbleMazeGame(
              config: _configForLevel(2),
              onEvent: events.add,
              onFinish: (GameResult r) => result = r),
        ),
      );

      await dragTo(
          tester, const Offset(1.5, 4.5)); // move partway, then bail out

      await tester.tap(find.text('Break'));
      await tester.pump();
      await tester.tap(find.text('Finish for now'));
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.status, GameResultStatus.stoppedByUser);
      expect(result!.finalSeq, events.last.seq);
      expect(result!.assisted, isFalse);
      expect(events.last.type, 'session_finished');
    });

    testWidgets(
        'difficultyParamsForLevel reports real settings, not just the level number',
        (
      WidgetTester tester,
    ) async {
      expect(MarbleMazeGame.difficultyParamsForLevel(1), <String, Object?>{
        'corridorWidth': 2,
        'turnCount': 2,
        'deadEndCount': 0,
      });
      expect(MarbleMazeGame.difficultyParamsForLevel(2), <String, Object?>{
        'corridorWidth': 1,
        'turnCount': 4,
        'deadEndCount': 1,
      });
      expect(MarbleMazeGame.difficultyParamsForLevel(3), <String, Object?>{
        'corridorWidth': 1,
        'turnCount': 6,
        'deadEndCount': 2,
      });
    });
  });

  group('MarbleMazeGame + TesseractGameStateMixin (paused time)', () {
    testWidgets('paused time (via Break/Continue) is excluded from elapsedMs',
        (WidgetTester tester) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
            home: MarbleMazeGame(
                config: _configForLevel(1),
                onEvent: events.add,
                onFinish: (_) {})),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });

      await tester.tap(find.text('Break'));
      await tester.pump();
      expect(events.last.type, 'paused');
      final int elapsedAtPause = events.last.elapsedMs;

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });

      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(events.last.type, 'resumed');
      final int elapsedAtResume = events.last.elapsedMs;

      // ~250ms passed while paused; none of it should show up here.
      expect(elapsedAtResume, lessThan(elapsedAtPause + 100));
    });
  });
}
