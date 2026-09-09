/**
 * Where the storage encryption key lives.
 *
 * On a phone this is `expo-secure-store`: the Keychain on iOS, the
 * EncryptedSharedPreferences-backed store on Android. That is the real
 * implementation and the one that matters.
 *
 * **On web there is no secure store.** `expo-secure-store` has no web
 * implementation at all, and before this file every first write on web threw
 * `getValueWithKeyAsync is not a function`, which meant the web build could
 * not save a patient, a reminder or a session.
 *
 * Rather than let the whole build fail on a platform the runbook offers as a
 * fallback, web falls back to `localStorage` — and that is **not secure
 * storage**. A key in `localStorage` is readable by any script on the origin
 * and by anyone with the browser profile. So:
 *
 *  - web is for looking at the interface, never for real patient data;
 *  - `isSecure` says which implementation is in use, so the app can tell the
 *    person the truth instead of implying encryption it does not have;
 *  - nothing here changes iOS or Android, where the Keychain path is used
 *    exactly as before.
 */
import { Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';

/**
 * True when the key is held in real device-backed secure storage.
 *
 * The UI uses this to describe local storage honestly. It is deliberately
 * computed from the platform rather than assumed.
 */
export const isSecure = Platform.OS !== 'web';

/** The browser's store, or null when it is unavailable (private mode, etc). */
function webStorage(): Storage | null {
  try {
    return typeof localStorage === 'undefined' ? null : localStorage;
  } catch {
    // Some browsers throw on access when site data is blocked.
    return null;
  }
}

export async function getKeyMaterial(name: string): Promise<string | null> {
  if (isSecure) return SecureStore.getItemAsync(name);
  return webStorage()?.getItem(name) ?? null;
}

export async function setKeyMaterial(name: string, value: string): Promise<void> {
  if (isSecure) {
    await SecureStore.setItemAsync(name, value, {
      keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
    });
    return;
  }
  const storage = webStorage();
  if (!storage) {
    throw new Error('This browser will not store data, so nothing can be saved.');
  }
  storage.setItem(name, value);
}
