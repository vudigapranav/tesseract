import 'package:flutter/material.dart';

import 'design_system.dart';
import 'host_flow_state.dart';
import 'speech/speak_button.dart';

/// The patient's view of today's reminders.
///
/// Independent of gameplay: this screen works whether or not the patient ever
/// opens an activity, and it never mentions sessions or progress.
///
/// Acknowledging is **not** a record that anything was actually done — it is
/// only "I have seen this". The wording says so plainly, and nothing here
/// claims medication adherence or reports an outcome to a clinician.
class PatientRemindersScreen extends StatefulWidget {
  const PatientRemindersScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<PatientRemindersScreen> createState() => _PatientRemindersScreenState();
}

class _PatientRemindersScreenState extends State<PatientRemindersScreen> {
  HostFlowState get flow => widget.flowState;

  Future<void> _persist() async {
    try {
      await flow.save();
    } catch (_) {
      // Saving is best-effort from the patient's side; the caregiver screen
      // surfaces storage problems. Never show the patient an error they
      // cannot act on.
    }
    try {
      await flow.reminderService.restore(flow.reminders,
          sound: flow.audioEnabled,
          languageCode: flow.effectivePatientLanguageCode);
    } catch (_) {
      // Rescheduling can fail if notifications are not permitted. The
      // in-app list below still shows the reminder.
    }
  }

  Future<void> _acknowledge(ReminderItem reminder) async {
    setState(() {
      reminder.acknowledgedAt = DateTime.now();
      reminder.postponedUntil = null;
    });
    await _persist();
  }

  Future<void> _postpone(ReminderItem reminder) async {
    setState(() {
      reminder.postponedUntil = DateTime.now().add(const Duration(minutes: 15));
      reminder.acknowledgedAt = null;
    });
    await _persist();
  }

  bool _acknowledgedToday(ReminderItem reminder) {
    final DateTime? when = reminder.acknowledgedAt;
    if (when == null) {
      return false;
    }
    final DateTime now = DateTime.now();
    return when.year == now.year &&
        when.month == now.month &&
        when.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ReminderItem> active = flow.reminders
        .where((ReminderItem r) => r.enabled)
        .toList(growable: false)
      ..sort((ReminderItem a, ReminderItem b) =>
          (a.time.hour * 60 + a.time.minute)
              .compareTo(b.time.hour * 60 + b.time.minute));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                TesseractDesign.gutter, 8, TesseractDesign.gutter, 32),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    tooltip: 'Go back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Today', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              if (active.isEmpty)
                TesseractCard(
                  child: Text(
                    'Nothing to remember right now.',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              else
                for (final ReminderItem reminder in active)
                  _reminderCard(theme, reminder),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reminderCard(ThemeData theme, ReminderItem reminder) {
    final bool seen = _acknowledgedToday(reminder);
    final String time = reminder.time.format(context);

    return TesseractCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(seen ? Icons.done_rounded : Icons.schedule_rounded,
                  size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(reminder.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: TesseractDesign.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // The reminder is read in the patient's language, but the words
          // spoken are the caregiver's own — this reads the title back, it
          // does not translate or rephrase what they wrote.
          SpeakButton(
            service: flow.speech,
            text: '${reminder.title}. $time',
            languageCode: flow.effectivePatientLanguageCode,
            compact: true,
          ),
          const SizedBox(height: 16),
          if (seen)
            // Says exactly what was recorded, and no more.
            Text(
              'You have seen this one.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: TesseractDesign.inkSoft),
            )
          else ...<Widget>[
            BigPatientAction(
              label: 'OK, I have seen this',
              icon: Icons.check_rounded,
              onPressed: () => _acknowledge(reminder),
            ),
            BigPatientAction(
              label: 'Remind me a bit later',
              icon: Icons.snooze_rounded,
              primary: false,
              onPressed: () => _postpone(reminder),
            ),
          ],
        ],
      ),
    );
  }
}
