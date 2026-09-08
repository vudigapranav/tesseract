import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// G8 Daily Routine Recall.
///
/// Ported to Flutter from Ruthika's original HTML/CSS/JS implementation
/// (github.com/ruthikareddy678/GAMES, `game2`, commit a504486). The mechanic
/// is hers and is preserved: show a step of a familiar daily routine, ask
/// which step comes next, offer the correct answer among distractors drawn
/// from elsewhere in the same routine.
///
/// Deliberate changes made for the Tesseract contract and patient-safety
/// rules, recorded here so the differences from her original are reviewable:
///
///  * **Answers are compared by stable id, not by name.** The original
///    compared step names, which breaks as soon as two steps share a label
///    (her own default routine has "Eating lunch" and "Eating dinner" sharing
///    an icon) and would put personal text in telemetry. Only opaque ids
///    appear in payloads.
///  * **No score and no stars.** The original showed a score-dependent star
///    rating. Tesseract patient screens carry no score, ranking or failure
///    state, so a wrong answer simply invites another try.
///  * **The routine comes from the caregiver**, through `config.items`. The
///    original hardcoded a default routine that included a medicine step;
///    importing that as everyone's routine would be presenting medical advice
///    the caregiver never entered.
///  * **No speech synthesis.** The original used the browser speech API.
///    Audio is a host-level setting here and no audio is implemented yet, so
///    the port is silent rather than pretending to read aloud.
///  * A wrong answer can be retried. First-attempt correctness is recorded
///    separately from eventual completion, which is what the analytics
///    acceptance for this game asks for.
class RoutineRecallGame extends TesseractGame {
  const RoutineRecallGame({
    super.key,
    required super.config,
    required super.onEvent,
    required super.onFinish,
  });

  /// The real settings for [level] — how much of the routine is used and how
  /// many choices are offered — never just the level number.
  static Map<String, Object?> difficultyParamsForLevel(int level) {
    switch (level) {
      case 1:
        return <String, Object?>{'stepCount': 3, 'optionCount': 2};
      case 2:
        return <String, Object?>{'stepCount': 4, 'optionCount': 3};
      default:
        return <String, Object?>{'stepCount': 5, 'optionCount': 3};
    }
  }

  @override
  State<RoutineRecallGame> createState() => _RoutineRecallGameState();
}

