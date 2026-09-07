import 'package:flutter/material.dart' show TimeOfDay;

import '../games/game_registry.dart';

/// One Know Me entry (C3): a person, place, or interest.
class KnowMeItem {
  KnowMeItem({required this.label, this.caption});
  String label;
  String? caption;
}

/// One caregiver-defined routine reminder (C6), independent of any game.
class ReminderItem {
  ReminderItem({required this.title, required this.time, this.enabled = true});
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
