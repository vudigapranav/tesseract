import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'host_flow_state.dart';
import 'host_strings.dart';
import 'how_to_play_screen.dart';
import 'rest_screen.dart';

/// P6 Session Finished: warm, one plain count (never accuracy, never a
/// comparison to last time), Rest as the primary action and Play again as
/// secondary. No failure summary — this screen renders the same way
/// regardless of how the session ended.
class FinishedScreen extends StatelessWidget {
  const FinishedScreen(
      {super.key, required this.flowState, required this.registration});

  final HostFlowState flowState;
  final GameRegistration registration;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _CompletionMark(gameId: registration.gameId),
              const SizedBox(height: 20),
              Text('All done for now!',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Thank you for playing ${HostStrings.displayName(registration.displayNameKey)}.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Activities today: ${flowState.completedActivitiesCount}',
                style: theme.textTheme.titleMedium,
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
                              RestScreen(flowState: flowState)),
                      (Route<void> route) => false,
                    );
                  },
                  child: const Text('Rest'),
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
                        builder: (BuildContext context) => HowToPlayScreen(
                            flowState: flowState, registration: registration),
                      ),
                      (Route<void> route) => false,
                    );
                  },
                  child: const Text('Play again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionMark extends StatelessWidget {
  const _CompletionMark({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final bool isRoute = gameId == 'route_quest';
    return TweenAnimationBuilder<double>(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.82, end: 1),
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: isRoute ? const Color(0xFFF6D895) : const Color(0xFFD8F1ED),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFFCF4), width: 6),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF315C4A).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isRoute ? Icons.flag_rounded : Icons.check_circle_rounded,
          size: 54,
          color: isRoute ? const Color(0xFFB94D2B) : const Color(0xFF21746B),
        ),
      ),
    );
  }
}
