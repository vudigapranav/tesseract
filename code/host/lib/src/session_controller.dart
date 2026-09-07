import 'dart:convert';
import 'dart:math';

import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import '../games/game_registry.dart';
import 'default_content.dart';
import 'uuid.dart';

/// Builds this session's [GameConfig], collects every [GameEvent] in order,
/// wraps each one with the host-side fields a game never sees or sets
/// (`event_id`, `session_id`, `occurred_at`, `game_id`, `game_version`,
/// `schema_version` — see the field-ownership note on `GameEvent` in
/// `tesseract_game_contract`), and on finish assembles the full session
/// snapshot as JSON.
///
/// No backend, no database, no http: [finish] currently only prints the
/// snapshot and keeps it in memory. The outbox that actually uploads this is
/// wired in separately.
class SessionController {
  SessionController(
      {required this.registration,
      required this.level,
      required this.isTutorial})
      : _random = Random.secure() {
    sessionId = generateUuidV4(_random);
  }

  final GameRegistration registration;
  final int level;
  final bool isTutorial;
  late final String sessionId;

  final Random _random;
  final List<Map<String, Object?>> _wrappedEvents = <Map<String, Object?>>[];

  /// This session's frozen configuration. [textScale] comes from the live
  /// `MediaQuery` at Play-screen build time, since that is a presentation
  /// concern the controller itself has no reason to know about otherwise.
  GameConfig buildConfig({required double textScale}) {
    return GameConfig(
      gameId: registration.gameId,
      gameVersion: registration.gameVersion,
      schemaVersion: '1',
      configVersion: '1',
      contentVersion: '1',
      metricVersion: '1',
      level: level,
      difficultyParams: registration.difficultyParamsFor(level),
      items: defaultGameItems(),
      strings: defaultGameStrings(),
      textScale: textScale,
      inputMode: registration.gameId == 'marble_maze'
          ? GameInputMode.tilt
          : GameInputMode.touch,
      showLabels: true,
      locale: registration.supportedLocales.contains('en')
          ? 'en'
          : registration.supportedLocales.first,
      isTutorial: isTutorial,
    );
  }

  /// Wraps [event] with the host-side envelope fields and appends it, in
  /// emission order.
  void recordEvent(GameEvent event) {
    _wrappedEvents.add(<String, Object?>{
      'event_id': generateUuidV4(_random),
      'session_id': sessionId,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
      'game_id': registration.gameId,
      'game_version': registration.gameVersion,
      'schema_version': '1',
      ...event.toJson(),
    });
  }

  /// Assembles and (for now) prints the full session snapshot.
  Map<String, Object?> finish(GameResult result) {
    final Map<String, Object?> snapshot = <String, Object?>{
      'session_id': sessionId,
      'game_id': registration.gameId,
      'game_version': registration.gameVersion,
      'level': level,
      'is_tutorial': isTutorial,
      'events': List<Map<String, Object?>>.unmodifiable(_wrappedEvents),
      'result': <String, Object?>{
        'status': result.status,
        'final_seq': result.finalSeq,
        'assisted': result.assisted
      },
    };
    // ignore: avoid_print
    print(jsonEncode(snapshot));
    return snapshot;
  }
}
