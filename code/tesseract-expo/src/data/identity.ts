/**
 * Caregiver and doctor identity, over the Firebase REST identity endpoints —
 * the same calls the Flutter client makes, against the same project.
 *
 * The Firebase **JS SDK** would also work in Expo Go, but the REST endpoints
 * are used deliberately: they are exactly what the Flutter build already
 * verified live, so both clients exercise one code path against one project.
 *
 * There is no synthetic fallback. A failed real sign-in stays failed. The only
 * non-real path is an explicitly chosen, visibly labelled preview, and it is
 * never reached by a sign-in failing.
 */
import * as SecureStore from 'expo-secure-store';
import { FIREBASE_API_KEY, isIdentityConfigured } from './config';

const REFRESH_KEY = 'tesseract.firebase.refresh';

export type SignInFailure =
  | 'notConfigured'
  | 'invalidCredentials'
  | 'offline'
  | 'expired'
  | 'unknown';

export class IdentityError extends Error {
  constructor(
    readonly failure: SignInFailure,
    message: string,
  ) {
    super(message);
  }
}

export class IdentityService {
  private idToken: string | null = null;
  private expiresAt = 0;

  /**
   * Stable provider user id. Used to partition durable local data so a shared
   * device never shows one caregiver another's patient content.
   */
  uid: string | null = null;

  get isSignedIn(): boolean {
    return this.uid !== null;
  }

  get configured(): boolean {
    return isIdentityConfigured();
  }

  async signIn(email: string, password: string): Promise<void> {
    if (!this.configured) {
      throw new IdentityError(
        'notConfigured',
        'Sign-in needs the public Firebase key and an HTTPS backend address, ' +
          'supplied as configuration. There is no offline substitute.',
      );
    }

    let response: Response;
    try {
      response = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password, returnSecureToken: true }),
        },
      );
    } catch {
      // A network failure is not a credentials failure, and must not be
      // reported as one — the caregiver would start doubting their password.
      throw new IdentityError(
        'offline',
        'Could not reach the sign-in service. Check your connection.',
      );
    }

    if (!response.ok) {
      throw new IdentityError(
        'invalidCredentials',
        'Sign-in was not accepted. Check your details and connection.',
      );
    }

    const data = (await response.json()) as {
      idToken: string;
      refreshToken: string;
      localId: string;
    };
    this.idToken = data.idToken;
    this.uid = data.localId;
    this.expiresAt = Date.now() + 55 * 60 * 1000;
    await SecureStore.setItemAsync(REFRESH_KEY, data.refreshToken);
  }

  /** A live ID token, refreshing when the current one is close to expiry. */
  async token(): Promise<string> {
    if (this.idToken && Date.now() < this.expiresAt) return this.idToken;

    const refresh = await SecureStore.getItemAsync(REFRESH_KEY);
    if (!refresh || !this.configured) {
      throw new IdentityError('expired', 'Please sign in again.');
    }

    let response: Response;
    try {
      response = await fetch(
        `https://securetoken.googleapis.com/v1/token?key=${FIREBASE_API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `grant_type=refresh_token&refresh_token=${encodeURIComponent(refresh)}`,
        },
      );
    } catch {
      throw new IdentityError('offline', 'Could not reach the sign-in service.');
    }

    if (!response.ok) {
      // A rejected refresh token means the session is genuinely over. It is
      // never quietly replaced with a synthetic identity.
      throw new IdentityError('expired', 'Identity expired. Please sign in again.');
    }

    const data = (await response.json()) as {
      id_token: string;
      refresh_token: string;
      user_id: string;
    };
    this.idToken = data.id_token;
    this.uid = data.user_id ?? this.uid;
    this.expiresAt = Date.now() + 55 * 60 * 1000;
    await SecureStore.setItemAsync(REFRESH_KEY, data.refresh_token);
    return this.idToken;
  }

  /** Restores a session from the stored refresh token, if there is one. */
  async restore(): Promise<boolean> {
    if (!this.configured) return false;
    try {
      await this.token();
      return this.uid !== null;
    } catch {
      return false;
    }
  }

  async signOut(): Promise<void> {
    this.idToken = null;
    this.uid = null;
    this.expiresAt = 0;
    await SecureStore.deleteItemAsync(REFRESH_KEY);
  }
}
