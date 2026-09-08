/**
 * Navigation.
 *
 * A plain state machine rather than a route stack, because the important
 * transitions here are *modes*, not pages: signed out, caregiver, doctor and
 * patient. Patient mode has no path back to caregiver screens except through
 * the protected gate, which is the point of the hand-over.
 */
import React, { useState } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { useApp } from './state/AppState';
import { SignInScreen } from './screens/SignInScreen';
import {
  CaregiverHomeScreen,
  HandOverScreen,
  PatientBasicsScreen,
} from './screens/CaregiverScreens';
import { SettingsScreen } from './screens/SettingsScreen';
import { KnowMeScreen } from './screens/KnowMeScreen';
import {
  PatientRemindersScreen,
  RemindersScreen,
} from './screens/RemindersScreen';
import { RecommendationsScreen } from './screens/RecommendationsScreen';
import {
  DoctorPatientDetailScreen,
  DoctorPatientsScreen,
} from './screens/DoctorScreens';
import { CaregiverGate } from './components/CaregiverGate';
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
import type { PatientSummary } from './data/apiClient';

type CaregiverRoute =
  | 'home'
  | 'basics'
  | 'settings'
  | 'handOver'
  | 'knowMe'
  | 'reminders'
  | 'recommendations';

type PatientRoute =
  | 'home'
  | 'choose'
  | 'howToPlay'
  | 'play'
  | 'finished'
  | 'rest'
  | 'reminders'
  | 'gate';

type DoctorRoute = 'list' | 'detail';

export function Navigation() {
  const app = useApp();
  const [caregiverRoute, setCaregiverRoute] = useState<CaregiverRoute>('home');
  const [patientRoute, setPatientRoute] = useState<PatientRoute>('home');
  const [doctorRoute, setDoctorRoute] = useState<DoctorRoute>('list');
  const [registration, setRegistration] = useState<GameRegistration | null>(null);
  const [level, setLevel] = useState(1);
  const [result, setResult] = useState<GameResult | null>(null);
  const [doctorPatient, setDoctorPatient] = useState<PatientSummary | null>(null);

  if (!app.ready) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  if (!app.signedIn && !app.previewMode) return <SignInScreen />;

  /* ------------------------------------------------------- doctor mode - */
  if (app.role === 'doctor' && !app.patientMode) {
    if (doctorRoute === 'detail' && doctorPatient) {
      return (
        <DoctorPatientDetailScreen
          patient={doctorPatient}
          onBack={() => setDoctorRoute('list')}
        />
      );
    }
    return (
      <DoctorPatientsScreen
        onOpen={(p) => {
          setDoctorPatient(p);
          setDoctorRoute('detail');
        }}
        onBack={() => setDoctorRoute('list')}
      />
    );
  }

  /* ------------------------------------------------------ patient mode - */
  if (app.patientMode) {
    switch (patientRoute) {
      case 'choose':
        return (
          <ChooseActivityScreen
            onChoose={(r) => {
              setRegistration(r);
              setLevel(1);
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
            level={level}
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
        return <PatientRemindersScreen onBack={() => setPatientRoute('home')} />;
      case 'gate':
        return (
          <CaregiverGate
            onUnlocked={() => {
              app.leavePatientMode();
              setPatientRoute('home');
              setCaregiverRoute('home');
            }}
            onCancel={() => setPatientRoute('home')}
          />
        );
      default:
        return (
          <PatientHomeScreen
            onPlay={() => setPatientRoute('choose')}
            onRest={() => setPatientRoute('rest')}
            onReminders={() => setPatientRoute('reminders')}
            // The only route out of patient mode, and it is protected.
            onReturn={() => setPatientRoute('gate')}
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
    case 'knowMe':
      return <KnowMeScreen onBack={() => setCaregiverRoute('home')} />;
    case 'reminders':
      return <RemindersScreen onBack={() => setCaregiverRoute('home')} />;
    case 'recommendations':
      return <RecommendationsScreen onBack={() => setCaregiverRoute('home')} />;
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
    default:
      return (
        <CaregiverHomeScreen
          onHandOver={() => setCaregiverRoute('handOver')}
          onBasics={() => setCaregiverRoute('basics')}
          onSettings={() => setCaregiverRoute('settings')}
          onKnowMe={() => setCaregiverRoute('knowMe')}
          onReminders={() => setCaregiverRoute('reminders')}
          onRecommendations={() => setCaregiverRoute('recommendations')}
        />
      );
  }
}
