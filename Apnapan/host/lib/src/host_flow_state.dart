import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart' show ChangeNotifier, TimeOfDay;
import 'data/local_repository.dart';
import 'data/identity_service.dart';
import 'data/api_client.dart';
import 'data/doctor_service.dart';
import 'data/session_outbox.dart';
import 'data/reminder_service.dart';
import 'speech/platform_speech_engine.dart';
import 'speech/speech_engine.dart';
import 'speech/speech_output_service.dart';

import '../games/game_registry.dart';

/// One Know Me entry (C3): a person, place, or interest.
class KnowMeItem {
  KnowMeItem({required this.label, this.caption, this.kind, this.mediaAssetId});
  String? kind;
  String? mediaAssetId;
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

/// Host state backed by caregiver-scoped durable settings and patient snapshots.
/// Server access is verified separately; offline data never grants access.
class HostFlowState extends ChangeNotifier {
  HostFlowState({this.repository, TtsEngine? ttsEngine, SttEngine? sttEngine})
      : _ttsEngine = ttsEngine,
        _sttEngine = sttEngine;

  // Speech engines are injected by tests and built lazily otherwise, so
  // constructing this state object never touches a platform channel. Nothing
  // is created until something actually asks to speak or listen — which also
  // means the microphone plugin is untouched until a user taps for it.
  final TtsEngine? _ttsEngine;
  final SttEngine? _sttEngine;
  SpeechOutputService? _speech;
  SttEngine? _resolvedStt;

  /// Optional spoken output. Text and touch never depend on it.
  SpeechOutputService get speech => _speech ??= SpeechOutputService(
        engine: _ttsEngine ??
            (kIsWeb ? const UnavailableTtsEngine() : PlatformTtsEngine()),
        audioEnabled: () => audioEnabled,
      );

  /// Recogniser for tap-to-speak. Idle until a sheet asks it to listen.
  SttEngine get stt => _resolvedStt ??= _sttEngine ??
      (kIsWeb ? const UnavailableSttEngine() : PlatformSttEngine());

  /// True once something has actually built the speech service, so lifecycle
  /// and language changes can avoid constructing an engine just to stop it.
  bool get speechStarted => _speech != null;

  /// Tell the app shell that a display preference changed.
  ///
  /// Text size and reduced motion are applied by the root `MediaQuery`, so
  /// they only take effect if something rebuilds it. Without this the
  /// caregiver has to close and reopen the app to see a change they just
  /// made, which reads as the setting being broken.
  void displayPreferencesChanged() => notifyListeners();
  final LocalRepository? repository;
  final identity = IdentityService();
  final reminderService = ReminderService();
  ApiClient? api;
  SessionOutbox? outbox;

  /// Doctor-side reads, present only while a doctor is signed in.
  DoctorService? doctorService;

  /// 'caregiver' or 'doctor'. Chosen at sign-in, but it grants nothing on its
  /// own: the backend decides what this identity may actually read.
  String role = 'caregiver';
  String patientId = '';
  int profileVersion = 1;
  int configVersion = 0;
  Map<String, dynamic>? serverActivity;
  Map<String, dynamic> personalizationPreferences = {};
  bool personalizationDirty = false;
  bool personalizationLoaded = false;
  List<Map<String, dynamic>> serverWords = [];
  String localContentVersion = 'local-0';
  String _savedContent = '';
  final Map<String, dynamic> _patientSnapshots = {};

  String get contentVersion =>
      personalizationDirty || patientId.isEmpty || reminders.isNotEmpty
          ? localContentVersion
          : profileVersion.toString();

