import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart' show TimeOfDay;
import 'data/local_repository.dart';
import 'data/identity_service.dart';
import 'data/api_client.dart';
import 'data/session_outbox.dart';
import 'data/reminder_service.dart';

import '../games/game_registry.dart';

/// One Know Me entry (C3): a person, place, or interest.
class KnowMeItem {
  KnowMeItem({required this.label, this.caption});
  String label;
  String? caption;
}

/// One caregiver-defined routine reminder (C6), independent of any game.
class ReminderItem {
  ReminderItem(
      {required this.title,
      required this.time,
      this.enabled = true,
      int? id,
      this.postponedUntil,
      this.acknowledgedAt})
      : id = id ?? Random.secure().nextInt(999999999);
  final int id;
  DateTime? postponedUntil;
  DateTime? acknowledgedAt;
  String title;
  TimeOfDay time;
  bool enabled;
}

/// One completed-or-stopped session, for the patient's plain-count history
/// (P9) and the caregiver home's "last activity" (C4). Never a score.
class ActivityRecord {
  ActivityRecord({
    required this.gameId,
    required this.displayNameKey,
    required this.completedAt,
    required this.status,
  });

  final String gameId;
  final String displayNameKey;
  final DateTime completedAt;

  /// A `GameResultStatus` value.
  final String status;
}

/// Cross-screen state for one app run.
///
/// This is the in-memory stand-in for everything that eventually comes from
/// real caregiver sign-in, Know Me content, reminders, settings and the
/// session outbox. Nothing here persists past an app restart, and none of
/// it is real caregiver-entered data yet — each screen that reads or writes
/// a field says what it's standing in for.
class HostFlowState {
  HostFlowState({this.repository});
  final LocalRepository? repository;
  final identity = IdentityService();
  final reminderService = ReminderService();
  ApiClient? api;
  SessionOutbox? outbox;
  String patientId = '';
  int profileVersion = 1;
  int configVersion = 0;
  List<Map<String, dynamic>> recommendations = [];
  String syncStatus = 'Saved on device; not connected';
  /// Patients this caregiver can actually access, for explicit selection when
  /// there is more than one and none is already chosen.
  List<Map<String, dynamic>> availablePatients = <Map<String, dynamic>>[];

  Future<void> connect() async {
    api = ApiClient(
        baseUrl: Uri.parse(IdentityService.backendUrl), token: identity.token);
    final response = await api!.request('GET', '/v1/patients');
    if (api!.demo) {
      api = null;
      throw StateError('A demo backend cannot verify real caregiver access.');
    }

    // Adopt this caregiver's data partition before reading or writing
    // anything patient-scoped. A shared device must never carry one
    // caregiver's patient content into another's session.
    await adoptIdentityScope();

    final patients =
        (response['items'] as List).cast<Map<String, dynamic>>();
    availablePatients = patients;

    final matching = patients.where((p) => p['patient_id'] == patientId);
    if (matching.isNotEmpty) {
      final p = matching.first;
      patientId = p['patient_id'] as String;
      patientName = p['display_name'] as String;
      profileVersion = p['version'] as int;
    } else if (patientId.isNotEmpty) {
      // The remembered patient is not accessible to this identity. Adopting
      // whichever patient happens to be first would attach this caregiver's
      // session history to a stranger, so drop the stale selection and make
      // the caller choose.
      _clearPatientSelection();
    } else if (patients.length == 1) {
      final p = patients.single;
      patientId = p['patient_id'] as String;
      patientName = p['display_name'] as String;
      profileVersion = p['version'] as int;
    }

    if (repository != null) {
      outbox = SessionOutbox(repository!, api!);
      await outbox!.restore();
    }
    caregiverSignedIn = true;
    synthetic = false;
    await save();
  }

  /// Point durable storage at the signed-in caregiver and load their data.
  ///
  /// Anything held in memory from the signed-out (anonymous) partition is
  /// discarded first, so a previous caregiver's content cannot leak into this
  /// session through state that was already loaded at launch.
  Future<void> adoptIdentityScope() async {
    final String? uid = identity.uid;
    if (repository == null || uid == null || uid.isEmpty) {
      return;
    }
    if (repository!.scope == uid) {
      return;
    }
    _clearPatientScopedState();
    await repository!.useScope(uid);
    await restore();
  }

