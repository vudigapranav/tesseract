import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_quest/route_quest.dart';
import 'package:route_quest/src/route_map_view.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

const GameStrings _strings = GameStrings(
  helpButtonLabel: 'Help',
  breakButtonLabel: 'Break',
  pausedTitle: 'Taking a break',
  pausedBody: 'Take your time.',
  resumeButtonLabel: 'Continue',
  finishNowButtonLabel: 'Finish for now',
);

List<GameItem> _fakeItems(int count) {
  return List<GameItem>.generate(
      count, (int i) => GameItem(id: 'loc_$i', label: 'Location $i'));
}

GameConfig _configForLevel(int level, {List<GameItem>? items}) {
  return GameConfig(
    gameId: 'route_quest',
    gameVersion: '0.1.0',
    schemaVersion: '1',
    configVersion: '1',
    contentVersion: '1',
    metricVersion: '1',
    level: level,
    difficultyParams: RouteQuestGame.difficultyParamsForLevel(level),
    items: items ?? _fakeItems(6),
    strings: _strings,
    textScale: 1.0,
    inputMode: GameInputMode.touch,
    showLabels: true,
    locale: 'en',
  );
}

/// Grabs the current [RouteMapView] and taps node [index] through its real
/// [RouteMapView.onTapNode] callback — the same code path a real tap on the
/// canvas invokes — without depending on pixel geometry, which the "adjacent
/// locations are visibly tappable" rendering rule already covers visually.
void tapNode(WidgetTester tester, int index) {
  tester.widget<RouteMapView>(find.byType(RouteMapView)).onTapNode(index);
}

void main() {
  group('RouteQuestGame', () {
    testWidgets('seq is gap-free across a full playthrough',
        (WidgetTester tester) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RouteQuestGame(
              config: _configForLevel(1),
              onEvent: events.add,
              onFinish: (_) {}),
        ),
      );

      // Level 1 topology: home(0) - mid(1) - destination(2).
      tapNode(tester, 1);
      await tester.pump();
      tapNode(tester, 2); // destination
      await tester.pump();
      tapNode(tester, 1);
      await tester.pump();
      tapNode(tester, 0); // home again -> return_completed

      final List<int> seqs = events.map((GameEvent e) => e.seq).toList();
      expect(seqs, List<int>.generate(seqs.length, (int i) => i + 1));
      expect(events.first.type, 'session_started');
      expect(events.last.type, 'session_finished');
    });

    testWidgets('Help emits hint_requested and marks the result assisted',
        (WidgetTester tester) async {
      GameResult? result;
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RouteQuestGame(
              config: _configForLevel(1),
              onEvent: events.add,
              onFinish: (GameResult r) => result = r),
        ),
      );

      await tester.tap(find.text('Help'));
      await tester.pump();
      expect(events.any((GameEvent e) => e.type == 'hint_requested'), isTrue);

      // Never shown as a failure: Help alone must not stop or alter play.
      tapNode(tester, 1);
      await tester.pump();
      expect(events.any((GameEvent e) => e.type == 'location_entered'), isTrue);

      await tester.tap(find.text('Break'));
      await tester.pump();
      await tester.tap(find.text('Finish for now'));
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.assisted, isTrue);
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
          home: RouteQuestGame(
              config: _configForLevel(2),
              onEvent: events.add,
              onFinish: (GameResult r) => result = r),
        ),
      );

      tapNode(
          tester, 1); // one move, then bail out before reaching the destination
      await tester.pump();

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
        'tapping a non-adjacent location does not move and emits wrong_interaction',
        (
      WidgetTester tester,
    ) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RouteQuestGame(
              config: _configForLevel(2),
              onEvent: events.add,
              onFinish: (_) {}),
        ),
      );

      // Level 2: home(0)'s only neighbour is junction(1) — destination(2) is
      // two hops away, not adjacent.
      tapNode(tester, 2);
      await tester.pump();

      expect(events.where((GameEvent e) => e.type == 'location_entered').length,
          0);
      final GameEvent wrongEvent =
          events.firstWhere((GameEvent e) => e.type == 'wrong_interaction');
      expect(wrongEvent.payload['objectId'], 'loc_2');
    });

    testWidgets('route efficiency is 1.0 on a shortest-path run',
        (WidgetTester tester) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RouteQuestGame(
              config: _configForLevel(1),
              onEvent: events.add,
              onFinish: (_) {}),
        ),
      );

      // Level 1's only path is already the shortest one: home -> mid ->
      // destination -> mid -> home. 2 hops out, 2 hops back.
      tapNode(tester, 1);
      await tester.pump();
      tapNode(tester, 2);
      await tester.pump();
      tapNode(tester, 1);
      await tester.pump();
      tapNode(tester, 0);
      await tester.pump();

      final int actualPathLength =
          events.where((GameEvent e) => e.type == 'location_entered').length;
      const int shortestOneWay =
          2; // computed by BFS at level load — see route_graph_test.dart
      final double efficiency = (shortestOneWay * 2) / actualPathLength;

      expect(events.any((GameEvent e) => e.type == 'return_completed'), isTrue);
      expect(efficiency, 1.0);
    });

    testWidgets(
        'difficultyParamsForLevel reports real settings, not just the level number',
        (
      WidgetTester tester,
    ) async {
      expect(RouteQuestGame.difficultyParamsForLevel(1), <String, Object?>{
        'nodeCount': 3,
        'branchCount': 0,
        'requiresReturn': true,
      });
      expect(RouteQuestGame.difficultyParamsForLevel(2), <String, Object?>{
        'nodeCount': 5,
        'branchCount': 1,
        'requiresReturn': true,
      });
      expect(RouteQuestGame.difficultyParamsForLevel(3), <String, Object?>{
        'nodeCount': 6,
        'branchCount': 2,
        'requiresReturn': true,
      });
    });
  });

  group('RouteQuestGame + TesseractGameStateMixin (paused time)', () {
    testWidgets('paused time (via Break/Continue) is excluded from elapsedMs',
        (WidgetTester tester) async {
      final List<GameEvent> events = <GameEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RouteQuestGame(
              config: _configForLevel(1),
              onEvent: events.add,
              onFinish: (_) {}),
        ),
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
