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
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(registration.icon, size: 56),
              const SizedBox(height: 16),
              Text(
                _instructionsFor(registration.gameId, flowState.preferTouch),
                style: Theme.of(context).textTheme.titleLarge,
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
        )),
      ),
    );
  }
}

/// One short, concrete instruction per activity.
///
/// Written for the person playing, not for a reviewer: what to do first, what
/// finishes it, and the reassurance that Help is there. Every game says Help
/// is available, because a patient who cannot find it will simply stop.
String _instructionsFor(String gameId, bool preferTouch) {
  switch (gameId) {
    case 'route_quest':
      return 'Follow the road to the flag. Tap a connected place to move. '
          'Pick up the flag, then return home. Help shows the way.';
    case 'marble_maze':
      return preferTouch
          ? 'Guide the marble along the wooden paths with your finger. Reach '
              'the glowing goal. Help shows the route.'
          : 'Hold your phone comfortably while it settles, then gently tilt to '
              'guide the marble to the glowing goal. If tilt is unavailable, '
              'use your finger. Help shows the route.';
    case 'word_search':
      return 'Find each word in the letters. Tap the first letter, then tap '
          'the last letter. Words go across, down, and sometimes at an angle. '
          'Help points out a word.';
    case 'routine_recall':
      return 'You will see a step from the day. Choose what usually comes '
          'next. If it is not the one, just try again. Help shows the answer.';
    case 'picture_sorting':
      return 'Look at the picture, then choose the group it belongs to. If it '
          'is not the one, just try again. Help shows the group.';
    default:
      return 'Take your time. Help is always there if you need it, and you '
          'can take a break whenever you like.';
  }
}
