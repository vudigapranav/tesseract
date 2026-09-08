import { toGraphemes, indicAwareSplit, graphemeLength } from '../graphemes';

// Both paths are exercised: the runtime's Intl.Segmenter when present, and the
// fallback a phone without it will actually run.
const paths: Array<[string, (s: string) => string[]]> = [
  ['runtime', toGraphemes],
  ['fallback', indicAwareSplit],
];

describe.each(paths)('grapheme splitting (%s)', (_name, split) => {
  it('keeps a Devanagari consonant and its matra together', () => {
    // की = क + ी. Two code points, one written syllable.
    expect(split('की')).toEqual(['की']);
    expect(Array.from('की')).toHaveLength(2); // the defect, for contrast
  });

  it('keeps a Devanagari conjunct joined by virama together', () => {
    // क्ष = क + ् + ष
    expect(split('क्ष')).toEqual(['क्ष']);
  });

  it('splits a Hindi word into readable syllables', () => {
    // हिन्दी → हि · न्दी
    const units = split('हिन्दी');
    expect(units.join('')).toBe('हिन्दी');
    expect(units.length).toBeLessThan(Array.from('हिन्दी').length);
  });

  it('keeps Bengali matras attached', () => {
    // কী = ক + ী
    expect(split('কী')).toEqual(['কী']);
  });

  it('keeps an Assamese ৰ with its matra attached', () => {
    expect(split('ৰা')).toEqual(['ৰা']);
  });

  it('keeps Bengali hasanta conjuncts together', () => {
    // ক্ষ = ক + ্ + ষ
    expect(split('ক্ষ')).toEqual(['ক্ষ']);
  });

  it('keeps a Meetei Mayek syllable with its vowel sign together', () => {
    // ꯀ + ꯤ
    expect(split('ꯀꯤ')).toEqual(['ꯀꯤ']);
  });

  it('leaves Latin alone', () => {
    expect(split('TEA')).toEqual(['T', 'E', 'A']);
  });

  it('never loses or reorders characters', () => {
    for (const word of ['हिन्दी', 'অসমীয়া', 'বাংলা', 'TEA', 'ꯃꯤꯇꯩ']) {
      expect(split(word).join('')).toBe(word);
    }
  });
});

describe('graphemeLength drives board sizing', () => {
  it('counts what a reader sees, not code points', () => {
    // A 6-cell grid must not accept a word that needs more visible cells.
    expect(graphemeLength('हिन्दी')).toBeLessThan(Array.from('हिन्दी').length);
    expect(graphemeLength('TEA')).toBe(3);
  });
});
