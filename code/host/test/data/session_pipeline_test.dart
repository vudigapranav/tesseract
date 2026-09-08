import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';
import 'package:tesseract_host/games/game_registry.dart';
import 'package:tesseract_host/src/data/local_repository.dart';
import 'package:tesseract_host/src/session_controller.dart';

/// The host boundary: a game's events becoming durable, uploadable records.
///
/// The backend rejects a session whose sequence has holes, so the property
/// that matters most here is that every event the recorder produces reaches
/// storage — including the background pause/resume pair, which the shared
/// lifecycle mixin previously generated and then dropped.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late LocalRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tesseract-pipeline-test');
    repo = await LocalRepository.open(path: '${tempDir.path}/pipeline.db');
    await repo.useScope('caregiver-a');
  });

  tearDown(() async {
    await repo.db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  SessionController controllerFor({bool preferTouch = false}) =>
      SessionController(
        registration: gameRegistry.first,
        level: 1,
        isTutorial: false,
        repository: repo,
        patientId: 'patient-1',
        preferTouch: preferTouch,
      );

  test('a played session is stored with contiguous sequence numbers', () async {
    final SessionController controller = controllerFor();
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();

    controller.recordEvent(recorder.sessionStarted());
    controller.recordEvent(
        recorder.custom('location_entered', <String, Object?>{'nodeId': 'n1'}));
    final GameEvent finished =
        recorder.sessionFinished(GameResultStatus.completed);
    controller.recordEvent(finished);
    controller.finish(GameResult(
        status: GameResultStatus.completed,
        finalSeq: finished.seq,
        assisted: recorder.assisted));
    await controller.flush();

    final List<Map<String, dynamic>> stored =
        await repo.events(controller.sessionId);
    expect(stored.map((e) => e['seq']), <int>[1, 2, 3]);
    expect(stored.map((e) => e['type']),
        <String>['session_started', 'location_entered', 'session_finished']);
  });

  test('backgrounding mid-play still yields an uploadable, gap-free session',
      () async {
    final SessionController controller = controllerFor();
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();

    controller.recordEvent(recorder.sessionStarted());
    // What TesseractGameStateMixin does when the app is backgrounded and
    // returns. Before the fix these two events were generated — consuming
    // seq 2 and 3 — but never forwarded, leaving a hole the backend would
    // refuse to complete over.
    controller.recordEvent(recorder.paused(reason: 'backgrounded'));
    controller.recordEvent(recorder.resumed());
    final GameEvent finished =
        recorder.sessionFinished(GameResultStatus.completed);
    controller.recordEvent(finished);
    controller.finish(GameResult(
        status: GameResultStatus.completed,
        finalSeq: finished.seq,
        assisted: recorder.assisted));
    await controller.flush();

    final List<Map<String, dynamic>> stored =
        await repo.events(controller.sessionId);
    expect(stored.map((e) => e['seq']), <int>[1, 2, 3, 4]);
    expect(
        stored.map((e) => e['type']),
        containsAllInOrder(<String>[
          'session_started',
          'paused',
          'resumed',
          'session_finished'
        ]));
    expect(stored[1]['payload']['reason'], 'backgrounded');
  });

  test('a dropped event is refused rather than written as a gap', () async {
    final SessionController controller = controllerFor();
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();

    controller.recordEvent(recorder.sessionStarted());
    recorder.paused(reason: 'backgrounded'); // deliberately not forwarded
    expect(
      () => controller.recordEvent(recorder.resumed()),
      throwsA(isA<StateError>()),
    );
  });

  test('the game clock is written as elapsed_ms for the API', () async {
    final SessionController controller = controllerFor();
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();

    controller.recordEvent(recorder.sessionStarted());
    await controller.flush();

    final Map<String, dynamic> stored =
        (await repo.events(controller.sessionId)).single;
    expect(stored.containsKey('elapsed_ms'), isTrue);
    expect(stored.containsKey('elapsedMs'), isFalse);
  });

  test('a finished session cannot be finalised twice', () async {
    final SessionController controller = controllerFor();
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();

    controller.recordEvent(recorder.sessionStarted());
    final GameResult result = GameResult(
        status: GameResultStatus.stoppedByUser, finalSeq: 1, assisted: false);
    controller.finish(result);

    expect(() => controller.finish(result), throwsA(isA<StateError>()));
  });

  test('tilt sessions do not claim an observed input mode', () async {
    final GameRegistration? maze =
        gameRegistry.where((g) => g.gameId == 'marble_maze').firstOrNull;
    if (maze == null) {
      return;
    }
    final SessionController controller = SessionController(
      registration: maze,
      level: 1,
      isTutorial: false,
      repository: repo,
      patientId: 'patient-1',
    );
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();
    controller.recordEvent(recorder.sessionStarted());
    await controller.flush();

    final Map<String, Object?> row = (await repo.sessions()).single;
    final Map<String, dynamic> body =
        jsonDecode(row['body'] as String) as Map<String, dynamic>;
    expect(body['requested_input_mode'], 'tilt');
    // The host cannot observe whether the gyroscope was really used, so it
    // must not assert an actual mode the backend would treat as verified.
    expect(body.containsKey('actual_input_mode'), isFalse);
  });

  test('an explicit touch preference is recorded as the actual mode', () async {
    final GameRegistration? maze =
        gameRegistry.where((g) => g.gameId == 'marble_maze').firstOrNull;
    if (maze == null) {
      return;
    }
    final SessionController controller = SessionController(
      registration: maze,
      level: 1,
      isTutorial: false,
      repository: repo,
      patientId: 'patient-1',
      preferTouch: true,
    );
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();
    controller.recordEvent(recorder.sessionStarted());
    await controller.flush();

    final Map<String, dynamic> body =
        jsonDecode((await repo.sessions()).single['body'] as String)
            as Map<String, dynamic>;
    expect(body['requested_input_mode'], 'touch');
    expect(body['actual_input_mode'], 'touch');
  });

  test('an interrupted session is recovered without inventing a finish',
      () async {
    final SessionController controller = controllerFor();
    controller.buildConfig(textScale: 1);
    final TesseractEventRecorder recorder = TesseractEventRecorder();
    controller.recordEvent(recorder.sessionStarted());
    controller.recordEvent(
        recorder.custom('location_entered', <String, Object?>{'nodeId': 'n1'}));
    await controller.flush();
    // Process dies here: finish() is never called.

    await repo.recoverInterrupted();

    final Map<String, dynamic> completion =
        jsonDecode((await repo.sessions()).single['completion'] as String)
            as Map<String, dynamic>;
    expect(completion['status'], 'interrupted');
    expect(completion['final_seq'], 2);
    final List<Map<String, dynamic>> stored =
        await repo.events(controller.sessionId);
    expect(stored.map((e) => e['type']), isNot(contains('session_finished')));
  });
}
