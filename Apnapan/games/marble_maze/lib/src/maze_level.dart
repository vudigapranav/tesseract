/// A hand-authored maze level: a fixed occupancy grid, no procedural
/// generation, no pathfinding AI beyond the BFS used to measure (never play)
/// a route.
///
/// Difficulty changes the map only — see `MarbleMazeGame.difficultyParamsForLevel`
/// for the real corridor width/turn/dead-end settings this reports, never
/// just the level number.
class MazeLevel {
  const MazeLevel({
    required this.cols,
    required this.rows,
    required this.grid,
    required this.start,
    required this.goal,
    required this.deadEndCells,
    required this.corridorWidth,
    required this.turnCount,
    required this.deadEndCount,
  });

  final int cols;
  final int rows;

  /// `grid[row][col]`: true = open corridor, false = wall.
  final List<List<bool>> grid;

  final (int, int) start;
  final (int, int) goal;

  /// Cells that are the far tip of a dead-end branch — used to fire
  /// `dead_end_entered` once per cell per session.
  final Set<(int, int)> deadEndCells;

  final int corridorWidth;
  final int turnCount;
  final int deadEndCount;

  bool isOpen(int col, int row) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      return false;
    }
    return grid[row][col];
  }

  /// BFS shortest path length (cell-hop count) between [from] and [to] over
  /// 4-directional open-cell adjacency, computed once at level load. Null
  /// if unreachable.
  int? shortestPathLength((int, int) from, (int, int) to) {
    if (from == to) {
      return 0;
    }
    final Set<(int, int)> visited = <(int, int)>{from};
    List<(int, int)> frontier = <(int, int)>[from];
    int distance = 0;
    while (frontier.isNotEmpty) {
      distance += 1;
      final List<(int, int)> next = <(int, int)>[];
      for (final (int, int) cell in frontier) {
        for (final (int, int) neighbor in _neighborsOf(cell)) {
          if (visited.add(neighbor)) {
            if (neighbor == to) {
              return distance;
            }
            next.add(neighbor);
          }
        }
      }
      frontier = next;
    }
    return null;
  }

  /// Returns the cell centres used by Help's visual guide. This is the same
  /// deterministic breadth-first search used for measurement, but exposing
  /// the path does not move the marble or alter the score.
  List<(int, int)> shortestPathCells((int, int) from, (int, int) to) {
    if (from == to) return <(int, int)>[from];
    final Map<(int, int), (int, int)?> parent = <(int, int), (int, int)?>{
      from: null
    };
    final List<(int, int)> queue = <(int, int)>[from];
    int cursor = 0;
    while (cursor < queue.length) {
      final (int, int) cell = queue[cursor++];
      for (final (int, int) neighbor in _neighborsOf(cell)) {
        if (parent.containsKey(neighbor)) continue;
        parent[neighbor] = cell;
        if (neighbor == to) {
          final List<(int, int)> path = <(int, int)>[to];
          (int, int)? step = cell;
          while (step != null) {
            path.add(step);
            step = parent[step];
          }
          return path.reversed.toList(growable: false);
        }
        queue.add(neighbor);
      }
    }
    return const <(int, int)>[];
  }

  List<(int, int)> _neighborsOf((int, int) cell) {
    final int c = cell.$1;
    final int r = cell.$2;
    final List<(int, int)> result = <(int, int)>[];
    for (final (int, int) delta in const <(int, int)>[
      (1, 0),
      (-1, 0),
      (0, 1),
      (0, -1)
    ]) {
      final int nc = c + delta.$1;
      final int nr = r + delta.$2;
      if (isOpen(nc, nr)) {
        result.add((nc, nr));
      }
    }
    return result;
  }

  /// Level 1: wide corridors, 2 turns.
  /// Level 2: 4 turns, one dead end.
  /// Level 3 (and any higher level): 6 turns, two dead ends.
  static MazeLevel forLevel(int level) {
    return switch (level) {
      1 => _build(
          cols: 9,
          rows: 13,
          waypoints: const <(int, int)>[(1, 1), (1, 6), (6, 6), (6, 11)],
          corridorWidth: 2,
          deadEnds: const <((int, int), (int, int))>[],
        ),
      2 => _build(
          cols: 9,
          rows: 13,
          waypoints: const <(int, int)>[
            (1, 1),
            (1, 4),
            (5, 4),
            (5, 8),
            (2, 8),
            (2, 11)
          ],
          corridorWidth: 1,
          deadEnds: const <((int, int), (int, int))>[((5, 6), (8, 6))],
        ),
      _ => _build(
          cols: 9,
          rows: 13,
          waypoints: const <(int, int)>[
            (1, 1),
            (1, 3),
            (4, 3),
            (4, 6),
            (7, 6),
            (7, 9),
            (3, 9),
            (3, 11)
          ],
          corridorWidth: 1,
          deadEnds: const <((int, int), (int, int))>[
            ((4, 4), (6, 4)),
            ((7, 7), (5, 7))
          ],
        ),
    };
  }

  static MazeLevel _build({
    required int cols,
    required int rows,
    required List<(int, int)> waypoints,
    required int corridorWidth,
    required List<((int, int), (int, int))> deadEnds,
  }) {
    final List<List<bool>> grid =
        List<List<bool>>.generate(rows, (_) => List<bool>.filled(cols, false));

    int turnCount = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      _stampSegment(
          grid, waypoints[i], waypoints[i + 1], corridorWidth, cols, rows);
      if (i > 0) {
        final (int, int) previousDirection =
            _directionOf(waypoints[i - 1], waypoints[i]);
        final (int, int) nextDirection =
            _directionOf(waypoints[i], waypoints[i + 1]);
        if (previousDirection != nextDirection) {
          turnCount += 1;
        }
      }
    }

    final Set<(int, int)> deadEndCells = <(int, int)>{};
    for (final ((int, int), (int, int)) stub in deadEnds) {
      _stampSegment(grid, stub.$1, stub.$2, 1, cols, rows);
      deadEndCells.add(stub.$2);
    }

    return MazeLevel(
      cols: cols,
      rows: rows,
      grid: grid,
      start: waypoints.first,
      goal: waypoints.last,
      deadEndCells: deadEndCells,
      corridorWidth: corridorWidth,
      turnCount: turnCount,
      deadEndCount: deadEnds.length,
    );
  }

  static (int, int) _directionOf((int, int) a, (int, int) b) {
    return ((b.$1 - a.$1).sign, (b.$2 - a.$2).sign);
  }

  static void _stampSegment(List<List<bool>> grid, (int, int) a, (int, int) b,
      int width, int cols, int rows) {
    final int ax = a.$1, ay = a.$2, bx = b.$1, by = b.$2;
    if (ax == bx) {
      final int y0 = ay < by ? ay : by;
      final int y1 = ay < by ? by : ay;
      for (int y = y0; y <= y1; y++) {
        for (int w = 0; w < width; w++) {
          final int x = ax + w;
          if (x >= 0 && x < cols && y >= 0 && y < rows) {
            grid[y][x] = true;
          }
        }
      }
    } else {
      final int x0 = ax < bx ? ax : bx;
      final int x1 = ax < bx ? bx : ax;
      for (int x = x0; x <= x1; x++) {
        for (int w = 0; w < width; w++) {
          final int y = ay + w;
          if (x >= 0 && x < cols && y >= 0 && y < rows) {
            grid[y][x] = true;
          }
        }
      }
    }
  }
}
