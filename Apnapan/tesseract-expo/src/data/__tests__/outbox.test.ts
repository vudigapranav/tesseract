import { SessionOutbox, createOutboxSession, type SessionSnapshot } from '../outbox';
import { ApiError, MAX_EVENT_BATCH, type EventBatchOut } from '../apiClient';
import { ScopedStore } from '../storage';
import type { GameEvent } from '../../games/contract';

jest.mock('expo-crypto', () => {
  let n = 0;
  return { randomUUID: () => `id-${++n}` };
});

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

const snapshot: SessionSnapshot = {
  patientId: 'patient-1',
  gameId: 'word_search',
  gameVersion: '1.0.0',
  schemaVersion: '1',
  configVersion: '7',
  contentVersion: 'local-abc',
  metricVersion: '1',
  level: 2,
  difficultyParams: { gridSize: 8 },
  requestedInputMode: 'touch',
  isTutorial: false,
  textScale: 1,
  locale: 'hi',
};

const okBatch = (ids: string[]): EventBatchOut => ({
  accepted: ids,
  duplicate: [],
  rejected: [],
  highest_seq: null,
  missing_seqs: [],
});

function fakeApi() {
  const calls = {
    put: [] as Array<{ id: string; body: unknown }>,
    batches: [] as Array<{ events: any[] }>,
    completed: [] as unknown[],
  };
  let nextError: Error | null = null;
  let batchResponder: ((events: any[]) => EventBatchOut) | null = null;

  return {
    calls,
    failWith(e: Error) {
      nextError = e;
    },
    respondToBatch(fn: (events: any[]) => EventBatchOut) {
      batchResponder = fn;
    },
    client: {
      putSession: jest.fn(async (id: string, body: unknown) => {
        if (nextError) {
          const e = nextError;
          nextError = null;
          throw e;
        }
        calls.put.push({ id, body });
        return { session_id: id, created: calls.put.length === 1 } as any;
      }),
      uploadEvents: jest.fn(async (_id: string, events: any[]) => {
        if (nextError) {
          const e = nextError;
          nextError = null;
          throw e;
        }
        if (events.length > MAX_EVENT_BATCH) throw new Error('batch too large');
        calls.batches.push({ events });
        return batchResponder
          ? batchResponder(events)
          : okBatch(events.map((e) => e.event_id));
      }),
      completeSession: jest.fn(async (id: string, body: unknown) => {
        if (nextError) {
          const e = nextError;
          nextError = null;
          throw e;
        }
        calls.completed.push({ id, body });
        return {} as any;
      }),
    } as any,
  };
}

const store = () => new ScopedStore('caregiver-a');
const make = (api: any, now = () => 1_000_000) =>
  new SessionOutbox(store(), () => api, now);

beforeEach(() => mockStore.clear());

describe('the frozen session snapshot reaches the server', () => {
  it('sends the real config and content versions, not a placeholder', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 1, assisted: false,
    });
    await outbox.flush();

    const body = api.calls.put[0].body as Record<string, unknown>;
    expect(body.patient_id).toBe('patient-1');
    expect(body.game_version).toBe('1.0.0');
    expect(body.requested_input_mode).toBe('touch');
    // The defect: these were hardcoded 'local-v1' while the game ran
    // something else.
    expect(body.config_version).toBe('7');
    expect(body.content_version).toBe('local-abc');
    expect(body.locale).toBe('hi');
  });

  it('never fabricates actual_input_mode', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.flush();
    expect(api.calls.put[0].body).not.toHaveProperty('actual_input_mode');
  });

  it('creates the session with PUT and its own client-owned id', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.flush();
    expect(api.client.putSession).toHaveBeenCalled();
    expect(api.calls.put[0].id).toBe(s.clientSessionId);
  });
});

describe('events carry when they happened', () => {
  it('stamps occurred_at at record time and preserves it on replay', async () => {
    const api = fakeApi();
    let now = 1_000_000;
    const outbox = make(api.client, () => now);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    const recordedAt = new Date(now).toISOString();

    // The upload fails, time passes, and the retry must not rewrite history.
    api.failWith(new ApiError(0, 'offline'));
    await outbox.flush();
    now += 60 * 60 * 1000;
    await outbox.flush();

    expect(api.calls.batches[0].events[0].occurred_at).toBe(recordedAt);
  });
});

