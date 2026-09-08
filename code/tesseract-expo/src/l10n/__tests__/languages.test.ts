import { en } from '../en';
import { hi } from '../hi';
import { as_ } from '../as';
import { bn } from '../bn';
import { mni } from '../mni';
import { kha } from '../kha';
import { lus } from '../lus';
import { translate, hasOwnTranslation } from '../i18n';
import { LANGUAGES, languageByCode, UNCOVERED_REGIONS } from '../languages';
import { matrixRow, resolveEngineTag, tagsFor } from '../../speech/capability';

const CATALOGUES = { hi, as: as_, bn, mni, kha, lus } as const;
const untranslatable = ['appName', 'appNameHindi', 'builtBy'] as const;
const denominator = Object.keys(en).filter(
  (k) => !(untranslatable as readonly string[]).includes(k),
);

describe('Hindi', () => {
  it('is offered, in its own script', () => {
    const l = languageByCode('hi');
    expect(l.endonym).toBe('हिन्दी');
    expect(l.script).toBe('Devanagari');
  });

  it('is fully translated', () => {
    const have = denominator.filter((k) => k in hi);
    expect(have).toHaveLength(denominator.length);
    expect(languageByCode('hi').coveragePercent).toBe(100);
  });

  it('is still a draft until a fluent speaker reviews it', () => {
    // Full coverage is a count, not an endorsement.
    expect(languageByCode('hi').reviewStatus).toBe('draft');
  });

  it('never overrides the product name or the attribution', () => {
    for (const key of untranslatable) {
      expect((hi as Record<string, unknown>)[key]).toBeUndefined();
    }
  });

  it('keeps every placeholder English declares', () => {
    const holes = (v: string) =>
      new Set(Array.from(v.matchAll(/\{(\w+)\}/g), (m) => m[1]));
    for (const [key, value] of Object.entries(hi)) {
      const source = (en as Record<string, string>)[key];
      if (!source) continue;
      expect(holes(value as string)).toEqual(holes(source));
    }
  });

  it('translates game names, instructions and Help/Break', () => {
    for (const key of [
      'gameRouteQuest', 'gameMarbleMaze', 'gameWordSearch',
      'gameRoutineRecall', 'gamePictureSorting',
      'howToPlayRouteQuest', 'howToPlayMarbleMazeTilt', 'howToPlayWordSearch',
      'howToPlayRoutineRecall', 'howToPlayPictureSorting',
      'help', 'breakLabel', 'takingABreak', 'continueLabel', 'finishForNow',
      'allDone', 'outcomeFinished', 'outcomeStoppedEarly',
    ] as const) {
      expect(hasOwnTranslation('hi', key)).toBe(true);
    }
  });

  it('translates reminders, speech and voice-confirmation wording', () => {
    for (const key of [
      'reminderNotificationTitle', 'reminderSeenIt', 'reminderLater',
      'speakThis', 'stopSpeaking', 'speechUnavailableForLanguage',
      'tapToSpeak', 'youSaid', 'useThis', 'voiceNeedsConfirmation',
      'voiceLanguageUnavailable',
    ] as const) {
      expect(hasOwnTranslation('hi', key)).toBe(true);
    }
  });

  it('renders a real Devanagari sentence, not an English fallback', () => {
    const s = translate('hi', 'voiceNeedsConfirmation');
    expect(s).not.toBe(en.voiceNeedsConfirmation);
    expect(/[ऀ-ॿ]/.test(s)).toBe(true);
  });
});

describe('Hindi speech is assessed on its own evidence', () => {
  it('has a matrix row with Hindi tags', () => {
    const row = matrixRow('hi');
    expect(row).toBeDefined();
    expect(tagsFor('hi')).toEqual(['hi-IN', 'hi']);
  });

  it('is not marked reviewed by a fluent speaker', () => {
    expect(matrixRow('hi')!.review).toBe('notReviewed');
  });

  it('never resolves to another language', () => {
    // A device with no Hindi voice must fall back to text, not to English
    // pronouncing Devanagari.
    for (const tag of tagsFor('hi')) {
      expect(resolveEngineTag(tag, ['en-US', 'en-IN', 'bn-IN'])).toBeUndefined();
    }
  });
});

describe('adding Hindi does not paper over the NER gap', () => {
  it('leaves Meitei, Khasi and Mizo where they were', () => {
    for (const code of ['mni', 'kha', 'lus'] as const) {
      expect(languageByCode(code).coveragePercent).toBeLessThan(20);
      expect(languageByCode(code).reviewStatus).toBe('draft');
    }
  });

  it('still names the states with no language at all', () => {
    expect([...UNCOVERED_REGIONS]).toEqual([
      'Nagaland', 'Tripura', 'Arunachal Pradesh', 'Sikkim',
    ]);
  });

  it('ships seven languages, none of them natively reviewed but English', () => {
    expect(LANGUAGES).toHaveLength(7);
    for (const l of LANGUAGES) {
      if (l.code === 'en') expect(l.reviewStatus).toBe('native');
      else expect(l.reviewStatus).toBe('draft');
    }
  });

  it('every catalogue falls back to English rather than showing a key', () => {
    for (const [code, catalogue] of Object.entries(CATALOGUES)) {
      const missing = denominator.find((k) => !(k in catalogue));
      if (!missing) continue;
      const rendered = translate(code as never, missing as never);
      expect(rendered).toBe((en as Record<string, string>)[missing]);
    }
  });
});
