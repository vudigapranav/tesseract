/**
 * Route Quest (G2), ported from route_quest.
 *
 * Original gameplay and design: Ruthika. This is a platform port — the rules,
 * event names, sequencing and difficulty settings are unchanged.
 *
 * Walk from home to the destination along connected places, pick the item up,
 * and walk back. Difficulty changes the map only: each level is a fixed shape
 * from `topologyForLevel`, never a computed difficulty score.
 *
 * Events: location_entered {nodeId}, wrong_interaction {objectId},
 * destination_reached, item_collected, return_completed — opaque ids only.
 */
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import Svg, { Circle, Line } from 'react-native-svg';
import { colors, spacing } from '../../design/tokens';
import { BodyLarge, TitleLarge } from '../../design/components';
import { GameScaffold } from '../GameScaffold';
import {
  GameResultStatus,
  TesseractEventRecorder,
  gameText,
  type TesseractGameProps,
} from '../contract';
import {
  layoutForLevel,
  neighbours,
  shortestPath,
  topologyForLevel,
} from './topology';

export const ROUTE_QUEST_ID = 'route_quest';

/** The real map settings for a level, never just the level number. */
export function routeQuestDifficultyParams(level: number) {
  const t = topologyForLevel(level);
  return {
    nodeCount: t.nodeCount,
    branchCount: t.branchCount,
    requiresReturn: true,
  };
}

type Phase = 'outbound' | 'returning';

export function RouteQuestGame({ config, onEvent, onFinish }: TesseractGameProps) {
  const recorder = useRef(new TesseractEventRecorder()).current;
  const topology = useMemo(() => topologyForLevel(config.level), [config.level]);
  const layout = useMemo(() => layoutForLevel(config.level), [config.level]);
  const { width } = useWindowDimensions();

  const [current, setCurrent] = useState(topology.homeIndex);
  const [phase, setPhase] = useState<Phase>('outbound');
  const [paused, setPaused] = useState(false);
  const [hinted, setHinted] = useState<number | null>(null);
  const started = useRef(false);
  const done = useRef(false);

  if (!started.current) {
    started.current = true;
    onEvent(recorder.sessionStarted());
    if (config.isTutorial) onEvent(recorder.tutorialStarted());
  }

  /**
   * Items are the caregiver's own places. Their labels are shown but never
   * travel in an event — only `item.id` does.
   */
  const itemFor = (index: number) =>
    config.items[index] ?? { id: `n${index}`, label: undefined };

  const finish = useCallback(
    (status: 'completed' | 'stopped_by_user') => {
      if (done.current) return;
      done.current = true;
      onEvent(recorder.sessionFinished(status));
      onFinish(recorder.result(status));
    },
    [onEvent, onFinish, recorder],
  );

  const onTapNode = (index: number) => {
    if (paused || done.current || index === current) return;

    const adjacent = neighbours(topology, current).includes(index);
    if (!adjacent) {
      // A tap on an unconnected place is recorded, but nothing moves and
      // nothing is scored against the person.
      onEvent(
        recorder.custom('wrong_interaction', { objectId: itemFor(index).id }),
      );
      return;
    }

    setCurrent(index);
    setHinted(null);
    onEvent(recorder.custom('location_entered', { nodeId: itemFor(index).id }));

    if (phase === 'outbound' && index === topology.destinationIndex) {
      onEvent(recorder.custom('destination_reached'));
      onEvent(recorder.custom('item_collected'));
      setPhase('returning');
      return;
    }
    if (phase === 'returning' && index === topology.homeIndex) {
      onEvent(recorder.custom('return_completed'));
      if (config.isTutorial) onEvent(recorder.tutorialCompleted());
      finish(GameResultStatus.completed);
    }
  };

  const onHelp = () => {
    // Help shows the next step of the route. It always emits hint_requested
    // and marks the session assisted, permanently.
    onEvent(recorder.hintRequested());
    const target =
      phase === 'outbound' ? topology.destinationIndex : topology.homeIndex;
    const path = shortestPath(topology, current, target);
    setHinted(path.length > 1 ? path[1] : null);
  };

  const size = Math.min(width - spacing.gutter * 2, 420);
  const target =
    phase === 'outbound' ? topology.destinationIndex : topology.homeIndex;

  return (
    <GameScaffold
      strings={config.strings}
      paused={paused}
      onHelp={onHelp}
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
          {phase === 'outbound'
            ? gameText(config.strings, 'route_go_to')
            : gameText(config.strings, 'route_return_home')}
        </TitleLarge>
        <BodyLarge center tone="soft" style={{ marginTop: 4 }}>
          {config.showLabels ? (itemFor(target).label ?? '') : ''}
        </BodyLarge>

        <View style={{ height: size, width: size, alignSelf: 'center', marginTop: 12 }}>
          <Svg width={size} height={size}>
            {topology.edges.map(([a, b], i) => (
              <Line
                key={`e${i}`}
                x1={layout[a][0] * size}
                y1={layout[a][1] * size}
                x2={layout[b][0] * size}
                y2={layout[b][1] * size}
                stroke={colors.peach}
                strokeWidth={14}
                strokeLinecap="round"
              />
            ))}
            {Array.from({ length: topology.nodeCount }).map((_, i) => (
              <Circle
                key={`n${i}`}
                cx={layout[i][0] * size}
                cy={layout[i][1] * size}
                r={i === current ? 26 : 22}
                fill={i === current ? colors.ink : colors.white}
                stroke={
                  i === hinted
                    ? colors.coral
                    : i === target
                      ? colors.ink
                      : colors.inkSoft
                }
                strokeWidth={i === hinted ? 5 : 2}
              />
            ))}
          </Svg>

          {/* Touch targets sit above the drawing so each place is a real,
              labelled, large control rather than a hit-test on a path. */}
          {Array.from({ length: topology.nodeCount }).map((_, i) => {
            const item = itemFor(i);
            const label = item.label ?? `Place ${i + 1}`;
            const isTarget = i === target;
            return (
              <Pressable
                key={`t${i}`}
                accessibilityRole="button"
                accessibilityLabel={label}
                accessibilityHint={
                  i === current
                    ? gameText(config.strings, 'route_you_are_here')
                    : isTarget
                      ? gameText(config.strings, 'route_destination')
                      : undefined
                }
                accessibilityState={{ selected: i === current }}
                onPress={() => onTapNode(i)}
                style={[
                  styles.hit,
                  {
                    left: layout[i][0] * size - 32,
                    top: layout[i][1] * size - 32,
                  },
                ]}
              />
            );
          })}
        </View>

        {config.showLabels ? (
          <View style={styles.legend}>
            {Array.from({ length: topology.nodeCount }).map((_, i) => (
              <BodyLarge key={`l${i}`} tone={i === current ? 'ink' : 'soft'}>
                {`${i === current ? '● ' : '○ '}${itemFor(i).label ?? ''}`}
              </BodyLarge>
            ))}
          </View>
        ) : null}
      </View>
    </GameScaffold>
  );
}

const styles = StyleSheet.create({
  body: { flex: 1, paddingHorizontal: spacing.gutter, paddingTop: 8 },
  hit: { position: 'absolute', width: 64, height: 64, borderRadius: 32 },
  legend: { marginTop: 12, gap: 2 },
});