  Future<void> refreshPatients() async {
    if (api == null) throw StateError('Connect to load patients.');
    final result = await api!.request('GET', '/v1/patients');
    availablePatients = (result['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> selectPatient(String id) async {
    if (api == null || !availablePatients.any((p) => p['patient_id'] == id)) {
      throw StateError('Patient access must be verified before selection.');
    }
    if (id == patientId) return;
    // Fetch before changing local state. An access/network failure keeps the
    // current patient and all unsent edits intact.
    final patient = await api!.request('GET', '/v1/patients/$id');
    final content =
        await api!.request('GET', '/v1/patients/$id/personalization');
    await save();
    if (patientId.isNotEmpty) {
      _patientSnapshots[patientId] =
          jsonDecode(jsonEncode(toJson(includeSnapshots: false)));
    }
    final interfaceCode = interfaceLanguageCode;
    final wasSynthetic = synthetic;
    final cached = _patientSnapshots[id];
    _clearPatientScopedState();
    if (cached is Map) {
      _restoreSettings(cached.cast<String, dynamic>());
    } else {
      patientId = id;
      patientName = patient['display_name'] as String;
      patientLanguageCode = patient['language'] as String? ?? 'en';
      knownConditionType = patient['known_type'] as String?;
      _adoptPersonalization(content);
    }
    interfaceLanguageCode = interfaceCode;
    synthetic = wasSynthetic;
    patientMode = false;
    await save();
    await refreshHistory();
    await synchronize();
    await rescheduleReminders();
    notifyListeners();
  }

  void _adoptPersonalization(Map<String, dynamic> content) {
    profileVersion = content['version'] as int;
    personalizationLoaded = true;
    serverWords =
        (content['personal_words'] as List).cast<Map<String, dynamic>>();
    knowMeWords
      ..clear()
      ..addAll(
          (content['personal_words'] as List).map((w) => w['text'] as String));
    knowMePeoplePlaces
      ..clear()
      ..addAll((content['people_places'] as List).map((p) => KnowMeItem(
          label: p['label'] as String,
          kind: p['kind'] as String?,
          mediaAssetId: p['media_asset_id'] as String?)));
    personalizationPreferences =
        (content['preferences'] as Map? ?? {}).cast<String, dynamic>();
    personalizationDirty = false;
    _savedContent = _contentSignature();
  }

  Future<void> startNewPatient() async {
    await save();
    if (patientId.isNotEmpty) {
      _patientSnapshots[patientId] =
          jsonDecode(jsonEncode(toJson(includeSnapshots: false)));
    }
    _clearPatientScopedState();
    await save();
    await rescheduleReminders();
    notifyListeners();
  }

  Future<void> createPatient() async {
    if (api == null || patientId.isNotEmpty) {
      throw StateError('Connect before creating a patient.');
    }
    final patient = await api!.request('POST', '/v1/patients', {
      'display_name': patientName,
      'language': effectivePatientLanguageCode,
      'known_type': knownConditionType,
      'accessibility': {
        'text_scale': textScalePreference,
        'reduced_motion': reducedMotion
      },
    });
    patientId = patient['patient_id'] as String;
    profileVersion = patient['version'] as int;
    availablePatients.add(patient);
    personalizationLoaded = true;
    await save();
  }

  Future<Map<String, dynamic>> readServerPersonalization() async {
    if (api == null || patientId.isEmpty) {
      throw StateError('Connect and select a patient.');
    }
    return api!.request('GET', '/v1/patients/$patientId/personalization');
  }

  /// Called only after the caregiver reviews and chooses the server copy.
  Future<void> useReviewedPersonalization(Map<String, dynamic> content) async {
    await save();
    await repository?.putMeta('personalization_backup:$patientId',
        jsonEncode(toJson(includeSnapshots: false)));
    _adoptPersonalization(content);
    await save();
    notifyListeners();
  }

  Future<void> uploadPersonalization() async {
    await save();
    if (api == null || patientId.isEmpty) {
      throw StateError(
          'Saved on device. Connect and select a patient to upload.');
    }
    if (!personalizationLoaded) {
      throw StateError(
          'This offline profile has no server content baseline. Review server content before uploading.');
    }
    if (knowMePeoplePlaces.any((p) => p.kind == null)) {
      throw StateError(
          'Choose Person or Place for each entry before uploading.');
    }
    // Never refetch a version and blindly retry a rejected replacement.
    final result =
        await api!.request('PUT', '/v1/patients/$patientId/personalization', {
      'version': profileVersion,
      'personal_words': knowMeWords
          .asMap()
          .entries
          .map((e) => {
                'text': e.value,
                'locale': e.key < serverWords.length &&
                        serverWords[e.key]['text'] == e.value
                    ? serverWords[e.key]['locale']
                    : effectivePatientLanguageCode
              })
          .toList(),
      'people_places': knowMePeoplePlaces
          .map((p) => {
                'kind': p.kind,
                'label': p.label,
                'media_asset_id': p.mediaAssetId,
              })
          .toList(),
      'preferences': personalizationPreferences,
    });
    profileVersion = result['version'] as int;
    personalizationDirty = false;
    await save();
  }

  String _contentSignature() => jsonEncode({
        'words': knowMeWords,
        'people': knowMePeoplePlaces
            .map((p) => [p.label, p.caption, p.kind, p.mediaAssetId])
            .toList(),
        'reminders': reminders
            .map((r) => [r.id, r.title, r.time.hour, r.time.minute, r.enabled])
            .toList(),
        'language': effectivePatientLanguageCode,
      });
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

    final patients = (response['items'] as List).cast<Map<String, dynamic>>();
    availablePatients = patients;

    final matching = patients.where((p) => p['patient_id'] == patientId);
    if (matching.isNotEmpty) {
      final p = matching.first;
      patientId = p['patient_id'] as String;
      if (patientName.isEmpty) patientName = p['display_name'] as String;
    } else if (patientId.isNotEmpty) {
      // The remembered patient is not accessible to this identity. Adopting
      // whichever patient happens to be first would attach this caregiver's
      // session history to a stranger, so drop the stale selection and make
      // the caller choose.
      _clearPatientScopedState();
    } else if (patients.length == 1) {
      final p = patients.single;
      await selectPatient(p['patient_id'] as String);
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
    _patientSnapshots.clear();
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
    serverActivity = null;
    patientLanguageCode = '';
    personalizationPreferences = {};
    personalizationLoaded = false;
    serverWords = [];
    personalizationDirty = false;
    _savedContent = '';
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
        serverActivity = activity;
        if (games.isNotEmpty && approvedActivity == null) {
          approvedActivity = games.first;
          approvedLevel = activity['level'] as int;
        }
        configVersion = activity['config_version'] as int;
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
    approvedActivity = null;
    await synchronize();
  }

  /// The caregiver's or doctor's own interface language.
  String interfaceLanguageCode = 'en';

  /// The language the person playing sees: activity instructions, Help and
  /// Break, and game content. Configured by the caregiver and deliberately
  /// **independent** of the interface language, because the caregiver and the
  /// person they care for may not read the same language.
  ///
  /// Empty means "not chosen yet", in which case it follows the interface
  /// language, matching "default it to the setup language".
  String patientLanguageCode = '';

  /// The language actually used for patient-facing text.
  String get effectivePatientLanguageCode =>
      patientLanguageCode.isEmpty ? interfaceLanguageCode : patientLanguageCode;

  /// Change the interface language and apply it immediately.
  ///
  /// Does not touch the patient's language once that has been chosen
  /// separately, and does not sign anyone out or disturb a running session.
  Future<void> setInterfaceLanguage(String code) async {
    interfaceLanguageCode = code;
    displayPreferencesChanged();
    await _speechLanguageChanged();
    await save();
    await rescheduleReminders();
  }

  Future<void> setPatientLanguage(String code) async {
    patientLanguageCode = code;
    displayPreferencesChanged();
    await _speechLanguageChanged();
    await save();
    await rescheduleReminders();
  }

  /// Stop anything mid-sentence and drop the bound voice.
  ///
  /// Without this a language change would finish the current utterance in the
  /// previous language, which is exactly the silent substitution the speech
  /// layer exists to prevent.
  Future<void> _speechLanguageChanged() async {
    if (!speechStarted) return;
    await speech.handleLanguageChanged();
  }

  /// The app went to the background, or a patient session ended.
  Future<void> stopSpeaking() async {
    if (!speechStarted) return;
    await speech.handleAppBackgrounded();
  }

  /// Turn spoken output on or off. Off stops immediately rather than at the
  /// end of the current sentence.
  Future<void> setAudioEnabled(bool enabled) async {
    audioEnabled = enabled;
    if (!enabled) await stopSpeaking();
    displayPreferencesChanged();
    await save();
    await rescheduleReminders();
  }

  Future<void> rescheduleReminders() async {
    if (reminders.isEmpty && !reminderService.ready) return;
    try {
      await reminderService.restore(reminders,
          sound: audioEnabled, languageCode: effectivePatientLanguageCode);
    } catch (_) {
      reminderService.status =
          'Language saved. Could not reschedule reminders; retry from Reminders.';
    }
  }

  bool patientMode = false;
  bool reducedMotion = false;
  bool preferTouch = false;
  bool synthetic = false;
  String? storageError;
  Future<void> save() async {
    try {
      final signature = _contentSignature();
      if (signature != _savedContent) {
        personalizationDirty = true;
        localContentVersion =
            'l${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
        _savedContent = signature;
      }
      await repository?.saveSettings(toJson());
      storageError = null;
    } catch (_) {
      storageError = 'Could not save on this device. Please try again.';
      rethrow;
    }
  }

  Map<String, Object?> toJson({bool includeSnapshots = true}) => {
        if (includeSnapshots) 'patient_snapshots': _patientSnapshots,
        'personalization_loaded': personalizationLoaded,
        'server_words': serverWords,
        'profile_version': profileVersion,
        'config_version': configVersion,
        'server_activity': serverActivity,
        'personalization_preferences': personalizationPreferences,
        'personalization_dirty': personalizationDirty,
        'local_content_version': localContentVersion,
        'patient_id': patientId,
        'patient_name': patientName,
        'patient_age': patientAge,
        'language': patientLanguage,
        'condition': knownConditionType,
        'caregiver_name': caregiverName,
        'patient_mode': patientMode,
        'interface_language': interfaceLanguageCode,
        'patient_language_code': patientLanguageCode,
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
            .map((e) => {
                  'label': e.label,
                  'caption': e.caption,
                  'kind': e.kind,
                  'media_asset_id': e.mediaAssetId
                })
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
    if (data != null) _restoreSettings(data);
    await repository?.recoverInterrupted();
    await refreshHistory();
  }

  void _restoreSettings(Map<String, dynamic> data) {
    _patientSnapshots.addAll(
        (data['patient_snapshots'] as Map? ?? {}).cast<String, dynamic>());
    personalizationLoaded = data['personalization_loaded'] == true;
    serverWords = (data['server_words'] as List? ?? [])
        .map((w) => (w as Map).cast<String, dynamic>())
        .toList();
    profileVersion = data['profile_version'] as int? ?? 1;
    configVersion = data['config_version'] as int? ?? 0;
    serverActivity = (data['server_activity'] as Map?)?.cast<String, dynamic>();
    personalizationPreferences =
        (data['personalization_preferences'] as Map? ?? {})
            .cast<String, dynamic>();
    personalizationDirty = data['personalization_dirty'] == true;
    localContentVersion = data['local_content_version'] as String? ?? 'local-0';
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
    interfaceLanguageCode = data['interface_language'] as String? ?? 'en';
    patientLanguageCode = data['patient_language_code'] as String? ?? '';
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
          caption: item['caption'] as String?,
          kind: item['kind'] as String?,
          mediaAssetId: item['media_asset_id'] as String?));
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
    _savedContent = _contentSignature();
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
      if (body['patient_id'] != patientId) continue;
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

  // C1 sign-in status; only connect() establishes real caregiver access.
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
