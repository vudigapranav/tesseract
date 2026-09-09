/**
 * The synthetic demonstration profile.
 *
 * One family, used consistently everywhere a demonstration needs a person:
 * **Kamala**, 72, the patient, and her daughter **Bidisha**, the caregiver.
 * That pairing is the project's established sample family (`By claude/CLAUDE.md`),
 * and reusing it is the point — a demo that invents a new name per screen
 * reads as a collection of mockups rather than one app.
 *
 * Three rules govern this file, and each exists because the opposite would be
 * a real failure:
 *
 *  1. **Preview scope only.** Seeding is called from the explicitly-labelled
 *     preview entry, which has its own storage scope. It can never run in a
 *     signed-in caregiver's scope, so it cannot touch a real profile.
 *  2. **Idempotent.** A marker records that seeding happened. Re-entering
 *     preview does not create a second Kamala, and never overwrites edits made
 *     to the seeded profile during a demonstration.
 *  3. **No fabricated history.** This seeds *content* — a person, her places,
 *     her routine, her words. It seeds **no sessions, no observations and no
 *     analysis**. An empty analysis screen before anyone has played is the
 *     honest state, and manufacturing progress to fill a card would be
 *     inventing clinical-looking data about a person who does not exist.
 *
 * The content is everyday North-Eastern household life — a courtyard, the
 * tulsi plant, rice and tea — chosen to be ordinary rather than picturesque.
 * It avoids anything that would read as a regional stereotype, and it is all
 * generic: no real address, no real family detail, nothing traceable.
 */
import type { ScopedStore } from './storage';
import type { KnowMeContent, KnowMeEntry } from './knowMe';
import { saveKnowMe } from './knowMe';

/** Stable id, so re-seeding recognises the same patient rather than adding one. */
export const DEMO_PATIENT_ID = 'demo-kamala';
export const DEMO_CAREGIVER_NAME = 'Bidisha';

const SEED_MARKER = 'demoSeedVersion';
/** Bump only to reseed a *fresh* preview scope; it never overwrites edits. */
const SEED_VERSION = 1;

export interface DemoPatient {
  id: string;
  displayName: string;
  language: 'en';
  ageYears: number;
  notes: string;
}

export const DEMO_PATIENT: DemoPatient = {
  id: DEMO_PATIENT_ID,
  displayName: 'Kamala',
  language: 'en',
  ageYears: 72,
  // Deliberately not a diagnosis or a stage. This is the kind of note a
  // daughter writes, and it is what the caregiver screens are for.
  notes: 'Likes the afternoon. Quieter after dark.',
};

/**
 * Kamala's world.
 *
 * Places are for Route Quest, steps for Daily Routine, words for Word Search
 * and pictures for the sorting and pair activities. The same objects recur
 * across them on purpose: a cup in her routine and a cup on a card is what
 * makes the content feel like one person's life instead of four word lists.
 */
const ENTRIES: Array<Omit<KnowMeEntry, 'id'> & { id: string }> = [
  // Places — index 0 is home, which Route Quest relies on.
  { id: 'demo-place-1', kind: 'place', label: 'Home', locale: 'en' },
  { id: 'demo-place-2', kind: 'place', label: 'The courtyard', locale: 'en' },
  { id: 'demo-place-3', kind: 'place', label: 'The kitchen', locale: 'en' },
  { id: 'demo-place-4', kind: 'place', label: 'The tulsi plant', locale: 'en' },
  { id: 'demo-place-5', kind: 'place', label: 'The front gate', locale: 'en' },
  { id: 'demo-place-6', kind: 'place', label: 'The verandah', locale: 'en' },

  // A day, in the order she keeps it. Not a universal "correct" routine.
  { id: 'demo-step-1', kind: 'step', label: 'Wake up', locale: 'en' },
  { id: 'demo-step-2', kind: 'step', label: 'Wash your face', locale: 'en' },
  { id: 'demo-step-3', kind: 'step', label: 'Morning tea', locale: 'en' },
  { id: 'demo-step-4', kind: 'step', label: 'Water the tulsi', locale: 'en' },
  { id: 'demo-step-5', kind: 'step', label: 'Sit on the verandah', locale: 'en' },

  // Short, familiar, and spellable in the Latin grid Word Search builds.
  { id: 'demo-word-1', kind: 'word', label: 'TEA', locale: 'en' },
  { id: 'demo-word-2', kind: 'word', label: 'RICE', locale: 'en' },
  { id: 'demo-word-3', kind: 'word', label: 'HOME', locale: 'en' },
  { id: 'demo-word-4', kind: 'word', label: 'RAIN', locale: 'en' },
  { id: 'demo-word-5', kind: 'word', label: 'SUN', locale: 'en' },

  // Pictures carry a category, which Picture Sorting needs.
  { id: 'demo-pic-1', kind: 'picture', label: 'Teacup', categoryId: 'kitchen', locale: 'en' },
  { id: 'demo-pic-2', kind: 'picture', label: 'Rice pot', categoryId: 'kitchen', locale: 'en' },
  { id: 'demo-pic-3', kind: 'picture', label: 'Tulsi plant', categoryId: 'outside', locale: 'en' },
  { id: 'demo-pic-4', kind: 'picture', label: 'Umbrella', categoryId: 'outside', locale: 'en' },
];

export function demoKnowMe(): KnowMeContent {
  return {
    entries: ENTRIES.map((e) => ({ ...e })),
    version: 1,
    // Synthetic content must never be pushed to a server as though a caregiver
    // had entered it, so it is not marked as having local edits to upload.
    dirty: false,
    localVersion: 'demo-v1',
  };
}

/**
 * Seeds the preview scope, once.
 *
 * Returns the patient id when there is a demonstration patient to select —
 * whether this call created it or a previous one did — and null when the
 * caller should leave the scope alone.
 *
 * Anything already in the scope wins. If a previous demonstration renamed
 * Kamala or added a place, that is what the next one shows.
 */
export async function seedDemoScope(store: ScopedStore): Promise<string | null> {
  // Guard: this must only ever run in the preview scope. A bug that called it
  // with a caregiver's store would write synthetic content into real data.
  if (store.scope !== 'preview') return null;

  const seeded = await store.tryRead<number>(SEED_MARKER, 0);
  const existing = await store.tryRead<Array<{ id: string }>>('patients', []);
  const alreadyThere = existing.value.some((p) => p.id === DEMO_PATIENT_ID);

  if (seeded.value >= SEED_VERSION && alreadyThere) {
    // Already seeded, and Kamala is still here. Select her and change nothing.
    return DEMO_PATIENT_ID;
  }
  if (alreadyThere) {
    await store.write(SEED_MARKER, SEED_VERSION);
    return DEMO_PATIENT_ID;
  }

  await store.write('patients', [...existing.value, DEMO_PATIENT]);
  await saveKnowMe(store, DEMO_PATIENT_ID, demoKnowMe());
  await store.write('selectedPatient', DEMO_PATIENT_ID);
  await store.write('patientLanguage', DEMO_PATIENT.language);
  await store.write(SEED_MARKER, SEED_VERSION);
  return DEMO_PATIENT_ID;
}
