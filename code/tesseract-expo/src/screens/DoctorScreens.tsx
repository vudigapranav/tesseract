/**
 * Doctor screens, behind role sign-in.
 *
 * Access is the server's decision, never this app's: the patient list comes
 * from `/v1/doctor/patients`, which returns only patients actually assigned to
 * the signed-in doctor. Choosing "Doctor" at sign-in grants nothing on its own.
 *
 * Nothing here is a clinical instrument. The measures are observed app
 * activity, the disclaimer says so on every screen, and no score, diagnosis or
 * progression figure is produced.
 */
import React, { useEffect, useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';
import { colors, spacing } from '../design/tokens';
import {
  BodyLarge,
  BodyMedium,
  Card,
  HeadlineLarge,
  PillButton,
  Screen,
  SectionHeading,
  StatusNote,
  TitleLarge,
} from '../design/components';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { readJson, writeJson } from '../data/storage';
import { newId } from '../data/outbox';
import type { PatientSummary } from '../data/apiClient';

interface DoctorNote {
  id: string;
  patientId: string;
  text: string;
  authorLabel: string;
  createdAt: string;
}

const NOTES_KEY = 'doctorNotes';

export function DoctorPatientsScreen({
  onOpen,
  onBack,
}: {
  onOpen: (p: PatientSummary) => void;
  onBack: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const [patients, setPatients] = useState<PatientSummary[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void (async () => {
      if (!app.api) {
        setPatients([]);
        setError(
          'No server is configured, so no assignments can be read. Doctor access is decided on the server, not in this app.',
        );
        return;
      }
      try {
        setPatients(await app.api.doctorPatients());
      } catch {
        setPatients([]);
        setError('Could not load your assigned patients.');
      }
    })();
  }, [app.api]);

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{t('myPatients')}</HeadlineLarge>
      <BodyMedium tone="soft">{t('assignedToYou')}</BodyMedium>

      {error ? <StatusNote icon="alert" tone="attention" text={error} /> : null}

      {patients && patients.length === 0 && !error ? (
        <Card>
          <BodyLarge>{t('noPatientsAssigned')}</BodyLarge>
        </Card>
      ) : null}

      {(patients ?? []).map((p) => (
        <Card key={p.id}>
          <TitleLarge>{p.display_name}</TitleLarge>
          <PillButton
            label={t('sessionHistory')}
            variant="outline"
            onPress={() => onOpen(p)}
          />
        </Card>
      ))}

      <View style={{ height: 8 }} />
      <PillButton label={t('signOut')} variant="outline" onPress={() => void app.signOut()} />
      <PillButton label={t('goBack')} onPress={onBack} />
    </Screen>
  );
}

export function DoctorPatientDetailScreen({
  patient,
  onBack,
}: {
  patient: PatientSummary;
  onBack: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const [summary, setSummary] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notes, setNotes] = useState<DoctorNote[]>([]);
  const [draft, setDraft] = useState('');

  useEffect(() => {
    void readJson<DoctorNote[]>(NOTES_KEY, []).then((all) =>
      setNotes(all.filter((n) => n.patientId === patient.id)),
    );
  }, [patient.id]);

  useEffect(() => {
    void (async () => {
      if (!app.api) {
        setError('No server is configured, so there is nothing to show here.');
        return;
      }
      try {
        setSummary(await app.api.doctorSummary(patient.id));
      } catch {
        setError('Could not load this patient’s summary.');
      }
    })();
  }, [app.api, patient.id]);

  const addNote = async () => {
    const text = draft.trim();
    if (!text) return;
    const note: DoctorNote = {
      id: newId(),
      patientId: patient.id,
      text,
      // Notes are attributed. An unattributed clinical note is not useful and
      // is not safe.
      authorLabel: app.identity.uid ?? 'this device',
      createdAt: new Date().toISOString(),
    };
    const all = await readJson<DoctorNote[]>(NOTES_KEY, []);
    const next = [...all, note];
    await writeJson(NOTES_KEY, next);
    setNotes(next.filter((n) => n.patientId === patient.id));
    setDraft('');
  };

  const measures = summary
    ? Object.entries(summary).filter(
        ([, v]) => typeof v === 'number' || typeof v === 'string',
      )
    : [];

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{patient.display_name}</HeadlineLarge>

      <SectionHeading title={t('observedMeasures')} />
      <Card>
        {error ? <StatusNote icon="alert" tone="attention" text={error} /> : null}
        {!error && measures.length === 0 ? (
          // Never a fabricated zero: an absent measure is shown as absent.
          <BodyLarge tone="soft">{t('notMeasured')}</BodyLarge>
        ) : null}
        {measures.map(([k, v]) => (
          <View key={k} style={styles.measureRow}>
            <BodyLarge style={{ flex: 1 }}>{k.replace(/_/g, ' ')}</BodyLarge>
            <BodyLarge tone="soft">{String(v)}</BodyLarge>
          </View>
        ))}
        <StatusNote icon="info" text={t('doctorDisclaimer')} />
      </Card>

      <SectionHeading title={t('notes')} />
      <Card>
        {notes.length === 0 ? (
          <BodyMedium tone="soft">{t('noNotes')}</BodyMedium>
        ) : (
          notes.map((n) => (
            <View key={n.id} style={{ paddingVertical: 6 }}>
              <BodyLarge>{n.text}</BodyLarge>
              <BodyMedium tone="soft">
                {`${new Date(n.createdAt).toLocaleString()} · ${n.authorLabel}`}
              </BodyMedium>
            </View>
          ))
        )}
        <TextInput
          accessibilityLabel={t('addNote')}
          value={draft}
          onChangeText={setDraft}
          multiline
          placeholder={t('addNote')}
          placeholderTextColor={colors.inkSoft}
          style={styles.input}
        />
        <PillButton
          label={t('addNote')}
          variant="outline"
          disabled={!draft.trim()}
          onPress={addNote}
        />
        <StatusNote
          icon="info"
          text="Notes are stored on this device only. There is no notes endpoint in the API yet."
        />
      </Card>

      <View style={{ height: 8 }} />
      <PillButton label={t('goBack')} onPress={onBack} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  measureRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 6,
  },
  input: {
    minHeight: 90,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    borderRadius: 14,
    padding: 14,
    fontSize: 18,
    color: colors.ink,
    backgroundColor: colors.cream,
    marginTop: 10,
    textAlignVertical: 'top',
  },
});
