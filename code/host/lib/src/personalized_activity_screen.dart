import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'choose_game_screen.dart';
import 'content/know_me_content.dart';
import 'design_system.dart';
import 'host_flow_state.dart';
import 'host_strings.dart';
import 'how_to_play_screen.dart';

/// P7 Personalized Activity: the activity a caregiver approved, using their
/// Know Me content.
///
/// The patient can always choose something else. An approved activity is a
/// suggestion, never an instruction — declining is offered with the same
/// prominence as accepting.
class PersonalizedActivityScreen extends StatelessWidget {
  const PersonalizedActivityScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final GameRegistration registration =
        flowState.approvedActivity ?? gameRegistry.first;
    final ThemeData theme = Theme.of(context);
    final bool personalised = KnowMeContent.hasPersonalContent(flowState);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: TesseractDesign.gutter, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    height: 132,
                    width: 132,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TesseractDesign.peach,
                    ),
                    child: Icon(registration.icon,
                        size: 64, color: TesseractDesign.ink),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Your activity today',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: TesseractDesign.inkSoft),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  HostStrings.displayName(registration.displayNameKey),
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (personalised) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'With places you know.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: TesseractDesign.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 36),
                BigPatientAction(
                  label: 'Start',
                  icon: Icons.play_arrow_rounded,
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
                ),
                BigPatientAction(
                  label: 'Choose something else',
                  icon: Icons.grid_view_rounded,
                  primary: false,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            ChooseGameScreen(flowState: flowState),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
