/**
 * The shared game boundary, ported from `tesseract_game_contract`.
 *
 * The same rules hold as in the Flutter build, and for the same reasons:
 *
 *  - A game takes **no** network, database or authentication dependency.
 *    Everything it needs arrives in `GameConfig`; everything it reports
 *    leaves through `onEvent` / `onFinish`.
 *  - Event payloads carry **opaque ids only** — never a name, a caregiver's
 *    word, a routine step's text, or anything a person said. There is a test
 *    per game asserting this.
 *  - `seq` starts at 1, increments by exactly 1, and is never reused.
 *  - `elapsedMs` is a monotonic session clock that excludes paused time.
 *  - Using Help always emits `hint_requested` and marks the session assisted.
 *  - A session finalises exactly once.
 *
 * These are runtime invariants, not development-only checks. A duplicated
 * `session_finished` reaching the backend violates "only one finalization is
 * accepted" regardless of build mode, so they throw rather than assert.
 */

/** Lifecycle event types shared by every game. */
export const GameLifecycleEvent = {
  sessionStarted: 'session_started',
  tutorialStarted: 'tutorial_started',
  tutorialCompleted: 'tutorial_completed',
  hintRequested: 'hint_requested',
  supportChanged: 'support_changed',
  paused: 'paused',
  resumed: 'resumed',
  sessionFinished: 'session_finished',
} as const;

export const GameResultStatus = {
  /** The game's own objective was reached. */
  completed: 'completed',
  /** The patient used Break/Finish to end the session before completion. */
  stoppedByUser: 'stopped_by_user',
  /** Ended without an explicit finish, e.g. killed while backgrounded. */
  interrupted: 'interrupted',
} as const;

export type GameResultStatusValue =
  (typeof GameResultStatus)[keyof typeof GameResultStatus];

export const GAME_RESULT_STATUSES: readonly string[] = Object.values(GameResultStatus);

export const GameInputMode = { touch: 'touch', tilt: 'tilt' } as const;
export type GameInputModeValue =
  (typeof GameInputMode)[keyof typeof GameInputMode];

export interface GameEvent {
  type: string;
  /** 1-based, gap-free, session-unique. */
  seq: number;
  /** Monotonic session clock in ms, excluding paused time. */
  elapsedMs: number;
  /** Opaque-id-only event data. */
  payload: Record<string, unknown>;
}

export interface GameResult {
  status: GameResultStatusValue;
  /** `seq` of the final event, so the host can check nothing was lost. */
  finalSeq: number;
  /** True if Help was used at any point this session. */
  assisted: boolean;
}

export interface GameItem {
  id: string;
  /** Display text. Never appears in an event payload. */
  label?: string;
  imageUri?: string;
  extra?: Record<string, unknown>;
}

/**
 * Every user-facing string a game may need, already localised by the host.
 * Games must never hardcode display text.
 */
export interface GameStrings {
  helpButtonLabel: string;
  breakButtonLabel: string;
  pausedTitle: string;
  pausedBody: string;
  resumeButtonLabel: string;
  finishNowButtonLabel: string;
  /** Game-specific strings, keyed by a name that game defines. */
  values: Record<string, string>;
}

/** Looks up a game-specific string; a miss returns '' rather than the key. */
export function gameText(strings: GameStrings, key: string): string {
  return strings.values[key] ?? '';
}

/**
 * Everything a game needs for one session, frozen at level load time.
 * A game never fetches or mutates any of this itself.
 */
export interface GameConfig {
  gameId: string;
  gameVersion: string;
  schemaVersion: string;
  configVersion: string;
  contentVersion: string;
  metricVersion: string;
  level: number;
  difficultyParams: Record<string, unknown>;
  items: GameItem[];
  strings: GameStrings;
  textScale: number;
  inputMode: GameInputModeValue;
  showLabels: boolean;
  locale: string;
  isTutorial: boolean;
}

export interface GameCallbacks {
  onEvent: (event: GameEvent) => void;
  onFinish: (result: GameResult) => void;
}

