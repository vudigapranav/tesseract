/**
 * Caregiver screens: the dashboard, patient selection and basics, and the
 * protected hand-over into patient mode.
 *
 * Denser than the patient side by design — a caregiver is doing setup and
 * review, not an activity. Still no decorative analytics, no invented metrics,
 * and nothing that reads as a clinical judgement.
 */
import React, { useEffect, useState } from 'react';
import { TextInput, StyleSheet, View } from 'react-native';
import { colors, fontFamilyForScript, spacing } from '../design/tokens';
import {
  Badge,
  BodyLarge,
  BodyMedium,
  Card,
  CoralAccent,
  Divider,
  HeadlineLarge,
  PillButton,
  Screen,
  SectionHeading,
  StatusNote,
  TitleLarge,
} from '../design/components';
import { useApp, type PatientSnapshot } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { languageByCode, type LanguageCode } from '../l10n/languages';
import { newId } from '../data/outbox';

/* ---------------------------------------------------------- dashboard - */

export function CaregiverHomeScreen({
  onHandOver,
  onBasics,
  onSettings,
  onKnowMe,
  onReminders,
  onRecommendations,
}: {
  onHandOver: () => void;
  onBasics: () => void;
  onSettings: () => void;
  onKnowMe: () => void;
  onReminders: () => void;
  onRecommendations: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);
  const font = fontFamilyForScript(
    languageByCode(app.interfaceLanguage).script,
  );

  useEffect(() => {
    void app.refreshPatients();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const patient = app.selectedPatient;

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <CoralAccent />
      <HeadlineLarge fontFamily={font}>{t('caregiverGreeting')}</HeadlineLarge>

      {app.previewMode ? (
        <StatusNote icon="flag" tone="attention" text={t('previewDataWarning')} />
      ) : null}
      {app.patientsError ? (
        <StatusNote icon="alert" tone="attention" text={app.patientsError} />
      ) : null}
      {!app.apiConfigured ? (
        // Says plainly that nothing is syncing, rather than showing a
        // reassuring but false "synced".
        <StatusNote icon="sync" text={t('savedOnDevice')} />
      ) : null}

      <SectionHeading title={t('myPatients')} />
      {app.patients.length === 0 ? (
        <Card>
          <BodyLarge fontFamily={font}>{t('noPatientYet')}</BodyLarge>
          <PillButton label={t('setUp')} onPress={onBasics} />
        </Card>
      ) : (
        app.patients.map((p) => {
          const selected = p.id === patient?.id;
          return (
            <Card key={p.id}>
              <View style={styles.rowBetween}>
                <View style={{ flex: 1 }}>
                  <TitleLarge>{p.displayName}</TitleLarge>
                  <BodyMedium tone="soft">
                    {languageByCode(p.language).endonym}
                  </BodyMedium>
                </View>
                {selected ? <Badge label="Selected" /> : null}
              </View>
              {!selected ? (
                <PillButton
                  label={t('useLevel')}
                  variant="outline"
                  onPress={() => void app.selectPatient(p.id)}
                />
              ) : null}
            </Card>
          );
        })
      )}

      <SectionHeading title={t('setUp')} />
      <Card>
        <PillButton label={t('patientBasics')} variant="outline" onPress={onBasics} />
        <PillButton label={t('knowMe')} variant="outline" onPress={onKnowMe} />
        <PillButton label={t('reminders')} variant="outline" onPress={onReminders} />
        <PillButton
          label={t('needsYourDecision')}
          variant="outline"
          onPress={onRecommendations}
        />
        <PillButton label={t('settingsAndSync')} variant="outline" onPress={onSettings} />
      </Card>

      <SectionHeading title={t('recentActivity')} />
      <Card>
        {app.outbox.sessions.length === 0 ? (
          <BodyMedium tone="soft">{t('noActivityYet')}</BodyMedium>
        ) : (
          app.outbox.sessions
            .slice(-6)
            .reverse()
            .map((s) => (
              <View key={s.clientSessionId} style={styles.historyRow}>
                <View style={{ flex: 1 }}>
                  <BodyLarge>{s.gameId}</BodyLarge>
                  <BodyMedium tone="soft">
                    {new Date(s.startedAt).toLocaleString()}
                  </BodyMedium>
                </View>
                {/* Truthful sync state, never an optimistic "synced". */}
                <Badge
                  label={
                    s.status === 'synced'
                      ? 'Synced'
                      : s.status === 'blocked'
                        ? 'Not accepted'
                        : s.status === 'paused'
                          ? 'Sign in again'
                          : 'On this device'
                  }
                />
              </View>
            ))
        )}
        {/* No score, no trend line, no invented measure. */}
        <StatusNote icon="info" text={t('doctorDisclaimer')} />
      </Card>

      <View style={{ height: 8 }} />
      <PillButton label={t('handOver')} onPress={onHandOver} />
    </Screen>
  );
}

/* ------------------------------------------------------- patient basics - */

export function PatientBasicsScreen({ onDone }: { onDone: () => void }) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const existing = app.selectedPatient;
  const [name, setName] = useState(existing?.displayName ?? '');
  const [age, setAge] = useState(
    existing?.ageYears ? String(existing.ageYears) : '',
  );
  const [language, setLanguage] = useState<LanguageCode>(
    existing?.language ?? app.patientLanguage,
  );
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async () => {
    setBusy(true);
    setError(null);
    try {
      let id = existing?.id;
      if (!id && app.api) {
        const created = await app.api.createPatient({
          display_name: name.trim(),
          language,
        });
        id = created.id;
      }
      const snapshot: PatientSnapshot = {
        id: id ?? `local-${newId()}`,
        displayName: name.trim(),
        language,
        ageYears: age ? Number(age) : undefined,
        profileRevision: existing?.profileRevision,
      };
      await app.upsertPatient(snapshot);
      await app.selectPatient(snapshot.id);
      await app.setPatientLanguage(language);
      onDone();
    } catch {
      // Never clears the form on failure — retyping a name because the
      // network blipped is exactly the wrong experience.
      setError(t('couldNotSave'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{t('patientBasics')}</HeadlineLarge>
      <BodyMedium tone="soft">{t('patientBasicsSubtitle')}</BodyMedium>

      <Card>
        <BodyMedium>{t('patientBasics')}</BodyMedium>
        <TextInput
          accessibilityLabel={t('patientBasics')}
          value={name}
          onChangeText={setName}
          style={styles.input}
        />
        <View style={{ height: 12 }} />
        <BodyMedium>Age</BodyMedium>
        <TextInput
          accessibilityLabel="Age"
          value={age}
          onChangeText={setAge}
          keyboardType="number-pad"
          style={styles.input}
        />
        {/* Honest about what the backend can and cannot store today. */}
        <StatusNote
          icon="info"
          text="Age and notes are kept on this device only. The API has no endpoint to update patient basics yet."
        />

        <Divider />

        <BodyMedium>{t('patientLanguage')}</BodyMedium>
        <BodyMedium tone="soft">{t('patientLanguageHelp')}</BodyMedium>
        <View style={{ height: 8 }} />
        {(['en', 'as', 'bn', 'mni', 'kha', 'lus'] as LanguageCode[]).map((c) => (
          <PillButton
            key={c}
            label={languageByCode(c).endonym}
            variant={language === c ? 'primary' : 'outline'}
            onPress={() => setLanguage(c)}
          />
        ))}

        {error ? <StatusNote icon="alert" tone="attention" text={error} /> : null}
        <PillButton
          label={t('save')}
          busy={busy}
          disabled={name.trim().length === 0}
          onPress={save}
        />
        <PillButton label={t('cancel')} variant="outline" onPress={onDone} />
      </Card>
    </Screen>
  );
}

/* ----------------------------------------------------------- hand over - */

export function HandOverScreen({
  onConfirm,
  onCancel,
}: {
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  return (
    <Screen>
      <View style={{ height: 40 }} />
      <CoralAccent />
      <HeadlineLarge>{t('handOver')}</HeadlineLarge>
      <View style={{ height: 12 }} />
      <BodyLarge tone="soft">{t('signInPatientNote')}</BodyLarge>
      <View style={{ height: 28 }} />
      <PillButton label={t('handOver')} onPress={onConfirm} />
      <PillButton label={t('cancel')} variant="outline" onPress={onCancel} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  rowBetween: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  historyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 10,
  },
  input: {
    minHeight: spacing.minTarget,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    borderRadius: 14,
    paddingHorizontal: 14,
    fontSize: 18,
    color: colors.ink,
    backgroundColor: colors.cream,
  },
});
