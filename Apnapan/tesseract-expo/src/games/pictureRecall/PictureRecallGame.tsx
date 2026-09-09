/**
 * Picture Recall (G9), ported from Aryan's Flutter `picture_recall`.
 * Original design: Aryan.
 *
 * Rules live in `./model` (pure TypeScript, separately tested). This file is
 * rendering and event emission only.
 *
 * | Event | Payload | When |
 * |---|---|---|
 * | `picture_presented` | `{sceneId}` | the scene is put in front of the patient |
 * | `picture_hidden` | `{sceneId}` | the patient says they are ready |
 * | `picture_shown_again` | `{questionId, showAgainCount}` | they ask to look again |
 * | `recall_answered` | `{questionId, choiceId, correct, supported, …}` | a choice is taken |
 * | `question_skipped` | `{questionId}` | a question is passed over |
 *
 * Plus the shared lifecycle events through the recorder.
 *
 * Everything in a payload is an authored id from the bundled catalogue. The
 * prompt text, the choice labels and the hint never enter one.
 *
 * What the patient never sees: a score, a running tally, or any mark saying an
 * answer was wrong. `correct` is recorded for the caregiver's summary; on
 * screen, an answer is simply acknowledged and the activity moves on.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, fontScaleCaps, spacing } from '../../design/tokens';
import { PictureView } from '../../content/PictureView';
import { GameScaffold } from '../GameScaffold';
import { EmptyBoard, GameLayout, Settle, tileVisual } from '../presentation';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';
import {
  PictureRecallBoard,
  pictureRecallDifficultyParams,
  sceneForIndex,
} from './model';

export const PICTURE_RECALL_ID = 'picture_recall';
export { pictureRecallDifficultyParams };

export function PictureRecallGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const params = useMemo(
    () => pictureRecallDifficultyParams(config.level),
    [config.level],
  );

  /**
   * Which scene this session uses.
   *
   * Content comes from the bundled catalogue rather than from `config.items`,
   * because a recall question is authored *about* a specific picture: the
   * question, its correct answer and its distractors are one unit. Handing the
   * game a loose list of caregiver pictures would mean inventing questions.
   */
  const board = useMemo(() => {
    const scene = sceneForIndex(Math.max(0, config.level - 1));
    if (scene.questions.length === 0) return null;
    return new PictureRecallBoard(scene, params);
  }, [config.level, params]);

  const [, forceRender] = useState(0);
  const redraw = useCallback(() => forceRender((n) => n + 1), []);
  const [paused, setPaused] = useState(false);
  const [hintText, setHintText] = useState<string | null>(null);
  const started = useRef(false);
  const done = useRef(false);

  if (!started.current) {
    started.current = true;
    onEvent(recorder.sessionStarted());
    if (config.isTutorial) onEvent(recorder.tutorialStarted());
    if (board) {
      onEvent(recorder.custom('picture_presented', { sceneId: board.scene.id }));
    }
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

  /** Called after any board transition that might have ended the activity. */
  const settleIfFinished = useCallback(() => {
    if (!board || !board.isComplete || done.current) return false;
    if (config.isTutorial) onEvent(recorder.tutorialCompleted());
    // "Completed" means every question was reached, whether answered or
    // passed over. Skipping is a legitimate way through, not a failure.
    finish(GameResultStatus.completed);
    return true;
  }, [board, config.isTutorial, finish, onEvent, recorder]);

  const ready = useCallback(() => {
    if (!board || paused || done.current) return;
    if (!board.ready(recorder.elapsedMs)) return;
    onEvent(recorder.custom('picture_hidden', { sceneId: board.scene.id }));
    redraw();
  }, [board, paused, recorder, onEvent, redraw]);

  const showAgain = useCallback(() => {
    if (!board || paused || done.current) return;
    const question = board.question;
    if (!board.showAgain(recorder.elapsedMs)) return;
    onEvent(
      recorder.custom('picture_shown_again', {
        questionId: question?.id ?? null,
        showAgainCount: board.metrics(false, recorder.elapsedMs).showAgainCount,
      }),
    );
    setHintText(null);
    redraw();
  }, [board, paused, recorder, onEvent, redraw]);

  /** Help offers the authored hint, and otherwise a second look. It never answers. */
  const help = useCallback(() => {
    if (!board || paused || done.current) return;
    onEvent(recorder.hintRequested());
    const hint = board.useHint();
    if (hint) setHintText(hint);
    else if (board.showAgainAvailable) showAgain();
    redraw();
  }, [board, paused, recorder, onEvent, redraw, showAgain]);

  const choose = useCallback(
    (choiceId: string) => {
      if (!board || paused || done.current) return;
      const answer = board.answer(choiceId, recorder.elapsedMs);
      if (!answer) return;
      onEvent(
        recorder.custom('recall_answered', {
          questionId: answer.questionId,
          choiceId: answer.choiceId,
          correct: answer.correct,
          supported: answer.supported,
          showAgainCount: answer.showAgainCount,
          hintUsed: answer.hintUsed,
          answerLatencyMs: answer.latencyMs,
        }),
      );
      setHintText(null);
      redraw();
      settleIfFinished();
    },
    [board, paused, recorder, onEvent, redraw, settleIfFinished],
  );

  const skip = useCallback(() => {
    if (!board || paused || done.current) return;
    const question = board.question;
    if (!board.skip(recorder.elapsedMs)) return;
    onEvent(recorder.custom('question_skipped', { questionId: question?.id ?? null }));
    setHintText(null);
    redraw();
    settleIfFinished();
  }, [board, paused, recorder, onEvent, redraw, settleIfFinished]);

  const next = useCallback(() => {
    if (!board || paused || done.current) return;
    if (!board.next(recorder.elapsedMs)) return;
    setHintText(null);
    redraw();
  }, [board, paused, recorder, redraw]);

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
      <EmptyBoard text={gameText(config.strings, 'recall_unavailable')} />,
      false,
    );
  }

  const phase = board.phase;
  const question = board.question;

  /* ------------------------------------------------ looking at the scene - */
  if (phase === 'viewing') {
    return scaffold(
      <GameLayout
        prompt={gameText(config.strings, 'recall_look_at_this')}
        subPrompt={gameText(config.strings, 'recall_take_your_time')}
        board={(size) => (
          <PictureView
            pictureId={board.scene.scenePictureId}
            size={size}
            rounded={false}
          />
        )}
      >
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={gameText(config.strings, 'recall_ready')}
          onPress={ready}
          disabled={paused}
          style={({ pressed }) => [styles.primary, pressed && styles.pressed]}
        >
          <Text
            maxFontSizeMultiplier={fontScaleCaps.buttonLabel}
            style={styles.primaryLabel}
          >
            {gameText(config.strings, 'recall_ready')}
          </Text>
        </Pressable>
      </GameLayout>,
    );
  }

  /* ------------------------------------------- between questions, briefly - */
  if (phase === 'feedback') {
    return scaffold(
      <GameLayout
        // Neutral on purpose. The patient is never told an answer was wrong,
        // and never shown a running count of how many they got.
        prompt={gameText(config.strings, 'recall_thank_you')}
        board={(size) => (
          <PictureView
            pictureId={board.scene.scenePictureId}
            size={size}
            rounded={false}
            opacity={0.35}
          />
        )}
      >
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={gameText(config.strings, 'recall_next')}
          onPress={next}
          disabled={paused}
          style={({ pressed }) => [styles.primary, pressed && styles.pressed]}
        >
          <Text
            maxFontSizeMultiplier={fontScaleCaps.buttonLabel}
            style={styles.primaryLabel}
          >
            {gameText(config.strings, 'recall_next')}
          </Text>
        </Pressable>
      </GameLayout>,
    );
  }

  /* ------------------------------------------------------ the question - */
  const choices = board.choices();
  // Fixed rather than proportional: three choices on a small phone still need
  // to be recognisable, and a picture below about 70pt stops being legible.
  const pictureSize = choices.length >= 3 ? 78 : 104;

  return scaffold(
    <GameLayout
      prompt={question?.prompt ?? ''}
      subPrompt={
        board.questionTotal > 1
          ? `${board.questionIndex + 1} / ${board.questionTotal}`
          : undefined
      }
      boardAspect={0.52}
      board={() => {
        // The cards share the row with flex rather than being given a computed
        // width. Two earlier attempts — deriving the width from the layout's
        // board size, then measuring the row with onLayout — both produced a
        // second choice that was pushed onto a new line and clipped out of
        // sight. Flex cannot get this wrong: the row never wraps, so whatever
        // the real width turns out to be, every choice is on screen.
        return (
          <View style={styles.choices}>
            {choices.map((choice) => {
              const visual = tileVisual('idle');
              // No Settle wrapper here: it is a flex container of its own, so
              // it swallowed the card's flex:1 and every choice collapsed to
              // its content width. The choices do not change within a question,
              // so there is nothing for it to animate anyway.
              return (
                  <Pressable
                    key={choice.id}
                    accessibilityRole="button"
                    accessibilityLabel={choice.label}
                    disabled={paused}
                    onPress={() => choose(choice.id)}
                    style={({ pressed }) => [
                      styles.choice,
                      { borderColor: visual.border, backgroundColor: visual.bg },
                      pressed && styles.pressed,
                    ]}
                  >
                    <PictureView
                      pictureId={choice.imageId}
                      size={pictureSize}
                      decorative
                    />
                    <Text
                      numberOfLines={2}
                      maxFontSizeMultiplier={fontScaleCaps.buttonLabel}
                      style={[styles.choiceLabel, { color: visual.fg }]}
                    >
                      {choice.label}
                    </Text>
                  </Pressable>
              );
            })}
          </View>
        );
      }}
    >
      {hintText ? (
        <Settle trigger={hintText}>
          <Text
            maxFontSizeMultiplier={fontScaleCaps.body}
            style={styles.hint}
          >
            {hintText}
          </Text>
        </Settle>
      ) : null}

      <View style={styles.secondaryRow}>
        {board.showAgainAvailable ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={gameText(config.strings, 'recall_show_again')}
            onPress={showAgain}
            disabled={paused}
            style={({ pressed }) => [styles.secondary, pressed && styles.pressed]}
          >
            <Text
              maxFontSizeMultiplier={fontScaleCaps.buttonLabel}
              style={styles.secondaryLabel}
            >
              {gameText(config.strings, 'recall_show_again')}
            </Text>
          </Pressable>
        ) : null}
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={gameText(config.strings, 'recall_skip')}
          onPress={skip}
          disabled={paused}
          style={({ pressed }) => [styles.secondary, pressed && styles.pressed]}
        >
          <Text
            maxFontSizeMultiplier={fontScaleCaps.buttonLabel}
            style={styles.secondaryLabel}
          >
            {gameText(config.strings, 'recall_skip')}
          </Text>
        </Pressable>
      </View>
    </GameLayout>,
  );
}

