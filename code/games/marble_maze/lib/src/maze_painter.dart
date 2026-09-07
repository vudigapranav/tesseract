import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'maze_level.dart';

/// Paints the maze as a tactile wooden board with recessed ivory channels,
/// a glass marble and a softly illuminated goal. All decoration is visual;
/// collision remains the deterministic grid model in [MazeLevel].
class MazePainter extends CustomPainter {
  MazePainter({
    required this.level,
    required this.marblePosition,
    required this.cellSize,
    required this.showHint,
    required this.pulse,
  });

  final MazeLevel level;
  final Offset marblePosition;
  final double cellSize;
  final bool showHint;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(cellSize * 0.25)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFB97B46), Color(0xFF8D5733)],
        ).createShader(bounds),
    );
    _drawWoodGrain(canvas, size);
    _drawChannels(canvas);
    if (showHint) _drawHintPath(canvas);
    _drawGoal(canvas);
    _drawMarble(canvas);
    _drawScrews(canvas, size);
  }

  void _drawWoodGrain(Canvas canvas, Size size) {
    final Paint grain = Paint()
      ..color = const Color(0xFF6F3F24).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, cellSize * 0.035);
    for (int i = 0; i < 11; i++) {
      final double y = (i + 0.55) * size.height / 11;
      final Path line = Path()
        ..moveTo(0, y)
        ..cubicTo(size.width * 0.28, y - 5, size.width * 0.62, y + 7,
            size.width, y - 2);
      canvas.drawPath(line, grain);
    }
    for (final Offset knot in <Offset>[
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.48),
      Offset(size.width * 0.30, size.height * 0.83),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: knot, width: cellSize * 0.55, height: cellSize * 0.22),
        grain,
      );
    }
  }

  void _drawChannels(Canvas canvas) {
    final Paint channel = Paint()..color = const Color(0xFFF2E5C8);
    final Paint channelLight = Paint()
      ..color = const Color(0xFFFFF8E8).withValues(alpha: 0.72);
    final Paint edgeDark = Paint()
      ..color = const Color(0xFF5B321D).withValues(alpha: 0.72)
      ..strokeWidth = math.max(2.3, cellSize * 0.10)
      ..strokeCap = StrokeCap.square;
    final Paint edgeLight = Paint()
      ..color = const Color(0xFFFFDDAA).withValues(alpha: 0.72)
      ..strokeWidth = math.max(1, cellSize * 0.035)
      ..strokeCap = StrokeCap.square;

    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        if (!level.grid[row][col]) continue;
        final Rect cell =
            Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize);
        canvas.drawRect(cell, channel);
        canvas.drawRect(cell.deflate(cellSize * 0.10), channelLight);

        final double l = cell.left;
        final double r = cell.right;
        final double t = cell.top;
        final double b = cell.bottom;
        if (!level.isOpen(col, row - 1)) {
          canvas.drawLine(Offset(l, t), Offset(r, t), edgeDark);
          canvas.drawLine(Offset(l, t + 2), Offset(r, t + 2), edgeLight);
        }
        if (!level.isOpen(col - 1, row)) {
          canvas.drawLine(Offset(l, t), Offset(l, b), edgeDark);
          canvas.drawLine(Offset(l + 2, t), Offset(l + 2, b), edgeLight);
        }
        if (!level.isOpen(col, row + 1)) {
          canvas.drawLine(Offset(l, b), Offset(r, b), edgeDark);
        }
        if (!level.isOpen(col + 1, row)) {
          canvas.drawLine(Offset(r, t), Offset(r, b), edgeDark);
        }
      }
    }
  }

  void _drawHintPath(Canvas canvas) {
    final (int, int) current =
        (marblePosition.dx.floor(), marblePosition.dy.floor());
    final List<(int, int)> cells = level.shortestPathCells(current, level.goal);
    if (cells.length < 2) return;

    final Path route = Path();
    for (int i = 0; i < cells.length; i++) {
      final Offset p = Offset(
          (cells[i].$1 + 0.5) * cellSize, (cells[i].$2 + 0.5) * cellSize);
      if (i == 0) {
        route.moveTo(p.dx, p.dy);
      } else {
        route.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF2E7D5B).withValues(alpha: 0.17 + pulse * 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.40
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF2E7D5B).withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.5, cellSize * 0.08)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawGoal(Canvas canvas) {
    final Offset center = Offset(
        (level.goal.$1 + 0.5) * cellSize, (level.goal.$2 + 0.5) * cellSize);
    final double radius = cellSize * (0.34 + pulse * 0.025);
    canvas.drawCircle(
      center,
      radius + cellSize * 0.11,
      Paint()
        ..color =
            const Color(0xFFFFC857).withValues(alpha: 0.30 + pulse * 0.16),
    );
    canvas.drawCircle(center, radius + cellSize * 0.05,
        Paint()..color = const Color(0xFFD99D1C));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.30, -0.35),
          colors: <Color>[Color(0xFF5B4A2A), Color(0xFF211B15)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawMarble(Canvas canvas) {
    final Offset center =
        Offset(marblePosition.dx * cellSize, marblePosition.dy * cellSize);
    final double radius = cellSize * 0.32;
    canvas.drawOval(
      Rect.fromCenter(
          center: center + Offset(cellSize * 0.06, cellSize * 0.12),
          width: radius * 2.0,
          height: radius * 1.18),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawCircle(center, radius + math.max(1.5, cellSize * 0.035),
        Paint()..color = const Color(0xFFEFFDFC));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.42, -0.46),
          radius: 0.92,
          colors: <Color>[
            Color(0xFFCFFFF7),
            Color(0xFF39A7A0),
            Color(0xFF155F62)
          ],
          stops: <double>[0, 0.48, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center - Offset(radius * 0.30, radius * 0.33),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.78),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.74),
      0.15,
      1.7,
      false,
      Paint()
        ..color = const Color(0xFF0C4548).withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, cellSize * 0.035),
    );
  }

  void _drawScrews(Canvas canvas, Size size) {
    final double radius = math.max(2.5, cellSize * 0.085);
    for (final Offset center in <Offset>[
      Offset(radius * 1.8, radius * 1.8),
      Offset(size.width - radius * 1.8, radius * 1.8),
      Offset(radius * 1.8, size.height - radius * 1.8),
      Offset(size.width - radius * 1.8, size.height - radius * 1.8),
    ]) {
      canvas.drawCircle(
          center, radius, Paint()..color = const Color(0xFF60442F));
      canvas.drawLine(
        center - Offset(radius * 0.55, 0),
        center + Offset(radius * 0.55, 0),
        Paint()
          ..color = const Color(0xFFCCAB82)
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MazePainter oldDelegate) {
    return oldDelegate.marblePosition != marblePosition ||
        oldDelegate.level != level ||
        oldDelegate.showHint != showHint ||
        oldDelegate.pulse != pulse;
  }
}
