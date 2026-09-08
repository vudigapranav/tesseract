/**
 * Word grid construction, ported from word_grid.dart.
 *
 * Script handling: words are split by Unicode **code point**, not UTF-16 code
 * unit, so Bengali-Assamese and Meetei Mayek text is placed one real character
 * per cell instead of splitting a surrogate pair down the middle.
 *
 * A word the caregiver supplied that cannot be placed is reported in
 * `skipped`, never silently dropped — the host tells them which of their words
 * did not fit.
 */
export interface PlacedWord {
  id: string;
  word: string;
  /** Flat cell indices, in reading order along the placement direction. */
  cells: number[];
}

export interface WordGrid {
  size: number;
  /** One code point per cell, row-major. */
  letters: string[];
  words: PlacedWord[];
  skipped: Array<{ id: string; word: string }>;
}

export function wordSearchDifficultyParams(level: number) {
  switch (level) {
    case 1:
      return { gridSize: 6, wordCount: 3, allowDiagonals: false };
    case 2:
      return { gridSize: 8, wordCount: 4, allowDiagonals: false };
    default:
      return { gridSize: 9, wordCount: 5, allowDiagonals: true };
  }
}

const codePoints = (s: string): string[] => Array.from(s);

type Dir = readonly [number, number];
const ORTHOGONAL: Dir[] = [
  [1, 0],
  [0, 1],
];
const DIAGONAL: Dir[] = [
  [1, 1],
  [1, -1],
];

/** Deterministic PRNG so a level is reproducible for a given seed. */
function mulberry32(seed: number) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function buildWordGrid({
  entries,
  size,
  wordCount,
  allowDiagonals,
  fillAlphabet,
  seed = 1,
}: {
  entries: Array<{ id: string; word: string }>;
  size: number;
  wordCount: number;
  allowDiagonals: boolean;
  /** Code points used to fill empty cells, from the patient's own script. */
  fillAlphabet: string[];
  seed?: number;
}): WordGrid {
  const rand = mulberry32(seed);
  const letters: (string | null)[] = Array(size * size).fill(null);
  const words: PlacedWord[] = [];
  const skipped: Array<{ id: string; word: string }> = [];

  // Longest first: long words are hardest to fit, and placing them while the
  // grid is empty gives every word its best chance.
  const ordered = [...entries].sort(
    (a, b) => codePoints(b.word).length - codePoints(a.word).length,
  );
  const dirs = allowDiagonals ? [...ORTHOGONAL, ...DIAGONAL] : ORTHOGONAL;

  for (const entry of ordered) {
    if (words.length >= wordCount) {
      skipped.push(entry);
      continue;
    }
    const chars = codePoints(entry.word);
    if (chars.length === 0 || chars.length > size) {
      skipped.push(entry);
      continue;
    }

    let placed: PlacedWord | null = null;
    // Bounded, deterministic search rather than an unbounded retry loop.
    for (let attempt = 0; attempt < 240 && !placed; attempt++) {
      const dir = dirs[Math.floor(rand() * dirs.length)];
      const [dx, dy] = dir;
      const maxCol = dx === 0 ? size - 1 : size - chars.length;
      const minRow = dy < 0 ? chars.length - 1 : 0;
      const maxRow = dy > 0 ? size - chars.length : size - 1;
      if (maxCol < 0 || maxRow < minRow) continue;

      const col = Math.floor(rand() * (maxCol + 1));
      const row = minRow + Math.floor(rand() * (maxRow - minRow + 1));

      const cells: number[] = [];
      let ok = true;
      for (let i = 0; i < chars.length; i++) {
        const c = col + dx * i;
        const r = row + dy * i;
        if (c < 0 || c >= size || r < 0 || r >= size) {
          ok = false;
          break;
        }
        const idx = r * size + c;
        const existing = letters[idx];
        if (existing !== null && existing !== chars[i]) {
          ok = false;
          break;
        }
        cells.push(idx);
      }
      if (!ok) continue;
      cells.forEach((idx, i) => (letters[idx] = chars[i]));
      placed = { id: entry.id, word: entry.word, cells };
    }

    if (placed) words.push(placed);
    else skipped.push(entry);
  }

  const alphabet = fillAlphabet.length > 0 ? fillAlphabet : codePoints('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
  const filled = letters.map(
    (c) => c ?? alphabet[Math.floor(rand() * alphabet.length)],
  );

  return { size, letters: filled, words, skipped };
}

/** Cells on the straight line between two indices, or null if not aligned. */
export function lineBetween(
  size: number,
  from: number,
  to: number,
  allowDiagonals: boolean,
): number[] | null {
  const r1 = Math.floor(from / size);
  const c1 = from % size;
  const r2 = Math.floor(to / size);
  const c2 = to % size;
  const dr = r2 - r1;
  const dc = c2 - c1;
  if (dr === 0 && dc === 0) return [from];

  const straight = dr === 0 || dc === 0;
  const diagonal = Math.abs(dr) === Math.abs(dc);
  if (!straight && !(diagonal && allowDiagonals)) return null;

  const steps = Math.max(Math.abs(dr), Math.abs(dc));
  const sr = Math.sign(dr);
  const sc = Math.sign(dc);
  const cells: number[] = [];
  for (let i = 0; i <= steps; i++) {
    cells.push((r1 + sr * i) * size + (c1 + sc * i));
  }
  return cells;
}
