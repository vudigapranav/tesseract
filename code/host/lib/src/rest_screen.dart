import 'package:flutter/material.dart';

import 'caregiver_return_gate.dart';
import 'choose_game_screen.dart';
import 'design_system.dart';
import 'home_screen.dart';
import 'host_flow_state.dart';

/// P8 Rest State: a calm idle screen with no active session.
///
/// Distinct from a paused game (P5), where a session is still waiting to
/// resume. Nothing here nudges the patient back into an activity: resting is
/// a legitimate place to stay.
class RestScreen extends StatelessWidget {
  const RestScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: CaregiverReturnGate(flowState: flowState),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TesseractDesign.gutter, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 12),
                      Text('Resting',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        'Come back whenever you feel ready.',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: TesseractDesign.inkSoft),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      BigPatientAction(
                        label: 'Ready to play',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  ChooseGameScreen(flowState: flowState),
                            ),
                            (Route<void> route) => false,
                          );
                        },
                      ),
                      BigPatientAction(
                        label: 'Home',
                        icon: Icons.home_rounded,
                        primary: false,
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  HomeScreen(flowState: flowState),
                            ),
                            (Route<void> route) => false,
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
