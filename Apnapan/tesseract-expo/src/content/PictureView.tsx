/**
 * Draws a catalogue picture.
 *
 * Pure rendering: it takes a picture id and a size and produces SVG. It has no
 * game knowledge, no state and no side effects, so every activity that needs a
 * recognisable image draws it the same way and a picture looks identical on a
 * card face, in an answer choice and inside a scene.
 *
 * Accessibility: the SVG is marked as an image with a label, so a screen reader
 * announces "Cup" rather than reading nothing. A game that must *not* reveal
 * what a picture is (a face-down card) passes its own label from the outside
 * and sets `decorative`, rather than this component guessing.
 */
import React, { useMemo } from 'react';
import { View } from 'react-native';
import Svg, { Ellipse, Polygon, Rect } from 'react-native-svg';
import { colors } from '../design/tokens';
import { PICTURE_CANVAS, pictureById, type Primitive } from './pictures';

export function PictureView({
  pictureId,
  size,
  label,
  decorative = false,
  /** Draws only these primitives. Used by coloring to build a faded base. */
  opacity = 1,
  /** A rounded frame, for tiles and choices. */
  rounded = true,
}: {
  pictureId: string;
  size: number;
  label?: string;
  decorative?: boolean;
  opacity?: number;
  rounded?: boolean;
}) {
  const picture = useMemo(() => pictureById(pictureId), [pictureId]);

  if (!picture) {
    // A missing picture is drawn as a plain card, never as a broken-image
    // glyph or an error string in front of a patient.
    return (
      <View
        style={{
          width: size,
          height: size,
          borderRadius: rounded ? 16 : 0,
          backgroundColor: colors.peach,
        }}
      />
    );
  }

  return (
    <View
      accessible={!decorative}
      accessibilityRole={decorative ? undefined : 'image'}
      accessibilityLabel={decorative ? undefined : (label ?? picture.label)}
      style={{
        width: size,
        height: size,
        borderRadius: rounded ? 16 : 0,
        overflow: 'hidden',
        opacity,
      }}
    >
      <Svg width={size} height={size} viewBox={`0 0 ${PICTURE_CANVAS} ${PICTURE_CANVAS}`}>
        {picture.primitives.map((primitive, index) => (
          <PrimitiveShape key={index} primitive={primitive} />
        ))}
      </Svg>
    </View>
  );
}

function PrimitiveShape({ primitive }: { primitive: Primitive }) {
  const fill = `#${primitive.color}`;
  if (primitive.type === 'rect') {
    const [x, y, w, h] = primitive.rect;
    return <Rect x={x} y={y} width={w} height={h} fill={fill} />;
  }
  if (primitive.type === 'ellipse') {
    // Authored as a bounding box, drawn from its centre.
    const [x, y, w, h] = primitive.rect;
    return <Ellipse cx={x + w / 2} cy={y + h / 2} rx={w / 2} ry={h / 2} fill={fill} />;
  }
  return (
    <Polygon points={primitive.points.map(([x, y]) => `${x},${y}`).join(' ')} fill={fill} />
  );
}