  void _clearPatientSelection() {
    patientId = '';
    patientName = '';
    profileVersion = 1;
  }

  /// Everything that belongs to one caregiver/patient pairing.
  void _clearPatientScopedState() {
    _clearPatientSelection();
    patientAge = null;
    patientLanguage = null;
    knownConditionType = null;
    knowMeWords.clear();
    knowMePeoplePlaces.clear();
    reminders.clear();
    activityHistory.clear();
    tutorialShownGameIds.clear();
    completedActivitiesCount = 0;
    approvedActivity = null;
    approvedLevel = 1;
    configVersion = 0;
    recommendations = <Map<String, dynamic>>[];
  }

  Future<void> synchronize() async {
    if (api == null) {
      syncStatus = 'Not connected. Your changes remain on this device.';
      return;
    }
    try {
      await outbox?.sync();
      if (patientId.isNotEmpty) {
        final activity =
            await api!.request('GET', '/v1/patients/$patientId/activity');
        final games =
            gameRegistry.where((g) => g.gameId == activity['game_id']);
        if (games.isNotEmpty) {
          approvedActivity = games.first;
          approvedLevel = activity['level'] as int;
          configVersion = activity['config_version'] as int;
        }
        final proposals = await api!
            .request('GET', '/v1/patients/$patientId/recommendations');
        recommendations =
            (proposals['items'] as List).cast<Map<String, dynamic>>();
      }
      syncStatus = outbox?.lastError ??
          'Connected; last checked ${DateTime.now().toLocal()}';
      await save();
    } catch (_) {
      syncStatus =
          'Could not synchronize. Saved data is retained; check sign-in and connection.';
    }
  }

  /// Pending proposals only. A decided one is removed by refetching.
  List<Map<String, dynamic>> get pendingRecommendations => recommendations
      .where((r) => r['status'] == 'pending')
      .toList(growable: false);

  /// Send a caregiver's decision on a proposed activity change.
  ///
  /// The reviewer is taken from the bearer token by the server, never sent
  /// from here. `expected_config_version` guards against a stale proposal
  /// overwriting a newer approved configuration — the server answers 409
  /// rather than applying it, and that surfaces to the caregiver instead of
  /// being retried silently.
  ///
  /// Nothing local is treated as approved: the approved activity is only
  /// updated from the server's own activity endpoint afterwards.
  Future<void> decideRecommendation(
    String recommendationId, {
    required String decision,
    Map<String, Object?>? modifiedConfig,
  }) async {
    if (api == null) {
      throw StateError(
          'Not connected. A change can only be approved while signed in.');
    }
    await api!.request(
      'POST',
      '/v1/recommendations/$recommendationId/decision',
      <String, Object?>{
        'decision': decision,
        if (modifiedConfig != null) 'modified_config': modifiedConfig,
        'expected_config_version': configVersion,
      },
    );
    await synchronize();
  }

  bool patientMode = false;
  bool reducedMotion = false;
  bool preferTouch = false;
  bool synthetic = false;
  String? storageError;
  Future<void> save() async {
    try {
      await repository?.saveSettings(toJson());
      storageError = null;
    } catch (_) {
      storageError = 'Could not save on this device. Please try again.';
      rethrow;
    }
  }

