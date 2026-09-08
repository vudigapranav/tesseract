/**
 * Daily Routine Recall (G8), ported from routine_recall. Original design: Ruthika.
 *
 * Put the day's steps in order. A wrong choice is gentle: it names what
 * happened, keeps the question open, and applies no penalty. `attempt` lets
 * first-attempt accuracy be separated from eventual completion without the
 * game computing an accuracy figure of its own.
 *
 * Events: step_presented {stepId}, attempt_resolved {stepId, chosenId,
 * correct, attempt}, routine_completed. Step text never leaves the device.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { spacing } from '../../design/tokens';
import {
  BigPatientAction,
  BodyLarge,
  StatusNote,
  TitleLarge,
} from '../../design/components';
import { GameScaffold } from '../GameScaffold';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';

export const ROUTINE_RECALL_ID = 'routine_recall';

export function routineRecallDifficultyParams(level: number) {
  switch (level) {
    case 1:
      return { stepCount: 3, optionCount: 2 };
    case 2:
      return { stepCount: 4, optionCount: 3 };
    default:
      return { stepCount: 5, optionCount: 3 };
  }
}

export function RoutineRecallGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const params = useMemo(
    () => routineRecallDifficultyParams(config.level),
    [config.level],
  );

  /** The correct order is the order the caregiver saved. */
  const steps = useMemo(
    () => config.items.slice(0, params.stepCount),
    [config.items, params.stepCount],
  );

  const [index, setIndex] = useState(0);
  const [attempt, setAttempt] = useState(1);
  const [paused, setPaused] = useState(false);
  const [wrongId, setWrongId] = useState<string | null>(null);
  const [hinted, setHinted] = useState(false);
  const started = useRef(false);
  const done = useRef(false);
  const presented = useRef<Set<number>>(new Set());

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

  const current = steps[index];

  // Announce each step exactly once, when it first becomes the question.
  if (current && !presented.current.has(index) && !done.current) {
    presented.current.add(index);
    onEvent(recorder.custom('step_presented', { stepId: current.id }));
  }

  /** Options: the correct next step plus distractors from later steps. */
  const options = useMemo(() => {
    if (!current) return [];
    const others = steps.filter((s) => s.id !== current.id);
    const picked = others.slice(0, Math.max(0, params.optionCount - 1));
    const all = [current, ...picked];
    // Stable shuffle by id, so the layout does not jump between renders.
    return all.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  }, [current, steps, params.optionCount]);

  if (steps.length === 0) {
    return (
      <GameScaffold
        strings={config.strings}
        paused={paused}
        helpEnabled={false}
        onHelp={() => {}}
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
        <View style={styles.body}>
          <StatusNote
            glyph="✎"
            tone="attention"
            text={gameText(config.strings, 'routine_unavailable')}
          />
        </View>
      </GameScaffold>
    );
  }

  const choose = (chosenId: string) => {
    if (paused || done.current || !current) return;
    const correct = chosenId === current.id;

    onEvent(
      recorder.custom('attempt_resolved', {
        stepId: current.id,
        chosenId,
        correct,
        attempt,
      }),
    );

    if (!correct) {
      // Gentle: name what happened, keep the question open, no penalty.
      setWrongId(chosenId);
      setAttempt((a) => a + 1);
      return;
    }

    setWrongId(null);
    setAttempt(1);
    setHinted(false);

    if (index + 1 >= steps.length) {
      onEvent(recorder.custom('routine_completed'));
      if (config.isTutorial) onEvent(recorder.tutorialCompleted());
      finish(GameResultStatus.completed);
      return;
    }
    setIndex((i) => i + 1);
  };

  return (
    <GameScaffold
      strings={config.strings}
      paused={paused}
      onHelp={() => {
        onEvent(recorder.hintRequested());
        setHinted(true);
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
      <View style={styles.body}>
        <TitleLarge center>
          {gameText(config.strings, 'routine_what_next')}
        </TitleLarge>
        <BodyLarge tone="soft" center style={{ marginTop: 6 }}>
          {`${index + 1} / ${steps.length}`}
        </BodyLarge>

        <View style={{ height: 20 }} />

        {options.map((o) => (
          <BigPatientAction
            key={o.id}
            label={o.label ?? ''}
            primary={hinted && o.id === current.id}
            onPress={() => choose(o.id)}
          />
        ))}

        {wrongId ? (
          <StatusNote
            glyph="↺"
            text={gameText(config.strings, 'routine_try_again')}
          />
        ) : null}
      </View>
    </GameScaffold>
  );
}

const styles = StyleSheet.create({
  body: { flex: 1, paddingHorizontal: spacing.gutter, paddingTop: 8 },
});
