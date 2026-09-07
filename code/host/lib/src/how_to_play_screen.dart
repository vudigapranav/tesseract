import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'host_flow_state.dart';
import 'host_strings.dart';
import 'play_screen.dart';

/// P3 How to Play: one short instruction, then Begin.
///
/// Marks the resulting session `isTutorial` the first time this game is
/// chosen this app run — see [HostFlowState] for why that tracking is
/// in-memory only for now, and why that is a deliberate, documented
/// simplification rather than real per-patient history.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({
    super.key,
    required this.flowState,
    required this.registration,
    this.level = 1,
  });

  final HostFlowState flowState;
  final GameRegistration registration;

  /// The host sets the level; a game never sets its own. Defaults to 1 when
  /// arriving from Choose Activity (P2); Personalized Activity (P7) passes
  /// through whatever the caregiver picked at Hand Over.
  final int level;

  @override
  Widget build(BuildContext context) {
    final bool isFirstTimeThisRun =
        !flowState.tutorialShownGameIds.contains(registration.gameId);
    return Scaffold(
      appBar: AppBar(
          title: Text(HostStrings.displayName(registration.displayNameKey))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(registration.icon, size: 56),
              const SizedBox(height: 16),
              Text(
                "Let's try together. Take your time.",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    flowState.tutorialShownGameIds.add(registration.gameId);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => PlayScreen(
                          flowState: flowState,
                          registration: registration,
                          level: level,
                          isTutorial: isFirstTimeThisRun,
                        ),
                      ),
                    );
                  },
                  child: const Text('Begin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
