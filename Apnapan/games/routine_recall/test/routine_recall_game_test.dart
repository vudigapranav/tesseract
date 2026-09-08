import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_recall/routine_recall.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Behaviour of the ported Daily Routine Recall.
///
/// The routine text below is deliberately distinctive so the privacy test can
/// assert that none of it reaches a telemetry payload.
void main() {
  const List<String> routineLabels = <String>[
    'Zarquon sunrise',
    'Brushing teeth',
    'Marmalade breakfast',
    'Quixotic walk',
    'Vermilion supper',
  ];

  List<GameItem> routineItems() => <GameItem>[
        for (int i = 0; i < routineLabels.length; i++)
          GameItem(
            id: 'step_${i + 1}',
            label: routineLabels[i],
            extra: const <String, Object?>{'emoji': '🕒'},
          ),
      ];

  GameConfig configFor(int level) => GameConfig(
        gameId: 'routine_recall',
        gameVersion: '0.1.0',
        schemaVersion: '1',
        configVersion: '1',
        contentVersion: '1',
        metricVersion: '1',
        level: level,
        difficultyParams: RoutineRecallGame.difficultyParamsForLevel(level),
        items: routineItems(),
        strings: const GameStrings(
          helpButtonLabel: 'Help',
          breakButtonLabel: 'Break',
          pausedTitle: 'Taking a break',
          pausedBody: 'Take your time.',
          resumeButtonLabel: 'Continue',
          finishNowButtonLabel: 'Finish for now',
          values: <String, String>{},
        ),
        textScale: 1,
        inputMode: GameInputMode.touch,
        showLabels: true,
        locale: 'en',
        isTutorial: false,
      );

  Future<({List<GameEvent> events, List<GameResult> results})> pump(
    WidgetTester tester, {
    int level = 1,
  }) async {
    final List<GameEvent> events = <GameEvent>[];
    final List<GameResult> results = <GameResult>[];
    await tester.pumpWidget(MaterialApp(
      home: RoutineRecallGame(
        config: configFor(level),
        onEvent: events.add,
        onFinish: results.add,
      ),
    ));
    return (events: events, results: results);
  }


  /// Taps text, scrolling it into view first. The play surface scrolls and the
  /// Help/Break bar is pinned over the bottom of it, so a control can be below
  /// the fold exactly as it would be for a real user.
  Future<void> tapText(WidgetTester tester, String text) async {
    final Finder finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  /// The label of the step that actually follows the one on screen.
  String correctNextLabel(int index) => routineLabels[index + 1];

  testWidgets('the session starts with session_started at seq 1',
      (tester) async {
    final record = await pump(tester);
    expect(record.events.first.type, 'session_started');
    expect(record.events.first.seq, 1);
  });

  testWidgets('presenting a step reports only its opaque id', (tester) async {
    final record = await pump(tester);
    final GameEvent presented =
        record.events.firstWhere((e) => e.type == 'step_presented');
    expect(presented.payload['stepId'], 'step_1');
  });

  testWidgets('a correct answer is recorded as a first attempt',
      (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text(correctNextLabel(0)));
    await tester.pump();

    final GameEvent resolved =
        record.events.lastWhere((e) => e.type == 'attempt_resolved');
    expect(resolved.payload['correct'], true);
    expect(resolved.payload['attempt'], 1);
    expect(resolved.payload['chosenId'], 'step_2');
  });

  testWidgets('a wrong answer keeps the question open and counts the attempt',
      (tester) async {
    final record = await pump(tester);
    // Any option that is not the correct next step.
    final String wrong = routineLabels.firstWhere((String label) =>
        label != correctNextLabel(0) &&
        label != routineLabels[0] &&
        find.text(label).evaluate().isNotEmpty);

    await tester.tap(find.text(wrong));
    await tester.pump();

    final GameEvent resolved =
        record.events.lastWhere((e) => e.type == 'attempt_resolved');
    expect(resolved.payload['correct'], false);
    expect(resolved.payload['attempt'], 1);
    // No score, no failure screen: the invitation is to try again.
    expect(find.textContaining('another look'), findsOneWidget);

    await tester.tap(find.text(correctNextLabel(0)));
    await tester.pump();
    final GameEvent second =
        record.events.lastWhere((e) => e.type == 'attempt_resolved');
    expect(second.payload['correct'], true);
    // Second attempt: first-attempt accuracy stays distinguishable.
    expect(second.payload['attempt'], 2);
  });

  testWidgets('no personal routine text ever reaches a payload',
      (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text(correctNextLabel(0)));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    final String serialised = jsonEncode(
        record.events.map((GameEvent e) => e.payload).toList());
    for (final String label in routineLabels) {
      expect(serialised.contains(label), isFalse,
          reason: '"$label" leaked into telemetry');
    }
  });

  testWidgets('Help marks the session assisted', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();

    expect(record.events.any((e) => e.type == 'hint_requested'), isTrue);

    // Finish and confirm the result carries the assisted flag.
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.tap(find.text('Finish for now'));
    await tester.pump();
    expect(record.results.single.assisted, isTrue);
  });

  testWidgets('Break pauses and Continue resumes', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.text('Taking a break'), findsOneWidget);
    expect(record.events.last.type, 'paused');

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(record.events.last.type, 'resumed');
  });

  testWidgets('playing to the end completes exactly once', (tester) async {
    final record = await pump(tester, level: 1);
    // Level 1 uses three steps, so two questions.
    for (int i = 0; i < 2; i++) {
      await tapText(tester, correctNextLabel(i));
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tapText(tester, 'Continue');
      }
    }

    expect(record.results, hasLength(1));
    expect(record.results.single.status, GameResultStatus.completed);
    expect(record.events.any((e) => e.type == 'routine_completed'), isTrue);
    expect(record.events.where((e) => e.type == 'session_finished'),
        hasLength(1));
  });

  testWidgets('sequence numbers stay contiguous', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text(correctNextLabel(0)));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    for (int i = 0; i < record.events.length; i++) {
      expect(record.events[i].seq, i + 1);
    }
  });

  testWidgets('the final result matches the last emitted sequence',
      (tester) async {
    final record = await pump(tester);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.tap(find.text('Finish for now'));
    await tester.pump();

    expect(record.results.single.finalSeq, record.events.last.seq);
    expect(record.events.last.type, 'session_finished');
  });

  testWidgets('difficulty params describe real settings, not a level number',
      (tester) async {
    expect(RoutineRecallGame.difficultyParamsForLevel(1)['stepCount'], 3);
    expect(RoutineRecallGame.difficultyParamsForLevel(3)['optionCount'], 3);
  });
}
