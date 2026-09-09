import React from 'react';
import { render, fireEvent, screen, act } from '@testing-library/react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  GAME_REGISTRY,
  MISSING_REQUIRED_GAME_IDS,
  REQUIRED_GAME_IDS,
} from '../registry';
import type { GameConfig, GameEvent, GameResult, GameStrings } from '../contract';
import { GameInputMode } from '../contract';
import { topologyForLevel, shortestPath } from '../routeQuest/topology';
import { mazeForLevel, isOpen } from '../marbleMaze/level';
import { buildWordGrid, lineBetween } from '../wordSearch/grid';
import { buildDeck } from '../revealMatch/model';

const strings: GameStrings = {
  helpButtonLabel: 'Help',
  breakButtonLabel: 'Break',
  pausedTitle: 'Taking a break',
  pausedBody: 'Take your time.',
  resumeButtonLabel: 'Continue',
  finishNowButtonLabel: 'Finish for now',
  values: {
    route_go_to: 'Go to',
    route_return_home: 'Now go home',
    route_you_are_here: 'You are here',
    route_destination: 'Destination',
    maze_title: 'Guide the marble',
    maze_hold_still: 'Hold the phone still',
    maze_touch_mode: 'Use your finger',
    maze_motion_mode: 'Tilt to move',
    words_find: 'Find these words',
    words_unavailable: 'No words yet',
    words_some_did_not_fit: 'Some words did not fit',
    routine_what_next: 'What comes next?',
    routine_try_again: 'Not quite. Try again.',
    routine_unavailable: 'No routine yet',
    sorting_where_does_this_go: 'Where does this go?',
    sorting_try_again: 'Not quite. Try again.',
    sorting_unavailable: 'No pictures yet',
    category_kitchen: 'Kitchen',
    category_garden: 'Garden',
    reveal_find_the_pair: 'Find the two that are the same',
    reveal_preview_hint: 'Have a look at the pictures.',
    reveal_ready: 'I am ready',
    reveal_hidden_card: 'A card, face down',
    reveal_unavailable: 'Not enough pictures yet',
  },
};

const makeConfig = (over: Partial<GameConfig> = {}): GameConfig => ({
  gameId: 'x',
  gameVersion: '1',
  schemaVersion: '1',
  configVersion: 'local-v1',
  contentVersion: 'local-v1',
  metricVersion: '1',
  level: 1,
  difficultyParams: {},
  items: [],
  strings,
  textScale: 1,
  inputMode: GameInputMode.touch,
  showLabels: true,
  locale: 'en',
  isTutorial: false,
  ...over,
});

const wrap = (node: React.ReactElement) =>
  render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, left: 0, right: 0, bottom: 34 },
      }}
    >
      <GestureHandlerRootView style={{ flex: 1 }}>{node}</GestureHandlerRootView>
    </SafeAreaProvider>,
  );

/**
 * Personal content is the caregiver's own wording: place names, routine step
 * text, the words they chose, and anyone's name. None of it may appear in an
 * event payload — only opaque ids.
 *
 * Structural ids a game defines for itself (a category key, a wall id, a dead
 * end id) are not personal and are expected in payloads; the Dart original
 * emits them too. This checks the labels the caregiver actually typed.
 */
const NAMES = ['Meera', 'Ravi'];

function assertNoPersonalData(events: GameEvent[], labels: string[]) {
  const blob = JSON.stringify(events.map((e) => e.payload)).toLowerCase();
  for (const word of [...labels, ...NAMES]) {
    expect(blob).not.toContain(word.toLowerCase());
  }
}

