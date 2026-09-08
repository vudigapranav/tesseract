import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picture_sorting/picture_sorting.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Behaviour of the ported Picture Sorting.
void main() {
  const List<({String label, String emoji, String category})> set =
      <({String label, String emoji, String category})>[
    (label: 'Zarquonfruit', emoji: '🍎', category: 'fruit'),
    (label: 'Marmalapple', emoji: '🍌', category: 'fruit'),
    (label: 'Vermilioncat', emoji: '🐈', category: 'animal'),
    (label: 'Quixoticdog', emoji: '🐕', category: 'animal'),
  ];

  GameConfig configFor(int level) => GameConfig(
        gameId: 'picture_sorting',
        gameVersion: '0.1.0',
        schemaVersion: '1',
        configVersion: '1',
        contentVersion: '1',
        metricVersion: '1',
        level: level,
        difficultyParams: PictureSortingGame.difficultyParamsForLevel(level),
        items: <GameItem>[
          for (int i = 0; i < set.length; i++)
            GameItem(
              id: 'pic_${i + 1}',
              label: set[i].label,
              extra: <String, Object?>{
                'emoji': set[i].emoji,
                'category': set[i].category,
              },
            ),
        ],
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
      home: PictureSortingGame(
        config: configFor(level),
        onEvent: events.add,
        onFinish: results.add,
      ),
    ));
    await tester.pump();
    return (events: events, results: results);
  }

  /// The category of whichever picture is currently shown.
  String currentCategory(WidgetTester tester) {
    for (final ({String label, String emoji, String category}) entry in set) {
      if (find.text(entry.label).evaluate().isNotEmpty) {
        return entry.category;
      }
    }
    fail('no known picture is on screen');
  }

  String otherCategory(String category) =>
      category == 'fruit' ? 'Animal' : 'Fruit';

  testWidgets('the session starts and offers the categories', (tester) async {
    final record = await pump(tester);
    expect(record.events.first.type, 'session_started');
    expect(find.text('Fruit'), findsOneWidget);
    expect(find.text('Animal'), findsOneWidget);
  });

  testWidgets('a correct choice records the opaque ids and the attempt',
      (tester) async {
    final record = await pump(tester);
    final String category = currentCategory(tester);
    await tester.tap(find.text(category == 'fruit' ? 'Fruit' : 'Animal'));
    await tester.pump();

    final GameEvent sorted =
        record.events.lastWhere((e) => e.type == 'item_sorted');
    expect(sorted.payload['correct'], true);
    expect(sorted.payload['attempt'], 1);
    expect((sorted.payload['itemId'] as String).startsWith('pic_'), isTrue);
    expect(sorted.payload['categoryId'], category);
  });

  testWidgets('a wrong choice invites another try and counts the attempt',
      (tester) async {
    final record = await pump(tester);
    final String category = currentCategory(tester);

    await tester.tap(find.text(otherCategory(category)));
    await tester.pump();

    final GameEvent sorted =
        record.events.lastWhere((e) => e.type == 'item_sorted');
    expect(sorted.payload['correct'], false);
    expect(find.textContaining('another look'), findsOneWidget);
    // No score anywhere on screen.
    expect(find.textContaining('Score'), findsNothing);

    await tester.tap(find.text(category == 'fruit' ? 'Fruit' : 'Animal'));
    await tester.pump();
    final GameEvent second =
        record.events.lastWhere((e) => e.type == 'item_sorted');
    expect(second.payload['correct'], true);
    expect(second.payload['attempt'], 2);
  });

  testWidgets('no picture label reaches a payload', (tester) async {
    final record = await pump(tester);
    final String category = currentCategory(tester);
    await tester.tap(find.text(category == 'fruit' ? 'Fruit' : 'Animal'));
    await tester.pump();

    final String serialised =
        jsonEncode(record.events.map((GameEvent e) => e.payload).toList());
    for (final ({String label, String emoji, String category}) entry in set) {
      expect(serialised.contains(entry.label), isFalse,
          reason: '"${entry.label}" leaked into telemetry');
    }
  });

  testWidgets('Help marks the session assisted', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();
    expect(record.events.any((e) => e.type == 'hint_requested'), isTrue);

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

  testWidgets('sorting every picture completes exactly once', (tester) async {
    final record = await pump(tester, level: 1);

    for (int i = 0; i < 4; i++) {
      if (record.results.isNotEmpty) {
        break;
      }
      final String category = currentCategory(tester);
      final Finder button =
          find.text(category == 'fruit' ? 'Fruit' : 'Animal');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();

      final Finder advance = find.text('Continue').evaluate().isNotEmpty
          ? find.text('Continue')
          : find.text('Finish');
      if (advance.evaluate().isNotEmpty) {
        await tester.ensureVisible(advance);
        await tester.pumpAndSettle();
        await tester.tap(advance);
        await tester.pump();
      }
    }

    expect(record.results, hasLength(1));
    expect(record.results.single.status, GameResultStatus.completed);
    expect(record.events.where((e) => e.type == 'session_finished'),
        hasLength(1));
  });

  testWidgets('sequence numbers stay contiguous', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();
    for (int i = 0; i < record.events.length; i++) {
      expect(record.events[i].seq, i + 1);
    }
  });

  testWidgets('with no categorised pictures it says so', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PictureSortingGame(
        config: GameConfig(
          gameId: 'picture_sorting',
          gameVersion: '0.1.0',
          schemaVersion: '1',
          configVersion: '1',
          contentVersion: '1',
          metricVersion: '1',
          level: 1,
          difficultyParams: PictureSortingGame.difficultyParamsForLevel(1),
          items: const <GameItem>[GameItem(id: 'x', label: 'Uncategorised')],
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
        ),
        onEvent: (_) {},
        onFinish: (_) {},
      ),
    ));
    await tester.pump();
    expect(find.textContaining('no pictures set up'), findsOneWidget);
  });
}
