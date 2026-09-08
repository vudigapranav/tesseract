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
import { readJson, writeJson } from './storage';
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
  reminderId: string;
  /** Local date key, YYYY-MM-DD. */
  day: string;
  seenAt?: string;
  postponedToMinutes?: number;
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

export const loadReminders = () => readJson<Reminder[]>(REMINDERS_KEY, []);
export const saveReminders = (r: Reminder[]) => writeJson(REMINDERS_KEY, r);
export const loadOccurrences = () =>
  readJson<Occurrence[]>(OCCURRENCES_KEY, []);
export const saveOccurrences = (o: Occurrence[]) =>
  writeJson(OCCURRENCES_KEY, o);

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
export async function reconcileSchedule(
  reminders: Reminder[],
  patientLanguage: LanguageCode,
): Promise<NotificationCapability> {
  let capability: NotificationCapability;
  try {
    capability = await permissionStatus();
    if (capability !== 'granted') return capability;

    const scheduled = await Notifications.getAllScheduledNotificationsAsync();
    await Promise.all(
      scheduled.map((s) =>
        Notifications.cancelScheduledNotificationAsync(s.identifier),
      ),
    );

    for (const r of reminders) {
      if (!r.enabled) continue;
      await Notifications.scheduleNotificationAsync({
        identifier: r.id,
        content: {
          title: translate(patientLanguage, 'reminderNotificationTitle'),
          // The caregiver's wording, verbatim.
          body: r.title,
          sound: true,
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

/** Records that the patient has seen a reminder today. Nothing more. */
export function acknowledge(
  occurrences: Occurrence[],
  reminderId: string,
): Occurrence[] {
  const day = todayKey();
  const rest = occurrences.filter(
    (o) => !(o.reminderId === reminderId && o.day === day),
  );
  return [...rest, { reminderId, day, seenAt: new Date().toISOString() }];
}

/** Pushes today's occurrence later without changing the daily reminder. */
export function postpone(
  occurrences: Occurrence[],
  reminderId: string,
  minutes = 15,
): Occurrence[] {
  const day = todayKey();
  const existing = occurrences.find(
    (o) => o.reminderId === reminderId && o.day === day,
  );
  const rest = occurrences.filter(
    (o) => !(o.reminderId === reminderId && o.day === day),
  );
  return [
    ...rest,
    {
      reminderId,
      day,
      postponedToMinutes: (existing?.postponedToMinutes ?? 0) + minutes,
    },
  ];
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
