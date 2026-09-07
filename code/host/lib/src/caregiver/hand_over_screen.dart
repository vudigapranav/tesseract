import 'package:flutter/material.dart';

import '../../games/game_registry.dart';
import '../home_screen.dart';
import '../host_flow_state.dart';
import '../host_strings.dart';

/// C5 Hand Over: preview the activity and settings, then enter patient
/// mode. The caregiver's own return path back here is protected —
/// see [CaregiverReturnGate] on the patient side.
///
/// Companion ("playing together") mode is deliberately not offered here:
/// it is proposed in `PS003_ADDITIONS.md`, which is not yet approved.
class HandOverScreen extends StatefulWidget {
  const HandOverScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<HandOverScreen> createState() => _HandOverScreenState();
}

class _HandOverScreenState extends State<HandOverScreen> {
  late GameRegistration _selected =
      widget.flowState.approvedActivity ?? gameRegistry.first;
  late int _level = widget.flowState.approvedLevel;

  void _enterPatientMode() {
    widget.flowState.approvedActivity = _selected;
    widget.flowState.approvedLevel = _level;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            HomeScreen(flowState: widget.flowState),
      ),
      (Route<void> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hand over')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text("Today's activity", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            RadioGroup<GameRegistration>(
              groupValue: _selected,
              onChanged: (GameRegistration? value) =>
                  setState(() => _selected = value!),
              child: Column(
                children: gameRegistry
                    .map(
                      (GameRegistration g) => RadioListTile<GameRegistration>(
                        value: g,
                        title: Text(HostStrings.displayName(g.displayNameKey)),
                        secondary: Icon(g.icon),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Level', style: theme.textTheme.titleMedium),
            RadioGroup<int>(
              groupValue: _level,
              onChanged: (int? value) => setState(() => _level = value!),
              child: Row(
                children: <int>[1, 2, 3]
                    .map(
                      (int level) => Expanded(
                        child: RadioListTile<int>(
                            value: level, title: Text('$level')),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                icon: const Icon(Icons.smartphone),
                label: const Text('Enter patient mode'),
                onPressed: _enterPatientMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
