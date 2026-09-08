/**
 * Splitting text into the units a reader actually sees.
 *
 * `Array.from(text)` splits by **code point**, which is wrong for every script
 * this app ships except Latin. In Devanagari, Bengali-Assamese and Meetei
 * Mayek a written syllable is a base consonant plus its vowel signs, nukta,
 * anusvara and virama-joined consonants — several code points forming one
 * visible cluster. Splitting between them puts a floating matra in its own
 * Word Search cell, which is not a letter anyone can look for, and lets the
 * grid claim a word "fits" when it visually does not.
 *
 * `Intl.Segmenter` is the correct tool and is used when the runtime has it.
 * Hermes does not always ship it, so there is a deliberate Indic-aware
 * fallback rather than a silent regression to code points.
 */

/** Marks that attach to the preceding base and never stand alone. */
const COMBINING = new RegExp(
  '^[' +
    // Devanagari signs, matras, nukta, virama, stress marks.
    'ऀ-ःऺ-ॏ॑-ॗॢॣ' +
    // Bengali-Assamese signs, nukta, matras, virama, au length mark.
    'ঁ-ঃ়া-্ৗৢৣ' +
    // Meetei Mayek vowel signs and finals.
    'ꯣ-ꯪ꯬꯭' +
    // Generic combining diacritics, plus the joiners.
    '̀-ͯ‌‍' +
    ']',
);

/** Viramas: a consonant after one of these joins into the same cluster. */
const VIRAMA = /^[्্꯭]/;

const hasSegmenter =
  typeof Intl !== 'undefined' &&
  typeof (Intl as { Segmenter?: unknown }).Segmenter === 'function';

/**
 * Splits `text` into grapheme clusters.
 *
 * Exported separately from the fallback so tests can exercise both paths on
 * any runtime — a test that only ever runs the `Intl` path would not tell us
 * whether a phone without it behaves correctly.
 */
export function toGraphemes(text: string): string[] {
  if (hasSegmenter) {
    const seg = new (Intl as unknown as {
      Segmenter: new (l?: string, o?: { granularity: string }) => {
        segment(s: string): Iterable<{ segment: string }>;
      };
    }).Segmenter(undefined, { granularity: 'grapheme' });
    return [...seg.segment(text)].map((s) => s.segment);
  }
  return indicAwareSplit(text);
}

/** The fallback used when the runtime has no `Intl.Segmenter`. */
export function indicAwareSplit(text: string): string[] {
  const points = Array.from(text);
  const out: string[] = [];
  let i = 0;

  while (i < points.length) {
    let cluster = points[i];
    i += 1;

    // Absorb everything that belongs to this cluster.
    while (i < points.length) {
      const next = points[i];

      // A combining mark always attaches to what precedes it.
      if (COMBINING.test(next)) {
        cluster += next;
        i += 1;
        continue;
      }

      // A virama binds the following consonant into the same cluster
      // (क + ् + ष reads as one conjunct, not three letters).
      if (VIRAMA.test(points[i - 1] ?? '') && !COMBINING.test(next)) {
        cluster += next;
        i += 1;
        continue;
      }

      // Regional indicators and surrogate pairs are already single points
      // via Array.from; nothing further to join.
      break;
    }
    out.push(cluster);
  }
  return out;
}

/** How many visible units the text has. */
export const graphemeLength = (text: string): number =>
  toGraphemes(text).length;
