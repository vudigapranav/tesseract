/**
 * What speech actually works, per language, on this phone.
 *
 * Same two-axis model as the Flutter build, and for the same reason:
 *
 *  - **Documented expectation** is what a vendor's docs claim. Background
 *    only. A language is never treated as usable because of it.
 *  - **Probe** is what the engine on this device actually reported. This is
 *    the only thing the app routes on.
 *
 * Neither says the pronunciation is any good. That needs a fluent speaker,
 * tracked separately and currently `notReviewed` for every language.
 */
import type { LanguageCode } from '../l10n/languages';

export type SpeechDirection = 'output' | 'input';
export type SpeechExpectation = 'documented' | 'undocumented';
export type PronunciationReview = 'notReviewed' | 'reviewed' | 'rejected';

export interface SpeechLanguageRow {
  code: LanguageCode;
  englishName: string;
  script: string;
  /**
   * BCP-47 tags to offer the engine, best first. Engines are inconsistent
   * about whether a language appears under a regional tag or a bare one, so
   * the probe tries these in order and records which one matched.
   */
  preferredTags: string[];
  outputExpectation: SpeechExpectation;
  inputExpectation: SpeechExpectation;
  notes: string;
  review: PronunciationReview;
}

/**
 * The documented starting point, from Apple's and Google's published voice
 * lists as consulted on 2026-09-08.
 *
 * The short version, and it is not good news: of the five North Eastern Region
 * languages, only **Bengali** has a documented voice from either vendor.
 * Assamese, Meitei, Khasi and Mizo appear in translation products and keyboard
 * language lists, which is a completely different capability from having a
 * voice. That distinction is the whole reason this file exists.
 */
export const SPEECH_MATRIX: readonly SpeechLanguageRow[] = [
  {
    code: 'en',
    englishName: 'English',
    script: 'Latin',
    preferredTags: ['en-IN', 'en-US', 'en'],
    outputExpectation: 'documented',
    inputExpectation: 'documented',
    notes:
      'Universally available. en-IN preferred so the accent matches the ' +
      'people this app is for.',
    review: 'notReviewed',
  },
  {
    code: 'hi',
    englishName: 'Hindi',
    script: 'Devanagari',
    preferredTags: ['hi-IN', 'hi'],
    outputExpectation: 'documented',
    inputExpectation: 'documented',
    notes:
      'Apple ships a Hindi (hi-IN) voice and iOS dictation lists Hindi, so ' +
      'reading aloud is expected to work once the voice is present on the ' +
      'device — which the probe checks rather than assumes. Recognition is a ' +
      'separate matter: it is unavailable in Expo Go for every language, ' +
      'because that needs a native module the container cannot load. Adding ' +
      'Hindi does not improve any North Eastern Region language.',
    review: 'notReviewed',
  },
  {
    code: 'bn',
    englishName: 'Bengali',
    script: 'Bengali-Assamese',
    preferredTags: ['bn-IN', 'bn-BD', 'bn'],
    outputExpectation: 'documented',
    inputExpectation: 'documented',
    notes:
      'The only NER language of the five with a documented voice. iOS ships ' +
      'a Bengali voice; whether it is installed on a given phone is a ' +
      'separate question the probe answers.',
    review: 'notReviewed',
  },
  {
    code: 'as',
    englishName: 'Assamese',
    script: 'Bengali-Assamese',
    preferredTags: ['as-IN', 'as'],
    outputExpectation: 'undocumented',
    inputExpectation: 'undocumented',
    notes:
      'No documented iOS or Android voice. Present in translation products ' +
      'and keyboards, neither of which is a voice. Probe anyway; claim ' +
      'nothing until a device says otherwise.',
    review: 'notReviewed',
  },
  {
    code: 'mni',
    englishName: 'Meitei (Manipuri)',
    script: 'Meetei Mayek',
    preferredTags: ['mni-IN', 'mni'],
    outputExpectation: 'undocumented',
    inputExpectation: 'undocumented',
    notes:
      'No documented voice from either vendor. Meetei Mayek script support ' +
      'is thin, which is why the font is bundled. Expect the text path to ' +
      'carry this language entirely.',
    review: 'notReviewed',
  },
  {
    code: 'kha',
    englishName: 'Khasi',
    script: 'Latin',
    preferredTags: ['kha-IN', 'kha'],
    outputExpectation: 'undocumented',
    inputExpectation: 'undocumented',
    notes: 'No documented voice. Expect speech to be unavailable.',
    review: 'notReviewed',
  },
  {
    code: 'lus',
    englishName: 'Mizo',
    script: 'Latin',
    preferredTags: ['lus-IN', 'lus'],
    outputExpectation: 'undocumented',
    inputExpectation: 'undocumented',
    notes:
      'No documented voice. Because Mizo is written in Latin script an ' +
      'English voice will happily read it aloud as mangled English — that ' +
      'is precisely the silent substitution this app refuses to do.',
    review: 'notReviewed',
  },
];

export const matrixRow = (code: string) =>
  SPEECH_MATRIX.find((r) => r.code === code);

/** Tags to try for a language, best first. Empty for an unknown language. */
export const tagsFor = (code: string): string[] =>
  matrixRow(code)?.preferredTags ?? [];

export interface SpeechProbe {
  code: string;
  direction: SpeechDirection;
  available: boolean;
  /** The exact tag the engine accepted, e.g. `bn-IN`. */
  resolvedTag?: string;
  /** Identifier of the voice that answered, when the platform offers one. */
  voice?: string;
}

/**
 * Matches a wanted tag against the tags an engine reported.
 *
 * Normalised for case and separator (`bn_IN`, `bn-IN`, `bn`). A bare wanted
 * tag matches any regional variant, because that is still the same language.
 * A regional tag does not match a different region, and **nothing ever matches
 * across languages** — `lus` must never resolve to `en`.
 */
export function resolveEngineTag(
  wanted: string,
  engineTags: readonly string[],
): string | undefined {
  const norm = (t: string) => t.replace(/_/g, '-').toLowerCase().trim();
  const want = norm(wanted);
  for (const tag of engineTags) if (norm(tag) === want) return tag;
  if (!want.includes('-')) {
    for (const tag of engineTags) {
      const have = norm(tag);
      if (have === want || have.startsWith(`${want}-`)) return tag;
    }
  }
  return undefined;
}
