import {
  TesseractEventRecorder,
  GameLifecycleEvent,
  GameResultStatus,
} from '../contract';

describe('TesseractEventRecorder invariants', () => {
  const recorder = () => {
    let now = 0;
    const r = new TesseractEventRecorder(() => now);
    return { r, tick: (ms: number) => (now += ms) };
  };

  it('numbers events from 1 with no gaps', () => {
    const { r } = recorder();
    expect(r.sessionStarted().seq).toBe(1);
    expect(r.custom('word_found', { wordId: 'w1' }).seq).toBe(2);
    expect(r.custom('word_found', { wordId: 'w2' }).seq).toBe(3);
    expect(r.lastSeq).toBe(3);
  });

  it('excludes paused time from the session clock', () => {
    const { r, tick } = recorder();
    r.sessionStarted();
    tick(1000);
    r.paused();
    tick(5000); // a long break must not count
    r.resumed();
    tick(500);
    expect(r.elapsedMs).toBe(1500);
  });

  it('marks the session assisted once Help is used, permanently', () => {
    const { r } = recorder();
    r.sessionStarted();
    expect(r.assisted).toBe(false);
    r.hintRequested();
    expect(r.assisted).toBe(true);
    r.custom('word_found', { wordId: 'w1' });
    expect(r.assisted).toBe(true);
  });

  it('refuses a second finalization', () => {
    const { r } = recorder();
    r.sessionStarted();
    r.sessionFinished(GameResultStatus.completed);
    expect(() => r.sessionFinished(GameResultStatus.completed)).toThrow(
      /finalises exactly once|after session_finished/,
    );
  });

  it('refuses any event after the session finished', () => {
    const { r } = recorder();
    r.sessionStarted();
    r.sessionFinished(GameResultStatus.completed);
    expect(() => r.custom('word_found', { wordId: 'w1' })).toThrow();
  });

  it('refuses an invalid status', () => {
    const { r } = recorder();
    r.sessionStarted();
    // @ts-expect-error deliberately invalid at runtime
    expect(() => r.sessionFinished('finished-ish')).toThrow(/not a valid/);
  });

  it('refuses a lifecycle type through custom()', () => {
    const { r } = recorder();
    r.sessionStarted();
    expect(() => r.custom(GameLifecycleEvent.paused)).toThrow(/lifecycle/);
  });

  it('refuses session_started twice', () => {
    const { r } = recorder();
    r.sessionStarted();
    expect(() => r.sessionStarted()).toThrow(/first event/);
  });

  it('builds a result only after finishing', () => {
    const { r } = recorder();
    r.sessionStarted();
    expect(() => r.result(GameResultStatus.completed)).toThrow();
    r.hintRequested();
    r.sessionFinished(GameResultStatus.stoppedByUser);
    expect(r.result(GameResultStatus.stoppedByUser)).toEqual({
      status: 'stopped_by_user',
      finalSeq: 3,
      assisted: true,
    });
  });
});
