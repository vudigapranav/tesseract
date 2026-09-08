/**
 * The standard answer card, shared by every activity that asks someone to
 * choose.
 *
 * Routine Recall and Picture Sorting previously used ordinary buttons, so a
 * choice looked like navigation. This gives choosing its own consistent shape,
 * a target far above the minimum, and one feedback vocabulary — the same
 * `TileState` the boards use.
 */
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, spacing } from '../design/tokens';
import { Icon } from '../design/Icon';
import { Settle, tileVisual, type TileState } from './presentation';

export function ChoiceCard({
  label,
  state = 'idle',
  onPress,
  fontFamily,
}: {
  label: string;
  state?: TileState;
  onPress?: () => void;
  fontFamily?: string;
}) {
  const v = tileVisual(state);
  const disabled = state === 'disabled' || !onPress;

  return (
    <Settle trigger={state}>
      <Pressable
        accessibilityRole={disabled ? 'text' : 'button'}
        accessibilityLabel={label}
        accessibilityState={{ disabled }}
        disabled={disabled}
        onPress={onPress}
        style={({ pressed }) => [
          styles.card,
          {
            backgroundColor: v.bg,
            borderColor: v.border,
            borderWidth: v.width,
          },
          pressed && !disabled && styles.pressed,
        ]}
      >
        <Text
          numberOfLines={3}
          style={[styles.label, { color: v.fg }, fontFamily ? { fontFamily } : null]}
        >
          {label}
        </Text>
        {/* Shape as well as colour: the state is legible in greyscale. */}
        {state === 'incorrect' ? (
          <Icon name="undo" size={22} color={colors.attention} />
        ) : null}
        {state === 'hinted' ? (
          <Icon name="target" size={22} color={colors.coral} />
        ) : null}
        {state === 'correct' || state === 'done' ? (
          <Icon name="check" size={22} color="#6F8C63" />
        ) : null}
      </Pressable>
    </Settle>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    minHeight: spacing.patientTarget,
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderRadius: spacing.cardRadius,
    marginVertical: 6,
  },
  pressed: { opacity: 0.8 },
  label: { flex: 1, fontSize: 20, fontWeight: '600' },
});
