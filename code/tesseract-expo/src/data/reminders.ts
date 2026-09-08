/**
 * Reminders, independent of games.
 *
 * A reminder is a definition (what, when, on or off) plus per-day occurrence
 * state (seen, postponed). The two are stored separately so acknowledging
 * today never edits the reminder itself.
 *
 * **Acknowledgement is not medication adherence.** "I have seen this" is the
 * only claim the data supports, and the wording everywhere says exactly that.
 * Nothing here reports an outcome to a clinician.
 *
 * Notification scheduling is local-only. `expo-notifications` supports local
 * notifications in Expo Go; **remote push does not work in Expo Go** and is not
 * used. Scheduling is reconciled against the OS after every change and on
 * startup, so a restart cannot leave a stale or duplicated schedule.
 */
import * as Notifications from 'expo-notifications';
import { patientKey, type ScopedStore } from './storage';
import { translate } from '../l10n/i18n';
import type { LanguageCode } from '../l10n/languages';

export interface Reminder {
  id: string;
  /** The caregiver's own wording. Never rewritten or translated. */
  title: string;
  hour: number;
  minute: number;
  enabled: boolean;
}

export interface Occurrence {
  /** Stable id, so a postponed notification can be cancelled precisely. */
  occurrenceId: string;
  reminderId: string;
  /** Local date key, YYYY-MM-DD. */
  day: string;
  seenAt?: string;
  /**
   * When this occurrence is actually next due, as an ISO timestamp.
   *
   * The previous version stored only an accumulating minute counter and
   * scheduled nothing, so "remind me later" silently did nothing at all.
   */
  scheduledFor?: string;
  /** Identifier of the one-off notification, when one is scheduled. */
  notificationId?: string;
}

export type NotificationCapability =
  | 'unknown'
  | 'granted'
  | 'denied'
  | 'unavailable';

const REMINDERS_KEY = 'reminders';
const OCCURRENCES_KEY = 'reminderOccurrences';

export const todayKey = (d = new Date()): string =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(
    d.getDate(),
  ).padStart(2, '0')}`;

/**
 * Reminders belong to a patient, not to a device. Two patients on one
 * caregiver's phone must not see each other's.
 */
export const loadReminders = (store: ScopedStore, patientId: string) =>
  store
    .tryRead<Reminder[]>(patientKey(patientId, REMINDERS_KEY), [])
    .then((r) => r.value);

export const saveReminders = (
  store: ScopedStore,
  patientId: string,
  r: Reminder[],
) => store.write(patientKey(patientId, REMINDERS_KEY), r);

export const loadOccurrences = (store: ScopedStore, patientId: string) =>
  store
    .tryRead<Occurrence[]>(patientKey(patientId, OCCURRENCES_KEY), [])
    .then((r) => r.value);

export const saveOccurrences = (
  store: ScopedStore,
  patientId: string,
  o: Occurrence[],
) => store.write(patientKey(patientId, OCCURRENCES_KEY), o);

export function formatTime(hour: number, minute: number): string {
  const h = hour % 12 === 0 ? 12 : hour % 12;
  const suffix = hour < 12 ? 'AM' : 'PM';
  return `${h}:${String(minute).padStart(2, '0')} ${suffix}`;
}

/** Asks for notification permission at the point of use, never at startup. */
export async function ensurePermission(): Promise<NotificationCapability> {
  try {
    const current = await Notifications.getPermissionsAsync();
    if (current.status === 'granted') return 'granted';
    const asked = await Notifications.requestPermissionsAsync();
    return asked.status === 'granted' ? 'granted' : 'denied';
  } catch {
    // No notification support at all in this runtime.
    return 'unavailable';
  }
}

export async function permissionStatus(): Promise<NotificationCapability> {
  try {
    const current = await Notifications.getPermissionsAsync();
    return current.status === 'granted' ? 'granted' : 'denied';
  } catch {
    return 'unavailable';
  }
}

/**
 * Rebuilds the OS schedule from the reminder list.
 *
 * Cancels everything first, then re-adds only enabled reminders. That is what
 * makes this safe to call after any change and on every startup: it converges,
 * so a crash mid-edit or a reboot cannot leave duplicates or orphans behind.
 *
 * Notification text is drawn in the **patient's** language, while the body
 * keeps the caregiver's exact wording — a personal reminder is never silently
 * rewritten or machine-translated.
 */
/**
 * Brings the OS schedule in line with the desired state for **this patient**.
 *
 * Deliberately not cancel-everything-then-rebuild. That erased unrelated
 * occurrences — another patient's reminders, and any one-off postponement in
 * flight — and left the device with no schedule at all if it failed halfway.
 *
 * Instead: compute what should exist, cancel only this patient's reminders
 * that should not, and add only those that are missing. Converging like this
 * is safe to run on every change, on startup, and after a time-zone shift.
 */
export async function reconcileSchedule(
  reminders: Reminder[],
  patientLanguage: LanguageCode,
  options: { patientId: string; soundEnabled?: boolean },
): Promise<NotificationCapability> {
  const { patientId, soundEnabled = true } = options;
  try {
    const capability = await permissionStatus();
    if (capability !== 'granted') return capability;

    // Namespaced, so this patient's schedule is addressable on its own.
    const idFor = (r: Reminder) => `apnapan:${patientId}:${r.id}`;
    const desired = new Map(
      reminders.filter((r) => r.enabled).map((r) => [idFor(r), r]),
    );

    const scheduled = await Notifications.getAllScheduledNotificationsAsync();
    const mine = scheduled.filter((s) =>
      s.identifier.startsWith(`apnapan:${patientId}:`),
    );

    // Remove only what belongs to this patient and is no longer wanted.
    for (const s of mine) {
      if (!desired.has(s.identifier)) {
        await cancelNotification(s.identifier);
      }
    }

    const present = new Set(mine.map((s) => s.identifier));
    for (const [identifier, r] of desired) {
      // Rewrite rather than skip, so an edited time or title takes effect.
      if (present.has(identifier)) await cancelNotification(identifier);
      await Notifications.scheduleNotificationAsync({
        identifier,
        content: {
          title: translate(patientLanguage, 'reminderNotificationTitle'),
          body: r.title,
          // Honours the caregiver's audio preference.
          sound: soundEnabled,
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DAILY,
          hour: r.hour,
          minute: r.minute,
        },
      });
    }
    return 'granted';
  } catch {
    return 'unavailable';
  }
}

export async function cancelAll(): Promise<void> {
  try {
    await Notifications.cancelAllScheduledNotificationsAsync();
  } catch {
    // Nothing scheduled, or no notification support. Either way there is
    // nothing to clean up and nothing worth surfacing.
  }
}

const newOccurrenceId = () =>
  `occ-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;

