/**
 * Durable local storage, bound to an explicit identity scope.
 *
 * The previous version kept the scope in a module-level mutable variable that
 * every read and write consulted at the moment it ran. Because those are
 * async, a caregiver signing out mid-flight could have an in-progress write
 * land in the *next* account's partition — a real cross-patient leak on a
 * shared device, not a theoretical one.
 *
 * A `ScopedStore` now captures its scope at construction. A write started
 * under one identity can only ever touch that identity's keys, whatever
 * happens to the app's idea of "current" while it is awaiting.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import { openStorage, sealStorage, StorageLockedError } from './storageCipher';

const PREFIX = 'tesseract';
export const ANON_SCOPE = 'anon';

/** Keys that belong to the device, not to any one caregiver. */
const DEVICE_KEYS = new Set(['interfaceLanguage', 'activeScope']);

export class CorruptDataError extends Error {
  constructor(readonly key: string) {
    super(`Stored data for "${key}" could not be read.`);
  }
}

/**
 * A handle onto exactly one identity's data.
 *
 * Construct it once per identity and pass it down. Nothing here reads a
 * global, so there is no window in which the destination can change.
 */
export class ScopedStore {
  constructor(readonly scope: string) {}

  private key(name: string): string {
    return DEVICE_KEYS.has(name)
      ? `${PREFIX}:${name}`
      : `${PREFIX}:${this.scope}:${name}`;
  }

  /**
   * Reads a document.
   *
   * `onCorrupt` decides what a broken document means. The default **throws**,
   * because silently turning unreadable data into a clean empty value is how a
   * caregiver's Know Me content or a queue of played sessions disappears
   * without anyone noticing. Callers that genuinely tolerate loss opt in.
   */
  async read<T>(
    name: string,
    fallback: T,
    options: { onCorrupt?: 'throw' | 'fallback' } = {},
  ): Promise<T> {
    const raw = await AsyncStorage.getItem(this.key(name));
    if (raw == null) return fallback;
    const plaintext = DEVICE_KEYS.has(name) ? raw : await openStorage(this.key(name), raw);
    try {
      return JSON.parse(plaintext) as T;
    } catch {
      if (options.onCorrupt === 'fallback') return fallback;
      throw new CorruptDataError(name);
    }
  }

  /** Reads without throwing, reporting whether the document was broken. */
  async tryRead<T>(
    name: string,
    fallback: T,
  ): Promise<{ value: T; corrupt: boolean }> {
    try {
      return { value: await this.read<T>(name, fallback), corrupt: false };
    } catch (error) {
      if (error instanceof StorageLockedError) throw error;
      return { value: fallback, corrupt: true };
    }
  }

  async write(name: string, value: unknown): Promise<void> {
    const existing = await AsyncStorage.getItem(this.key(name));
    if (existing && !DEVICE_KEYS.has(name)) await openStorage(this.key(name), existing);
    const plaintext = JSON.stringify(value);
    const raw = DEVICE_KEYS.has(name) ? plaintext : await sealStorage(this.key(name), plaintext);
    await AsyncStorage.setItem(this.key(name), raw);
  }

  async remove(name: string): Promise<void> {
    await AsyncStorage.removeItem(this.key(name));
  }

  /** The raw stored string, kept for quarantining a corrupt document. */
  async raw(name: string): Promise<string | null> {
    return AsyncStorage.getItem(this.key(name));
  }

  /**
   * Moves a broken document aside instead of deleting it, so a caregiver's
   * data can still be recovered by hand rather than being destroyed by the
   * code that failed to parse it.
   */
  async quarantine(name: string): Promise<void> {
    const raw = await this.raw(name);
    if (raw == null) return;
    await AsyncStorage.setItem(
      `${this.key(name)}:corrupt:${Date.now()}`,
      raw,
    );
    await this.remove(name);
  }

  /** Everything under this scope, for a sign-out that really clears. */
  async clear(): Promise<void> {
    const keys = await AsyncStorage.getAllKeys();
    const mine = keys.filter((k) => k.startsWith(`${PREFIX}:${this.scope}:`));
    if (mine.length) await AsyncStorage.multiRemove(mine);
  }
}

/** Per-patient partition inside a caregiver's scope. */
export const patientKey = (patientId: string, name: string): string =>
  `p:${patientId}:${name}`;

export const deviceStore = new ScopedStore(ANON_SCOPE);

export async function rememberActiveScope(scope: string): Promise<void> {
  await AsyncStorage.setItem(`${PREFIX}:activeScope`, scope);
}

export async function recallActiveScope(): Promise<string> {
  return (await AsyncStorage.getItem(`${PREFIX}:activeScope`)) ?? ANON_SCOPE;
}

export const storeFor = (uid: string | null): ScopedStore =>
  new ScopedStore(uid && uid.trim() ? uid.trim() : ANON_SCOPE);