const styles = StyleSheet.create({
  choices: {
    // Explicitly full width. Without this the row sizes to its content, and
    // flex:1 on the cards then has nothing to divide up.
    width: '100%',
    flexDirection: 'row',
    // Never wraps: every choice stays visible whatever the screen width.
    flexWrap: 'nowrap',
    justifyContent: 'center',
    alignItems: 'stretch',
    gap: 10,
  },
  choice: {
    flex: 1,
    borderRadius: spacing.cardRadius,
    borderWidth: 2,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    paddingHorizontal: 6,
    minHeight: spacing.patientTarget,
    gap: 8,
  },
  choiceLabel: { fontSize: 16, fontWeight: '600', textAlign: 'center' },
  pressed: { opacity: 0.8 },
  primary: {
    minHeight: spacing.patientTarget,
    borderRadius: 999,
    backgroundColor: colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 28,
    marginTop: 8,
  },
  primaryLabel: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.white,
    textAlign: 'center',
  },
  secondaryRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    flexWrap: 'wrap',
    gap: 10,
    marginTop: 6,
  },
  secondary: {
    minHeight: spacing.minTarget,
    borderRadius: 999,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  secondaryLabel: { fontSize: 16, fontWeight: '600', color: colors.ink },
  hint: {
    fontSize: 16,
    color: colors.attention,
    textAlign: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
});
