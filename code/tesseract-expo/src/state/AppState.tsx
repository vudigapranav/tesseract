/**
 * Application state: identity, languages, preferences, the selected patient,
 * the outbox and the speech service.
 *
 * Two rules shape this file:
 *
 *  - **Partitioned by caregiver.** Storage points at the signed-in identity's
 *    scope, so a shared phone never shows one caregiver another's patient.
 *    Signing out returns to the anonymous scope, which holds only device
 *    preferences.
 *  - **Patient language is independent** of the caregiver's interface
 *    language, because the two people may not read the same language.
 */
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { AppState as RNAppState } from 'react-native';
import { ApiClient } from '../data/apiClient';
import { isApiConfigured, isIdentityConfigured } from '../data/config';
import { IdentityService } from '../data/identity';
import { SessionOutbox } from '../data/outbox';
import * as storage from '../data/storage';
import { SpeechOutputService } from '../speech/tts';
import type { LanguageCode } from '../l10n/languages';

export type Role = 'caregiver' | 'doctor';

export interface PatientSnapshot {
  id: string;
  displayName: string;
  language: LanguageCode;
  /** Server revision last read, for conflict-aware uploads. */
  profileRevision?: string;
  /** Local-only until a patient-basics update endpoint exists. */
  ageYears?: number;
  notes?: string;
}

export interface Preferences {
  audioEnabled: boolean;
  reducedMotion: boolean;
  /** Marble Maze: prefer the touch fallback over phone motion. */
  preferTouch: boolean;
  textScale: number;
}

const DEFAULT_PREFS: Preferences = {
  audioEnabled: true,
  reducedMotion: false,
  preferTouch: false,
  textScale: 1,
};

interface AppStateValue {
  ready: boolean;

  /* identity */
  identity: IdentityService;
  role: Role | null;
  signedIn: boolean;
  identityConfigured: boolean;
  apiConfigured: boolean;
  signIn: (email: string, password: string, role: Role) => Promise<void>;
  signOut: () => Promise<void>;

  /** Explicitly chosen, visibly labelled. Never reached by a sign-in failing. */
  previewMode: boolean;
  enterPreview: () => Promise<void>;

  /* languages */
  interfaceLanguage: LanguageCode;
  patientLanguage: LanguageCode;
  setInterfaceLanguage: (code: LanguageCode) => Promise<void>;
  setPatientLanguage: (code: LanguageCode) => Promise<void>;

  /* preferences */
  prefs: Preferences;
  setPrefs: (next: Partial<Preferences>) => Promise<void>;

  /* patients */
  patients: PatientSnapshot[];
  selectedPatient: PatientSnapshot | null;
  selectPatient: (id: string) => Promise<void>;
  upsertPatient: (p: PatientSnapshot) => Promise<void>;
  refreshPatients: () => Promise<void>;
  patientsError: string | null;

  /* patient mode */
  patientMode: boolean;
  enterPatientMode: () => void;
  leavePatientMode: () => void;

  /* services */
  api: ApiClient | null;
  outbox: SessionOutbox;
  speech: SpeechOutputService;
  syncNow: () => Promise<void>;
  pendingUploads: number;
}

const Ctx = createContext<AppStateValue | null>(null);

