import 'package:flutter/material.dart';

import '../games/game_registry.dart';
import 'host_flow_state.dart';
import 'host_strings.dart';
import 'how_to_play_screen.dart';

/// P2 Choose Activity: cards built from the registry, at most three shown.
class ChooseGameScreen extends StatelessWidget {
  const ChooseGameScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final List<GameRegistration> shown = gameRegistry.take(3).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Choose an activity')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: shown
              .map((GameRegistration registration) =>
                  _GameCard(registration: registration, flowState: flowState))
              .toList(),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.registration, required this.flowState});

  final GameRegistration registration;
  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 96,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => HowToPlayScreen(
                      flowState: flowState, registration: registration),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(registration.icon, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      HostStrings.displayName(registration.displayNameKey),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
