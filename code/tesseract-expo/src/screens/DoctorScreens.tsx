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
import type { NoteOut, PatientOut, ReportOut } from '../data/apiClient';

// Notes and reports are server-backed. The previous UI claimed there was no
// notes endpoint; POST/GET /v1/patients/{id}/notes and the reports routes
// exist, and are used here with the server's assignment checks in force.

export function DoctorPatientsScreen({
  onOpen,
  onBack,
}: {
  onOpen: (p: PatientOut) => void;
  onBack: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const [patients, setPatients] = useState<PatientOut[] | null>(null);
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
        <Card key={p.patient_id}>
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
  patient: PatientOut;
  onBack: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const [summary, setSummary] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notes, setNotes] = useState<NoteOut[] | null>(null);
  const [notesError, setNotesError] = useState<string | null>(null);
  const [draft, setDraft] = useState('');
  const [savingNote, setSavingNote] = useState(false);
  const [report, setReport] = useState<ReportOut | null>(null);
  const [reportError, setReportError] = useState<string | null>(null);
  const [generating, setGenerating] = useState(false);

  useEffect(() => {
    void (async () => {
      if (!app.api) {
        setNotes([]);
        return;
      }
      try {
        setNotes(await app.api.listNotes(patient.patient_id));
        setNotesError(null);
      } catch {
        setNotes([]);
        setNotesError('Could not load notes.');
      }
    })();
  }, [app.api, patient.patient_id]);

  useEffect(() => {
    void (async () => {
      if (!app.api) {
        setError('No server is configured, so there is nothing to show here.');
        return;
      }
      try {
        setSummary(await app.api.doctorSummary(patient.patient_id));
        setError(null);
      } catch {
        setError('Could not load this patient\u2019s summary.');
      }
    })();
  }, [app.api, patient.patient_id]);

  const addNote = async () => {
    const text = draft.trim();
    if (!text || !app.api) return;
    setSavingNote(true);
    setNotesError(null);
    try {
      // Authorship comes from the authenticated identity on the server, never
      // from anything this client asserts.
      const created = await app.api.addNote(patient.patient_id, text);
      setNotes((prev) => [...(prev ?? []), created]);
      setDraft('');
    } catch {
      // The draft is kept: losing a written clinical note to a network blip
      // is not acceptable.
      setNotesError('Could not save that note. Your text is still here.');
    } finally {
      setSavingNote(false);
    }
  };

  const generateReport = async () => {
    if (!app.api) return;
    setGenerating(true);
    setReportError(null);
    try {
      setReport(await app.api.createReport(patient.patient_id, 30));
    } catch {
      setReportError('Could not generate a report.');
    } finally {
      setGenerating(false);
    }
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

      <SectionHeading title={t('draftReport')} />
      <Card>
        {report ? (
          <>
            <BodyMedium tone="soft">
              {`${report.generator} ${report.generator_version} \u00b7 ${report.window_days} days \u00b7 ${report.source_session_ids.length} sessions`}
            </BodyMedium>
            {Object.entries(report.content).map(([k, v]) => (
              <View key={k} style={{ paddingVertical: 4 }}>
                <BodyLarge>{k.replace(/_/g, ' ')}</BodyLarge>
                <BodyMedium tone="soft">
                  {typeof v === 'object' ? JSON.stringify(v) : String(v)}
                </BodyMedium>
              </View>
            ))}
          </>
        ) : (
          <BodyMedium tone="soft">{t('noActivityYet')}</BodyMedium>
        )}
        {reportError ? (
          <StatusNote icon="alert" tone="attention" text={reportError} />
        ) : null}
        <PillButton
          label={t('generate')}
          variant="outline"
          busy={generating}
          disabled={!app.api}
          onPress={generateReport}
        />
        <StatusNote icon="info" text={t('doctorDisclaimer')} />
      </Card>

      <SectionHeading title={t('notes')} />
      <Card>
        {notes === null ? (
          <BodyMedium tone="soft">{t('signingIn')}</BodyMedium>
        ) : notes.length === 0 ? (
          <BodyMedium tone="soft">{t('noNotes')}</BodyMedium>
        ) : (
          notes.map((n) => (
            <View key={n.note_id} style={{ paddingVertical: 6 }}>
              <BodyLarge>{n.body}</BodyLarge>
              {/* Attributed to the author the server recorded. */}
              <BodyMedium tone="soft">
                {`${new Date(n.created_at).toLocaleString()} \u00b7 ${n.author_user_id}`}
              </BodyMedium>
            </View>
          ))
        )}
        {notesError ? (
          <StatusNote icon="alert" tone="attention" text={notesError} />
        ) : null}
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
          busy={savingNote}
          disabled={!draft.trim() || !app.api}
          onPress={addNote}
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
