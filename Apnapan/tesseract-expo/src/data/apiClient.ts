/**
 * The Apnapan API client, written against `services/api/app/schemas.py`.
 *
 * The previous version was written from memory and was wrong in ways that
 * would have failed on first contact with the real server:
 *
 *  - patients were read as `id` / `profile_revision`; the server returns
 *    `patient_id` / `version`
 *  - sessions were created with `POST /patients/{id}/sessions`; the route is
 *    `PUT /v1/sessions/{session_id}` and it requires `patient_id`,
 *    `game_version` and `requested_input_mode`
 *  - events omitted `occurred_at`, which `EventIn` requires
 *  - the batch response was ignored, so rejected events counted as uploaded
 *  - personalization was sent as `revision` + `entries`; the schema is
 *    `version`, `personal_words`, `people_places`, `preferences`
 *  - decisions were free-form strings; the schema is accept | modify | reject
 *
 * Responses are validated at runtime, because a client that trusts a shape it
 * never checked fails later and further from the cause.
 */
import { TESSERACT_API_URL } from './config';

export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly body?: unknown,
  ) {
    super(message);
  }

  /** 4xx other than 408/429: retrying will not help. */
  get isPermanent(): boolean {
    return (
      this.status >= 400 &&
      this.status < 500 &&
      this.status !== 408 &&
      this.status !== 429
    );
  }
  get isConflict(): boolean {
    return this.status === 409;
  }
  get isUnauthorized(): boolean {
    return this.status === 401 || this.status === 403;
  }
  /** No response at all — offline, DNS, timeout. Always worth retrying. */
  get isTransport(): boolean {
    return this.status === 0;
  }
}

export class ShapeError extends Error {
  constructor(what: string) {
    super(`The server returned something unexpected for ${what}.`);
  }
}

export const MAX_EVENT_BATCH = 500;
const DEFAULT_TIMEOUT_MS = 20_000;

/* ------------------------------------------------------------- shapes - */

export interface PatientOut {
  patient_id: string;
  display_name: string;
  language: string;
  known_type: string | null;
  known_stage: string | null;
  accessibility: Record<string, unknown>;
  version: number;
  created_at: string;
}

export interface ActivityOut {
  patient_id: string;
  game_id: string;
  level: number;
  input_mode: 'touch' | 'tilt';
  config: Record<string, unknown>;
  config_version: number;
  source: 'approved' | 'safe_default';
  approved_at: string | null;
  content_sufficiency: {
    personal_words: number;
    people_places: number;
    sufficient_for_word_games: boolean;
    target_personal_words: string;
  };
}

export interface SessionOut {
  session_id: string;
  patient_id: string;
  game_id: string;
  game_version: string;
  level: number;
  is_tutorial: boolean;
  requested_input_mode: string;
  actual_input_mode: string;
  input_mode_unverified: boolean;
  status: string;
  created: boolean;
  events_received: number;
  final_seq: number | null;
  created_at: string;
}

export interface EventBatchOut {
  accepted: string[];
  duplicate: string[];
  rejected: Array<{ event_id: string; reason: string; detail?: string | null }>;
  highest_seq: number | null;
  missing_seqs: number[];
}

export interface SessionCompleteOut {
  session_id: string;
  status: string;
  final_seq: number;
  created: boolean;
  metrics: unknown | null;
  recommendation_id: string | null;
}

export interface RecommendationOut {
  recommendation_id: string;
  patient_id: string;
  status: string;
  rule_version: string;
  proposed_config: Record<string, unknown>;
  current_config: Record<string, unknown>;
  reason: Record<string, unknown>;
  based_on_config_version: number;
  created_at: string;
  decided_at: string | null;
}

export interface NoteOut {
  note_id: string;
  patient_id: string;
  author_user_id: string;
  body: string;
  created_at: string;
}

export interface ReportOut {
  report_id: string;
  patient_id: string;
  window_days: number;
  status: string;
  generator: string;
  generator_version: string;
  source_session_ids: string[];
  content: Record<string, unknown>;
  created_at: string;
}

