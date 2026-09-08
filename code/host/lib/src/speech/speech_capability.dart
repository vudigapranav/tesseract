/// What speech actually works, per language.
///
/// Two different things are recorded here and they must never be conflated:
///
/// * [SpeechExpectation] — what published provider documentation says about
///   an engine, gathered by a human reading vendor docs. It is background,
///   not evidence. A language is *never* treated as usable because of it.
/// * [SpeechProbe] — what the engine on the phone in front of the user
///   actually reported when asked. This is the only thing the app routes on.
///
/// Neither of them says the pronunciation is any good. That needs a fluent
/// speaker, which is tracked separately in [PronunciationReview].
library;

import 'package:flutter/foundation.dart';

/// The direction of speech being described.
enum SpeechDirection {
  /// Text-to-speech: the app speaks.
  output,

  /// Speech-to-text: the app listens.
  input,
}

/// What vendor documentation claims. Background only.
enum SpeechExpectation {
  /// Vendor documentation lists this language for this direction.
  documented,

  /// Vendor documentation does not list it. Usually means unavailable, but a
  /// third-party engine the user has installed may still provide it, which is
  /// exactly why the app probes instead of trusting this.
  undocumented,
}

/// Whether a fluent speaker has actually listened to, or spoken into, this.
enum PronunciationReview {
  /// Nobody has checked. This is the honest default and the current value for
  /// every language in this build.
  notReviewed,

  /// A fluent speaker confirmed the output is intelligible / the recogniser
  /// understands them.
  reviewed,

  /// A fluent speaker checked and rejected it.
  rejected,
}

/// One row of the per-language speech matrix, as documented before any device
/// has been consulted.
@immutable
class SpeechLanguageRow {
  const SpeechLanguageRow({
    required this.code,
    required this.englishName,
    required this.script,
    required this.preferredTags,
    required this.outputExpectation,
    required this.inputExpectation,
    required this.notes,
    this.review = PronunciationReview.notReviewed,
  });

  /// The app's language code, matching `LanguageCatalogue`.
  final String code;

  final String englishName;

  final String script;

  /// BCP-47 tags to offer the engine, best first.
  ///
  /// An engine may expose a language under a regional tag only (`bn-IN`) or
  /// under a bare tag (`bn`), and Android engines are inconsistent about
  /// which. The probe tries these in order and records the one that matched,
  /// so the app speaks with the exact tag the engine accepted rather than a
  /// guess.
  final List<String> preferredTags;

  final SpeechExpectation outputExpectation;
  final SpeechExpectation inputExpectation;

  /// Why the expectation is what it is, in plain words, for the handoff doc.
  final String notes;

  final PronunciationReview review;
}

