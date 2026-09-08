import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tesseract_host/games/game_registry.dart';
import 'package:tesseract_host/l10n/app_localizations.dart';
import 'package:tesseract_host/src/design_system.dart';
import 'package:tesseract_host/src/host_flow_state.dart';
import 'package:tesseract_host/src/how_to_play_screen.dart';
import 'package:tesseract_host/src/speech/speech_settings_section.dart';
import 'package:tesseract_host/src/l10n/language_catalogue.dart';
import 'package:tesseract_host/src/speech/speech_engine.dart';

import 'test_helpers.dart';

/// Renders the speak control against an engine that really answers, so there
/// is visual evidence of what a patient sees — the plain golden runs on a test
/// host with no speech plugin at all, where the honest result is no control.
class GoldenTts implements TtsEngine {
  GoldenTts(this.offered);
  final List<String> offered;

  @override
  Future<List<String>> languages() async => offered;
  @override
  Future<bool> setLanguage(String tag) async => offered.contains(tag);
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<String?> engineName() async => 'golden.engine';
  @override
  Future<void> setSpeechRate(double rate) async {}
}

Future<void> pumpScreen(WidgetTester tester, Widget child,
    {double textScale = 1.0, String locale = 'en'}) async {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: TesseractDesign.theme,
    locale: Locale(locale),
    supportedLocales: LanguageCatalogue.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (BuildContext context, Widget? c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c ?? const SizedBox.shrink()),
    home: child,
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Same faces the other goldens use, so the script actually renders
    // instead of drawing as boxes.
    await loadAppFonts();
  });

  testWidgets('instructions offer Read aloud when the engine has the language',
      (WidgetTester tester) async {
    final HostFlowState flow =
        HostFlowState(ttsEngine: GoldenTts(<String>['en-IN']));
    await pumpScreen(tester,
        HowToPlayScreen(flowState: flow, registration: gameRegistry.first));

    expect(find.text('Read aloud'), findsOneWidget);
    // Begin is still there and still the primary action: speech is additive.
    expect(find.text('Begin'), findsOneWidget);
    await expectLater(find.byType(HowToPlayScreen),
        matchesGoldenFile('goldens/how_to_play_speech.png'));
  });

  testWidgets('an unsupported language says so instead of hiding the feature',
      (WidgetTester tester) async {
    // A Mizo patient on a phone whose engine only has English. The engine
    // *could* pronounce the Latin letters; the app must refuse to.
    final HostFlowState flow =
        HostFlowState(ttsEngine: GoldenTts(<String>['en-IN']))
          ..patientLanguageCode = 'lus';
    await pumpScreen(tester,
        HowToPlayScreen(flowState: flow, registration: gameRegistry.first));

    expect(find.text('Read aloud'), findsNothing);
    expect(find.textContaining('Mizo'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
    await expectLater(find.byType(HowToPlayScreen),
        matchesGoldenFile('goldens/how_to_play_speech_unavailable.png'));
  });

  settingsTests();

  testWidgets('large text keeps the speak control usable',
      (WidgetTester tester) async {
    final HostFlowState flow =
        HostFlowState(ttsEngine: GoldenTts(<String>['bn-IN']))
          ..patientLanguageCode = 'bn';
    await pumpScreen(tester,
        HowToPlayScreen(flowState: flow, registration: gameRegistry.first),
        textScale: 2.0, locale: 'bn');
    await expectLater(find.byType(HowToPlayScreen),
        matchesGoldenFile('goldens/how_to_play_speech_bengali_2x.png'));
  });
}

/// A recogniser that offers only English, matching the realistic case for a
/// phone in the North East today.
class GoldenStt implements SttEngine {
  GoldenStt(this.offered);
  final List<String> offered;

  @override
  bool get isListening => false;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<List<String>> locales() async => offered;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<VoiceInputResult> listenOnce({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
  }) async =>
      const VoiceInputResult.failed(VoiceInputFailure.timeout);
  @override
  Future<void> cancel() async {}
}

void settingsTests() {
  testWidgets('the phone check reports each language and each direction',
      (WidgetTester tester) async {
    final HostFlowState flow = HostFlowState(
      // A common real shape: a voice for Bengali, recognition only for
      // English, nothing at all for the other three.
      ttsEngine: GoldenTts(<String>['en-IN', 'bn-IN']),
      sttEngine: GoldenStt(<String>['en-IN']),
    );
    await pumpScreen(
        tester,
        Scaffold(
            body: SingleChildScrollView(
                child: SpeechSettingsSection(flowState: flow))));

    // Nothing is claimed before the caregiver asks.
    expect(find.text('Not checked on this phone yet'), findsWidgets);

    await tester.tap(find.text('Check what this phone supports'));
    await tester.pumpAndSettle();

    // Two directions reported separately, and they disagree for Bengali —
    // which is the whole reason they are probed separately.
    expect(find.text('Reading aloud: available'), findsNWidgets(2)); // en, bn
    expect(find.text('Speaking to the app: available'), findsOneWidget); // en
    expect(find.text('Reading aloud: not available'), findsNWidgets(4));

    // And the standing caveat, regardless of what came back available.
    expect(
        find.text(
            'Speech has not been checked by a fluent speaker of this language.'),
        findsOneWidget);
  });
}
