# Marble Maze (G3)

Guide a marble to the goal.

Grid-based collision, not a physics engine: `MazeLevel` is a hand-authored
occupancy grid (open cell / wall cell) per level. Movement is continuous but
constrained by cell walls, stepped on a fixed 16ms timestep via a `Ticker`
(core Flutter, no Flame, no third-party engine, no added dependency). No
gravity, no bouncing.

The integrated Android host selects tilt mode. Its native motion channel uses
Android's fused game-rotation vector (gyroscope plus supporting motion sensors),
calibrates the resting phone angle for 12 samples, then sends smoothed tilt to
the game with a small dead zone. The game adds no plugin dependency and remains
inside the package boundary. Touch is used when `inputMode` is `touch`, and is
the automatic fallback if a configured tilt stream is unavailable.

- **Level 1** — wide corridors (2-cell-wide), 2 turns, no dead ends.
- **Level 2** — standard width, 4 turns, one dead end.
- **Level 3** — standard width, 6 turns, two dead ends.

Difficulty changes the map only (see `MarbleMazeGame.difficultyParamsForLevel`
for the real `corridorWidth`/`turnCount`/`deadEndCount` settings) — never a
time limit or speed change.

## Events

| type | payload | when |
|---|---|---|
| `collision` | `{wallId}` | motion would move the marble into a wall (or off the grid edge); movement along that axis stops — no sound, no penalty, no counter shown to the patient |
| `dead_end_entered` | `{cellId}` | the marble's centre enters a dead-end branch's tip cell, once per cell per session |
| `goal_reached` | — | the marble's centre enters the goal cell |

Plus the shared lifecycle events (`session_started`, `hint_requested`,
`paused`, `resumed`, `session_finished`) from `TesseractEventRecorder`.

## Path efficiency

`shortest grid path / actual path travelled`, for completed runs only.
Shortest length is BFS'd once per level load (`MazeLevel.shortestPathLength`,
4-directional over open cells). Actual path length is continuous (not a
per-move event count like Route Quest's), so reconstructing it downstream
needs position sampling this build does not yet emit — the shared event list
for this game was deliberately kept to `collision`/`dead_end_entered`/
`goal_reached` only; a `path_sample`-style event is a documented future
addition, not something invented here.
