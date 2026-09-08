import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import 'word_grid.dart';

/// G7 Personalized Word Search.
///
/// The words are the caregiver's own familiar words, supplied through
/// `config.items`. That is the point of the activity: the content is personal
/// even though nothing personal ever reaches telemetry — payloads carry the
/// item's opaque id only, never the word.
///
/// Interaction is **tap the first letter, then tap the last letter**, not a
/// drag. Dragging a precise path across small cells is hard with tremor or
/// low dexterity; two taps are forgiving, work with a screen reader, and can
/// be undone by tapping again.
class WordSearchGame extends TesseractGame {
  const WordSearchGame({
    super.key,
    required super.config,
    required super.onEvent,
    required super.onFinish,
  });

  /// The real grid settings for [level], never just the level number.
  static Map<String, Object?> difficultyParamsForLevel(int level) {
    switch (level) {
      case 1:
        return <String, Object?>{
          'gridSize': 6,
          'wordCount': 3,
          'allowDiagonals': false,
        };
      case 2:
        return <String, Object?>{
          'gridSize': 8,
          'wordCount': 4,
          'allowDiagonals': false,
        };
      default:
        return <String, Object?>{
          'gridSize': 9,
          'wordCount': 5,
          'allowDiagonals': true,
        };
    }
  }

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame>
    with WidgetsBindingObserver, TesseractGameStateMixin<WordSearchGame> {
  final TesseractEventRecorder _recorder = TesseractEventRecorder();

  late final WordGrid _grid = _buildGrid();
  final Set<String> _foundIds = <String>{};
  final Set<int> _foundCells = <int>{};

  int? _anchor;
  List<int> _highlighted = const <int>[];
  bool _paused = false;
  String? _hintedWordId;

  @override
  TesseractEventRecorder get eventRecorder => _recorder;

  int get _gridSize =>
      (widget.config.difficultyParams['gridSize'] as int?) ?? 6;
  int get _wordCount =>
      (widget.config.difficultyParams['wordCount'] as int?) ?? 3;
  bool get _allowDiagonals =>
      (widget.config.difficultyParams['allowDiagonals'] as bool?) ?? false;

  WordGrid _buildGrid() {
    final List<({String id, String word})> entries = <({String id, String word})>[
      for (final GameItem item in widget.config.items.take(_wordCount))
        if ((item.label ?? '').trim().isNotEmpty)
          (id: item.id, word: item.label!.trim()),
    ];
    return WordGridBuilder(
      size: _gridSize,
      allowDiagonals: _allowDiagonals,
      // Deterministic per level so the same level yields the same puzzle.
      seed: widget.config.level * 104729,
    ).build(entries);
  }

  @override
  void initState() {
    super.initState();
    widget.onEvent(_recorder.sessionStarted());
    if (_grid.skipped.isNotEmpty) {
      // A caregiver's word that will not fit must not just vanish. Ids only —
      // the words themselves are personal content.
      widget.onEvent(_recorder.custom('content_unavailable', <String, Object?>{
        'reason': 'word_does_not_fit_grid',
        'wordIds': _grid.skipped.map((e) => e.id).toList(),
      }));
    }
  }

  void _handleHelp() {
    if (_paused) {
      return;
    }
    widget.onEvent(_recorder.hintRequested());
    final PlacedWord? next = _grid.words
        .cast<PlacedWord?>()
        .firstWhere((PlacedWord? w) => !_foundIds.contains(w!.id),
            orElse: () => null);
    setState(() => _hintedWordId = next?.id);
  }

  void _handleBreak() {
    widget.onEvent(_recorder.paused(reason: 'break'));
    setState(() => _paused = true);
  }

  void _handleResume() {
    widget.onEvent(_recorder.resumed());
    setState(() => _paused = false);
  }

  void _finish(String status) {
    if (_recorder.isFinished) {
      return;
    }
    widget.onEvent(_recorder.sessionFinished(status));
    widget.onFinish(GameResult(
      status: status,
      finalSeq: _recorder.lastSeq,
      assisted: _recorder.assisted,
    ));
  }

  void _tapCell(int index) {
    if (_paused) {
      return;
    }
    if (_anchor == null) {
      setState(() {
        _anchor = index;
        _highlighted = <int>[index];
      });
      return;
    }
    if (_anchor == index) {
      // Tapping the anchor again cancels, so a mistaken first tap costs
      // nothing and is not recorded as a wrong answer.
      setState(() {
        _anchor = null;
        _highlighted = const <int>[];
      });
      return;
    }

    final List<int>? line = lineBetween(_grid.size, _anchor!, index,
        allowDiagonals: _allowDiagonals);

    if (line == null) {
      // Not a straight run: guidance, not a failure event.
      setState(() {
        _anchor = null;
        _highlighted = const <int>[];
      });
      return;
    }

    _resolveSelection(line);
  }

  void _resolveSelection(List<int> line) {
    final List<int> reversed = line.reversed.toList();
    PlacedWord? match;
    for (final PlacedWord word in _grid.words) {
      if (_foundIds.contains(word.id)) {
        continue;
      }
      if (_sameCells(word.cells, line) || _sameCells(word.cells, reversed)) {
        match = word;
        break;
      }
    }

    if (match == null) {
      widget.onEvent(_recorder.custom('selection_rejected', <String, Object?>{
        'cellCount': line.length,
      }));
      setState(() {
        _anchor = null;
        _highlighted = const <int>[];
      });
      return;
    }

    widget.onEvent(_recorder.custom('word_found', <String, Object?>{
      // Opaque id only. The word itself is personal content and stays out of
      // telemetry.
      'wordId': match.id,
    }));

    setState(() {
      _foundIds.add(match!.id);
      _foundCells.addAll(match.cells);
      _anchor = null;
      _highlighted = const <int>[];
      if (_hintedWordId == match.id) {
        _hintedWordId = null;
      }
    });

    if (_foundIds.length >= _grid.words.length && _grid.words.isNotEmpty) {
      widget.onEvent(_recorder.custom('all_words_found'));
      _finish(GameResultStatus.completed);
    }
  }

  bool _sameCells(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final GameStrings strings = widget.config.strings;

    if (_grid.words.isEmpty) {
      return TesseractGameScaffold(
        strings: strings,
        paused: _paused,
        helpEnabled: false,
        onHelp: _handleHelp,
        onBreak: _handleBreak,
        onResume: _handleResume,
        onFinish: () => _finish(GameResultStatus.stoppedByUser),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'There are no familiar words set up for this puzzle yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
    }

    final Set<int> hintCells = <int>{
      if (_hintedWordId != null)
        ..._grid.words
            .firstWhere((PlacedWord w) => w.id == _hintedWordId)
            .cells,
    };

    return TesseractGameScaffold(
      strings: strings,
      paused: _paused,
      onHelp: _handleHelp,
      onBreak: _handleBreak,
      onResume: _handleResume,
      onFinish: () => _finish(GameResultStatus.stoppedByUser),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            children: <Widget>[
              Text(
                'Find these words',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: <Widget>[
                  for (final PlacedWord word in _grid.words)
                    _wordChip(word),
                ],
              ),
              const SizedBox(height: 18),
              _gridView(hintCells),
              const SizedBox(height: 12),
              Text(
                _anchor == null
                    ? 'Tap the first letter, then the last letter.'
                    : 'Now tap the last letter.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordChip(PlacedWord word) {
    final bool found = _foundIds.contains(word.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: found ? Colors.green.shade50 : Colors.white,
        border: Border.all(
            color: found ? Colors.green.shade700 : Colors.black26,
            width: found ? 2 : 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Found state is shown by icon and strike-through as well as
          // colour, so it does not rely on colour alone.
          if (found) const Icon(Icons.check_rounded, size: 18),
          if (found) const SizedBox(width: 6),
          Text(
            word.display,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  decoration: found ? TextDecoration.lineThrough : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _gridView(Set<int> hintCells) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side = constraints.maxWidth / _grid.size;
        return Column(
          children: <Widget>[
            for (int row = 0; row < _grid.size; row++)
              Row(
                children: <Widget>[
                  for (int col = 0; col < _grid.size; col++)
                    _cell(row * _grid.size + col, side, hintCells),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _cell(int index, double side, Set<int> hintCells) {
    final bool found = _foundCells.contains(index);
    final bool selected = _highlighted.contains(index);
    final bool hinted = hintCells.contains(index);

    return SizedBox(
      width: side,
      height: side,
      child: Semantics(
        button: true,
        label: _grid.cells[index],
        child: InkWell(
          onTap: () => _tapCell(index),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: found
                  ? Colors.green.shade100
                  : selected
                      ? Colors.amber.shade200
                      : hinted
                          ? Colors.amber.shade50
                          : Colors.white,
              border: Border.all(
                color: selected ? Colors.amber.shade800 : Colors.black12,
                width: selected ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _grid.cells[index],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: found ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
