import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'route_graph.dart';

/// Large illustrated landmarks with an even larger invisible hit area.
const double kRouteNodeRadius = 31;
const double kRouteNodeHitRadius = 42;

/// Hand-authored maps read as small places rather than graph diagrams. The
/// topology and metrics stay unchanged; these positions only create a more
/// natural journey across the canvas.
List<Offset> routeLayoutForLevel(int level) {
  return switch (level) {
    1 => const <Offset>[
        Offset(0.24, 0.17),
        Offset(0.58, 0.46),
        Offset(0.73, 0.81),
      ],
    2 => const <Offset>[
        Offset(0.20, 0.13),
        Offset(0.46, 0.38),
        Offset(0.28, 0.82),
        Offset(0.79, 0.37),
        Offset(0.76, 0.69),
      ],
    _ => const <Offset>[
        Offset(0.20, 0.12),
        Offset(0.45, 0.31),
        Offset(0.37, 0.58),
        Offset(0.68, 0.84),
        Offset(0.79, 0.20),
        Offset(0.78, 0.59),
      ],
  };
}

/// Paints a warm illustrated map with raised roads, recognisable landmarks,
/// a moving traveller and a gentle visual hint. The underlying interaction
/// remains the same small, deterministic node graph.
class RouteMapPainter extends CustomPainter {
  RouteMapPainter({
    required this.graph,
    required this.positions,
    required this.currentIndex,
    required this.destinationIndex,
    required this.hintedIndex,
    required this.showLabels,
    required this.travellerPosition,
    required this.pulse,
    required this.isReturning,
    required this.textScale,
  });

  final RouteGraph graph;
  final List<Offset> positions;
  final int currentIndex;
  final int destinationIndex;
  final int? hintedIndex;
  final bool showLabels;
  final Offset travellerPosition;
  final double pulse;
  final bool isReturning;
  final double textScale;

  Offset _resolve(Size size, int index) {
    final Offset p = positions[index];
    return Offset(p.dx * size.width, p.dy * size.height);
  }

