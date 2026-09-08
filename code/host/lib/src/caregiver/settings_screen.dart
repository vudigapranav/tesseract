import 'package:flutter/material.dart';
import '../host_flow_state.dart';
import 'sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.flowState});
  final HostFlowState flowState;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> save() async {
    try {
      await widget.flowState.save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Settings could not be saved. Try again.')));
      }
    }
  }

  Future<void> signOut() async {
    // Persist this caregiver's data into their own partition first, then drop
    // the active-identity pointer so the next launch starts signed out
    // instead of reopening their patient's content. Their data is kept for
    // when they sign back in; it is not deleted.
    await save();
    await widget.flowState.identity.signOut();
    await widget.flowState.repository?.clearActiveScope();
    widget.flowState.caregiverSignedIn = false;
    widget.flowState.patientMode = false;
    widget.flowState.api = null;
    widget.flowState.outbox = null;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
            builder: (_) => SignInScreen(flowState: widget.flowState)),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flowState;
    return Scaffold(
        appBar: AppBar(title: const Text('Settings & sync')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          SwitchListTile(
              title: const Text('Reminder sound'),
              subtitle: const Text(
                  'Controls sounds for newly scheduled reminders. Games currently have no audio playback.'),
              value: flow.audioEnabled,
              onChanged: (v) async {
                setState(() => flow.audioEnabled = v);
                await save();
              }),
          SwitchListTile(
              title: const Text('Reduce motion'),
              value: flow.reducedMotion,
              onChanged: (v) async {
                setState(() => flow.reducedMotion = v);
                flow.displayPreferencesChanged();
                await save();
              }),
          const ListTile(
              title: Text('Text size'),
              subtitle: Text(
                  'Applies straight away, on top of the Android text-size setting.')),
          Slider(
              value: flow.textScalePreference,
              min: 1,
              max: 2,
              divisions: 4,
              label: '${flow.textScalePreference}×',
              onChanged: (v) {
                setState(() => flow.textScalePreference = v);
                flow.displayPreferencesChanged();
              },
              onChangeEnd: (_) => save()),
          const ListTile(
              title: Text('Language'),
              subtitle:
                  Text('English. Regional translations await native review.')),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Synchronization'),
                        const SizedBox(height: 8),
                        Text(flow.synthetic
                            ? 'Synthetic development data • saved locally'
                            : flow.syncStatus),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: () async {
                              await flow.synchronize();
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            child: const Text('Sync now'))
                      ]))),
          FutureBuilder(
              future: flow.repository?.sessions(pendingOnly: true),
              builder: (context, snapshot) => ListTile(
                  title: const Text('Pending session uploads'),
                  subtitle: Text(
                      '${snapshot.data?.length ?? 0} retained on this device'))),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: signOut, child: const Text('Sign out')),
        ])));
  }
}
