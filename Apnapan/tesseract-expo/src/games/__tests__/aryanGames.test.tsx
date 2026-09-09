/**
 * The four activities ported from Aryan's staged Flutter package on
 * 2026-09-09: Trace (G4), Coloring (G5), Spot Difference (G6) and Picture
 * Recall (G9).
 *
 * Two kinds of test here, and both matter:
 *
 *  - **Model tests** exercise the rules directly. They are where the geometry,
 *    the hit testing and the coverage arithmetic are actually checked.
 *  - **Host integration tests** mount each game *through the registry*, the way
 *    the app does, and drive it with real presses. They are what catches a game
 *    that computes correctly and renders nothing.
 */
import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { GAME_REGISTRY } from '../registry';
import type { GameConfig, GameEvent, GameResult, GameStrings } from '../contract';
import { GameInputMode } from '../contract';
import { GAME_TEXT_EN } from '../gameText';
import {
  DIFFERENCE_PAIRS,
  RECALL_SCENES,
  TRACE_TEMPLATES,
  PICTURES,
  pictureById,
} from '../../content/pictures';
import {
  PictureRecallBoard,
  pictureRecallDifficultyParams,
  sceneForIndex,
} from '../pictureRecall/model';
import {
  SpotDifferenceBoard,
  hitDifference,
  pairForParams,
  spotDifferenceDifficultyParams,
} from '../spotDifference/model';
import { ColoringCanvas, coloringDifficultyParams } from '../coloring/model';
import { TraceBoard, referenceBins, traceDifficultyParams } from '../trace/model';

