jest.mock('@react-native-async-storage/async-storage', () => require('@react-native-async-storage/async-storage/jest/async-storage-mock'));
import { ScopedStore } from '../storage';
import { sealStorage, openStorage } from '../storageCipher';
import * as SecureStore from 'expo-secure-store';
jest.unmock('../storageCipher');
// Real AES-GCM through Node, mirroring Expo's native byte API. Device bridge is separate QA.
jest.mock('expo-crypto', () => {
  const c = require('node:crypto');
  return {
    AESEncryptionKey: {
      generate: async () => { const bytes = c.randomBytes(32); return { bytes, encoded: () => Promise.resolve(bytes.toString('base64')) }; },
      import: async (s: string) => ({ bytes: Buffer.from(s, 'base64') }),
    },
    AESSealedData: { fromCombined: (bytes: Uint8Array) => {
      // Android's native fromCombined takes ByteArray, not a Base64 string.
      if (!(bytes instanceof Uint8Array)) throw new Error('Android requires bytes');
      return Buffer.from(bytes);
    } },
    aesEncryptAsync: async (data: Uint8Array, key: any, options: any) => {
      const iv = c.randomBytes(12); const cipher = c.createCipheriv('aes-256-gcm', key.bytes, iv);
      cipher.setAAD(Buffer.from(options.additionalData));
      const combined = Buffer.concat([iv, cipher.update(data), cipher.final(), cipher.getAuthTag()]);
      return { combined: async () => combined.toString('base64') };
    },
    aesDecryptAsync: async (data: Buffer, key: any, options: any) => {
      const cipher = c.createDecipheriv('aes-256-gcm', key.bytes, data.subarray(0, 12));
      cipher.setAAD(Buffer.from(options.additionalData)); cipher.setAuthTag(data.subarray(-16));
      return Buffer.concat([cipher.update(data.subarray(12, -16)), cipher.final()]);
    },
  };
});
let stored: string | null;
beforeEach(() => {
  stored = null;
  (SecureStore.getItemAsync as jest.Mock).mockImplementation(async () => stored);
  (SecureStore.setItemAsync as jest.Mock).mockImplementation(async (_k: string, v: string) => { stored = v; });
});
it('encrypts multilingual content with fresh nonces and round-trips', async () => {
  const plain = JSON.stringify({label: 'अपनापन বাংলা ꯃꯤ'});
  const a = await sealStorage('account:patient:queue', plain);
  const b = await sealStorage('account:patient:queue', plain);
  expect(a).not.toContain('अपनापन'); expect(a).not.toBe(b);
  expect(await openStorage('account:patient:queue', a)).toBe(plain);
});
it('authenticates the account/patient/document address', async () => {
  const sealed = await sealStorage('alice:patient-a', 'private');
  await expect(openStorage('bob:patient-a', sealed)).rejects.toThrow(/preserved/);
});
it('refuses modified ciphertext and a missing key without replacement', async () => {
  const sealed = await sealStorage('alice', 'private');
  const cut = sealed.indexOf(':', 15) + 1;
  const changed = sealed.slice(0, cut + 20) + (sealed[cut + 20] === 'A' ? 'B' : 'A') + sealed.slice(cut + 21);
  await expect(openStorage('alice', changed)).rejects.toThrow();
  stored = null; const calls = (SecureStore.setItemAsync as jest.Mock).mock.calls.length;
  await expect(openStorage('alice', sealed)).rejects.toThrow(/preserved/);
  expect((SecureStore.setItemAsync as jest.Mock).mock.calls.length).toBe(calls);
});
it('preserves legacy plaintext for non-destructive migration', async () => {
  expect(await openStorage('alice', '{"old":true}')).toBe('{"old":true}');
});

it('saves, reopens, selects and edits a patient using the Android byte contract', async () => {
  const store = new ScopedStore('android-save-regression');
  const patient = { id: 'p1', displayName: 'कमला', ageYears: 72, language: 'hi' };
  await store.write('patients', [patient]);
  const reopened = new ScopedStore('android-save-regression');
  expect(await reopened.read('patients', [])).toEqual([patient]);
  await reopened.write('selectedPatient', patient.id);
  await reopened.write('patientLanguage', patient.language);
  await reopened.write('patients', [{ ...patient, ageYears: 73 }]);
  expect(await reopened.read('patients', [])).toEqual([{ ...patient, ageYears: 73 }]);
  expect(await reopened.read('selectedPatient', '')).toBe('p1');
});
