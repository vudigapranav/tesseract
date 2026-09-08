/**
 * Shared game chrome: the permanent Help and Break controls, and the pause
 * overlay. Ported from `GameScaffold` in the Dart contract.
 *
 * Nothing here emits events — the game still owns its recorder, so Help and
 * Break stay the game's decisions. This only guarantees the two controls are
 * always reachable while playing and never hidden behind a menu.
 */
import React from 'react';
import { Modal, StyleSheet, View } from 'react-native';
import { colors, spacing } from '../design/tokens';
import {
  BodyLarge,
  HeadlineSmall,
  PillButton,
} from '../design/components';
import type { GameStrings } from './contract';

export function GameScaffold({
  strings,
  paused,
  helpEnabled = true,
  onHelp,
  onBreak,
  onResume,
  onFinishNow,
  fontFamily,
  children,
}: {
  strings: GameStrings;
  paused: boolean;
  helpEnabled?: boolean;
  onHelp: () => void;
  onBreak: () => void;
  onResume: () => void;
  onFinishNow: () => void;
  fontFamily?: string;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.root}>
      <View style={styles.playArea}>{children}</View>

      {/* Always visible, never behind a menu, never below the target floor. */}
      <View style={styles.controls}>
        <PillButton
          label={strings.helpButtonLabel}
          variant="outline"
          disabled={paused || !helpEnabled}
          onPress={onHelp}
          style={styles.control}
        />
        <PillButton
          label={strings.breakButtonLabel}
          variant="outline"
          disabled={paused}
          onPress={onBreak}
          style={styles.control}
        />
      </View>

      <Modal
        visible={paused}
        transparent
        animationType="fade"
        onRequestClose={onResume}
      >
        <View style={styles.scrim}>
          <View style={styles.sheet} accessibilityViewIsModal>
            <HeadlineSmall fontFamily={fontFamily}>
              {strings.pausedTitle}
            </HeadlineSmall>
            <View style={{ height: 12 }} />
            <BodyLarge tone="soft" fontFamily={fontFamily}>
              {strings.pausedBody}
            </BodyLarge>
            <View style={{ height: 24 }} />
            <PillButton label={strings.resumeButtonLabel} onPress={onResume} />
            <PillButton
              label={strings.finishNowButtonLabel}
              variant="outline"
              onPress={onFinishNow}
            />
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  playArea: { flex: 1 },
  controls: {
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: spacing.gutter,
    paddingTop: 4,
  },
  control: { flex: 1 },
  scrim: {
    flex: 1,
    backgroundColor: 'rgba(36,33,31,0.55)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.gutter,
  },
  sheet: {
    width: '100%',
    maxWidth: 420,
    backgroundColor: colors.white,
    borderRadius: spacing.cardRadius,
    padding: 24,
  },
});
