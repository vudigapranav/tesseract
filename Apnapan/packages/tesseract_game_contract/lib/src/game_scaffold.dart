import 'package:flutter/material.dart';

import 'game_strings.dart';

/// Optional shared chrome for a game: the permanent Help and Break controls,
/// and the pause overlay behind Break.
///
/// **Additive and optional.** Route Quest and Marble Maze draw their own
/// equivalents and are unchanged; this exists so games written later do not
/// each re-implement the same patient-safety furniture slightly differently.
/// Nothing here emits events — the game still owns its recorder, so Help
/// still means `hint_requested` and Break still means `paused`, exactly as
/// before.
///
/// The rules this encodes, from the patient experience spec:
///
///  * Help and Break are always reachable while playing. They are never
///    hidden, disabled, or behind a menu.
///  * Pausing is not failure. The overlay offers Continue and Finish for now
///    with equal weight and says nothing about performance.
///  * There is no timer and no score anywhere in this chrome.
class TesseractGameScaffold extends StatelessWidget {
  const TesseractGameScaffold({
    super.key,
    required this.strings,
    required this.child,
    required this.paused,
    required this.onHelp,
    required this.onBreak,
    required this.onResume,
    required this.onFinish,
    this.background = const Color(0xFFF8F1DF),
    this.helpEnabled = true,
  });

  final GameStrings strings;

  /// The game's own play surface.
  final Widget child;

  final bool paused;
  final VoidCallback onHelp;
  final VoidCallback onBreak;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final Color background;

  /// Help can be temporarily unavailable (for example while feedback is
  /// showing) but never permanently removed.
  final bool helpEnabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: child),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: paused || !helpEnabled ? null : onHelp,
                        icon: const Icon(Icons.lightbulb_outline, size: 24),
                        label: FittedBox(child: Text(strings.helpButtonLabel)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: OutlinedButton(
                      onPressed: paused ? null : onBreak,
                      style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder()),
                      child: Tooltip(
                        message: strings.breakButtonLabel,
                        child: const Icon(Icons.pause_rounded, size: 25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (paused) _PauseOverlay(strings: strings, onResume: onResume, onFinish: onFinish),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.strings,
    required this.onResume,
    required this.onFinish,
  });

  final GameStrings strings;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(strings.pausedTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(strings.pausedBody, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: onResume,
                      child: FittedBox(child: Text(strings.resumeButtonLabel)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onFinish,
                      child:
                          FittedBox(child: Text(strings.finishNowButtonLabel)),
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