/// The documented starting point for the five North Eastern Region languages
/// this build ships, plus English.
///
/// Sources consulted 2026-09-08: Google's official TalkBack / text-to-speech
/// language list, and Google's Gboard voice-typing documentation. Read the
/// caveats in [SpeechExpectation] before using any of this as a claim.
///
/// The short version, and it is not good news: of the five NER languages,
/// **only Bengali is documented by Google for either direction.** Assamese,
/// Meitei, Khasi and Mizo appear in Google *Translate* and in Gboard's
/// *typing* languages, which is a completely different capability from having
/// a voice or a recogniser. That distinction is the whole reason this file
/// exists.
abstract final class SpeechMatrix {
  static const List<SpeechLanguageRow> rows = <SpeechLanguageRow>[
    SpeechLanguageRow(
      code: 'en',
      englishName: 'English',
      script: 'Latin',
      preferredTags: <String>['en-IN', 'en-US', 'en'],
      outputExpectation: SpeechExpectation.documented,
      inputExpectation: SpeechExpectation.documented,
      notes: 'Universally available on Android. en-IN preferred so the accent '
          'matches the users this app is for.',
    ),
    SpeechLanguageRow(
      code: 'bn',
      englishName: 'Bengali',
      script: 'Bengali-Assamese',
      preferredTags: <String>['bn-IN', 'bn-BD', 'bn'],
      outputExpectation: SpeechExpectation.documented,
      inputExpectation: SpeechExpectation.documented,
      notes: 'The only NER language of the five that Google documents for '
          'both directions. Listed as "Bangla (India)" and "Bangla '
          '(Bangladesh)" in the TalkBack voice list; bn-IN is the right one '
          'here. Voice data may still need an on-device download before it '
          'works offline.',
    ),
    SpeechLanguageRow(
      code: 'as',
      englishName: 'Assamese',
      script: 'Bengali-Assamese',
      preferredTags: <String>['as-IN', 'as'],
      outputExpectation: SpeechExpectation.undocumented,
      inputExpectation: SpeechExpectation.undocumented,
      notes: 'Not in Google\'s TalkBack voice list. Present in Google '
          'Translate and as a Gboard typing language, neither of which is a '
          'voice or a recogniser. Some Google speech-recognition expansions '
          'have covered Assamese, so the probe is worth running, but nothing '
          'here may be presented as supported until a device says so.',
    ),
    SpeechLanguageRow(
      code: 'mni',
      englishName: 'Meitei (Manipuri)',
      script: 'Meetei Mayek',
      preferredTags: <String>['mni-IN', 'mni'],
      outputExpectation: SpeechExpectation.undocumented,
      inputExpectation: SpeechExpectation.undocumented,
      notes: 'No documented Google voice or recogniser. Meetei Mayek script '
          'support is also thin, which is why the app bundles the Noto face. '
          'Expect speech to be unavailable and the text path to carry this '
          'language entirely.',
    ),
    SpeechLanguageRow(
      code: 'kha',
      englishName: 'Khasi',
      script: 'Latin',
      preferredTags: <String>['kha-IN', 'kha'],
      outputExpectation: SpeechExpectation.undocumented,
      inputExpectation: SpeechExpectation.undocumented,
      notes: 'No documented Google voice or recogniser, and not in Google '
          'Translate either. Expect speech to be unavailable.',
    ),
    SpeechLanguageRow(
      code: 'lus',
      englishName: 'Mizo',
      script: 'Latin',
      preferredTags: <String>['lus-IN', 'lus'],
      outputExpectation: SpeechExpectation.undocumented,
      inputExpectation: SpeechExpectation.undocumented,
      notes: 'No documented Google voice or recogniser. In Google Translate '
          'since 2022, which says nothing about speech. Because Mizo is '
          'written in Latin script an English engine will happily read it '
          'aloud as mangled English — that is precisely the silent '
          'substitution this app refuses to do.',
    ),
  ];

  static SpeechLanguageRow? byCode(String code) {
    for (final SpeechLanguageRow row in rows) {
      if (row.code == code) return row;
    }
    return null;
  }

  /// Tags to try for [code], best first. Empty when the language is unknown,
  /// which the services treat as unavailable rather than falling back.
  static List<String> tagsFor(String code) =>
      byCode(code)?.preferredTags ?? const <String>[];
}

/// What an engine on this device actually reported for one language.
@immutable
class SpeechProbe {
  const SpeechProbe({
    required this.code,
    required this.direction,
    required this.available,
    this.resolvedTag,
    this.engine,
  });

  /// Unavailable, with nothing resolved. The honest default.
  const SpeechProbe.unavailable(this.code, this.direction)
      : available = false,
        resolvedTag = null,
        engine = null;

  final String code;
  final SpeechDirection direction;

  /// True only when the engine listed a tag this app asked for.
  final bool available;

  /// The exact tag the engine accepted, e.g. `bn-IN`. Null when unavailable.
  final String? resolvedTag;

  /// The engine that answered, when it identifies itself.
  final String? engine;

  @override
  String toString() => available
      ? 'SpeechProbe($code ${direction.name} -> $resolvedTag'
          '${engine == null ? '' : ' via $engine'})'
      : 'SpeechProbe($code ${direction.name} -> unavailable)';
}

/// Matches a wanted tag against the tags an engine reported.
///
/// Engines are inconsistent in case and separator (`bn_IN`, `bn-IN`, `bn`),
/// so comparison is normalised. A bare wanted tag (`bn`) matches any regional
/// variant the engine offers (`bn-BD`), because that is still the same
/// language. A *regional* wanted tag does not match a different region, and
/// nothing ever matches across languages — `lus` must never resolve to `en`.
String? resolveEngineTag(String wanted, Iterable<String> engineTags) {
  String norm(String t) => t.replaceAll('_', '-').toLowerCase().trim();
  final String want = norm(wanted);
  for (final String tag in engineTags) {
    if (norm(tag) == want) return tag;
  }
  if (!want.contains('-')) {
    for (final String tag in engineTags) {
      final String have = norm(tag);
      if (have == want || have.startsWith('$want-')) return tag;
    }
  }
  return null;
}
