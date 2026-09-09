/**
 * Coloring (G5), ported from Aryan's Flutter `swipe_reveal`.
 * Original design: Aryan. Product direction: swipe-to-reveal, confirmed in
 * `docs/PS003_PATIENT_EXPERIENCE.md`.
 *
 * Rules live in `./model`. This file is touch handling and drawing.
 *
 * **How the reveal is drawn.** The faded picture sits underneath. The full
 * colour picture sits on top, inside an SVG mask made of the patient's own
 * strokes drawn as thick round-capped polylines. Where they have swept, the
 * mask is white and the colour shows; everywhere else it is black and the
 * faded version shows through.
 *
 * That is one mask and a handful of paths — not thousands of small views. The
 * grid in the model is only for measuring how much has been uncovered; it is
 * never rendered.
 *
 * | Event | Payload | When |
 * |---|---|---|
 * | `reveal_stroke` | `{strokeId, newlyRevealedCells}` | a stroke ends |
 * | `picture_shown` | — | Help uncovers the whole picture |
 * | `reveal_finished` | `{coveragePercent, strokes}` | the activity ends |
 *
 * Payloads carry counts, never the stroke itself. The raw path is a stream of
 * finger coordinates: it stays on the device.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { PanResponder, Pressable, StyleSheet, Text, View } from 'react-native';
import Svg, { Defs, Ellipse, G, Mask, Polygon, Polyline, Rect } from 'react-native-svg';
import { colors, fontScaleCaps, spacing } from '../../design/tokens';
import { PictureView } from '../../content/PictureView';
import { SCENE_PICTURE_IDS, pictureById } from '../../content/pictures';
import { GameScaffold } from '../GameScaffold';
import { GameLayout } from '../presentation';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';
import { ColoringCanvas, coloringDifficultyParams } from './model';

export const COLORING_ID = 'coloring';
export { coloringDifficultyParams };

/** How faded the picture is before any colour is brought back. */
const FADED_OPACITY = 0.16;

export function ColoringGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const params = useMemo(() => coloringDifficultyParams(config.level), [config.level]);
  const canvas = useMemo(() => new ColoringCanvas(params), [params]);

  const pictureId = useMemo(
    () => SCENE_PICTURE_IDS[Math.max(0, config.level - 1) % SCENE_PICTURE_IDS.length],
    [config.level],
  );

  const [, forceRender] = useState(0);
  const redraw = useCallback(() => forceRender((n) => n + 1), []);
  const [paused, setPaused] = useState(false);
  const started = useRef(false);
  const done = useRef(false);

  /**
   * Board size, captured when the board lays out.
   *
   * PanResponder reports coordinates relative to the responding view, and the
   * view is the board, so dividing by this size gives the unit fraction the
   * model works in.
   */
  const boardSize = useRef(1);
  // Mirrors of state the gesture handlers need. A PanResponder is created once
  // and closes over its first render, so reading React state inside it would
  // read stale values.
  const pausedRef = useRef(false);
  pausedRef.current = paused;

  if (!started.current) {
    started.current = true;
    onEvent(recorder.sessionStarted());
    if (config.isTutorial) onEvent(recorder.tutorialStarted());
  }

  const finish = useCallback(
    (status: 'completed' | 'stopped_by_user') => {
      if (done.current) return;
      done.current = true;
      const metrics = canvas.metrics(status === 'completed', recorder.elapsedMs);
      onEvent(
        recorder.custom('reveal_finished', {
          // Rounded to whole percent: a coverage figure with more precision
          // than that says nothing extra and looks like a score.
          coveragePercent: Math.round(metrics.manualCoverage * 100),
          strokes: metrics.strokeCount,
          helpUsed: metrics.helpUsed,
        }),
      );
      onEvent(recorder.sessionFinished(status));
      onFinish(recorder.result(status));
    },
    [canvas, onEvent, onFinish, recorder],
  );

  const responder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (event) => {
          if (pausedRef.current || done.current) return;
          const { locationX, locationY } = event.nativeEvent;
          canvas.begin(
            { x: locationX / boardSize.current, y: locationY / boardSize.current },
            recorder.elapsedMs,
          );
        },
        onPanResponderMove: (event) => {
          if (pausedRef.current || done.current) return;
          const { locationX, locationY } = event.nativeEvent;
          if (
            canvas.extend({
              x: locationX / boardSize.current,
              y: locationY / boardSize.current,
            })
          ) {
            redraw();
          }
        },
        onPanResponderRelease: () => {
          const ended = canvas.end(recorder.elapsedMs);
          if (ended) {
            onEvent(
              recorder.custom('reveal_stroke', {
                strokeId: `stroke-${ended.strokeIndex + 1}`,
                newlyRevealedCells: ended.newlyCovered,
              }),
            );
          }
          redraw();
          // Finishing is never abrupt: reaching the coverage threshold ends
          // the activity, but only once the finger has been lifted.
          if (canvas.isComplete && !done.current) {
            if (config.isTutorial) onEvent(recorder.tutorialCompleted());
            finish(GameResultStatus.completed);
          }
        },
        onPanResponderTerminate: () => {
          canvas.end(recorder.elapsedMs);
          redraw();
        },
      }),
    [canvas, recorder, redraw, onEvent, finish, config.isTutorial],
  );

  /** Help shows the whole picture. It ends nothing — the patient chooses when. */
  const help = useCallback(() => {
    if (paused || done.current) return;
    onEvent(recorder.hintRequested());
    canvas.showPicture();
    onEvent(recorder.custom('picture_shown'));
    redraw();
  }, [canvas, paused, recorder, onEvent, redraw]);

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

  const strokes = canvas.strokes;
  const shown = canvas.pictureShown;

  return (
    <GameScaffold
      strings={config.strings}
      paused={paused}
      helpEnabled={!shown}
      onHelp={help}
      onBreak={pause}
      onResume={resume}
      onFinishNow={stop}
    >
      <GameLayout
        prompt={gameText(config.strings, 'coloring_sweep_to_reveal')}
        subPrompt={
          shown ? gameText(config.strings, 'coloring_here_it_is') : undefined
        }
        board={(size) => {
          boardSize.current = size;
          const brushPx = canvas.brushRadius * size * 2;
          return (
            <View
              style={styles.board}
              onLayout={() => {
                boardSize.current = size;
              }}
              {...(shown || paused ? {} : responder.panHandlers)}
            >
              {/* Underneath: the picture, faded. */}
              <PictureView
                pictureId={pictureId}
                size={size}
                decorative
                rounded={false}
                opacity={FADED_OPACITY}
              />

              {/* On top: full colour, revealed only where a finger has been. */}
              <View pointerEvents="none" style={StyleSheet.absoluteFill}>
                {shown ? (
                  <PictureView
                    pictureId={pictureId}
                    size={size}
                    decorative
                    rounded={false}
                  />
                ) : strokes.length > 0 ? (
                  <Svg width={size} height={size}>
                    <Defs>
                      <Mask id="revealed" maskUnits="userSpaceOnUse">
                        <Rect x="0" y="0" width={size} height={size} fill="black" />
                        {strokes.map((stroke, index) => (
                          <Polyline
                            key={index}
                            points={stroke
                              .map((p) => `${p.x * size},${p.y * size}`)
                              .join(' ')}
                            fill="none"
                            stroke="white"
                            strokeWidth={brushPx}
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        ))}
                      </Mask>
                    </Defs>
                    <G mask="url(#revealed)">
                      <ColourLayer pictureId={pictureId} size={size} />
                    </G>
                  </Svg>
                ) : null}
              </View>
            </View>
          );
        }}
      >
        {/* Progress as a quiet bar, never a percentage or a score. */}
        <View
          accessible
          accessibilityRole="progressbar"
          accessibilityLabel={gameText(config.strings, 'coloring_progress')}
          style={styles.track}
        >
          <View
            style={[
              styles.fill,
              { width: `${Math.round(canvas.displayCoverage * 100)}%` },
            ]}
          />
        </View>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel={gameText(config.strings, 'coloring_finish')}
          onPress={stop}
          disabled={paused}
          style={({ pressed }) => [styles.secondary, pressed && styles.pressed]}
        >
          <Text
            maxFontSizeMultiplier={fontScaleCaps.buttonLabel}
            style={styles.secondaryLabel}
          >
            {gameText(config.strings, 'coloring_finish')}
          </Text>
        </Pressable>
      </GameLayout>
    </GameScaffold>
  );
}