class _RoutineRecallGameState extends State<RoutineRecallGame>
    with WidgetsBindingObserver, TesseractGameStateMixin<RoutineRecallGame> {
  final TesseractEventRecorder _recorder = TesseractEventRecorder();

  /// Seeded from the level so a session is reproducible for a fixture, while
  /// still varying between levels.
  late final Random _random = Random(widget.config.level * 7919);

  late final List<GameItem> _routine = _buildRoutine();
  late List<GameItem> _options;

  int _index = 0;
  int _attempt = 1;
  bool _paused = false;
  bool _showingFeedback = false;
  String? _wrongChoiceId;
  String? _revealedId;

  @override
  TesseractEventRecorder get eventRecorder => _recorder;

  int get _optionCount =>
      (widget.config.difficultyParams['optionCount'] as int?) ?? 3;

  /// The routine the patient is asked about.
  ///
  /// Uses the caregiver's ordered content. A routine needs at least three
  /// steps to ask even one "what comes next" question with a distractor, so a
  /// shorter list is padded from whatever content exists rather than failing.
  List<GameItem> _buildRoutine() {
    final List<GameItem> source = widget.config.items;
    if (source.isEmpty) {
      return const <GameItem>[];
    }
    final int wanted = min(_stepCountFromConfig(), source.length);
    return source.take(max(wanted, min(3, source.length))).toList();
  }

  int _stepCountFromConfig() =>
      (widget.config.difficultyParams['stepCount'] as int?) ?? 3;

  @override
  void initState() {
    super.initState();
    widget.onEvent(_recorder.sessionStarted());
    _options = _buildOptions();
    _emitStepPresented();
  }

  bool get _hasQuestion => _routine.length >= 2 && _index < _routine.length - 1;

  GameItem get _current => _routine[_index];
  GameItem get _correctNext => _routine[_index + 1];

  void _emitStepPresented() {
    if (!_hasQuestion) {
      return;
    }
    widget.onEvent(_recorder.custom(
        'step_presented', <String, Object?>{'stepId': _current.id}));
  }

  /// Correct answer plus distractors taken from elsewhere in the routine,
  /// exactly as the original does.
  List<GameItem> _buildOptions() {
    if (!_hasQuestion) {
      return const <GameItem>[];
    }
    final List<GameItem> pool = <GameItem>[
      for (int i = 0; i < _routine.length; i++)
        if (i != _index && i != _index + 1) _routine[i],
    ]..shuffle(_random);

    final List<GameItem> options = <GameItem>[
      _correctNext,
      ...pool.take(max(0, _optionCount - 1)),
    ]..shuffle(_random);
    return options;
  }

  void _handleHelp() {
    if (_paused || !_hasQuestion) {
      return;
    }
    widget.onEvent(_recorder.hintRequested());
    setState(() => _revealedId = _correctNext.id);
  }

  void _handleBreak() {
    widget.onEvent(_recorder.paused(reason: 'break'));
    setState(() => _paused = true);
  }

  void _handleResume() {
    widget.onEvent(_recorder.resumed());
    setState(() => _paused = false);
  }

  void _handleFinishFromPause() {
    _finish(GameResultStatus.stoppedByUser);
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

  void _choose(GameItem option) {
    if (_paused || _showingFeedback || !_hasQuestion) {
      return;
    }
    final bool correct = option.id == _correctNext.id;

    widget.onEvent(_recorder.custom('attempt_resolved', <String, Object?>{
      'stepId': _current.id,
      'chosenId': option.id,
      'correct': correct,
      // Lets first-attempt accuracy be separated from eventual completion
      // without the game itself computing an accuracy figure.
      'attempt': _attempt,
    }));

    if (!correct) {
      // Gentle: name what happened, keep the question open, no penalty.
      setState(() {
        _wrongChoiceId = option.id;
        _attempt += 1;
      });
      return;
    }

    setState(() {
      _showingFeedback = true;
      _wrongChoiceId = null;
    });
  }

  void _continue() {
    final bool last = _index + 1 >= _routine.length - 1;
    if (last) {
      widget.onEvent(_recorder.custom('routine_completed'));
      _finish(GameResultStatus.completed);
      return;
    }
    setState(() {
      _index += 1;
      _attempt = 1;
      _showingFeedback = false;
      _wrongChoiceId = null;
      _revealedId = null;
      _options = _buildOptions();
    });
    _emitStepPresented();
  }

  String _emojiFor(GameItem item) =>
      (item.extra['emoji'] as String?) ?? '•';

  @override
  Widget build(BuildContext context) {
    final GameStrings strings = widget.config.strings;

    if (!_hasQuestion && !_recorder.isFinished) {
      // Not enough content to ask anything. Say so plainly instead of
      // showing an empty board.
      return TesseractGameScaffold(
        strings: strings,
        paused: _paused,
        helpEnabled: false,
        onHelp: _handleHelp,
        onBreak: _handleBreak,
        onResume: _handleResume,
        onFinish: _handleFinishFromPause,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'This routine needs a few more steps before we can play.',
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
      helpEnabled: !_showingFeedback,
      onHelp: _handleHelp,
      onBreak: _handleBreak,
      onResume: _handleResume,
      onFinish: _handleFinishFromPause,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _progressDots(),
              const SizedBox(height: 24),
              _currentStepCard(),
              const SizedBox(height: 20),
              Text(
                'What comes next?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final GameItem option in _options) _optionButton(option),
              if (_wrongChoiceId != null && !_showingFeedback) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Not quite — have another look.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              if (_showingFeedback) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'That\'s right.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Position in the routine, with no count of right or wrong answers.
  Widget _progressDots() {
    final int total = max(1, _routine.length - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= _index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }

  Widget _currentStepCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          Text('Just now', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(_emojiFor(_current), style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            _current.label ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _optionButton(GameItem option) {
    final bool wrong = option.id == _wrongChoiceId;
    final bool revealed = option.id == _revealedId;
    final bool chosenRight = _showingFeedback && option.id == _correctNext.id;

    // State is carried by border, icon and text as well as fill, so it does
    // not depend on colour alone.
    final Color border = wrong
        ? Colors.orange.shade700
        : (revealed || chosenRight)
            ? Colors.green.shade700
            : Colors.black26;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: revealed
            ? '${option.label}. Suggested by Help.'
            : option.label,
        child: OutlinedButton(
          onPressed: _showingFeedback ? null : () => _choose(option),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(72),
            side: BorderSide(color: border, width: revealed || wrong ? 3 : 1.5),
            backgroundColor: Colors.white,
          ),
          child: Row(
            children: <Widget>[
              Text(_emojiFor(option), style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.label ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (revealed) const Icon(Icons.lightbulb, size: 22),
              if (chosenRight) const Icon(Icons.check_rounded, size: 24),
              if (wrong) const Icon(Icons.refresh_rounded, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
