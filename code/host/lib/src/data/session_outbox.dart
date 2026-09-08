import 'dart:convert';
import 'local_repository.dart';
import 'api_client.dart';

class SessionOutbox {
  SessionOutbox(this.repository, this.api);
  final LocalRepository repository;
  final ApiClient api;
  bool _running = false;
  String? lastError;
  DateTime? lastSuccessfulSync;

  /// Replays immutable IDs. A lost response is safe: server deduplicates.
  /// Permanent rejections are retained for caregiver review, never discarded.
  static const String lastSyncKey = 'last_successful_sync';

  /// Load the persisted last-success time so sync status survives a restart
  /// instead of silently reading as "never synced".
  Future<void> restore() async {
    final String? stored = await repository.readMeta(lastSyncKey);
    if (stored != null) {
      lastSuccessfulSync = DateTime.tryParse(stored);
    }
  }

  Future<void> sync() async {
    if (_running) {
      return;
    }
    _running = true;
    try {
      for (final row in await repository.sessions(pendingOnly: true)) {
        if (row['error'] != null || row['completion'] == null) {
          continue;
        }
        final id = row['id'] as String;
        try {
          await api.request('PUT', '/v1/sessions/$id',
              jsonDecode(row['body'] as String) as Map<String, dynamic>);
          final events = await repository.events(id);
          for (var start = 0; start < events.length; start += 500) {
            final batch =
                events.sublist(start, (start + 500).clamp(0, events.length));
            final response = await api.request(
                'POST', '/v1/sessions/$id/events:batch', {'events': batch});
            if ((response['rejected'] as List).isNotEmpty) {
              throw ApiFailure(409, 'event_rejected');
            }
            final acknowledged = {
              ...(response['accepted'] as List),
              ...(response['duplicate'] as List)
            };
            if (!batch.every((e) => acknowledged.contains(e['event_id']))) {
              throw ApiFailure(409, 'event_ack_missing');
            }
          }
          await api.request('POST', '/v1/sessions/$id/complete',
              jsonDecode(row['completion'] as String) as Map<String, dynamic>);
          await repository.markSynced(id);
          lastSuccessfulSync = DateTime.now().toUtc();
          await repository.putMeta(
              lastSyncKey, lastSuccessfulSync!.toIso8601String());
          lastError = null;
        } on ApiFailure catch (e) {
          lastError = e.code;
          if (e.status == 401 || e.status == 403 || e.retryable) {
            break;
          }
          await repository.markError(id, e.code);
        } catch (_) {
          lastError = 'Connection unavailable; saved on this device';
          break;
        }
      }
    } finally {
      _running = false;
    }
  }
}
