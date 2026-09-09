/**
 * A small picture of what each activity is.
 *
 * The patient's activity list used to be a column of identical buttons with
 * words on them. Words are the hardest thing to read for the people this app
 * is for, and ten of them in a row are indistinguishable at a glance. Each
 * activity now has a drawing that shows its *shape* — two cards, a path with
 * stops, a half-coloured picture — so it can be recognised without reading.
 *
 * Drawn rather than photographed: no licence, no download, no broken image,
 * and it scales from a 72pt tile to a 220pt demonstration without blurring.
 *
 * These are illustrations of the activity, not screenshots of it. They are
 * decorative: every tile still carries the activity's name in text, and these
 * are hidden from screen readers so nothing is announced twice.
 */
import React from 'react';
import { View } from 'react-native';
import Svg, { Circle, G, Line, Path, Polyline, Rect, Text as SvgText } from 'react-native-svg';
import { colors } from '../design/tokens';

const INK = colors.ink;
const CORAL = colors.coral;
const PEACH = colors.peach;
const CREAM = colors.creamTop;
const SOFT = colors.hairline;

/** All previews are drawn on this square and scaled by the caller. */
const CANVAS = 100;

export function ActivityPreview({
  gameId,
  size,
}: {
  gameId: string;
  size: number;
}) {
  return (
    <View
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      style={{
        width: size,
        height: size,
        borderRadius: Math.round(size * 0.2),
        overflow: 'hidden',
        backgroundColor: CREAM,
      }}
    >
      <Svg width={size} height={size} viewBox={`0 0 ${CANVAS} ${CANVAS}`}>
        {drawing(gameId)}
      </Svg>
    </View>
  );
}

function drawing(gameId: string): React.ReactNode {
  switch (gameId) {
    /* Two cards, one turned over. */
    case 'reveal_match':
      return (
        <G>
          <Rect x={12} y={26} width={34} height={48} rx={6} fill={PEACH} />
          <Circle cx={29} cy={50} r={10} fill={CORAL} />
          <Rect x={54} y={26} width={34} height={48} rx={6} fill={INK} opacity={0.12} />
          <Circle cx={71} cy={50} r={7} fill={colors.white} opacity={0.7} />
        </G>
      );

    /* A path between places, with a flag at the end. */
    case 'route_quest':
      return (
        <G>
          <Polyline
            points="16,74 38,74 38,44 70,44 70,24"
            fill="none"
            stroke={SOFT}
            strokeWidth={9}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <Circle cx={16} cy={74} r={8} fill={CORAL} />
          <Circle cx={38} cy={44} r={5} fill={PEACH} />
          <Circle cx={70} cy={24} r={8} fill={INK} />
        </G>
      );

    /* A marble in a corridor with a turn. */
    case 'marble_maze':
      return (
        <G>
          <Rect x={14} y={14} width={72} height={72} rx={8} fill={colors.white} />
          <Path
            d="M26 30 H60 V56 H74"
            fill="none"
            stroke={SOFT}
            strokeWidth={12}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <Circle cx={30} cy={30} r={7} fill={CORAL} />
          <Circle cx={74} cy={56} r={6} fill={INK} opacity={0.25} />
        </G>
      );

    /* A line being followed by a finger. */
    case 'trace':
      return (
        <G>
          <Path
            d="M18 70 Q34 26 50 40 T84 34"
            fill="none"
            stroke={SOFT}
            strokeWidth={12}
            strokeLinecap="round"
          />
          <Path
            d="M18 70 Q30 34 46 40"
            fill="none"
            stroke={CORAL}
            strokeWidth={7}
            strokeLinecap="round"
          />
          <Circle cx={18} cy={70} r={7} fill="#2F7D4F" />
        </G>
      );

    /* Half a picture faded, half in colour. */
    case 'coloring':
      return (
        <G>
          <Rect x={14} y={14} width={72} height={72} rx={8} fill={colors.white} />
          <G opacity={0.18}>
            <Circle cx={38} cy={44} r={16} fill={CORAL} />
            <Rect x={20} y={62} width={60} height={18} fill={INK} />
          </G>
          <G>
            <Circle cx={68} cy={44} r={16} fill={CORAL} />
            <Rect x={54} y={62} width={26} height={18} fill={INK} opacity={0.7} />
          </G>
          <Line x1={50} y1={14} x2={50} y2={86} stroke={SOFT} strokeWidth={2} />
        </G>
      );

    /* Two panels, one with an extra mark. */
    case 'spot_difference':
      return (
        <G>
          <Rect x={10} y={22} width={36} height={56} rx={6} fill={colors.white} />
          <Rect x={54} y={22} width={36} height={56} rx={6} fill={colors.white} />
          <Rect x={18} y={52} width={20} height={18} fill={PEACH} />
          <Rect x={62} y={52} width={20} height={18} fill={PEACH} />
          <Circle cx={36} cy={34} r={7} fill={CORAL} />
          {/* The change: present on the left, missing on the right. */}
          <Circle cx={80} cy={34} r={8} fill="none" stroke={CORAL} strokeWidth={3} strokeDasharray="4 4" />
        </G>
      );

    /* A grid of letters with one word picked out. */
    case 'word_search':
      return (
        <G>
          {[0, 1, 2, 3].map((row) =>
            [0, 1, 2, 3].map((col) => (
              <Rect
                key={`${row}-${col}`}
                x={16 + col * 18}
                y={16 + row * 18}
                width={15}
                height={15}
                rx={3}
                fill={row === 1 && col < 3 ? PEACH : colors.white}
              />
            )),
          )}
          <Line
            x1={23}
            y1={41}
            x2={59}
            y2={41}
            stroke={CORAL}
            strokeWidth={7}
            strokeLinecap="round"
            opacity={0.75}
          />
        </G>
      );

    /* Three steps of a day, in order. */
    case 'routine_recall':
      return (
        <G>
          {[0, 1, 2].map((index) => (
            <G key={index}>
              <Rect
                x={14}
                y={18 + index * 24}
                width={54}
                height={18}
                rx={6}
                fill={index === 2 ? PEACH : colors.white}
              />
              <Circle cx={78} cy={27 + index * 24} r={5} fill={index === 2 ? CORAL : SOFT} />
            </G>
          ))}
        </G>
      );

    /* Pictures going into two groups. */
    case 'picture_sorting':
      return (
        <G>
          <Circle cx={50} cy={26} r={11} fill={CORAL} />
          <Rect x={12} y={54} width={32} height={30} rx={6} fill={colors.white} />
          <Rect x={56} y={54} width={32} height={30} rx={6} fill={PEACH} />
          <Path d="M50 40 L70 52" stroke={SOFT} strokeWidth={4} strokeLinecap="round" />
        </G>
      );

    /* A picture, then a question about it. */
    case 'picture_recall':
      return (
        <G>
          <Rect x={16} y={14} width={68} height={40} rx={6} fill={colors.white} />
          <Circle cx={38} cy={34} r={9} fill={CORAL} />
          <Rect x={54} y={26} width={16} height={16} fill={PEACH} />
          <Rect x={16} y={62} width={30} height={24} rx={6} fill={PEACH} />
          <Rect x={54} y={62} width={30} height={24} rx={6} fill={colors.white} />
          <SvgText
            x={69}
            y={80}
            fontSize={18}
            fontWeight="700"
            fill={INK}
            textAnchor="middle"
          >
            ?
          </SvgText>
        </G>
      );

    default:
      return <Circle cx={50} cy={50} r={26} fill={PEACH} />;
  }
}
