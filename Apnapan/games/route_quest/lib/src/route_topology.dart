/// Abstract level topology — node count, edges (as index pairs), which
/// index is home/destination, and how many dead-end branches exist. Purely
/// structural: no content, no rendering, no timing.
///
/// Difficulty changes the map only: each level is a fixed, hand-authored
/// shape, not something computed from a difficulty score.
class RouteTopology {
  const RouteTopology({
    required this.nodeCount,
    required this.edges,
    required this.homeIndex,
    required this.destinationIndex,
    required this.branchCount,
  });

  final int nodeCount;

  /// Undirected edges as (a, b) node-index pairs.
  final List<(int, int)> edges;

  final int homeIndex;
  final int destinationIndex;

  /// Number of dead-end branches off the main path — the real setting
  /// `RouteQuestGame.difficultyParamsForLevel` reports, not just the level
  /// number.
  final int branchCount;

  /// Level 1: 3 locations, a direct path there and back.
  /// Level 2: 5 locations, one branch.
  /// Level 3 (and any higher level): 6 locations, two branches.
  static RouteTopology forLevel(int level) {
    return switch (level) {
      1 => const RouteTopology(
          nodeCount: 3,
          edges: <(int, int)>[(0, 1), (1, 2)],
          homeIndex: 0,
          destinationIndex: 2,
          branchCount: 0,
        ),
      2 => const RouteTopology(
          nodeCount: 5,
          edges: <(int, int)>[(0, 1), (1, 2), (1, 3), (3, 4)],
          homeIndex: 0,
          destinationIndex: 2,
          branchCount: 1,
        ),
      _ => const RouteTopology(
          nodeCount: 6,
          edges: <(int, int)>[(0, 1), (1, 2), (2, 3), (1, 4), (2, 5)],
          homeIndex: 0,
          destinationIndex: 3,
          branchCount: 2,
        ),
    };
  }
}
