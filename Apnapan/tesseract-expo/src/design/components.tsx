/**
 * The shared look. Ported from the Flutter design system so the two builds
 * read as one product: warm cream ground, decorative coral, rounded white
 * cards, dark readable headings, black pill actions, generous spacing.
 *
 * Accessibility rules that hold everywhere in this file:
 *  - Nothing relies on colour alone. Meaning is carried by words, and usually
 *    an icon as well, so the UI survives greyscale and colour blindness.
 *  - Every control declares an accessibility role and label for VoiceOver.
 *  - Targets never go below `spacing.minTarget`, and patient-facing actions
 *    use the larger `spacing.patientTarget`.
 *  - Text sizes are unscaled tokens, so iOS Dynamic Type scales them freely.
 */
import React from 'react';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  type StyleProp,
  type TextStyle,
  type ViewStyle,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, spacing, type as typeScale } from './tokens';
import { Icon, type IconName } from './Icon';

/* ------------------------------------------------------------------ text - */

type TextTone = 'ink' | 'soft' | 'attention' | 'onDark';

const toneColor: Record<TextTone, string> = {
  ink: colors.ink,
  soft: colors.inkSoft,
  attention: colors.attention,
  onDark: colors.white,
};

interface TxtProps {
  children: React.ReactNode;
  tone?: TextTone;
  style?: StyleProp<TextStyle>;
  center?: boolean;
  /** Bound to the script of the language being rendered, when it needs one. */
  fontFamily?: string;
  numberOfLines?: number;
  accessibilityRole?: 'header' | 'text';
}

const makeText =
  (base: TextStyle) =>
  ({ children, tone = 'ink', style, center, fontFamily, numberOfLines, accessibilityRole }: TxtProps) => (
    <Text
      accessibilityRole={accessibilityRole}
      numberOfLines={numberOfLines}
      style={[
        base,
        { color: toneColor[tone] },
        center && { textAlign: 'center' },
        fontFamily ? { fontFamily } : null,
        style,
      ]}
    >
      {children}
    </Text>
  );

export const HeadlineLarge = makeText(typeScale.headlineLarge as TextStyle);
export const HeadlineSmall = makeText(typeScale.headlineSmall as TextStyle);
export const TitleLarge = makeText(typeScale.titleLarge as TextStyle);
export const BodyLarge = makeText(typeScale.bodyLarge as TextStyle);
export const BodyMedium = makeText(typeScale.bodyMedium as TextStyle);

/* ---------------------------------------------------------------- screen - */

/**
 * Page shell: the warm gradient-ish ground, safe-area padding, and optional
 * scrolling. Content scrolls by default because at large Dynamic Type sizes
 * almost every screen overflows, and a screen that cannot scroll is a screen
 * a low-vision user cannot finish.
 */
export function Screen({
  children,
  scroll = true,
  header,
  footer,
  contentStyle,
}: {
  children: React.ReactNode;
  scroll?: boolean;
  header?: React.ReactNode;
  footer?: React.ReactNode;
  contentStyle?: StyleProp<ViewStyle>;
}) {
  const insets = useSafeAreaInsets();
  const body = (
    <View
      style={[
        { paddingHorizontal: spacing.gutter, paddingBottom: 24 },
        contentStyle,
      ]}
    >
      {children}
    </View>
  );
  return (
    <View style={[styles.screen, { paddingTop: insets.top }]}>
      {header}
      {scroll ? (
        <ScrollView
          style={styles.flex}
          contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
          keyboardShouldPersistTaps="handled"
        >
          {body}
        </ScrollView>
      ) : (
        <View style={styles.flex}>{body}</View>
      )}
      {footer ? (
        <View style={{ paddingBottom: insets.bottom }}>{footer}</View>
      ) : null}
    </View>
  );
}

/* ------------------------------------------------------------------ card - */

export function Card({
  children,
  style,
}: {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
}) {
  return <View style={[styles.card, style]}>{children}</View>;
}

export function SectionHeading({
  title,
  trailing,
}: {
  title: string;
  trailing?: React.ReactNode;
}) {
  return (
    <View style={styles.sectionHeading}>
      <TitleLarge accessibilityRole="header" style={styles.flex}>
        {title}
      </TitleLarge>
      {trailing}
    </View>
  );
}

/** A thin decorative coral rule. Carries no meaning. */
export function CoralAccent({ width = 56 }: { width?: number }) {
  return <View style={[styles.accent, { width }]} accessibilityElementsHidden importantForAccessibility="no" />;
}

/* --------------------------------------------------------------- buttons - */

