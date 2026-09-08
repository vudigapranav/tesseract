import 'package:flutter/material.dart';

import 'route_graph.dart';
import 'route_map_painter.dart';

/// Renders the map and turns taps into node-index callbacks. Movement between
/// nodes is animated, while the game state and event are committed immediately
/// so visual polish cannot make telemetry timing ambiguous.
class RouteMapView extends StatefulWidget {
  const RouteMapView({
    super.key,
    required this.graph,
    required this.positions,
    required this.currentIndex,
    required this.destinationIndex,
    required this.hintedIndex,
    required this.showLabels,
    required this.isReturning,
    required this.onTapNode,
  });

  final RouteGraph graph;
  final List<Offset> positions;
  final int currentIndex;
  final int destinationIndex;
  final int? hintedIndex;
  final bool showLabels;
  final bool isReturning;
  final void Function(int index) onTapNode;

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView>
    with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _movement = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late Offset _from = widget.positions[widget.currentIndex];
  late Offset _to = _from;
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
  void didUpdateWidget(covariant RouteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.positions != widget.positions) {
      _from = _travellerPosition;
      _to = widget.positions[widget.currentIndex];
      if (_animationsDisabled) {
        _movement.value = 1;
      } else {
        _movement.forward(from: 0);
      }
    }
  }

  Offset get _travellerPosition {
    final double t = Curves.easeInOutCubic.transform(_movement.value);
    return Offset.lerp(_from, _to, t)!;
  }

  @override
  void dispose() {
    _ambient.dispose();
    _movement.dispose();
    super.dispose();
  }

  int? _hitTest(Size size, Offset local) {
    for (int i = 0; i < widget.positions.length; i++) {
      final Offset center = Offset(widget.positions[i].dx * size.width,
          widget.positions[i].dy * size.height);
      if ((local - center).distance <= kRouteNodeHitRadius) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final double textScale =
            MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.45);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails details) {
            final int? tapped = _hitTest(size, details.localPosition);
            if (tapped != null) widget.onTapNode(tapped);
          },
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_ambient, _movement]),
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  size: size,
                  painter: RouteMapPainter(
                    graph: widget.graph,
                    positions: widget.positions,
                    currentIndex: widget.currentIndex,
                    destinationIndex: widget.destinationIndex,
                    hintedIndex: widget.hintedIndex,
                    showLabels: widget.showLabels,
                    travellerPosition: _travellerPosition,
                    pulse: _ambient.value,
                    isReturning: widget.isReturning,
                    textScale: textScale,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
