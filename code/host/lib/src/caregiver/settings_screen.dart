import 'package:flutter/material.dart';

import '../host_flow_state.dart';
import 'sign_in_screen.dart';

/// C7 Settings / Sync: language, audio, accessibility, and sync status.
///
/// There is no backend yet, so "sync" is always "Never" here — this screen
/// exists to show where that status will live once the outbox is wired in.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _signOut() {
    widget.flowState.caregiverSignedIn = false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            SignInScreen(flowState: widget.flowState),
      ),
      (Route<void> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & sync')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SwitchListTile(
              title: const Text('Audio cues'),
              value: widget.flowState.audioEnabled,
              onChanged: (bool value) =>
                  setState(() => widget.flowState.audioEnabled = value),
            ),
            const Divider(),
            const ListTile(
              title: Text('Text size'),
              subtitle: Text(
                  'Set per game session for now; a standing preference comes later.'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('Last successful sync'),
              subtitle: Text('Never — no backend connection yet'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                  onPressed: _signOut, child: const Text('Sign out')),
            ),
          ],
        ),
      ),
    );
  }
}
