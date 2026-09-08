/**
 * Navigation.
 *
 * A plain state machine rather than a route stack, because the important
 * transitions here are *modes*, not pages: signed out, caregiver, and patient.
 * Patient mode has no path back to caregiver screens except through the
 * protected return, which is the point of the hand-over.
 */
import React, { useState } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { Screen, StatusNote, HeadlineLarge, PillButton } from './design/components';
import { useApp } from './state/AppState';
import { SignInScreen } from './screens/SignInScreen';
import {
  CaregiverHomeScreen,
  HandOverScreen,
  PatientBasicsScreen,
} from './screens/CaregiverScreens';
import { SettingsScreen } from './screens/SettingsScreen';
import {
  ChooseActivityScreen,
  FinishedScreen,
  HowToPlayScreen,
  PatientHomeScreen,
  PlayScreen,
  RestScreen,
} from './screens/PatientScreens';
import type { GameRegistration } from './games/registry';
import type { GameResult } from './games/contract';
import { translate } from './l10n/i18n';

type CaregiverRoute = 'home' | 'basics' | 'settings' | 'handOver' | 'stub';
type PatientRoute =
  | 'home'
  | 'choose'
  | 'howToPlay'
  | 'play'
  | 'finished'
  | 'rest'
  | 'reminders';

export function Navigation() {
  const app = useApp();
  const [caregiverRoute, setCaregiverRoute] = useState<CaregiverRoute>('home');
  const [patientRoute, setPatientRoute] = useState<PatientRoute>('home');
  const [registration, setRegistration] = useState<GameRegistration | null>(null);
  const [result, setResult] = useState<GameResult | null>(null);
  const [stubTitle, setStubTitle] = useState('');

  if (!app.ready) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  if (!app.signedIn && !app.previewMode) return <SignInScreen />;

  /* ------------------------------------------------------ patient mode - */
  if (app.patientMode) {
    switch (patientRoute) {
      case 'choose':
        return (
          <ChooseActivityScreen
            onChoose={(r) => {
              setRegistration(r);
              setPatientRoute('howToPlay');
            }}
            onBack={() => setPatientRoute('home')}
          />
        );
      case 'howToPlay':
        return registration ? (
          <HowToPlayScreen
            registration={registration}
            onBegin={() => setPatientRoute('play')}
            onBack={() => setPatientRoute('choose')}
          />
        ) : null;
      case 'play':
        return registration ? (
          <PlayScreen
            registration={registration}
            level={1}
            onFinished={(r) => {
              setResult(r);
              setPatientRoute('finished');
            }}
          />
        ) : null;
      case 'finished':
        return result ? (
          <FinishedScreen
            result={result}
            onAgain={() => setPatientRoute('choose')}
            onHome={() => setPatientRoute('home')}
          />
        ) : null;
      case 'rest':
        return (
          <RestScreen
            onReady={() => setPatientRoute('choose')}
            onHome={() => setPatientRoute('home')}
          />
        );
      case 'reminders':
        return (
          <Stub
            title={translate(app.patientLanguage, 'todaysReminders')}
            note="Reminders are not implemented in this Expo build yet. See the status document for what is and is not done."
            onBack={() => setPatientRoute('home')}
          />
        );
      default:
        return (
          <PatientHomeScreen
            onPlay={() => setPatientRoute('choose')}
            onRest={() => setPatientRoute('rest')}
            onReminders={() => setPatientRoute('reminders')}
            onReturn={() => {
              // The protected door back. There is no other route out of
              // patient mode.
              app.leavePatientMode();
              setPatientRoute('home');
              setCaregiverRoute('home');
            }}
          />
        );
    }
  }

  /* ---------------------------------------------------- caregiver mode - */
  switch (caregiverRoute) {
    case 'basics':
      return <PatientBasicsScreen onDone={() => setCaregiverRoute('home')} />;
    case 'settings':
      return <SettingsScreen onBack={() => setCaregiverRoute('home')} />;
    case 'handOver':
      return (
        <HandOverScreen
          onConfirm={() => {
            app.enterPatientMode();
            setPatientRoute('home');
            setCaregiverRoute('home');
          }}
          onCancel={() => setCaregiverRoute('home')}
        />
      );
    case 'stub':
      return (
        <Stub
          title={stubTitle}
          note="Not implemented in this Expo build yet. The Flutter build has it; see the Expo status document for the current gap list."
          onBack={() => setCaregiverRoute('home')}
        />
      );
    default:
      return (
        <CaregiverHomeScreen
          onHandOver={() => setCaregiverRoute('handOver')}
          onBasics={() => setCaregiverRoute('basics')}
          onSettings={() => setCaregiverRoute('settings')}
          onKnowMe={() => {
            setStubTitle(translate(app.interfaceLanguage, 'knowMe'));
            setCaregiverRoute('stub');
          }}
          onReminders={() => {
            setStubTitle(translate(app.interfaceLanguage, 'reminders'));
            setCaregiverRoute('stub');
          }}
        />
      );
  }
}

/**
 * An explicitly unfinished screen.
 *
 * Deliberately blunt rather than a plausible-looking empty state: a screen
 * that looks finished but does nothing is worse than one that says it is not
 * built yet.
 */
function Stub({
  title,
  note,
  onBack,
}: {
  title: string;
  note: string;
  onBack: () => void;
}) {
  const app = useApp();
  return (
    <Screen>
      <View style={{ height: 24 }} />
      <HeadlineLarge>{title}</HeadlineLarge>
      <View style={{ height: 16 }} />
      <StatusNote glyph="⚑" tone="attention" text={note} />
      <View style={{ height: 16 }} />
      <PillButton
        label={translate(app.interfaceLanguage, 'goBack')}
        variant="outline"
        onPress={onBack}
      />
    </Screen>
  );
}
