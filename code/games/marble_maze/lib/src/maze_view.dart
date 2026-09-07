import 'package:flutter/material.dart';

import 'maze_level.dart';
import 'maze_painter.dart';

/// Renders the tactile maze board and turns a drag anywhere on the board
/// into a target position. The patient never has to grab the marble exactly.
class MazeView extends StatefulWidget {
  const MazeView({
    super.key,
    required this.level,
    required this.marblePosition,
    required this.onDrag,
    this.showHint = false,
  });

  final MazeLevel level;
  final Offset marblePosition;
  final void Function(Offset gridPosition) onDrag;
  final bool showHint;

  @override
  State<MazeView> createState() => _MazeViewState();
}

class _MazeViewState extends State<MazeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  bool _animationsDisabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool disabled = MediaQuery.disableAnimationsOf(context);
    if (disabled == _animationsDisabled && _ambient.isAnimating) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _ambient
        ..stop()
        ..value = 0.5;
    } else {
      _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double byWidth = constraints.maxWidth / widget.level.cols;
          final double byHeight = constraints.maxHeight / widget.level.rows;
          final double cellSize = byWidth < byHeight ? byWidth : byHeight;
          final Size boardSize =
              Size(widget.level.cols * cellSize, widget.level.rows * cellSize);

          void handle(Offset localPixelPosition) {
            widget.onDrag(Offset(localPixelPosition.dx / cellSize,
                localPixelPosition.dy / cellSize));
          }

          return Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cellSize * 0.25),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF49301F).withValues(alpha: 0.34),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cellSize * 0.25),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (DragStartDetails details) =>
                        handle(details.localPosition),
                    onPanUpdate: (DragUpdateDetails details) =>
                        handle(details.localPosition),
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (BuildContext context, Widget? child) {
                        return CustomPaint(
                          size: boardSize,
                          painter: MazePainter(
                            level: widget.level,
                            marblePosition: widget.marblePosition,
                            cellSize: cellSize,
                            showHint: widget.showHint,
                            pulse: _ambient.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
