/** Native AES-GCM; only the small random key lives in SecureStore. */
import { AESEncryptionKey, AESSealedData, aesEncryptAsync, aesDecryptAsync } from 'expo-crypto';
import { getKeyMaterial, setKeyMaterial } from './secureKeyStore';
const KEY_NAME = 'apnapan.storage.aes256.v1';
const MARKER = 'apnapan.aesgcm.v1:';
let creating: Promise<AESEncryptionKey> | null = null;
export class StorageLockedError extends Error {
  constructor() { super('Saved data could not be unlocked. It has been preserved.'); }
}
async function key(create: boolean): Promise<AESEncryptionKey> {
  const saved = await getKeyMaterial(KEY_NAME);
  if (saved) return AESEncryptionKey.import(saved, 'base64');
  if (!create) throw new StorageLockedError();
  if (!creating) {
    creating = (async () => {
      const generated = await AESEncryptionKey.generate();
      await setKeyMaterial(KEY_NAME, await generated.encoded('base64'));
      return generated;
    })().finally(() => { creating = null; });
  }
  return creating;
}
export async function sealStorage(address: string, plaintext: string): Promise<string> {
  const sealed = await aesEncryptAsync(new TextEncoder().encode(plaintext), await key(true), {
    additionalData: new TextEncoder().encode(address),
  });
  return MARKER + await sealed.combined('base64');
}
export async function openStorage(address: string, raw: string): Promise<string> {
  // Existing plaintext remains readable for non-destructive migration on write.
  if (!raw.startsWith(MARKER)) return raw;
  try {
    const bytes = await aesDecryptAsync(AESSealedData.fromCombined(decodeSealedBytes(raw.slice(MARKER.length))), await key(false), {
      additionalData: new TextEncoder().encode(address),
    });
    return new TextDecoder().decode(bytes);
  } catch { throw new StorageLockedError(); }
}

/** Android's native fromCombined requires ByteArray even though JS accepts strings. */
function decodeSealedBytes(base64: string): Uint8Array {
  const binary = atob(base64);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}
