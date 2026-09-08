import { ScopedStore, CorruptDataError, patientKey } from '../storage';

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

beforeEach(() => mockStore.clear());

describe('storage is bound to one identity', () => {
  it('keeps two caregivers apart', async () => {
    const a = new ScopedStore('caregiver-a');
    const b = new ScopedStore('caregiver-b');
    await a.write('patients', [{ id: 'p1' }]);
    expect(await b.read('patients', [])).toEqual([]);
    expect(await a.read('patients', [])).toEqual([{ id: 'p1' }]);
  });

  it('a write started under one identity cannot land in another', async () => {
    // The defect: the destination used to be a module-level mutable read at
    // await time, so signing out mid-write redirected it.
    const a = new ScopedStore('caregiver-a');
    const write = a.write('prefs', { audioEnabled: false });
    // "Sign out" happens while that is in flight.
    const b = new ScopedStore('caregiver-b');
    await write;
    expect(await b.read('prefs', null)).toBeNull();
    expect(await a.read('prefs', null)).toEqual({ audioEnabled: false });
  });

  it('partitions per patient inside one caregiver', async () => {
    const s = new ScopedStore('caregiver-a');
    await s.write(patientKey('p1', 'reminders'), [{ id: 'r1' }]);
    expect(await s.read(patientKey('p2', 'reminders'), [])).toEqual([]);
  });

  it('device-level keys are shared, identity keys are not', async () => {
    const a = new ScopedStore('caregiver-a');
    const b = new ScopedStore('caregiver-b');
    await a.write('interfaceLanguage', 'hi');
    expect(await b.read('interfaceLanguage', 'en')).toBe('hi');
  });
});

describe('corrupt data is surfaced, not swallowed', () => {
  it('throws rather than returning a clean empty value', async () => {
    const s = new ScopedStore('caregiver-a');
    mockStore.set('tesseract:caregiver-a:sessionOutbox', 'not json');
    await expect(s.read('sessionOutbox', [])).rejects.toBeInstanceOf(
      CorruptDataError,
    );
  });

  it('quarantines rather than deleting, so data stays recoverable', async () => {
    const s = new ScopedStore('caregiver-a');
    mockStore.set('tesseract:caregiver-a:knowMe', '{ broken');
    await s.quarantine('knowMe');
    expect(mockStore.get('tesseract:caregiver-a:knowMe')).toBeUndefined();
    const kept = [...mockStore.entries()].find(([k]) => k.includes(':corrupt:'));
    expect(kept?.[1]).toBe('{ broken');
  });

  it('tolerates corruption only where a caller opts in', async () => {
    const s = new ScopedStore('caregiver-a');
    mockStore.set('tesseract:caregiver-a:prefs', 'oops');
    expect(await s.tryRead('prefs', { audioEnabled: true })).toEqual({
      value: { audioEnabled: true },
      corrupt: true,
    });
  });

  it('clears only its own scope on sign-out', async () => {
    const a = new ScopedStore('caregiver-a');
    const b = new ScopedStore('caregiver-b');
    await a.write('patients', [1]);
    await b.write('patients', [2]);
    await a.clear();
    expect(await a.read('patients', [])).toEqual([]);
    expect(await b.read('patients', [])).toEqual([2]);
  });
});
