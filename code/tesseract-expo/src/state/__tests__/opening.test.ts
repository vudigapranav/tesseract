import { shouldReopen, REOPEN_AFTER_MS } from '../useOpeningScreen';
import { en } from '../../l10n/en';
import { as_ } from '../../l10n/as';
import { bn } from '../../l10n/bn';

const T0 = 1_000_000;

describe('when the opening screen reappears', () => {
  it('does not reappear for a biometric prompt', () => {
    // Face ID puts the app in `inactive`, never `background`, so nothing
    // starts the clock and coming back is not a reopen.
    expect(
      shouldReopen({
        previous: 'inactive',
        next: 'active',
        backgroundedAt: null,
        now: T0,
      }),
    ).toBe(false);
  });

  it('does not reappear for a permission dialog or the notification shade', () => {
    // Same shape: inactive, then active, with no background in between.
    expect(
      shouldReopen({
        previous: 'inactive',
        next: 'active',
        backgroundedAt: null,
        now: T0 + 5_000,
      }),
    ).toBe(false);
  });

  it('does not reappear after a brief genuine background', () => {
    // Glancing at a notification and coming straight back is an
    // interruption, not a reopen — especially mid-activity.
    expect(
      shouldReopen({
        previous: 'background',
        next: 'active',
        backgroundedAt: T0,
        now: T0 + 4_000,
      }),
    ).toBe(false);
  });

  it('reappears after a long genuine background', () => {
    expect(
      shouldReopen({
        previous: 'background',
        next: 'active',
        backgroundedAt: T0,
        now: T0 + REOPEN_AFTER_MS + 1,
      }),
    ).toBe(true);
  });

  it('ignores transitions that are not becoming active', () => {
    for (const next of ['background', 'inactive'] as const) {
      expect(
        shouldReopen({
          previous: 'active',
          next,
          backgroundedAt: T0,
          now: T0 + 10 * REOPEN_AFTER_MS,
        }),
      ).toBe(false);
    }
  });

  it('is exactly at the boundary, not almost', () => {
    const base = {
      previous: 'background' as const,
      next: 'active' as const,
      backgroundedAt: T0,
    };
    expect(shouldReopen({ ...base, now: T0 + REOPEN_AFTER_MS - 1 })).toBe(false);
    expect(shouldReopen({ ...base, now: T0 + REOPEN_AFTER_MS })).toBe(true);
  });
});

describe('Apnapan branding strings', () => {
  it('names the product Apnapan', () => {
    expect(en.appName).toBe('Apnapan');
    expect(en.appNameHindi).toBe('अपनापन');
  });

  it('keeps the exact team attribution', () => {
    expect(en.builtBy).toBe('Built and developed by the Tesseract Team.');
  });

  it('carries the tagline as a localised string, not baked into the image', () => {
    expect(en.appTagline).toBe(
      'AI-based cognitive activities and everyday support.',
    );
    // Present where a translation was actually written.
    expect(as_.appTagline).toBeDefined();
    expect(bn.appTagline).toBeDefined();
  });

  it('never translates the product name or the attribution', () => {
    // Both are proper nouns / fixed attribution: a locale overriding them
    // would silently change the brand or the credit.
    for (const catalogue of [as_, bn]) {
      expect(catalogue.appName).toBeUndefined();
      expect(catalogue.appNameHindi).toBeUndefined();
      expect(catalogue.builtBy).toBeUndefined();
    }
  });

  it('describes the product without making a clinical claim', () => {
    const claims = /diagnos|treat|cure|clinically (proven|validated)|prescri/i;
    expect(en.appTagline).not.toMatch(claims);
    expect(en.aboutDescription).not.toMatch(claims);
  });

  it('About refers to Apnapan', () => {
    expect(en.aboutTesseract).toContain('Apnapan');
    expect(en.aboutDescription).toContain('Apnapan');
  });
});
