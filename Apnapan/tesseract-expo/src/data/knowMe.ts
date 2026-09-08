/**
 * Know Me: the caregiver's own content, and how it reaches the games.
 *
 * This is the heart of what makes the activities personal — the places someone
 * actually walks to, the steps of their real morning, the words that mean
 * something to them. Two rules hold throughout:
 *
 *  - **Original script is preserved.** A caregiver typing in Assamese gets
 *    Assamese back, untouched. Nothing is transliterated or "normalised".
 *  - **None of it ever reaches telemetry.** Games receive it as `GameItem`
 *    labels and emit only the opaque `id`. Every game test asserts this.
 */
import type { GameItem } from '../games/contract';
import { patientKey, type ScopedStore } from './storage';

export type KnowMeKind = 'place' | 'step' | 'word' | 'picture';

export interface KnowMeEntry {
  id: string;
  kind: KnowMeKind;
  /** Exactly what the caregiver typed, in their script. */
  label: string;
  /** For pictures: which category it belongs to. */
  categoryId?: string;
  /** Language the caregiver entered this in, so it renders with the right face. */
  locale?: string;
}

export interface KnowMeContent {
  entries: KnowMeEntry[];
  /**
   * Server `version` this was last synced from — an integer, matching
   * `PersonalizationIn`. Used for conflict-aware uploads; a 409 keeps local
   * edits rather than overwriting them.
   */
  version: number;
  /** True when there are local edits the server has not seen. */
  dirty: boolean;
  /** Bumped locally so a session can report the content it actually used. */
  localVersion: string;
}

const KEY = 'knowMe';

export const emptyKnowMe = (): KnowMeContent => ({
  entries: [],
  version: 1,
  dirty: false,
  localVersion: 'local-v1',
});

/** Partitioned per patient, so one patient's content never feeds another's. */
export const loadKnowMe = (
  store: ScopedStore,
  patientId: string,
): Promise<KnowMeContent> =>
  store
    .tryRead<KnowMeContent>(patientKey(patientId, KEY), emptyKnowMe())
    .then((r) => r.value);

export async function saveKnowMe(
  store: ScopedStore,
  patientId: string,
  content: KnowMeContent,
): Promise<void> {
  await store.write(patientKey(patientId, KEY), content);
}

/**
 * The server's personalization shape.
 *
 * `personal_words` and `people_places` are separate lists with different
 * schemas, so the flat local entry list is split rather than sent as an
 * invented `entries` array.
 *
 * Routine steps and sorting categories have **no approved server
 * representation**. They stay local and are deliberately not smuggled into
 * `preferences` — that needs a contract decision from Pranav, not a client
 * inventing a payload. See docs/handoffs/PRANAV_BACKEND_GAPS.md.
 */
export function toPersonalizationBody(content: KnowMeContent) {
  return {
    version: content.version,
    personal_words: content.entries
      .filter((e) => e.kind === 'word')
      .map((e) => ({ text: e.label, locale: e.locale ?? 'en' })),
    people_places: content.entries
      .filter((e) => e.kind === 'place')
      .map((e) => ({ kind: 'place' as const, label: e.label })),
    preferences: {},
  };
}

/** Kinds the server can store today. The rest are local-only, and say so. */
export const SERVER_BACKED_KINDS: readonly KnowMeKind[] = ['word', 'place'];

/** A new local content version, so a session records what it really used. */
export const bumpLocalVersion = (): string =>
  `local-${Date.now().toString(36)}`;

/**
 * Categories offered for Picture Sorting.
 *
 * Deliberately a small fixed set rather than free text: the category id ends
 * up in an event payload, so it must be structural vocabulary the caregiver
 * picks from, not something they type. That keeps personal wording out of
 * telemetry by construction rather than by filtering.
 */
export const PICTURE_CATEGORIES = [
  { id: 'kitchen', labelKey: 'Kitchen' },
  { id: 'outside', labelKey: 'Outside' },
  { id: 'bedroom', labelKey: 'Bedroom' },
] as const;

const MINIMUMS: Record<string, { kind: KnowMeKind; min: number }> = {
  route_quest: { kind: 'place', min: 3 },
  routine_recall: { kind: 'step', min: 3 },
  word_search: { kind: 'word', min: 3 },
  picture_sorting: { kind: 'picture', min: 4 },
  // Four, because the hardest level lays out four pairs and every pair needs
  // its own picture.
  reveal_match: { kind: 'picture', min: 4 },
  marble_maze: { kind: 'place', min: 0 },
};

/** Whether a game has enough real content to run on the caregiver's own words. */
export function hasEnoughContent(
  content: KnowMeContent,
  gameId: string,
): boolean {
  const rule = MINIMUMS[gameId];
  if (!rule || rule.min === 0) return true;
  return content.entries.filter((e) => e.kind === rule.kind).length >= rule.min;
}

export function countFor(content: KnowMeContent, kind: KnowMeKind): number {
  return content.entries.filter((e) => e.kind === kind).length;
}

/**
 * Turns Know Me content into the items a game receives.
 *
 * Returns null when there is not enough real content, so the caller can fall
 * back to the generic placeholder set **and say that it is doing so** — rather
 * than silently mixing two sentences of the caregiver's with filler and
 * presenting the result as personalised.
 */
export function itemsForGame(
  content: KnowMeContent,
  gameId: string,
): GameItem[] | null {
  if (!hasEnoughContent(content, gameId)) return null;
  const rule = MINIMUMS[gameId];
  if (!rule) return null;

  const of = (kind: KnowMeKind) =>
    content.entries.filter((e) => e.kind === kind);

  switch (gameId) {
    case 'route_quest':
      // Order is the caregiver's; index 0 is home.
      return of('place').map((e) => ({ id: e.id, label: e.label }));
    case 'routine_recall':
      // The correct order is the order they saved.
      return of('step').map((e) => ({ id: e.id, label: e.label }));
    case 'word_search':
      return of('word').map((e) => ({ id: e.id, label: e.label }));
    case 'reveal_match':
      // No category needed: this game only asks whether two cards show the
      // same picture, so a picture without a group is still usable here.
      return of('picture').map((e) => ({ id: e.id, label: e.label }));
    case 'picture_sorting':
      return of('picture')
        .filter((e) => !!e.categoryId)
        .map((e) => ({
          id: e.id,
          label: e.label,
          extra: { categoryId: e.categoryId },
        }));
    default:
      return null;
  }
}