/**
 * Records that the patient has seen a reminder today, and cancels any
 * postponed notification still pending for it — otherwise an acknowledged
 * reminder would still buzz later.
 */
export async function acknowledge(
  occurrences: Occurrence[],
  reminderId: string,
): Promise<Occurrence[]> {
  const day = todayKey();
  const existing = occurrences.find(
    (o) => o.reminderId === reminderId && o.day === day,
  );
  if (existing?.notificationId) {
    await cancelNotification(existing.notificationId);
  }
  const rest = occurrences.filter(
    (o) => !(o.reminderId === reminderId && o.day === day),
  );
  return [
    ...rest,
    {
      occurrenceId: existing?.occurrenceId ?? newOccurrenceId(),
      reminderId,
      day,
      seenAt: new Date().toISOString(),
    },
  ];
}

/**
 * Pushes today's occurrence later and **actually schedules** a one-off
 * notification for the new time, without touching the daily reminder.
 *
 * Any previously postponed notification for the same occurrence is cancelled
 * first, so repeated postponing does not stack up several alerts.
 */
export async function postpone(
  occurrences: Occurrence[],
  reminder: Reminder,
  patientLanguage: LanguageCode,
  minutes = 15,
  soundEnabled = true,
): Promise<{ occurrences: Occurrence[]; scheduled: boolean }> {
  const day = todayKey();
  const existing = occurrences.find(
    (o) => o.reminderId === reminder.id && o.day === day,
  );
  if (existing?.notificationId) {
    await cancelNotification(existing.notificationId);
  }

  const dueAt = new Date(Date.now() + minutes * 60_000);
  let notificationId: string | undefined;
  try {
    if ((await permissionStatus()) === 'granted') {
      notificationId = await Notifications.scheduleNotificationAsync({
        content: {
          title: translate(patientLanguage, 'reminderNotificationTitle'),
          // The caregiver's own wording, verbatim.
          body: reminder.title,
          sound: soundEnabled,
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: dueAt,
        },
      });
    }
  } catch {
    // Scheduling failed; the occurrence still records the new time so the
    // in-app list is correct even when the OS alert is not available.
    notificationId = undefined;
  }

  const rest = occurrences.filter(
    (o) => !(o.reminderId === reminder.id && o.day === day),
  );
  return {
    occurrences: [
      ...rest,
      {
        occurrenceId: existing?.occurrenceId ?? newOccurrenceId(),
        reminderId: reminder.id,
        day,
        scheduledFor: dueAt.toISOString(),
        notificationId,
      },
    ],
    scheduled: notificationId !== undefined,
  };
}

async function cancelNotification(id: string): Promise<void> {
  try {
    await Notifications.cancelScheduledNotificationAsync(id);
  } catch {
    // Already fired or already gone. Nothing to undo.
  }
}

export function dueLaterToday(
  occurrences: Occurrence[],
  reminderId: string,
): string | undefined {
  const day = todayKey();
  return occurrences.find(
    (o) => o.reminderId === reminderId && o.day === day && !o.seenAt,
  )?.scheduledFor;
}

export function seenToday(
  occurrences: Occurrence[],
  reminderId: string,
): boolean {
  const day = todayKey();
  return occurrences.some(
    (o) => o.reminderId === reminderId && o.day === day && !!o.seenAt,
  );
}
