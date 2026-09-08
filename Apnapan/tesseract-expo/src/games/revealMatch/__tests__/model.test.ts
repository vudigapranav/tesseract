import {
  REVEAL_MATCH_COLUMNS,
  RevealMatchBoard,
  buildDeck,
  revealMatchDifficultyParams,
  type RevealCard,
} from '../model';

/** Deterministic order so a test can name specific cards. */
const noShuffle = <T>(items: T[]): T[] => items;

const deckOf = (pairs: number): RevealCard[] =>
  buildDeck(['a', 'b', 'c', 'd'], pairs, noShuffle);

const boardOf = (pairs: number, overrides = {}) =>
  new RevealMatchBoard(deckOf(pairs), {
    ...revealMatchDifficultyParams(pairs === 2 ? 1 : pairs === 3 ? 2 : 3),
    guidedPreview: false,
    ...overrides,
  });

describe('difficulty', () => {
  it('gives each level real settings, not a level number', () => {
    expect(revealMatchDifficultyParams(1).pairCount).toBe(2);
    expect(revealMatchDifficultyParams(2).pairCount).toBe(3);
    expect(revealMatchDifficultyParams(3).pairCount).toBe(4);
  });

  it('turns the guided preview on only at the supported level', () => {
    expect(revealMatchDifficultyParams(1).guidedPreview).toBe(true);
    expect(revealMatchDifficultyParams(2).guidedPreview).toBe(false);
    expect(revealMatchDifficultyParams(3).guidedPreview).toBe(false);
  });

  it('gives the easiest level the longest look at a mismatch', () => {
    expect(revealMatchDifficultyParams(1).resolutionMs).toBeGreaterThan(
      revealMatchDifficultyParams(3).resolutionMs,
    );
  });
});

describe('deck', () => {
  it('builds two copies of each pair', () => {
    const deck = deckOf(3);
    expect(deck).toHaveLength(6);
    for (let p = 0; p < 3; p++) {
      expect(deck.filter((c) => c.pairId === `pair-${p}`)).toHaveLength(2);
    }
  });

  it('gives every card a unique opaque id', () => {
    const ids = deckOf(4).map((c) => c.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids.every((id) => /^card-\d+-[01]$/.test(id))).toBe(true);
  });

  it('pairs share one asset and different pairs do not', () => {
    const deck = deckOf(2);
    const byPair = new Map<string, Set<string>>();
    for (const c of deck) {
      byPair.set(c.pairId, (byPair.get(c.pairId) ?? new Set()).add(c.asset));
    }
    for (const assets of byPair.values()) expect(assets.size).toBe(1);
  });

  it('refuses to build when there are too few distinct pictures', () => {
    // The original asserted this; silently reusing a picture would create two
    // "pairs" that look identical and cannot be told apart.
    expect(() => buildDeck(['a', 'b'], 3, noShuffle)).toThrow(/distinct/i);
  });

  it('ignores duplicate assets when counting distinct pictures', () => {
    expect(() => buildDeck(['a', 'a', 'b'], 2, noShuffle)).not.toThrow();
  });

  it('keeps a two-column board so cards stay large', () => {
    expect(REVEAL_MATCH_COLUMNS).toBe(2);
  });
});

describe('matching', () => {
  it('reveals nothing until the first tap', () => {
    const board = boardOf(2);
    expect(board.isFaceUp('card-0-0')).toBe(false);
    expect(board.phase).toBe('idle');
  });

  it('shows one card and waits', () => {
    const board = boardOf(2);
    expect(board.tap('card-0-0', 0).accepted).toBe(true);
    expect(board.isFaceUp('card-0-0')).toBe(true);
    expect(board.phase).toBe('oneSelected');
  });

  it('keeps a matched pair revealed', () => {
    const board = boardOf(2);
    board.tap('card-0-0', 0);
    const outcome = board.tap('card-0-1', 500);

    expect(outcome.resolved?.matched).toBe(true);
    expect(board.isMatched('card-0-0')).toBe(true);
    // Still face-up after the resolution window closes.
    board.settle(9999);
    expect(board.isFaceUp('card-0-0')).toBe(true);
  });

  it('turns a mismatch back over once its window passes', () => {
    const board = boardOf(2, { resolutionMs: 1200 });
    board.tap('card-0-0', 0);
    const outcome = board.tap('card-1-0', 400);

    expect(outcome.resolved?.matched).toBe(false);
    // Still visible while resolving — the patient gets to see both.
    expect(board.isFaceUp('card-0-0')).toBe(true);
    expect(board.settle(1000)).toBe(false);
    expect(board.isFaceUp('card-0-0')).toBe(true);

    expect(board.settle(1600)).toBe(true);
    expect(board.isFaceUp('card-0-0')).toBe(false);
    expect(board.isFaceUp('card-1-0')).toBe(false);
  });

  it('measures the resolution window on active time, not wall clock', () => {
    // The caller passes the recorder's paused-excluding clock. A break during
    // a mismatch must not eat the look-at-it window.
    const board = boardOf(2, { resolutionMs: 1200 });
    board.tap('card-0-0', 0);
    board.tap('card-1-0', 100);
    // Active time barely moved because the session was paused.
    expect(board.settle(200)).toBe(false);
    expect(board.isFaceUp('card-1-0')).toBe(true);
  });

  it('reports the attempt number and the two cards involved', () => {
    const board = boardOf(3);
    board.tap('card-0-0', 0);
    const first = board.tap('card-1-0', 300);
    expect(first.resolved?.attemptNumber).toBe(1);
    expect(first.resolved?.cardIds).toEqual(['card-0-0', 'card-1-0']);

    board.settle(5000);
    board.tap('card-0-0', 6000);
    const second = board.tap('card-0-1', 6200);
    expect(second.resolved?.attemptNumber).toBe(2);
  });

  it('records how long the second card took', () => {
    const board = boardOf(2);
    board.tap('card-0-0', 1000);
    const outcome = board.tap('card-0-1', 1750);
    expect(outcome.resolved?.latencyMs).toBe(750);
  });
});

