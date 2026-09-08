import 'package:flutter_test/flutter_test.dart';
import 'package:marble_maze/marble_maze.dart';
import 'package:marble_maze/src/maze_view.dart';
import 'package:route_quest/route_quest.dart';
import 'package:route_quest/src/route_map_view.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';
import 'package:tesseract_host/games/game_registry.dart';
import 'package:tesseract_host/src/choose_game_screen.dart';
import 'package:tesseract_host/src/default_content.dart';
import 'package:tesseract_host/src/finished_screen.dart';
import 'package:tesseract_host/src/home_screen.dart';
import 'package:tesseract_host/src/host_flow_state.dart';
import 'package:tesseract_host/src/how_to_play_screen.dart';
import 'package:tesseract_host/src/play_screen.dart';
import 'package:tesseract_host/src/rest_screen.dart';

import 'test_helpers.dart';

GameConfig _routeQuestConfig(int level) => GameConfig(
      gameId: 'route_quest',
      gameVersion: '0.1.0',
      schemaVersion: '1',
      configVersion: '1',
      contentVersion: '1',
      metricVersion: '1',
      level: level,
      difficultyParams: RouteQuestGame.difficultyParamsForLevel(level),
      items: defaultGameItems(),
      strings: defaultGameStrings(),
      textScale: 1.0,
      inputMode: GameInputMode.touch,
      showLabels: true,
      locale: 'en',
    );

GameConfig _marbleMazeConfig(int level) => GameConfig(
      gameId: 'marble_maze',
      gameVersion: '0.1.0',
      schemaVersion: '1',
      configVersion: '1',
      contentVersion: '1',
      metricVersion: '1',
      level: level,
      difficultyParams: MarbleMazeGame.difficultyParamsForLevel(level),
      items: const <GameItem>[],
      strings: defaultGameStrings(),
      textScale: 1.0,
      inputMode: GameInputMode.touch,
      showLabels: true,
      locale: 'en',
    );

