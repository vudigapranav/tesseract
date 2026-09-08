import 'package:flutter/material.dart';
import '../host_flow_state.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen(
      {super.key, required this.flowState, this.patientView = false});
  final HostFlowState flowState;
  final bool patientView;
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Future<void> save() async {
    try {
      await widget.flowState.save();
      await widget.flowState.reminderService.restore(widget.flowState.reminders,
          sound: widget.flowState.audioEnabled,
          languageCode: widget.flowState.effectivePatientLanguageCode);
    } catch (_) {
      widget.flowState.reminderService.status =
          'Could not save or schedule. Please try again.';
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> edit([ReminderItem? original]) async {
    final controller = TextEditingController(text: original?.title);
    var time = original?.time ?? const TimeOfDay(hour: 8, minute: 0);
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: Text(original == null
                        ? 'New daily reminder'
                        : 'Edit daily reminder'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                              labelText: 'Reminder',
                              hintText: 'For example, water the plants')),
                      const SizedBox(height: 16),
                      TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context, initialTime: time);
                            if (picked != null) {
                              update(() => time = picked);
                            }
                          },
                          child: Text(time.format(context)))
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Save'))
                    ])));
    final title = controller.text.trim();
    // Dispose after the dialog route's closing animation releases its field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (accepted != true || title.isEmpty || !mounted) {
      return;
    }
    if (original == null) {
      widget.flowState.reminders.add(ReminderItem(title: title, time: time));
    } else {
      original.title = title;
      original.time = time;
      original.postponedUntil = null;
    }
    await save();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Everyday reminders')),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        if (!widget.patientView) ...[
          Text(widget.flowState.reminderService.status),
          TextButton(
              onPressed: () async {
                await widget.flowState.reminderService.permission();
                await save();
              },
              child: const Text('Allow notifications')),
          const Text(
              'Daily reminders follow this device’s time zone. Acknowledging a reminder does not confirm that a task or medication was completed.')
        ],
        if (widget.flowState.reminders.isEmpty)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No reminders yet. Your caregiver can add one.')),
        for (final r in widget.flowState.reminders)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                            'Daily • ${r.time.format(context)}${r.enabled ? "" : " • Off"}'),
                        if (r.acknowledgedAt != null)
                          Text('Acknowledged ${r.acknowledgedAt!.toLocal()}'),
                        if (r.postponedUntil != null)
                          Text(
                              'Postponed until ${r.postponedUntil!.toLocal()}'),
                        Wrap(spacing: 8, children: [
                          if (r.enabled)
                            TextButton(
                                onPressed: () async {
                                  r.acknowledgedAt = DateTime.now();
                                  r.postponedUntil = null;
                                  await widget.flowState.reminderService.plugin
                                      .cancel(id: r.id + 1000000000);
                                  await save();
                                },
                                child: const Text('Acknowledge')),
                          if (r.enabled)
                            TextButton(
                                onPressed: () async {
                                  r.postponedUntil = DateTime.now()
                                      .add(const Duration(minutes: 15));
                                  await save();
                                },
                                child: const Text('Later • 15 min')),
                          if (!widget.patientView) ...[
                            TextButton(
                                onPressed: () => edit(r),
                                child: const Text('Edit')),
                            TextButton(
                                onPressed: () async {
                                  r.enabled = !r.enabled;
                                  await save();
                                },
                                child:
                                    Text(r.enabled ? 'Turn off' : 'Turn on')),
                            TextButton(
                                onPressed: () async {
                                  widget.flowState.reminders.remove(r);
                                  await save();
                                },
                                child: const Text('Remove'))
                          ],
                        ])
                      ]))),
        const SizedBox(height: 80),
      ])),
      floatingActionButton: widget.patientView
          ? null
          : FloatingActionButton.extended(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('New reminder')));
}
