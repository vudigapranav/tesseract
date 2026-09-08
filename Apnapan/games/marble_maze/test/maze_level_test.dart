import 'package:flutter_test/flutter_test.dart';
import 'package:marble_maze/src/maze_level.dart';

void main() {
  group('MazeLevel.forLevel', () {
    test('level 1: wide corridors (width 2), 2 turns, no dead ends', () {
      final MazeLevel level = MazeLevel.forLevel(1);
      expect(level.corridorWidth, 2);
      expect(level.turnCount, 2);
      expect(level.deadEndCount, 0);
      expect(level.deadEndCells, isEmpty);
    });

    test('level 2: 4 turns, one dead end', () {
      final MazeLevel level = MazeLevel.forLevel(2);
      expect(level.corridorWidth, 1);
      expect(level.turnCount, 4);
      expect(level.deadEndCount, 1);
      expect(level.deadEndCells.length, 1);
    });

    test('level 3: 6 turns, two dead ends', () {
      final MazeLevel level = MazeLevel.forLevel(3);
      expect(level.corridorWidth, 1);
      expect(level.turnCount, 6);
      expect(level.deadEndCount, 2);
      expect(level.deadEndCells.length, 2);
    });

    test('start and goal are always open cells', () {
      for (final int lvl in <int>[1, 2, 3]) {
        final MazeLevel level = MazeLevel.forLevel(lvl);
        expect(level.isOpen(level.start.$1, level.start.$2), isTrue,
            reason: 'level $lvl start');
        expect(level.isOpen(level.goal.$1, level.goal.$2), isTrue,
            reason: 'level $lvl goal');
      }
    });
  });

  group('MazeLevel.shortestPathLength (BFS, computed once at level load)', () {
    test('level 1: shortest start->goal is the Manhattan-optimal 15 hops', () {
      final MazeLevel level = MazeLevel.forLevel(1);
      expect(level.shortestPathLength(level.start, level.goal), 15);
    });

    test(
        'level 2: shortest start->goal follows the single corridor (17 hops), ignoring the dead end',
        () {
      final MazeLevel level = MazeLevel.forLevel(2);
      expect(level.shortestPathLength(level.start, level.goal), 17);
    });

    test(
        'level 3: shortest start->goal follows the single corridor (20 hops), ignoring both dead ends',
        () {
      final MazeLevel level = MazeLevel.forLevel(3);
      expect(level.shortestPathLength(level.start, level.goal), 20);
    });

    test('same cell is distance 0', () {
      final MazeLevel level = MazeLevel.forLevel(1);
      expect(level.shortestPathLength(level.start, level.start), 0);
    });

    test('unreachable cells return null', () {
      final MazeLevel level = MazeLevel.forLevel(1);
      expect(level.shortestPathLength(level.start, (0, 0)), isNull);
    });
  });
}
