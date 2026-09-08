/**
 * Word Search (G7), ported from word_search. Original design: Ruthika.
 *
 * Words come from the caregiver's Know Me content. The words themselves are
 * personal content and never appear in an event — only `wordId` does.
 *
 * Events: word_found {wordId}, selection_rejected {cellCount},
 * all_words_found, content_unavailable {reason, wordIds}.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { colors, spacing } from '../../design/tokens';
import { BodyLarge, StatusNote, TitleLarge } from '../../design/components';
import { GameScaffold } from '../GameScaffold';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';
import { buildWordGrid, lineBetween, wordSearchDifficultyParams } from './grid';

export const WORD_SEARCH_ID = 'word_search';
export { wordSearchDifficultyParams };

export function WordSearchGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const params = useMemo(
    () => wordSearchDifficultyParams(config.level),
    [config.level],
  );
  const { width } = useWindowDimensions();

  const grid = useMemo(() => {
    const entries = config.items
      .filter((i) => (i.label ?? '').trim().length > 0)
      .map((i) => ({ id: i.id, word: (i.label as string).trim() }));
    // Fill letters are drawn from the patient's own words, so a Bengali grid
    // is filled with Bengali characters rather than Latin ones.
    const alphabet = Array.from(new Set(entries.flatMap((e) => Array.from(e.word))));
    return buildWordGrid({
      entries,
      size: params.gridSize,
      wordCount: params.wordCount,
      allowDiagonals: params.allowDiagonals,
      fillAlphabet: alphabet,
    });
  }, [config.items, params]);

  const [found, setFound] = useState<Set<string>>(new Set());
  const [anchor, setAnchor] = useState<number | null>(null);
  const [paused, setPaused] = useState(false);
  const [hintedId, setHintedId] = useState<string | null>(null);
  const started = useRef(false);
  const done = useRef(false);

  if (!started.current) {
    started.current = true;
    onEvent(recorder.sessionStarted());
    if (config.isTutorial) onEvent(recorder.tutorialStarted());
    if (grid.skipped.length > 0) {
      // A caregiver's word that will not fit must not just vanish. Ids only.
      onEvent(
        recorder.custom('content_unavailable', {
          reason: 'word_does_not_fit_grid',
          wordIds: grid.skipped.map((s) => s.id),
        }),
      );
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

  const foundCells = useMemo(() => {
    const s = new Set<number>();
    grid.words.filter((w) => found.has(w.id)).forEach((w) => w.cells.forEach((c) => s.add(c)));
    return s;
  }, [grid.words, found]);

  const onTapCell = (index: number) => {
    if (paused || done.current) return;
    if (anchor === null) {
      setAnchor(index);
      return;
    }
    if (anchor === index) {
      setAnchor(null);
      return;
    }

    const line = lineBetween(grid.size, anchor, index, params.allowDiagonals);
    setAnchor(null);
    if (!line) {
      onEvent(recorder.custom('selection_rejected', { cellCount: 0 }));
      return;
    }

    const match = grid.words.find(
      (w) =>
        !found.has(w.id) &&
        (sameCells(w.cells, line) || sameCells(w.cells, [...line].reverse())),
    );
    if (!match) {
      onEvent(recorder.custom('selection_rejected', { cellCount: line.length }));
      return;
    }

    onEvent(recorder.custom('word_found', { wordId: match.id }));
    const next = new Set(found).add(match.id);
    setFound(next);
    if (hintedId === match.id) setHintedId(null);

    if (next.size >= grid.words.length && grid.words.length > 0) {
      onEvent(recorder.custom('all_words_found'));
      if (config.isTutorial) onEvent(recorder.tutorialCompleted());
      finish(GameResultStatus.completed);
    }
  };

  // Nothing to play. Says so rather than showing an empty grid.
  if (grid.words.length === 0) {
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
            text={gameText(config.strings, 'words_unavailable')}
          />
        </View>
      </GameScaffold>
    );
  }

  const size = Math.min(width - spacing.gutter * 2, 380);
  const cell = size / grid.size;
  const hinted = grid.words.find((w) => w.id === hintedId);

  return (
    <GameScaffold
      strings={config.strings}
      paused={paused}
      onHelp={() => {
        onEvent(recorder.hintRequested());
        const next = grid.words.find((w) => !found.has(w.id));
        setHintedId(next?.id ?? null);
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
        <TitleLarge center>{gameText(config.strings, 'words_find')}</TitleLarge>

        <View style={[styles.grid, { width: size, height: size }]}>
          {grid.letters.map((ch, i) => {
            const isFound = foundCells.has(i);
            const isAnchor = anchor === i;
            const isHint = hinted?.cells.includes(i) ?? false;
            return (
              <Pressable
                key={i}
                accessibilityRole="button"
                accessibilityLabel={ch}
                accessibilityState={{ selected: isAnchor || isFound }}
                onPress={() => onTapCell(i)}
                style={[
                  styles.cell,
                  { width: cell, height: cell },
                  isFound && styles.cellFound,
                  isAnchor && styles.cellAnchor,
                  isHint && !isFound && styles.cellHint,
                ]}
              >
                <BodyLarge tone={isFound || isAnchor ? 'onDark' : 'ink'} center>
                  {ch}
                </BodyLarge>
              </Pressable>
            );
          })}
        </View>

        <View style={styles.wordList}>
          {grid.words.map((w) => (
            <BodyLarge key={w.id} tone={found.has(w.id) ? 'soft' : 'ink'}>
              {found.has(w.id) ? `✓ ${w.word}` : `• ${w.word}`}
            </BodyLarge>
          ))}
        </View>

        {grid.skipped.length > 0 ? (
          <StatusNote
            glyph="!"
            tone="attention"
            text={gameText(config.strings, 'words_some_did_not_fit')}
          />
        ) : null}
      </View>
    </GameScaffold>
  );
}

const sameCells = (a: number[], b: number[]) =>
  a.length === b.length && a.every((v, i) => v === b[i]);

const styles = StyleSheet.create({
  body: { flex: 1, paddingHorizontal: spacing.gutter, paddingTop: 8 },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignSelf: 'center',
    marginTop: 12,
  },
  cell: {
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: colors.hairline,
    backgroundColor: colors.white,
  },
  cellFound: { backgroundColor: colors.ink },
  cellAnchor: { backgroundColor: colors.coral },
  cellHint: { borderColor: colors.coral, borderWidth: 3 },
  wordList: { marginTop: 16, gap: 4 },
});
