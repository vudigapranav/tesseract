/**
 * The session outbox: durable, ordered, exactly-once-in-effect uploads.
 *
 * Defects this version fixes, each of which loses or corrupts real sessions:
 *
 *  - **Batch results were ignored.** Upload progress advanced by the number of
 *    events *sent*, so a partially rejected 200 marked rejected events as
 *    uploaded and they were never seen again. Progress now advances only over
 *    ids the server actually reported as accepted or duplicate.
 *  - **Flushes could overlap**, letting two passes create the same session or
 *    double-send a batch. Flushes are serialized on a single promise chain,
 *    and so are writes.
 *  - **`occurred_at` did not exist.** It is now stamped when the event is
 *    recorded and preserved verbatim on every replay, so a retry does not
 *    rewrite history to the time of the retry.
 *  - **Session metadata was hardcoded `local-v1`** while the game could be
 *    running different content. The snapshot is frozen from the real config
 *    before the session is queued, so uploaded metadata matches what was
 *    played.
 *  - **Corrupt storage became a clean empty queue.** It is now quarantined and
 *    surfaced, not silently swallowed.
 *  - Retries are bounded with backoff, and a finalized session refuses further
 *    events.
 */
import * as Crypto from 'expo-crypto';
import {
  ApiError,
  MAX_EVENT_BATCH,
  type ApiClient,
  type SessionCreateBody,
  type SessionEventUpload,
} from './apiClient';
import { CorruptDataError, type ScopedStore } from './storage';
import type { GameEvent, GameResult } from '../games/contract';

const QUEUE_KEY = 'sessionOutbox';

export type OutboxStatus =
  | 'pending'
  | 'uploading'
  | 'synced'
  | 'blocked'
  | 'paused';

/** One recorded event plus the identity and time the server needs. */
export interface RecordedEvent {
  eventId: string;
  event: GameEvent;
  /** Stamped once, when it happened. Never rewritten on replay. */
  occurredAt: string;
}

/**
 * Everything about a session, frozen when it starts.
 *
 * This is the snapshot the server is told about. It is built from the actual
 * `GameConfig` the game was handed, after content finished loading.
 */
export interface SessionSnapshot {
  patientId: string;
  gameId: string;
  gameVersion: string;
  schemaVersion: string;
  configVersion: string;
  contentVersion: string;
  metricVersion: string;
  level: number;
  difficultyParams: Record<string, unknown>;
  requestedInputMode: 'touch' | 'tilt';
  /** Only when the game genuinely reported it. Never fabricated. */
  actualInputMode?: 'touch' | 'tilt';
  isTutorial: boolean;
  textScale: number;
  locale: string;
}

export interface OutboxSession {
  clientSessionId: string;
  snapshot: SessionSnapshot;
  startedAt: string;
  events: RecordedEvent[];
  /** Event ids the server has confirmed. Progress is measured by this set. */
  confirmedEventIds: string[];
  /** Ids the server refused, with the reason, kept for recovery. */
  rejected: Array<{ eventId: string; reason: string }>;
  result?: GameResult;
  completed: boolean;
  /** True once the server has accepted completion. */
  finalized: boolean;
  status: OutboxStatus;
  failureReason?: string;
  attempts: number;
  /** Earliest time a retry may run, for bounded backoff. */
  nextAttemptAt?: number;
}

export const newId = (): string => Crypto.randomUUID();

export function createOutboxSession(snapshot: SessionSnapshot): OutboxSession {
  return {
    clientSessionId: newId(),
    snapshot,
    startedAt: new Date().toISOString(),
    events: [],
    confirmedEventIds: [],
    rejected: [],
    completed: false,
    finalized: false,
    status: 'pending',
    attempts: 0,
  };
}

const BASE_BACKOFF_MS = 2_000;
const MAX_BACKOFF_MS = 5 * 60_000;
export const MAX_ATTEMPTS = 8;

const backoffFor = (attempts: number) =>
  Math.min(BASE_BACKOFF_MS * 2 ** Math.max(0, attempts - 1), MAX_BACKOFF_MS);

const toUpload = (r: RecordedEvent): SessionEventUpload => ({
  event_id: r.eventId,
  seq: r.event.seq,
  type: r.event.type,
  // The one rename at this boundary; the game contract keeps camelCase.
  elapsed_ms: r.event.elapsedMs,
  occurred_at: r.occurredAt,
  payload: r.event.payload,
});