  Map<String, Object?> toJson() => {
        'patient_id': patientId,
        'patient_name': patientName,
        'patient_age': patientAge,
        'language': patientLanguage,
        'condition': knownConditionType,
        'caregiver_name': caregiverName,
        'patient_mode': patientMode,
        'text_scale': textScalePreference,
        'audio': audioEnabled,
        'reduced_motion': reducedMotion,
        'prefer_touch': preferTouch,
        'synthetic': synthetic,
        'tutorials': tutorialShownGameIds.toList(),
        'approved_game': approvedActivity?.gameId,
        'approved_level': approvedLevel,
        'words': knowMeWords,
        'people': knowMePeoplePlaces
            .map((e) => {'label': e.label, 'caption': e.caption})
            .toList(),
        'reminders': reminders
            .map((e) => {
                  'id': e.id,
                  'postponed_until': e.postponedUntil?.toIso8601String(),
                  'acknowledged_at': e.acknowledgedAt?.toIso8601String(),
                  'title': e.title,
                  'hour': e.time.hour,
                  'minute': e.time.minute,
                  'enabled': e.enabled
                })
            .toList(),
      };
  Future<void> restore() async {
    final data = await repository?.readSettings();
    if (data != null) {
      patientId = data['patient_id'] as String? ?? '';
      patientName = data['patient_name'] as String? ?? '';
      patientAge = data['patient_age'] as int?;
      patientLanguage = data['language'] as String?;
      knownConditionType = data['condition'] as String?;
      caregiverName = data['caregiver_name'] as String? ?? '';
      patientMode = data['patient_mode'] == true;
      synthetic = data['synthetic'] == true;
      reducedMotion = data['reduced_motion'] == true;
      preferTouch = data['prefer_touch'] == true;
      audioEnabled = data['audio'] != false;
      textScalePreference = (data['text_scale'] as num? ?? 1).toDouble();
      tutorialShownGameIds
          .addAll((data['tutorials'] as List? ?? []).cast<String>());
      approvedLevel = data['approved_level'] as int? ?? 1;
      for (final game in gameRegistry) {
        if (game.gameId == data['approved_game']) {
          approvedActivity = game;
        }
      }
      knowMeWords.addAll((data['words'] as List? ?? []).cast<String>());
      for (final item in data['people'] as List? ?? []) {
        knowMePeoplePlaces.add(KnowMeItem(
            label: item['label'] as String,
            caption: item['caption'] as String?));
      }
      for (final item in data['reminders'] as List? ?? []) {
        reminders.add(ReminderItem(
            id: item['id'] as int?,
            postponedUntil:
                DateTime.tryParse(item['postponed_until'] as String? ?? ''),
            acknowledgedAt:
                DateTime.tryParse(item['acknowledged_at'] as String? ?? ''),
            title: item['title'] as String,
            time: TimeOfDay(
                hour: item['hour'] as int, minute: item['minute'] as int),
            enabled: item['enabled'] == true));
      }
    }
    await repository?.recoverInterrupted();
    await refreshHistory();
  }

  Future<void> refreshHistory() async {
    if (repository == null) {
      return;
    }
    activityHistory.clear();
    completedActivitiesCount = 0;
    for (final row in await repository!.sessions()) {
      if (row['completion'] == null) {
        continue;
      }
      final body = jsonDecode(row['body'] as String) as Map;
      final result = jsonDecode(row['completion'] as String) as Map;
      final games = gameRegistry.where((g) => g.gameId == body['game_id']);
      if (games.isEmpty) {
        continue;
      }
      activityHistory.add(ActivityRecord(
          gameId: body['game_id'] as String,
          displayNameKey: games.first.displayNameKey,
          completedAt: DateTime.parse(result['ended_at'] as String),
          status: result['status'] as String));
      if (result['status'] == 'completed') {
        completedActivitiesCount++;
      }
    }
  }

  // Session/tutorial bookkeeping (existing).
  final Set<String> tutorialShownGameIds = <String>{};
  int completedActivitiesCount = 0;
  final List<ActivityRecord> activityHistory = <ActivityRecord>[];

  // C1 Sign In — placeholder only; no real identity provider yet.
  bool caregiverSignedIn = false;
  String caregiverName = '';

  // C2 Patient Basics.
  String patientName = '';
  int? patientAge;
  String? patientLanguage;

  /// One of: "Alzheimer's", "Frontotemporal", "Lewy body", "Vascular",
  /// "Mixed/other", "Unknown" — or null if not entered. Never inferred from
  /// gameplay.
  String? knownConditionType;

  // C3 Know Me.
  final List<KnowMeItem> knowMePeoplePlaces = <KnowMeItem>[];
  final List<String> knowMeWords = <String>[];

  // C5 Hand Over — today's caregiver-approved activity, if one was picked.
  // When set, Home (P1) offers it directly as P7 instead of routing through
  // Choose Activity (P2).
  GameRegistration? approvedActivity;
  int approvedLevel = 1;

  // C6 Reminders.
  final List<ReminderItem> reminders = <ReminderItem>[];

  // C7 Settings.
  double textScalePreference = 1.0;
  bool audioEnabled = true;
}
