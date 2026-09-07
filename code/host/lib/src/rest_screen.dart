import 'package:flutter/material.dart';

import 'caregiver_return_gate.dart';
import 'choose_game_screen.dart';
import 'home_screen.dart';
import 'host_flow_state.dart';

/// P8 Rest State: calm idle state, no active session — distinct from a
/// paused game (P5), where a session is waiting to resume. Home and Ready
/// to play are both offered, per the patient-mode spec for this screen.
class RestScreen extends StatelessWidget {
  const RestScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: CaregiverReturnGate(flowState: flowState),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Resting',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Come back whenever you feel ready.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  ChooseGameScreen(flowState: flowState),
                            ),
                            (Route<void> route) => false,
                          );
                        },
                        child: const Text('Ready to play'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  HomeScreen(flowState: flowState),
                            ),
                            (Route<void> route) => false,
                          );
                        },
                        child: const Text('Home'),
                      ),
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
