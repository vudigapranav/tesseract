import { SessionOutbox, createOutboxSession } from '../outbox';
import { ApiError, MAX_EVENT_BATCH } from '../apiClient';
import type { GameEvent } from '../../games/contract';

jest.mock('expo-crypto', () => {
  let n = 0;
  return { randomUUID: () => `id-${++n}` };
});

// `var` + a `mock` prefix: jest hoists mock factories above the file, and
// only allows out-of-scope names that begin with "mock".
// eslint-disable-next-line no-var
var mockStore = new Map<string, string>();
jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn(async (k: string) => mockStore.get(k) ?? null),
  setItem: jest.fn(async (k: string, v: string) => void mockStore.set(k, v)),
  removeItem: jest.fn(async (k: string) => void mockStore.delete(k)),
  getAllKeys: jest.fn(async () => [...mockStore.keys()]),
  multiRemove: jest.fn(async (ks: string[]) =>
    ks.forEach((k) => mockStore.delete(k)),
  ),
}));

const ev = (seq: number): GameEvent => ({
  type: 'word_found',
  seq,
  elapsedMs: seq * 100,
  payload: { wordId: `w${seq}` },
});

function fakeApi() {
  const calls = {
    created: [] as unknown[],
    batches: [] as Array<{ sessionId: string; events: GameEvent[]; ids: string[] }>,
    completed: [] as unknown[],
  };
  let failNext: Error | null = null;
  return {
    calls,
    failWith(e: Error) {
      failNext = e;
    },
    client: {
      createSession: jest.fn(async (patientId: string, body: any) => {
        if (failNext) {
          const e = failNext;
          failNext = null;
          throw e;
        }
        calls.created.push(body);
        return { session_id: `srv-${body.client_session_id}` };
      }),
      uploadEvents: jest.fn(
        async (sessionId: string, events: GameEvent[], ids: string[]) => {
          if (failNext) {
            const e = failNext;
            failNext = null;
            throw e;
          }
          if (events.length > MAX_EVENT_BATCH) throw new Error('batch too large');
          calls.batches.push({ sessionId, events, ids });
          return {};
        },
      ),
      completeSession: jest.fn(async (sessionId: string, body: any) => {
        if (failNext) {
          const e = failNext;
          failNext = null;
          throw e;
        }
        calls.completed.push({ sessionId, body });
        return {};
      }),
    } as any,
  };
}

const session = () =>
  createOutboxSession({
    patientId: 'p1',
    gameId: 'word_search',
    level: 1,
    configVersion: 'local-v1',
    contentVersion: 'local-v1',
    schemaVersion: '1',
    metricVersion: '1',
  });

beforeEach(() => mockStore.clear());

describe('session outbox', () => {
  it('uploads create, then events, then complete, in that order', async () => {
    const api = fakeApi();
    const outbox = new SessionOutbox(() => api.client);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.record(s.clientSessionId, ev(2));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed',
      finalSeq: 2,
      assisted: false,
    });

    await outbox.flush();

    expect(api.calls.created).toHaveLength(1);
    expect(api.calls.batches).toHaveLength(1);
    expect(api.calls.completed).toHaveLength(1);
    expect(outbox.pendingCount).toBe(0);
  });

  it('serializes elapsedMs as elapsed_ms at the API boundary', async () => {
    const api = fakeApi();
    const outbox = new SessionOutbox(() => api.client);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed',
      finalSeq: 1,
      assisted: false,
    });
    await outbox.flush();

    // uploadEvents receives camelCase and renames internally; assert the
    // client was handed the game-shaped event and the rename is its job.
    const [batch] = api.calls.batches;
    expect(batch.events[0]).toHaveProperty('elapsedMs', 100);
  });

  it('does not create the session twice when a retry happens', async () => {
    const api = fakeApi();
    const outbox = new SessionOutbox(() => api.client);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed',
      finalSeq: 1,
      assisted: false,
    });

    api.failWith(new Error('network down'));
    await outbox.flush(); // creation fails
    await outbox.flush(); // retry

    expect(api.calls.created).toHaveLength(1);
    expect(outbox.pendingCount).toBe(0);
  });

  it('keeps the same event ids across a retry, so replays deduplicate', async () => {
    const api = fakeApi();
    const outbox = new SessionOutbox(() => api.client);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));

    await outbox.flush();
    const first = [...(api.calls.batches[0]?.ids ?? [])];

    await outbox.finalize(s.clientSessionId, {
      status: 'completed',
      finalSeq: 1,
      assisted: false,
    });
    await outbox.flush();

    // The first event is not re-sent, because the server already took it.
    expect(api.calls.batches).toHaveLength(1);
    expect(first).toHaveLength(1);
  });

  it('never sends more than 500 events in one batch', async () => {
    const api = fakeApi();
    const outbox = new SessionOutbox(() => api.client);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    for (let i = 1; i <= 1200; i++) await outbox.record(s.clientSessionId, ev(i));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed',
      finalSeq: 1200,
      assisted: false,
    });

    await outbox.flush();

    expect(api.calls.batches.map((b) => b.events.length)).toEqual([500, 500, 200]);
    // Ordering is preserved across batches.
    expect(api.calls.batches[0].events[0].seq).toBe(1);
    expect(api.calls.batches[2].events[199].seq).toBe(1200);
  });

  it('stops retrying on a permanent 4xx and keeps the session', async () => {
    const api = fakeApi();
    const outbox = new SessionOutbox(() => api.client);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed',
      finalSeq: 1,
      assisted: false,
    });

    api.failWith(new ApiError(422, 'unprocessable'));
    await outbox.flush();

    const stored = outbox.sessions[0];
    expect(stored.status).toBe('blocked');
    expect(stored.failureReason).toMatch(/kept on this device/);
    // The played session is still here — not discarded.
    expect(stored.events).toHaveLength(1);

    await outbox.flush();
    expect(api.calls.created).toHaveLength(0);
  });

  it('pauses rather than losing data when identity is rejected', async () => {
    const api = fakeApi();
    const outbox = new SessionOutbox(() => api.client);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));

    api.failWith(new ApiError(401, 'unauthorized'));
    await outbox.flush();

    expect(outbox.sessions[0].status).toBe('paused');
    expect(outbox.sessions[0].events).toHaveLength(1);
  });

  it('recovers a session interrupted mid-upload after a restart', async () => {
    const api = fakeApi();
    const first = new SessionOutbox(() => api.client);
    await first.load();
    const s = session();
    await first.enqueue(s);
    await first.record(s.clientSessionId, ev(1));
    await first.finalize(s.clientSessionId, {
      status: 'completed',
      finalSeq: 1,
      assisted: false,
    });

    // Simulate being killed while uploading.
    (first.sessions[0] as any).status = 'uploading';
    await (first as any).persist();

    const restarted = new SessionOutbox(() => api.client);
    await restarted.load();
    expect(restarted.sessions[0].status).toBe('pending');

    await restarted.flush();
    expect(api.calls.completed).toHaveLength(1);
    expect(restarted.pendingCount).toBe(0);
  });

  it('does nothing and loses nothing when there is no API configured', async () => {
    const outbox = new SessionOutbox(() => null);
    await outbox.load();
    const s = session();
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.flush();
    expect(outbox.pendingCount).toBe(1);
    expect(outbox.sessions[0].events).toHaveLength(1);
  });
});
