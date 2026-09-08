/**
 * The Tesseract API client, against Pranav's contract (routes under /v1).
 *
 * Serialization details that matter and are easy to get wrong:
 *  - `elapsedMs` becomes `elapsed_ms` at this boundary. The game contract
 *    keeps camelCase; the API is snake_case. The mapping lives here and
 *    nowhere else.
 *  - Event batches are capped at 500.
 *  - Session ids and event ids are stable across retries, so a replay is
 *    recognisable as the same logical write rather than a new one.
 */
import { TESSERACT_API_URL } from './config';
import type { GameEvent } from '../games/contract';

export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly body?: unknown,
  ) {
    super(message);
  }

  /** 4xx other than 408/429: retrying will not help, so the outbox stops. */
  get isPermanent(): boolean {
    return (
      this.status >= 400 &&
      this.status < 500 &&
      this.status !== 408 &&
      this.status !== 429
    );
  }

  /** A revision conflict. Never resolved by overwriting. */
  get isConflict(): boolean {
    return this.status === 409;
  }

  /** Identity rejected — the session is over, sync pauses. */
  get isUnauthorized(): boolean {
    return this.status === 401 || this.status === 403;
  }
}

export const MAX_EVENT_BATCH = 500;

export interface PatientSummary {
  id: string;
  display_name: string;
  language?: string;
  profile_revision?: string;
}

export class ApiClient {
  constructor(private readonly getToken: () => Promise<string>) {}

  private async request<T>(
    method: string,
    path: string,
    body?: unknown,
    extraHeaders?: Record<string, string>,
  ): Promise<T> {
    const token = await this.getToken();
    const response = await fetch(`${TESSERACT_API_URL}/v1${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        ...extraHeaders,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });

    if (!response.ok) {
      let parsed: unknown;
      try {
        parsed = await response.json();
      } catch {
        parsed = undefined;
      }
      throw new ApiError(
        response.status,
        `${method} ${path} failed with ${response.status}`,
        parsed,
      );
    }
    if (response.status === 204) return undefined as T;
    return (await response.json()) as T;
  }

  health() {
    return this.request<{ status: string }>('GET', '/health');
  }

  listPatients() {
    return this.request<PatientSummary[]>('GET', '/patients');
  }

  getPatient(patientId: string) {
    return this.request<PatientSummary>('GET', `/patients/${patientId}`);
  }

  createPatient(body: { display_name: string; language?: string }) {
    return this.request<PatientSummary>('POST', '/patients', body);
  }

  getPersonalization(patientId: string) {
    return this.request<Record<string, unknown>>(
      'GET',
      `/patients/${patientId}/personalization`,
    );
  }

  /**
   * Uploads personalization against the revision the client last read.
   * A 409 means the server moved on; the caller keeps local edits and asks
   * the caregiver, and never retries with a bumped revision.
   */
  putPersonalization(
    patientId: string,
    body: Record<string, unknown>,
  ) {
    return this.request<Record<string, unknown>>(
      'PUT',
      `/patients/${patientId}/personalization`,
      body,
    );
  }

  getActivity(patientId: string) {
    return this.request<Record<string, unknown>>(
      'GET',
      `/patients/${patientId}/activity`,
    );
  }

  getRecommendations(patientId: string) {
    return this.request<Record<string, unknown>>(
      'GET',
      `/patients/${patientId}/recommendations`,
    );
  }

  decideRecommendation(
    recommendationId: string,
    body: { decision: string; level?: number },
  ) {
    return this.request<Record<string, unknown>>(
      'POST',
      `/recommendations/${recommendationId}/decision`,
      body,
    );
  }

  listSessions(patientId: string, cursor?: string) {
    const q = cursor ? `?cursor=${encodeURIComponent(cursor)}` : '';
    return this.request<{ items: unknown[]; next_cursor?: string }>(
      'GET',
      `/patients/${patientId}/sessions${q}`,
    );
  }

  createSession(patientId: string, body: Record<string, unknown>) {
    return this.request<{ session_id: string }>(
      'POST',
      `/patients/${patientId}/sessions`,
      body,
    );
  }

  /** Uploads one batch. Caller enforces MAX_EVENT_BATCH and ordering. */
  uploadEvents(sessionId: string, events: GameEvent[], eventIds: string[]) {
    if (events.length > MAX_EVENT_BATCH) {
      throw new Error(
        `Batch of ${events.length} exceeds the ${MAX_EVENT_BATCH} cap.`,
      );
    }
    return this.request<Record<string, unknown>>(
      'POST',
      `/sessions/${sessionId}/events:batch`,
      {
        events: events.map((e, i) => ({
          // Stable across retries, so a replay is the same logical event.
          event_id: eventIds[i],
          type: e.type,
          seq: e.seq,
          // The one rename that matters at this boundary.
          elapsed_ms: e.elapsedMs,
          payload: e.payload,
        })),
      },
    );
  }

  completeSession(sessionId: string, body: Record<string, unknown>) {
    return this.request<Record<string, unknown>>(
      'POST',
      `/sessions/${sessionId}/complete`,
      body,
    );
  }

  listReminders(patientId: string) {
    return this.request<{ items: unknown[] }>(
      'GET',
      `/patients/${patientId}/reminders`,
    );
  }

  doctorPatients() {
    return this.request<PatientSummary[]>('GET', '/doctor/patients');
  }

  doctorSummary(patientId: string) {
    return this.request<Record<string, unknown>>(
      'GET',
      `/doctor/patients/${patientId}/summary`,
    );
  }
}
