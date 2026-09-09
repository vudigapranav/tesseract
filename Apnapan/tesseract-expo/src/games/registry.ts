/**
 * The activity registry.
 *
 * **Catalogue status, stated plainly:** all NINE required games are registered
 * and playable, plus Picture Sorting as an extra:
 *
 *   G1 Reveal Match     Aryan    ported from Flutter `reveal_match`
 *   G2 Route Quest      Ruthika
 *   G3 Marble Maze      Ruthika
 *   G4 Trace            Aryan    ported from Flutter `trace`
 *   G5 Coloring         Aryan    ported from Flutter `swipe_reveal`
 *   G6 Spot Difference  Aryan    ported from Flutter `spot_difference`
 *   G7 Word Search      Ruthika
 *   G8 Routine Recall   Ruthika
 *   G9 Picture Recall   Aryan    ported from Flutter `picture_recall`
 *
 * `MISSING_REQUIRED_GAME_IDS` is now empty, and the test suite asserts that
 * rather than trusting this comment. Registration is not the same as polish:
 * see `PS003_MOBILE_CODE_STATUS.md` for what has and has not been exercised on
 * a real device.
 */
import type React from 'react';
import type { TesseractGameProps } from './contract';
import { RouteQuestGame, ROUTE_QUEST_ID, routeQuestDifficultyParams } from './routeQuest/RouteQuestGame';
import { MarbleMazeGame, MARBLE_MAZE_ID } from './marbleMaze/MarbleMazeGame';
import { marbleMazeDifficultyParams } from './marbleMaze/level';
import { WordSearchGame, WORD_SEARCH_ID, wordSearchDifficultyParams } from './wordSearch/WordSearchGame';
import { RoutineRecallGame, ROUTINE_RECALL_ID, routineRecallDifficultyParams } from './routineRecall/RoutineRecallGame';
import { PictureSortingGame, PICTURE_SORTING_ID, pictureSortingDifficultyParams } from './pictureSorting/PictureSortingGame';
import { RevealMatchGame, REVEAL_MATCH_ID, revealMatchDifficultyParams } from './revealMatch/RevealMatchGame';
import { PictureRecallGame, PICTURE_RECALL_ID, pictureRecallDifficultyParams } from './pictureRecall/PictureRecallGame';
import { SpotDifferenceGame, SPOT_DIFFERENCE_ID, spotDifferenceDifficultyParams } from './spotDifference/SpotDifferenceGame';
import { ColoringGame, COLORING_ID, coloringDifficultyParams } from './coloring/ColoringGame';
import { TraceGame, TRACE_ID, traceDifficultyParams } from './trace/TraceGame';

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
  {
    gameId: REVEAL_MATCH_ID,
    displayNameKey: 'gameRevealMatch',
    instructionKey: 'howToPlayRevealMatch',
    required: true,
    owner: 'Aryan',
    component: RevealMatchGame,
    difficultyParamsForLevel: revealMatchDifficultyParams,
    maxLevel: 3,
  },
  {
    gameId: PICTURE_RECALL_ID,
    displayNameKey: 'gamePictureRecall',
    instructionKey: 'howToPlayPictureRecall',
    required: true,
    owner: 'Aryan',
    component: PictureRecallGame,
    difficultyParamsForLevel: pictureRecallDifficultyParams,
    maxLevel: 3,
  },
  {
    gameId: SPOT_DIFFERENCE_ID,
    displayNameKey: 'gameSpotDifference',
    instructionKey: 'howToPlaySpotDifference',
    required: true,
    owner: 'Aryan',
    component: SpotDifferenceGame,
    difficultyParamsForLevel: spotDifferenceDifficultyParams,
    maxLevel: 3,
  },
  {
    gameId: COLORING_ID,
    displayNameKey: 'gameColoring',
    instructionKey: 'howToPlayColoring',
    required: true,
    owner: 'Aryan',
    component: ColoringGame,
    difficultyParamsForLevel: coloringDifficultyParams,
    maxLevel: 3,
  },
  {
    gameId: TRACE_ID,
    displayNameKey: 'gameTrace',
    instructionKey: 'howToPlayTrace',
    required: true,
    owner: 'Aryan',
    component: TraceGame,
    difficultyParamsForLevel: traceDifficultyParams,
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
