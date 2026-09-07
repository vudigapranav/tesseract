import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'caregiver_return_gate.dart';
import 'choose_game_screen.dart';
import 'host_flow_state.dart';
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
    return Scaffold(
      body: SafeArea(
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
                              HostStrings.displayName(suggested.displayNameKey),
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
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
                        child: const Text('Start'),
                      ),
                    ),
                    const SizedBox(height: 12),
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
    );
  }
}
