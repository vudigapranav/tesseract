import 'package:flutter/widgets.dart';

/// How far along a language actually is.
///
/// Nothing here is aspirational. `coveragePercent` is measured from the ARB
/// files by `flutter gen-l10n`'s untranslated-messages report, and a test
/// recomputes it so these numbers cannot drift away from the real files.
enum ReviewStatus {
  /// Written by a fluent speaker, or the source language.
  native,

  /// Machine-drafted. Usable, but must be shown as a draft until a fluent
  /// speaker has checked it.
  draft,
}

@immutable
class LanguageOption {
  const LanguageOption({
    required this.locale,
    required this.endonym,
    required this.englishName,
    required this.coveragePercent,
    required this.reviewStatus,
    required this.script,
    this.region,
  });

  final Locale locale;

  /// The language's name in its own script, so a speaker can recognise it
  /// without reading English.
  final String endonym;

  final String englishName;

  /// Percentage of the English string set that is translated. The remainder
  /// falls back to English, which the UI discloses.
  final int coveragePercent;

  final ReviewStatus reviewStatus;

  /// Writing system, for the font fallback and for the script-rendering
  /// checks that still need a real device.
  final String script;

  /// Where the language is chiefly spoken. Shown so a caregiver can find
  /// theirs — **not** a claim that one language represents a whole state.
  final String? region;

  bool get isDraft => reviewStatus == ReviewStatus.draft;
  bool get isComplete => coveragePercent >= 100;

  String get code => locale.languageCode;
}

/// The languages this build ships.
///
/// Confirmed by the user on 2026-09-08 from the list named in the project
/// records: English plus Assamese, Bengali, Meitei, Khasi and Mizo.
///
/// **This does not cover the North Eastern Region.** These five reach four of
/// the eight states; Nagaland, Tripura, Arunachal Pradesh and Sikkim have no
/// language here at all. That gap is deliberate and recorded rather than
/// papered over, and no language here should be read as representing an
/// entire state.
abstract final class LanguageCatalogue {
  static const List<LanguageOption> all = <LanguageOption>[
    LanguageOption(
      locale: Locale('en'),
      endonym: 'English',
      englishName: 'English',
      coveragePercent: 100,
      reviewStatus: ReviewStatus.native,
      script: 'Latin',
    ),
    LanguageOption(
      locale: Locale('as'),
      endonym: 'অসমীয়া',
      englishName: 'Assamese',
      coveragePercent: 73,
      reviewStatus: ReviewStatus.draft,
      script: 'Bengali-Assamese',
      region: 'Assam',
    ),
    LanguageOption(
      locale: Locale('bn'),
      endonym: 'বাংলা',
      englishName: 'Bengali',
      coveragePercent: 73,
      reviewStatus: ReviewStatus.draft,
      script: 'Bengali-Assamese',
      region: 'Assam, Tripura',
    ),
    LanguageOption(
      locale: Locale('mni'),
      endonym: 'ꯃꯤꯇꯩꯂꯣꯟ',
      englishName: 'Meitei (Manipuri)',
      coveragePercent: 10,
      reviewStatus: ReviewStatus.draft,
      script: 'Meetei Mayek',
      region: 'Manipur',
    ),
    LanguageOption(
      locale: Locale('kha'),
      endonym: 'Ka Ktien Khasi',
      englishName: 'Khasi',
      coveragePercent: 10,
      reviewStatus: ReviewStatus.draft,
      script: 'Latin',
      region: 'Meghalaya',
    ),
    LanguageOption(
      locale: Locale('lus'),
      endonym: 'Mizo ṭawng',
      englishName: 'Mizo',
      coveragePercent: 10,
      reviewStatus: ReviewStatus.draft,
      script: 'Latin',
      region: 'Mizoram',
    ),
  ];

  static List<Locale> get supportedLocales =>
      all.map((LanguageOption o) => o.locale).toList(growable: false);

  static LanguageOption byCode(String code) => all.firstWhere(
        (LanguageOption o) => o.code == code,
        orElse: () => all.first,
      );

  /// Fonts that must be available for the bundled scripts.
  ///
  /// Latin is covered by Roboto. Bengali-Assamese and Meetei Mayek are
  /// bundled because an entry-level Android device may not ship them, and a
  /// missing font shows as empty boxes rather than as an error.
  static const List<String> fontFallback = <String>[
    'NotoSansBengali',
    'NotoSansMeeteiMayek',
  ];

  /// States of the North Eastern Region with no language in this build.
  /// Named so the gap stays visible in the UI and in review.
  static const List<String> uncoveredRegions = <String>[
    'Nagaland',
    'Tripura',
    'Arunachal Pradesh',
    'Sikkim',
  ];
}
