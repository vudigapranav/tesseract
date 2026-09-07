import 'package:flutter/material.dart';

import '../host_flow_state.dart';
import '../host_strings.dart';
import 'hand_over_screen.dart';
import 'know_me_screen.dart';
import 'patient_basics_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

/// C4 Caregiver Home: patient status, today's activity, basic alerts, and
/// links to Know Me, reminders and settings.
///
/// "Patient status" here is only the last known local activity — never live
/// health monitoring. There are no real alerts yet (failed sync, missing
/// content, pending recommendations) since none of those systems exist.
class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ActivityRecord? last = flowState.activityHistory.isEmpty
        ? null
        : flowState.activityHistory.last;
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver home')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              flowState.patientName.isEmpty
                  ? 'No patient set up yet'
                  : flowState.patientName,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              last == null
                  ? 'No activity yet.'
                  : 'Last activity: ${HostStrings.displayName(last.displayNameKey)} (${last.status})',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Patient basics & Know Me'),
                subtitle: const Text(
                    'Name, language, people, places, familiar words'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        PatientBasicsScreen(flowState: flowState),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Know Me'),
                subtitle: const Text(
                    'Edit people, places and familiar words directly'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        KnowMeScreen(flowState: flowState),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Reminders'),
                subtitle: Text('${flowState.reminders.length} set up'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        RemindersScreen(flowState: flowState),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings & sync'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        SettingsScreen(flowState: flowState),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                icon: const Icon(Icons.smartphone),
                label: const Text('Hand over to patient'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        HandOverScreen(flowState: flowState),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
