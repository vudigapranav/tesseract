/**
 * Authentication for the return out of patient mode.
 *
 * The previous implementation failed **open**: while capability was still
 * loading, and whenever the device reported no biometric enrollment, it drew a
 * plain "Continue" button wired straight to `onUnlocked`. Anyone holding the
 * phone could leave patient mode by pressing it. A confirmation button is not
 * authentication.
 *
 * This module fails closed. The gate opens only on a positive result from one
 * of two real factors:
 *
 *  1. **Device authentication** — Face ID, Touch ID, or the device passcode.
 *     Biometric enrollment and passcode support are separate things, so
 *     `getEnrolledLevelAsync` is used rather than `isEnrolledAsync` alone: a
 *     phone with a passcode but no enrolled face can still authenticate.
 *  2. **A caregiver PIN** — something the caregiver knows, set while they are
 *     already signed in, stored only as a salted hash. This is the fallback
 *     for a device with no lock at all, and it works offline and inside
 *     Expo Go.
 *
 * If neither is available the gate stays shut and says why. There is no path
 * that opens it without a factor.
 */
import * as LocalAuthentication from 'expo-local-authentication';
import * as SecureStore from 'expo-secure-store';
import * as Crypto from 'expo-crypto';

const PIN_KEY = 'apnapan.caregiverPin.v1';

/** What this device can actually do, kept separate rather than collapsed. */
export interface AuthCapability {
  /** Biometric or passcode available through the OS prompt. */
  deviceAuth: boolean;
  /** True specifically when a face/fingerprint is enrolled. */
  biometricEnrolled: boolean;
  /** True when at least a device passcode exists. */
  passcodeSet: boolean;
  /** True when the caregiver has set a PIN in this app. */
  pinSet: boolean;
}

export type UnlockResult =
  | { ok: true; factor: 'device' | 'pin' }
  | { ok: false; reason: 'cancelled' | 'failed' | 'unavailable' | 'noFactor' };

export async function readCapability(): Promise<AuthCapability> {
  let biometricEnrolled = false;
  let passcodeSet = false;
  try {
    const hasHardware = await LocalAuthentication.hasHardwareAsync();
    const level = await LocalAuthentication.getEnrolledLevelAsync();
    // SECRET means a passcode exists; the biometric levels imply it too.
    passcodeSet = level !== LocalAuthentication.SecurityLevel.NONE;
    biometricEnrolled =
      hasHardware &&
      (level === LocalAuthentication.SecurityLevel.BIOMETRIC_STRONG ||
        level === LocalAuthentication.SecurityLevel.BIOMETRIC_WEAK);
  } catch {
    // An error here means we could not establish capability. It is never
    // treated as "no lock, so let them through".
    biometricEnrolled = false;
    passcodeSet = false;
  }
  return {
    deviceAuth: passcodeSet || biometricEnrolled,
    biometricEnrolled,
    passcodeSet,
    pinSet: await hasPin(),
  };
}

export async function hasPin(): Promise<boolean> {
  try {
    return (await SecureStore.getItemAsync(PIN_KEY)) !== null;
  } catch {
    return false;
  }
}

const hash = (pin: string, salt: string) =>
  Crypto.digestStringAsync(
    Crypto.CryptoDigestAlgorithm.SHA256,
    `${salt}:${pin}`,
  );

/**
 * Stores a caregiver PIN as a salted hash. Called only from Settings, where
 * the caregiver is already signed in.
 */
export async function setPin(pin: string): Promise<void> {
  if (pin.trim().length < 4) {
    throw new Error('A PIN needs at least 4 digits.');
  }
  const salt = Crypto.randomUUID();
  const digest = await hash(pin.trim(), salt);
  await SecureStore.setItemAsync(PIN_KEY, JSON.stringify({ salt, digest }));
}

export async function clearPin(): Promise<void> {
  await SecureStore.deleteItemAsync(PIN_KEY);
}

export async function verifyPin(pin: string): Promise<boolean> {
  try {
    const raw = await SecureStore.getItemAsync(PIN_KEY);
    if (!raw) return false;
    const { salt, digest } = JSON.parse(raw) as { salt: string; digest: string };
    const candidate = await hash(pin.trim(), salt);
    return candidate === digest;
  } catch {
    return false;
  }
}

/** Runs the OS prompt. Only a genuine success unlocks. */
export async function unlockWithDevice(
  promptMessage: string,
  cancelLabel: string,
): Promise<UnlockResult> {
  const capability = await readCapability();
  if (!capability.deviceAuth) return { ok: false, reason: 'unavailable' };
  try {
    const result = await LocalAuthentication.authenticateAsync({
      promptMessage,
      cancelLabel,
      // Deliberately left enabled: a caregiver whose face is not recognised
      // must still be able to use the device passcode.
      disableDeviceFallback: false,
    });
    if (result.success) return { ok: true, factor: 'device' };
    return {
      ok: false,
      reason:
        'error' in result && result.error === 'user_cancel'
          ? 'cancelled'
          : 'failed',
    };
  } catch {
    return { ok: false, reason: 'failed' };
  }
}

export async function unlockWithPin(pin: string): Promise<UnlockResult> {
  if (!(await hasPin())) return { ok: false, reason: 'noFactor' };
  return (await verifyPin(pin))
    ? { ok: true, factor: 'pin' }
    : { ok: false, reason: 'failed' };
}

/**
 * The decision the UI needs: what, if anything, this device can offer.
 *
 * `none` means the gate cannot be opened here. That is a real state and the
 * UI says so — it does not degrade into an open door.
 */
export function availableFactor(
  c: AuthCapability | null,
): 'loading' | 'device' | 'pin' | 'none' {
  if (c === null) return 'loading';
  if (c.deviceAuth) return 'device';
  if (c.pinSet) return 'pin';
  return 'none';
}
