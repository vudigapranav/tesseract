import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import 'route_graph.dart';
import 'route_map_painter.dart';
import 'route_map_view.dart';
import 'route_topology.dart';

/// Route Quest (G2): go somewhere familiar, collect one thing, and find the
/// way back.
///
/// Built as a node graph — locations are nodes, connections are edges, the
/// patient moves by tapping an adjacent location. No tile map, no character
/// controller, no physics, no pathfinding AI: BFS over the graph only ever
/// measures a route (see [RouteGraph.shortestPathLength]), it never plays
/// one.
///
/// Difficulty changes the map only — see [difficultyParamsForLevel] — never
/// a time limit or movement speed. This game never sets its own level.
class RouteQuestGame extends TesseractGame {
  const RouteQuestGame({
    super.key,
    required super.config,
    required super.onEvent,
    required super.onFinish,
  });

  /// The real map settings for [level] — node count, branch count, and
  /// whether a return leg is required — never just the level number. See
  /// the `difficultyParamsForLevel` convention documented on
  /// [TesseractGame].
  static Map<String, Object?> difficultyParamsForLevel(int level) {
    final RouteTopology topology = RouteTopology.forLevel(level);
    return <String, Object?>{
      'nodeCount': topology.nodeCount,
      'branchCount': topology.branchCount,
      'requiresReturn': true,
    };
  }

  @override
  State<RouteQuestGame> createState() => _RouteQuestGameState();
}

enum _Phase { outbound, returning }

class _RouteQuestGameState extends State<RouteQuestGame>
    with WidgetsBindingObserver, TesseractGameStateMixin<RouteQuestGame> {
  final TesseractEventRecorder _recorder = TesseractEventRecorder();

  late final RouteTopology _topology =
      RouteTopology.forLevel(widget.config.level);
  late final RouteGraph _graph =
      buildRouteGraph(_topology, widget.config.items);
  late final List<Offset> _positions = routeLayoutForLevel(widget.config.level);

  late int _currentIndex = _graph.homeIndex;
  _Phase _phase = _Phase.outbound;
  bool _paused = false;
  int? _hintedIndex;

  @override
  TesseractEventRecorder get eventRecorder => _recorder;

  @override
  void initState() {
    super.initState();
    widget.onEvent(_recorder.sessionStarted());
  }

  int get _currentTarget =>
      _phase == _Phase.outbound ? _graph.destinationIndex : _graph.homeIndex;

  void _handleHelp() {
    widget.onEvent(_recorder.hintRequested());
    unawaited(HapticFeedback.selectionClick());
    setState(() =>
        _hintedIndex = _graph.nextHopToward(_currentIndex, _currentTarget));
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
    final GameEvent event =
        _recorder.sessionFinished(GameResultStatus.stoppedByUser);
    widget.onEvent(event);
    widget.onFinish(
      GameResult(
          status: GameResultStatus.stoppedByUser,
          finalSeq: _recorder.lastSeq,
          assisted: _recorder.assisted),
    );
  }

  void _handleTapNode(int index) {
    if (_paused || index == _currentIndex) {
      return;
    }
    if (!_graph.areAdjacent(_currentIndex, index)) {
      widget.onEvent(
        _recorder.custom('wrong_interaction',
            <String, Object?>{'objectId': _graph.nodes[index].item.id}),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
      _hintedIndex = null;
    });
    final bool reachesMilestone =
        (_phase == _Phase.outbound && index == _graph.destinationIndex) ||
            (_phase == _Phase.returning && index == _graph.homeIndex);
    unawaited(reachesMilestone
        ? HapticFeedback.mediumImpact()
        : HapticFeedback.selectionClick());
    widget.onEvent(_recorder.custom('location_entered',
        <String, Object?>{'nodeId': _graph.nodes[index].item.id}));

    if (_phase == _Phase.outbound && index == _graph.destinationIndex) {
      widget.onEvent(_recorder.custom('destination_reached'));
      widget.onEvent(_recorder.custom('item_collected'));
      setState(() => _phase = _Phase.returning);
      return;
    }

    if (_phase == _Phase.returning && index == _graph.homeIndex) {
      widget.onEvent(_recorder.custom('return_completed'));
      final GameEvent finishEvent =
          _recorder.sessionFinished(GameResultStatus.completed);
      widget.onEvent(finishEvent);
      widget.onFinish(
        GameResult(
            status: GameResultStatus.completed,
            finalSeq: _recorder.lastSeq,
            assisted: _recorder.assisted),
      );
    }
  }

  Widget _buildControls(GameStrings strings) {
    return Material(
      color: const Color(0xFFFBF7ED),
      elevation: 3,
      shadowColor: const Color(0xFF315C4A).withValues(alpha: 0.18),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _handleHelp,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 23),
                    label: FittedBox(child: Text(strings.helpButtonLabel)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F6148),
                      side: const BorderSide(
                          color: Color(0xFF7AA48F), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _handleBreak,
                    icon: const Icon(Icons.pause_rounded, size: 25),
                    label: FittedBox(child: Text(strings.breakButtonLabel)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F6148),
                      side: const BorderSide(
                          color: Color(0xFF7AA48F), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyCue(GameStrings strings) {
    final String message = strings.values['destination_reached_body'] ?? '';
    if (_phase != _Phase.returning || message.isEmpty) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: const Color(0xFFE7F2EA),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.flag_rounded, color: Color(0xFFB94D2B), size: 24),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF234B3C)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(GameStrings strings) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(strings.pausedTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(strings.pausedBody, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _handleResume,
                      child: FittedBox(child: Text(strings.resumeButtonLabel)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _handleFinishFromPause,
                      child:
                          FittedBox(child: Text(strings.finishNowButtonLabel)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameStrings strings = widget.config.strings;
    return Material(
      color: const Color(0xFFF8F1DF),
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              _buildControls(strings),
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _buildJourneyCue(strings)),
              Expanded(
                child: RouteMapView(
                  graph: _graph,
                  positions: _positions,
                  currentIndex: _currentIndex,
                  destinationIndex: _graph.destinationIndex,
                  hintedIndex: _hintedIndex,
                  showLabels: widget.config.showLabels,
                  isReturning: _phase == _Phase.returning,
                  onTapNode: _handleTapNode,
                ),
              ),
            ],
          ),
          if (_paused) _buildPauseOverlay(strings),
        ],
      ),
    );
  }
}
