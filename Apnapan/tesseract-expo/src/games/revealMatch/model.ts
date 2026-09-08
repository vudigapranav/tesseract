/**
 * Reveal Match (G1) — the model, ported from Aryan's Flutter
 * `reveal_match_controller.dart` / `reveal_match_model.dart`.
 * Original design: Aryan.
 *
 * Pure TypeScript. No React, no timers, no I/O — the view drives it and the
 * clock is passed in, so every rule here is testable without rendering
 * anything. That mirrors the original, whose controller was pure Dart with
 * the note "the host supplies persistence, navigation and event delivery".
 *
 * Behaviour preserved from the original:
 *  - 2, 3 or 4 pairs in a two-column board.
 *  - Tap one card, tap a second. A match stays revealed; a mismatch stays
 *    visible for `resolutionMs` of **active** time, then hides again.
 *  - An optional guided preview shows every card until the patient is ready.
 *  - Latency between first and second card of each attempt is recorded.
 *
 * Deliberately dropped: nothing behavioural. The original's metrics object is
 * kept, minus anything patient-facing — the patient never sees a count, an
 * accuracy or a "wrong". A mismatch simply turns back over.
 */

/** A single card on the board. `asset` is an opaque content id. */
export interface RevealCard {
  id: string;
  pairId: string;
  asset: string;
}

export type RevealPhase = 'idle' | 'oneSelected' | 'resolving' | 'completed';

export interface RevealMatchParams {
  pairCount: number;
  guidedPreview: boolean;
  resolutionMs: number;
  /** The registry hands these to the host as a plain settings bag. */
  [key: string]: unknown;
}

/**
 * Real settings per level, never the level number.
 *
 * Level 1 is the supported tier: fewest pairs, and the guided preview on so
 * the patient sees the board before being asked to remember any of it. The
 * original exposed exactly these three tiers (2/3/4 pairs).
 */
export function revealMatchDifficultyParams(level: number): RevealMatchParams {
  switch (level) {
    case 1:
      return { pairCount: 2, guidedPreview: true, resolutionMs: 1600 };
    case 2:
      return { pairCount: 3, guidedPreview: false, resolutionMs: 1400 };
    default:
      return { pairCount: 4, guidedPreview: false, resolutionMs: 1200 };
  }
}

/** Board columns. Two, as in the original, so cards stay large on a phone. */
export const REVEAL_MATCH_COLUMNS = 2;

/**
 * Builds the deck: one pair per asset, two copies each, shuffled.
 *
 * `shuffle` is injectable so a test can pin the order. Requires one distinct
 * asset per pair, exactly as the original asserted.
 */
export function buildDeck(
  assets: readonly string[],
  pairCount: number,
  shuffle: <T>(items: T[]) => T[] = defaultShuffle,
): RevealCard[] {
  const distinct = Array.from(new Set(assets));
  if (distinct.length < pairCount) {
    throw new Error('Each pair requires a distinct image');
  }
  const cards: RevealCard[] = [];
  for (let p = 0; p < pairCount; p++) {
    for (let copy = 0; copy < 2; copy++) {
      cards.push({
        id: `card-${p}-${copy}`,
        pairId: `pair-${p}`,
        asset: distinct[p],
      });
    }
  }
  return shuffle(cards);
}

function defaultShuffle<T>(items: T[]): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

/** What a tap did, so the view knows what to emit and render. */
export interface TapOutcome {
  /** False when the tap was ignored: already matched, mid-resolution, etc. */
  accepted: boolean;
  /** Set when this tap completed an attempt. */
  resolved?: {
    matched: boolean;
    cardIds: [string, string];
    attemptNumber: number;
    /** Active ms between the first and second card of this attempt. */
    latencyMs: number;
  };
}

export interface RevealMatchMetrics {
  pairsFound: number;
  resolvedAttempts: number;
  mismatches: number;
  /** Null when nothing was attempted — never 0, which would read as failure. */
  pairAccuracy: number | null;
  medianSecondCardLatencyMs: number | null;
  completion: boolean;
}

