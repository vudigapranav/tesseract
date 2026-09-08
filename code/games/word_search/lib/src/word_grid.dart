import 'dart:math';

/// One word placed in the grid.
class PlacedWord {
  PlacedWord({
    required this.id,
    required this.display,
    required this.letters,
    required this.cells,
  });

  /// Opaque id from the host's `GameItem`. The only form of this word that
  /// may appear in a telemetry payload — never the word itself, which is
  /// personal content.
  final String id;

  /// What the patient reads.
  final String display;

  /// The word split into grid characters.
  final List<String> letters;

  /// Grid indices the word occupies, in reading order.
  final List<int> cells;
}

/// The generated puzzle.
class WordGrid {
  WordGrid({
    required this.size,
    required this.cells,
    required this.words,
    required this.skipped,
  });

  final int size;

  /// `size * size` characters, row-major.
  final List<String> cells;

  final List<PlacedWord> words;

  /// Words that could not be placed — too long for the grid, or the grid ran
  /// out of room. Reported rather than silently dropped so the caregiver's
  /// content is never quietly ignored: the game reports the ids as an event,
  /// and the host can tell the caregiver which of their words did not fit.
  final List<({String id, String word})> skipped;

  int indexOf(int row, int col) => row * size + col;
}

/// Builds a small word-search grid.
///
/// Placement is deterministic for a given [seed] so a level is reproducible
/// and testable.
///
/// **Script handling:** words are split by Unicode *code point* (`runes`),
/// not by UTF-16 code unit, so characters outside the Basic Multilingual
/// Plane are not cut in half. This is not full grapheme-cluster segmentation:
/// scripts that build clusters from combining marks (Devanagari conjuncts,
/// for example) would need a proper segmenter and a native reviewer before
/// this game is offered in those languages. English content is safe today.
class WordGridBuilder {
  WordGridBuilder({
    required this.size,
    required this.allowDiagonals,
    required this.seed,
  });

  final int size;
  final bool allowDiagonals;
  final int seed;

  static const List<String> _fallbackAlphabet = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  /// [entries] maps opaque word id to the caregiver's word.
  WordGrid build(List<({String id, String word})> entries) {
    final Random random = Random(seed);
    final List<String> cells = List<String>.filled(size * size, '');
    final List<PlacedWord> placed = <PlacedWord>[];
    final List<({String id, String word})> skipped = <({String id, String word})>[];

    // Longest first: long words are the hardest to fit, and placing them
    // while the grid is empty avoids skipping them needlessly.
    final List<({String id, String word})> ordered = entries.toList()
      ..sort((a, b) => b.word.runes.length.compareTo(a.word.runes.length));

    final Set<String> usedIds = <String>{};

    for (final ({String id, String word}) entry in ordered) {
      final String cleaned = entry.word.trim().toUpperCase();
      if (cleaned.isEmpty || usedIds.contains(entry.id)) {
        continue;
      }
      final List<String> letters =
          cleaned.runes.map((int r) => String.fromCharCode(r)).toList();
      if (letters.length > size) {
        skipped.add(entry);
        continue;
      }
      final PlacedWord? word = _tryPlace(entry.id, entry.word, letters, cells, random);
      if (word == null) {
        skipped.add(entry);
        continue;
      }
      usedIds.add(entry.id);
      placed.add(word);
    }

    // Fill the gaps with letters drawn from the words themselves, so filler
    // never looks like a different alphabet from the content.
    final List<String> alphabet = <String>{
      for (final PlacedWord w in placed) ...w.letters,
    }.toList()
      ..sort();
    final List<String> pool =
        alphabet.length >= 5 ? alphabet : _fallbackAlphabet;
    for (int i = 0; i < cells.length; i++) {
      if (cells[i].isEmpty) {
        cells[i] = pool[random.nextInt(pool.length)];
      }
    }

    return WordGrid(
        size: size, cells: cells, words: placed, skipped: skipped);
  }

  PlacedWord? _tryPlace(
    String id,
    String display,
    List<String> letters,
    List<String> cells,
    Random random,
  ) {
    final List<({int dr, int dc})> directions = <({int dr, int dc})>[
      (dr: 0, dc: 1), // across
      (dr: 1, dc: 0), // down
      if (allowDiagonals) (dr: 1, dc: 1),
    ]..shuffle(random);

    for (final ({int dr, int dc}) direction in directions) {
      final List<int> starts =
          List<int>.generate(size * size, (int i) => i)..shuffle(random);
      for (final int start in starts) {
        final int row = start ~/ size;
        final int col = start % size;
        final int endRow = row + direction.dr * (letters.length - 1);
        final int endCol = col + direction.dc * (letters.length - 1);
        if (endRow >= size || endCol >= size) {
          continue;
        }
        final List<int> target = <int>[];
        bool fits = true;
        for (int i = 0; i < letters.length; i++) {
          final int index =
              (row + direction.dr * i) * size + (col + direction.dc * i);
          final String existing = cells[index];
          // Crossings are allowed where the letters already agree.
          if (existing.isNotEmpty && existing != letters[i]) {
            fits = false;
            break;
          }
          target.add(index);
        }
        if (!fits) {
          continue;
        }
        for (int i = 0; i < letters.length; i++) {
          cells[target[i]] = letters[i];
        }
        return PlacedWord(
            id: id, display: display, letters: letters, cells: target);
      }
    }
    return null;
  }
}

/// The straight line of cells between two grid positions, or null when the
/// two do not form a straight horizontal, vertical or diagonal run.
List<int>? lineBetween(int size, int from, int to, {required bool allowDiagonals}) {
  final int fromRow = from ~/ size;
  final int fromCol = from % size;
  final int toRow = to ~/ size;
  final int toCol = to % size;

  final int dRow = toRow - fromRow;
  final int dCol = toCol - fromCol;

  if (dRow == 0 && dCol == 0) {
    return <int>[from];
  }

  final bool straight = dRow == 0 || dCol == 0;
  final bool diagonal = dRow.abs() == dCol.abs();
  if (!straight && !(diagonal && allowDiagonals)) {
    return null;
  }

  final int steps = max(dRow.abs(), dCol.abs());
  final int stepRow = dRow == 0 ? 0 : dRow ~/ dRow.abs();
  final int stepCol = dCol == 0 ? 0 : dCol ~/ dCol.abs();

  return <int>[
    for (int i = 0; i <= steps; i++)
      (fromRow + stepRow * i) * size + (fromCol + stepCol * i),
  ];
}
