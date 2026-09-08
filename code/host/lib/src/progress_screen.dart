import 'package:flutter/material.dart';

import 'design_system.dart';
import 'host_flow_state.dart';
import 'host_strings.dart';

/// P9 Simple Progress: a plain list of what was played.
///
/// No percentages, rankings, streaks or cognitive scores. Deliberately there
/// is also no failure state: a session the patient stopped early is shown the
/// same way as one they finished, because "you did this" is the message and
/// stopping when you have had enough is a perfectly good outcome.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ActivityRecord> recent =
        flowState.activityHistory.reversed.toList();

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
              Text('What you have been doing',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              if (recent.isEmpty)
                TesseractCard(
                  child: Text(
                    'Nothing yet today. Whenever you feel like it, there is an '
                    'activity waiting.',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              else
                for (final ActivityRecord record in recent)
                  TesseractCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.done_rounded, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'You played '
                                '${HostStrings.displayName(record.displayNameKey)}',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _friendlyTime(record.completedAt),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: TesseractDesign.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyTime(DateTime time) {
    final DateTime local = time.toLocal();
    final DateTime now = DateTime.now();
    final bool sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      final int hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final String minute = local.minute.toString().padLeft(2, '0');
      final String period = local.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    }
    return '${local.day}/${local.month}/${local.year}';
  }
}
