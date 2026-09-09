/**
 * Trace (G4), ported from Aryan's Flutter `trace`. Original design: Aryan.
 *
 * Rules and geometry live in `./model`. This file is drawing and touch.
 *
 * | Event | Payload | When |
 * |---|---|---|
 * | `stroke_started` | `{strokeId, templateId}` | a finger goes down |
 * | `stroke_ended` | `{strokeId, coveragePercent}` | it lifts |
 * | `guide_shown` | `{templateId}` | Help animates the route |
 * | `trace_finished` | `{coveragePercent, strokes, lifts}` | the activity ends |
 *
 * **The stroke never leaves the device.** A trace is a dense stream of finger
 * positions — the most identifying motor data this app touches. It is drawn on
 * screen and then discarded. Payloads carry percentages and counts.
 *
 * What the patient sees: a grey line to follow, a green dot to start from, and
 * the line turning coral behind their finger as they go. There is no accuracy
 * readout and nothing marks a wobble.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { PanResponder, StyleSheet, View } from 'react-native';
import Svg, { Circle, Polyline } from 'react-native-svg';
import { colors, spacing } from '../../design/tokens';
import { TRACE_TEMPLATES } from '../../content/pictures';
import { GameScaffold } from '../GameScaffold';
import { EmptyBoard, GameLayout } from '../presentation';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';
import { TraceBoard, traceDifficultyParams, type TracePoint } from './model';

export const TRACE_ID = 'trace';
export { traceDifficultyParams };

export function TraceGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const params = useMemo(() => traceDifficultyParams(config.level), [config.level]);

  /** Level picks a different shape, not the same shape judged harder. */
  const template = useMemo(
    () => TRACE_TEMPLATES[Math.max(0, config.level - 1) % TRACE_TEMPLATES.length],
    [config.level],
  );

  const board = useMemo(() => {
    if (!template) return null;
    const path: TracePoint[] = template.path.map(([x, y]) => ({ x, y }));
    return new TraceBoard(path, { ...params, corridorWidth: template.corridorWidth });
  }, [template, params]);

  const [, forceRender] = useState(0);
  const redraw = useCallback(() => forceRender((n) => n + 1), []);
  const [paused, setPaused] = useState(false);
  const started = useRef(false);
  const done = useRef(false);
  const boardSize = useRef(1);
  const pausedRef = useRef(false);
  pausedRef.current = paused;

  if (!started.current) {
    started.current = true;
    onEvent(recorder.sessionStarted());
    if (config.isTutorial) onEvent(recorder.tutorialStarted());
  }

  const finish = useCallback(
    (status: 'completed' | 'stopped_by_user') => {
      if (done.current || !board) return;
      done.current = true;
      const metrics = board.metrics(status === 'completed');
      onEvent(
        recorder.custom('trace_finished', {
          coveragePercent: Math.round(metrics.coverage * 100),
          strokes: metrics.strokeCount,
          lifts: metrics.liftCount,
          guideUsed: metrics.guideUsed,
        }),
      );
      onEvent(recorder.sessionFinished(status));
      onFinish(recorder.result(status));
    },
    [board, onEvent, onFinish, recorder],
  );

  const responder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (event) => {
          if (!board || pausedRef.current || done.current) return;
          const { locationX, locationY } = event.nativeEvent;
          if (
            board.begin({
              x: locationX / boardSize.current,
              y: locationY / boardSize.current,
            })
          ) {
            onEvent(
              recorder.custom('stroke_started', {
                strokeId: `stroke-${board.strokes.length}`,
                templateId: template?.id ?? null,
              }),
            );
            redraw();
          }
        },
        onPanResponderMove: (event) => {
          if (!board || pausedRef.current || done.current) return;
          const { locationX, locationY } = event.nativeEvent;
          if (
            board.extend({
              x: locationX / boardSize.current,
              y: locationY / boardSize.current,
            })
          ) {
            redraw();
          }
        },
        onPanResponderRelease: () => {
          if (!board || done.current) return;
          const complete = board.isComplete;
          if (board.endStroke()) {
            onEvent(
              recorder.custom('stroke_ended', {
                strokeId: `stroke-${board.strokes.length}`,
                coveragePercent: Math.round(board.coverage * 100),
              }),
            );
          }
          redraw();
          // Finish on the lift, never mid-stroke: the line should not vanish
          // out from under a moving finger.
          if (complete || board.isComplete) {
            if (config.isTutorial) onEvent(recorder.tutorialCompleted());
            finish(GameResultStatus.completed);
          }
        },
        onPanResponderTerminate: () => {
          board?.endStroke();
          redraw();
        },
      }),
    [board, template, recorder, onEvent, redraw, finish, config.isTutorial],
  );

  /** Help draws the whole route as a guide. It never traces it for them. */
  const help = useCallback(() => {
    if (!board || paused || done.current) return;
    onEvent(recorder.hintRequested());
    board.showGuide();
    onEvent(recorder.custom('guide_shown', { templateId: template?.id ?? null }));
    redraw();
  }, [board, template, paused, recorder, onEvent, redraw]);

  const pause = useCallback(() => {
    setPaused(true);
    onEvent(recorder.paused());
  }, [onEvent, recorder]);

  const resume = useCallback(() => {
    setPaused(false);
    onEvent(recorder.resumed());
  }, [onEvent, recorder]);

  const stop = useCallback(() => {
    setPaused(false);
    finish(GameResultStatus.stoppedByUser);
  }, [finish]);

  const scaffold = (children: React.ReactNode, helpEnabled = true) => (
    <GameScaffold
      strings={config.strings}
      paused={paused}
      helpEnabled={helpEnabled}
      onHelp={help}
      onBreak={pause}
      onResume={resume}
      onFinishNow={stop}
    >
      {children}
    </GameScaffold>
  );

  if (!board || !template) {
    return scaffold(
      <EmptyBoard text={gameText(config.strings, 'trace_unavailable')} />,
      false,
    );
  }

  const start = board.start;
  const end = board.finishPoint;

  return scaffold(
    <GameLayout
      prompt={gameText(config.strings, 'trace_follow_the_line')}
      subPrompt={gameText(config.strings, 'trace_start_at_the_dot')}
      board={(size) => {
        boardSize.current = size;
        const toPixels = (p: TracePoint) => `${p.x * size},${p.y * size}`;
        return (
          <View
            style={styles.board}
            {...(paused ? {} : responder.panHandlers)}
            accessibilityLabel={gameText(config.strings, 'trace_follow_the_line')}
          >
            <Svg width={size} height={size}>
              {/* The line to follow. */}
              <Polyline
                points={board.path.map(toPixels).join(' ')}
                fill="none"
                stroke={colors.hairline}
                strokeWidth={board.guideVisible ? 26 : 22}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              {/* Help draws the route brighter, over the corridor. */}
              {board.guideVisible ? (
                <Polyline
                  points={board.path.map(toPixels).join(' ')}
                  fill="none"
                  stroke={colors.peach}
                  strokeWidth={10}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeDasharray="2 14"
                />
              ) : null}

              {/* Progress: the bins already reached, filled in behind them. */}
              {Array.from({ length: board.binCount }, (_, index) => {
                if (!board.isBinVisited(index)) return null;
                const bin = board.binAt(index);
                if (!bin) return null;
                return (
                  <Circle
                    key={index}
                    cx={bin.x * size}
                    cy={bin.y * size}
                    r={7}
                    fill={colors.peach}
                  />
                );
              })}

              {/* The patient's own stroke. */}
              {board.strokes.map((stroke, index) =>
                stroke.length < 2 ? null : (
                  <Polyline
                    key={index}
                    points={stroke.map(toPixels).join(' ')}
                    fill="none"
                    stroke={colors.coral}
                    strokeWidth={9}
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                ),
              )}

              {/* Where to start, and where it ends. */}
              {start ? (
                <Circle
                  cx={start.x * size}
                  cy={start.y * size}
                  r={15}
                  fill="#2F7D4F"
                />
              ) : null}
              {end ? (
                <Circle
                  cx={end.x * size}
                  cy={end.y * size}
                  r={13}
                  fill="none"
                  stroke={colors.ink}
                  strokeWidth={3}
                />
              ) : null}
            </Svg>
          </View>
        );
      }}
    />,
  );
}

const styles = StyleSheet.create({
  board: {
    flex: 1,
    borderRadius: spacing.cardRadius,
    overflow: 'hidden',
    backgroundColor: colors.white,
  },
});
