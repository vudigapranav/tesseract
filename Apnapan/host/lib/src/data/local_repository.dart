import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Durable host data only. Games never import this library.
///
/// Everything stored here is **partitioned by caregiver identity**. A device
/// can be shared, and a second caregiver signing in must never see the first
/// caregiver's patient name, Know Me content, reminders or session history.
/// Every read and write is therefore scoped, and a scope is only adopted when
/// that identity actually signs in (or its saved session is restored).
///
/// The active scope pointer is stored separately and holds an identity key
/// only — never patient content — so the app can tell whose data to load on
/// restart without first exposing anyone's data.
class LocalRepository {
  LocalRepository(this.db, {String scope = anonymousScope}) : _scope = scope;

  final Database db;

  /// Used before anyone has signed in. Data written here belongs to nobody
  /// and is never shown to a signed-in caregiver.
  static const String anonymousScope = '__unsigned__';

  static const String _activeScopeRow = '__active_scope__';
  static const int schemaVersion = 2;

  String _scope;

  /// The caregiver identity whose data is currently readable.
  String get scope => _scope;

  static Future<LocalRepository> open({String? path}) async {
    final Database db = await openDatabase(
      path ?? 'tesseract-v1.db',
      version: schemaVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA synchronous = FULL');
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createV1(db);
        await _upgradeToV2(db);
      },
      onUpgrade: (Database db, int from, int to) async {
        if (from < 2) {
          await _upgradeToV2(db);
        }
      },
    );
    return LocalRepository(db);
  }

  static Future<void> _createV1(Database db) async {
    await db.execute(
        'CREATE TABLE settings (id TEXT PRIMARY KEY, body TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE sessions (id TEXT PRIMARY KEY, body TEXT NOT NULL, completion TEXT, synced INTEGER NOT NULL DEFAULT 0, error TEXT)');
    await db.execute(
        'CREATE TABLE events (id TEXT PRIMARY KEY, session_id TEXT NOT NULL, seq INTEGER NOT NULL, body TEXT NOT NULL, UNIQUE(session_id, seq))');
  }

  /// v2 adds identity partitioning and a per-scope key/value table.
  ///
  /// Rows written before partitioning existed cannot be attributed to a
  /// caregiver, so they stay on the anonymous scope rather than being handed
  /// to whoever signs in next.
  static Future<void> _upgradeToV2(Database db) async {
    final List<Map<String, Object?>> columns =
        await db.rawQuery('PRAGMA table_info(sessions)');
    final bool hasScope =
        columns.any((Map<String, Object?> c) => c['name'] == 'scope');
    if (!hasScope) {
      await db.execute(
          "ALTER TABLE sessions ADD COLUMN scope TEXT NOT NULL DEFAULT '$anonymousScope'");
    }
    await db.execute(
        'CREATE TABLE IF NOT EXISTS meta (scope TEXT NOT NULL, key TEXT NOT NULL, value TEXT, PRIMARY KEY (scope, key))');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS ix_sessions_scope ON sessions (scope)');
  }

  // ---------------------------------------------------------------------
  // Scope
  // ---------------------------------------------------------------------

  /// Adopt [scope] and remember it as the active identity.
  ///
  /// Call this after identity is established. Until it is called the
  /// repository reads and writes the anonymous scope only.
  Future<void> useScope(String scope) async {
    _scope = scope.isEmpty ? anonymousScope : scope;
    await db.insert(
      'settings',
      <String, Object?>{'id': _activeScopeRow, 'body': jsonEncode(_scope)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// The identity that was active when the app last ran, if any.
  Future<String?> readActiveScope() async {
    final List<Map<String, Object?>> rows = await db.query('settings',
        where: 'id = ?', whereArgs: <Object?>[_activeScopeRow]);
    if (rows.isEmpty) {
      return null;
    }
    final Object? decoded = jsonDecode(rows.single['body'] as String);
    return decoded is String ? decoded : null;
  }

  /// Forget the active identity without deleting anyone's data, so the next
  /// launch starts signed out instead of reopening the last caregiver's view.
  Future<void> clearActiveScope() async {
    _scope = anonymousScope;
    await db.delete('settings',
        where: 'id = ?', whereArgs: <Object?>[_activeScopeRow]);
  }

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>?> readSettings() async {
    final List<Map<String, Object?>> rows = await db
        .query('settings', where: 'id = ?', whereArgs: <Object?>[_scope]);
    return rows.isEmpty
        ? null
        : jsonDecode(rows.single['body'] as String) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, Object?> body) async {
    await db.insert(
      'settings',
      <String, Object?>{'id': _scope, 'body': jsonEncode(body)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------------
  // Per-scope key/value
  // ---------------------------------------------------------------------

  Future<void> putMeta(String key, String? value) async {
    await db.insert(
      'meta',
      <String, Object?>{'scope': _scope, 'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> readMeta(String key) async {
    final List<Map<String, Object?>> rows = await db.query('meta',
        where: 'scope = ? AND key = ?', whereArgs: <Object?>[_scope, key]);
    return rows.isEmpty ? null : rows.single['value'] as String?;
  }

  // ---------------------------------------------------------------------
  // Sessions and events
  // ---------------------------------------------------------------------

  Future<void> createSession(String id, Map<String, Object?> body) async {
    await db.insert('sessions', <String, Object?>{
      'id': id,
      'scope': _scope,
      'body': jsonEncode(body),
    });
  }

  Future<void> appendEvent(String sessionId, Map<String, Object?> event) async {
    await db.insert('events', <String, Object?>{
      'id': event['event_id'],
      'session_id': sessionId,
      'seq': event['seq'],
      'body': jsonEncode(event),
    });
  }

  /// Record the terminal state exactly once.
  ///
  /// A repeat with identical content is accepted so a retried finalisation is
  /// harmless; a repeat with *different* content is a real conflict and is
  /// surfaced rather than silently overwriting what was already stored.
  Future<void> complete(String id, Map<String, Object?> completion) async {
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query('sessions',
          where: 'id = ? AND scope = ?', whereArgs: <Object?>[id, _scope]);
      if (rows.isEmpty) {
        throw StateError('No local session $id in this scope');
      }
      final Object? stored = rows.single['completion'];
      if (stored != null) {
        if (stored != jsonEncode(completion)) {
          throw StateError('Conflicting local completion');
        }
        return;
      }
      await txn.update(
          'sessions', <String, Object?>{'completion': jsonEncode(completion)},
          where: 'id = ?', whereArgs: <Object?>[id]);
    });
  }

  Future<List<Map<String, Object?>>> sessions({bool pendingOnly = false}) =>
      db.query('sessions',
          where: pendingOnly ? 'scope = ? AND synced = 0' : 'scope = ?',
          whereArgs: <Object?>[_scope],
          orderBy: 'rowid');

  Future<List<Map<String, dynamic>>> events(String id) async =>
      (await db.rawQuery(
        'SELECT e.body AS body FROM events e JOIN sessions s ON s.id = e.session_id '
        'WHERE e.session_id = ? AND s.scope = ? ORDER BY e.seq',
        <Object?>[id, _scope],
      ))
          .map((Map<String, Object?> r) =>
              jsonDecode(r['body'] as String) as Map<String, dynamic>)
          .toList();

  Future<void> markSynced(String id) async {
    await db.update('sessions', <String, Object?>{'synced': 1},
        where: 'id = ? AND scope = ?', whereArgs: <Object?>[id, _scope]);
  }

  Future<void> markError(String id, String code) async {
    await db.update('sessions', <String, Object?>{'error': code},
        where: 'id = ? AND scope = ?', whereArgs: <Object?>[id, _scope]);
  }

  /// An interrupted process cannot resume a game's private widget state.
  /// Recover only persisted events, without inventing a terminal game event.
  Future<void> recoverInterrupted() async {
    for (final Map<String, Object?> row in await sessions()) {
      if (row['completion'] != null) {
        continue;
      }
      final String id = row['id'] as String;
      final List<Map<String, dynamic>> saved = await events(id);
      if (saved.isEmpty) {
        // No events were ever persisted, so there is nothing to upload and
        // nothing to complete. Left in place it would stay open forever and
        // be retried on every launch, so drop it rather than leak a row.
        await db.delete('sessions',
            where: 'id = ? AND scope = ?', whereArgs: <Object?>[id, _scope]);
        continue;
      }
      final Map<String, dynamic> last = saved.last;
      final bool terminal = last['type'] == 'session_finished';
      await complete(id, <String, Object?>{
        'status': terminal ? (last['payload'] as Map)['status'] : 'interrupted',
        'final_seq': last['seq'],
        'assisted': saved
            .any((Map<String, dynamic> e) => e['type'] == 'hint_requested'),
        'ended_at': last['occurred_at'],
      });
    }
  }
}