describe('upload progress follows what the server confirmed', () => {
  it('does not advance past events the server rejected', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.record(s.clientSessionId, ev(2));

    // HTTP 200, but only one event was taken. The old code counted both.
    api.respondToBatch((events) => ({
      accepted: [events[0].event_id],
      duplicate: [],
      rejected: [{ event_id: events[1].event_id, reason: 'bad_payload' }],
      highest_seq: 1,
      missing_seqs: [],
    }));

    await outbox.flush();

    const stored = outbox.sessions[0];
    expect(stored.confirmedEventIds).toHaveLength(1);
    expect(stored.rejected).toEqual([
      { eventId: expect.any(String), reason: 'bad_payload' },
    ]);
    expect(stored.failureReason).toMatch(/refused/);
  });

  it('treats duplicates as confirmed, so a lost response settles', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));

    api.respondToBatch((events) => ({
      accepted: [],
      duplicate: [events[0].event_id],
      rejected: [],
      highest_seq: 1,
      missing_seqs: [],
    }));

    await outbox.flush();
    expect(outbox.sessions[0].confirmedEventIds).toHaveLength(1);
  });

  it('stops rather than spinning when a batch confirms nothing', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));

    api.respondToBatch(() => ({
      accepted: [], duplicate: [], rejected: [], highest_seq: null, missing_seqs: [],
    }));

    await outbox.flush();
    // One attempt, not an endless loop.
    expect(api.calls.batches.length).toBe(1);
    expect(outbox.sessions[0].status).not.toBe('synced');
  });

  it('never sends more than 500 in a batch, in order', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    for (let i = 1; i <= 1200; i++) await outbox.record(s.clientSessionId, ev(i));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 1200, assisted: false,
    });
    await outbox.flush();

    expect(api.calls.batches.map((b) => b.events.length)).toEqual([500, 500, 200]);
    expect(api.calls.batches[0].events[0].seq).toBe(1);
    expect(api.calls.batches[2].events[199].seq).toBe(1200);
  });
});

describe('finalization is exactly once', () => {
  it('refuses events after the session is completed', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 0, assisted: false,
    });
    await expect(outbox.record(s.clientSessionId, ev(1))).rejects.toThrow(
      /after session .* was finalized/,
    );
  });

  it('refuses a conflicting second completion', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 1, assisted: false,
    });
    await expect(
      outbox.finalize(s.clientSessionId, {
        status: 'stopped_by_user', finalSeq: 1, assisted: false,
      }),
    ).rejects.toThrow(/already completed/);
  });

  it('completes once even across a lost response and a replay', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 1, assisted: false,
    });

    await outbox.flush();
    await outbox.flush();
    await outbox.flush();

    expect(api.calls.completed).toHaveLength(1);
  });
});

describe('failure handling keeps data and stays actionable', () => {
  it('backs off rather than retrying instantly', async () => {
    const api = fakeApi();
    let now = 1_000_000;
    const outbox = make(api.client, () => now);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));

    api.failWith(new ApiError(0, 'offline'));
    await outbox.flush();
    expect(outbox.sessions[0].nextAttemptAt).toBeGreaterThan(now);

    // Too soon: skipped entirely.
    const before = api.client.putSession.mock.calls.length;
    await outbox.flush();
    expect(api.client.putSession.mock.calls.length).toBe(before);

    now += 60_000;
    await outbox.flush();
    expect(api.client.putSession.mock.calls.length).toBeGreaterThan(before);
  });

  it('blocks on a permanent refusal but keeps the played session', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));

    api.failWith(new ApiError(422, 'unprocessable'));
    await outbox.flush();

    expect(outbox.sessions[0].status).toBe('blocked');
    expect(outbox.sessions[0].events).toHaveLength(1);
    expect(outbox.blocked).toHaveLength(1);
  });

  it('offers an actionable retry out of blocked', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    api.failWith(new ApiError(422, 'no'));
    await outbox.flush();

    await outbox.retryBlocked();
    expect(outbox.sessions[0].status).toBe('pending');
    await outbox.flush();
    expect(outbox.sessions[0].confirmedEventIds).toHaveLength(1);
  });

  it('pauses rather than losing data when identity is rejected', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    api.failWith(new ApiError(401, 'unauthorized'));
    await outbox.flush();
    expect(outbox.sessions[0].status).toBe('paused');
    expect(outbox.sessions[0].events).toHaveLength(1);
  });
});

describe('durability across restart and concurrency', () => {
  it('recovers a session interrupted mid-upload', async () => {
    const api = fakeApi();
    const first = make(api.client);
    await first.load();
    const s = createOutboxSession(snapshot);
    await first.enqueue(s);
    await first.record(s.clientSessionId, ev(1));
    await first.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 1, assisted: false,
    });
    (first.sessions[0] as { status: string }).status = 'uploading';
    await (first as unknown as { persist: () => Promise<void> }).persist();

    const restarted = make(api.client);
    await restarted.load();
    expect(restarted.sessions[0].status).toBe('pending');
    await restarted.flush();
    expect(api.calls.completed).toHaveLength(1);
  });

  it('does not let two flushes overlap and double-send', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 1, assisted: false,
    });

    await Promise.all([outbox.flush(), outbox.flush(), outbox.flush()]);
    expect(api.calls.completed).toHaveLength(1);
    expect(api.calls.batches).toHaveLength(1);
  });

  it('abandons an in-flight flush when the account changes', async () => {
    const api = fakeApi();
    const outbox = make(api.client);
    await outbox.load();
    const s = createOutboxSession(snapshot);
    await outbox.enqueue(s);
    await outbox.record(s.clientSessionId, ev(1));
    await outbox.finalize(s.clientSessionId, {
      status: 'completed', finalSeq: 1, assisted: false,
    });

    const controller = new AbortController();
    controller.abort();
    await outbox.flush(controller.signal);
    expect(api.calls.completed).toHaveLength(0);
  });

  it('quarantines corrupt data instead of starting cleanly empty', async () => {
    mockStore.set('tesseract:caregiver-a:sessionOutbox', '{ not json');
    const outbox = make(fakeApi().client);
    await outbox.load();

    expect(outbox.hadCorruptData).toBe(true);
    // The unreadable document is kept aside, not destroyed.
    const quarantined = [...mockStore.keys()].filter((k) =>
      k.includes(':corrupt:'),
    );
    expect(quarantined).toHaveLength(1);
  });
});

