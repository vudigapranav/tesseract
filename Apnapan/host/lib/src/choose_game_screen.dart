import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'design_system.dart';
import 'host_flow_state.dart';
import 'host_strings.dart';
import 'how_to_play_screen.dart';

/// P2 Choose Activity.
///
/// One large, plainly labelled choice per activity. No timer, no scores, no
/// "recommended" badge — the patient is choosing what they feel like doing,
/// and nothing here should read as a test.
class ChooseGameScreen extends StatelessWidget {
  const ChooseGameScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  /// A calm, concrete sentence about what the activity involves. Keyed by
  /// game id so a new game supplies its own without changing this screen.
  static const Map<String, String> _whatItIs = <String, String>{
    'route_quest': 'Find your way to a place and back again.',
    'marble_maze': 'Guide the marble gently to the end.',
    'word_search': 'Find familiar words hidden in the letters.',
    'routine_recall': 'Remember what comes next in the day.',
    'picture_sorting': 'Put each picture with the ones like it.',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const List<GameRegistration> shown = gameRegistry;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                TesseractDesign.gutter, 16, TesseractDesign.gutter, 32),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    tooltip: 'Go back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('What would you like to do?',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Take your time. You can stop whenever you like.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: TesseractDesign.inkSoft),
              ),
              const SizedBox(height: 28),
              for (final GameRegistration registration in shown)
                BigPatientAction(
                  label: HostStrings.displayName(registration.displayNameKey),
                  subtitle: _whatItIs[registration.gameId],
                  icon: registration.icon,
                  primary: false,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => HowToPlayScreen(
                          flowState: flowState, registration: registration),
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
