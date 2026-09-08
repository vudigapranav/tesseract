/**
 * Build configuration.
 *
 * The Firebase Web API key is a **public client identifier**, not a secret —
 * it identifies the project to Google's identity endpoints and is designed to
 * ship in clients. It is still supplied through configuration rather than
 * hard-coded, so a fork points at its own project.
 *
 * Nothing here is a server credential. Service-account keys, AI-provider keys
 * and database URLs stay on the backend and must never reach this file.
 */
import Constants from 'expo-constants';

/**
 * Read from `EXPO_PUBLIC_*` environment variables, which Expo inlines at bundle
 * time from a gitignored `.env`. Nothing is committed, and `.env.example`
 * documents what to set.
 */
// Expo only inlines statically named EXPO_PUBLIC accesses.

/** Public Firebase Web API key for the Tesseract project. */
export const FIREBASE_API_KEY = (process.env.EXPO_PUBLIC_FIREBASE_API_KEY ?? '').trim();

/**
 * HTTPS base URL of the Tesseract API.
 *
 * HTTPS is required, matching the Flutter client: a plain-HTTP backend would
 * carry identity tokens in the clear, and iOS App Transport Security blocks it
 * anyway. A local `http://localhost` backend is therefore refused by design,
 * and reaching one needs a tunnel.
 */
export const TESSERACT_API_URL = (process.env.EXPO_PUBLIC_TESSERACT_API_URL ?? '').trim().replace(/\/$/, '');

/**
 * True when real sign-in can be attempted.
 *
 * Deliberately **narrower** than the Flutter client, which also demands an
 * HTTPS API URL before it will let anyone sign in. Identity and the API are
 * separate services: a caregiver can hold a valid Firebase session while the
 * backend is unreachable, and the app already handles that by keeping sessions
 * on the device and showing an honest "saved on this device" state. Refusing
 * sign-in for a missing API would report an identity problem that does not
 * exist.
 */
export const isIdentityConfigured = (): boolean => FIREBASE_API_KEY.length > 0;

/** True when the API is reachable, even if identity is not configured. */
export const isApiConfigured = (): boolean =>
  TESSERACT_API_URL.startsWith('https://');

/**
 * The app's own version, distinct from the Expo Go container it runs inside.
 *
 * In Expo Go, `Application.nativeApplicationVersion` reports **Expo Go's**
 * version, not ours. Presenting that as the Tesseract build would be a false
 * version number in the About screen, so this reads our own manifest instead
 * and says where it is running.
 */
export function appVersion(): {
  version: string;
  runtime: string;
  isExpoGo: boolean;
} {
  const isExpoGo = Constants.executionEnvironment === 'storeClient';
  return {
    version: Constants.expoConfig?.version ?? '0.0.0',
    runtime: isExpoGo ? 'Expo Go' : 'standalone',
    isExpoGo,
  };
}
