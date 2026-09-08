import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_host/src/caregiver/about_screen.dart';
import 'package:tesseract_host/src/caregiver/sign_in_screen.dart';
import 'package:tesseract_host/src/design_system.dart';
import 'package:tesseract_host/src/host_flow_state.dart';
import 'package:tesseract_host/src/l10n/language_catalogue.dart';
import 'package:tesseract_host/src/l10n/language_selector.dart';

import 'test_helpers.dart';

/// Screenshots for script rendering and the language surfaces.
///
/// These are how missing glyphs get caught without a phone: if a bundled font
/// is not reaching the widget tree, the Bengali and Meetei Mayek text renders
/// as empty boxes and it is visible here. They are **not** a substitute for
/// checking on a real Android device, where the system fonts differ.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('Language selector, every script side by side', (tester) async {
    await pumpForGolden(
      tester,
      Scaffold(
        backgroundColor: TesseractDesign.cream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: LanguageSelector(
              selectedCode: 'en',
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byType(LanguageSelector),
        matchesGoldenFile('goldens/language_selector.png'));
  });

  testWidgets('Sign in rendered in Bengali', (tester) async {
    final HostFlowState flow = HostFlowState();
    flow.interfaceLanguageCode = 'bn';
    await pumpForGolden(
      tester,
      SignInScreen(flowState: flow),
      locale: 'bn',
    );
    await expectLater(find.byType(SignInScreen),
        matchesGoldenFile('goldens/sign_in_bengali.png'));
  });

  testWidgets('Sign in rendered in Assamese at large text', (tester) async {
    final HostFlowState flow = HostFlowState();
    flow.interfaceLanguageCode = 'as';
    await pumpForGolden(
      tester,
      SignInScreen(flowState: flow),
      locale: 'as',
      textScale: 1.6,
    );
    await expectLater(find.byType(SignInScreen),
        matchesGoldenFile('goldens/sign_in_assamese_large.png'));
  });

  testWidgets('About Tesseract', (tester) async {
    await pumpForGolden(tester, const AboutScreen(), locale: 'en');
    await tester.pump(const Duration(seconds: 4));
    await expectLater(find.byType(AboutScreen),
        matchesGoldenFile('goldens/about_tesseract.png'));
  });

  test('every catalogue script has a font strategy recorded', () {
    // Latin is Roboto; the other two are bundled. Anything else would render
    // as boxes on a device without a system font for it.
    const Set<String> covered = <String>{
      'Latin',
      'Bengali-Assamese',
      'Meetei Mayek',
    };
    for (final LanguageOption option in LanguageCatalogue.all) {
      expect(covered.contains(option.script), isTrue,
          reason: 'no font strategy for ${option.script}');
    }
  });
}
