import 'dart:async';

import 'package:flutter/services.dart';

/// Reads the Android host's fused game-rotation sensor without adding a
/// plugin dependency to the game package.
///
/// The native side uses `TYPE_GAME_ROTATION_VECTOR`, which combines the
/// gyroscope with the phone's other motion sensors to provide stable tilt
/// without compass drift. Hosts without this channel simply report no
/// samples and Marble Maze keeps its required touch fallback.
class MarbleTiltInput {
  const MarbleTiltInput(
      {EventChannel channel = const EventChannel(_channelName)})
      : _channel = channel;

  static const String _channelName = 'org.tesseract/marble_tilt';

  final EventChannel _channel;

  Stream<({double x, double y})> samples() {
    return _channel.receiveBroadcastStream().map((Object? event) {
      final Map<Object?, Object?> values = event! as Map<Object?, Object?>;
      return (
        x: (values['x']! as num).toDouble(),
        y: (values['y']! as num).toDouble(),
      );
    });
  }
}
