/**
 * The icon set.
 *
 * Drawn as SVG paths rather than typed as emoji or dingbat characters. Those
 * were standing in for icons and it showed: they render differently on every
 * device, ignore the app's colours, sit off the text baseline, and are read
 * aloud by VoiceOver as whatever the platform calls them ("waving hand sign")
 * rather than as the thing they meant.
 *
 * Every icon here is decorative by default — the meaning is always carried by
 * adjacent words, so the UI still reads correctly in greyscale, at any size,
 * and to a screen reader.
 */
import React from 'react';
import Svg, { Circle, Path, Rect } from 'react-native-svg';
import { colors } from './tokens';

export type IconName =
  | 'info'
  | 'alert'
  | 'sync'
  | 'flag'
  | 'speaker'
  | 'speakerOff'
  | 'microphone'
  | 'microphoneOff'
  | 'lock'
  | 'check'
  | 'cross'
  | 'undo'
  | 'hand'
  | 'target'
  | 'pencil'
  | 'help';

export function Icon({
  name,
  size = 20,
  color = colors.inkSoft,
}: {
  name: IconName;
  size?: number;
  color?: string;
}) {
  const stroke = {
    stroke: color,
    strokeWidth: 2,
    strokeLinecap: 'round' as const,
    strokeLinejoin: 'round' as const,
    fill: 'none',
  };
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      {name === 'info' && (
        <>
          <Circle cx={12} cy={12} r={9} {...stroke} />
          <Path d="M12 11v5" {...stroke} />
          <Circle cx={12} cy={7.75} r={1.1} fill={color} stroke="none" />
        </>
      )}
      {name === 'alert' && (
        <>
          <Path d="M12 3.5 21 20H3L12 3.5Z" {...stroke} />
          <Path d="M12 10v4.5" {...stroke} />
          <Circle cx={12} cy={17.2} r={1.1} fill={color} stroke="none" />
        </>
      )}
      {name === 'sync' && (
        <>
          <Path d="M4 10a8 8 0 0 1 13.6-4.6L20 8" {...stroke} />
          <Path d="M20 4v4h-4" {...stroke} />
          <Path d="M20 14a8 8 0 0 1-13.6 4.6L4 16" {...stroke} />
          <Path d="M4 20v-4h4" {...stroke} />
        </>
      )}
      {name === 'flag' && (
        <>
          <Path d="M6 21V4" {...stroke} />
          <Path d="M6 5h11l-2.2 3.6L17 12H6" {...stroke} />
        </>
      )}
      {name === 'speaker' && (
        <>
          <Path d="M4 9.5h3.5L12 5.5v13L7.5 14.5H4Z" {...stroke} />
          <Path d="M15.5 9.2a4 4 0 0 1 0 5.6" {...stroke} />
          <Path d="M18 6.7a7.5 7.5 0 0 1 0 10.6" {...stroke} />
        </>
      )}
      {name === 'speakerOff' && (
        <>
          <Path d="M4 9.5h3.5L12 5.5v13L7.5 14.5H4Z" {...stroke} />
          <Path d="M16 10l5 4M21 10l-5 4" {...stroke} />
        </>
      )}
      {name === 'microphone' && (
        <>
          <Rect x={9} y={3} width={6} height={11} rx={3} {...stroke} />
          <Path d="M5.5 11.5a6.5 6.5 0 0 0 13 0" {...stroke} />
          <Path d="M12 18v3" {...stroke} />
        </>
      )}
      {name === 'microphoneOff' && (
        <>
          <Rect x={9} y={3} width={6} height={11} rx={3} {...stroke} />
          <Path d="M5.5 11.5a6.5 6.5 0 0 0 13 0" {...stroke} />
          <Path d="M4 4l16 16" {...stroke} />
        </>
      )}
      {name === 'lock' && (
        <>
          <Rect x={5} y={10.5} width={14} height={10} rx={2.6} {...stroke} />
          <Path d="M8.5 10.5V7.8a3.5 3.5 0 0 1 7 0v2.7" {...stroke} />
        </>
      )}
      {name === 'check' && <Path d="M4.5 12.5 10 18 19.5 6.5" {...stroke} />}
      {name === 'cross' && <Path d="M6 6l12 12M18 6L6 18" {...stroke} />}
      {name === 'undo' && (
        <>
          <Path d="M4 10h9a5.5 5.5 0 1 1 0 11H8" {...stroke} />
          <Path d="M4 10l4-4M4 10l4 4" {...stroke} />
        </>
      )}
      {name === 'hand' && (
        <>
          <Path
            d="M8.5 12V5.6a1.6 1.6 0 0 1 3.2 0V11m0-.5V4.6a1.6 1.6 0 0 1 3.2 0V11m0-.4V6.6a1.6 1.6 0 0 1 3.2 0V14a7 7 0 0 1-7 7h-.8a5.6 5.6 0 0 1-4.5-2.4L3.7 15a1.7 1.7 0 0 1 2.6-2.1l2.2 2"
            {...stroke}
          />
        </>
      )}
      {name === 'target' && (
        <>
          <Circle cx={12} cy={12} r={8.5} {...stroke} />
          <Circle cx={12} cy={12} r={4} {...stroke} />
          <Circle cx={12} cy={12} r={1.3} fill={color} stroke="none" />
        </>
      )}
      {name === 'pencil' && (
        <>
          <Path d="M4 20l1-4.2L16.2 4.6a2 2 0 0 1 2.8 2.8L7.8 18.6 4 20Z" {...stroke} />
          <Path d="M14.5 6.5l3 3" {...stroke} />
        </>
      )}
      {name === 'help' && (
        <>
          <Circle cx={12} cy={12} r={9} {...stroke} />
          <Path d="M9.4 9.3a2.7 2.7 0 1 1 3.5 2.6c-.6.2-.9.7-.9 1.3v.6" {...stroke} />
          <Circle cx={12} cy={17} r={1.1} fill={color} stroke="none" />
        </>
      )}
    </Svg>
  );
}
