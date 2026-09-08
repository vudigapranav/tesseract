/**
 * Optional tap-to-speak input — and an honest account of why it cannot work
 * in Expo Go today.
 *
 * ## The limitation, stated plainly
 *
 * Speech recognition on iOS is `SFSpeechRecognizer`, a native API. Reaching it
 * from React Native needs a native module, and every available one
 * (`expo-speech-recognition`, `@react-native-voice/voice`) ships a config
 * plugin that modifies the native iOS project. Expo Go runs a **fixed** native
 * binary from the App Store; it cannot load a module that was not compiled
 * into it. So:
 *
 *   **On-device speech recognition is impossible in Expo Go. Full stop.**
 *
 * This is not a missing feature to be worked around with a clever library —
 * it is a property of the runtime the user asked for. The Flutter build has
 * working tap-to-speak because it compiles its own binary.
 *
 * ## What this module does instead
 *
 * It reports the limitation through the same interface the UI would use for a
 * real recogniser, so:
 *
 *  - Every text and touch path stays exactly as it was. Nothing was removed to
 *    make room for voice.
 *  - The UI can explain, in the patient's own language, that speaking is not
 *    available — rather than showing a microphone button that does nothing.
 *  - The confirmation-before-acting contract is already written and tested, so
 *    when a recogniser becomes available the safety behaviour does not have to
 *    be invented under time pressure.
 *
 * ## The two ways to actually get voice input
 *
 *  1. **A development build or TestFlight build** with `expo-speech-recognition`.
 *     Keeps audio on the device. Costs the Expo Go workflow.
 *  2. **Record in Expo Go, transcribe on the backend.** `expo-audio` records
 *     fine in Expo Go. This sends a patient's voice to a third party, needs
 *     provider selection, a credential that must live server-side, and a cost
 *     conversation — and for four of the five NER languages no major provider
 *     lists support anyway. Not implemented, and not to be implemented without
 *     an explicit decision.
 */
import type { LanguageCode } from '../l10n/languages';
import { matrixRow } from './capability';

export type VoiceInputFailure =
  | 'permissionDenied'
  | 'permissionPermanentlyDenied'
  | 'recognitionUnavailable'
  | 'recognitionUnavailableInExpoGo'
  | 'languageUnavailable'
  | 'timeout'
  | 'cancelled'
  | 'network'
  | 'engineError';

export interface VoiceInputResult {
  transcript: string;
  confidence?: number;
  failure?: VoiceInputFailure;
}

export type VoicePhase =
  | 'idle'
  | 'requestingPermission'
  | 'listening'
  | 'awaitingConfirmation'
  | 'failed';

/**
 * The seam a real recogniser would implement. Kept so the UI, the tests and
 * the confirmation contract are written against an interface rather than
 * against "nothing", and so swapping in a native recogniser later is a
 * one-file change.
 */
export interface SpeechRecognizer {
  /** Whether this runtime can recognise speech at all. */
  isAvailable(): Promise<boolean>;
  /** Locale ids the recogniser offers. */
  locales(): Promise<string[]>;
  hasPermission(): Promise<boolean>;
  requestPermission(): Promise<boolean>;
  listenOnce(opts: {
    localeId: string;
    listenForMs: number;
  }): Promise<VoiceInputResult>;
  cancel(): Promise<void>;
}

/**
 * The recogniser Expo Go actually has: none.
 *
 * It fails with a distinct reason so the UI can explain the *runtime*
 * limitation rather than blaming the language or the device.
 */
export class ExpoGoUnavailableRecognizer implements SpeechRecognizer {
  async isAvailable(): Promise<boolean> {
    return false;
  }
  async locales(): Promise<string[]> {
    return [];
  }
  async hasPermission(): Promise<boolean> {
    return false;
  }
  async requestPermission(): Promise<boolean> {
    // Never asks for the microphone. Requesting a permission the app cannot
    // use would be a prompt with nothing behind it.
    return false;
  }
  async listenOnce(): Promise<VoiceInputResult> {
    return { transcript: '', failure: 'recognitionUnavailableInExpoGo' };
  }
  async cancel(): Promise<void> {}
}

/**
 * Drives one tap-to-speak interaction.
 *
 * Even with no recogniser present, the rules are encoded and tested here so
 * they cannot be lost later:
 *
 *  - Nothing listens until the user taps. No wake word, no ambient capture.
 *  - The microphone is requested at point of use, never at startup.
 *  - A language with no recogniser fails as unavailable, never by listening
 *    in a different language.
 *  - **Nothing is saved or executed from a transcript alone.** The text is
 *    returned for the user to confirm; `confirm()` is the only way out.
 *  - Recognised words never reach analytics or logs.
 */
