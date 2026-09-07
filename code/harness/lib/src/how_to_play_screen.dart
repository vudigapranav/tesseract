import 'package:flutter/material.dart';

/// Host-owned "How to Play" screen (P3). A game never draws this — it owns
/// only its own pause overlay.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({
    super.key,
    required this.gameName,
    required this.instructions,
    required this.onStart,
  });

  final String gameName;
  final String instructions;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                gameName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(instructions, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(onPressed: onStart, child: const Text('Start')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
