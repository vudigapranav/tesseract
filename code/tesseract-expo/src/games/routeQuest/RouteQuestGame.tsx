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
import { Pressable, StyleSheet, Text, View } from 'react-native';
import Svg, { Circle, G, Line, Path } from 'react-native-svg';
import { colors } from '../../design/tokens';
import { BodyLarge } from '../../design/components';
import { GameScaffold } from '../GameScaffold';
import { GameLayout, MIN_CELL, Settle } from '../presentation';
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

  const target =
    phase === 'outbound' ? topology.destinationIndex : topology.homeIndex;
  const reachable = neighbours(topology, current);

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
      <GameLayout
        prompt={
          phase === 'outbound'
            ? gameText(config.strings, 'route_go_to')
            : gameText(config.strings, 'route_return_home')
        }
        subPrompt={config.showLabels ? (itemFor(target).label ?? '') : undefined}
        board={(size) => {
          const inner = size - 20;
          const px = (i: number) => layout[i][0] * inner;
          const py = (i: number) => layout[i][1] * inner;
          return (
            <View style={{ width: inner, height: inner }}>
              <Svg width={inner} height={inner}>
                {/* Roads are drawn twice: a wide soft bed and a lighter
                    centre line, so a path reads as a road rather than a
                    connector, and stays visible against the board. */}
                {topology.edges.map(([a, b], i) => (
                  <G key={`e${i}`}>
                    <Line
                      x1={px(a)} y1={py(a)} x2={px(b)} y2={py(b)}
                      stroke={colors.peach} strokeWidth={22} strokeLinecap="round"
                    />
                    <Line
                      x1={px(a)} y1={py(a)} x2={px(b)} y2={py(b)}
                      stroke="#FFFFFF" strokeWidth={4} strokeLinecap="round"
                      strokeDasharray="1 10"
                    />
                  </G>
                ))}

                {Array.from({ length: topology.nodeCount }).map((_, i) => {
                  const isHere = i === current;
                  const isTarget = i === target;
                  const isOpen = reachable.includes(i);
                  const isHint = i === hinted;
                  // Where you can go is drawn as an open ring, so a valid
                  // move is obvious without relying on colour alone.
                  return (
                    <G key={`n${i}`}>
                      {isOpen && !isHere ? (
                        <Circle
                          cx={px(i)} cy={py(i)} r={30}
                          fill="none" stroke={colors.coral}
                          strokeWidth={2} strokeDasharray="4 5"
                        />
                      ) : null}
                      <Circle
                        cx={px(i)} cy={py(i)} r={isHere ? 24 : 20}
                        fill={isHere ? colors.ink : colors.white}
                        stroke={isHint ? colors.coral : isTarget ? colors.ink : colors.inkSoft}
                        strokeWidth={isHint ? 4 : isTarget ? 3 : 1.5}
                      />
                      {/* The destination carries a flag, not just a heavier
                          outline — shape, not colour, says where to go. */}
                      {isTarget ? (
                        <Path
                          d={`M${px(i) - 5} ${py(i) + 8} L${px(i) - 5} ${py(i) - 9} L${px(i) + 8} ${py(i) - 5} L${px(i) - 5} ${py(i) - 1}`}
                          fill={colors.coral}
                          stroke={colors.coral}
                          strokeWidth={2}
                          strokeLinejoin="round"
                        />
                      ) : null}
                      {isHere ? (
                        <Circle cx={px(i)} cy={py(i)} r={7} fill={colors.white} />
                      ) : null}
                    </G>
                  );
                })}
              </Svg>

              {/* Real, labelled controls over the drawing: each place is a
                  button a screen reader can find, not a hit-test on a path. */}
              {Array.from({ length: topology.nodeCount }).map((_, i) => {
                const item = itemFor(i);
                const label = item.label ?? `Place ${i + 1}`;
                const isOpen = reachable.includes(i);
                return (
                  <Pressable
                    key={`t${i}`}
                    accessibilityRole="button"
                    accessibilityLabel={label}
                    accessibilityState={{
                      selected: i === current,
                      disabled: !isOpen && i !== current,
                    }}
                    accessibilityHint={
                      i === current
                        ? gameText(config.strings, 'route_you_are_here')
                        : i === target
                          ? gameText(config.strings, 'route_destination')
                          : undefined
                    }
                    onPress={() => onTapNode(i)}
                    style={{
                      position: 'absolute',
                      left: px(i) - MIN_CELL / 2,
                      top: py(i) - MIN_CELL / 2,
                      width: MIN_CELL,
                      height: MIN_CELL,
                      borderRadius: MIN_CELL / 2,
                    }}
                  />
                );
              })}

              {/* Landmark names sit beside their place rather than in a
                  detached legend, so the map is readable on its own. */}
              {config.showLabels
                ? Array.from({ length: topology.nodeCount }).map((_, i) => (
                    <View
                      key={`l${i}`}
                      pointerEvents="none"
                      style={{
                        position: 'absolute',
                        left: px(i) - 60,
                        top: py(i) + 24,
                        width: 120,
                        alignItems: 'center',
                      }}
                    >
                      <Text
                        numberOfLines={2}
                        style={[
                          styles.nodeLabel,
                          i === current && styles.nodeLabelHere,
                        ]}
                      >
                        {itemFor(i).label ?? ''}
                      </Text>
                    </View>
                  ))
                : null}
            </View>
          );
        }}
      >
        <Settle trigger={current}>
          <BodyLarge center tone="soft">
            {config.showLabels ? (itemFor(current).label ?? '') : ''}
          </BodyLarge>
        </Settle>
      </GameLayout>
    </GameScaffold>
  );
}

const styles = StyleSheet.create({
  nodeLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.inkSoft,
    textAlign: 'center',
  },
  nodeLabelHere: { color: colors.ink, fontWeight: '700' },
});
