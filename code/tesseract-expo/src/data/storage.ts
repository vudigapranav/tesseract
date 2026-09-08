/**
 * Durable local storage, partitioned by caregiver identity.
 *
 * The partitioning is the point: a shared device must never show one
 * caregiver another's patient content. Every key is namespaced by the signed-in
 * identity's stable uid, and reading without an identity returns the anonymous
 * scope, which holds nothing but device preferences.
 *
 * AsyncStorage rather than SQLite: it is bundled in Expo Go, and what this app
 * stores is a handful of JSON documents, not a relational workload. The Flutter
 * build uses SQLite because it also runs a session outbox at volume; the outbox
 * here keeps the same ordering guarantees over a JSON array.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';

const ANON = 'anon';
const PREFIX = 'tesseract';

/** Keys that belong to the device, not to any one caregiver. */
const DEVICE_KEYS = ['interfaceLanguage', 'activeScope'] as const;
type DeviceKey = (typeof DEVICE_KEYS)[number];

let scope = ANON;

export function currentScope(): string {
  return scope;
}

/** Points storage at a caregiver's partition. */
export async function useScope(uid: string | null): Promise<void> {
  scope = uid && uid.trim().length > 0 ? uid.trim() : ANON;
  await AsyncStorage.setItem(`${PREFIX}:activeScope`, scope);
}

/** Restores the partition that was in use before the app was closed. */
export async function restoreScope(): Promise<string> {
  const saved = await AsyncStorage.getItem(`${PREFIX}:activeScope`);
  scope = saved ?? ANON;
  return scope;
}

const scopedKey = (key: string) =>
  (DEVICE_KEYS as readonly string[]).includes(key)
    ? `${PREFIX}:${key}`
    : `${PREFIX}:${scope}:${key}`;

export async function readJson<T>(key: string, fallback: T): Promise<T> {
  try {
    const raw = await AsyncStorage.getItem(scopedKey(key));
    if (raw == null) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    // A corrupt document must not take the app down. The caller gets its
    // default and the user sees an empty section rather than a crash.
    return fallback;
  }
}

export async function writeJson(key: string, value: unknown): Promise<void> {
  await AsyncStorage.setItem(scopedKey(key), JSON.stringify(value));
}

export async function removeKey(key: string): Promise<void> {
  await AsyncStorage.removeItem(scopedKey(key));
}

/** Everything stored for the current scope, for a sign-out that really clears. */
export async function clearScope(): Promise<void> {
  const keys = await AsyncStorage.getAllKeys();
  const mine = keys.filter((k) => k.startsWith(`${PREFIX}:${scope}:`));
  if (mine.length) await AsyncStorage.multiRemove(mine);
}

export type { DeviceKey };
