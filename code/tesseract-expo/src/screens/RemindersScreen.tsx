/**
 * Caregiver reminders, and the patient's own view of them.
 *
 * Independent of games entirely: these work whether or not anyone ever opens
 * an activity. Acknowledging records "I have seen this" and nothing else.
 */
import React, { useEffect, useState } from 'react';
import { StyleSheet, Switch, TextInput, View } from 'react-native';
import { colors, fontFamilyForScript, spacing } from '../design/tokens';
import {
  BigPatientAction,
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
import { SpeakButton } from '../components/SpeakButton';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { languageByCode } from '../l10n/languages';
import { newId } from '../data/outbox';
import {
  acknowledge,
  dueLaterToday,
  ensurePermission,
  formatTime,
  loadOccurrences,
  loadReminders,
  postpone,
  reconcileSchedule,
  saveOccurrences,
  saveReminders,
  seenToday,
  type NotificationCapability,
  type Occurrence,
  type Reminder,
} from '../data/reminders';

/* ------------------------------------------------------- caregiver view - */

export function RemindersScreen({ onBack }: { onBack: () => void }) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);
  const font = fontFamilyForScript(languageByCode(app.patientLanguage).script);

  const [reminders, setReminders] = useState<Reminder[]>([]);
  const [capability, setCapability] = useState<NotificationCapability>('unknown');
  const [title, setTitle] = useState('');
  const [hour, setHour] = useState('8');
  const [minute, setMinute] = useState('00');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [loaded, setLoaded] = useState(false);

  const patientId = app.selectedPatient?.id ?? 'local';

  useEffect(() => {
    void (async () => {
      setReminders(await loadReminders(app.store, patientId));
      setLoaded(true);
    })();
  }, [app.store, patientId]);

  /**
   * Persist, then converge this patient's schedule. Always in that order, and
   * always scoped — reconciliation must not touch another patient's alerts.
   */
  const commit = async (next: Reminder[]) => {
    setReminders(next);
    await saveReminders(app.store, patientId, next);
    const cap = await reconcileSchedule(next, app.patientLanguage, {
      patientId,
      soundEnabled: app.prefs.audioEnabled,
    });
    setCapability(cap);
  };

  const startEdit = (r: Reminder) => {
    setEditingId(r.id);
    setTitle(r.title);
    setHour(String(r.hour));
    setMinute(String(r.minute).padStart(2, '0'));
  };

  const clearForm = () => {
    setEditingId(null);
    setTitle('');
    setHour('8');
    setMinute('00');
  };

  const save = async () => {
    const h = Math.min(23, Math.max(0, Number(hour) || 0));
    const m = Math.min(59, Math.max(0, Number(minute) || 0));
    const text = title.trim();
    if (!text) return;

    // Permission is asked here — at the point the caregiver actually creates
    // something that needs it — not at app startup.
    const cap = await ensurePermission();
    setCapability(cap);

    const next = editingId
      ? reminders.map((r) =>
          r.id === editingId ? { ...r, title: text, hour: h, minute: m } : r,
        )
      : [
          ...reminders,
          { id: newId(), title: text, hour: h, minute: m, enabled: true },
        ];
    clearForm();
    await commit(next);
  };

  if (!loaded) return <Screen><View /></Screen>;

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{t('reminders')}</HeadlineLarge>

      {capability === 'denied' ? (
        <StatusNote
          icon="alert"
          tone="attention"
          text="Notifications are turned off, so nothing will pop up at the set time. The reminders below still show inside the app. You can turn notifications on in the phone's Settings."
        />
      ) : null}
      {capability === 'unavailable' ? (
        <StatusNote
          icon="alert"
          tone="attention"
          text="This device cannot schedule notifications. The reminders below still show inside the app."
        />
      ) : null}

      <SectionHeading title={editingId ? 'Edit reminder' : 'New reminder'} />
      <Card>
        <BodyMedium tone="soft">
          Write this in the language the person reads. It is shown exactly as
          you type it and is never translated.
        </BodyMedium>
        <TextInput
          accessibilityLabel="Reminder text"
          value={title}
          onChangeText={setTitle}
          placeholder="For example, water the plants"
          placeholderTextColor={colors.inkSoft}
          style={[styles.input, font ? { fontFamily: font } : null]}
        />
        <View style={styles.timeRow}>
          <View style={{ flex: 1 }}>
            <BodyMedium tone="soft">Hour (0–23)</BodyMedium>
            <TextInput
              accessibilityLabel="Hour"
              value={hour}
              onChangeText={setHour}
              keyboardType="number-pad"
              style={styles.input}
            />
          </View>
          <View style={{ flex: 1 }}>
            <BodyMedium tone="soft">Minute</BodyMedium>
            <TextInput
              accessibilityLabel="Minute"
              value={minute}
              onChangeText={setMinute}
              keyboardType="number-pad"
              style={styles.input}
            />
          </View>
        </View>
        <PillButton
          label={editingId ? t('save') : t('add')}
          disabled={!title.trim()}
          onPress={save}
        />
        {editingId ? (
          <PillButton label={t('cancel')} variant="outline" onPress={clearForm} />
        ) : null}
      </Card>

      <SectionHeading title={t('today')} />
      {reminders.length === 0 ? (
        <Card>
          <BodyLarge>{t('nothingToRemember')}</BodyLarge>
        </Card>
      ) : (
        reminders.map((r) => (
          <Card key={r.id}>
            <View style={styles.row}>
              <View style={{ flex: 1 }}>
                <TitleLarge fontFamily={font}>{r.title}</TitleLarge>
                <BodyMedium tone="soft">{formatTime(r.hour, r.minute)}</BodyMedium>
              </View>
              <Switch
                accessibilityLabel={`${r.title} enabled`}
                value={r.enabled}
                onValueChange={(v) =>
                  void commit(
                    reminders.map((x) =>
                      x.id === r.id ? { ...x, enabled: v } : x,
                    ),
                  )
                }
              />
            </View>
            <View style={styles.row}>
              <PillButton
                label="Edit"
                variant="outline"
                onPress={() => startEdit(r)}
                style={{ flex: 1 }}
              />
              <PillButton
                label="Delete"
                variant="outline"
                onPress={() =>
                  void commit(reminders.filter((x) => x.id !== r.id))
                }
                style={{ flex: 1 }}
              />
            </View>
          </Card>
        ))
      )}

      <View style={{ height: 8 }} />
      <PillButton label={t('goBack')} onPress={onBack} />
    </Screen>
  );
}

