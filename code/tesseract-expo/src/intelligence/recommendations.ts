/**
 * The activity suggestion layer.
 *
 * This is the app's "intelligence", and it is deliberately **deterministic and
 * explainable**, not a model. Every suggestion is derived from sessions the
 * person actually played, and every one carries the reason in plain words that
 * a caregiver can check against what they saw.
 *
 * Three rules it will not break:
 *
 *  - **It never changes anything on its own.** A suggestion is a proposal. The
 *    caregiver accepts, changes or rejects it, and only that decision moves the
 *    patient's activity.
 *  - **It never invents a measure.** With too little history it says so and
 *    suggests nothing, rather than producing a confident-looking number from
 *    two data points.
 *  - **It is not clinical.** No cognitive score, no diagnosis, no progression.
 *    The wording is about the activity, never about the person's condition.
 */
import type { OutboxSession } from '../data/outbox';

export interface ActivitySignal {
  gameId: string;
  sessions: number;
  completed: number;
  assisted: number;
  stoppedEarly: number;
  /** Median duration in ms across completed sessions. */
  medianMs: number | null;
  lastLevel: number;
}

export type SuggestionKind =
  | 'raiseLevel'
  | 'lowerLevel'
  | 'keepLevel'
  | 'tryDifferent'
  | 'notEnoughData';

export interface Suggestion {
  id: string;
  gameId: string;
  kind: SuggestionKind;
  currentLevel: number;
  proposedLevel: number;
  /** Plain-language reason, shown verbatim to the caregiver. */
  reason: string;
  /** What the caregiver should weigh that the app cannot see. */
  caveat: string;
}

/** How many finished sessions before any suggestion is offered at all. */
export const MIN_SESSIONS_FOR_SUGGESTION = 4;

function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const s = [...values].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 === 0 ? Math.round((s[mid - 1] + s[mid]) / 2) : s[mid];
}

/** Summarises real sessions per activity. No inference, just counting. */
export function signalsFrom(sessions: readonly OutboxSession[]): ActivitySignal[] {
  const byGame = new Map<string, OutboxSession[]>();
  for (const s of sessions) {
    if (!s.completed || !s.result) continue;
    const list = byGame.get(s.gameId) ?? [];
    list.push(s);
    byGame.set(s.gameId, list);
  }

  return [...byGame.entries()].map(([gameId, list]) => {
    const completed = list.filter((s) => s.result?.status === 'completed');
    const durations = completed
      .map((s) => {
        const last = s.events[s.events.length - 1];
        return last?.elapsedMs ?? 0;
      })
      .filter((ms) => ms > 0);

    return {
      gameId,
      sessions: list.length,
      completed: completed.length,
      assisted: list.filter((s) => s.result?.assisted).length,
      stoppedEarly: list.filter((s) => s.result?.status === 'stopped_by_user')
        .length,
      medianMs: median(durations),
      lastLevel: list[list.length - 1]?.level ?? 1,
    };
  });
}

/**
 * Turns signals into at most one suggestion per activity.
 *
 * The thresholds are conservative on purpose. Getting this wrong in the
 * confident direction means making an activity harder for someone who was
 * already struggling, which is a bad day for a real person — so the bar for
 * raising a level is higher than the bar for lowering one.
 */
export function suggestionsFrom(
  signals: readonly ActivitySignal[],
  maxLevelFor: (gameId: string) => number,
): Suggestion[] {
  const out: Suggestion[] = [];

  for (const s of signals) {
    if (s.sessions < MIN_SESSIONS_FOR_SUGGESTION) {
      out.push({
        id: `${s.gameId}-insufficient`,
        gameId: s.gameId,
        kind: 'notEnoughData',
        currentLevel: s.lastLevel,
        proposedLevel: s.lastLevel,
        reason: `Only ${s.sessions} finished ${
          s.sessions === 1 ? 'session' : 'sessions'
        } so far. That is not enough to suggest a change.`,
        caveat: 'Nothing changes until there is more to go on.',
      });
      continue;
    }

    const completionRate = s.completed / s.sessions;
    const assistedRate = s.assisted / s.sessions;
    const maxLevel = maxLevelFor(s.gameId);

    // Finishing nearly everything, rarely needing Help, and not at the top.
    if (
      completionRate >= 0.8 &&
      assistedRate <= 0.25 &&
      s.lastLevel < maxLevel
    ) {
      out.push({
        id: `${s.gameId}-raise`,
        gameId: s.gameId,
        kind: 'raiseLevel',
        currentLevel: s.lastLevel,
        proposedLevel: s.lastLevel + 1,
        reason: `Finished ${s.completed} of the last ${s.sessions} and used Help in ${s.assisted}. A slightly larger version may suit better.`,
        caveat:
          'You have seen how these went; the app has not. If it felt like hard work, keep it as it is.',
      });
      continue;
    }

    // Stopping early often, or leaning on Help most of the time.
    if (completionRate <= 0.4 || assistedRate >= 0.7) {
      if (s.lastLevel > 1) {
        out.push({
          id: `${s.gameId}-lower`,
          gameId: s.gameId,
          kind: 'lowerLevel',
          currentLevel: s.lastLevel,
          proposedLevel: s.lastLevel - 1,
          reason: `Stopped early in ${s.stoppedEarly} of the last ${s.sessions} and used Help in ${s.assisted}. A smaller version may feel better.`,
          caveat: 'A calmer session is a good session. This is not a setback.',
        });
      } else {
        out.push({
          id: `${s.gameId}-different`,
          gameId: s.gameId,
          kind: 'tryDifferent',
          currentLevel: s.lastLevel,
          proposedLevel: s.lastLevel,
          reason: `Already at the smallest version, and ${s.stoppedEarly} of the last ${s.sessions} ended early. A different activity may suit better today.`,
          caveat: 'Preferences change day to day. This is worth your judgement, not the app’s.',
        });
      }
      continue;
    }

    out.push({
      id: `${s.gameId}-keep`,
      gameId: s.gameId,
      kind: 'keepLevel',
      currentLevel: s.lastLevel,
      proposedLevel: s.lastLevel,
      reason: `Finished ${s.completed} of the last ${s.sessions}. This size looks about right.`,
      caveat: 'No change suggested.',
    });
  }

  return out;
}

/** A caregiver's decision. Only this changes what a patient is offered. */
export interface Decision {
  suggestionId: string;
  gameId: string;
  decision: 'accepted' | 'modified' | 'rejected';
  /** The level the caregiver actually chose. */
  level: number;
  decidedAt: string;
  /** Revision the decision was made against, for conflict detection. */
  basedOnRevision?: string;
}

/**
 * Human-readable summary of observed activity.
 *
 * Deterministic template text. If the backend's LLM summariser is ever enabled
 * it may only *rephrase* this — it does not get to compute or assert anything
 * of its own, and this stays the fallback.
 */
export function describeSignal(s: ActivitySignal, gameName: string): string {
  const parts: string[] = [
    `${gameName}: ${s.sessions} finished ${s.sessions === 1 ? 'session' : 'sessions'}`,
  ];
  parts.push(`${s.completed} completed`);
  if (s.stoppedEarly > 0) parts.push(`${s.stoppedEarly} ended early`);
  if (s.assisted > 0) parts.push(`Help used in ${s.assisted}`);
  if (s.medianMs) {
    parts.push(`typically about ${Math.round(s.medianMs / 1000)} seconds`);
  }
  return `${parts.join(' · ')}.`;
}