describe('the registry states the catalogue honestly', () => {
  it('registers ten activities', () => {
    expect(GAME_REGISTRY).toHaveLength(10);
  });

  it('is all nine required games plus one extra', () => {
    const required = GAME_REGISTRY.filter((g) => g.required);
    const extra = GAME_REGISTRY.filter((g) => !g.required);
    expect(required).toHaveLength(9);
    // Picture Sorting is an extra. It has never counted towards the nine, and
    // must not start counting because the nine are now complete.
    expect(extra.map((g) => g.gameId)).toEqual(['picture_sorting']);
    expect(REQUIRED_GAME_IDS).toHaveLength(9);
  });

  it('has no required game left unregistered', () => {
    expect([...MISSING_REQUIRED_GAME_IDS]).toEqual([]);
  });

  it('gives every required game its own component', () => {
    // The way a catalogue fakes completeness is by pointing two entries at one
    // component — Picture Recall rendering Picture Pairs, say. Distinct
    // components do not prove distinct behaviour, but sharing one disproves it.
    const components = GAME_REGISTRY.filter((g) => g.required).map((g) => g.component);
    expect(new Set(components).size).toBe(components.length);
  });

  it('gives every activity real per-level settings, not a level number', () => {
    for (const game of GAME_REGISTRY) {
      const first = game.difficultyParamsForLevel(1);
      const last = game.difficultyParamsForLevel(game.maxLevel);
      expect(Object.keys(first).length).toBeGreaterThan(0);
      // Levels must actually differ, or "difficulty" is a label on nothing.
      expect(JSON.stringify(first)).not.toEqual(JSON.stringify(last));
    }
  });

  it('attributes every activity to its owner', () => {
    // Reveal Match is Aryan's design, ported; the rest are Ruthika's.
    for (const g of GAME_REGISTRY) {
      expect(['Ruthika', 'Aryan']).toContain(g.owner);
    }
    expect(GAME_REGISTRY.find((g) => g.gameId === 'reveal_match')!.owner).toBe(
      'Aryan',
    );
  });
});

describe('pure game rules', () => {
  it('Route Quest levels have the documented shapes', () => {
    expect(topologyForLevel(1).nodeCount).toBe(3);
    expect(topologyForLevel(1).branchCount).toBe(0);
    expect(topologyForLevel(2).branchCount).toBe(1);
    expect(topologyForLevel(3).branchCount).toBe(2);
  });

  it('Route Quest Help points along a real path', () => {
    const t = topologyForLevel(3);
    const path = shortestPath(t, t.homeIndex, t.destinationIndex);
    expect(path[0]).toBe(t.homeIndex);
    expect(path[path.length - 1]).toBe(t.destinationIndex);
  });

  it('the maze start and goal are both reachable cells', () => {
    for (const level of [1, 2, 3]) {
      const m = mazeForLevel(level);
      expect(isOpen(m, m.start[0], m.start[1])).toBe(true);
      expect(isOpen(m, m.goal[0], m.goal[1])).toBe(true);
    }
  });

  it('maze difficulty reports real settings, not the level number', () => {
    expect(mazeForLevel(1).corridorWidth).toBe(2);
    expect(mazeForLevel(2).deadEndCount).toBe(1);
    expect(mazeForLevel(3).deadEndCount).toBe(2);
  });

  it('places a Bengali syllable in one cell, not one per code point', () => {
    // চা is চ + া: two code points, but one syllable a reader looks for.
    // The previous behaviour gave it two cells, the second holding a bare
    // matra — not a letter anyone can search for.
    const grid = buildWordGrid({
      entries: [{ id: 'w1', word: 'চা' }],
      size: 6,
      wordCount: 3,
      allowDiagonals: false,
      fillAlphabet: ['ক', 'খ', 'গ'],
    });
    const placed = grid.words.find((w) => w.id === 'w1');
    expect(placed).toBeDefined();
    expect(placed!.cells).toHaveLength(1);
    expect(grid.letters[placed!.cells[0]]).toBe('চা');
  });

  it('places a Hindi word by syllable, not by code point', () => {
    // हिन्दी is 6 code points but fewer written units. Splitting by code
    // point put a bare matra in its own cell and mis-sized the word.
    const grid = buildWordGrid({
      entries: [{ id: 'w1', word: 'हिन्दी' }],
      size: 8,
      wordCount: 3,
      allowDiagonals: false,
      fillAlphabet: ['क', 'ख', 'ग'],
    });
    const placed = grid.words.find((w) => w.id === 'w1');
    expect(placed).toBeDefined();
    expect(placed!.cells.length).toBeLessThan(Array.from('हिन्दी').length);
    // Every occupied cell holds a whole syllable, never a lone mark.
    for (const cell of placed!.cells) {
      expect(grid.letters[cell]).not.toMatch(/^[\u093E-\u094D]$/);
    }
  });

  it('reports words that do not fit instead of dropping them', () => {
    const grid = buildWordGrid({
      entries: [{ id: 'long', word: 'extraordinarily' }],
      size: 6,
      wordCount: 3,
      allowDiagonals: false,
      fillAlphabet: ['A'],
    });
    expect(grid.words).toHaveLength(0);
    expect(grid.skipped.map((s) => s.id)).toEqual(['long']);
  });

  it('rejects a selection that is not a straight line', () => {
    expect(lineBetween(6, 0, 8, false)).toBeNull();
    expect(lineBetween(6, 0, 5, false)).toHaveLength(6);
    expect(lineBetween(6, 0, 7, true)).toEqual([0, 7]);
  });
});

