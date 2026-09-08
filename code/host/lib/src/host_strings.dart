/// Minimal display-name lookup so the game registry stores a key, not a
/// hardcoded literal — a seam for real localisation later without needing a
/// full intl setup for this first host build.
abstract final class HostStrings {
  static const Map<String, String> _displayNames = <String, String>{
    'route_quest_name': 'Route Quest',
    'marble_maze_name': 'Marble Maze',
  };

  static String displayName(String key) => _displayNames[key] ?? key;

  /// Display name from a bare `game_id` (as the API returns it), rather than
  /// from a registry display key. Without this the caregiver sees the raw
  /// identifier, e.g. "route_quest".
  static String gameName(String gameId) =>
      _displayNames['${gameId}_name'] ?? _displayNames[gameId] ?? gameId;
}
