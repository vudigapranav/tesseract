/**
 * Shared presentation standards for every activity.
 *
 * Before this, each game invented its own spacing, its own prompt size and its
 * own idea of what "selected" looks like, so five games that should read as one
 * product read as five prototypes. Everything visual that is common now lives
 * here, and a game only draws what is genuinely specific to it.
 *
 * The rules:
 *
 *  - **The board is the subject.** It sits on its own surface with the prompt
 *    above it and supporting actions below, so hierarchy is never ambiguous.
 *  - **One feedback vocabulary.** Selected, correct, incorrect, hinted and
 *    done look the same in every game, and each is carried by shape and
 *    position as well as colour.
 *  - **Forgiving targets.** Interactive cells are never smaller than
 *    `MIN_CELL`, and boards shrink to fit rather than clipping.
 *  - **Restrained motion.** A short scale/opacity settle, skipped entirely
 *    under reduce-motion. Nothing bounces, nothing celebrates loudly.
 *  - **No punishment.** There are no scores, lives, streaks or timers, and a
 *    wrong answer is corrected gently rather than marked.
 */
import React, { useEffect, useRef } from 'react';
import {
  AccessibilityInfo,
  Animated,
  StyleSheet,
  View,
  useWindowDimensions,
  type ViewStyle,
} from 'react-native';
import { colors, spacing } from '../design/tokens';
import { BodyLarge, BodyMedium, TitleLarge } from '../design/components';

/** Smallest an interactive board cell may be, in points. */
export const MIN_CELL = 44;

/** The board's own surface tone — a shade off the page so the edge reads. */
export const BOARD_SURFACE = '#FFFDF9';

/** Feedback states, shared by every game. */
export type TileState =
  | 'idle'
  | 'selected'
  | 'correct'
  | 'incorrect'
  | 'hinted'
  | 'done'
  | 'disabled';

export const tileVisual = (state: TileState) => {
  switch (state) {
    case 'selected':
      return { bg: colors.ink, fg: colors.white, border: colors.ink, width: 2 };
    case 'correct':
    case 'done':
      return { bg: '#E8F0E4', fg: colors.ink, border: '#6F8C63', width: 2 };
    case 'incorrect':
      return { bg: '#FBE7DF', fg: colors.attention, border: colors.attention, width: 2 };
    case 'hinted':
      return { bg: colors.peach, fg: colors.ink, border: colors.coral, width: 3 };
    case 'disabled':
      return { bg: colors.cream, fg: colors.inkSoft, border: colors.hairline, width: 1 };
    default:
      return { bg: colors.white, fg: colors.ink, border: colors.hairline, width: 1 };
  }
};

/** True when the system asks for reduced motion. */
export function useReduceMotion(): boolean {
  const [reduce, setReduce] = React.useState(false);
  useEffect(() => {
    let alive = true;
    void AccessibilityInfo.isReduceMotionEnabled().then((v) => {
      if (alive) setReduce(v);
    });
    const sub = AccessibilityInfo.addEventListener(
      'reduceMotionChanged',
      (v) => setReduce(v),
    );
    return () => {
      alive = false;
      sub.remove();
    };
  }, []);
  return reduce;
}

/**
 * A short settle when `trigger` changes. Deliberately small: this is feedback
 * that something registered, not a celebration.
 */
export function Settle({
  trigger,
  children,
  style,
}: {
  trigger: unknown;
  children: React.ReactNode;
  style?: ViewStyle;
}) {
  const reduce = useReduceMotion();
  const value = useRef(new Animated.Value(1)).current;
  const first = useRef(true);

  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    if (reduce) {
      value.setValue(1);
      return;
    }
    value.setValue(0.94);
    const a = Animated.spring(value, {
      toValue: 1,
      speed: 20,
      bounciness: 4,
      useNativeDriver: true,
    });
    a.start();
    return () => a.stop();
  }, [trigger, reduce, value]);

  return (
    <Animated.View style={[style, { transform: [{ scale: value }] }]}>
      {children}
    </Animated.View>
  );
}

/**
 * The standard activity layout: prompt, board, then supporting content.
 *
 * The board is sized against the smaller screen edge and capped, so it neither
 * clips on a small iPhone nor floats in empty space on a large one.
 */
export function GameLayout({
  prompt,
  subPrompt,
  board,
  boardAspect = 1,
  children,
  fontFamily,
}: {
  prompt: string;
  subPrompt?: string;
  /** Receives the resolved board width in points. */
  board: (size: number) => React.ReactNode;
  /** height / width. 1 is square. */
  boardAspect?: number;
  children?: React.ReactNode;
  fontFamily?: string;
}) {
  const { width, height } = useWindowDimensions();
  const available = width - spacing.gutter * 2;
  // Leave room for the prompt above and the Help/Break controls below, so the
  // board never pushes them off a small screen.
  const maxByHeight = (height - 300) / boardAspect;
  const size = Math.max(240, Math.min(available, maxByHeight, 420));

  return (
    <View style={styles.root}>
      <View style={styles.header}>
        <TitleLarge center fontFamily={fontFamily}>
          {prompt}
        </TitleLarge>
        {subPrompt ? (
          <BodyMedium center tone="soft" fontFamily={fontFamily} style={styles.sub}>
            {subPrompt}
          </BodyMedium>
        ) : null}
      </View>

      <View style={styles.boardWrap}>
        <View style={[styles.board, { width: size, height: size * boardAspect }]}>
          {board(size)}
        </View>
      </View>

      {children ? <View style={styles.below}>{children}</View> : null}
    </View>
  );
}

/**
 * Gentle corrective feedback. Names what happened and keeps the question open;
 * never "wrong", never a mark against the person.
 */
export function GentleCorrection({
  text,
  fontFamily,
}: {
  text: string;
  fontFamily?: string;
}) {
  return (
    <Settle trigger={text}>
      <View style={styles.correction}>
        <BodyLarge center fontFamily={fontFamily} style={{ color: colors.attention }}>
          {text}
        </BodyLarge>
      </View>
    </Settle>
  );
}

/** Shown when a game has no content to run on. Says so plainly. */
export function EmptyBoard({
  text,
  fontFamily,
}: {
  text: string;
  fontFamily?: string;
}) {
  return (
    <View style={styles.empty}>
      <BodyLarge center tone="soft" fontFamily={fontFamily}>
        {text}
      </BodyLarge>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, paddingHorizontal: spacing.gutter, paddingTop: 4 },
  header: { paddingBottom: 12, gap: 4 },
  sub: { marginTop: 2 },
  boardWrap: { alignItems: 'center' },
  board: {
    backgroundColor: BOARD_SURFACE,
    borderRadius: spacing.cardRadius,
    borderWidth: 1,
    borderColor: colors.hairline,
    overflow: 'hidden',
    padding: 10,
  },
  below: { paddingTop: 14, gap: 6 },
  correction: {
    marginTop: 10,
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 999,
    backgroundColor: '#FBE7DF',
    alignSelf: 'center',
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
});