const strings: GameStrings = {
  helpButtonLabel: 'Help',
  breakButtonLabel: 'Break',
  pausedTitle: 'Taking a break',
  pausedBody: 'Take your time.',
  resumeButtonLabel: 'Continue',
  finishNowButtonLabel: 'Finish for now',
  // The real English catalogue, so a missing key fails here rather than
  // rendering an empty label on a phone.
  values: GAME_TEXT_EN,
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

/** Mounts a game exactly as the host does: by looking it up in the registry. */
function mount(gameId: string, level = 1) {
  const registration = GAME_REGISTRY.find((g) => g.gameId === gameId)!;
  const events: GameEvent[] = [];
  const results: GameResult[] = [];
  const Game = registration.component;
  wrap(
    <Game
      config={makeConfig({
        gameId,
        level,
        difficultyParams: registration.difficultyParamsForLevel(level),
      })}
      onEvent={(e) => events.push(e)}
      onFinish={(r) => results.push(r)}
    />,
  );
  return { events, results, registration };
}

const types = (events: GameEvent[]) => events.map((e) => e.type);

/** Every activity owes the host the same lifecycle guarantees. */
function assertLifecycle(events: GameEvent[], results: GameResult[]) {
  expect(types(events)[0]).toBe('session_started');
  expect(types(events).filter((t) => t === 'session_finished')).toHaveLength(1);
  expect(results).toHaveLength(1);
  // seq is 1-based and gap-free; the backend rejects a hole.
  expect(events.map((e) => e.seq)).toEqual(events.map((_, i) => i + 1));
}

/* ====================================================== bundled pictures = */

describe('the bundled picture catalogue', () => {
  it('has artwork for every picture a game refers to', () => {
    const referenced = new Set<string>();
    for (const pair of DIFFERENCE_PAIRS) {
      referenced.add(pair.leftPictureId);
      referenced.add(pair.rightPictureId);
    }
    for (const scene of RECALL_SCENES) {
      referenced.add(scene.scenePictureId);
      for (const q of scene.questions) for (const c of q.choices) referenced.add(c.imageId);
    }
    for (const id of referenced) {
      // A missing picture would render as a blank card at demo time.
      expect(pictureById(id)).toBeDefined();
    }
  });

  it('draws every picture from primitives, with no remote URL anywhere', () => {
    // Offline by construction. A broken image link in front of a patient is
    // not an acceptable failure mode.
    const blob = JSON.stringify(PICTURES);
    expect(blob).not.toMatch(/https?:\/\//);
    for (const picture of PICTURES) {
      expect(picture.primitives.length).toBeGreaterThan(0);
    }
  });

  it('gives every recall question a correct answer that is on offer', () => {
    for (const scene of RECALL_SCENES) {
      for (const question of scene.questions) {
        expect(question.choices.some((c) => c.id === question.correctChoiceId)).toBe(true);
        expect(question.choices.length).toBeGreaterThanOrEqual(2);
      }
    }
  });
});

/* ================================================= G9 — Picture Recall = */

describe('Picture Recall (G9) model', () => {
  const board = () =>
    new PictureRecallBoard(sceneForIndex(0), {
      ...pictureRecallDifficultyParams(2),
      allowShowAgain: true,
    });

  it('starts by showing the scene, not by asking', () => {
    expect(board().phase).toBe('viewing');
  });

  it('will not accept an answer while the picture is still up', () => {
    const b = board();
    const choice = b.question!.choices[0].id;
    expect(b.answer(choice, 100)).toBeNull();
  });

  it('moves to the question once the patient says they have looked', () => {
    const b = board();
    expect(b.ready(500)).toBe(true);
    expect(b.phase).toBe('question');
  });

  it('counts looking again as support, never as a wrong answer', () => {
    const b = board();
    b.ready(500);
    expect(b.showAgain(700)).toBe(true);
    expect(b.phase).toBe('viewing');
    b.ready(1200);

    const answer = b.answer(b.question!.correctChoiceId, 1500)!;
    expect(answer.correct).toBe(true);
    expect(answer.supported).toBe(true);
    expect(answer.showAgainCount).toBe(1);
  });

  it('keeps exposure and answer time on separate clocks', () => {
    const b = board();
    b.ready(2000);
    // 2s looking, then answering starts from zero.
    expect(b.exposureMs(2000)).toBe(2000);
    const answer = b.answer(b.question!.choices[0].id, 2600)!;
    expect(answer.latencyMs).toBe(600);
  });

  it('never trims the correct answer away when a level shows fewer choices', () => {
    const b = new PictureRecallBoard(sceneForIndex(0), {
      questionCount: 1,
      choiceCount: 2,
      allowShowAgain: false,
    });
    const ids = b.choices().map((c) => c.id);
    expect(ids).toContain(b.question!.correctChoiceId);
  });

  it('never asks more questions than the scene authored', () => {
    const scene = sceneForIndex(0);
    const b = new PictureRecallBoard(scene, {
      questionCount: 99,
      choiceCount: 2,
      allowShowAgain: false,
    });
    expect(b.questionTotal).toBe(scene.questions.length);
  });

  it('lets a question be passed over without it counting as answered', () => {
    const b = board();
    b.ready(100);
    expect(b.skip(200)).toBe(true);
    const metrics = b.metrics(false, 300);
    expect(metrics.questionsSkipped).toBe(1);
    expect(metrics.questionsAnswered).toBe(0);
    expect(metrics.firstAttemptAccuracy).toBeNull();
  });

  it('reports null accuracy when nothing was answered, never zero', () => {
    // Zero reads as "got everything wrong"; null is "not observed".
    expect(board().metrics(false, 0).firstAttemptAccuracy).toBeNull();
    expect(board().metrics(false, 0).unsupportedAccuracy).toBeNull();
  });

  it('separates accuracy with support from accuracy without it', () => {
    const b = board();
    b.ready(0);
    b.showAgain(10);
    b.ready(20);
    b.answer(b.question!.correctChoiceId, 30); // supported, correct
    b.next(40);
    b.answer(b.question!.correctChoiceId, 50); // still supported: count carries
    const m = b.metrics(true, 60);
    expect(m.firstAttemptAccuracy).toBe(1);
    expect(m.unsupportedAccuracy).toBeNull();
  });
});

describe('Picture Recall (G9) through the host', () => {
  it('shows the scene, asks a question, and finishes exactly once', () => {
    const { events, results } = mount('picture_recall', 1);

    expect(types(events)).toContain('picture_presented');
    fireEvent.press(screen.getByLabelText('I have looked'));
    expect(types(events)).toContain('picture_hidden');

    const scene = sceneForIndex(0);
    const question = scene.questions[0];
    const correct = question.choices.find((c) => c.id === question.correctChoiceId)!;
    fireEvent.press(screen.getByLabelText(correct.label));

    expect(types(events)).toContain('recall_answered');
    assertLifecycle(events, results);
    expect(results[0].status).toBe('completed');
  });

  it('lets the patient look again, and records it as support', () => {
    const { events } = mount('picture_recall', 1);
    fireEvent.press(screen.getByLabelText('I have looked'));
    fireEvent.press(screen.getByLabelText('Show me again'));
    expect(types(events)).toContain('picture_shown_again');
    // Back to the scene, so the Ready control is on screen again.
    expect(screen.getByLabelText('I have looked')).toBeTruthy();
  });

  it('passes a question over without answering it', () => {
    const { events, results } = mount('picture_recall', 1);
    fireEvent.press(screen.getByLabelText('I have looked'));
    fireEvent.press(screen.getByLabelText('Pass this one'));
    expect(types(events)).toContain('question_skipped');
    expect(types(events)).not.toContain('recall_answered');
    assertLifecycle(events, results);
  });

  it('ignores repeated presses on a choice after it has finished', () => {
    const { events, results } = mount('picture_recall', 1);
    fireEvent.press(screen.getByLabelText('I have looked'));
    const question = sceneForIndex(0).questions[0];
    const correct = question.choices.find((c) => c.id === question.correctChoiceId)!;

    // A patient with tremor double-taps. The second press must change nothing.
    fireEvent.press(screen.getByLabelText(correct.label));
    fireEvent.press(screen.getByLabelText(correct.label));
    fireEvent.press(screen.getByLabelText(correct.label));

    expect(types(events).filter((x) => x === 'recall_answered')).toHaveLength(1);
    assertLifecycle(events, results);
  });

  it('keeps the prompt and the labels out of every payload', () => {
    const { events } = mount('picture_recall', 1);
    fireEvent.press(screen.getByLabelText('I have looked'));
    const question = sceneForIndex(0).questions[0];
    fireEvent.press(screen.getByLabelText(question.choices[0].label));

    const blob = JSON.stringify(events.map((e) => e.payload)).toLowerCase();
    expect(blob).not.toContain(question.prompt.toLowerCase());
    for (const choice of question.choices) {
      expect(blob).not.toContain(choice.label.toLowerCase());
    }
  });
});

/* =============================================== G6 — Spot Difference = */

describe('Spot Difference (G6) model', () => {
  const params = spotDifferenceDifficultyParams(3);
  const pair = pairForParams(params)!;
  const board = () => new SpotDifferenceBoard(pair, params);

  it('has an authored pair for every level', () => {
    for (const level of [1, 2, 3]) {
      expect(pairForParams(spotDifferenceDifficultyParams(level))).not.toBeNull();
    }
  });

  it('finds the difference under a tap inside its region', () => {
    const region = pair.regions[0];
    const hit = hitDifference(pair.regions, region.left + region.width / 2, region.top + region.height / 2);
    expect(hit?.id).toBe(region.id);
  });

  it('ignores a tap outside the picture entirely', () => {
    expect(hitDifference(pair.regions, -0.2, 0.5)).toBeNull();
    expect(hitDifference(pair.regions, 0.5, 1.4)).toBeNull();
  });

  it('lets an exact region beat another region’s forgiveness margin', () => {
    // The rule the original is explicit about: margins never steal a tap that
    // landed squarely inside a different difference.
    const regions = [
      { id: 'far', left: 0.0, top: 0.0, width: 0.1, height: 0.1, margin: 0.9 },
      { id: 'exact', left: 0.5, top: 0.5, width: 0.1, height: 0.1, margin: 0.0 },
    ];
    expect(hitDifference(regions, 0.55, 0.55)?.id).toBe('exact');
  });

  it('recognises tapping the same difference twice as a repeat', () => {
    const b = board();
    const region = pair.regions[0];
    const x = region.left + region.width / 2;
    const y = region.top + region.height / 2;
    expect(b.select(x, y, 100).alreadyFound).toBe(false);
    const second = b.select(x, y, 200);
    expect(second.correct).toBe(true);
    expect(second.alreadyFound).toBe(true);
    // A repeat must not be recorded as a miss.
    expect(b.metrics(false).nonMatchingTaps).toBe(0);
  });

  it('completes only when every difference has been found', () => {
    const b = board();
    for (const region of pair.regions.slice(0, -1)) {
      b.select(region.left + region.width / 2, region.top + region.height / 2, 100);
    }
    expect(b.isComplete).toBe(false);
    const last = pair.regions[pair.regions.length - 1];
    b.select(last.left + last.width / 2, last.top + last.height / 2, 200);
    expect(b.isComplete).toBe(true);
  });

  it('points at a difference the patient has not found yet', () => {
    const b = board();
    const first = pair.regions[0];
    b.select(first.left + first.width / 2, first.top + first.height / 2, 10);
    const hinted = b.requestHint();
    if (pair.regions.length > 1) expect(hinted).not.toBe(first.id);
    expect(b.metrics(false).hintsUsed).toBe(1);
  });

  it('records the time to the first difference, and null when there was none', () => {
    expect(board().metrics(false).timeToFirstFoundMs).toBeNull();
    const b = board();
    const region = pair.regions[0];
    b.select(region.left + region.width / 2, region.top + region.height / 2, 4200);
    expect(b.metrics(false).timeToFirstFoundMs).toBe(4200);
  });
});

describe('Spot Difference (G6) through the host', () => {
  it('mounts, accepts a tap and finishes exactly once', () => {
    const { events, results, registration } = mount('spot_difference', 1);
    const params = registration.difficultyParamsForLevel(1) as any;
    const pair = pairForParams(params)!;

    const panels = screen.getAllByLabelText('Tap where you see something different');
    expect(panels.length).toBe(2);

    // The panel measures itself, so the test tells it a size and then taps in
    // that same coordinate space — exactly what a real layout does.
    const size = 300;
    fireEvent(panels[0], 'layout', { nativeEvent: { layout: { width: size, height: size } } });

    for (const region of pair.regions) {
      fireEvent.press(panels[0], {
        nativeEvent: {
          locationX: (region.left + region.width / 2) * size,
          locationY: (region.top + region.height / 2) * size,
        },
      });
    }

    expect(types(events)).toContain('difference_selected');
    expect(types(events)).toContain('puzzle_finished');
    assertLifecycle(events, results);
    expect(results[0].status).toBe('completed');
  });

  it('never puts a tap coordinate in a payload', () => {
    const { events } = mount('spot_difference', 1);
    const panels = screen.getAllByLabelText('Tap where you see something different');
    fireEvent(panels[0], 'layout', { nativeEvent: { layout: { width: 300, height: 300 } } });
    fireEvent.press(panels[0], {
      nativeEvent: { locationX: 137.5, locationY: 201.25 },
    });
    const blob = JSON.stringify(events.map((e) => e.payload));
    expect(blob).not.toContain('137');
    expect(blob).not.toContain('201');
  });
});

/* ====================================================== G5 — Coloring = */

describe('Coloring (G5) model', () => {
  const canvas = () => new ColoringCanvas(coloringDifficultyParams(1));

  it('starts with nothing revealed', () => {
    expect(canvas().coverage).toBe(0);
    expect(canvas().isComplete).toBe(false);
  });

  it('reveals as a finger sweeps across', () => {
    const c = canvas();
    c.begin({ x: 0.1, y: 0.5 }, 0);
    c.extend({ x: 0.5, y: 0.5 });
    c.extend({ x: 0.9, y: 0.5 });
    expect(c.coverage).toBeGreaterThan(0);
  });

  it('ignores a finger that has not really moved', () => {
    const c = canvas();
    c.begin({ x: 0.5, y: 0.5 }, 0);
    // Below the resample step: recording this would grow the path for nothing.
    expect(c.extend({ x: 0.5005, y: 0.5 })).toBe(false);
  });

  it('does not require every part to be uncovered', () => {
    // The confirmed product rule: no pixel-perfect completion requirement.
    expect(coloringDifficultyParams(1).completionCoverage).toBeLessThan(1);
    expect(coloringDifficultyParams(3).completionCoverage).toBeLessThan(1);
  });

  it('keeps what was revealed across a pause', () => {
    const c = canvas();
    c.begin({ x: 0.1, y: 0.5 }, 0);
    c.extend({ x: 0.9, y: 0.5 });
    c.end(1000);
    const before = c.coverage;
    // Nothing about pausing touches the canvas; a later stroke adds to it.
    c.begin({ x: 0.1, y: 0.6 }, 9000);
    c.extend({ x: 0.9, y: 0.6 });
    c.end(9500);
    expect(c.coverage).toBeGreaterThan(before);
  });

  it('counts only time with a finger down, not time on screen', () => {
    const c = canvas();
    c.begin({ x: 0.1, y: 0.1 }, 1000);
    c.extend({ x: 0.4, y: 0.1 });
    c.end(1600);
    // 600ms of sweeping, even though 30s of session may have passed.
    expect(c.interactionMs(30000)).toBe(600);
  });

  it('shows the whole picture when asked, and records that as help', () => {
    const c = canvas();
    c.showPicture();
    expect(c.displayCoverage).toBe(1);
    expect(c.isComplete).toBe(true);
    expect(c.metrics(true, 0).helpUsed).toBe(true);
  });

  it('caps a single stroke so a long session cannot grow without bound', () => {
    const c = canvas();
    c.begin({ x: 0, y: 0.5 }, 0);
    for (let i = 0; i < 3000; i++) c.extend({ x: (i % 100) / 100, y: 0.5 });
    expect(c.strokes[0].length).toBeLessThanOrEqual(400);
  });
});

describe('Coloring (G5) through the host', () => {
  it('mounts and finishes exactly once when the picture is shown', () => {
    const { events, results } = mount('coloring', 1);
    fireEvent.press(screen.getByLabelText('Help'));
    expect(types(events)).toContain('picture_shown');

    // Coloring keeps its own gentle exit on the play surface.
    fireEvent.press(screen.getByLabelText('That is enough'));
    expect(types(events)).toContain('reveal_finished');
    assertLifecycle(events, results);
    expect(results[0].status).toBe('stopped_by_user');
    // Using Help is support, and the host records it as an assisted session.
    expect(results[0].assisted).toBe(true);
  });

  it('can be finished early without revealing anything', () => {
    const { events, results } = mount('coloring', 1);
    fireEvent.press(screen.getByLabelText('That is enough'));
    assertLifecycle(events, results);
    expect(results[0].assisted).toBe(false);
  });
});

/* ========================================================= G4 — Trace = */

describe('Trace (G4) model', () => {
  const template = TRACE_TEMPLATES[0];
  const board = (level = 1) =>
    new TraceBoard(
      template.path.map(([x, y]) => ({ x, y })),
      { ...traceDifficultyParams(level), corridorWidth: template.corridorWidth },
    );

  it('has a template for every level', () => {
    for (const level of [1, 2, 3]) {
      expect(TRACE_TEMPLATES[(level - 1) % TRACE_TEMPLATES.length]).toBeDefined();
    }
  });

  it('spaces bins by arc length, not by index', () => {
    // A path whose first segment is ten times the second. Half the bins must
    // land in the long part, which index-based binning would not do.
    const bins = referenceBins([{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 0.1 }], 10);
    expect(bins).toHaveLength(10);
    const inLongSegment = bins.filter((b) => b.y < 0.001).length;
    expect(inLongSegment).toBeGreaterThan(6);
  });

  it('marks progress as a finger follows the line', () => {
    const b = board();
    expect(b.coverage).toBe(0);
    b.begin({ x: template.path[0][0], y: template.path[0][1] });
    for (const [x, y] of template.path) b.extend({ x, y });
    expect(b.coverage).toBeGreaterThan(0.5);
  });

  it('finishes without demanding every last bin', () => {
    // Precision is exactly what this activity must not require.
    expect(traceDifficultyParams(1).completionCoverage).toBeLessThan(1);
  });

  it('lets the patient lift a finger and carry on from the middle', () => {
    const b = board();
    const half = Math.floor(template.path.length / 2);
    b.begin({ x: template.path[0][0], y: template.path[0][1] });
    for (const [x, y] of template.path.slice(0, half)) b.extend({ x, y });
    b.endStroke();
    const afterFirst = b.coverage;

    b.begin({ x: template.path[half][0], y: template.path[half][1] });
    for (const [x, y] of template.path.slice(half)) b.extend({ x, y });
    b.endStroke();
    expect(b.coverage).toBeGreaterThan(afterFirst);
    expect(b.metrics(false).strokeCount).toBe(2);
  });

  it('gives harder levels a narrower corridor, not a longer line', () => {
    expect(traceDifficultyParams(3).corridorWidth).toBeLessThan(
      traceDifficultyParams(1).corridorWidth,
    );
  });

  it('reports deviation as null until something has been drawn', () => {
    expect(board().metrics(false).normalizedDeviation).toBeNull();
  });

  it('rejects a point outside the board', () => {
    const b = board();
    expect(b.begin({ x: 1.5, y: 0.5 })).toBe(false);
    expect(b.begin({ x: Number.NaN, y: 0.5 })).toBe(false);
  });
});

describe('Trace (G4) through the host', () => {
  it('mounts, shows the guide on Help, and finishes exactly once', () => {
    const { events, results } = mount('trace', 1);
    fireEvent.press(screen.getByLabelText('Help'));
    expect(types(events)).toContain('guide_shown');

    // Finish lives on the pause overlay, which is the reachable exit.
    fireEvent.press(screen.getByLabelText('Break'));
    fireEvent.press(screen.getByLabelText('Finish for now'));
    expect(types(events)).toContain('trace_finished');
    assertLifecycle(events, results);
    expect(results[0].assisted).toBe(true);
  });

  it('records no raw coordinates in any payload', () => {
    const { events } = mount('trace', 1);
    fireEvent.press(screen.getByLabelText('Help'));
    fireEvent.press(screen.getByLabelText('Break'));
    fireEvent.press(screen.getByLabelText('Finish for now'));
    for (const event of events) {
      for (const value of Object.values(event.payload)) {
        // Percentages and counts are whole numbers; a coordinate is not.
        if (typeof value === 'number') expect(Number.isInteger(value)).toBe(true);
      }
    }
  });
});

/* ============================================ every game, one more time = */

describe('every registered activity', () => {
  it.each(GAME_REGISTRY.map((g) => [g.gameId, g]))(
    '%s starts, pauses, resumes and finishes exactly once',
    (_id, registration: any) => {
      const events: GameEvent[] = [];
      const results: GameResult[] = [];
      const Game = registration.component;
      wrap(
        <Game
          config={makeConfig({
            gameId: registration.gameId,
            level: 1,
            difficultyParams: registration.difficultyParamsForLevel(1),
            items: [
              { id: 'p1', label: 'Teacup' },
              { id: 'p2', label: 'Flower' },
              { id: 'p3', label: 'Umbrella' },
              { id: 'p4', label: 'Slippers' },
              { id: 'p5', label: 'Window' },
              { id: 'p6', label: 'Garden' },
            ],
          })}
          onEvent={(e: GameEvent) => events.push(e)}
          onFinish={(r: GameResult) => results.push(r)}
        />,
      );

      fireEvent.press(screen.getByLabelText('Break'));
      fireEvent.press(screen.getByLabelText('Continue'));
      fireEvent.press(screen.getByLabelText('Break'));
      // Finishing from the pause overlay is the reachable exit.
      fireEvent.press(screen.getByLabelText('Finish for now'));
      // The control goes away with the overlay, so it cannot be pressed twice.
      expect(screen.queryByLabelText('Finish for now')).toBeNull();

      expect(types(events)).toContain('paused');
      expect(types(events)).toContain('resumed');
      assertLifecycle(events, results);
      expect(results[0].status).toBe('stopped_by_user');
    },
  );
});