void main() {
  setUpAll(loadAppFonts);

  group('Host screens (one golden each, plus textScale 2.0)', () {
    testWidgets('Home', (WidgetTester tester) async {
      await pumpForGolden(tester, HomeScreen(flowState: HostFlowState()));
      await expectLater(
          find.byType(HomeScreen), matchesGoldenFile('goldens/home.png'));
    });

    testWidgets('Home at textScale 2.0', (WidgetTester tester) async {
      await pumpForGolden(tester, HomeScreen(flowState: HostFlowState()),
          textScale: 2.0);
      await expectLater(find.byType(HomeScreen),
          matchesGoldenFile('goldens/home_textscale_2x.png'));
    });

    testWidgets('ChooseGame', (WidgetTester tester) async {
      await pumpForGolden(tester, ChooseGameScreen(flowState: HostFlowState()));
      await expectLater(find.byType(ChooseGameScreen),
          matchesGoldenFile('goldens/choose_game.png'));
    });

    testWidgets('ChooseGame at textScale 2.0', (WidgetTester tester) async {
      await pumpForGolden(tester, ChooseGameScreen(flowState: HostFlowState()),
          textScale: 2.0);
      await expectLater(
        find.byType(ChooseGameScreen),
        matchesGoldenFile('goldens/choose_game_textscale_2x.png'),
      );
    });

    testWidgets('HowToPlay', (WidgetTester tester) async {
      await pumpForGolden(
          tester,
          HowToPlayScreen(
              flowState: HostFlowState(), registration: gameRegistry.first));
      await expectLater(find.byType(HowToPlayScreen),
          matchesGoldenFile('goldens/how_to_play.png'));
    });

    testWidgets('HowToPlay at textScale 2.0', (WidgetTester tester) async {
      await pumpForGolden(
        tester,
        HowToPlayScreen(
            flowState: HostFlowState(), registration: gameRegistry.first),
        textScale: 2.0,
      );
      await expectLater(find.byType(HowToPlayScreen),
          matchesGoldenFile('goldens/how_to_play_textscale_2x.png'));
    });

    testWidgets('Play (hosts Route Quest) at textScale 2.0',
        (WidgetTester tester) async {
      await pumpForGolden(
        tester,
        PlayScreen(
            flowState: HostFlowState(),
            registration: gameRegistry.first,
            level: 1,
            isTutorial: false),
        textScale: 2.0,
      );
      await expectLater(find.byType(PlayScreen),
          matchesGoldenFile('goldens/play_textscale_2x.png'));
    });

    testWidgets('Finished', (WidgetTester tester) async {
      final HostFlowState flow = HostFlowState()..completedActivitiesCount = 1;
      await pumpForGolden(tester,
          FinishedScreen(flowState: flow, registration: gameRegistry.first));
      await expectLater(find.byType(FinishedScreen),
          matchesGoldenFile('goldens/finished.png'));
    });

    testWidgets('Finished at textScale 2.0', (WidgetTester tester) async {
      final HostFlowState flow = HostFlowState()..completedActivitiesCount = 1;
      await pumpForGolden(tester,
          FinishedScreen(flowState: flow, registration: gameRegistry.first),
          textScale: 2.0);
      await expectLater(find.byType(FinishedScreen),
          matchesGoldenFile('goldens/finished_textscale_2x.png'));
    });

    testWidgets('Finished after Marble Maze', (WidgetTester tester) async {
      final HostFlowState flow = HostFlowState()..completedActivitiesCount = 1;
      await pumpForGolden(
          tester,
          FinishedScreen(
              flowState: flow, registration: gameRegistry.elementAt(1)));
      await expectLater(find.byType(FinishedScreen),
          matchesGoldenFile('goldens/finished_marble_maze.png'));
    });

    testWidgets('Rest', (WidgetTester tester) async {
      await pumpForGolden(tester, RestScreen(flowState: HostFlowState()));
      await expectLater(
          find.byType(RestScreen), matchesGoldenFile('goldens/rest.png'));
    });

    testWidgets('Rest at textScale 2.0', (WidgetTester tester) async {
      await pumpForGolden(tester, RestScreen(flowState: HostFlowState()),
          textScale: 2.0);
      await expectLater(find.byType(RestScreen),
          matchesGoldenFile('goldens/rest_textscale_2x.png'));
    });
  });

  group('Games (level 1, level 3, pause overlay)', () {
    testWidgets('Route Quest level 1', (WidgetTester tester) async {
      await pumpForGolden(
          tester,
          RouteQuestGame(
              config: _routeQuestConfig(1), onEvent: (_) {}, onFinish: (_) {}));
      await expectLater(find.byType(RouteQuestGame),
          matchesGoldenFile('goldens/route_quest_level1.png'));
    });

    testWidgets('Route Quest level 3', (WidgetTester tester) async {
      await pumpForGolden(
          tester,
          RouteQuestGame(
              config: _routeQuestConfig(3), onEvent: (_) {}, onFinish: (_) {}));
      await expectLater(find.byType(RouteQuestGame),
          matchesGoldenFile('goldens/route_quest_level3.png'));
    });

    testWidgets('Route Quest pause overlay', (WidgetTester tester) async {
      await pumpForGolden(
          tester,
          RouteQuestGame(
              config: _routeQuestConfig(1), onEvent: (_) {}, onFinish: (_) {}));
      await tester.tap(find.text('Break'));
      await tester.pump();
      await expectLater(find.byType(RouteQuestGame),
          matchesGoldenFile('goldens/route_quest_paused.png'));
    });

    testWidgets('Route Quest returning with collected flag',
        (WidgetTester tester) async {
      await pumpForGolden(
        tester,
        RouteQuestGame(
            config: _routeQuestConfig(1), onEvent: (_) {}, onFinish: (_) {}),
      );
      tester.widget<RouteMapView>(find.byType(RouteMapView)).onTapNode(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      tester.widget<RouteMapView>(find.byType(RouteMapView)).onTapNode(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byType(RouteQuestGame),
        matchesGoldenFile('goldens/route_quest_returning.png'),
      );
    });

    testWidgets('Marble Maze level 1', (WidgetTester tester) async {
      await pumpForGolden(
          tester,
          MarbleMazeGame(
              config: _marbleMazeConfig(1), onEvent: (_) {}, onFinish: (_) {}));
      await expectLater(find.byType(MarbleMazeGame),
          matchesGoldenFile('goldens/marble_maze_level1.png'));
    });

    testWidgets('Marble Maze level 3', (WidgetTester tester) async {
      await pumpForGolden(
          tester,
          MarbleMazeGame(
              config: _marbleMazeConfig(3), onEvent: (_) {}, onFinish: (_) {}));
      await expectLater(find.byType(MarbleMazeGame),
          matchesGoldenFile('goldens/marble_maze_level3.png'));
    });

    testWidgets('Marble Maze pause overlay', (WidgetTester tester) async {
      await pumpForGolden(
          tester,
          MarbleMazeGame(
              config: _marbleMazeConfig(1), onEvent: (_) {}, onFinish: (_) {}));
      await tester.tap(find.text('Break'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await expectLater(find.byType(MarbleMazeGame),
          matchesGoldenFile('goldens/marble_maze_paused.png'));
    });

    testWidgets('Marble Maze visible Help route', (WidgetTester tester) async {
      await pumpForGolden(
        tester,
        MarbleMazeGame(
            config: _marbleMazeConfig(1), onEvent: (_) {}, onFinish: (_) {}),
      );
      await tester.tap(find.text('Help'));
      await tester.pump();
      expect(tester.widget<MazeView>(find.byType(MazeView)).showHint, isTrue);
      await expectLater(
        find.byType(MarbleMazeGame),
        matchesGoldenFile('goldens/marble_maze_help.png'),
      );
    });
  });
}