/* --------------------------------------------------------- patient view - */

export function PatientRemindersScreen({ onBack }: { onBack: () => void }) {
  const app = useApp();
  const patientId = app.selectedPatient?.id ?? 'local';
  const code = app.patientLanguage;
  const t = (k: Parameters<typeof translate>[1]) => translate(code, k);
  const font = fontFamilyForScript(languageByCode(code).script);

  const [reminders, setReminders] = useState<Reminder[]>([]);
  const [occurrences, setOccurrences] = useState<Occurrence[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    void (async () => {
      setReminders(
        (await loadReminders(app.store, patientId)).filter((r) => r.enabled),
      );
      setOccurrences(await loadOccurrences(app.store, patientId));
      setLoaded(true);
    })();
  }, [app.store, patientId]);

  const update = async (next: Occurrence[]) => {
    setOccurrences(next);
    await saveOccurrences(app.store, patientId, next);
  };

  if (!loaded) return <Screen><View /></Screen>;

  return (
    <Screen>
      <View style={{ height: 16 }} />
      <HeadlineLarge fontFamily={font}>{t('todaysReminders')}</HeadlineLarge>

      {reminders.length === 0 ? (
        <Card>
          <BodyLarge fontFamily={font}>{t('nothingToRemember')}</BodyLarge>
        </Card>
      ) : (
        reminders.map((r) => {
          const seen = seenToday(occurrences, r.id);
          const time = formatTime(r.hour, r.minute);
          return (
            <Card key={r.id}>
              <TitleLarge fontFamily={font}>{r.title}</TitleLarge>
              <BodyMedium tone="soft">{time}</BodyMedium>
              {dueLaterToday(occurrences, r.id) ? (
                <BodyMedium tone="soft">
                  {`${t('reminderLater')}: ${new Date(
                    dueLaterToday(occurrences, r.id) as string,
                  ).toLocaleTimeString()}`}
                </BodyMedium>
              ) : null}
              {/* Reads the caregiver's own words back, in the patient's
                  language setting. It does not translate them. */}
              <SpeakButton text={`${r.title}. ${time}`} languageCode={code} />
              <View style={{ height: 12 }} />
              {seen ? (
                // Says exactly what was recorded, and no more.
                <BodyLarge tone="soft" fontFamily={font}>
                  {t('reminderSeen')}
                </BodyLarge>
              ) : (
                <>
                  <BigPatientAction
                    label={t('reminderSeenIt')}
                    fontFamily={font}
                    onPress={() =>
                      void acknowledge(occurrences, r.id).then(update)
                    }
                  />
                  <BigPatientAction
                    label={t('reminderLater')}
                    primary={false}
                    fontFamily={font}
                    onPress={() =>
                      // Actually schedules a one-off notification rather than
                      // incrementing a counter that nothing ever reads.
                      void postpone(
                        occurrences,
                        r,
                        code,
                        15,
                        app.prefs.audioEnabled,
                      ).then((res) => update(res.occurrences))
                    }
                  />
                </>
              )}
            </Card>
          );
        })
      )}

      <View style={{ height: 8 }} />
      <PillButton label={t('goBack')} variant="outline" onPress={onBack} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 12, marginTop: 8 },
  timeRow: { flexDirection: 'row', gap: 12, marginTop: 8 },
  input: {
    minHeight: spacing.minTarget,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    borderRadius: 14,
    paddingHorizontal: 14,
    fontSize: 18,
    color: colors.ink,
    backgroundColor: colors.cream,
    marginTop: 6,
  },
});