export interface ReminderOut {
  reminder_id: string;
  patient_id: string;
  title: string;
  body: string | null;
  schedule: Record<string, unknown>;
  schedule_version: number;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface OccurrenceOut {
  occurrence_id: string;
  reminder_id: string;
  scheduled_for: string;
  schedule_version: number;
  state: string;
  acknowledgement_state: string | null;
  acknowledged_at: string | null;
}

export interface SessionEventUpload {
  event_id: string;
  seq: number;
  type: string;
  elapsed_ms: number;
  /** Recorded when the event happened; preserved verbatim on replay. */
  occurred_at: string;
  payload: Record<string, unknown>;
}

export interface SessionCreateBody {
  started_at?: string;
  patient_id: string;
  game_id: string;
  game_version: string;
  schema_version: string;
  config_version: string;
  content_version: string;
  metric_version: string;
  level: number;
  difficulty_params: Record<string, unknown>;
  requested_input_mode: 'touch' | 'tilt';
  /** Omitted when the game did not report it — never fabricated. */
  actual_input_mode?: 'touch' | 'tilt';
  is_tutorial: boolean;
  text_scale: number;
  locale: string;
}

/* --------------------------------------------------------- validation - */

const isObj = (v: unknown): v is Record<string, unknown> =>
  typeof v === 'object' && v !== null && !Array.isArray(v);

function expect<T>(value: unknown, ok: boolean, what: string): T {
  if (!ok) throw new ShapeError(what);
  return value as T;
}

const asPatient = (v: unknown): PatientOut =>
  expect<PatientOut>(
    v,
    isObj(v) &&
      typeof v.patient_id === 'string' &&
      typeof v.display_name === 'string' &&
      typeof v.version === 'number',
    'a patient',
  );

const asBatch = (v: unknown): EventBatchOut =>
  expect<EventBatchOut>(
    v,
    isObj(v) &&
      Array.isArray(v.accepted) &&
      Array.isArray(v.duplicate) &&
      Array.isArray(v.rejected),
    'an event batch result',
  );

/* ------------------------------------------------------------ client - */

export class ApiClient {
  constructor(
    private readonly getToken: () => Promise<string>,
    private readonly timeoutMs = DEFAULT_TIMEOUT_MS,
  ) {}

