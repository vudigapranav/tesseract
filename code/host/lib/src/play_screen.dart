import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import '../games/game_registry.dart';
import 'content/know_me_content.dart';
import 'finished_screen.dart';
import 'host_flow_state.dart';
import 'session_controller.dart';

/// P4 Cognitive Game: hosts the chosen game edge to edge, for the largest
/// possible play area.
///
/// The game owns its own Help/Break controls and pause overlay entirely —
/// this screen adds no chrome around it at all. There is no developer
/// event-log control on the patient surface; events still flow to
/// [SessionController] through [_onEvent], unseen by the patient.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.flowState,
    required this.registration,
    required this.level,
    required this.isTutorial,
  });

  final HostFlowState flowState;
  final GameRegistration registration;
  final int level;
  final bool isTutorial;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final SessionController _session = SessionController(
    registration: widget.registration,
    level: widget.level,
    isTutorial: widget.isTutorial,
    repository: widget.flowState.repository,
    patientId: widget.flowState.patientId,
    preferTouch: widget.flowState.preferTouch,
    // Caregiver-entered Know Me content, as opaque-id items. Falls back to
    // neutral places when Know Me was skipped or is short.
    items: KnowMeContent.itemsFor(widget.flowState, widget.registration.gameId),
  );
  void _onEvent(GameEvent event) {
    _session.recordEvent(event);
  }

  bool _finishing = false;
  Future<void> _onFinish(GameResult result) async {
    if (_finishing) {
      return;
    }
    _finishing = true;
    _session.finish(result);
    if (result.status == GameResultStatus.completed) {
      widget.flowState.completedActivitiesCount += 1;
    }
    widget.flowState.activityHistory.add(
      ActivityRecord(
        gameId: widget.registration.gameId,
        displayNameKey: widget.registration.displayNameKey,
        completedAt: DateTime.now(),
        status: result.status,
      ),
    );
    try {
      await _session.flush();
      await widget.flowState.save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Activity could not be fully saved. Please tell your caregiver.')));
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 380),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => FinishedScreen(
          flowState: widget.flowState, registration: widget.registration),
      transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
        final Animation<double> eased =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: eased,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(eased),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final GameConfig config = _session.buildConfig(textScale: textScale);
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Use Break, then Finish for now to leave this activity.')));
          }
        },
        child: Scaffold(
          body: SafeArea(
              child: widget.registration.builder(
                  config: config, onEvent: _onEvent, onFinish: _onFinish)),
        ));
  }
}
