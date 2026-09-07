import 'package:flutter/material.dart';

import 'caregiver/caregiver_home_screen.dart';
import 'host_flow_state.dart';

/// A small, deliberately unobtrusive control that lets a caregiver reclaim
/// the device from patient mode — placed on the idle patient screens (Home,
/// Rest), never during an active game.
///
/// This is a placeholder gate: a confirmation dialog, not real
/// authentication. "Clear caregiver return control protected by caregiver
/// authentication or a reviewed local gate" (per the patient-mode spec)
/// still needs a real PIN/biometric/re-auth step before this ships.
class CaregiverReturnGate extends StatelessWidget {
  const CaregiverReturnGate({super.key, required this.flowState});

  final HostFlowState flowState;

  Future<void> _confirmReturn(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('For the caregiver'),
        content: const Text('Switch to the caregiver area?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              CaregiverHomeScreen(flowState: flowState),
        ),
        (Route<void> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Caregiver',
      onPressed: () => _confirmReturn(context),
      icon: const Icon(Icons.shield_outlined),
    );
  }
}
