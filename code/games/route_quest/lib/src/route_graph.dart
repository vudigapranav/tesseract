import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import 'route_topology.dart';

/// One bound location: the host-supplied content item, plus which other
/// node indices it connects to.
class RouteNode {
  const RouteNode({required this.item, required this.neighborIndices});

  final GameItem item;
  final List<int> neighborIndices;
}

/// A [RouteTopology] bound to real content — the graph a session actually
/// plays on. Locations are nodes, connections are edges; the patient moves
/// by tapping an adjacent node. No tile map, no free movement, no
/// pathfinding AI — BFS over this graph is the only "AI" involved, and it
/// only ever measures a route, never plays one.
class RouteGraph {
  const RouteGraph(
      {required this.nodes,
      required this.homeIndex,
      required this.destinationIndex});

  final List<RouteNode> nodes;
  final int homeIndex;
  final int destinationIndex;

  bool areAdjacent(int a, int b) => nodes[a].neighborIndices.contains(b);

  /// BFS shortest path length (edge count) between [from] and [to]. Null if
  /// unreachable — every level's topology is connected, so this only
  /// matters for malformed/test graphs.
  int? shortestPathLength(int from, int to) {
    if (from == to) {
      return 0;
    }
    final Set<int> visited = <int>{from};
    List<int> frontier = <int>[from];
    int distance = 0;
    while (frontier.isNotEmpty) {
      distance += 1;
      final List<int> next = <int>[];
      for (final int node in frontier) {
        for (final int neighbor in nodes[node].neighborIndices) {
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

  /// The node to move to next from [from] on a shortest path toward [to].
  /// Null if already there or [to] is unreachable. Powers Help's route
  /// highlight only — it never moves the patient itself.
  int? nextHopToward(int from, int to) {
    if (from == to) {
      return null;
    }
    final Map<int, int> parentOf = <int, int>{};
    final Set<int> visited = <int>{from};
    List<int> frontier = <int>[from];
    while (frontier.isNotEmpty) {
      final List<int> next = <int>[];
      for (final int node in frontier) {
        for (final int neighbor in nodes[node].neighborIndices) {
          if (visited.add(neighbor)) {
            parentOf[neighbor] = node;
            if (neighbor == to) {
              int step = neighbor;
              while (parentOf[step] != from) {
                step = parentOf[step]!;
              }
              return step;
            }
            next.add(neighbor);
          }
        }
      }
      frontier = next;
    }
    return null;
  }
}

/// Binds a [RouteTopology] to real host-supplied [items] in order:
/// `items[i]` becomes the node at topology index `i`.
///
/// Throws [ArgumentError] if fewer items than the topology needs are
/// supplied — a host contract violation, not a recoverable game state.
RouteGraph buildRouteGraph(RouteTopology topology, List<GameItem> items) {
  if (items.length < topology.nodeCount) {
    throw ArgumentError.value(
      items.length,
      'items.length',
      'Route Quest needs at least ${topology.nodeCount} items for this level',
    );
  }
  final List<List<int>> adjacency =
      List<List<int>>.generate(topology.nodeCount, (_) => <int>[]);
  for (final (int a, int b) in topology.edges) {
    adjacency[a].add(b);
    adjacency[b].add(a);
  }
  final List<RouteNode> nodes = List<RouteNode>.generate(
    topology.nodeCount,
    (int i) => RouteNode(
        item: items[i], neighborIndices: List<int>.unmodifiable(adjacency[i])),
  );
  return RouteGraph(
      nodes: nodes,
      homeIndex: topology.homeIndex,
      destinationIndex: topology.destinationIndex);
}