export class VoiceInputController {
  private phaseValue: VoicePhase = 'idle';
  private transcriptValue = '';
  private failureValue: VoiceInputFailure | null = null;
  private disposed = false;
  private listeners = new Set<() => void>();

  constructor(
    private readonly recognizer: SpeechRecognizer,
    private readonly listenForMs = 12000,
  ) {}

  get phase(): VoicePhase {
    return this.phaseValue;
  }
  /** What was heard, pending confirmation. Empty at every other phase. */
  get transcript(): string {
    return this.transcriptValue;
  }
  get failure(): VoiceInputFailure | null {
    return this.failureValue;
  }
  get isListening(): boolean {
    return this.phaseValue === 'listening';
  }

  subscribe(fn: () => void): () => void {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  private set(phase: VoicePhase) {
    if (this.disposed) return;
    this.phaseValue = phase;
    this.listeners.forEach((l) => l());
  }

  private fail(f: VoiceInputFailure) {
    if (this.disposed) return;
    this.failureValue = f;
    this.transcriptValue = '';
    this.set('failed');
  }

  /** Whether `code` could be recognised here. */
  async probe(code: LanguageCode): Promise<boolean> {
    if (!(await this.recognizer.isAvailable())) return false;
    const wanted = matrixRow(code)?.preferredTags ?? [];
    if (wanted.length === 0) return false;
    const offered = await this.recognizer.locales();
    const { resolveEngineTag } = await import('./capability');
    return wanted.some((t) => resolveEngineTag(t, offered) !== undefined);
  }

  /** Starts one listen. Only ever called from a tap. */
  async start(languageCode: LanguageCode): Promise<void> {
    if (this.phaseValue === 'listening' || this.phaseValue === 'requestingPermission') {
      return;
    }
    this.transcriptValue = '';
    this.failureValue = null;
    this.set('requestingPermission');

    if (!(await this.recognizer.isAvailable())) {
      // Distinct from "this language has no recogniser": the runtime has none
      // at all, and the UI says so in those terms.
      this.fail('recognitionUnavailableInExpoGo');
      return;
    }

    if (!(await this.recognizer.hasPermission())) {
      if (!(await this.recognizer.requestPermission())) {
        this.fail('permissionDenied');
        return;
      }
    }

    const wanted = matrixRow(languageCode)?.preferredTags ?? [];
    const offered = await this.recognizer.locales();
    const { resolveEngineTag } = await import('./capability');
    let localeId: string | undefined;
    for (const t of wanted) {
      const m = resolveEngineTag(t, offered);
      if (m) {
        localeId = m;
        break;
      }
    }
    if (!localeId) {
      // Resolved before listening, so an unsupported language fails cleanly
      // instead of the recogniser quietly choosing its default locale.
      this.fail('languageUnavailable');
      return;
    }

    this.set('listening');
    const result = await this.recognizer.listenOnce({
      localeId,
      listenForMs: this.listenForMs,
    });
    // Read through the getter: the user may have cancelled while the
    // recogniser was busy, and narrowing across the await would hide that.
    const phaseNow: VoicePhase = this.phase;
    if (this.disposed || phaseNow !== 'listening') return;

    if (result.failure || result.transcript.trim().length === 0) {
      this.fail(result.failure ?? 'timeout');
      return;
    }
    this.transcriptValue = result.transcript.trim();
    this.set('awaitingConfirmation');
  }

  async cancel(): Promise<void> {
    await this.recognizer.cancel();
    this.transcriptValue = '';
    this.failureValue = 'cancelled';
    this.set('idle');
  }

  /** The user rejected the transcript. Same as never having spoken. */
  discard(): void {
    this.transcriptValue = '';
    this.failureValue = null;
    this.set('idle');
  }

  /**
   * The user confirmed. Returns the text and clears it, so one utterance
   * cannot be applied twice by accident.
   */
  confirm(): string {
    const text = this.transcriptValue;
    this.transcriptValue = '';
    this.failureValue = null;
    this.set('idle');
    return text;
  }

  dispose(): void {
    this.disposed = true;
    void this.recognizer.cancel();
    this.transcriptValue = '';
  }
}
