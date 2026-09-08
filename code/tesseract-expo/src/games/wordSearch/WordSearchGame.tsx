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
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, spacing } from '../../design/tokens';
import { BodyLarge, BodyMedium } from '../../design/components';
import { Icon } from '../../design/Icon';
import { GameScaffold } from '../GameScaffold';
import {
  EmptyBoard,
  GameLayout,
  MIN_CELL,
  Settle,
  tileVisual,
  type TileState,
} from '../presentation';
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
        <EmptyBoard text={gameText(config.strings, 'words_unavailable')} />
      </GameScaffold>
    );
  }

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
      <GameLayout
        prompt={gameText(config.strings, 'words_find')}
        subPrompt={`${found.size} / ${grid.words.length}`}
        board={(size) => {
          // The grid fills the board surface exactly, so rows and columns
          // stay aligned at every screen size instead of drifting.
          const inner = size - 20;
          const cell = inner / grid.size;
          return (
            <View style={{ width: inner, height: inner, flexDirection: 'row', flexWrap: 'wrap' }}>
              {grid.letters.map((ch, i) => {
                const isFound = foundCells.has(i);
                const isAnchor = anchor === i;
                const isHint = hinted?.cells.includes(i) ?? false;
                const state: TileState = isFound
                  ? 'done'
                  : isAnchor
                    ? 'selected'
                    : isHint
                      ? 'hinted'
                      : 'idle';
                const v = tileVisual(state);
                return (
                  <Pressable
                    key={i}
                    accessibilityRole="button"
                    accessibilityLabel={ch}
                    accessibilityState={{ selected: isAnchor || isFound }}
                    accessibilityHint={
                      anchor === null
                        ? gameText(config.strings, 'words_find')
                        : undefined
                    }
                    // Hit area is padded out to a forgiving target even when
                    // the drawn cell is smaller than a fingertip.
                    hitSlop={Math.max(0, (MIN_CELL - cell) / 2)}
                    onPress={() => onTapCell(i)}
                    style={{
                      width: cell,
                      height: cell,
                      alignItems: 'center',
                      justifyContent: 'center',
                      backgroundColor: v.bg,
                      borderColor: v.border,
                      borderWidth: v.width,
                      borderRadius: Math.min(10, cell * 0.22),
                    }}
                  >
                    <Text
                      allowFontScaling={false}
                      numberOfLines={1}
                      style={{
                        color: v.fg,
                        fontWeight: isFound || isAnchor ? '700' : '600',
                        // Scaled to the cell so long scripts never overflow
                        // and letters stay optically consistent.
                        fontSize: Math.max(13, cell * 0.46),
                      }}
                    >
                      {ch}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
          );
        }}
      >
        {/* Found words move to a settled state rather than just changing
            colour, so progress is legible at a glance. */}
        <View style={styles.wordList}>
          {grid.words.map((w) => {
            const done = found.has(w.id);
            return (
              <Settle key={w.id} trigger={done}>
                <View
                  style={[styles.wordChip, done && styles.wordChipDone]}
                  accessible
                  accessibilityLabel={`${w.word}${done ? ', found' : ''}`}
                >
                  <Icon
                    name={done ? 'check' : 'target'}
                    size={16}
                    color={done ? '#6F8C63' : colors.inkSoft}
                  />
                  <BodyLarge
                    tone={done ? 'soft' : 'ink'}
                    style={done ? styles.wordDone : undefined}
                  >
                    {w.word}
                  </BodyLarge>
                </View>
              </Settle>
            );
          })}
        </View>

        {grid.skipped.length > 0 ? (
          <BodyMedium tone="soft">
            {gameText(config.strings, 'words_some_did_not_fit')}
          </BodyMedium>
        ) : null}
      </GameLayout>
    </GameScaffold>
  );
}

const sameCells = (a: number[], b: number[]) =>
  a.length === b.length && a.every((v, i) => v === b[i]);

const styles = StyleSheet.create({
  wordList: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  wordChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 999,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.hairline,
    minHeight: 44,
  },
  wordChipDone: { backgroundColor: '#E8F0E4', borderColor: '#6F8C63' },
  wordDone: { textDecorationLine: 'line-through' },
});