export interface TesseractGameProps extends GameCallbacks {
  config: GameConfig;
}

/**
 * The single shared implementation of the event rules.
 *
 * One recorder per session. Call `sessionStarted` when play begins,
 * `paused`/`resumed` around breaks and backgrounding, `hintRequested` when
 * Help is used, game types through `custom`, and `sessionFinished` exactly
 * once — then build the `GameResult` from `lastSeq` and `assisted`.
 */
export class TesseractEventRecorder {
  private seq = 0;
  private assistedFlag = false;
  private finished = false;

  /** Accumulated running time, excluding paused stretches. */
  private accumulatedMs = 0;
  private runningSince: number | null = null;

  constructor(private readonly now: () => number = () => Date.now()) {}

  get elapsedMs(): number {
    const live = this.runningSince === null ? 0 : this.now() - this.runningSince;
    return Math.round(this.accumulatedMs + live);
  }

  get lastSeq(): number {
    return this.seq;
  }

  get assisted(): boolean {
    return this.assistedFlag;
  }

  get isPaused(): boolean {
    return this.runningSince === null && this.seq > 0 && !this.finished;
  }

  get isFinished(): boolean {
    return this.finished;
  }

  private emit(type: string, payload: Record<string, unknown> = {}): GameEvent {
    if (this.finished) {
      throw new Error(
        `Event "${type}" was emitted after session_finished. A session ` +
          'finalises exactly once and nothing may follow it.',
      );
    }
    this.seq += 1;
    return { type, seq: this.seq, elapsedMs: this.elapsedMs, payload };
  }

  sessionStarted(payload: Record<string, unknown> = {}): GameEvent {
    if (this.seq !== 0) {
      throw new Error('session_started must be the first event of a session.');
    }
    this.runningSince = this.now();
    return this.emit(GameLifecycleEvent.sessionStarted, payload);
  }

  tutorialStarted(): GameEvent {
    return this.emit(GameLifecycleEvent.tutorialStarted);
  }

  tutorialCompleted(): GameEvent {
    return this.emit(GameLifecycleEvent.tutorialCompleted);
  }

  /** Using Help marks the whole session assisted. This is not reversible. */
  hintRequested(payload: Record<string, unknown> = {}): GameEvent {
    this.assistedFlag = true;
    return this.emit(GameLifecycleEvent.hintRequested, payload);
  }

  supportChanged(payload: Record<string, unknown> = {}): GameEvent {
    return this.emit(GameLifecycleEvent.supportChanged, payload);
  }

  paused(): GameEvent {
    const event = this.emit(GameLifecycleEvent.paused);
    if (this.runningSince !== null) {
      this.accumulatedMs += this.now() - this.runningSince;
      this.runningSince = null;
    }
    return event;
  }

  resumed(): GameEvent {
    if (this.runningSince === null) this.runningSince = this.now();
    return this.emit(GameLifecycleEvent.resumed);
  }

  custom(type: string, payload: Record<string, unknown> = {}): GameEvent {
    if (
      (Object.values(GameLifecycleEvent) as string[]).includes(type)
    ) {
      throw new Error(
        `"${type}" is a lifecycle event; use its dedicated method so the ` +
          'clock and assisted flag stay correct.',
      );
    }
    return this.emit(type, payload);
  }

  sessionFinished(status: GameResultStatusValue): GameEvent {
    if (!GAME_RESULT_STATUSES.includes(status)) {
      throw new Error(`"${status}" is not a valid GameResultStatus.`);
    }
    const event = this.emit(GameLifecycleEvent.sessionFinished, { status });
    if (this.runningSince !== null) {
      this.accumulatedMs += this.now() - this.runningSince;
      this.runningSince = null;
    }
    this.finished = true;
    return event;
  }

  /** The result to hand to `onFinish`, after `sessionFinished`. */
  result(status: GameResultStatusValue): GameResult {
    if (!this.finished) {
      throw new Error('Call sessionFinished() before building a GameResult.');
    }
    return { status, finalSeq: this.seq, assisted: this.assistedFlag };
  }
}
