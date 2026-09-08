/**
 * Picture Sorting (extra activity), ported from picture_sorting.
 * Original design: Ruthika.
 *
 * Note on the catalogue: this is an **extra**, not one of the nine required
 * games. The registry ships four of the nine required activities plus this.
 *
 * Events: item_sorted {itemId, categoryId, correct, attempt},
 * sorting_completed. Picture labels never enter an event.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors } from '../../design/tokens';
import { GameScaffold } from '../GameScaffold';
import { ChoiceCard } from '../ChoiceCard';
import { EmptyBoard, GameLayout, GentleCorrection } from '../presentation';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';

export const PICTURE_SORTING_ID = 'picture_sorting';

export function pictureSortingDifficultyParams(level: number) {
  switch (level) {
    case 1:
      return { itemCount: 4, categoryCount: 2 };
    case 2:
      return { itemCount: 6, categoryCount: 2 };
    default:
      return { itemCount: 8, categoryCount: 3 };
  }
}

export function PictureSortingGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const params = useMemo(
    () => pictureSortingDifficultyParams(config.level),
    [config.level],
  );

  /**
   * Each item carries its category in `extra.categoryId`. Items without one
   * are not guessed at — they are simply not playable content.
   */
  const items = useMemo(
    () =>
      config.items
        .filter((i) => typeof i.extra?.categoryId === 'string')
        .slice(0, params.itemCount),
    [config.items, params.itemCount],
  );

  const categories = useMemo(() => {
    const seen: string[] = [];
    for (const i of items) {
      const c = i.extra?.categoryId as string;
      if (!seen.includes(c)) seen.push(c);
    }
    return seen.slice(0, params.categoryCount);
  }, [items, params.categoryCount]);

  const [index, setIndex] = useState(0);
  const [attempt, setAttempt] = useState(1);
  const [paused, setPaused] = useState(false);
  const [wrong, setWrong] = useState(false);
  const [hinted, setHinted] = useState(false);
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

  const current = items[index];

  if (items.length === 0 || categories.length < 2) {
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
        <EmptyBoard text={gameText(config.strings, 'sorting_unavailable')} />
      </GameScaffold>
    );
  }

  const sort = (categoryId: string) => {
    if (paused || done.current || !current) return;
    const correct = categoryId === current.extra?.categoryId;

    onEvent(
      recorder.custom('item_sorted', {
        itemId: current.id,
        categoryId,
        correct,
        attempt,
      }),
    );

    if (!correct) {
      setWrong(true);
      setAttempt((a) => a + 1);
      return;
    }

    setWrong(false);
    setAttempt(1);
    setHinted(false);

    if (index + 1 >= items.length) {
      onEvent(recorder.custom('sorting_completed'));
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
      <GameLayout
        prompt={gameText(config.strings, 'sorting_where_does_this_go')}
        subPrompt={`${index + 1} / ${items.length}`}
        boardAspect={0.55}
        board={() => (
          // The subject sits alone on the board, large and centred, so it is
          // unmistakably the thing being sorted.
          <View style={styles.subject}>
            <Text numberOfLines={3} style={styles.subjectLabel}>
              {current.label ?? ''}
            </Text>
          </View>
        )}
      >
        {categories.map((c) => (
          <ChoiceCard
            key={c}
            label={gameText(config.strings, `category_${c}`) || c}
            state={
              wrong && c !== current.extra?.categoryId
                ? 'idle'
                : hinted && c === current.extra?.categoryId
                  ? 'hinted'
                  : 'idle'
            }
            onPress={() => sort(c)}
          />
        ))}

        {wrong ? (
          <GentleCorrection text={gameText(config.strings, 'sorting_try_again')} />
        ) : null}
      </GameLayout>
    </GameScaffold>
  );
}

const styles = StyleSheet.create({
  subject: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  subjectLabel: {
    fontSize: 30,
    fontWeight: '700',
    textAlign: 'center',
    color: colors.ink,
  },
});
