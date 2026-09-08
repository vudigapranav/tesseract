/**
 * The languages this build ships, ported from LanguageCatalogue.
 *
 * `coveragePercent` is measured from the ARB files by tools/sync-l10n.mjs and
 * re-checked by a test, so a language cannot drift into claiming more
 * completeness than it has.
 *
 * Coverage and review are separate axes on purpose. 100% means every string is
 * written. It says nothing about whether a fluent speaker agrees with the
 * wording, which is `reviewStatus`, and which is `draft` for everything.
 */
export type ReviewStatus = 'native' | 'draft';

export interface LanguageOption {
  code: LanguageCode;
  /** The language's name in its own script, so a speaker can recognise it. */
  endonym: string;
  englishName: string;
  coveragePercent: number;
  reviewStatus: ReviewStatus;
  script: string;
  /**
   * Where the language is chiefly spoken. Shown so a caregiver can find
   * theirs — not a claim that one language represents a whole state.
   */
  region?: string;
}

export type LanguageCode = 'en' | 'as' | 'bn' | 'mni' | 'kha' | 'lus';

export const LANGUAGES: readonly LanguageOption[] = [
  {
    code: 'en',
    endonym: 'English',
    englishName: 'English',
    coveragePercent: 100,
    reviewStatus: 'native',
    script: 'Latin',
  },
  {
    code: 'as',
    endonym: 'অসমীয়া',
    englishName: 'Assamese',
    coveragePercent: 100,
    reviewStatus: 'draft',
    script: 'Bengali-Assamese',
    region: 'Assam',
  },
  {
    code: 'bn',
    endonym: 'বাংলা',
    englishName: 'Bengali',
    coveragePercent: 100,
    reviewStatus: 'draft',
    script: 'Bengali-Assamese',
    region: 'Assam, Tripura',
  },
  {
    code: 'mni',
    endonym: 'ꯃꯤꯇꯩꯂꯣꯟ',
    englishName: 'Meitei (Manipuri)',
    coveragePercent: 8,
    reviewStatus: 'draft',
    script: 'Meetei Mayek',
    region: 'Manipur',
  },
  {
    code: 'kha',
    endonym: 'Ka Ktien Khasi',
    englishName: 'Khasi',
    coveragePercent: 8,
    reviewStatus: 'draft',
    script: 'Latin',
    region: 'Meghalaya',
  },
  {
    code: 'lus',
    endonym: 'Mizo ṭawng',
    englishName: 'Mizo',
    coveragePercent: 8,
    reviewStatus: 'draft',
    script: 'Latin',
    region: 'Mizoram',
  },
];

/**
 * States of the North Eastern Region with no language in this build.
 * Named so the gap stays visible in the UI and in review rather than being
 * quietly papered over. Adding any of these needs a scope decision.
 */
export const UNCOVERED_REGIONS = [
  'Nagaland',
  'Tripura',
  'Arunachal Pradesh',
  'Sikkim',
] as const;

export const languageByCode = (code: string): LanguageOption =>
  LANGUAGES.find((l) => l.code === code) ?? LANGUAGES[0];

export const isDraft = (l: LanguageOption) => l.reviewStatus === 'draft';

/** Every string written. **Not** a claim that they are any good. */
export const isTextComplete = (l: LanguageOption) => l.coveragePercent >= 100;