/**
 * The colour picture, drawn inside the mask.
 *
 * `PictureView` renders its own <Svg>, which cannot be nested inside another
 * one, so the primitives are drawn directly here at the board's scale.
 */
function ColourLayer({ pictureId, size }: { pictureId: string; size: number }) {
  return (
    <G scale={size / 100}>
      <PicturePrimitives pictureId={pictureId} />
    </G>
  );
}

function PicturePrimitives({ pictureId }: { pictureId: string }) {
  const picture = pictureById(pictureId);
  if (!picture) return null;
  return (
    <>
      {picture.primitives.map((primitive, index) => {
        const fill = `#${primitive.color}`;
        if (primitive.type === 'rect') {
          const [x, y, w, h] = primitive.rect;
          return <Rect key={index} x={x} y={y} width={w} height={h} fill={fill} />;
        }
        if (primitive.type === 'ellipse') {
          const [x, y, w, h] = primitive.rect;
          return (
            <Ellipse
              key={index}
              cx={x + w / 2}
              cy={y + h / 2}
              rx={w / 2}
              ry={h / 2}
              fill={fill}
            />
          );
        }
        return (
          <Polygon
            key={index}
            points={primitive.points.map(([x, y]) => `${x},${y}`).join(' ')}
            fill={fill}
          />
        );
      })}
    </>
  );
}

const styles = StyleSheet.create({
  board: {
    flex: 1,
    borderRadius: spacing.cardRadius,
    overflow: 'hidden',
    backgroundColor: colors.white,
  },
  track: {
    height: 10,
    borderRadius: 999,
    backgroundColor: colors.hairline,
    overflow: 'hidden',
    marginTop: 10,
    marginHorizontal: 8,
  },
  fill: { height: '100%', backgroundColor: colors.coral, borderRadius: 999 },
  secondary: {
    minHeight: spacing.minTarget,
    borderRadius: 999,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 22,
    marginTop: 10,
    alignSelf: 'center',
  },
  secondaryLabel: { fontSize: 16, fontWeight: '600', color: colors.ink },
  pressed: { opacity: 0.8 },
});
