import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Picture Sorting — put each picture into the group it belongs to.
///
/// Ported to Flutter from Ruthika's original HTML/CSS/JS implementation
/// (github.com/ruthikareddy678/GAMES, `game1`, commit a504486). Her mechanic
/// is preserved: one picture at a time, choose its category, gentle feedback,
/// move on.
///
/// Deliberate changes from her original, recorded for review:
///
///  * **No score, no high score.** The original counted a score, showed it
///    live and persisted a high score to local storage. Tesseract patient
///    screens carry no score, ranking or streak, so all of that is removed.
///  * **Content comes from the host**, through `config.items`, each carrying
///    its category in `extra['category']`. The original hardcoded its item
///    list. Categories are derived from whatever items the host supplies.
///  * **Her hand-drawn SVG artwork was not ported.** This uses the emoji the
///    host supplies in `extra['emoji']`. Real illustrations are a design
///    asset for Maharshitha and Ruthika to supply; this is deliberately a
///    placeholder and is noted as such in the integration notes.
///  * A wrong choice can be retried rather than advancing, and only the
///    opaque item and category ids ever reach telemetry.
///
/// **Scope note:** Picture Sorting is not one of the nine catalogue games.
/// It is registered as an extra activity at the user's explicit request.
class PictureSortingGame extends TesseractGame {
  const PictureSortingGame({
    super.key,
    required super.config,
    required super.onEvent,
    required super.onFinish,
  });

  /// The real settings for [level], never just the level number.
  static Map<String, Object?> difficultyParamsForLevel(int level) {
    switch (level) {
      case 1:
        return <String, Object?>{'itemCount': 4, 'categoryCount': 2};
      case 2:
        return <String, Object?>{'itemCount': 6, 'categoryCount': 2};
      default:
        return <String, Object?>{'itemCount': 8, 'categoryCount': 3};
    }
  }

  @override
  State<PictureSortingGame> createState() => _PictureSortingGameState();
}

class _PictureSortingGameState extends State<PictureSortingGame>
    with WidgetsBindingObserver, TesseractGameStateMixin<PictureSortingGame> {
  final TesseractEventRecorder _recorder = TesseractEventRecorder();
  late final Random _random = Random(widget.config.level * 65537);

  late final List<GameItem> _items = _selectItems();
  late final List<String> _categories = _deriveCategories();

  int _index = 0;
  int _attempt = 1;
  bool _paused = false;
  bool _correctShown = false;
  String? _wrongCategory;
  String? _hintedCategory;

  @override
  TesseractEventRecorder get eventRecorder => _recorder;

  int get _itemCount =>
      (widget.config.difficultyParams['itemCount'] as int?) ?? 4;

  List<GameItem> _selectItems() {
    final List<GameItem> usable = widget.config.items
        .where((GameItem i) => (i.extra['category'] as String?) != null)
        .toList()
      ..shuffle(_random);
    return usable.take(_itemCount).toList();
  }

  List<String> _deriveCategories() {
    final Set<String> found = <String>{
      for (final GameItem item in _items) item.extra['category'] as String,
    };
    return found.toList()..sort();
  }

  bool get _hasContent => _items.isNotEmpty && _categories.length >= 2;

  GameItem get _current => _items[_index];
  String get _correctCategory => _current.extra['category'] as String;

  void _handleHelp() {
    if (_paused || !_hasContent) {
      return;
    }
    widget.onEvent(_recorder.hintRequested());
    setState(() => _hintedCategory = _correctCategory);
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

  @override
  void initState() {
    super.initState();
    widget.onEvent(_recorder.sessionStarted());
  }

  void _choose(String category) {
    if (_paused || _correctShown || !_hasContent) {
      return;
    }
    final bool correct = category == _correctCategory;

    widget.onEvent(_recorder.custom('item_sorted', <String, Object?>{
      'itemId': _current.id,
      'categoryId': category,
      'correct': correct,
      'attempt': _attempt,
    }));

    if (!correct) {
      setState(() {
        _wrongCategory = category;
        _attempt += 1;
      });
      return;
    }
    setState(() {
      _correctShown = true;
      _wrongCategory = null;
    });
  }

  void _next() {
    if (_index + 1 >= _items.length) {
      widget.onEvent(_recorder.custom('sorting_completed'));
      _finish(GameResultStatus.completed);
      return;
    }
    setState(() {
      _index += 1;
      _attempt = 1;
      _correctShown = false;
      _wrongCategory = null;
      _hintedCategory = null;
    });
  }

  String _labelFor(String category) =>
      category.isEmpty ? category : category[0].toUpperCase() + category.substring(1);

  @override
  Widget build(BuildContext context) {
    final GameStrings strings = widget.config.strings;

    if (!_hasContent) {
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
              'There are no pictures set up for this activity yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
    }

    return TesseractGameScaffold(
      strings: strings,
      paused: _paused,
      helpEnabled: !_correctShown,
      onHelp: _handleHelp,
      onBreak: _handleBreak,
      onResume: _handleResume,
      onFinish: () => _finish(GameResultStatus.stoppedByUser),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Picture ${_index + 1} of ${_items.length}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      (_current.extra['emoji'] as String?) ?? '🖼️',
                      style: const TextStyle(fontSize: 72),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _current.label ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Where does this belong?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              for (final String category in _categories)
                _categoryButton(category),
              if (_wrongCategory != null && !_correctShown) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Not quite — have another look.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              if (_correctShown) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'That\'s right.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(_index + 1 >= _items.length
                        ? 'Finish'
                        : 'Continue'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryButton(String category) {
    final bool wrong = category == _wrongCategory;
    final bool hinted = category == _hintedCategory;
    final bool right = _correctShown && category == _correctCategory;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: _correctShown ? null : () => _choose(category),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(68),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: wrong
                ? Colors.orange.shade700
                : (hinted || right)
                    ? Colors.green.shade700
                    : Colors.black26,
            width: wrong || hinted || right ? 3 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _labelFor(category),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (hinted) ...<Widget>[
              const SizedBox(width: 10),
              const Icon(Icons.lightbulb, size: 22),
            ],
            if (right) ...<Widget>[
              const SizedBox(width: 10),
              const Icon(Icons.check_rounded, size: 24),
            ],
            if (wrong) ...<Widget>[
              const SizedBox(width: 10),
              const Icon(Icons.refresh_rounded, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
