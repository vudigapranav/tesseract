import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Host-owned "Session Finished" screen (P6). No failure summary, no score —
/// a game never draws this either; it owns only its own pause overlay.
///
/// The status/assisted line is harness-only debug output for verifying the
/// contract wiring, not something the real product would show a patient.
class SessionFinishedScreen extends StatelessWidget {
  const SessionFinishedScreen({
    super.key,
    required this.gameName,
    required this.result,
    required this.onHome,
  });

  final String gameName;
  final GameResult result;
  final VoidCallback onHome;

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
                'All done for now',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Thank you for playing $gameName.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(
                '(harness debug — status: ${result.status}, assisted: ${result.assisted})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(onPressed: onHome, child: const Text('Home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
