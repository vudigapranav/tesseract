import 'package:flutter_test/flutter_test.dart';
import 'package:route_quest/src/route_graph.dart';
import 'package:route_quest/src/route_topology.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

List<GameItem> _items(int n) =>
    List<GameItem>.generate(n, (int i) => GameItem(id: 'loc_$i'));

void main() {
  group('RouteGraph BFS shortest path', () {
    test('level 1 (3 nodes, direct path): shortest home->dest is 2', () {
      final RouteTopology topology = RouteTopology.forLevel(1);
      final RouteGraph graph =
          buildRouteGraph(topology, _items(topology.nodeCount));
      expect(
          graph.shortestPathLength(graph.homeIndex, graph.destinationIndex), 2);
    });

    test(
        'level 2 (5 nodes, one branch): shortest home->dest is 2, ignoring the branch',
        () {
      final RouteTopology topology = RouteTopology.forLevel(2);
      final RouteGraph graph =
          buildRouteGraph(topology, _items(topology.nodeCount));
      expect(
          graph.shortestPathLength(graph.homeIndex, graph.destinationIndex), 2);
    });

    test(
        'level 3 (6 nodes, two branches): shortest home->dest is 3, ignoring both branches',
        () {
      final RouteTopology topology = RouteTopology.forLevel(3);
      final RouteGraph graph =
          buildRouteGraph(topology, _items(topology.nodeCount));
      expect(
          graph.shortestPathLength(graph.homeIndex, graph.destinationIndex), 3);
    });

    test('same node is distance 0', () {
      final RouteTopology topology = RouteTopology.forLevel(1);
      final RouteGraph graph =
          buildRouteGraph(topology, _items(topology.nodeCount));
      expect(graph.shortestPathLength(0, 0), 0);
    });

    test('unreachable nodes return null', () {
      const RouteGraph graph = RouteGraph(
        nodes: <RouteNode>[
          RouteNode(item: GameItem(id: 'a'), neighborIndices: <int>[]),
          RouteNode(item: GameItem(id: 'b'), neighborIndices: <int>[]),
        ],
        homeIndex: 0,
        destinationIndex: 1,
      );
      expect(graph.shortestPathLength(0, 1), isNull);
    });
  });

  group('RouteGraph.nextHopToward', () {
    test(
        'returns the first step on a shortest path, not the destination itself',
        () {
      final RouteTopology topology = RouteTopology.forLevel(2);
      final RouteGraph graph =
          buildRouteGraph(topology, _items(topology.nodeCount));
      // home(0) -> junction(1) -> destination(2): next hop from home is 1.
      expect(graph.nextHopToward(graph.homeIndex, graph.destinationIndex), 1);
    });

    test('returns null when already at the target', () {
      final RouteTopology topology = RouteTopology.forLevel(1);
      final RouteGraph graph =
          buildRouteGraph(topology, _items(topology.nodeCount));
      expect(graph.nextHopToward(graph.homeIndex, graph.homeIndex), isNull);
    });
  });

  group('buildRouteGraph', () {
    test('throws ArgumentError when fewer items than nodeCount are supplied',
        () {
      final RouteTopology topology = RouteTopology.forLevel(3);
      expect(() => buildRouteGraph(topology, _items(2)), throwsArgumentError);
    });

    test('binds items[i] to node i in order', () {
      final RouteTopology topology = RouteTopology.forLevel(1);
      final List<GameItem> items = _items(topology.nodeCount);
      final RouteGraph graph = buildRouteGraph(topology, items);
      expect(graph.nodes[0].item.id, 'loc_0');
      expect(graph.nodes[2].item.id, 'loc_2');
    });
  });
}
