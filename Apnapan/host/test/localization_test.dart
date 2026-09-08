import 'dart:convert';
import 'dart:io';
import 'package:tesseract_host/src/data/reminder_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tesseract_host/l10n/app_localizations.dart';
import 'package:tesseract_host/src/caregiver/about_screen.dart';
import 'package:tesseract_host/src/caregiver/sign_in_screen.dart';
import 'package:tesseract_host/src/data/local_repository.dart';
import 'package:tesseract_host/src/default_content.dart';
import 'package:tesseract_host/src/design_system.dart';
import 'package:tesseract_host/src/host_flow_state.dart';
import 'package:tesseract_host/src/l10n/language_catalogue.dart';
import 'package:tesseract_host/src/l10n/language_selector.dart';

/// Localization behaviour.
///
/// The point of the coverage test is that the numbers shown to a caregiver
/// are measured from the actual ARB files, so a language cannot drift into
/// claiming more completeness than it has.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Map<String, dynamic> readArb(String code) => jsonDecode(
        File('lib/l10n/app_$code.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  /// Keys that must never be translated, read from the template's own
  /// `x-untranslatable` markers rather than hard-coded here, so the ARB file
  /// stays the single source of truth.
  Set<String> untranslatableKeys(Map<String, dynamic> template) =>
      template.entries
          .where((MapEntry<String, dynamic> e) =>
              e.key.startsWith('@') &&
              e.value is Map &&
              (e.value as Map)['x-untranslatable'] == true)
          .map((MapEntry<String, dynamic> e) => e.key.substring(1))
          .toSet();

  List<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((String k) => !k.startsWith('@')).toList();

  group('coverage is measured, not asserted', () {
    late Map<String, dynamic> template;
    late Set<String> untranslatable;
    late List<String> denominator;

    setUp(() {
      template = readArb('en');
      untranslatable = untranslatableKeys(template);
      denominator = messageKeys(template)
          .where((String k) => !untranslatable.contains(k))
          .toList();
    });

    test('every catalogue language has an ARB file', () {
      for (final LanguageOption option in LanguageCatalogue.all) {
        expect(File('lib/l10n/app_${option.code}.arb').existsSync(), isTrue,
            reason: 'missing ARB for ${option.englishName}');
      }
    });

    test('published coverage matches the real files, within rounding', () {
      for (final LanguageOption option in LanguageCatalogue.all) {
        final List<String> present = messageKeys(readArb(option.code));
        // Only keys the template actually asks for count. A stale key left
        // behind after an English string is deleted must not prop a
        // percentage up.
        final int translated =
            denominator.where((String k) => present.contains(k)).length;
        final int actual = ((translated / denominator.length) * 100).round();
        expect(
          option.coveragePercent == actual,
          isTrue,
          reason: '${option.englishName} claims ${option.coveragePercent}% '
              'but the ARB files measure $actual%',
        );
      }
    });

    test('no translation file carries a key English marks untranslatable', () {
      // The product name and the fixed attribution must render in their exact
      // English wording everywhere, which they do by falling through. A
      // locale that redefined one would silently change the attribution.
      for (final LanguageOption option in LanguageCatalogue.all) {
        if (option.code == 'en') continue;
        final List<String> present = messageKeys(readArb(option.code));
        for (final String key in untranslatable) {
          expect(present.contains(key), isFalse,
              reason: '${option.englishName} overrides "$key", which must '
                  'stay exactly as written in English');
        }
      }
    });

    test('no translation is a verbatim copy of the English string', () {
      // Copying English in and counting it as translated is the easiest way
      // to fake coverage, so it is checked rather than trusted. Genuine
      // loanwords are listed explicitly and reviewed as such.
      const Set<String> allowedLoanwords = <String>{
        'roleDoctor',
        'password',
      };
      for (final LanguageOption option in LanguageCatalogue.all) {
        if (option.code == 'en') continue;
        final Map<String, dynamic> arb = readArb(option.code);
        for (final String key in messageKeys(arb)) {
          if (allowedLoanwords.contains(key)) continue;
          if (!template.containsKey(key)) continue;
          expect(arb[key], isNot(template[key]),
              reason: '${option.englishName} "$key" is the English string '
                  'verbatim; either translate it or leave it out so it falls '
                  'back honestly');
        }
      }
    });

    test('every translated string keeps the placeholders English declares', () {
      // A dropped {language} placeholder would render a sentence with a hole
      // in it, and gen-l10n would not catch it across locales.
      final RegExp placeholder = RegExp(r'\{(\w+)\}');
      Set<String> holes(String v) =>
          placeholder.allMatches(v).map((Match m) => m.group(1)!).toSet();
      for (final LanguageOption option in LanguageCatalogue.all) {
        if (option.code == 'en') continue;
        final Map<String, dynamic> arb = readArb(option.code);
        for (final String key in messageKeys(arb)) {
          final Object? en = template[key];
          if (en is! String) continue;
          final Object? tr = arb[key];
          if (tr is! String) continue;
          expect(holes(tr), holes(en),
              reason: '${option.englishName} "$key" changed its placeholders');
        }
      }
    });

    test('only English claims to be natively reviewed', () {
      for (final LanguageOption option in LanguageCatalogue.all) {
        if (option.code == 'en') {
          expect(option.reviewStatus, ReviewStatus.native);
        } else {
          // Nothing has been checked by a fluent speaker yet. A language must
          // not silently promote itself.
          expect(option.reviewStatus, ReviewStatus.draft,
              reason: '${option.englishName} claims native review');
        }
      }
    });

    test('no language below full coverage is presented as complete', () {
      for (final LanguageOption option in LanguageCatalogue.all) {
        if (option.coveragePercent < 100) {
          expect(option.isTextComplete, isFalse);
          expect(option.isDraft, isTrue);
        }
      }
    });

    test('full text coverage still does not imply fluent-speaker review', () {
      // Assamese and Bengali reached 100% of the strings in this pass. That
      // is a count, not an endorsement, and the UI must keep saying draft
      // until a named fluent speaker has actually read them.
      for (final LanguageOption option in LanguageCatalogue.all) {
        if (option.code == 'en') continue;
        if (option.isTextComplete) {
          expect(option.isDraft, isTrue,
              reason: '${option.englishName} is fully written but has not '
                  'been reviewed; it must still present as a draft');
        }
      }
    });

    test('each language shows its own name in its own script', () {
      for (final LanguageOption option in LanguageCatalogue.all) {
        expect(option.endonym.trim(), isNotEmpty);
      }
      // The three non-Latin/self-named ones must not just repeat English.
      expect(LanguageCatalogue.byCode('bn').endonym, isNot('Bengali'));
      expect(LanguageCatalogue.byCode('as').endonym, isNot('Assamese'));
      expect(LanguageCatalogue.byCode('mni').endonym, isNot('Meitei'));
    });

    test('the uncovered NE states are named rather than hidden', () {
      expect(LanguageCatalogue.uncoveredRegions, contains('Nagaland'));
      expect(LanguageCatalogue.uncoveredRegions, contains('Tripura'));
      expect(LanguageCatalogue.uncoveredRegions, contains('Sikkim'));
      expect(LanguageCatalogue.uncoveredRegions, contains('Arunachal Pradesh'));
    });
  });

  test('notification text uses patient locale with safe English fallback', () {
    expect(
        ReminderService.notificationStrings('bn').reminderNotificationTitle,
        isNot(ReminderService.notificationStrings('en')
            .reminderNotificationTitle));
    expect(
        ReminderService.notificationStrings('unknown')
            .reminderNotificationTitle,
        ReminderService.notificationStrings('en').reminderNotificationTitle);
    expect(ReminderService.notificationStrings('mni').reminderNotificationTitle,
        ReminderService.notificationStrings('en').reminderNotificationTitle);
  });

  group('translations actually load', () {
    for (final String code in <String>['en', 'as', 'bn', 'mni', 'kha', 'lus']) {
      test('$code resolves and falls back to English where untranslated', () {
        final AppLocalizations l10n = lookupAppLocalizations(Locale(code));
        // A key every language translates.
        expect(l10n.help.trim(), isNotEmpty);
        // A key only some translate: it must still resolve, in English.
        expect(l10n.doctorDisclaimer.trim(), isNotEmpty);
      });
    }

    test('a translated string really differs from English', () {
      final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
      final AppLocalizations bn = lookupAppLocalizations(const Locale('bn'));
      expect(bn.help, isNot(en.help));
      expect(bn.start, isNot(en.start));
    });

    test('an untranslated string falls back to the English text', () {
      final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
      final AppLocalizations lus = lookupAppLocalizations(const Locale('lus'));
      // Mizo has no draft for this one, so it must read as English rather
      // than as an empty string or a crash.
      expect(lus.doctorDisclaimer, en.doctorDisclaimer);
    });
  });

  group('patient language is independent of the interface language', () {
    test('it follows the interface language until set separately', () {
      final HostFlowState flow = HostFlowState();
      flow.interfaceLanguageCode = 'bn';
      expect(flow.effectivePatientLanguageCode, 'bn');
    });

    test('once set, it stays put when the interface language changes', () {
      final HostFlowState flow = HostFlowState();
      flow.interfaceLanguageCode = 'en';
      flow.patientLanguageCode = 'as';
      flow.interfaceLanguageCode = 'bn';
      // The caregiver switching their own language must not silently change
      // what the person playing sees.
      expect(flow.effectivePatientLanguageCode, 'as');
    });

    test('game Help and Break come from the patient language', () {
      final GameStringsProbe probe = GameStringsProbe();
      expect(probe.helpIn('bn'), isNot(probe.helpIn('en')));
      expect(probe.helpIn('as'), isNot(probe.helpIn('en')));
    });

    test('game instructions come from the patient language', () {
      final String en =
          localizedInstructions('en', 'word_search', preferTouch: false);
      final String bn =
          localizedInstructions('bn', 'word_search', preferTouch: false);
      expect(bn, isNot(en));
      expect(bn.trim(), isNotEmpty);
    });

    test('an untranslated game instruction still reads in English', () {
      final String lus =
          localizedInstructions('lus', 'marble_maze', preferTouch: true);
      expect(lus.trim(), isNotEmpty);
    });
  });

  group('persistence', () {
    late Directory tempDir;
    late LocalRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tesseract-l10n');
      repo = await LocalRepository.open(path: '${tempDir.path}/l10n.db');
      await repo.useScope('caregiver-a');
    });

    tearDown(() async {
      await repo.db.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('both languages survive a restart', () async {
      final HostFlowState first = HostFlowState(repository: repo);
      await first.setInterfaceLanguage('bn');
      await first.setPatientLanguage('as');

      final HostFlowState second = HostFlowState(repository: repo);
      await second.restore();

      expect(second.interfaceLanguageCode, 'bn');
      expect(second.patientLanguageCode, 'as');
    });

    test('language is stored per caregiver, not shared', () async {
      final HostFlowState a = HostFlowState(repository: repo);
      await a.setInterfaceLanguage('bn');

      await repo.useScope('caregiver-b');
      final HostFlowState b = HostFlowState(repository: repo);
      await b.restore();
      // A different caregiver on a shared device gets the default, not the
      // first caregiver's choice.
      expect(b.interfaceLanguageCode, 'en');
    });
  });

  group('language selector', () {
    Widget wrap(Widget child, {String locale = 'en'}) => MaterialApp(
          locale: Locale(locale),
          supportedLocales: LanguageCatalogue.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: TesseractDesign.theme,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('lists every language in its own script', (tester) async {
      await tester.pumpWidget(wrap(
        LanguageSelector(selectedCode: 'en', onSelected: (_) {}),
      ));
      await tester.pumpAndSettle();

      for (final LanguageOption option in LanguageCatalogue.all) {
        // English's endonym and English name are the same word, so it can
        // legitimately appear twice on its own row.
        expect(find.text(option.endonym), findsWidgets,
            reason: '\${option.englishName} endonym missing');
      }
    });

    testWidgets('draft languages disclose coverage and review status',
        (tester) async {
      await tester.pumpWidget(wrap(
        LanguageSelector(selectedCode: 'en', onSelected: (_) {}),
      ));
      await tester.pumpAndSettle();

      // Every draft language says so; English does not.
      expect(find.textContaining('Awaiting native review'),
          findsNWidgets(LanguageCatalogue.all.where((o) => o.isDraft).length));
    });

    testWidgets('selecting reports the chosen code', (tester) async {
      String? chosen;
      await tester.pumpWidget(wrap(
        LanguageSelector(
            selectedCode: 'en', onSelected: (String c) => chosen = c),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('বাংলা'));
      await tester.pumpAndSettle();
      expect(chosen, 'bn');
    });

    testWidgets('the draft banner appears only for draft languages',
        (tester) async {
      await tester
          .pumpWidget(wrap(const DraftLanguageBanner(languageCode: 'en')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Draft translation'), findsNothing);

      await tester.pumpWidget(
          wrap(const DraftLanguageBanner(languageCode: 'bn'), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Draft translation'), findsOneWidget);
    });
  });

  group('sign-in language switching', () {
    testWidgets('a language can be chosen before signing in', (tester) async {
      final HostFlowState flow = HostFlowState();
      await tester.pumpWidget(MaterialApp(
        locale: Locale(flow.interfaceLanguageCode),
        supportedLocales: LanguageCatalogue.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: TesseractDesign.theme,
        home: SignInScreen(flowState: flow),
      ));
      await tester.pumpAndSettle();

      // The current language is shown in its own script, before any auth.
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();
      expect(find.text('বাংলা'), findsOneWidget);
    });

    testWidgets('switching language does not clear what was typed',
        (tester) async {
      final HostFlowState flow = HostFlowState();
      await tester.pumpWidget(MaterialApp(
        locale: Locale(flow.interfaceLanguageCode),
        supportedLocales: LanguageCatalogue.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: TesseractDesign.theme,
        home: SignInScreen(flowState: flow),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).first, 'someone@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();
      await tester.tap(find.text('বাংলা'));
      await tester.pumpAndSettle();

      // The form survives the switch: no restart, no lost entry.
      expect(find.text('someone@example.com'), findsOneWidget);
      expect(flow.interfaceLanguageCode, 'bn');
    });
  });

  group('About Tesseract', () {
    testWidgets('shows the exact attribution and no invented people',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: LanguageCatalogue.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: TesseractDesign.theme,
        home: const AboutScreen(),
      ));
      // Not pumpAndSettle: the version lookup shows a spinner until platform
      // metadata resolves, which never happens in a widget test. Pump past
      // the lookup's own timeout so it resolves to a dash and leaves no
      // pending timer behind.
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Built and developed by the Tesseract Team.'),
          findsOneWidget);
      expect(find.text('Tesseract'), findsOneWidget);

      // Every language's status is disclosed here too, further down the page.
      await tester.scrollUntilVisible(find.textContaining('Nagaland'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(find.textContaining('Nagaland'), findsOneWidget);
    });
  });
}

/// Small helper so the game-boundary test reads clearly.
class GameStringsProbe {
  String helpIn(String code) => localizedGameStrings(code).helpButtonLabel;
}