describe('identity isolation', () => {
  it('keeps two caregivers’ queues apart', async () => {
    const api = fakeApi();
    const a = new SessionOutbox(new ScopedStore('caregiver-a'), () => api.client);
    await a.load();
    await a.enqueue(createOutboxSession(snapshot));

    const b = new SessionOutbox(new ScopedStore('caregiver-b'), () => api.client);
    await b.load();

    expect(a.sessions).toHaveLength(1);
    expect(b.sessions).toHaveLength(0);
  });
});

describe('remaining audit regressions', () => {
  it('captures snapshots and events before callers can mutate them', async () => {
    const o = make(fakeApi().client); await o.load();
    const config = { ...snapshot, difficultyParams: { gridSize: 8 } };
    const s = createOutboxSession(config);
    config.difficultyParams.gridSize = 99;
    await o.enqueue(s);
    s.snapshot.level = 99;
    const event = ev(1); const saving = o.record(s.clientSessionId, event);
    event.payload.wordId = 'mutated'; await saving;
    expect(o.sessions[0].snapshot.level).toBe(2);
    expect(o.sessions[0].snapshot.difficultyParams.gridSize).toBe(8);
    expect(o.sessions[0].events[0].event.payload.wordId).toBe('w1');
  });
  it('keeps completion time stable after a genuinely lost completion response', async () => {
    const api = fakeApi(); let now = 1000000;
    const o = make(api.client, () => now); await o.load();
    const s = createOutboxSession(snapshot); await o.enqueue(s); await o.record(s.clientSessionId, ev(1));
    await o.finalize(s.clientSessionId, {status: 'completed', finalSeq: 1, assisted: false});
    const bodies: any[] = [];
    api.client.completeSession.mockImplementation(async (_id: string, body: any) => {
      bodies.push(body); if (bodies.length === 1) throw new ApiError(0, 'lost response'); return {};
    });
    await o.flush(); now += 60000; await o.flush();
    expect(bodies).toHaveLength(2); expect(bodies[0]).toEqual(bodies[1]);
    expect(bodies[0].ended_at).toBe(new Date(1000000).toISOString());
  });
  it('does not complete rejected batches and resends them only on explicit retry', async () => {
    const api = fakeApi(); const o = make(api.client); await o.load();
    const s = createOutboxSession(snapshot); await o.enqueue(s); await o.record(s.clientSessionId, ev(1));
    await o.finalize(s.clientSessionId, {status: 'completed', finalSeq: 1, assisted: false});
    api.respondToBatch(es => ({...okBatch([]), rejected: [{event_id: es[0].event_id, reason:'rejected'}]}));
    await o.flush(); expect(api.calls.completed).toHaveLength(0); expect(o.sessions[0].status).toBe('blocked');
    api.respondToBatch(es => okBatch(es.map(e => e.event_id)));
    await o.retryBlocked(); await o.flush(); expect(api.calls.completed).toHaveLength(1);
  });
  it('rejects acknowledgements for events outside the submitted batch', async () => {
    const api = fakeApi(); const o = make(api.client); await o.load();
    const s = createOutboxSession(snapshot); await o.enqueue(s); await o.record(s.clientSessionId, ev(1));
    api.respondToBatch(() => okBatch(['foreign-id'])); await o.flush();
    expect(o.sessions[0].confirmedEventIds).toEqual([]); expect(o.sessions[0].status).toBe('blocked');
  });
  it('recovers killed play as interrupted with the last observed time', async () => {
    const o = make(null); await o.load(); const s = createOutboxSession(snapshot);
    await o.enqueue(s); await o.record(s.clientSessionId, ev(1));
    const restarted = make(null); await restarted.load();
    expect(restarted.sessions[0].result).toEqual({status:'interrupted', finalSeq:1, assisted:false});
    expect(restarted.sessions[0].endedAt).toBe(restarted.sessions[0].events[0].occurredAt);
  });
});
