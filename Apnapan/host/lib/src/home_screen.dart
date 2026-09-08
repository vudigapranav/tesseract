import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'caregiver_return_gate.dart';
import 'choose_game_screen.dart';
import 'design_system.dart';
import 'host_flow_state.dart';
import 'patient_reminders_screen.dart';
import 'host_strings.dart';
import 'personalized_activity_screen.dart';
import 'progress_screen.dart';
import 'web_preview_banner.dart';

/// P1 Home: warm greeting, one primary Start action, and today's suggested
/// activity, plus small optional Progress access.
///
/// Start leads to the caregiver-approved activity (P7) when one has been
/// set at Hand Over (C5), otherwise to Choose Activity (P2).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameRegistration suggested =
        flowState.approvedActivity ?? gameRegistry.first;
    final bool hasApprovedActivity = flowState.approvedActivity != null;
    final int dueReminders =
        flowState.reminders.where((ReminderItem r) => r.enabled).length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              if (kIsWeb) const WebPreviewBanner(),
              Align(
                alignment: Alignment.topRight,
                child: CaregiverReturnGate(flowState: flowState),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Hello!',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        'Ready for a little activity?',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: <Widget>[
                              Icon(suggested.icon, size: 40),
                              const SizedBox(height: 8),
                              Text('Suggested for today',
                                  style: theme.textTheme.labelLarge),
                              Text(
                                HostStrings.displayName(
                                    suggested.displayNameKey),
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      BigPatientAction(
                        label: 'Start',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  hasApprovedActivity
                                      ? PersonalizedActivityScreen(
                                          flowState: flowState)
                                      : ChooseGameScreen(flowState: flowState),
                            ),
                          );
                        },
                      ),
                      // Reminders are reachable without ever starting an
                      // activity: they do not depend on gameplay.
                      if (dueReminders > 0)
                        BigPatientAction(
                          label: 'Today\'s reminders',
                          icon: Icons.notifications_none_rounded,
                          primary: false,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    PatientRemindersScreen(
                                        flowState: flowState),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('See recent activities'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  ProgressScreen(flowState: flowState),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
