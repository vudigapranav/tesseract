/**
 * Maze levels, ported from maze_level.dart. Corridors are carved between
 * hand-authored waypoints on a 9x13 grid; difficulty is the corridor width,
 * the number of turns and the number of dead ends — the real settings, not a
 * difficulty score.
 */
export interface MazeLevel {
  cols: number;
  rows: number;
  /** open[row][col] — true where the marble may travel. */
  open: boolean[][];
  start: readonly [number, number];
  goal: readonly [number, number];
  corridorWidth: number;
  turnCount: number;
  deadEndCount: number;
  /** Dead-end cells, keyed for the dead_end_entered event. */
  deadEndCells: ReadonlyArray<{ col: number; row: number; id: string }>;
}

type Pt = readonly [number, number];

function carve(
  open: boolean[][],
  a: Pt,
  b: Pt,
  width: number,
  cols: number,
  rows: number,
) {
  const half = Math.floor((width - 1) / 2);
  const extra = width - 1 - half;
  const [ax, ay] = a;
  const [bx, by] = b;
  if (ax === bx) {
    const [lo, hi] = ay <= by ? [ay, by] : [by, ay];
    for (let y = lo; y <= hi; y++) {
      for (let x = ax - half; x <= ax + extra; x++) {
        if (x >= 0 && x < cols && y >= 0 && y < rows) open[y][x] = true;
      }
    }
  } else {
    const [lo, hi] = ax <= bx ? [ax, bx] : [bx, ax];
    for (let x = lo; x <= hi; x++) {
      for (let y = ay - half; y <= ay + extra; y++) {
        if (x >= 0 && x < cols && y >= 0 && y < rows) open[y][x] = true;
      }
    }
  }
}

function build(
  cols: number,
  rows: number,
  waypoints: readonly Pt[],
  corridorWidth: number,
  deadEnds: ReadonlyArray<readonly [Pt, Pt]>,
): MazeLevel {
  const open = Array.from({ length: rows }, () =>
    Array.from({ length: cols }, () => false),
  );
  for (let i = 0; i < waypoints.length - 1; i++) {
    carve(open, waypoints[i], waypoints[i + 1], corridorWidth, cols, rows);
  }
  const deadEndCells: Array<{ col: number; row: number; id: string }> = [];
  deadEnds.forEach(([from, to], i) => {
    carve(open, from, to, corridorWidth, cols, rows);
    deadEndCells.push({ col: to[0], row: to[1], id: `d${i + 1}` });
  });

  // A turn is a waypoint where the axis of travel changes.
  let turnCount = 0;
  for (let i = 1; i < waypoints.length - 1; i++) {
    const before = waypoints[i][0] === waypoints[i - 1][0] ? 'v' : 'h';
    const after = waypoints[i + 1][0] === waypoints[i][0] ? 'v' : 'h';
    if (before !== after) turnCount++;
  }

  return {
    cols,
    rows,
    open,
    start: waypoints[0],
    goal: waypoints[waypoints.length - 1],
    corridorWidth,
    turnCount,
    deadEndCount: deadEnds.length,
    deadEndCells,
  };
}

export function mazeForLevel(level: number): MazeLevel {
  switch (level) {
    case 1:
      return build(9, 13, [[1, 1], [1, 6], [6, 6], [6, 11]], 2, []);
    case 2:
      return build(
        9,
        13,
        [[1, 1], [1, 4], [5, 4], [5, 8], [2, 8], [2, 11]],
        1,
        [[[5, 6], [8, 6]]],
      );
    default:
      return build(
        9,
        13,
        [[1, 1], [1, 3], [4, 3], [4, 6], [7, 6], [7, 9], [3, 9], [3, 11]],
        1,
        [
          [[4, 4], [6, 4]],
          [[7, 7], [5, 7]],
        ],
      );
  }
}

export function marbleMazeDifficultyParams(level: number) {
  const m = mazeForLevel(level);
  return {
    corridorWidth: m.corridorWidth,
    turnCount: m.turnCount,
    deadEndCount: m.deadEndCount,
  };
}

export const isOpen = (m: MazeLevel, col: number, row: number): boolean =>
  row >= 0 && row < m.rows && col >= 0 && col < m.cols && m.open[row][col];