/**
 * The board's rules.
 *
 * Time is supplied by the caller as *active* milliseconds (the recorder's
 * clock, which excludes paused stretches), so a mismatch that spans a break
 * still stays visible for its full duration rather than expiring while the
 * patient is away. That subtlety is from the original and is easy to lose.
 */
export class RevealMatchBoard {
  private readonly cards: RevealCard[];
  private readonly matched = new Set<string>();
  private selected: string[] = [];
  private latencies: number[] = [];
  private attempts = 0;
  private firstAtMs: number | null = null;
  private resolveAtMs: number | null = null;
  private preview: boolean;

  constructor(
    cards: RevealCard[],
    private readonly params: RevealMatchParams,
  ) {
    this.cards = cards;
    this.preview = params.guidedPreview;
  }

  get allCards(): readonly RevealCard[] {
    return this.cards;
  }

  get previewVisible(): boolean {
    return this.preview;
  }

  get isComplete(): boolean {
    return this.matched.size === this.cards.length;
  }

  get phase(): RevealPhase {
    if (this.isComplete) return 'completed';
    if (this.resolveAtMs !== null) return 'resolving';
    return this.selected.length === 0 ? 'idle' : 'oneSelected';
  }

  /** A card shows its face during preview, once matched, or while selected. */
  isFaceUp(cardId: string): boolean {
    return (
      this.preview ||
      this.matched.has(cardId) ||
      this.selected.includes(cardId)
    );
  }

  isMatched(cardId: string): boolean {
    return this.matched.has(cardId);
  }

  dismissPreview(): void {
    this.preview = false;
  }

  tap(cardId: string, nowMs: number): TapOutcome {
    if (
      this.preview ||
      this.resolveAtMs !== null ||
      this.matched.has(cardId) ||
      this.selected.includes(cardId) ||
      !this.cards.some((c) => c.id === cardId)
    ) {
      return { accepted: false };
    }

    this.selected.push(cardId);

    if (this.selected.length === 1) {
      this.firstAtMs = nowMs;
      return { accepted: true };
    }

    const [aId, bId] = this.selected;
    const a = this.cards.find((c) => c.id === aId)!;
    const b = this.cards.find((c) => c.id === bId)!;
    const matched = a.pairId === b.pairId;
    const latencyMs = nowMs - (this.firstAtMs ?? nowMs);

    this.attempts += 1;
    this.latencies.push(latencyMs);
    if (matched) {
      this.matched.add(aId);
      this.matched.add(bId);
    }
    this.resolveAtMs = nowMs + this.params.resolutionMs;

    return {
      accepted: true,
      resolved: {
        matched,
        cardIds: [aId, bId],
        attemptNumber: this.attempts,
        latencyMs,
      },
    };
  }

  /**
   * Ends a resolution once its deadline passes on the active clock.
   * Returns true when the board changed, so the view only re-renders then.
   */
  settle(nowMs: number): boolean {
    if (this.resolveAtMs === null || nowMs < this.resolveAtMs) return false;
    this.selected = [];
    this.firstAtMs = null;
    this.resolveAtMs = null;
    return true;
  }

  metrics(completion: boolean): RevealMatchMetrics {
    const sorted = [...this.latencies].sort((x, y) => x - y);
    let median: number | null = null;
    if (sorted.length > 0) {
      const mid = Math.floor(sorted.length / 2);
      median =
        sorted.length % 2 === 1
          ? sorted[mid]
          : (sorted[mid - 1] + sorted[mid]) / 2;
    }
    const successful = this.matched.size / 2;
    return {
      pairsFound: successful,
      resolvedAttempts: this.attempts,
      mismatches: this.attempts - successful,
      // Null, not zero: no attempts is "nothing observed", not "got it wrong".
      pairAccuracy: this.attempts === 0 ? null : successful / this.attempts,
      medianSecondCardLatencyMs: median,
      completion,
    };
  }
}
