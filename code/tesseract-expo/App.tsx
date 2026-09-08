/**
 * Apnapan — Expo Go build.
 *
 * A React Native port of the Flutter application in `code/host`, which remains
 * the reference implementation and the fallback. This build exists so the app
 * can be opened on an iPhone through Expo Go without a custom native build.
 *
 * Built and developed by the Tesseract Team.
 */
import React, { useCallback } from 'react';
import { useFonts } from 'expo-font';
import { View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AppStateProvider, useApp } from './src/state/AppState';
import { LanguageProvider } from './src/l10n/i18n';
import { Navigation } from './src/Navigation';
import { OpeningScreen } from './src/screens/OpeningScreen';
import { useOpeningScreen } from './src/state/useOpeningScreen';
import { colors } from './src/design/tokens';

function Shell() {
  const app = useApp();
  const opening = useOpeningScreen();

  const handleRetry = useCallback(() => {
    // Nothing to retry beyond re-reading storage, which AppStateProvider does
    // on mount; this simply lets the person dismiss a stuck opening screen
    // rather than trapping them behind branding.
    opening.dismiss();
  }, [opening]);

  return (
    <LanguageProvider
      interfaceCode={app.interfaceLanguage}
      patientCode={app.patientLanguage}
    >
      {/* The app tree stays mounted underneath the opening screen. That is
          what preserves the current route, form text, authentication state and
          a running activity's timing across a reopen — the brand is an
          overlay, never a remount. */}
      <View style={{ flex: 1 }}>
        <Navigation />
      </View>

      {opening.visible ? (
        <View style={StyleSheetAbsolute}>
          <OpeningScreen
            languageCode={app.interfaceLanguage}
            ready={app.ready}
            onDone={opening.dismiss}
            onRetry={handleRetry}
          />
        </View>
      ) : null}
    </LanguageProvider>
  );
}

/** Full-bleed overlay. Declared once rather than rebuilt every render. */
const StyleSheetAbsolute = {
  position: 'absolute' as const,
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
};

export default function App() {
  // Bundled so Bengali-Assamese and Meetei Mayek render on any device rather
  // than falling back to a face that has no glyphs for them and drawing empty
  // boxes. SIL Open Font License — see assets/fonts/LICENSE-NOTO.txt.
  const [fontsLoaded] = useFonts({
    NotoSansBengali: require('./assets/fonts/NotoSansBengali-Regular.ttf'),
    NotoSansMeeteiMayek: require('./assets/fonts/NotoSansMeeteiMayek-Regular.ttf'),
    NotoSansDevanagari: require('./assets/fonts/NotoSansDevanagari-Regular.ttf'),
  });

  // Held back one frame rather than flashing boxed glyphs at someone whose
  // language depends on these faces.
  if (!fontsLoaded) {
    return <View style={{ flex: 1, backgroundColor: colors.cream }} />;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: colors.cream }}>
      <SafeAreaProvider>
        <StatusBar style="dark" />
        {/* Storage and any saved session load here, in parallel with the
            opening screen's one-second hold, rather than after it. */}
        <AppStateProvider>
          <Shell />
        </AppStateProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