describe('Route Quest gameplay', () => {
  const items = [
    { id: 'n0', label: 'Home' },
    { id: 'n1', label: 'Market' },
    { id: 'n2', label: 'Temple' },
  ];

  it('plays a whole session and finishes exactly once', () => {
    const events: GameEvent[] = [];
    const results: GameResult[] = [];
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'route_quest')!;
    wrap(
      <reg.component
        config={makeConfig({ gameId: 'route_quest', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={(r) => results.push(r)}
      />,
    );

    fireEvent.press(screen.getByLabelText('Market'));
    fireEvent.press(screen.getByLabelText('Temple'));
    fireEvent.press(screen.getByLabelText('Market'));
    fireEvent.press(screen.getByLabelText('Home'));

    const types = events.map((e) => e.type);
    expect(types[0]).toBe('session_started');
    expect(types).toContain('destination_reached');
    expect(types).toContain('item_collected');
    expect(types).toContain('return_completed');
    expect(types.filter((t) => t === 'session_finished')).toHaveLength(1);
    expect(results).toHaveLength(1);
    expect(results[0].status).toBe('completed');

    // seq is 1-based and gap-free.
    expect(events.map((e) => e.seq)).toEqual(
      events.map((_, i) => i + 1),
    );
    assertNoPersonalData(events, items.map((i) => i.label));
  });

  it('records a tap on an unconnected place without moving', () => {
    const events: GameEvent[] = [];
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'route_quest')!;
    wrap(
      <reg.component
        config={makeConfig({ gameId: 'route_quest', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={() => {}}
      />,
    );
    // Home connects to Market only; Temple is two hops away.
    fireEvent.press(screen.getByLabelText('Temple'));
    const wrong = events.filter((e) => e.type === 'wrong_interaction');
    expect(wrong).toHaveLength(1);
    expect(wrong[0].payload).toEqual({ objectId: 'n2' });
    assertNoPersonalData(events, items.map((i) => i.label));
  });

  it('Help marks the session assisted', () => {
    const events: GameEvent[] = [];
    const results: GameResult[] = [];
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'route_quest')!;
    wrap(
      <reg.component
        config={makeConfig({ gameId: 'route_quest', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={(r) => results.push(r)}
      />,
    );
    fireEvent.press(screen.getByLabelText('Help'));
    fireEvent.press(screen.getByLabelText('Break'));
    fireEvent.press(screen.getByLabelText('Finish for now'));
    expect(events.map((e) => e.type)).toContain('hint_requested');
    expect(results[0].assisted).toBe(true);
    expect(results[0].status).toBe('stopped_by_user');
  });
});

describe('Daily Routine Recall gameplay', () => {
  const items = [
    { id: 's1', label: 'Wake up' },
    { id: 's2', label: 'Brush teeth' },
    { id: 's3', label: 'Have tea' },
  ];

  it('keeps a wrong answer open with no penalty and counts the attempt', () => {
    const events: GameEvent[] = [];
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'routine_recall')!;
    wrap(
      <reg.component
        config={makeConfig({ gameId: 'routine_recall', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={() => {}}
      />,
    );

    fireEvent.press(screen.getByLabelText('Brush teeth')); // wrong first
    fireEvent.press(screen.getByLabelText('Wake up')); // then right

    const attempts = events.filter((e) => e.type === 'attempt_resolved');
    expect(attempts[0].payload).toMatchObject({ correct: false, attempt: 1 });
    expect(attempts[1].payload).toMatchObject({ correct: true, attempt: 2 });
    // Step text never travels — only ids.
    assertNoPersonalData(events, items.map((i) => i.label));
  });

  it('says so when there is no routine rather than showing an empty game', () => {
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'routine_recall')!;
    wrap(
      <reg.component
        config={makeConfig({ gameId: 'routine_recall', items: [] })}
        onEvent={() => {}}
        onFinish={() => {}}
      />,
    );
    expect(screen.getByText('No routine yet')).toBeTruthy();
  });
});

describe('Picture Sorting gameplay', () => {
  const items = [
    { id: 'i1', label: 'Kettle', extra: { categoryId: 'kitchen' } },
    { id: 'i2', label: 'Spade', extra: { categoryId: 'garden' } },
  ];

  it('completes once every picture is sorted', () => {
    const events: GameEvent[] = [];
    const results: GameResult[] = [];
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'picture_sorting')!;
    wrap(
      <reg.component
        config={makeConfig({ gameId: 'picture_sorting', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={(r) => results.push(r)}
      />,
    );
    fireEvent.press(screen.getByLabelText('Kitchen'));
    fireEvent.press(screen.getByLabelText('Garden'));

    expect(events.map((e) => e.type)).toContain('sorting_completed');
    expect(results[0].status).toBe('completed');
    expect(
      events.filter((e) => e.type === 'session_finished'),
    ).toHaveLength(1);
    // The picture labels are the personal part; the category key is not.
    assertNoPersonalData(events, items.map((i) => i.label));
  });
});

describe('Word Search gameplay', () => {
  it('reports a caregiver word that will not fit', () => {
    const events: GameEvent[] = [];
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'word_search')!;
    wrap(
      <reg.component
        config={makeConfig({
          gameId: 'word_search',
          level: 1,
          items: [
            { id: 'w1', label: 'tea' },
            { id: 'w2', label: 'absolutelyenormousword' },
          ],
        })}
        onEvent={(e) => events.push(e)}
        onFinish={() => {}}
      />,
    );
    const unavailable = events.find((e) => e.type === 'content_unavailable');
    expect(unavailable).toBeDefined();
    expect(unavailable!.payload).toMatchObject({
      reason: 'word_does_not_fit_grid',
      wordIds: ['w2'],
    });
    // The word itself must not be in the payload — only its id.
    expect(JSON.stringify(unavailable!.payload)).not.toContain('enormous');
  });

  it('says so when there are no usable words', () => {
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'word_search')!;
    wrap(
      <reg.component
        config={makeConfig({ gameId: 'word_search', items: [] })}
        onEvent={() => {}}
        onFinish={() => {}}
      />,
    );
    expect(screen.getByText('No words yet')).toBeTruthy();
  });
});

describe('Marble Maze', () => {
  it('falls back to touch and says so when there is no motion sensor', async () => {
    // The mocked expo-sensors reports no motion available, which is exactly
    // the case this must handle honestly.
    const reg = GAME_REGISTRY.find((g) => g.gameId === 'marble_maze')!;
    wrap(
      <reg.component
        config={makeConfig({
          gameId: 'marble_maze',
          level: 1,
          inputMode: GameInputMode.tilt,
        })}
        onEvent={() => {}}
        onFinish={() => {}}
      />,
    );
    expect(await screen.findAllByText('Use your finger')).not.toHaveLength(0);
  });
});

describe('Reveal Match gameplay', () => {
  const items = [
    { id: 'p1', label: 'Teacup' },
    { id: 'p2', label: 'Flower' },
    { id: 'p3', label: 'Umbrella' },
    { id: 'p4', label: 'Slippers' },
  ];
  const reg = () => GAME_REGISTRY.find((g) => g.gameId === 'reveal_match')!;

  /**
   * The deck is shuffled, so the board is pinned by fixing Math.random and
   * then asking the model for the same order the component will get. Nothing
   * about the arrangement is hardcoded here.
   */
  const pinnedOrder = (pairs: number) => {
    jest.spyOn(Math, 'random').mockReturnValue(0);
    return buildDeck(items.map((i) => i.id), pairs);
  };

  beforeEach(() => jest.useFakeTimers());
  afterEach(() => {
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  const cards = () => screen.getAllByLabelText('A card, face down');

  /**
   * Presses the card at a position in the pinned deck.
   *
   * Only face-down cards carry the hidden-card label, so once some are turned
   * over the visible list is shorter — `faceUp` is the set of deck positions
   * already showing, which shifts the query index down.
   */
  const pressCard = (deckIndex: number, faceUp: Set<number>) => {
    const shift = [...faceUp].filter((i) => i < deckIndex).length;
    fireEvent.press(cards()[deckIndex - shift]);
    faceUp.add(deckIndex);
  };

  it('plays a whole session and finishes exactly once', () => {
    const order = pinnedOrder(2);
    const events: GameEvent[] = [];
    const results: GameResult[] = [];
    const Game = reg().component;
    wrap(
      <Game
        config={makeConfig({ gameId: 'reveal_match', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={(r) => results.push(r)}
      />,
    );

    // Level 1 opens with the guided preview: every card is already face-up,
    // so there is nothing face-down to tap yet.
    expect(screen.queryAllByLabelText('A card, face down')).toHaveLength(0);
    fireEvent.press(screen.getByLabelText('I am ready'));

    // Matched cards stay face-up, so what is revealed accumulates.
    const faceUp = new Set<number>();
    for (const pairId of ['pair-0', 'pair-1']) {
      const idx = order
        .map((c, i) => (c.pairId === pairId ? i : -1))
        .filter((i) => i >= 0);
      pressCard(idx[0], faceUp);
      pressCard(idx[1], faceUp);
      act(() => jest.advanceTimersByTime(2000));
    }

    const types = events.map((e) => e.type);
    expect(types[0]).toBe('session_started');
    expect(types.filter((x) => x === 'card_revealed')).toHaveLength(4);
    expect(types.filter((x) => x === 'pair_resolved')).toHaveLength(2);
    expect(types).toContain('board_cleared');
    expect(types.filter((x) => x === 'session_finished')).toHaveLength(1);
    expect(results).toHaveLength(1);
    expect(results[0].status).toBe('completed');
    expect(results[0].assisted).toBe(false);

    // seq is 1-based and gap-free.
    expect(events.map((e) => e.seq)).toEqual(events.map((_, i) => i + 1));
    assertNoPersonalData(events, items.map((i) => i.label));
  });

  it('turns a mismatch back over and tells the patient nothing about it', () => {
    const order = pinnedOrder(2);
    const events: GameEvent[] = [];
    const Game = reg().component;
    wrap(
      <Game
        config={makeConfig({ gameId: 'reveal_match', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={() => {}}
      />,
    );
    fireEvent.press(screen.getByLabelText('I am ready'));

    const a = order.findIndex((c) => c.pairId === 'pair-0');
    const b = order.findIndex((c) => c.pairId === 'pair-1');
    const faceUp = new Set<number>();
    pressCard(a, faceUp);
    pressCard(b, faceUp);

    const resolved = events.filter((e) => e.type === 'pair_resolved');
    expect(resolved).toHaveLength(1);
    expect(resolved[0].payload.matched).toBe(false);
    // Nothing about a mismatch reaches the screen: no score, no "wrong".
    expect(screen.queryByText(/wrong|not quite|try again/i)).toBeNull();

    act(() => jest.advanceTimersByTime(2000));
    // Both are face-down again, and the session is still going.
    expect(cards()).toHaveLength(4);
    expect(events.map((e) => e.type)).not.toContain('session_finished');
  });

  it('keeps the hidden picture out of the accessibility label', () => {
    pinnedOrder(2);
    const Game = reg().component;
    wrap(
      <Game
        config={makeConfig({ gameId: 'reveal_match', items, level: 1 })}
        onEvent={() => {}}
        onFinish={() => {}}
      />,
    );
    fireEvent.press(screen.getByLabelText('I am ready'));
    // A screen reader must not be able to solve the board by listening.
    for (const label of items.map((i) => i.label)) {
      expect(screen.queryByLabelText(label)).toBeNull();
    }
    expect(cards()).toHaveLength(4);
  });

  it('Help marks the session assisted and never plays the move', () => {
    pinnedOrder(2);
    const events: GameEvent[] = [];
    const results: GameResult[] = [];
    const Game = reg().component;
    wrap(
      <Game
        config={makeConfig({ gameId: 'reveal_match', items, level: 1 })}
        onEvent={(e) => events.push(e)}
        onFinish={(r) => results.push(r)}
      />,
    );
    fireEvent.press(screen.getByLabelText('I am ready'));
    fireEvent.press(screen.getByLabelText('Help'));
    // Help highlights a pair; it does not reveal or match it.
    expect(cards()).toHaveLength(4);
    expect(events.map((e) => e.type)).toContain('hint_requested');

    fireEvent.press(screen.getByLabelText('Break'));
    fireEvent.press(screen.getByLabelText('Finish for now'));
    expect(results[0].assisted).toBe(true);
    expect(results[0].status).toBe('stopped_by_user');
    expect(events.map((e) => e.type).filter((x) => x === 'session_finished')).toHaveLength(1);
  });

  it('says so plainly when there are too few pictures for a pair', () => {
    const Game = reg().component;
    wrap(
      <Game
        config={makeConfig({ gameId: 'reveal_match', items: [items[0]], level: 1 })}
        onEvent={() => {}}
        onFinish={() => {}}
      />,
    );
    expect(screen.getByText('Not enough pictures yet')).toBeTruthy();
  });
});
