/**
 * Phone-motion input for Marble Maze, over expo-sensors DeviceMotion.
 *
 * `DeviceMotion` is bundled in Expo Go, so this works on a plain Expo Go
 * install with no development build. It reports a fused orientation rather
 * than raw gyroscope rates, which is what a tilt-a-marble game actually wants.
 *
 * Two things this module is careful about:
 *
 *  - **Calibration.** The neutral position is whatever the phone is at when
 *    play starts, not "flat on a table". Someone in a chair holds a phone at
 *    an angle, and calibrating to flat would make the marble drift constantly.
 *  - **Honesty about the mode actually used.** `available` reflects whether
 *    motion really produced samples on this device. The host reports the mode
 *    that was genuinely in effect; it is never fabricated.
 */
import { DeviceMotion } from 'expo-sensors';

export interface TiltSample {
  /** Left/right, negative is left. Roughly -1..1 after scaling. */
  x: number;
  /** Forward/back, negative is away from the player. */
  y: number;
}

export interface MotionSubscription {
  remove: () => void;
}

/** Samples below this are treated as a resting hand, not an intent to move. */
export const TILT_DEAD_ZONE = 0.035;

/** Grid cells per second at full tilt. Ported from the Flutter tuning. */
export const TILT_GRID_UNITS_PER_SECOND = 2.65;

/** Samples averaged to establish the neutral hold before the marble moves. */
export const CALIBRATION_SAMPLES = 12;

export async function isMotionAvailable(): Promise<boolean> {
  try {
    return await DeviceMotion.isAvailableAsync();
  } catch {
    return false;
  }
}

/**
 * Subscribes to device motion, emitting calibrated tilt.
 *
 * `onReady` fires once calibration completes, so the UI can say "hold still"
 * and then "go" rather than having the marble lurch on the first frame.
 */
export function subscribeTilt({
  onSample,
  onReady,
  intervalMs = 33,
}: {
  onSample: (s: TiltSample) => void;
  onReady?: () => void;
  intervalMs?: number;
}): MotionSubscription {
  let neutralX = 0;
  let neutralY = 0;
  let sumX = 0;
  let sumY = 0;
  let samples = 0;
  let ready = false;

  DeviceMotion.setUpdateInterval(intervalMs);
  const sub = DeviceMotion.addListener((data) => {
    const rotation = data?.rotation;
    if (!rotation) return;
    // gamma is roll (left/right), beta is pitch (forward/back).
    const rawX = rotation.gamma ?? 0;
    const rawY = rotation.beta ?? 0;

    if (!ready) {
      sumX += rawX;
      sumY += rawY;
      samples += 1;
      if (samples >= CALIBRATION_SAMPLES) {
        neutralX = sumX / samples;
        neutralY = sumY / samples;
        ready = true;
        onReady?.();
      }
      return;
    }

    onSample(applyDeadZone({ x: rawX - neutralX, y: rawY - neutralY }));
  });

  return { remove: () => sub.remove() };
}

/** Zeroes tiny movements so a resting hand does not creep the marble. */
export function applyDeadZone(s: TiltSample): TiltSample {
  return {
    x: Math.abs(s.x) < TILT_DEAD_ZONE ? 0 : s.x,
    y: Math.abs(s.y) < TILT_DEAD_ZONE ? 0 : s.y,
  };
}
