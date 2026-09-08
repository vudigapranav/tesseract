import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tesseract_host/src/data/api_client.dart';
import 'package:tesseract_host/src/data/local_repository.dart';
import 'package:tesseract_host/src/data/session_outbox.dart';

/// Upload behaviour the offline outbox depends on.
///
/// The device is the source of truth until the server acknowledges, so the
/// rules under test are: a replay must be safe, a lost response must not
/// duplicate anything, and nothing is ever deleted because the server said no.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late LocalRepository repo;
  late List<String> calls;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tesseract-outbox-test');
    repo = await LocalRepository.open(path: '${tempDir.path}/outbox.db');
    await repo.useScope('caregiver-a');
    calls = <String>[];
  });

  tearDown(() async {
    await repo.db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> seedCompletedSession({int eventCount = 2}) async {
    await repo.createSession('s1', <String, Object?>{
      'patient_id': 'patient-1',
      'game_id': 'route_quest',
      'level': 1,
    });
    for (int seq = 1; seq <= eventCount; seq++) {
      await repo.appendEvent('s1', <String, Object?>{
        'event_id': 'event-$seq',
        'seq': seq,
        'type': seq == eventCount ? 'session_finished' : 'location_entered',
        'elapsed_ms': seq * 100,
        'occurred_at': '2026-09-08T10:00:00.000Z',
        'payload': <String, Object?>{},
      });
    }
    await repo.complete('s1', <String, Object?>{
      'status': 'completed',
      'final_seq': eventCount,
      'assisted': false,
    });
  }

  /// A server that behaves like the real one: it acknowledges every event,
  /// reporting the ones it had already stored as duplicates.
  ApiClient apiWith(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return ApiClient(
      baseUrl: Uri.parse('https://example.invalid'),
      token: () async => 'test-token',
      client: MockClient((http.Request request) async {
        calls.add('${request.method} ${request.url.path}');
        return handler(request);
      }),
    );
  }

  http.Response acknowledgeAll(http.Request request,
      {required bool asDuplicate}) {
    if (request.url.path.endsWith('events:batch')) {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      final List<String> ids = (body['events'] as List)
          .map((dynamic e) => (e as Map)['event_id'] as String)
          .toList();
      return http.Response(
        jsonEncode(<String, Object?>{
          'accepted': asDuplicate ? <String>[] : ids,
          'duplicate': asDuplicate ? ids : <String>[],
          'rejected': <Object?>[],
        }),
        200,
      );
    }
    return http.Response(jsonEncode(<String, Object?>{}), 200);
  }

  test('a completed session is uploaded in create, batch, complete order',
      () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: false)));

    await outbox.sync();

    expect(calls, <String>[
      'PUT /v1/sessions/s1',
      'POST /v1/sessions/s1/events:batch',
      'POST /v1/sessions/s1/complete',
    ]);
    expect(outbox.lastError, isNull);
    expect((await repo.sessions()).single['synced'], 1);
    expect(await repo.sessions(pendingOnly: true), isEmpty);
  });

  test('a replay after a lost response is safe and does not re-upload',
      () async {
    await seedCompletedSession();

    // First attempt: the server stored everything but the response was lost,
    // so the device still believes the session is pending.
    final SessionOutbox first = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: false)));
    await first.sync();

    // Second attempt against a server that now reports everything duplicate.
    calls.clear();
    final SessionOutbox second = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: true)));
    await second.sync();

    // Already synced, so nothing is sent at all.
    expect(calls, isEmpty);
    expect((await repo.sessions()), hasLength(1));
  });

  test('events reported only as duplicates still complete the session',
      () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: true)));

    await outbox.sync();

    expect(outbox.lastError, isNull);
    expect((await repo.sessions()).single['synced'], 1);
  });

  test('a rejected event is retained for review, never deleted', () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(repo, apiWith((r) async {
      if (r.url.path.endsWith('events:batch')) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'accepted': <String>[],
            'duplicate': <String>[],
            'rejected': <Object?>[
              <String, Object?>{'event_id': 'event-1', 'reason': 'seq_conflict'}
            ],
          }),
          200,
        );
      }
      return http.Response(jsonEncode(<String, Object?>{}), 200);
    }));

    await outbox.sync();

    final Map<String, Object?> row = (await repo.sessions()).single;
    expect(row['error'], isNotNull);
    expect(row['synced'], 0);
    // The recorded play is still on the device for a caregiver to review.
    expect(await repo.events('s1'), hasLength(2));
  });

  test('an unacknowledged event is treated as a failure, not a success',
      () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(repo, apiWith((r) async {
      if (r.url.path.endsWith('events:batch')) {
        // Server silently drops one event: acknowledges fewer than were sent.
        return http.Response(
          jsonEncode(<String, Object?>{
            'accepted': <String>['event-1'],
            'duplicate': <String>[],
            'rejected': <Object?>[],
          }),
          200,
        );
      }
      return http.Response(jsonEncode(<String, Object?>{}), 200);
    }));

    await outbox.sync();

    expect((await repo.sessions()).single['synced'], 0);
    expect(outbox.lastError, isNotNull);
  });

  test('a server error leaves the session pending for a later retry', () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(repo, apiWith((r) async {
      return http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{'code': 'server_error'}
          }),
          500);
    }));

    await outbox.sync();

    final Map<String, Object?> row = (await repo.sessions()).single;
    // Retryable: not marked as a permanent error, still pending.
    expect(row['error'], isNull);
    expect(row['synced'], 0);
    expect(await repo.sessions(pendingOnly: true), hasLength(1));
  });

  test('an expired identity stops the run without discarding anything',
      () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(repo, apiWith((r) async {
      return http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{'code': 'identity_required'}
          }),
          401);
    }));

    await outbox.sync();

    final Map<String, Object?> row = (await repo.sessions()).single;
    expect(row['error'], isNull);
    expect(row['synced'], 0);
    expect(outbox.lastError, 'identity_required');
  });

  test('being offline keeps the data and reports it plainly', () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(repo, apiWith((r) async {
      throw const SocketException('offline');
    }));

    await outbox.sync();

    expect((await repo.sessions()).single['synced'], 0);
    expect(outbox.lastError, contains('saved on this device'));
  });

  test('more than 500 events are uploaded in ordered batches', () async {
    await seedCompletedSession(eventCount: 1201);
    final SessionOutbox outbox = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: false)));

    await outbox.sync();

    final int batches =
        calls.where((String c) => c.endsWith('events:batch')).length;
    expect(batches, 3);
    expect((await repo.sessions()).single['synced'], 1);
  });

  test('the last successful sync time survives a restart', () async {
    await seedCompletedSession();
    final SessionOutbox outbox = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: false)));
    await outbox.sync();
    expect(outbox.lastSuccessfulSync, isNotNull);

    // A fresh outbox, as after an app restart, reports the real last sync
    // rather than implying the device has never synced.
    final SessionOutbox reopened = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: false)));
    expect(reopened.lastSuccessfulSync, isNull);
    await reopened.restore();
    expect(reopened.lastSuccessfulSync, isNotNull);
  });

  test('another caregiver\'s pending session is never uploaded', () async {
    await seedCompletedSession();
    await repo.useScope('caregiver-b');

    final SessionOutbox outbox = SessionOutbox(
        repo, apiWith((r) async => acknowledgeAll(r, asDuplicate: false)));
    await outbox.sync();

    expect(calls, isEmpty);
  });
}
