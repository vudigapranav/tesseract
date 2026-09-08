/**
 * Marble Maze (G3), ported from marble_maze.
 *
 * Original gameplay and design: Ruthika. Platform port only — rules, events,
 * difficulty settings and the motion-first stance are unchanged.
 *
 * Motion-first with a real touch fallback. If the device has no motion sensor,
 * or motion never produces samples, the game says so and switches to touch —
 * and the mode it reports is the mode that was actually used. It is never
 * fabricated, which is why `actual_input_mode` is only ever set from
 * `motionActuallyUsed`.
 *
 * Events: collision {wallId}, dead_end_entered {deadEndId}, goal_reached.
 */
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { View } from 'react-native';
import Svg, { Circle, Defs, G, RadialGradient, Rect, Stop } from 'react-native-svg';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { colors } from '../../design/tokens';
import { BodyMedium, StatusNote } from '../../design/components';
import { GameScaffold } from '../GameScaffold';
import { GameLayout } from '../presentation';
import {
  GameInputMode,
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';
import { isOpen, mazeForLevel } from './level';
import {
  TILT_GRID_UNITS_PER_SECOND,
  isMotionAvailable,
  subscribeTilt,
} from './motionInput';

export const MARBLE_MAZE_ID = 'marble_maze';
export { marbleMazeDifficultyParams } from './level';

const FRAME_MS = 33;

export function MarbleMazeGame({
  config,
  onEvent,
  onFinish,
}: TesseractGameProps & {
  /** Reports the input mode genuinely used, for the host to record. */
  onActualInputMode?: (mode: 'tilt' | 'touch') => void;
}) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const maze = useMemo(() => mazeForLevel(config.level), [config.level]);
  // Cell size is resolved by GameLayout from the real board width, so the
  // maze fits any screen instead of assuming one.
  const cellFor = (boardSize: number) => (boardSize - 20) / maze.cols;
  const cell = 24;

  const [pos, setPos] = useState({ x: maze.start[0] + 0.5, y: maze.start[1] + 0.5 });
  const [paused, setPaused] = useState(false);
  const [motionReady, setMotionReady] = useState(false);
  const [motionOffered, setMotionOffered] = useState(
    config.inputMode === GameInputMode.tilt,
  );
  const [showHint, setShowHint] = useState(false);

  const tilt = useRef({ x: 0, y: 0 });
  const posRef = useRef(pos);
  posRef.current = pos;
  const started = useRef(false);
  const done = useRef(false);
  const pausedRef = useRef(paused);
  pausedRef.current = paused;
  /** True only once motion has genuinely driven the marble. */
  const motionActuallyUsed = useRef(false);
  const visitedDeadEnds = useRef(new Set<string>());

  if (!started.current) {
    started.current = true;
    onEvent(recorder.sessionStarted());
    if (config.isTutorial) onEvent(recorder.tutorialStarted());
  }

  const finish = useCallback(
    (status: 'completed' | 'stopped_by_user') => {
      if (done.current) return;
      done.current = true;
      onEvent(recorder.sessionFinished(status));
      onFinish(recorder.result(status));
    },
    [onEvent, onFinish, recorder],
  );

  /* ------------------------------------------------------------ motion - */
  useEffect(() => {
    if (config.inputMode !== GameInputMode.tilt) return;
    let sub: { remove: () => void } | null = null;
    let cancelled = false;

    (async () => {
      const available = await isMotionAvailable();
      if (cancelled) return;
      if (!available) {
        // Honest: no sensor, so the game says so and touch takes over.
        setMotionOffered(false);
        onEvent(recorder.supportChanged({ motion: false }));
        return;
      }
      sub = subscribeTilt({
        onSample: (s) => {
          tilt.current = s;
        },
        onReady: () => !cancelled && setMotionReady(true),
      });
    })();

    return () => {
      cancelled = true;
      sub?.remove();
    };
  }, [config.inputMode, onEvent, recorder]);

  /* ------------------------------------------------------------- clock - */
  useEffect(() => {
    if (!motionOffered || !motionReady) return;
    const id = setInterval(() => {
      if (pausedRef.current || done.current) return;
      const t = tilt.current;
      if (t.x === 0 && t.y === 0) return;
      motionActuallyUsed.current = true;
      const step = (TILT_GRID_UNITS_PER_SECOND * FRAME_MS) / 1000;
      move(t.x * step * 3, t.y * step * 3);
    }, FRAME_MS);
    return () => clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [motionOffered, motionReady]);

  /**
   * Moves the marble, sliding along walls rather than sticking on them, and
   * reports a collision the first time it is blocked on an axis.
   */
  const move = (dx: number, dy: number) => {
    const p = posRef.current;
    let nx = p.x + dx;
    let ny = p.y + dy;
    let blocked = false;

    if (!isOpen(maze, Math.floor(nx), Math.floor(p.y))) {
      nx = p.x;
      blocked = true;
    }
    if (!isOpen(maze, Math.floor(nx), Math.floor(ny))) {
      ny = p.y;
      blocked = true;
    }
    if (nx === p.x && ny === p.y) {
      if (blocked) {
        onEvent(
          recorder.custom('collision', {
            wallId: `c${Math.floor(p.x)}-${Math.floor(p.y)}`,
          }),
        );
      }
      return;
    }

    const next = { x: nx, y: ny };
    posRef.current = next;
    setPos(next);

    const col = Math.floor(nx);
    const row = Math.floor(ny);

    const dead = maze.deadEndCells.find((d) => d.col === col && d.row === row);
    if (dead && !visitedDeadEnds.current.has(dead.id)) {
      visitedDeadEnds.current.add(dead.id);
      onEvent(recorder.custom('dead_end_entered', { deadEndId: dead.id }));
    }

    if (col === maze.goal[0] && row === maze.goal[1]) {
      onEvent(recorder.custom('goal_reached'));
      if (config.isTutorial) onEvent(recorder.tutorialCompleted());
      finish(GameResultStatus.completed);
    }
  };

  /* -------------------------------------------------------------- touch - */
  // The accessible fallback, always available: drag the marble directly.
  // Present even in motion mode, so someone who cannot tilt is never stuck.
  const pan = Gesture.Pan()
    .onChange((e) => {
      if (pausedRef.current || done.current) return;
      move(e.changeX / cell, e.changeY / cell);
    })
    .runOnJS(true);

  const usingMotion = motionOffered && motionReady;

  return (
    <GameScaffold
      strings={config.strings}
      paused={paused}
      onHelp={() => {
        onEvent(recorder.hintRequested());
        setShowHint(true);
      }}
      onBreak={() => {
        setPaused(true);
        onEvent(recorder.paused());
      }}
      onResume={() => {
        setPaused(false);
        onEvent(recorder.resumed());
      }}
      onFinishNow={() => {
        setPaused(false);
        finish(GameResultStatus.stoppedByUser);
      }}
    >
      <GameLayout
        prompt={gameText(config.strings, 'maze_title')}
        // The control mode in effect, stated plainly and never guessed.
        subPrompt={
          motionOffered && !motionReady
            ? gameText(config.strings, 'maze_hold_still')
            : usingMotion
              ? gameText(config.strings, 'maze_motion_mode')
              : gameText(config.strings, 'maze_touch_mode')
        }
        boardAspect={maze.rows / maze.cols}
        board={(size) => {
          const c = cellFor(size);
          const w = c * maze.cols;
          const h = c * maze.rows;
          return (
            <GestureDetector gesture={pan}>
              <View
                style={{ width: w, height: h }}
                accessible
                accessibilityRole="adjustable"
                accessibilityLabel={gameText(config.strings, 'maze_title')}
                accessibilityHint={gameText(config.strings, 'maze_touch_mode')}
              >
                <Svg width={w} height={h}>
                  <Defs>
                    <RadialGradient id="goalGlow" cx="50%" cy="50%" r="50%">
                      <Stop offset="0%" stopColor={colors.coral} stopOpacity={0.9} />
                      <Stop offset="100%" stopColor={colors.coral} stopOpacity={0.15} />
                    </RadialGradient>
                  </Defs>

                  {/* Corridors are drawn as one rounded path per open cell
                      with a slight overlap, so the route reads as a
                      continuous channel rather than a grid of tiles. */}
                  {maze.open.map((row, r) =>
                    row.map((open, col) =>
                      open ? (
                        <Rect
                          key={`${r}-${col}`}
                          x={col * c - 0.5}
                          y={r * c - 0.5}
                          width={c + 1}
                          height={c + 1}
                          rx={c * 0.28}
                          fill={colors.peach}
                        />
                      ) : null,
                    ),
                  )}

                  {/* The goal glows, so it is findable at a glance. */}
                  <Circle
                    cx={(maze.goal[0] + 0.5) * c}
                    cy={(maze.goal[1] + 0.5) * c}
                    r={c * 0.95}
                    fill="url(#goalGlow)"
                  />
                  <Circle
                    cx={(maze.goal[0] + 0.5) * c}
                    cy={(maze.goal[1] + 0.5) * c}
                    r={c * 0.34}
                    fill={colors.coral}
                  />

                  {showHint
                    ? maze.deadEndCells.map((d) => (
                        <Rect
                          key={d.id}
                          x={d.col * c + 2}
                          y={d.row * c + 2}
                          width={c - 4}
                          height={c - 4}
                          rx={c * 0.24}
                          fill="none"
                          stroke={colors.attention}
                          strokeWidth={2}
                          strokeDasharray="3 4"
                        />
                      ))
                    : null}

                  {/* The marble gets a soft contact shadow and a highlight so
                      it reads as an object on the board, not a flat dot. */}
                  <G>
                    <Circle
                      cx={pos.x * c}
                      cy={pos.y * c + c * 0.12}
                      r={c * 0.34}
                      fill={colors.ink}
                      opacity={0.16}
                    />
                    <Circle cx={pos.x * c} cy={pos.y * c} r={c * 0.34} fill={colors.ink} />
                    <Circle
                      cx={pos.x * c - c * 0.1}
                      cy={pos.y * c - c * 0.12}
                      r={c * 0.1}
                      fill="#FFFFFF"
                      opacity={0.5}
                    />
                  </G>
                </Svg>
              </View>
            </GestureDetector>
          );
        }}
      >
        {!motionOffered ? (
          <StatusNote icon="hand" text={gameText(config.strings, 'maze_touch_mode')} />
        ) : null}
        <BodyMedium center tone="soft">
          {gameText(config.strings, 'maze_touch_mode')}
        </BodyMedium>
      </GameLayout>
    </GameScaffold>
  );
}