  private async request<T>(
    method: string,
    path: string,
    body?: unknown,
    signal?: AbortSignal,
  ): Promise<T> {
    if (signal?.aborted) throw new ApiError(0, "Request cancelled.");
    const token = await this.getToken();
    if (signal?.aborted) throw new ApiError(0, "Request cancelled.");
    // Every request is bounded. Without this a stalled connection hangs a
    // flush forever and the outbox never makes progress.
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    const onOuterAbort = () => controller.abort();
    signal?.addEventListener('abort', onOuterAbort);

    let response: Response;
    try {
      response = await fetch(`${TESSERACT_API_URL}/v1${path}`, {
        method,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: controller.signal,
      });
    } catch {
      // Status 0 means "no response", which is retryable — distinct from a
      // server that answered with a refusal.
      throw new ApiError(0, `${method} ${path} could not reach the server.`);
    } finally {
      clearTimeout(timer);
      signal?.removeEventListener('abort', onOuterAbort);
    }

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

  /* ---------------------------------------------------------- patients - */

  async listPatients(signal?: AbortSignal): Promise<PatientOut[]> {
    const raw = await this.request<unknown>('GET', '/patients', undefined, signal);
    if (!Array.isArray(raw)) throw new ShapeError('the patient list');
    return raw.map(asPatient);
  }

  async getPatient(patientId: string): Promise<PatientOut> {
    return asPatient(await this.request<unknown>('GET', `/patients/${patientId}`));
  }

  async createPatient(body: {
    display_name: string;
    language?: string;
    known_type?: string | null;
    known_stage?: string | null;
    accessibility?: Record<string, unknown>;
  }): Promise<PatientOut> {
    return asPatient(await this.request<unknown>('POST', '/patients', body));
  }

  getActivity(patientId: string, signal?: AbortSignal) {
    return this.request<ActivityOut>(
      'GET',
      `/patients/${patientId}/activity`,
      undefined,
      signal,
    );
  }

  /* --------------------------------------------------- personalization - */

  getPersonalization(patientId: string) {
    return this.request<Record<string, unknown>>(
      'GET',
      `/patients/${patientId}/personalization`,
    );
  }

  /**
   * Uploads personalization at the exact schema the server accepts.
   * A 409 means the server moved on; the caller keeps local edits.
   */
  putPersonalization(
    patientId: string,
    body: {
      version: number;
      personal_words: Array<{ text: string; locale: string }>;
      people_places: Array<{
        kind: 'person' | 'place';
        label: string;
        media_asset_id?: string | null;
      }>;
      preferences: Record<string, unknown>;
    },
  ) {
    return this.request<{
      patient_id: string;
      version: number;
      personal_words_count: number;
      people_places_count: number;
    }>('PUT', `/patients/${patientId}/personalization`, body);
  }

  /* ---------------------------------------------------------- sessions - */

  /** Idempotent create. The client owns the session id. */
  putSession(sessionId: string, body: SessionCreateBody, signal?: AbortSignal) {
    return this.request<SessionOut>(
      'PUT',
      `/sessions/${sessionId}`,
      body,
      signal,
    );
  }

  async uploadEvents(
    sessionId: string,
    events: SessionEventUpload[],
    signal?: AbortSignal,
  ): Promise<EventBatchOut> {
    if (events.length === 0 || events.length > MAX_EVENT_BATCH) {
      throw new Error(
        `A batch must hold 1..${MAX_EVENT_BATCH} events; got ${events.length}.`,
      );
    }
    return asBatch(
      await this.request<unknown>(
        'POST',
        `/sessions/${sessionId}/events:batch`,
        { events },
        signal,
      ),
    );
  }

  completeSession(
    sessionId: string,
    body: {
      status: 'completed' | 'stopped_by_user' | 'interrupted';
      final_seq: number;
      assisted: boolean;
      ended_at?: string;
    },
    signal?: AbortSignal,
  ) {
    return this.request<SessionCompleteOut>(
      'POST',
      `/sessions/${sessionId}/complete`,
      body,
      signal,
    );
  }

  listSessions(patientId: string, cursor?: string) {
    const q = cursor ? `?cursor=${encodeURIComponent(cursor)}` : '';
    return this.request<{ items: unknown[]; next_cursor?: string | null }>(
      'GET',
      `/patients/${patientId}/sessions${q}`,
    );
  }

  patientSummary(patientId: string) {
    return this.request<Record<string, unknown>>(
      'GET',
      `/patients/${patientId}/summary`,
    );
  }

  /* --------------------------------------------------- recommendations - */

  listRecommendations(patientId: string, signal?: AbortSignal) {
    return this.request<{
      items: RecommendationOut[];
      next_cursor: string | null;
    }>('GET', `/patients/${patientId}/recommendations`, undefined, signal);
  }

  /** `recommendationId` must be the server-issued UUID, never a local key. */
  decideRecommendation(
    recommendationId: string,
    body: {
      decision: 'accept' | 'modify' | 'reject';
      modified_config?: Record<string, unknown>;
      expected_config_version?: number;
    },
  ) {
    return this.request<RecommendationOut>(
      'POST',
      `/recommendations/${recommendationId}/decision`,
      body,
    );
  }

  /* ------------------------------------------------------------- notes - */

  listNotes(patientId: string) {
    return this.request<NoteOut[]>('GET', `/patients/${patientId}/notes`);
  }

  addNote(patientId: string, body: string) {
    return this.request<NoteOut>('POST', `/patients/${patientId}/notes`, {
      body,
    });
  }

  createReport(patientId: string, windowDays: number) {
    return this.request<ReportOut>('POST', `/patients/${patientId}/reports`, {
      window_days: windowDays,
    });
  }

  getReport(reportId: string) {
    return this.request<ReportOut>('GET', `/reports/${reportId}`);
  }

  /* --------------------------------------------------------- reminders - */

  listReminders(patientId: string) {
    return this.request<ReminderOut[]>('GET', `/patients/${patientId}/reminders`);
  }

  createReminder(
    patientId: string,
    body: {
      title: string;
      body?: string | null;
      schedule: {
        kind: 'daily' | 'weekly' | 'once';
        times: string[];
        weekdays?: number[];
        date?: string | null;
        timezone: string;
      };
      active: boolean;
    },
  ) {
    return this.request<ReminderOut>(
      'POST',
      `/patients/${patientId}/reminders`,
      body,
    );
  }

  listOccurrences(patientId: string) {
    return this.request<OccurrenceOut[]>(
      'GET',
      `/patients/${patientId}/reminders/occurrences`,
    );
  }

  acknowledgeOccurrence(occurrenceId: string) {
    return this.request<OccurrenceOut>(
      'POST',
      `/reminder-occurrences/${occurrenceId}/acknowledge`,
    );
  }

  /* ---------------------------------------------------------- doctor - */

  async doctorPatients(): Promise<PatientOut[]> {
    const raw = await this.request<unknown>('GET', '/doctor/patients');
    if (!Array.isArray(raw)) throw new ShapeError('the doctor patient list');
    return raw.map(asPatient);
  }

  doctorSummary(patientId: string) {
    return this.request<Record<string, unknown>>(
      'GET',
      `/doctor/patients/${patientId}/summary`,
    );
  }
}
