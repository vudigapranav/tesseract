/**
 * Decides when the opening screen should be shown.
 *
 * The whole difficulty here is telling a *genuine* reopen from an interruption.
 * iOS sends the same lifecycle events for both, so a naive
 * "show it whenever we become active" would flash the brand at someone every
 * time Face ID appears, a permission dialog opens, or they pull down the
 * notification shade — and during an activity that is not just ugly, it
 * interrupts someone mid-task.
 *
 * Two things separate them:
 *
 *  - **`inactive` is not `background`.** A biometric prompt, the app switcher
 *    preview, a permission sheet and the notification shade all put the app in
 *    `inactive`. Only a real departure reaches `background`.
 *  - **Time away.** Even a real background can be momentary — dismissing a
 *    notification, glancing at the shade. A short absence is not a reopen.
 *
 * Showing the screen never unmounts anything: the app tree stays mounted
 * underneath, so routes, form text, authentication and a running game keep
 * their state and their timing.
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import { AppState, type AppStateStatus } from 'react-native';

/**
 * How long the app must be genuinely backgrounded before returning counts as
 * reopening. Below this it is treated as an interruption.
 */
export const REOPEN_AFTER_MS = 90_000;

export interface OpeningController {
  /** Whether the opening screen should currently be on screen. */
  visible: boolean;
  /** Called by the opening screen once its hold has elapsed and app is ready. */
  dismiss: () => void;
}

export function useOpeningScreen({
  enabled = true,
  reopenAfterMs = REOPEN_AFTER_MS,
}: { enabled?: boolean; reopenAfterMs?: number } = {}): OpeningController {
  // Shown on the first render of a fresh launch or reload.
  const [visible, setVisible] = useState(enabled);
  const backgroundedAt = useRef<number | null>(null);
  const appState = useRef<AppStateStatus>(AppState.currentState);

  const dismiss = useCallback(() => setVisible(false), []);

  useEffect(() => {
    if (!enabled) return;

    const onChange = (next: AppStateStatus) => {
      const previous = appState.current;
      appState.current = next;

      if (next === 'background') {
        // Only a real background starts the clock. `inactive` deliberately
        // does not, because that is what a biometric prompt looks like.
        backgroundedAt.current = Date.now();
        return;
      }

      if (next === 'active') {
        const since = backgroundedAt.current;
        backgroundedAt.current = null;

        // Came back from `inactive` without ever backgrounding: an
        // interruption, not a reopen.
        if (since === null) return;
        if (previous !== 'background' && previous !== 'inactive') return;

        if (Date.now() - since >= reopenAfterMs) setVisible(true);
      }
    };

    const sub = AppState.addEventListener('change', onChange);
    return () => sub.remove();
  }, [enabled, reopenAfterMs]);

  return { visible, dismiss };
}

/**
 * The pure decision, extracted so it can be tested without a running app.
 *
 * Returns true when a transition into `active` should re-show the brand.
 */
export function shouldReopen({
  previous,
  next,
  backgroundedAt,
  now,
  reopenAfterMs = REOPEN_AFTER_MS,
}: {
  previous: AppStateStatus;
  next: AppStateStatus;
  /** When the app last genuinely backgrounded, or null if it did not. */
  backgroundedAt: number | null;
  now: number;
  reopenAfterMs?: number;
}): boolean {
  if (next !== 'active') return false;
  if (backgroundedAt === null) return false;
  if (previous !== 'background' && previous !== 'inactive') return false;
  return now - backgroundedAt >= reopenAfterMs;
}
