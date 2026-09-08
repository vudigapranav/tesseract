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
    final bool confirmed = await flowState.identity.unlock();
    if (!confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Caregiver area stays locked. Set up a device screen lock and try again.')));
    }
    if (confirmed == true && context.mounted) {
      flowState.patientMode = false;
      await flowState.save();
      if (!context.mounted) {
        return;
      }
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
