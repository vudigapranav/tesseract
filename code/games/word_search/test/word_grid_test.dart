import 'package:flutter_test/flutter_test.dart';
import 'package:word_search/word_search.dart';

/// Grid generation, independent of any widget.
void main() {
  WordGrid buildWith(
    List<({String id, String word})> entries, {
    int size = 8,
    bool diagonals = false,
  }) =>
      WordGridBuilder(size: size, allowDiagonals: diagonals, seed: 42)
          .build(entries);

  test('every placed word really is in the cells it claims', () {
    final WordGrid grid = buildWith(<({String id, String word})>[
      (id: 'word_1', word: 'garden'),
      (id: 'word_2', word: 'tea'),
    ]);

    expect(grid.words, hasLength(2));
    for (final PlacedWord word in grid.words) {
      final String spelled =
          word.cells.map((int i) => grid.cells[i]).join();
      expect(spelled, word.letters.join());
    }
  });

  test('the grid is completely filled', () {
    final WordGrid grid =
        buildWith(<({String id, String word})>[(id: 'word_1', word: 'tea')]);
    expect(grid.cells, hasLength(8 * 8));
    expect(grid.cells.any((String c) => c.isEmpty), isFalse);
  });

  test('a word too long for the grid is reported, not silently dropped', () {
    final WordGrid grid = buildWith(
      <({String id, String word})>[
        (id: 'word_1', word: 'extraordinarily'),
        (id: 'word_2', word: 'tea'),
      ],
      size: 6,
    );

    expect(grid.words.map((PlacedWord w) => w.id), <String>['word_2']);
    expect(grid.skipped.map((e) => e.word), contains('extraordinarily'));
  });

  test('generation is deterministic for a given seed', () {
    final List<({String id, String word})> entries = <({String id, String word})>[
      (id: 'word_1', word: 'garden'),
      (id: 'word_2', word: 'music'),
    ];
    final WordGrid a = buildWith(entries);
    final WordGrid b = buildWith(entries);
    expect(a.cells, b.cells);
  });

  test('a single-letter word still places', () {
    final WordGrid grid =
        buildWith(<({String id, String word})>[(id: 'word_1', word: 'A')]);
    expect(grid.words, hasLength(1));
    expect(grid.words.single.cells, hasLength(1));
  });

  test('words are uppercased so the grid reads consistently', () {
    final WordGrid grid = buildWith(
        <({String id, String word})>[(id: 'word_1', word: 'garden')]);
    expect(grid.words.single.letters.join(), 'GARDEN');
    // The caregiver's original casing is kept for display.
    expect(grid.words.single.display, 'garden');
  });

  test('no words produces an empty puzzle rather than an error', () {
    final WordGrid grid = buildWith(const <({String id, String word})>[]);
    expect(grid.words, isEmpty);
    expect(grid.cells.any((String c) => c.isEmpty), isFalse);
  });

  test('multi-code-point characters are not split in half', () {
    // Splitting by UTF-16 code unit would cut this into two broken halves.
    final WordGrid grid = buildWith(
        <({String id, String word})>[(id: 'word_1', word: '𝔸𝔹ℂ')], size: 6);
    if (grid.words.isNotEmpty) {
      expect(grid.words.single.letters, hasLength(3));
    } else {
      expect(grid.skipped, isNotEmpty);
    }
  });

  group('line detection', () {
    test('a horizontal run is accepted', () {
      expect(lineBetween(5, 0, 3, allowDiagonals: false), <int>[0, 1, 2, 3]);
    });

    test('a vertical run is accepted', () {
      expect(lineBetween(5, 0, 15, allowDiagonals: false), <int>[0, 5, 10, 15]);
    });

    test('a backwards run is accepted and ordered from the first tap', () {
      expect(lineBetween(5, 3, 0, allowDiagonals: false), <int>[3, 2, 1, 0]);
    });

    test('a diagonal is refused unless the level allows it', () {
      expect(lineBetween(5, 0, 12, allowDiagonals: false), isNull);
      expect(lineBetween(5, 0, 12, allowDiagonals: true), <int>[0, 6, 12]);
    });

    test('a crooked selection is refused', () {
      expect(lineBetween(5, 0, 7, allowDiagonals: true), isNull);
    });

    test('tapping the same cell twice is a single cell', () {
      expect(lineBetween(5, 6, 6, allowDiagonals: false), <int>[6]);
    });
  });
}
