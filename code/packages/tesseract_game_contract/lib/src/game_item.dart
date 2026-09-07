import 'package:flutter/foundation.dart';

/// One piece of content a game plays with — a location, a card, a maze
/// template, a routine step. The host supplies these; a game never invents
/// its own content.
@immutable
class GameItem {
  const GameItem({
    required this.id,
    this.label,
    this.imagePath,
    this.extra = const <String, Object?>{},
  });

  /// Stable, opaque identifier. This is the only form of this item that may
  /// ever appear in a [GameEvent] payload.
  final String id;

  /// Already-localised display text, or null if this item has none.
  final String? label;

  /// Path/asset key for this item's image, or null if it has none.
  final String? imagePath;

  /// Game-specific data the host attaches to this item (for example, which
  /// other item ids it connects to). Shape is defined by each game, not by
  /// this package.
  final Map<String, Object?> extra;
}
