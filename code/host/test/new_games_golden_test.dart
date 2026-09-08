import 'package:flutter_test/flutter_test.dart';
import 'package:picture_sorting/picture_sorting.dart';
import 'package:routine_recall/routine_recall.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';
import 'package:tesseract_host/src/caregiver/sign_in_screen.dart';
import 'package:tesseract_host/src/content/know_me_content.dart';
import 'package:tesseract_host/src/default_content.dart';
import 'package:tesseract_host/src/host_flow_state.dart';
import 'package:word_search/word_search.dart';

import 'test_helpers.dart';

/// Screenshots of the newly integrated activities and the role sign-in.
///
/// The three games are rendered through the host's own content pipeline, so
/// these show what a patient actually gets — including the shared Help/Break
/// chrome — rather than a hand-built fixture.
void main() {
  setUpAll(loadAppFonts);

  HostFlowState flowWithContent() {
    final HostFlowState flow = HostFlowState();
    flow.knowMeWords.addAll(<String>['CHAI', 'GARDEN', 'TEMPLE', 'RADIO']);
    flow.knowMePeoplePlaces.add(KnowMeItem(label: 'Daughter'));
    return flow;
  }

  GameConfig configFor(
    String gameId,
    int level,
    Map<String, Object?> difficulty,
    HostFlowState flow,
  ) =>
      GameConfig(
        gameId: gameId,
        gameVersion: '0.1.0',
        schemaVersion: '1',
        configVersion: '1',
        contentVersion: '1',
        metricVersion: '1',
        level: level,
        difficultyParams: difficulty,
        items: KnowMeContent.itemsFor(flow, gameId),
        strings: defaultGameStrings(),
        textScale: 1.0,
        inputMode: GameInputMode.touch,
        showLabels: true,
        locale: 'en',
      );

  testWidgets('Word Search with the caregiver\'s own words', (tester) async {
    final HostFlowState flow = flowWithContent();
    await pumpForGolden(
      tester,
      WordSearchGame(
        config: configFor('word_search', 1,
            WordSearchGame.difficultyParamsForLevel(1), flow),
        onEvent: (_) {},
        onFinish: (_) {},
      ),
    );
    await expectLater(find.byType(WordSearchGame),
        matchesGoldenFile('goldens/word_search_level1.png'));
  });

  testWidgets('Daily Routine asks what comes next', (tester) async {
    final HostFlowState flow = flowWithContent();
    await pumpForGolden(
      tester,
      RoutineRecallGame(
        config: configFor('routine_recall', 1,
            RoutineRecallGame.difficultyParamsForLevel(1), flow),
        onEvent: (_) {},
        onFinish: (_) {},
      ),
    );
    await expectLater(find.byType(RoutineRecallGame),
        matchesGoldenFile('goldens/routine_recall_level1.png'));
  });

  testWidgets('Picture Sorting offers its groups', (tester) async {
    final HostFlowState flow = flowWithContent();
    await pumpForGolden(
      tester,
      PictureSortingGame(
        config: configFor('picture_sorting', 1,
            PictureSortingGame.difficultyParamsForLevel(1), flow),
        onEvent: (_) {},
        onFinish: (_) {},
      ),
    );
    await expectLater(find.byType(PictureSortingGame),
        matchesGoldenFile('goldens/picture_sorting_level1.png'));
  });

  testWidgets('Sign in offers caregiver and doctor roles', (tester) async {
    await pumpForGolden(tester, SignInScreen(flowState: HostFlowState()));
    await expectLater(find.byType(SignInScreen),
        matchesGoldenFile('goldens/sign_in_roles.png'));
  });

  testWidgets('Sign in at textScale 2.0 still reads', (tester) async {
    await pumpForGolden(tester, SignInScreen(flowState: HostFlowState()),
        textScale: 2.0);
    await expectLater(find.byType(SignInScreen),
        matchesGoldenFile('goldens/sign_in_roles_textscale_2x.png'));
  });
}