export class SessionOutbox {
  private queue: OutboxSession[] = [];
  private loaded = false;
  private listeners = new Set<() => void>();
  /** Serializes every mutation, so concurrent callers cannot interleave. */
  private chain: Promise<unknown> = Promise.resolve();
  private flushing = false;
  private corrupt = false;

  constructor(
    private readonly store: ScopedStore,
    private readonly api: () => ApiClient | null,
    private readonly now: () => number = () => Date.now(),
  ) {}

  /** True when stored data could not be read; surfaced, never swallowed. */
  get hadCorruptData(): boolean {
    return this.corrupt;
  }

  subscribe(fn: () => void): () => void {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  private notify() {
    this.listeners.forEach((l) => l());
  }

  /** Runs `work` after everything already queued on this store. */
  private serialize<T>(work: () => Promise<T>): Promise<T> {
    const next = this.chain.then(work, work);
    this.chain = next.catch(() => undefined);
    return next;
  }

  private async persist(): Promise<void> {
    await this.store.write(QUEUE_KEY, this.queue);
    this.notify();
  }

  async load(): Promise<void> {
    return this.serialize(async () => {
      try {
        this.queue = await this.store.read<OutboxSession[]>(QUEUE_KEY, []);
        this.corrupt = false;
      } catch (e) {
        if (e instanceof CorruptDataError) {
          // Moved aside, not deleted, and reported. Silently starting empty
          // would destroy played sessions that are still recoverable by hand.
          await this.store.quarantine(QUEUE_KEY);
          this.queue = [];
          this.corrupt = true;
        } else {
          throw e;
        }
      }
      // Anything caught mid-upload by a crash returns to pending with its ids
      // intact, so the retry is recognisably the same logical write.
      for (const s of this.queue) {
        if (s.status === 'uploading') s.status = 'pending';
      }
      this.loaded = true;
      this.notify();
    });
  }

  get sessions(): readonly OutboxSession[] {
    return this.queue;
  }

  get pendingCount(): number {
    return this.queue.filter((s) => s.status !== 'synced').length;
  }

  /** Sessions that need a person to look at them. */
  get blocked(): readonly OutboxSession[] {
    return this.queue.filter(
      (s) => s.status === 'blocked' || s.status === 'paused',
    );
  }

  enqueue(session: OutboxSession): Promise<void> {
    return this.serialize(async () => {
      this.queue.push(session);
      await this.persist();
    });
  }

  /** Records one event, stamped with the time it actually happened. */
  record(clientSessionId: string, event: GameEvent): Promise<void> {
    return this.serialize(async () => {
      const s = this.queue.find((x) => x.clientSessionId === clientSessionId);
      if (!s) return;
      if (s.completed || s.finalized) {
        // A session finalises exactly once; nothing may follow it. Accepting
        // this would put the queue at odds with the server's own rule.
        throw new Error(
          `Event "${event.type}" arrived after session ${clientSessionId} was finalized.`,
        );
      }
      s.events.push({
        eventId: newId(),
        event,
        occurredAt: new Date(this.now()).toISOString(),
      });
      await this.persist();
    });
  }

  finalize(clientSessionId: string, result: GameResult): Promise<void> {
    return this.serialize(async () => {
      const s = this.queue.find((x) => x.clientSessionId === clientSessionId);
      if (!s) return;
      if (s.completed && s.result && s.result.status !== result.status) {
        throw new Error(
          `Session ${clientSessionId} was already completed as ` +
            `"${s.result.status}" and cannot also be "${result.status}".`,
        );
      }
      s.result = result;
      s.completed = true;
      await this.persist();
    });
  }

  /** Events the server has not yet confirmed, in sequence order. */
  private unconfirmed(s: OutboxSession): RecordedEvent[] {
    const done = new Set(s.confirmedEventIds);
    const refused = new Set(s.rejected.map((r) => r.eventId));
    return s.events.filter(
      (e) => !done.has(e.eventId) && !refused.has(e.eventId),
    );
  }

  private createBody(s: OutboxSession): SessionCreateBody {
    const n = s.snapshot;
    return {
      patient_id: n.patientId,
      game_id: n.gameId,
      game_version: n.gameVersion,
      schema_version: n.schemaVersion,
      config_version: n.configVersion,
      content_version: n.contentVersion,
      metric_version: n.metricVersion,
      level: n.level,
      difficulty_params: n.difficultyParams,
      requested_input_mode: n.requestedInputMode,
      ...(n.actualInputMode ? { actual_input_mode: n.actualInputMode } : {}),
      is_tutorial: n.isTutorial,
      text_scale: n.textScale,
      locale: n.locale,
    };
  }

  /**
   * Uploads everything outstanding.
   *
   * Only one flush runs at a time. `signal` lets an account change abandon an
   * in-flight pass rather than letting it finish against the wrong identity.
   */
  async flush(signal?: AbortSignal): Promise<void> {
    if (!this.loaded) await this.load();
    if (this.flushing) return;
    const api = this.api();
    if (!api) return;

    this.flushing = true;
    try {
      for (const s of this.queue) {
        if (signal?.aborted) return;
        if (s.status === 'synced' || s.status === 'blocked') continue;
        if (s.nextAttemptAt && this.now() < s.nextAttemptAt) continue;

        try {
          await this.serialize(async () => {
            s.status = 'uploading';
            await this.persist();
          });

          // Idempotent create: the client owns the id, so a lost response is
          // safe to repeat and the server reports `created: false`.
          await api.putSession(s.clientSessionId, this.createBody(s), signal);

          let outstanding = this.unconfirmed(s);
          while (outstanding.length > 0) {
            if (signal?.aborted) return;
            const batch = outstanding.slice(0, MAX_EVENT_BATCH);
            const result = await api.uploadEvents(
              s.clientSessionId,
              batch.map(toUpload),
              signal,
            );

            await this.serialize(async () => {
              // Progress advances over what the server confirmed, never over
              // what was sent.
              const confirmed = new Set([
                ...s.confirmedEventIds,
                ...result.accepted,
                ...result.duplicate,
              ]);
              s.confirmedEventIds = [...confirmed];
              for (const r of result.rejected) {
                if (!s.rejected.some((x) => x.eventId === r.event_id)) {
                  s.rejected.push({ eventId: r.event_id, reason: r.reason });
                }
              }
              await this.persist();
            });

            const before = outstanding.length;
            outstanding = this.unconfirmed(s);
            if (outstanding.length >= before) {
              // The server accepted nothing and refused nothing: repeating
              // would spin forever.
              throw new ApiError(
                422,
                'The server neither accepted nor rejected any event in the batch.',
              );
            }
          }

          if (s.completed && s.result && !s.finalized) {
            await api.completeSession(
              s.clientSessionId,
              {
                status: s.result.status,
                final_seq: s.result.finalSeq,
                assisted: s.result.assisted,
                ended_at: new Date(this.now()).toISOString(),
              },
              signal,
            );
            await this.serialize(async () => {
              s.finalized = true;
            });
          }

          await this.serialize(async () => {
            s.status = s.finalized ? 'synced' : 'pending';
            s.attempts = 0;
            s.nextAttemptAt = undefined;
            s.failureReason = s.rejected.length
              ? `${s.rejected.length} event(s) were refused by the server and are kept here.`
              : undefined;
            await this.persist();
          });
        } catch (err) {
          if (signal?.aborted) return;
          await this.serialize(async () => {
            s.attempts += 1;
            if (err instanceof ApiError && err.isUnauthorized) {
              // Identity is gone. Pause everything rather than lose a session
              // or hammer the server with a token it has rejected.
              s.status = 'paused';
              s.failureReason = 'Sign in again to finish syncing.';
              await this.persist();
              return;
            }
            if (
              err instanceof ApiError &&
              err.isPermanent &&
              !err.isTransport
            ) {
              s.status = 'blocked';
              s.failureReason = `The server refused this session (${err.status}). It is kept on this device.`;
            } else if (s.attempts >= MAX_ATTEMPTS) {
              s.status = 'blocked';
              s.failureReason =
                'Could not upload after several tries. It is kept on this device and can be retried.';
            } else {
              s.status = 'pending';
              s.nextAttemptAt = this.now() + backoffFor(s.attempts);
            }
            await this.persist();
          });
          if (err instanceof ApiError && err.isUnauthorized) return;
        }
      }
    } finally {
      this.flushing = false;
      this.notify();
    }
  }

  /** Clears the backoff and un-blocks, for an explicit "try again". */
  retryBlocked(): Promise<void> {
    return this.serialize(async () => {
      for (const s of this.queue) {
        if (s.status === 'blocked' || s.status === 'paused') {
          s.status = 'pending';
          s.attempts = 0;
          s.nextAttemptAt = undefined;
        }
      }
      await this.persist();
    });
  }
}
