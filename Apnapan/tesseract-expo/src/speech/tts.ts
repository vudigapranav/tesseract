/**
 * Optional spoken output, in the patient's own language or not at all.
 *
 * Rules this module exists to enforce:
 *
 *  - **Never speak the wrong language.** If no voice exists for the patient's
 *    language, the app says so in text and stays quiet. It does not read Mizo
 *    aloud with an English voice because both use Latin letters.
 *  - **Never speak over itself.** One utterance at a time.
 *  - **Never speak when the caregiver turned sound off.**
 *  - **Never keep speaking into the background.**
 *  - Speech is additive. Every word it reads is already on screen and every
 *    action stays reachable by touch.
 *
 * Backed by expo-speech, which is bundled in Expo Go — no development build.
 */
import * as Speech from 'expo-speech';
import { resolveEngineTag, tagsFor, type SpeechProbe } from './capability';

export type SpeechUnavailableReason =
  | 'audioOff'
  | 'noEngine'
  | 'noVoiceForLanguage'
  | 'engineError';

export interface SpeechAvailability {
  isAvailable: boolean;
  reason?: SpeechUnavailableReason;
  resolvedTag?: string;
}

const available = (resolvedTag: string): SpeechAvailability => ({
  isAvailable: true,
  resolvedTag,
});
const unavailable = (reason: SpeechUnavailableReason): SpeechAvailability => ({
  isAvailable: false,
  reason,
});

export class SpeechOutputService {
  private probes = new Map<string, SpeechProbe>();
  private voiceTags: string[] | null = null;
  private speaking = false;
  private generation = 0;
  private listeners = new Set<() => void>();

  constructor(private readonly audioEnabled: () => boolean) {}

  get isSpeaking(): boolean {
    return this.speaking;
  }

  get probeResults(): ReadonlyMap<string, SpeechProbe> {
    return this.probes;
  }

  subscribe(fn: () => void): () => void {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  private notify() {
    this.listeners.forEach((l) => l());
  }

  /** Voice language tags this device really offers. Cached after the first ask. */
  private async engineTags(): Promise<string[]> {
    if (this.voiceTags) return this.voiceTags;
    try {
      const voices = await Speech.getAvailableVoicesAsync();
      this.voiceTags = voices.map((v) => v.language);
    } catch {
      // An engine that cannot enumerate is treated as offering nothing, which
      // routes every language to the explicit "speech unavailable" path.
      this.voiceTags = [];
    }
    return this.voiceTags;
  }

  /** Asks the device, once per language, whether it can speak `code`. */
  async probe(code: string): Promise<SpeechProbe> {
    const cached = this.probes.get(code);
    if (cached) return cached;

    const wanted = tagsFor(code);
    if (wanted.length === 0) {
      // A language the matrix does not describe. Refusing is right: guessing
      // a tag is how you end up speaking the wrong language.
      const miss: SpeechProbe = { code, direction: 'output', available: false };
      this.probes.set(code, miss);
      return miss;
    }

    const offered = await this.engineTags();
    for (const tag of wanted) {
      const match = resolveEngineTag(tag, offered);
      if (!match) continue;
      const hit: SpeechProbe = {
        code,
        direction: 'output',
        available: true,
        resolvedTag: match,
      };
      this.probes.set(code, hit);
      return hit;
    }

    const miss: SpeechProbe = { code, direction: 'output', available: false };
    this.probes.set(code, miss);
    return miss;
  }

  /** Whether a speak control should be offered for `code`, and if not, why. */
  async availability(code: string): Promise<SpeechAvailability> {
    if (!this.audioEnabled()) return unavailable('audioOff');
    const offered = await this.engineTags();
    if (offered.length === 0) return unavailable('noEngine');
    const p = await this.probe(code);
    return p.available
      ? available(p.resolvedTag as string)
      : unavailable('noVoiceForLanguage');
  }

  /**
   * Speaks `text` in `languageCode`.
   *
   * Returns the availability that was applied, so the caller can show the
   * reason inline when nothing was spoken. A repeat call while speaking stops
   * the previous utterance first — that is the replay behaviour, and it is
   * also what keeps two utterances off the speaker at once.
   */
  async speak(text: string, languageCode: string): Promise<SpeechAvailability> {
    const a = await this.availability(languageCode);
    if (!a.isAvailable) {
      await this.stop();
      return a;
    }
    await this.stop();
    const generation = ++this.generation;

    this.speaking = true;
    this.notify();

    return new Promise<SpeechAvailability>((resolve) => {
      const settle = () => {
        // Only the utterance that is still current may clear the flag,
        // otherwise the control flickers back to "play" under a live one.
        if (generation === this.generation) {
          this.speaking = false;
          this.notify();
        }
        resolve(a);
      };
      try {
        Speech.speak(text, {
          language: a.resolvedTag,
          onDone: settle,
          onStopped: settle,
          onError: () => {
            if (generation === this.generation) {
              this.speaking = false;
              this.notify();
            }
            resolve(unavailable('engineError'));
          },
        });
      } catch {
        this.speaking = false;
        this.notify();
        resolve(unavailable('engineError'));
      }
    });
  }

  /** Stops at once. Safe when nothing is speaking. */
  async stop(): Promise<void> {
    this.generation++;
    try {
      await Speech.stop();
    } catch {
      // Nothing to stop is not an error worth surfacing.
    }
    if (this.speaking) {
      this.speaking = false;
      this.notify();
    }
  }

  /**
   * The app left the foreground, or a patient session ended.
   *
   * Speech must not continue out of a backgrounded app: it would talk over
   * whatever the person opened next, and a reminder read aloud after handover
   * could be heard by someone the caregiver did not intend.
   */
  handleAppBackgrounded(): Promise<void> {
    return this.stop();
  }

  /** The selected language changed; drop the bound voice and stop. */
  handleLanguageChanged(): Promise<void> {
    return this.stop();
  }
}