export function AppStateProvider({ children }: { children: React.ReactNode }) {
  const identity = useRef(new IdentityService()).current;
  const [ready, setReady] = useState(false);
  const [role, setRole] = useState<Role | null>(null);
  const [signedIn, setSignedIn] = useState(false);
  const [previewMode, setPreviewMode] = useState(false);
  const [interfaceLanguage, setInterfaceLang] = useState<LanguageCode>('en');
  const [patientLanguage, setPatientLang] = useState<LanguageCode>('en');
  const [prefs, setPrefsState] = useState<Preferences>(DEFAULT_PREFS);
  const [patients, setPatients] = useState<PatientSnapshot[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [patientMode, setPatientMode] = useState(false);
  const [patientsError, setPatientsError] = useState<string | null>(null);
  const [pendingUploads, setPending] = useState(0);

  const prefsRef = useRef(prefs);
  prefsRef.current = prefs;

  const speech = useRef(
    new SpeechOutputService(() => prefsRef.current.audioEnabled),
  ).current;

  const api = useMemo(
    () =>
      isApiConfigured() && signedIn
        ? new ApiClient(() => identity.token())
        : null,
    [signedIn, identity],
  );
  const apiRef = useRef(api);
  apiRef.current = api;

  const outbox = useRef(new SessionOutbox(() => apiRef.current)).current;

  /* ------------------------------------------------------------- boot - */
  useEffect(() => {
    (async () => {
      await storage.restoreScope();
      const restored = await identity.restore();
      if (restored) {
        await storage.useScope(identity.uid);
        setSignedIn(true);
        setRole(await storage.readJson<Role>('role', 'caregiver'));
      }
      setInterfaceLang(
        await storage.readJson<LanguageCode>('interfaceLanguage', 'en'),
      );
      setPatientLang(await storage.readJson<LanguageCode>('patientLanguage', 'en'));
      setPrefsState(await storage.readJson<Preferences>('prefs', DEFAULT_PREFS));
      setPatients(await storage.readJson<PatientSnapshot[]>('patients', []));
      setSelectedId(await storage.readJson<string | null>('selectedPatient', null));
      await outbox.load();
      setReady(true);
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => outbox.subscribe(() => setPending(outbox.pendingCount)), [outbox]);

  /* Speech must not continue out of a backgrounded app. */
  useEffect(() => {
    const sub = RNAppState.addEventListener('change', (s) => {
      if (s !== 'active') void speech.handleAppBackgrounded();
    });
    return () => sub.remove();
  }, [speech]);

  /* --------------------------------------------------------- identity - */
  const signIn = useCallback(
    async (email: string, password: string, nextRole: Role) => {
      await identity.signIn(email, password);
      await storage.useScope(identity.uid);
      await storage.writeJson('role', nextRole);
      setRole(nextRole);
      setSignedIn(true);
      setPreviewMode(false);
      // Preferences and patients are per-caregiver, so re-read them now that
      // the partition has changed.
      setInterfaceLang(
        await storage.readJson<LanguageCode>('interfaceLanguage', interfaceLanguage),
      );
      setPatientLang(await storage.readJson<LanguageCode>('patientLanguage', 'en'));
      setPrefsState(await storage.readJson<Preferences>('prefs', DEFAULT_PREFS));
      setPatients(await storage.readJson<PatientSnapshot[]>('patients', []));
      setSelectedId(await storage.readJson<string | null>('selectedPatient', null));
      await outbox.load();
    },
    [identity, interfaceLanguage, outbox],
  );

  const signOut = useCallback(async () => {
    await speech.stop();
    await identity.signOut();
    await storage.useScope(null);
    setSignedIn(false);
    setRole(null);
    setPreviewMode(false);
    setPatients([]);
    setSelectedId(null);
    setPatientMode(false);
    await outbox.load();
  }, [identity, outbox, speech]);

  const enterPreview = useCallback(async () => {
    // Explicit and labelled. Never a fallback from a failed real sign-in.
    setPreviewMode(true);
    setRole('caregiver');
    await storage.useScope('preview');
    setPatients(await storage.readJson<PatientSnapshot[]>('patients', []));
    setSelectedId(await storage.readJson<string | null>('selectedPatient', null));
  }, []);

  /* -------------------------------------------------------- languages - */
  const setInterfaceLanguage = useCallback(
    async (code: LanguageCode) => {
      setInterfaceLang(code);
      await storage.writeJson('interfaceLanguage', code);
      await speech.handleLanguageChanged();
    },
    [speech],
  );

  const setPatientLanguage = useCallback(
    async (code: LanguageCode) => {
      setPatientLang(code);
      await storage.writeJson('patientLanguage', code);
      await speech.handleLanguageChanged();
    },
    [speech],
  );

  const setPrefs = useCallback(
    async (next: Partial<Preferences>) => {
      const merged = { ...prefsRef.current, ...next };
      setPrefsState(merged);
      await storage.writeJson('prefs', merged);
      // Turning sound off stops speech immediately, not at the end of the
      // current sentence.
      if (next.audioEnabled === false) await speech.stop();
    },
    [speech],
  );

  /* --------------------------------------------------------- patients - */
  const upsertPatient = useCallback(async (p: PatientSnapshot) => {
    setPatients((prev) => {
      const next = prev.some((x) => x.id === p.id)
        ? prev.map((x) => (x.id === p.id ? { ...x, ...p } : x))
        : [...prev, p];
      void storage.writeJson('patients', next);
      return next;
    });
  }, []);

  const selectPatient = useCallback(async (id: string) => {
    setSelectedId(id);
    await storage.writeJson('selectedPatient', id);
  }, []);

  const refreshPatients = useCallback(async () => {
    const client = apiRef.current;
    if (!client) {
      setPatientsError(null);
      return;
    }
    try {
      const remote = await client.listPatients();
      setPatientsError(null);
      setPatients((prev) => {
        // Server data does not silently replace local edits: local fields the
        // server has no endpoint for (age, notes) are preserved.
        const merged = remote.map((r) => {
          const local = prev.find((p) => p.id === r.id);
          return {
            id: r.id,
            displayName: r.display_name,
            language: (r.language as LanguageCode) ?? local?.language ?? 'en',
            profileRevision: r.profile_revision,
            ageYears: local?.ageYears,
            notes: local?.notes,
          };
        });
        void storage.writeJson('patients', merged);
        return merged;
      });
    } catch {
      setPatientsError(
        'Could not load the patient list. Showing what is saved on this device.',
      );
    }
  }, []);

  const syncNow = useCallback(async () => {
    await outbox.flush();
    setPending(outbox.pendingCount);
  }, [outbox]);

  const selectedPatient = useMemo(
    () => patients.find((p) => p.id === selectedId) ?? null,
    [patients, selectedId],
  );

  const value = useMemo<AppStateValue>(
    () => ({
      ready,
      identity,
      role,
      signedIn,
      identityConfigured: isIdentityConfigured(),
      apiConfigured: isApiConfigured(),
      signIn,
      signOut,
      previewMode,
      enterPreview,
      interfaceLanguage,
      patientLanguage,
      setInterfaceLanguage,
      setPatientLanguage,
      prefs,
      setPrefs,
      patients,
      selectedPatient,
      selectPatient,
      upsertPatient,
      refreshPatients,
      patientsError,
      patientMode,
      enterPatientMode: () => setPatientMode(true),
      leavePatientMode: () => setPatientMode(false),
      api,
      outbox,
      speech,
      syncNow,
      pendingUploads,
    }),
    [
      ready, identity, role, signedIn, signIn, signOut, previewMode, enterPreview,
      interfaceLanguage, patientLanguage, setInterfaceLanguage, setPatientLanguage,
      prefs, setPrefs, patients, selectedPatient, selectPatient, upsertPatient,
      refreshPatients, patientsError, patientMode, api, outbox, speech, syncNow,
      pendingUploads,
    ],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useApp(): AppStateValue {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useApp must be used inside an AppStateProvider');
  return ctx;
}
