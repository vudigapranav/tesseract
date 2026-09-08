import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tesseract_host/src/data/local_repository.dart';

/// Durable storage behaviour, exercised against a real SQLite database.
///
/// These run on the FFI factory rather than a device, so they prove schema,
/// transaction and partitioning behaviour — not Android filesystem behaviour.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tesseract-repo-test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  String pathFor(String name) => '${tempDir.path}/$name.db';

  Map<String, Object?> event(int seq, String type,
          {String? status, String? occurredAt}) =>
      <String, Object?>{
        'event_id': 'event-$seq',
        'seq': seq,
        'type': type,
        'elapsed_ms': seq * 100,
        'occurred_at': occurredAt ?? '2026-09-08T10:0$seq:00.000Z',
        'payload': status == null
            ? <String, Object?>{}
            : <String, Object?>{'status': status},
      };

  group('durability across reopen', () {
    test('settings written in one process are readable in the next', () async {
      final String path = pathFor('reopen');

      final LocalRepository first = await LocalRepository.open(path: path);
      await first.useScope('caregiver-a');
      await first.saveSettings(<String, Object?>{'patient_name': 'Synthetic A'});
      await first.db.close();

      final LocalRepository second = await LocalRepository.open(path: path);
      final String? active = await second.readActiveScope();
      expect(active, 'caregiver-a');
      await second.useScope(active!);

      expect((await second.readSettings())!['patient_name'], 'Synthetic A');
      await second.db.close();
    });

    test('a completed session and its events survive a reopen', () async {
      final String path = pathFor('session-reopen');

      final LocalRepository first = await LocalRepository.open(path: path);
      await first.useScope('caregiver-a');
      await first.createSession('s1', <String, Object?>{'game_id': 'route_quest'});
      await first.appendEvent('s1', event(1, 'session_started'));
      await first.appendEvent('s1', event(2, 'session_finished', status: 'completed'));
      await first.complete('s1', <String, Object?>{'status': 'completed', 'final_seq': 2});
      await first.db.close();

      final LocalRepository second = await LocalRepository.open(path: path);
      await second.useScope('caregiver-a');
      final List<Map<String, Object?>> sessions = await second.sessions();
      expect(sessions, hasLength(1));
      expect(await second.events('s1'), hasLength(2));
      await second.db.close();
    });
  });

  group('identity partitioning', () {
    late LocalRepository repo;

    setUp(() async {
      repo = await LocalRepository.open(path: pathFor('identity'));
    });

    tearDown(() async => repo.db.close());

    test('a second caregiver cannot read the first caregiver\'s settings',
        () async {
      await repo.useScope('caregiver-a');
      await repo.saveSettings(<String, Object?>{'patient_name': 'Synthetic A'});

      await repo.useScope('caregiver-b');
      expect(await repo.readSettings(), isNull);
    });

    test('a second caregiver cannot see the first caregiver\'s sessions',
        () async {
      await repo.useScope('caregiver-a');
      await repo.createSession('s1', <String, Object?>{'game_id': 'route_quest'});
      await repo.appendEvent('s1', event(1, 'session_started'));

      await repo.useScope('caregiver-b');
      expect(await repo.sessions(), isEmpty);
      // Even addressing the session directly must not return its events.
      expect(await repo.events('s1'), isEmpty);
    });

    test('each caregiver keeps their own settings independently', () async {
      await repo.useScope('caregiver-a');
      await repo.saveSettings(<String, Object?>{'patient_name': 'Synthetic A'});
      await repo.useScope('caregiver-b');
      await repo.saveSettings(<String, Object?>{'patient_name': 'Synthetic B'});

      await repo.useScope('caregiver-a');
      expect((await repo.readSettings())!['patient_name'], 'Synthetic A');
      await repo.useScope('caregiver-b');
      expect((await repo.readSettings())!['patient_name'], 'Synthetic B');
    });

    test('signing out clears the active pointer but keeps the data', () async {
      await repo.useScope('caregiver-a');
      await repo.saveSettings(<String, Object?>{'patient_name': 'Synthetic A'});

      await repo.clearActiveScope();
      expect(await repo.readActiveScope(), isNull);
      expect(repo.scope, LocalRepository.anonymousScope);
      // Signed out, no patient content is readable...
      expect(await repo.readSettings(), isNull);

      // ...but signing back in restores it rather than having deleted it.
      await repo.useScope('caregiver-a');
      expect((await repo.readSettings())!['patient_name'], 'Synthetic A');
    });

    test('per-scope metadata does not leak between caregivers', () async {
      await repo.useScope('caregiver-a');
      await repo.putMeta('last_successful_sync', '2026-09-08T10:00:00.000Z');
      await repo.useScope('caregiver-b');
      expect(await repo.readMeta('last_successful_sync'), isNull);
    });
  });

  group('exactly-once completion', () {
    late LocalRepository repo;

    setUp(() async {
      repo = await LocalRepository.open(path: pathFor('completion'));
      await repo.useScope('caregiver-a');
      await repo.createSession('s1', <String, Object?>{'game_id': 'route_quest'});
      await repo.appendEvent('s1', event(1, 'session_started'));
    });

    tearDown(() async => repo.db.close());

    test('repeating an identical completion is accepted', () async {
      final Map<String, Object?> completion = <String, Object?>{
        'status': 'completed',
        'final_seq': 1,
      };
      await repo.complete('s1', completion);
      await repo.complete('s1', completion);

      final List<Map<String, Object?>> rows = await repo.sessions();
      expect(rows.single['completion'], isNotNull);
    });

    test('a differing completion is refused rather than overwriting', () async {
      await repo.complete('s1',
          <String, Object?>{'status': 'completed', 'final_seq': 1});
      expect(
        () => repo.complete('s1',
            <String, Object?>{'status': 'interrupted', 'final_seq': 1}),
        throwsA(isA<StateError>()),
      );
    });

    test('completing an unknown session in this scope is refused', () async {
      expect(
        () => repo.complete('does-not-exist', <String, Object?>{'status': 'completed'}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('interrupted session recovery', () {
    late LocalRepository repo;

    setUp(() async {
      repo = await LocalRepository.open(path: pathFor('recovery'));
      await repo.useScope('caregiver-a');
    });

    tearDown(() async => repo.db.close());

    test('a session whose last event is terminal keeps that status', () async {
      await repo.createSession('s1', <String, Object?>{'game_id': 'route_quest'});
      await repo.appendEvent('s1', event(1, 'session_started'));
      await repo.appendEvent(
          's1', event(2, 'session_finished', status: 'completed'));

      await repo.recoverInterrupted();

      final Map<String, Object?> row = (await repo.sessions()).single;
      expect(row['completion'], contains('"status":"completed"'));
      expect(row['completion'], contains('"final_seq":2'));
    });

    test('a session cut off mid-play is recorded as interrupted', () async {
      await repo.createSession('s1', <String, Object?>{'game_id': 'route_quest'});
      await repo.appendEvent('s1', event(1, 'session_started'));
      await repo.appendEvent('s1', event(2, 'location_entered'));

      await repo.recoverInterrupted();

      final Map<String, Object?> row = (await repo.sessions()).single;
      expect(row['completion'], contains('"status":"interrupted"'));
      // No terminal game event is invented; the last real seq is the final one.
      expect(row['completion'], contains('"final_seq":2'));
    });

    test('help used before the interruption is preserved as assisted', () async {
      await repo.createSession('s1', <String, Object?>{'game_id': 'route_quest'});
      await repo.appendEvent('s1', event(1, 'session_started'));
      await repo.appendEvent('s1', event(2, 'hint_requested'));

      await repo.recoverInterrupted();

      expect((await repo.sessions()).single['completion'],
          contains('"assisted":true'));
    });

    test('a session that never recorded an event is dropped, not left open',
        () async {
      await repo.createSession('s1', <String, Object?>{'game_id': 'route_quest'});

      await repo.recoverInterrupted();

      // Nothing to upload and nothing to complete: keeping it would retry
      // forever on every launch.
      expect(await repo.sessions(), isEmpty);
    });

    test('recovery is idempotent across repeated launches', () async {
      await repo.createSession('s1', <String, Object?>{'game_id': 'route_quest'});
      await repo.appendEvent('s1', event(1, 'session_started'));

      await repo.recoverInterrupted();
      await repo.recoverInterrupted();

      expect((await repo.sessions()).single['completion'],
          contains('"status":"interrupted"'));
    });

    test('recovery only touches the active caregiver\'s sessions', () async {
      await repo.useScope('caregiver-a');
      await repo.createSession('a1', <String, Object?>{'game_id': 'route_quest'});
      await repo.appendEvent('a1', event(1, 'session_started'));

      await repo.useScope('caregiver-b');
      await repo.recoverInterrupted();

      await repo.useScope('caregiver-a');
      expect((await repo.sessions()).single['completion'], isNull);
    });
  });
}
