import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import 'maze_level.dart';
import 'maze_view.dart';
import 'marble_tilt_input.dart';

/// Marble Maze (G3): guide a marble to the goal.
///
/// In tilt mode the Android host supplies fused gyroscope motion through a
/// platform event channel. Touch remains available when the configured mode
/// is touch, or automatically when that motion stream is unavailable.
///
/// Grid-based collision, not a physics engine: walls are grid cells,
/// movement is continuous but constrained by cell walls, stepped on a fixed
/// timestep. No gravity, no bouncing, no Flame, no third-party engine.
class MarbleMazeGame extends TesseractGame {
  const MarbleMazeGame({
    super.key,
    required super.config,
    required super.onEvent,
    required super.onFinish,
    this.tiltInput = const MarbleTiltInput(),
  });

  /// Injectable only so the fused motion behavior can be verified without
  /// physical sensors in widget tests. Production callers use the default.
  final MarbleTiltInput tiltInput;

  /// The real board settings for [level] — corridor width, turn count, and
  /// dead-end count — never just the level number. See the
  /// `difficultyParamsForLevel` convention documented on [TesseractGame].
  static Map<String, Object?> difficultyParamsForLevel(int level) {
    final MazeLevel maze = MazeLevel.forLevel(level);
    return <String, Object?>{
      'corridorWidth': maze.corridorWidth,
      'turnCount': maze.turnCount,
      'deadEndCount': maze.deadEndCount,
    };
  }

  @override
  State<MarbleMazeGame> createState() => _MarbleMazeGameState();
}

