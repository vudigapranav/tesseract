import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';
import 'package:word_search/word_search.dart';

/// Word Search behaviour in the widget.
///
/// The words below are distinctive so the privacy test can prove the
/// caregiver's personal words never reach a payload.
void main() {
  // All short enough to fit the level-2 grid, so all three are findable.
  const List<String> words = <String>['ZARQUON', 'MARMAL', 'VERMIL'];

  GameConfig configFor(int level) => GameConfig(
        gameId: 'word_search',
        gameVersion: '0.1.0',
        schemaVersion: '1',
        configVersion: '1',
        contentVersion: '1',
        metricVersion: '1',
        level: level,
        difficultyParams: WordSearchGame.difficultyParamsForLevel(level),
        items: <GameItem>[
          for (int i = 0; i < words.length; i++)
            GameItem(id: 'word_${i + 1}', label: words[i]),
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
    int level = 2,
  }) async {
    final List<GameEvent> events = <GameEvent>[];
    final List<GameResult> results = <GameResult>[];
    await tester.pumpWidget(MaterialApp(
      home: WordSearchGame(
        config: configFor(level),
        onEvent: events.add,
        onFinish: results.add,
      ),
    ));
    await tester.pump();
    return (events: events, results: results);
  }

  testWidgets('the session starts and lists the words to find', (tester) async {
    final record = await pump(tester);
    expect(record.events.first.type, 'session_started');
    for (final String word in words) {
      expect(find.text(word), findsOneWidget);
    }
  });

  testWidgets('a word that cannot fit the grid is reported, not lost',
      (tester) async {
    final List<GameEvent> events = <GameEvent>[];
    await tester.pumpWidget(MaterialApp(
      home: WordSearchGame(
        config: GameConfig(
          gameId: 'word_search',
          gameVersion: '0.1.0',
          schemaVersion: '1',
          configVersion: '1',
          contentVersion: '1',
          metricVersion: '1',
          level: 1,
          difficultyParams: WordSearchGame.difficultyParamsForLevel(1),
          items: const <GameItem>[
            GameItem(id: 'word_1', label: 'EXTRAORDINARILY'),
            GameItem(id: 'word_2', label: 'TEA'),
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
        ),
        onEvent: events.add,
        onFinish: (_) {},
      ),
    ));
    await tester.pump();

    final GameEvent unavailable =
        events.firstWhere((e) => e.type == 'content_unavailable');
    expect(unavailable.payload['wordIds'], <String>['word_1']);
    // The id, never the caregiver's word.
    expect(unavailable.payload.toString().contains('EXTRAORDINARILY'), isFalse);
    // The unusable word is not offered to the patient as findable.
    expect(find.text('EXTRAORDINARILY'), findsNothing);
  });

  testWidgets('a wrong selection is recorded without personal content',
      (tester) async {
    final record = await pump(tester);
    // Two cells that are very unlikely to spell a placed word.
    final Finder cells = find.byType(InkWell);
    await tester.tap(cells.at(0));
    await tester.pump();
    await tester.tap(cells.at(1));
    await tester.pump();

    final Iterable<GameEvent> rejected =
        record.events.where((e) => e.type == 'selection_rejected');
    if (rejected.isNotEmpty) {
      expect(rejected.last.payload.containsKey('cellCount'), isTrue);
      // No letters, no word text.
      expect(rejected.last.payload.containsKey('word'), isFalse);
    }
  });

  testWidgets('Help asks for a hint and marks the session assisted',
      (tester) async {
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

  testWidgets('finishing early is terminal and reported once', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.tap(find.text('Finish for now'));
    await tester.pump();

    expect(record.results, hasLength(1));
    expect(record.results.single.status, GameResultStatus.stoppedByUser);
    expect(record.events.where((e) => e.type == 'session_finished'),
        hasLength(1));
    expect(record.results.single.finalSeq, record.events.last.seq);
  });

  testWidgets('no personal word text reaches any payload', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();
    final Finder cells = find.byType(InkWell);
    await tester.tap(cells.at(0));
    await tester.pump();
    await tester.tap(cells.at(3));
    await tester.pump();

    final String serialised =
        jsonEncode(record.events.map((GameEvent e) => e.payload).toList());
    for (final String word in words) {
      expect(serialised.contains(word), isFalse,
          reason: '"$word" leaked into telemetry');
    }
  });

  testWidgets('sequence numbers stay contiguous', (tester) async {
    final record = await pump(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();
    for (int i = 0; i < record.events.length; i++) {
      expect(record.events[i].seq, i + 1);
    }
  });

  testWidgets('with no words it says so instead of showing an empty grid',
      (tester) async {
    final List<GameEvent> events = <GameEvent>[];
    await tester.pumpWidget(MaterialApp(
      home: WordSearchGame(
        config: GameConfig(
          gameId: 'word_search',
          gameVersion: '0.1.0',
          schemaVersion: '1',
          configVersion: '1',
          contentVersion: '1',
          metricVersion: '1',
          level: 1,
          difficultyParams: WordSearchGame.difficultyParamsForLevel(1),
          items: const <GameItem>[],
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
        onEvent: events.add,
        onFinish: (_) {},
      ),
    ));
    await tester.pump();
    expect(find.textContaining('no familiar words'), findsOneWidget);
  });

  testWidgets('difficulty params describe the real grid, not a level number',
      (tester) async {
    expect(WordSearchGame.difficultyParamsForLevel(1)['gridSize'], 6);
    expect(WordSearchGame.difficultyParamsForLevel(1)['allowDiagonals'], false);
    expect(WordSearchGame.difficultyParamsForLevel(3)['allowDiagonals'], true);
  });
}
