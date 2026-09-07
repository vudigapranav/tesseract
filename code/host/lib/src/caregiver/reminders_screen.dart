import 'package:flutter/material.dart';

import '../host_flow_state.dart';

/// C6 Reminders: create, edit, enable, postpone or remove routine
/// reminders — independent of games.
///
/// No local notification scheduling exists yet; these are stored in memory
/// only. Acknowledgement vs. actual completion, and real scheduling, are
/// later integration work.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Future<void> _addReminder() async {
    final TextEditingController controller = TextEditingController();
    TimeOfDay time = TimeOfDay.now();
    final bool? added = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('New reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(labelText: 'e.g. Drink water'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Time: ${time.format(context)}'),
                      TextButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                              context: context, initialTime: time);
                          if (picked != null) {
                            setDialogState(() => time = picked);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Add')),
              ],
            );
          },
        );
      },
    );
    if (added == true && controller.text.trim().isNotEmpty) {
      setState(() {
        widget.flowState.reminders
            .add(ReminderItem(title: controller.text.trim(), time: time));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: widget.flowState.reminders.isEmpty
            ? const Center(child: Text('No reminders yet.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: widget.flowState.reminders
                    .map(
                      (ReminderItem reminder) => Card(
                        child: SwitchListTile(
                          title: Text(reminder.title),
                          subtitle: Text(reminder.time.format(context)),
                          value: reminder.enabled,
                          onChanged: (bool value) =>
                              setState(() => reminder.enabled = value),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() =>
                                widget.flowState.reminders.remove(reminder)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add),
        label: const Text('Add reminder'),
      ),
    );
  }
}