export function PillButton({
  label,
  onPress,
  disabled,
  busy,
  variant = 'primary',
  accessibilityHint,
  style,
}: {
  label: string;
  onPress?: () => void;
  disabled?: boolean;
  busy?: boolean;
  variant?: 'primary' | 'outline';
  accessibilityHint?: string;
  style?: StyleProp<ViewStyle>;
}) {
  const isDisabled = disabled || busy;
  const primary = variant === 'primary';
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled: !!isDisabled, busy: !!busy }}
      disabled={isDisabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.pill,
        primary ? styles.pillPrimary : styles.pillOutline,
        isDisabled && styles.pillDisabled,
        pressed && !isDisabled && styles.pressed,
        style,
      ]}
    >
      {busy ? (
        <ActivityIndicator color={primary ? colors.white : colors.ink} />
      ) : (
        <Text
          style={[
            styles.pillLabel,
            { color: primary ? colors.white : colors.ink },
          ]}
        >
          {label}
        </Text>
      )}
    </Pressable>
  );
}

/**
 * A large, plainly labelled patient action. Patient screens use these instead
 * of ordinary buttons: generous target, words rather than an icon alone, and
 * no reliance on colour to say what it does.
 */
export function BigPatientAction({
  label,
  subtitle,
  onPress,
  primary = true,
  fontFamily,
  disabled,
}: {
  label: string;
  subtitle?: string;
  onPress?: () => void;
  primary?: boolean;
  fontFamily?: string;
  disabled?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={subtitle ? `${label}. ${subtitle}` : label}
      accessibilityState={{ disabled: !!disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.bigAction,
        primary ? styles.bigActionPrimary : styles.bigActionSecondary,
        disabled && styles.pillDisabled,
        pressed && !disabled && styles.pressed,
      ]}
    >
      <Text
        style={[
          styles.bigActionLabel,
          { color: primary ? colors.white : colors.ink },
          fontFamily ? { fontFamily } : null,
        ]}
      >
        {label}
      </Text>
      {subtitle ? (
        <Text
          style={[
            styles.bigActionSubtitle,
            { color: primary ? colors.white : colors.inkSoft },
            fontFamily ? { fontFamily } : null,
          ]}
        >
          {subtitle}
        </Text>
      ) : null}
    </Pressable>
  );
}

/* ---------------------------------------------------------------- status - */

/**
 * A short status line. Never colour alone: an icon glyph and the words carry
 * the meaning, so this reads correctly in greyscale and to a screen reader.
 */
export function StatusNote({
  text,
  tone = 'neutral',
  icon,
}: {
  text: string;
  tone?: 'neutral' | 'attention';
  icon?: IconName;
}) {
  const color = tone === 'attention' ? colors.attention : colors.inkSoft;
  return (
    <View style={styles.statusRow} accessible accessibilityRole="text">
      {/* Decorative: the sentence beside it carries the meaning. */}
      <View style={styles.statusIcon}>
        <Icon name={icon ?? (tone === 'attention' ? 'alert' : 'info')} color={color} />
      </View>
      <Text style={[typeScale.bodyMedium as TextStyle, { color, flex: 1 }]}>
        {text}
      </Text>
    </View>
  );
}

/** A labelled badge, e.g. the draft marker beside a language. */
export function Badge({ label }: { label: string }) {
  return (
    <View style={styles.badge}>
      <Text style={styles.badgeLabel}>{label}</Text>
    </View>
  );
}

export function Divider() {
  return <View style={styles.divider} />;
}

/* ----------------------------------------------------------------- style - */

const styles = StyleSheet.create({
  flex: { flex: 1 },
  screen: { flex: 1, backgroundColor: colors.cream },
  card: {
    backgroundColor: colors.white,
    borderRadius: spacing.cardRadius,
    padding: 20,
    marginVertical: 8,
  },
  sectionHeading: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 20,
    paddingBottom: 10,
    gap: 12,
  },
  accent: {
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.coral,
    marginBottom: 12,
  },
  pill: {
    minHeight: 56,
    borderRadius: 999,
    paddingHorizontal: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 6,
  },
  pillPrimary: { backgroundColor: colors.ink },
  pillOutline: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: colors.ink,
  },
  pillDisabled: { opacity: 0.4 },
  pressed: { opacity: 0.75 },
  pillLabel: { fontSize: 18, fontWeight: '600', textAlign: 'center' },
  bigAction: {
    minHeight: spacing.patientTarget,
    borderRadius: 999,
    paddingHorizontal: 28,
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 8,
  },
  bigActionPrimary: { backgroundColor: colors.ink },
  bigActionSecondary: {
    backgroundColor: colors.white,
    borderWidth: 1.5,
    borderColor: colors.ink,
  },
  bigActionLabel: { fontSize: 20, fontWeight: '700', textAlign: 'center' },
  bigActionSubtitle: { fontSize: 15, textAlign: 'center', marginTop: 4 },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    paddingVertical: 6,
  },
  statusIcon: { paddingTop: 2 },
  badge: {
    backgroundColor: colors.peach,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  badgeLabel: { fontSize: 13, fontWeight: '600', color: colors.attention },
  divider: {
    height: 1,
    backgroundColor: colors.hairline,
    marginVertical: 16,
  },
});
