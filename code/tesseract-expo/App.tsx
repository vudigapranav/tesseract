/**
 * Tesseract — Expo Go build.
 *
 * A React Native port of the Flutter application in `code/host`, which remains
 * the reference implementation and the fallback. This build exists so the app
 * can be opened on an iPhone through Expo Go without a custom native build.
 */
import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AppStateProvider, useApp } from './src/state/AppState';
import { LanguageProvider } from './src/l10n/i18n';
import { Navigation } from './src/Navigation';
import { colors } from './src/design/tokens';

function Localised() {
  const app = useApp();
  return (
    <LanguageProvider
      interfaceCode={app.interfaceLanguage}
      patientCode={app.patientLanguage}
    >
      <Navigation />
    </LanguageProvider>
  );
}

export default function App() {
  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: colors.cream }}>
      <SafeAreaProvider>
        <StatusBar style="dark" />
        <AppStateProvider>
          <Localised />
        </AppStateProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