describe('taps that must be ignored', () => {
  it('ignores a third card while a pair is resolving', () => {
    const board = boardOf(3);
    board.tap('card-0-0', 0);
    board.tap('card-1-0', 100);
    expect(board.tap('card-2-0', 150).accepted).toBe(false);
  });

  it('ignores the same card twice', () => {
    const board = boardOf(2);
    board.tap('card-0-0', 0);
    expect(board.tap('card-0-0', 50).accepted).toBe(false);
  });

  it('ignores an already-matched card', () => {
    const board = boardOf(2);
    board.tap('card-0-0', 0);
    board.tap('card-0-1', 100);
    board.settle(9999);
    expect(board.tap('card-0-0', 10000).accepted).toBe(false);
  });

  it('ignores taps during the guided preview', () => {
    const board = new RevealMatchBoard(deckOf(2), {
      ...revealMatchDifficultyParams(1),
      guidedPreview: true,
    });
    expect(board.previewVisible).toBe(true);
    expect(board.tap('card-0-0', 0).accepted).toBe(false);

    board.dismissPreview();
    expect(board.previewVisible).toBe(false);
    expect(board.tap('card-0-0', 10).accepted).toBe(true);
  });

  it('ignores a card that is not on the board', () => {
    expect(boardOf(2).tap('card-9-9', 0).accepted).toBe(false);
  });

  it('shows every card during the guided preview', () => {
    const board = new RevealMatchBoard(deckOf(2), {
      ...revealMatchDifficultyParams(1),
      guidedPreview: true,
    });
    expect(board.allCards.every((c) => board.isFaceUp(c.id))).toBe(true);
  });
});

describe('completion', () => {
  it('completes only once every pair is found', () => {
    const board = boardOf(2);
    board.tap('card-0-0', 0);
    board.tap('card-0-1', 100);
    board.settle(9999);
    expect(board.isComplete).toBe(false);

    board.tap('card-1-0', 10000);
    board.tap('card-1-1', 10100);
    expect(board.isComplete).toBe(true);
    expect(board.phase).toBe('completed');
  });
});

describe('metrics', () => {
  it('reports null accuracy when nothing was attempted', () => {
    // Not zero. Zero reads as "got everything wrong"; null is "not observed".
    expect(boardOf(2).metrics(false).pairAccuracy).toBeNull();
    expect(boardOf(2).metrics(false).medianSecondCardLatencyMs).toBeNull();
  });

  it('counts pairs, attempts and mismatches', () => {
    const board = boardOf(2);
    board.tap('card-0-0', 0);
    board.tap('card-1-0', 100); // mismatch
    board.settle(9999);
    board.tap('card-0-0', 10000);
    board.tap('card-0-1', 10100); // match
    board.settle(20000);

    const m = board.metrics(false);
    expect(m.resolvedAttempts).toBe(2);
    expect(m.pairsFound).toBe(1);
    expect(m.mismatches).toBe(1);
    expect(m.pairAccuracy).toBeCloseTo(0.5);
  });

  it('takes the median of an even number of latencies', () => {
    const board = boardOf(4);
    board.tap('card-0-0', 0);
    board.tap('card-1-0', 100); // 100ms
    board.settle(9999);
    board.tap('card-2-0', 10000);
    board.tap('card-3-0', 10300); // 300ms
    board.settle(20000);
    expect(board.metrics(false).medianSecondCardLatencyMs).toBe(200);
  });

  it('carries completion through untouched', () => {
    expect(boardOf(2).metrics(true).completion).toBe(true);
  });
});
