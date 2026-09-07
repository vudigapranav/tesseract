import 'package:flutter/material.dart';

import 'host_flow_state.dart';
import 'host_strings.dart';

/// P9 Simple Progress: recent activities and gentle completion
/// acknowledgements. No percentages, rankings, streak loss or cognitive
/// scores — a plain list of what was played.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  Widget build(BuildContext context) {
    final List<ActivityRecord> recent =
        flowState.activityHistory.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Recent activities')),
      body: SafeArea(
        child: recent.isEmpty
            ? const Center(child: Text('Nothing played yet today.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recent.length,
                itemBuilder: (BuildContext context, int index) {
                  final ActivityRecord record = recent[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title:
                          Text(HostStrings.displayName(record.displayNameKey)),
                      subtitle: Text(_friendlyTime(record.completedAt)),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _friendlyTime(DateTime time) {
    final DateTime now = DateTime.now();
    final bool sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    if (sameDay) {
      final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final String minute = time.minute.toString().padLeft(2, '0');
      final String period = time.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}
