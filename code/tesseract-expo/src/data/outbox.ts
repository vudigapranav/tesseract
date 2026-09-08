/**
 * The session outbox: durable, ordered, exactly-once-in-effect uploads.
 *
 * Guarantees, matching the Flutter build:
 *  - Sessions upload in the order `create → events → complete`, never
 *    out of order and never partially skipped.
 *  - Session ids and event ids are generated **once**, on the device, and
 *    reused on every retry — so a replayed batch is recognisable as the same
 *    logical write rather than a duplicate.
 *  - Batches never exceed 500 events.
 *  - A transport or 5xx failure retries with the same ids.
 *  - A permanent 4xx stops automatic retries and keeps the data, rather than
 *    discarding a real session someone played.
 *  - An identity failure pauses sync entirely rather than dropping anything.
 *  - Everything survives a restart, because the queue is persisted after each
 *    state change, not held in memory.
 */
import * as Crypto from 'expo-crypto';
import { ApiError, MAX_EVENT_BATCH, type ApiClient } from './apiClient';
import { readJson, writeJson } from './storage';
import type { GameEvent, GameResult } from '../games/contract';

const QUEUE_KEY = 'sessionOutbox';

export type OutboxStatus =
  | 'pending'
  | 'uploading'
  | 'synced'
  | 'blocked'
  | 'paused';

export interface OutboxSession {
  /** Client-generated. Stable for the life of this session, across retries. */
  clientSessionId: string;
  /** Server id, once creation succeeded. Creation is not repeated after this. */
  serverSessionId?: string;
  patientId: string;
  gameId: string;
  level: number;
  configVersion: string;
  contentVersion: string;
  schemaVersion: string;
  metricVersion: string;
  startedAt: string;
  events: GameEvent[];
  /** One stable id per event, index-aligned with `events`. */
  eventIds: string[];
  /** How many events the server has already accepted. */
  uploadedCount: number;
  result?: GameResult;
  completed: boolean;
  status: OutboxStatus;
  /** Set when status is 'blocked', so the caregiver sees a real reason. */
  failureReason?: string;
  attempts: number;
}

export const newId = (): string => Crypto.randomUUID();

export function createOutboxSession(init: {
  patientId: string;
  gameId: string;
  level: number;
  configVersion: string;
  contentVersion: string;
  schemaVersion: string;
  metricVersion: string;
}): OutboxSession {
  return {
    clientSessionId: newId(),
    ...init,
    startedAt: new Date().toISOString(),
    events: [],
    eventIds: [],
    uploadedCount: 0,
    completed: false,
    status: 'pending',
    attempts: 0,
  };
}

export class SessionOutbox {
  private queue: OutboxSession[] = [];
  private loaded = false;
  private listeners = new Set<() => void>();

  constructor(private readonly api: () => ApiClient | null) {}

  subscribe(fn: () => void): () => void {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  private notify() {
    this.listeners.forEach((l) => l());
  }

  private async persist(): Promise<void> {
    await writeJson(QUEUE_KEY, this.queue);
    this.notify();
  }

  async load(): Promise<void> {
    this.queue = await readJson<OutboxSession[]>(QUEUE_KEY, []);
    // Anything caught mid-upload by a crash or a kill goes back to pending
    // with its ids intact, so the retry is the same logical write.
    for (const s of this.queue) {
      if (s.status === 'uploading') s.status = 'pending';
    }
    this.loaded = true;
    this.notify();
  }

  get sessions(): readonly OutboxSession[] {
    return this.queue;
  }

  get pendingCount(): number {
    return this.queue.filter((s) => s.status !== 'synced').length;
  }

  async enqueue(session: OutboxSession): Promise<void> {
    this.queue.push(session);
    await this.persist();
  }

  /** Records one event with a stable id, ready for upload. */
  async record(clientSessionId: string, event: GameEvent): Promise<void> {
    const s = this.queue.find((x) => x.clientSessionId === clientSessionId);
    if (!s) return;
    s.events.push(event);
    s.eventIds.push(newId());
    await this.persist();
  }

  async finalize(
    clientSessionId: string,
    result: GameResult,
  ): Promise<void> {
    const s = this.queue.find((x) => x.clientSessionId === clientSessionId);
    if (!s) return;
    s.result = result;
    s.completed = true;
    await this.persist();
  }

  /**
   * Attempts to upload everything outstanding.
   *
   * Returns quietly when there is no API configured or no connection — a
   * pending session is a normal state, not an error to shout about.
   */
  async flush(): Promise<void> {
    if (!this.loaded) await this.load();
    const api = this.api();
    if (!api) return;

    for (const s of this.queue) {
      if (s.status === 'synced' || s.status === 'blocked') continue;
      try {
        s.status = 'uploading';
        await this.persist();

        if (!s.serverSessionId) {
          const created = await api.createSession(s.patientId, {
            client_session_id: s.clientSessionId,
            game_id: s.gameId,
            level: s.level,
            config_version: s.configVersion,
            content_version: s.contentVersion,
            schema_version: s.schemaVersion,
            metric_version: s.metricVersion,
            started_at: s.startedAt,
          });
          s.serverSessionId = created.session_id;
          await this.persist();
        }

        // Only events the server has not accepted, in order, capped.
        while (s.uploadedCount < s.events.length) {
          const from = s.uploadedCount;
          const to = Math.min(from + MAX_EVENT_BATCH, s.events.length);
          await api.uploadEvents(
            s.serverSessionId,
            s.events.slice(from, to),
            s.eventIds.slice(from, to),
          );
          s.uploadedCount = to;
          await this.persist();
        }

        if (s.completed && s.result) {
          await api.completeSession(s.serverSessionId, {
            status: s.result.status,
            final_seq: s.result.finalSeq,
            assisted: s.result.assisted,
          });
          s.status = 'synced';
        } else {
          s.status = 'pending';
        }
        s.attempts = 0;
        await this.persist();
      } catch (err) {
        s.attempts += 1;
        if (err instanceof ApiError && err.isUnauthorized) {
          // Identity is gone. Pause everything rather than lose a session or
          // hammer the server with a token it has rejected.
          s.status = 'paused';
          s.failureReason = 'Sign in again to finish syncing.';
          await this.persist();
          return;
        }
        if (err instanceof ApiError && err.isPermanent) {
          // Retrying cannot help. Keep the data and say so.
          s.status = 'blocked';
          s.failureReason = `The server refused this session (${err.status}). It is kept on this device.`;
        } else {
          s.status = 'pending';
        }
        await this.persist();
      }
    }
  }
}