class _MarbleMazeGameState extends State<MarbleMazeGame>
    with
        WidgetsBindingObserver,
        SingleTickerProviderStateMixin,
        TesseractGameStateMixin<MarbleMazeGame> {
  static const Duration _fixedDt = Duration(milliseconds: 16);
  static const double _gridUnitsPerSecond = 2.2; // low, stable, forgiving speed
  static const double _tiltGridUnitsPerSecond = 2.65;
  static const int _calibrationSampleCount = 12;
  static const double _tiltDeadZone = 0.035;

  final TesseractEventRecorder _recorder = TesseractEventRecorder();
  late final MazeLevel _level = MazeLevel.forLevel(widget.config.level);

  late Offset _marblePosition = _cellCenter(_level.start);
  late Offset _targetPosition = _marblePosition;

  late final Ticker _ticker;
  StreamSubscription<({double x, double y})>? _tiltSubscription;
  Duration _lastTick = Duration.zero;
  Duration _accumulator = Duration.zero;

  Offset _tiltNeutralTotal = Offset.zero;
  Offset _tiltNeutral = Offset.zero;
  Offset _tiltVector = Offset.zero;
  int _tiltCalibrationSamples = 0;
  bool _tiltAvailable = false;

  final Set<String> _activeCollisionWallIds = <String>{};
  final Set<(int, int)> _enteredDeadEnds = <(int, int)>{};
  bool _paused = false;
  bool _finished = false;
  bool _showHint = false;
  DateTime? _lastCollisionHapticAt;

  @override
  TesseractEventRecorder get eventRecorder => _recorder;

  @override
  void initState() {
    super.initState();
    widget.onEvent(_recorder.sessionStarted());
    _ticker = createTicker(_onTick)..start();
    if (widget.config.inputMode == GameInputMode.tilt) {
      _startTiltInput();
    }
  }

  @override
  void dispose() {
    unawaited(_tiltSubscription?.cancel());
    _ticker.dispose();
    super.dispose();
  }

  void _startTiltInput() {
    _tiltSubscription = widget.tiltInput.samples().listen(
      _handleTiltSample,
      onError: (Object _) {
        if (mounted) {
          setState(() {
            _tiltAvailable = false;
            _tiltVector = Offset.zero;
          });
        }
      },
      cancelOnError: false,
    );
  }

  void _handleTiltSample(({double x, double y}) sample) {
    final Offset raw = Offset(sample.x, sample.y);
    if (_tiltCalibrationSamples < _calibrationSampleCount) {
      _tiltNeutralTotal += raw;
      _tiltCalibrationSamples += 1;
      if (_tiltCalibrationSamples == _calibrationSampleCount) {
        _tiltNeutral = _tiltNeutralTotal / _calibrationSampleCount.toDouble();
        if (mounted) {
          setState(() => _tiltAvailable = true);
        }
      }
      return;
    }

    Offset adjusted = (raw - _tiltNeutral) * 2.4;
    adjusted = Offset(
      adjusted.dx.abs() < _tiltDeadZone ? 0 : adjusted.dx,
      adjusted.dy.abs() < _tiltDeadZone ? 0 : adjusted.dy,
    );
    if (adjusted.distance > 1) {
      adjusted = adjusted / adjusted.distance;
    }
    _tiltVector = Offset.lerp(_tiltVector, adjusted, 0.22)!;
  }

  Offset _cellCenter((int, int) cell) => Offset(cell.$1 + 0.5, cell.$2 + 0.5);

  void _onTick(Duration elapsed) {
    if (_paused || _finished) {
      _lastTick = elapsed;
      return;
    }
    Duration delta = elapsed - _lastTick;
    _lastTick = elapsed;
    if (delta < Duration.zero) {
      delta = Duration.zero;
    }
    _accumulator += delta;

    bool moved = false;
    while (_accumulator >= _fixedDt) {
      _step(_fixedDt);
      _accumulator -= _fixedDt;
      moved = true;
      if (_finished) {
        break;
      }
    }
    if (moved) {
      setState(() {});
    }
  }

  void _step(Duration dt) {
    final double maxStep = _gridUnitsPerSecond *
        dt.inMicroseconds /
        Duration.microsecondsPerSecond;
    final Offset delta = _targetPosition - _marblePosition;
    final double distance = delta.distance;
    final Set<String> blockedThisTick = <String>{};

    final bool usesTilt =
        widget.config.inputMode == GameInputMode.tilt && _tiltAvailable;
    if (usesTilt || distance > 1e-6) {
      final Offset stepVector;
      if (usesTilt) {
        final double tiltStep = _tiltGridUnitsPerSecond *
            dt.inMicroseconds /
            Duration.microsecondsPerSecond;
        stepVector = _tiltVector * tiltStep;
      } else {
        final double stepLength = distance < maxStep ? distance : maxStep;
        stepVector = Offset(
            delta.dx / distance * stepLength, delta.dy / distance * stepLength);
      }

      final Offset afterX =
          Offset(_marblePosition.dx + stepVector.dx, _marblePosition.dy);
      final String? wallX = _wallIdAt(afterX);
      if (wallX == null) {
        _marblePosition = afterX;
      } else {
        blockedThisTick.add(wallX);
      }

      final Offset afterY =
          Offset(_marblePosition.dx, _marblePosition.dy + stepVector.dy);
      final String? wallY = _wallIdAt(afterY);
      if (wallY == null) {
        _marblePosition = afterY;
      } else {
        blockedThisTick.add(wallY);
      }
    }

    for (final String id in blockedThisTick) {
      if (_activeCollisionWallIds.add(id)) {
        widget.onEvent(
            _recorder.custom('collision', <String, Object?>{'wallId': id}));
        final DateTime now = DateTime.now();
        if (_lastCollisionHapticAt == null ||
            now.difference(_lastCollisionHapticAt!) >
                const Duration(milliseconds: 250)) {
          _lastCollisionHapticAt = now;
          unawaited(HapticFeedback.selectionClick());
        }
      }
    }
    _activeCollisionWallIds
        .removeWhere((String id) => !blockedThisTick.contains(id));

    _checkDeadEndAndGoal();
  }

  /// Null if the cell at [pos] is open; otherwise a stable id for that wall
  /// (or out-of-bounds) cell.
  String? _wallIdAt(Offset pos) {
    final int col = pos.dx.floor();
    final int row = pos.dy.floor();
    if (!_level.isOpen(col, row)) {
      return 'wall_${row}_$col';
    }
    return null;
  }

  void _checkDeadEndAndGoal() {
    final (int, int) cell =
        (_marblePosition.dx.floor(), _marblePosition.dy.floor());

    if (_level.deadEndCells.contains(cell) && _enteredDeadEnds.add(cell)) {
      widget.onEvent(_recorder.custom('dead_end_entered',
          <String, Object?>{'cellId': 'cell_${cell.$2}_${cell.$1}'}));
    }

    if (!_finished && cell == _level.goal) {
      _finished = true;
      widget.onEvent(_recorder.custom('goal_reached'));
      unawaited(HapticFeedback.mediumImpact());
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

  void _handleDrag(Offset gridPosition) {
    if (_paused || _finished) {
      return;
    }
    if (widget.config.inputMode == GameInputMode.tilt && _tiltAvailable) {
      return;
    }
    setState(() => _targetPosition = gridPosition);
  }

  void _handleHelp() {
    widget.onEvent(_recorder.hintRequested());
    unawaited(HapticFeedback.selectionClick());
    setState(() => _showHint = true);
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
      color: const Color(0xFFF5EBDD),
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              _buildControls(strings),
              Expanded(
                child: MazeView(
                  level: _level,
                  marblePosition: _marblePosition,
                  showHint: _showHint,
                  onDrag: _handleDrag,
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
