import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'choose_game_screen.dart';
import 'host_flow_state.dart';
import 'host_strings.dart';
import 'how_to_play_screen.dart';

/// P7 Personalized Activity: a familiar suggested activity using
/// caregiver-approved content and settings. The patient may choose another.
///
/// Reached from Home (P1) when a caregiver picked an activity at Hand Over
/// (C5). If the approved activity's content is ever missing, this should
/// fall back to Choose Activity (P2) — not attempted yet, since there is no
/// real content pipeline to fail.
class PersonalizedActivityScreen extends StatelessWidget {
  const PersonalizedActivityScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final GameRegistration registration =
        flowState.approvedActivity ?? gameRegistry.first;
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(registration.icon, size: 64),
              const SizedBox(height: 16),
              Text('Your activity today',
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.center),
              Text(
                HostStrings.displayName(registration.displayNameKey),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => HowToPlayScreen(
                          flowState: flowState,
                          registration: registration,
                          level: flowState.approvedLevel,
                        ),
                      ),
                    );
                  },
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          ChooseGameScreen(flowState: flowState),
                    ),
                  );
                },
                child: const Text('Choose another activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