  Offset _resolveNormalised(Size size, Offset p) =>
      Offset(p.dx * size.width, p.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF8F1DF), Color(0xFFE4F1E8)],
        ).createShader(bounds),
    );

    _drawLandscape(canvas, size);
    _drawRoads(canvas, size);

    if (hintedIndex != null) {
      _drawHint(
          canvas, _resolve(size, currentIndex), _resolve(size, hintedIndex!));
    }

    for (int i = 0; i < graph.nodes.length; i++) {
      _drawLandmark(canvas, size, i);
    }

    _drawTraveller(canvas, _resolveNormalised(size, travellerPosition));
  }

  void _drawLandscape(Canvas canvas, Size size) {
    final Paint hillPaint = Paint()
      ..color = const Color(0xFFCAE0C7).withValues(alpha: 0.55);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.11, size.height * 0.35),
            width: 150,
            height: 88),
        hillPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.92, size.height * 0.80),
            width: 180,
            height: 104),
        hillPaint);

    final Paint waterPaint = Paint()
      ..color = const Color(0xFFB7DCE3).withValues(alpha: 0.48);
    final Path stream = Path()
      ..moveTo(-20, size.height * 0.70)
      ..cubicTo(size.width * 0.25, size.height * 0.61, size.width * 0.67,
          size.height * 0.76, size.width + 20, size.height * 0.66)
      ..lineTo(size.width + 20, size.height * 0.71)
      ..cubicTo(size.width * 0.65, size.height * 0.81, size.width * 0.25,
          size.height * 0.66, -20, size.height * 0.76)
      ..close();
    canvas.drawPath(stream, waterPaint);

    const List<Offset> treeSpots = <Offset>[
      Offset(0.08, 0.08),
      Offset(0.88, 0.10),
      Offset(0.10, 0.53),
      Offset(0.91, 0.49),
      Offset(0.52, 0.74),
      Offset(0.12, 0.91),
      Offset(0.91, 0.92),
    ];
    for (int i = 0; i < treeSpots.length; i++) {
      final Offset p = _resolveNormalised(size, treeSpots[i]);
      final double scale = i.isEven ? 0.9 : 0.72;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: p + Offset(0, 8 * scale),
              width: 5 * scale,
              height: 18 * scale),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF8A6447),
      );
      canvas.drawCircle(p, 11 * scale,
          Paint()..color = const Color(0xFF6FA076).withValues(alpha: 0.72));
      canvas.drawCircle(
        p + Offset(-6 * scale, 2),
        7 * scale,
        Paint()..color = const Color(0xFF8DB68A).withValues(alpha: 0.74),
      );
    }
  }

  void _drawRoads(Canvas canvas, Size size) {
    final Set<int> drawnEdges = <int>{};
    for (int i = 0; i < graph.nodes.length; i++) {
      for (final int j in graph.nodes[i].neighborIndices) {
        final int key = i < j ? i * 1000 + j : j * 1000 + i;
        if (!drawnEdges.add(key)) continue;

        final Offset a = _resolve(size, i);
        final Offset b = _resolve(size, j);
        canvas.drawLine(
          a + const Offset(0, 4),
          b + const Offset(0, 4),
          Paint()
            ..color = const Color(0xFF7D694E).withValues(alpha: 0.24)
            ..strokeWidth = 20
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFFE7D4AD)
            ..strokeWidth = 17
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFFF9EED3)
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        _drawDashedLine(canvas, a, b,
            Paint()..color = const Color(0xFFAF9164).withValues(alpha: 0.62));
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final double length = (b - a).distance;
    if (length == 0) return;
    final Offset direction = (b - a) / length;
    const double dash = 5;
    const double gap = 8;
    paint
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (double d = 18; d < length - 18; d += dash + gap) {
      canvas.drawLine(a + direction * d,
          a + direction * math.min(d + dash, length - 18), paint);
    }
  }

  void _drawHint(Canvas canvas, Offset from, Offset to) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFF2E7D5B).withValues(alpha: 0.16 + pulse * 0.10)
        ..strokeWidth = 24 + pulse * 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFF2E7D5B)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawLandmark(Canvas canvas, Size size, int index) {
    final Offset center = _resolve(size, index);
    final bool isCurrent = index == currentIndex;
    final bool isAdjacent = graph.areAdjacent(currentIndex, index);
    final bool isTarget =
        index == (isReturning ? graph.homeIndex : destinationIndex);

    canvas.drawOval(
      Rect.fromCenter(
          center: center + const Offset(0, 7), width: 72, height: 30),
      Paint()..color = const Color(0xFF31493A).withValues(alpha: 0.17),
    );

    if (isTarget || hintedIndex == index) {
      canvas.drawCircle(
        center,
        kRouteNodeRadius + 10 + pulse * 3,
        Paint()
          ..color = (hintedIndex == index
                  ? const Color(0xFF2E7D5B)
                  : const Color(0xFFD19910))
              .withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }

    canvas.drawCircle(
        center, kRouteNodeRadius + 3, Paint()..color = const Color(0xFFFFFCF4));
    canvas.drawCircle(
      center,
      kRouteNodeRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: <Color>[
            isAdjacent || isCurrent
                ? const Color(0xFFF6D895)
                : const Color(0xFFE5E0D5),
            isAdjacent || isCurrent
                ? const Color(0xFFE4B962)
                : const Color(0xFFCFC8BB),
          ],
        ).createShader(
            Rect.fromCircle(center: center, radius: kRouteNodeRadius)),
    );

    if (index == graph.homeIndex) {
      _drawHouse(canvas, center);
    } else if (index == destinationIndex) {
      _drawFlag(canvas, center);
    } else {
      _drawSmallLandmark(canvas, center, index);
    }

    if (showLabels) _drawLabel(canvas, center, graph.nodes[index].item.label);
  }

  void _drawHouse(Canvas canvas, Offset c) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c + const Offset(0, 5), width: 27, height: 22),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF315C4A),
    );
    final Path roof = Path()
      ..moveTo(c.dx - 18, c.dy)
      ..lineTo(c.dx, c.dy - 16)
      ..lineTo(c.dx + 18, c.dy)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFB94D2B));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - 4, c.dy + 4, 8, 12), const Radius.circular(2)),
      Paint()..color = const Color(0xFFF6E9CD),
    );
  }

  void _drawFlag(Canvas canvas, Offset c) {
    canvas.drawLine(
      c + const Offset(-7, 14),
      c + const Offset(-7, -15),
      Paint()
        ..color = const Color(0xFF315C4A)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final Path flag = Path()
      ..moveTo(c.dx - 5, c.dy - 14)
      ..quadraticBezierTo(c.dx + 6, c.dy - 19, c.dx + 16, c.dy - 11)
      ..lineTo(c.dx + 16, c.dy + 1)
      ..quadraticBezierTo(c.dx + 5, c.dy - 6, c.dx - 5, c.dy - 1)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFE66B45));
  }

  void _drawSmallLandmark(Canvas canvas, Offset c, int index) {
    if (index.isEven) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: c + const Offset(0, 10), width: 7, height: 17),
            const Radius.circular(3)),
        Paint()..color = const Color(0xFF815D41),
      );
      canvas.drawCircle(c + const Offset(0, -3), 14,
          Paint()..color = const Color(0xFF4A8A65));
      canvas.drawCircle(
          c + const Offset(-8, 1), 8, Paint()..color = const Color(0xFF6AA477));
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: c + const Offset(0, 4), width: 31, height: 20),
        Paint()..color = const Color(0xFF70A7B3),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c + const Offset(0, 1), width: 25, height: 14),
        Paint()..color = const Color(0xFFBDE3E5),
      );
      canvas.drawLine(
          c + const Offset(-16, 14),
          c + const Offset(16, 14),
          Paint()
            ..color = const Color(0xFF815D41)
            ..strokeWidth = 4);
    }
  }

  void _drawLabel(Canvas canvas, Offset center, String? label) {
    if (label == null || label.isEmpty) return;
    final TextPainter text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFF2A312E),
          fontSize: 14 * textScale,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 104);
    final Rect pill = Rect.fromCenter(
      center: center + const Offset(0, kRouteNodeRadius + 17),
      width: text.width + 18,
      height: 25 + 8 * (textScale - 1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pill, const Radius.circular(13)),
      Paint()..color = const Color(0xFFFFFCF4).withValues(alpha: 0.94),
    );
    text.paint(
        canvas,
        Offset(
            pill.center.dx - text.width / 2, pill.center.dy - text.height / 2));
  }

  void _drawTraveller(Canvas canvas, Offset c) {
    final double bob = math.sin(pulse * math.pi) * 1.5;
    final Offset center = c + Offset(0, bob);
    canvas.drawOval(
      Rect.fromCenter(
          center: center + const Offset(0, 11), width: 34, height: 16),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFFFFFCF4));
    canvas.drawCircle(
      center,
      14.5,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2E7D5B), Color(0xFF17513B)],
        ).createShader(Rect.fromCircle(center: center, radius: 15)),
    );
    canvas.drawCircle(center + const Offset(-4, -5), 4,
        Paint()..color = Colors.white.withValues(alpha: 0.72));
    canvas.drawCircle(center + const Offset(0, 1), 4.5,
        Paint()..color = const Color(0xFFF1C7A7));
    canvas.drawArc(
      Rect.fromCenter(
          center: center + const Offset(0, 4), width: 12, height: 8),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFF123D30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.hintedIndex != hintedIndex ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.travellerPosition != travellerPosition ||
        oldDelegate.pulse != pulse ||
        oldDelegate.isReturning != isReturning ||
        oldDelegate.textScale != textScale;
  }
}
