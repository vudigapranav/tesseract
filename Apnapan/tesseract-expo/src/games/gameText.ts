/**
 * In-game strings and placeholder activity content.
 *
 * **These are English-only, and that is a real limitation, not an oversight.**
 *
 * The Flutter build has the same gap: `localizedGameStrings` localises only the
 * six shared control labels (Help, Break, the pause overlay, Continue, Finish
 * for now) from the ARB files, and the game-specific wording is English
 * literals. Rather than invent ARB keys and claim translation coverage that has
 * not been written or reviewed, the same boundary is kept here and stated
 * plainly, so the measured coverage figures stay truthful.
 *
 * To translate these properly: add them to `Apnapan/host/lib/l10n/app_en.arb`,
 * translate them per language, re-run `node tools/sync-l10n.mjs`, and read them
 * through `translate()` like everything else. Coverage will drop until the
 * translations actually exist, which is the correct signal.
 */
export const GAME_TEXT_EN: Record<string, string> = {
  route_go_to: 'Go to',
  route_return_home: 'Now go back home',
  route_you_are_here: 'You are here',
  route_destination: 'Where you are going',
  maze_title: 'Guide the marble',
  maze_hold_still: 'Hold the phone still for a moment.',
  maze_touch_mode: 'Use your finger to move the marble.',
  maze_motion_mode: 'Tilt the phone to move the marble.',
  words_find: 'Find these words',
  words_unavailable: 'There are no words to find yet.',
  words_some_did_not_fit: 'Some words did not fit on this grid.',
  routine_what_next: 'What comes next?',
  routine_try_again: 'Not quite. Have another look.',
  routine_unavailable: 'There is no routine set up yet.',
  sorting_where_does_this_go: 'Where does this go?',
  sorting_try_again: 'Not quite. Have another look.',
  sorting_unavailable: 'There are no pictures to sort yet.',
  category_kitchen: 'Kitchen',
  category_outside: 'Outside',
};

/**
 * Placeholder activity content, used until a caregiver uploads Know Me
 * personalization. Generic on purpose and labelled as generic in the
 * caregiver's Know Me screen — never presented as something they entered.
 */
export const PLACEHOLDER_CONTENT: Record<
  string,
  Array<{ id: string; label: string; extra?: Record<string, unknown> }>
> = {
  route_quest: [
    { id: 'n0', label: 'Home' },
    { id: 'n1', label: 'The shop' },
    { id: 'n2', label: 'The garden' },
    { id: 'n3', label: 'The kitchen' },
    { id: 'n4', label: 'The gate' },
    { id: 'n5', label: 'The window' },
  ],
  routine_recall: [
    { id: 's1', label: 'Wake up' },
    { id: 's2', label: 'Wash your face' },
    { id: 's3', label: 'Have breakfast' },
    { id: 's4', label: 'Go for a short walk' },
    { id: 's5', label: 'Sit and rest' },
  ],
  word_search: [
    { id: 'w1', label: 'TEA' },
    { id: 'w2', label: 'RICE' },
    { id: 'w3', label: 'SUN' },
    { id: 'w4', label: 'RAIN' },
    { id: 'w5', label: 'HOME' },
  ],
  picture_sorting: [
    { id: 'i1', label: 'Teacup', extra: { categoryId: 'kitchen' } },
    { id: 'i2', label: 'Rice pot', extra: { categoryId: 'kitchen' } },
    { id: 'i3', label: 'Flower', extra: { categoryId: 'outside' } },
    { id: 'i4', label: 'Umbrella', extra: { categoryId: 'outside' } },
  ],
  marble_maze: [],
};
