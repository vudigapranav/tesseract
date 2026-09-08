/**
 * The activity registry.
 *
 * **Catalogue status, stated plainly:** this ships FOUR of the NINE required
 * games — Route Quest (G2), Marble Maze (G3), Word Search (G7) and Daily
 * Routine Recall (G8) — plus Picture Sorting as an extra activity.
 *
 * Still missing, and owned by Aryan: Reveal Match (G1), Trace (G4),
 * Coloring (G5), Spot Difference (G6) and Picture Recall (G9). They are not
 * stubbed, faked or approximated here. When their repositories are available
 * they get integrated through this registry and the shared contract, with
 * ownership preserved.
 */
import type React from 'react';
import type { TesseractGameProps } from './contract';
import { RouteQuestGame, ROUTE_QUEST_ID, routeQuestDifficultyParams } from './routeQuest/RouteQuestGame';
import { MarbleMazeGame, MARBLE_MAZE_ID } from './marbleMaze/MarbleMazeGame';
import { marbleMazeDifficultyParams } from './marbleMaze/level';
import { WordSearchGame, WORD_SEARCH_ID, wordSearchDifficultyParams } from './wordSearch/WordSearchGame';
import { RoutineRecallGame, ROUTINE_RECALL_ID, routineRecallDifficultyParams } from './routineRecall/RoutineRecallGame';
import { PictureSortingGame, PICTURE_SORTING_ID, pictureSortingDifficultyParams } from './pictureSorting/PictureSortingGame';

export interface GameRegistration {
  gameId: string;
  /** Key into the string catalogue for the display name. */
  displayNameKey: string;
  /** Key for the instruction shown before play. */
  instructionKey: string;
  /** Whether this is one of the nine required games or an extra. */
  required: boolean;
  /** Who designed and owns the activity. */
  owner: string;
  component: React.ComponentType<TesseractGameProps>;
  difficultyParamsForLevel: (level: number) => Record<string, unknown>;
  /** Motion-first activities declare it, so the host can offer calibration. */
  motionFirst?: boolean;
  maxLevel: number;
}

export const GAME_REGISTRY: readonly GameRegistration[] = [
  {
    gameId: ROUTE_QUEST_ID,
    displayNameKey: 'gameRouteQuest',
    instructionKey: 'howToPlayRouteQuest',
    required: true,
    owner: 'Ruthika',
    component: RouteQuestGame,
    difficultyParamsForLevel: routeQuestDifficultyParams,
    maxLevel: 3,
  },
  {
    gameId: MARBLE_MAZE_ID,
    displayNameKey: 'gameMarbleMaze',
    instructionKey: 'howToPlayMarbleMazeTilt',
    required: true,
    owner: 'Ruthika',
    component: MarbleMazeGame,
    difficultyParamsForLevel: marbleMazeDifficultyParams,
    motionFirst: true,
    maxLevel: 3,
  },
  {
    gameId: WORD_SEARCH_ID,
    displayNameKey: 'gameWordSearch',
    instructionKey: 'howToPlayWordSearch',
    required: true,
    owner: 'Ruthika',
    component: WordSearchGame,
    difficultyParamsForLevel: wordSearchDifficultyParams,
    maxLevel: 3,
  },
  {
    gameId: ROUTINE_RECALL_ID,
    displayNameKey: 'gameRoutineRecall',
    instructionKey: 'howToPlayRoutineRecall',
    required: true,
    owner: 'Ruthika',
    component: RoutineRecallGame,
    difficultyParamsForLevel: routineRecallDifficultyParams,
    maxLevel: 3,
  },
  {
    gameId: PICTURE_SORTING_ID,
    displayNameKey: 'gamePictureSorting',
    instructionKey: 'howToPlayPictureSorting',
    required: false,
    owner: 'Ruthika',
    component: PictureSortingGame,
    difficultyParamsForLevel: pictureSortingDifficultyParams,
    maxLevel: 3,
  },
];

/** The nine required games, by id, so the gap stays countable in code. */
export const REQUIRED_GAME_IDS = [
  'reveal_match',
  'route_quest',
  'marble_maze',
  'trace',
  'coloring',
  'spot_difference',
  'word_search',
  'routine_recall',
  'picture_recall',
] as const;

export const MISSING_REQUIRED_GAME_IDS = REQUIRED_GAME_IDS.filter(
  (id) => !GAME_REGISTRY.some((g) => g.gameId === id),
);

export const registrationFor = (gameId: string) =>
  GAME_REGISTRY.find((g) => g.gameId === gameId);
