/**
 * Spot Difference (G6), ported from Aryan's Flutter `spot_difference`.
 * Original design: Aryan.
 *
 * Rules and hit testing live in `./model`. This file is layout, touch
 * translation and event emission.
 *
 * | Event | Payload | When |
 * |---|---|---|
 * | `difference_selected` | `{regionId, correct, alreadyFound}` | any tap on a picture |
 * | `hint_used` | `{regionId}` | Help points at one |
 * | `puzzle_finished` | `{found, total}` | every difference found |
 *
 * Payloads carry authored region ids and booleans. **No coordinates.** A tap
 * position is a raw motor measurement; it stays on the device, and only the
 * region it resolved to is recorded.
 *
 * The two pictures stack vertically rather than sitting side by side: on a
 * phone, two images across a 390pt screen are about 180pt each, which is too
 * small to see a change in. Stacked, each gets the full width.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import { colors, spacing } from '../../design/tokens';
import { PictureView } from '../../content/PictureView';
import { GameScaffold } from '../GameScaffold';
import { EmptyBoard, GameLayout, Settle } from '../presentation';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';
import {
  SpotDifferenceBoard,
  pairForParams,
  spotDifferenceDifficultyParams,
} from './model';

export const SPOT_DIFFERENCE_ID = 'spot_difference';
export { spotDifferenceDifficultyParams };

export function SpotDifferenceGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const params = useMemo(
    () => spotDifferenceDifficultyParams(config.level),
    [config.level],
  );

  const board = useMemo(() => {
    const pair = pairForParams(params);
    return pair ? new SpotDifferenceBoard(pair, params) : null;
  }, [params]);

  /**
   * Each panel's own measured width.
   *
   * Measured rather than inherited from the layout's computed size: the panel
   * is what the finger actually touches, so its real width is the only correct
   * divisor. Trusting the parent's arithmetic would silently mis-map every tap
   * if a border or padding ever changed.
   */
  const panelSize = useRef(1);

  const [, forceRender] = useState(0);
  const redraw = useCallback(() => forceRender((n) => n + 1), []);
  const [paused, setPaused] = useState(false);
  const started = useRef(false);
  const done = useRef(false);

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

  /**
   * A tap, translated from a point inside the picture box to a unit fraction.
   *
   * `locationX/Y` are already relative to the pressed view, and the picture
   * fills that view exactly, so the division is the whole translation. The
   * pixel values are used here and then dropped.
   */
  const tap = useCallback(
    (localX: number, localY: number) => {
      if (!board || paused || done.current) return;
      const size = panelSize.current;
      if (size <= 0) return;
      const outcome = board.select(localX / size, localY / size, recorder.elapsedMs);

      onEvent(
        recorder.custom('difference_selected', {
          regionId: outcome.regionId,
          correct: outcome.correct,
          alreadyFound: outcome.alreadyFound,
        }),
      );
      redraw();

      if (board.isComplete) {
        const metrics = board.metrics(true);
        onEvent(
          recorder.custom('puzzle_finished', {
            found: metrics.differencesFound,
            total: metrics.differencesTotal,
          }),
        );
        if (config.isTutorial) onEvent(recorder.tutorialCompleted());
        finish(GameResultStatus.completed);
      }
    },
    [board, paused, recorder, onEvent, redraw, finish, config.isTutorial],
  );

  const help = useCallback(() => {
    if (!board || paused || done.current) return;
    onEvent(recorder.hintRequested());
    const regionId = board.requestHint();
    if (regionId) onEvent(recorder.custom('hint_used', { regionId }));
    redraw();
  }, [board, paused, recorder, onEvent, redraw]);

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

  if (!board) {
    return scaffold(
      <EmptyBoard text={gameText(config.strings, 'spot_unavailable')} />,
      false,
    );
  }

  /** One picture, tappable, with markers over the differences already found. */
  const panel = (pictureId: string, size: number, tappable: boolean) => (
    <Pressable
      accessibilityRole={tappable ? 'button' : 'image'}
      accessibilityLabel={gameText(
        config.strings,
        tappable ? 'spot_tap_what_changed' : 'spot_the_first_picture',
      )}
      disabled={!tappable || paused}
      onLayout={(event) => {
        panelSize.current = event.nativeEvent.layout.width;
      }}
      onPress={(event) =>
        tap(event.nativeEvent.locationX, event.nativeEvent.locationY)
      }
      style={styles.panel}
    >
      <PictureView pictureId={pictureId} size={size} decorative rounded={false} />

      {/* Markers sit above the picture and do not intercept touches, so a
          patient can still tap a difference they have already found without
          being blocked by its own marker. */}
      <View pointerEvents="none" style={StyleSheet.absoluteFill}>
        <Svg width={size} height={size}>
          {board.regions.map((region) => {
            const found = board.isFound(region.id);
            const hinted = board.highlightedId === region.id;
            if (!found && !hinted) return null;
            const cx = (region.left + region.width / 2) * size;
            const cy = (region.top + region.height / 2) * size;
            const r = (Math.max(region.width, region.height) / 2 + 0.03) * size;
            return (
              <Circle
                key={region.id}
                cx={cx}
                cy={cy}
                r={r}
                fill="none"
                stroke={found ? colors.ink : colors.coral}
                strokeWidth={found ? 3 : 4}
                strokeDasharray={hinted && !found ? '6 6' : undefined}
              />
            );
          })}
        </Svg>
      </View>
    </Pressable>
  );

  const remaining = board.regions.length - board.foundCount;

  return scaffold(
    <GameLayout
      prompt={gameText(config.strings, 'spot_find_what_changed')}
      subPrompt={
        remaining === board.regions.length
          ? undefined
          : gameText(config.strings, 'spot_one_more')
      }
      boardAspect={2.08}
      board={(size) => (
        <Settle trigger={`${board.foundCount}-${board.highlightedId}`}>
          <View style={styles.stack}>
            {panel(board.pair.leftPictureId, size, true)}
            {panel(board.pair.rightPictureId, size, true)}
          </View>
        </Settle>
      )}
    />,
  );
}

const styles = StyleSheet.create({
  stack: { gap: 10, alignItems: 'center' },
  panel: {
    borderRadius: spacing.cardRadius,
    overflow: 'hidden',
    borderWidth: 1.5,
    borderColor: colors.hairline,
  },
});
