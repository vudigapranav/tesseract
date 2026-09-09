/**
 * Spot Difference (G6) — the model, ported from Aryan's Flutter
 * `spot_difference_controller.dart` and `difference_hit_test.dart`.
 * Original design: Aryan.
 *
 * Pure TypeScript. Coordinates are unit fractions of the picture box (0..1),
 * never pixels, so hit testing behaves the same on any screen and nothing
 * device-specific reaches an event payload.
 *
 * The hit test is the interesting part, and it is preserved exactly: an
 * authored region always wins over another region's forgiveness margin, and
 * among margins the nearest centre wins. Ties keep authored order. Whether a
 * difference has already been found never changes where a tap lands — so
 * tapping the same spot twice is recognised as a repeat rather than silently
 * counting as a miss.
 */
import { DIFFERENCE_PAIRS, type DifferencePair, type DifferenceRegion } from '../../content/pictures';

export interface SpotDifferenceParams {
  /** How many differences this level asks for. */
  differenceCount: number;
  /** Extra forgiveness added to every authored margin, in box fractions. */
  extraMargin: number;
  [key: string]: unknown;
}

/**
 * Real settings per level.
 *
 * Level 1 is the one-difference pair with generous forgiveness. Level 3 is the
 * two-difference pair with only the authored margin. The differences
 * themselves are authored per pair, so a level selects a puzzle rather than
 * inventing extra changes in a picture.
 */
export function spotDifferenceDifficultyParams(level: number): SpotDifferenceParams {
  switch (level) {
    case 1:
      return { differenceCount: 1, extraMargin: 0.05 };
    case 2:
      return { differenceCount: 2, extraMargin: 0.04 };
    default:
      return { differenceCount: 2, extraMargin: 0.0 };
  }
}

/** Picks the authored pair that has the wanted number of differences. */
export function pairForParams(params: SpotDifferenceParams): DifferencePair | null {
  return (
    DIFFERENCE_PAIRS.find((p) => p.regions.length === params.differenceCount) ??
    DIFFERENCE_PAIRS[0] ??
    null
  );
}

function within(
  region: DifferenceRegion,
  x: number,
  y: number,
  margin: number,
): boolean {
  return (
    x >= region.left - margin &&
    x <= region.left + region.width + margin &&
    y >= region.top - margin &&
    y <= region.top + region.height + margin
  );
}

/**
 * Which difference a tap landed on, or null.
 *
 * Two passes, as in the original: exact regions first, then acceptance
 * margins by nearest centre. Without the two passes, a generous margin around
 * one difference could swallow a tap that was squarely inside another.
 */
export function hitDifference(
  regions: readonly DifferenceRegion[],
  x: number,
  y: number,
  extraMargin = 0,
): DifferenceRegion | null {
  if (!(x >= 0 && x <= 1 && y >= 0 && y <= 1)) return null;

  for (const region of regions) {
    if (within(region, x, y, 0)) return region;
  }

  let best: DifferenceRegion | null = null;
  let bestDistance = Number.POSITIVE_INFINITY;
  for (const region of regions) {
    if (!within(region, x, y, region.margin + extraMargin)) continue;
    const dx = x - (region.left + region.width / 2);
    const dy = y - (region.top + region.height / 2);
    const distance = dx * dx + dy * dy;
    // Strictly less-than, so an exact tie keeps the authored order.
    if (distance < bestDistance) {
      best = region;
      bestDistance = distance;
    }
  }
  return best;
}

export interface SelectOutcome {
  regionId: string | null;
  correct: boolean;
  alreadyFound: boolean;
}

export interface SpotDifferenceMetrics {
  differencesFound: number;
  differencesTotal: number;
  /** Taps that landed on no difference. Descriptive; never shown to the patient. */
  nonMatchingTaps: number;
  /** Active ms to the first difference found. Null when none was. */
  timeToFirstFoundMs: number | null;
  hintsUsed: number;
  completion: boolean;
}

export class SpotDifferenceBoard {
  private readonly found = new Set<string>();
  private nonMatching = 0;
  private firstFoundMs: number | null = null;
  private hints = 0;
  private highlight: string | null = null;

  constructor(
    readonly pair: DifferencePair,
    private readonly params: SpotDifferenceParams,
  ) {}

  get regions(): readonly DifferenceRegion[] {
    return this.pair.regions;
  }

  isFound(regionId: string): boolean {
    return this.found.has(regionId);
  }

  get foundCount(): number {
    return this.found.size;
  }

  get highlightedId(): string | null {
    return this.highlight;
  }

  get isComplete(): boolean {
    return this.found.size === this.pair.regions.length;
  }

  select(x: number, y: number, nowMs: number): SelectOutcome {
    const region = hitDifference(this.pair.regions, x, y, this.params.extraMargin);
    const alreadyFound = region !== null && this.found.has(region.id);

    if (region === null) {
      this.nonMatching += 1;
    } else if (!alreadyFound) {
      this.found.add(region.id);
      if (this.firstFoundMs === null) this.firstFoundMs = nowMs;
      if (this.highlight === region.id) this.highlight = null;
    }

    return { regionId: region?.id ?? null, correct: region !== null, alreadyFound };
  }

  /** Points at one difference that has not been found. Never taps it for them. */
  requestHint(): string | null {
    const remaining = this.pair.regions.find((r) => !this.found.has(r.id));
    if (!remaining) return null;
    this.highlight = remaining.id;
    this.hints += 1;
    return remaining.id;
  }

  metrics(completion: boolean): SpotDifferenceMetrics {
    return {
      differencesFound: this.found.size,
      differencesTotal: this.pair.regions.length,
      nonMatchingTaps: this.nonMatching,
      timeToFirstFoundMs: this.firstFoundMs,
      hintsUsed: this.hints,
      completion,
    };
  }
}
