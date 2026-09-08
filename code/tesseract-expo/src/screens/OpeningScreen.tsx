/**
 * The Apnapan opening screen.
 *
 * This is an **in-app** screen, drawn by React once the JavaScript is running.
 * That is deliberate and it matters for what it can and cannot do:
 *
 *  - In Expo Go it is the only branding the user sees, and it works there.
 *  - It is **not** the iOS launch screen, and it does not control the
 *    home-screen icon or app name. Those belong to whatever binary is
 *    installed — which, in Expo Go, is Expo Go. Changing them needs a
 *    separately installed build of Apnapan.
 *
 * Held for about a second, then handed over. If initialisation is still going
 * after that, it says so rather than routing somewhere half-loaded.
 */
import React, { useEffect, useRef, useState } from 'react';
import {
  AccessibilityInfo,
  Animated,
  Image,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, fontFamilyForScript, spacing } from '../design/tokens';
import { BodyLarge, BodyMedium, PillButton, TitleLarge } from '../design/components';
import { translate } from '../l10n/i18n';
import { languageByCode, type LanguageCode } from '../l10n/languages';

/** How long the brand is held before handing over. */
export const OPENING_MS = 1000;

const LOGO = require('../../assets/branding/apnapan-logo.png');

export function OpeningScreen({
  languageCode,
  /** True once saved settings and any stored session have finished loading. */
  ready,
  onDone,
  onRetry,
}: {
  languageCode: LanguageCode;
  ready: boolean;
  onDone: () => void;
  onRetry?: () => void;
}) {
  const insets = useSafeAreaInsets();
  const { width, height } = useWindowDimensions();
  const t = (k: Parameters<typeof translate>[1]) => translate(languageCode, k);
  const font = fontFamilyForScript(languageByCode(languageCode).script);

  const fade = useRef(new Animated.Value(0)).current;
  const [elapsed, setElapsed] = useState(false);
  const [reduceMotion, setReduceMotion] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void AccessibilityInfo.isReduceMotionEnabled().then((v) => {
      if (!cancelled) setReduceMotion(v);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  /* A short, subtle fade — skipped entirely when the system asks for reduced
     motion, in which case the brand is simply present. */
  useEffect(() => {
    if (reduceMotion) {
      fade.setValue(1);
      return;
    }
    const animation = Animated.timing(fade, {
      toValue: 1,
      duration: 260,
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [fade, reduceMotion]);

  /* The one-second hold. Cleared on unmount so a fast reload cannot leave a
     timer pointing at a screen that is gone. */
  useEffect(() => {
    const timer = setTimeout(() => setElapsed(true), OPENING_MS);
    return () => clearTimeout(timer);
  }, []);

  /* Hand over only when the hold has passed *and* loading has finished.
     Routing before the saved session is known would flash the sign-in screen
     at someone who is already signed in. */
  useEffect(() => {
    if (elapsed && ready) onDone();
  }, [elapsed, ready, onDone]);

  // Sized against the smaller edge so a small iPhone in landscape, or a very
  // large text setting, cannot push the wordmark off screen.
  const logoSize = Math.min(width * 0.62, height * 0.34, 300);
  const stillLoading = elapsed && !ready;

  return (
    <View
      style={[
        styles.root,
        { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24 },
      ]}
      accessible
      accessibilityRole="header"
      accessibilityLabel={`${t('appName')}. ${t('appTagline')}`}
    >
      <Animated.View style={[styles.center, { opacity: fade }]}>
        <Image
          source={LOGO}
          style={{ width: logoSize, height: logoSize }}
          resizeMode="contain"
          // The wordmarks are inside the artwork; the text below carries the
          // meaning for a screen reader, so the image itself is decorative.
          accessibilityElementsHidden
          importantForAccessibility="no"
        />

        <View style={{ height: 20 }} />

        {/* Real text, not part of the image: it scales with Dynamic Type,
            is readable by VoiceOver, and is localised. */}
        <BodyLarge center fontFamily={font} style={styles.tagline}>
          {t('appTagline')}
        </BodyLarge>
      </Animated.View>

      <View style={styles.footer}>
        {stillLoading ? (
          <View style={styles.loadingBlock}>
            {/* Honest: the hold is over but the app is not ready, so it says
                so instead of routing somewhere half-initialised. */}
            <TitleLarge center fontFamily={font}>
              {t('signingIn')}
            </TitleLarge>
            {onRetry ? (
              <PillButton
                label={t('tryAgain')}
                variant="outline"
                onPress={onRetry}
              />
            ) : null}
          </View>
        ) : null}

        <BodyMedium center tone="soft" style={styles.attribution}>
          {t('builtBy')}
        </BodyMedium>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    // Matches the logo artwork's own ground, so the image edge is invisible.
    backgroundColor: '#FEF8EE',
    paddingHorizontal: spacing.gutter,
    justifyContent: 'space-between',
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tagline: { maxWidth: 420 },
  footer: { alignItems: 'center', gap: 16 },
  loadingBlock: { alignItems: 'center', gap: 12, alignSelf: 'stretch' },
  attribution: { color: colors.inkSoft },
});
