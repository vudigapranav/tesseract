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
import { ApiClient, type PatientOut } from '../data/apiClient';
import { isApiConfigured, isIdentityConfigured } from '../data/config';
import { IdentityService } from '../data/identity';
import { SessionOutbox } from '../data/outbox';
import {
  ANON_SCOPE,
  ScopedStore,
  patientKey,
  recallActiveScope,
  rememberActiveScope,
  storeFor,
} from '../data/storage';
import { SpeechOutputService } from '../speech/tts';
import type { LanguageCode } from '../l10n/languages';

export type Role = 'caregiver' | 'doctor';

export interface PatientSnapshot {
  /** The server's `patient_id`. */
  id: string;
  displayName: string;
  language: LanguageCode;
  /** The server's `version`, for conflict-aware writes. */
  version?: number;
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
  startupError: string | null;

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
  /** The store bound to the signed-in identity. */
  store: ScopedStore;
  outbox: SessionOutbox;
  speech: SpeechOutputService;
  syncNow: () => Promise<void>;
  pendingUploads: number;
}

const Ctx = createContext<AppStateValue | null>(null);

export function AppStateProvider({ children }: { children: React.ReactNode }) {
  const identity = useRef(new IdentityService()).current;
  const [ready, setReady] = useState(false);
  const [startupError, setStartupError] = useState<string | null>(null);
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

  /**
   * The store for whoever is signed in. Captured in state rather than read
   * from a global, so an async operation that started under one identity
   * cannot land in another's partition.
   */
  const [store, setStore] = useState<ScopedStore>(() => storeFor(null));
  const storeRef = useRef(store);
  storeRef.current = store;

  const prefsRef = useRef(prefs);
  prefsRef.current = prefs;

  const speech = useRef(
    new SpeechOutputService(() => prefsRef.current.audioEnabled),
  ).current;

  const api = useMemo(
    () =>
      isApiConfigured() && signedIn
        ? new ApiClient(async () => {
            const expected = store.scope;
            if (identity.uid !== expected) throw new Error('Identity changed.');
            const token = await identity.token();
            if (identity.uid !== expected) throw new Error('Identity changed.');
            return token;
          })
        : null,
    [signedIn, identity, store.scope],
  );
  const apiRef = useRef(api);
  apiRef.current = api;

  /** Rebuilt whenever the scope changes, so it can never span two accounts. */
  const [outbox, setOutbox] = useState<SessionOutbox>(
    () => new SessionOutbox(storeFor(null), () => apiRef.current),
  );

  /** Aborts any sync in flight when the account changes. */
  const syncAbort = useRef<AbortController | null>(null);

  const cancelSync = useCallback(() => {
    syncAbort.current?.abort();
    syncAbort.current = null;
  }, []);

  /**
   * Points every scoped service at one identity, atomically.
   *
   * Any sync already running belongs to the previous identity and is
   * abandoned first — letting it finish would write one account's sessions
   * while another is signed in.
   */
  const adoptScope = useCallback(
    async (uid: string | null) => {
      cancelSync();
      const next = storeFor(uid);
      const nextOutbox = new SessionOutbox(next, () => identity.uid === next.scope ? apiRef.current : null);
      await nextOutbox.load();
      setStore(next);
      storeRef.current = next;
      setOutbox(nextOutbox);
      await rememberActiveScope(next.scope);
      return next;
    },
    [cancelSync],
  );

  /** Reads every per-identity document from one explicit store. */
  const loadFrom = useCallback(async (s: ScopedStore) => {
    setInterfaceLang(
      (await s.tryRead<LanguageCode>('interfaceLanguage', 'en')).value,
    );
    setPatientLang((await s.tryRead<LanguageCode>('patientLanguage', 'en')).value);
    setPrefsState((await s.tryRead<Preferences>('prefs', DEFAULT_PREFS)).value);
    setPatients((await s.tryRead<PatientSnapshot[]>('patients', [])).value);
    setSelectedId(
      (await s.tryRead<string | null>('selectedPatient', null)).value,
    );
    // Patient mode is durable: a device handed to someone must not reopen in
    // caregiver mode after a restart or a battery death.
    setPatientMode(await s.read<boolean>('patientMode', false));
  }, []);

  /** Drops everything identity-specific from memory. */
  const clearInMemory = useCallback(() => {
    setPatients([]);
    setSelectedId(null);
    setPatientMode(false);
    setPrefsState(DEFAULT_PREFS);
    setPatientLang('en');
    setPatientsError(null);
  }, []);

  /* ------------------------------------------------------------- boot - */
  useEffect(() => {
    (async () => {
      try {
      const restored = await identity.restore();
      if (restored && identity.uid) {
        const s = await adoptScope(identity.uid);
        setSignedIn(true);
        setRole((await s.tryRead<Role>('role', 'caregiver')).value);
        await loadFrom(s);
      } else {
        // Restoration failed. Do not leave the previous account's data
        // sitting in memory behind a signed-out shell.
        clearInMemory();
        const s = await adoptScope(null);
        setSignedIn(false);
        setInterfaceLang(
          (await s.tryRead<LanguageCode>('interfaceLanguage', 'en')).value,
        );
      }
      } catch {
        setStartupError("Saved data could not be opened. It has been preserved. Close and reopen Apnapan to retry.");
      }
      setReady(true);
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(
    () => outbox.subscribe(() => setPending(outbox.pendingCount)),
    [outbox],
  );

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
      const s = await adoptScope(identity.uid);
      await s.write('role', nextRole);
      setRole(nextRole);
      setSignedIn(true);
      setPreviewMode(false);
      await loadFrom(s);
    },
    [identity, adoptScope, loadFrom],
  );

  const signOut = useCallback(async () => {
    cancelSync();
    await speech.stop();
    await identity.signOut();
    clearInMemory();
    await adoptScope(null);
    setSignedIn(false);
    setRole(null);
    setPreviewMode(false);
  }, [identity, adoptScope, speech, cancelSync, clearInMemory]);

  const enterPreview = useCallback(async () => {
    // Explicit and labelled, never a fallback from a failed sign-in. Preview
    // gets its own scope and its own outbox, so it cannot mix with a real
    // caregiver's queued sessions.
    cancelSync();
    clearInMemory();
    const s = await adoptScope('preview');
    setPreviewMode(true);
    setRole('caregiver');
    await loadFrom(s);
  }, [adoptScope, cancelSync, clearInMemory, loadFrom]);

  /* -------------------------------------------------------- languages - */
  const setInterfaceLanguage = useCallback(
    async (code: LanguageCode) => {
      setInterfaceLang(code);
      await storeRef.current.write('interfaceLanguage', code);
      await speech.handleLanguageChanged();
    },
    [speech],
  );

  const setPatientLanguage = useCallback(
    async (code: LanguageCode) => {
      setPatientLang(code);
      await storeRef.current.write('patientLanguage', code);
      await speech.handleLanguageChanged();
    },
    [speech],
  );

  const setPrefs = useCallback(
    async (next: Partial<Preferences>) => {
      const merged = { ...prefsRef.current, ...next };
      setPrefsState(merged);
      await storeRef.current.write('prefs', merged);
      if (next.audioEnabled === false) await speech.stop();
    },
    [speech],
  );

  /* --------------------------------------------------------- patients - */
  const upsertPatient = useCallback(async (p: PatientSnapshot) => {
    const s = storeRef.current;
    const prev = await s.read<PatientSnapshot[]>('patients', []);
    const next = prev.some((x) => x.id === p.id)
      ? prev.map((x) => x.id === p.id ? { ...x, ...p } : x) : [...prev, p];
    await s.write('patients', next);
    if (storeRef.current === s) setPatients(next);
  }, []);

  const selectPatient = useCallback(async (id: string) => {
    const s = storeRef.current;
    const savedPatients = await s.read<PatientSnapshot[]>('patients', []);
    const patient = savedPatients.find((p) => p.id === id);
    if (!patient) throw new Error('Patient is unavailable.');
    await s.write('selectedPatient', id);
    await s.write('patientLanguage', patient.language);
    if (storeRef.current !== s) return;
    setPatientLang(patient.language);
    setSelectedId(id);
  }, []);

  const refreshPatients = useCallback(async () => {
    const client = apiRef.current;
    if (!client) {
      setPatientsError(null);
      return;
    }
    const s = storeRef.current;
    try {
      const remote = await client.listPatients();
      if (storeRef.current !== s) return;
      setPatientsError(null);
      setPatients((prev) => {
        // Local fields the server has no endpoint for are preserved rather
        // than wiped by a refresh.
        const merged = remote.map((r: PatientOut) => {
          const local = prev.find((p) => p.id === r.patient_id);
          return {
            id: r.patient_id,
            displayName: r.display_name,
            language: (r.language as LanguageCode) ?? local?.language ?? 'en',
            version: r.version,
            ageYears: local?.ageYears,
            notes: local?.notes,
          };
        });
        void s.write('patients', merged);
        return merged;
      });
    } catch {
      if (storeRef.current !== s) return;
      setPatientsError(
        'Could not load the patient list. Showing what is saved on this device.',
      );
    }
  }, []);

  const syncNow = useCallback(async () => {
    cancelSync();
    const controller = new AbortController();
    syncAbort.current = controller;
    await outbox.flush(controller.signal);
    setPending(outbox.pendingCount);
  }, [outbox, cancelSync]);

  const enterPatientMode = useCallback(() => {
    setPatientMode(true);
    void storeRef.current.write('patientMode', true);
  }, []);

  const leavePatientMode = useCallback(() => {
    setPatientMode(false);
    void storeRef.current.write('patientMode', false);
  }, []);

  const selectedPatient = useMemo(
    () => patients.find((p) => p.id === selectedId) ?? null,
    [patients, selectedId],
  );

  const value = useMemo<AppStateValue>(
    () => ({
      ready,
      startupError,
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
      enterPatientMode,
      leavePatientMode,
      api,
      store,
      outbox,
      speech,
      syncNow,
      pendingUploads,
    }),
    [
      ready, startupError, identity, role, signedIn, signIn, signOut, previewMode, enterPreview,
      interfaceLanguage, patientLanguage, setInterfaceLanguage, setPatientLanguage,
      prefs, setPrefs, patients, selectedPatient, selectPatient, upsertPatient,
      refreshPatients, patientsError, patientMode, enterPatientMode,
      leavePatientMode, api, store, outbox, speech, syncNow, pendingUploads,
    ],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

/** Key for a document that belongs to one patient inside this scope. */
export const forPatient = patientKey;

export function useApp(): AppStateValue {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useApp must be used inside an AppStateProvider');
  return ctx;
}
