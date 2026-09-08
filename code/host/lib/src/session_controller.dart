import 'dart:math';

import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import '../games/game_registry.dart';
import 'default_content.dart';
import 'uuid.dart';
import 'data/local_repository.dart';

/// Builds this session's [GameConfig], collects every [GameEvent] in order,
/// wraps each one with the host-side fields a game never sees or sets
/// (`event_id`, `session_id`, `occurred_at`, `game_id`, `game_version`,
/// `schema_version` — see the field-ownership note on `GameEvent` in
/// `tesseract_game_contract`), and on finish assembles the full session
/// snapshot as JSON.
///
/// Events are written to durable local storage as they arrive, through a
/// serialised queue so they land in emission order; [flush] waits for that
/// queue and surfaces any write failure rather than losing it silently. The
/// session is uploaded later by [SessionOutbox], not from here.
///
/// Two invariants are enforced here rather than trusted from the game:
/// `seq` must be contiguous, and a session finalises exactly once. The
/// contract-level recorder already guarantees both, so a violation means the
/// host wiring dropped or reordered an event — which is exactly the failure
/// that would otherwise reach the backend as an uncompletable session.
///
/// `elapsedMs` from the game becomes `elapsed_ms` on the wire here. That
/// rename is the host's job: the game contract is unchanged.
class SessionController {
  SessionController(
      {required this.registration,
      required this.level,
      required this.isTutorial,
      this.repository,
      this.patientId = '',
      this.preferTouch = false,
      this.items})
      : _random = Random.secure() {
    sessionId = generateUuidV4(_random);
  }

  final LocalRepository? repository;
  final String patientId;
  final bool preferTouch;
  final List<GameItem>? items;
  Future<void> _writes = Future<void>.value();
  Object? persistenceError;
  bool _started = false;
  bool _finished = false;
  GameConfig? _config;
  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) async {
      if (persistenceError != null) {
        return;
      }
      try {
        await write();
      } catch (e) {
        persistenceError = e;
      }
    });
  }

  Future<void> flush() async {
    await _writes;
    if (persistenceError != null) {
      throw StateError('Session could not be saved');
    }
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
    return _config ??= GameConfig(
      gameId: registration.gameId,
      gameVersion: registration.gameVersion,
      schemaVersion: '1',
      configVersion: '1',
      contentVersion: '1',
      metricVersion: '1',
      level: level,
      difficultyParams: registration.difficultyParamsFor(level),
      items: items == null || items!.isEmpty ? defaultGameItems() : items!,
      strings: defaultGameStrings(),
      textScale: textScale,
      inputMode: registration.gameId == 'marble_maze' && !preferTouch
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
    if (_finished) {
      throw StateError('Session already finalized');
    }
    if (event.seq != _wrappedEvents.length + 1) {
      throw StateError('Non-contiguous event sequence');
    }
    if (!_started) {
      _started = true;
      final config = _config ?? buildConfig(textScale: 1);
      _enqueue(() async {
        await repository?.createSession(sessionId, {
          'patient_id': patientId,
          'game_id': registration.gameId,
          'game_version': registration.gameVersion,
          'schema_version': config.schemaVersion,
          'config_version': config.configVersion,
          'content_version': config.contentVersion,
          'metric_version': config.metricVersion,
          'level': level,
          'difficulty_params': config.difficultyParams,
          'requested_input_mode': config.inputMode,
          if (config.inputMode == GameInputMode.touch)
            'actual_input_mode': 'touch',
          'is_tutorial': isTutorial,
          'text_scale': config.textScale,
          'locale': config.locale,
          'started_at': DateTime.now().toUtc().toIso8601String(),
        });
      });
    }
    final wrapped = <String, Object?>{
      'event_id': generateUuidV4(_random),
      'session_id': sessionId,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
      'game_id': registration.gameId,
      'game_version': registration.gameVersion,
      'schema_version': '1',
      'type': event.type,
      'seq': event.seq,
      'elapsed_ms': event.elapsedMs,
      'payload': event.payload,
    };
    _wrappedEvents.add(wrapped);
    _enqueue(() async {
      await repository?.appendEvent(sessionId, wrapped);
    });
  }

  /// Assembles and (for now) prints the full session snapshot.
  Map<String, Object?> finish(GameResult result) {
    if (_finished) {
      throw StateError('Session already finalized');
    }
    if (result.finalSeq != _wrappedEvents.length) {
      throw StateError('Final sequence mismatch');
    }
    _finished = true;
    _enqueue(() async {
      await repository?.complete(sessionId, {
        'status': result.status,
        'final_seq': result.finalSeq,
        'assisted': result.assisted,
        'ended_at': DateTime.now().toUtc().toIso8601String()
      });
    });
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

    return snapshot;
  }
}
