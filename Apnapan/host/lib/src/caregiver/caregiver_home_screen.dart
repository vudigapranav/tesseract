import 'package:flutter/material.dart';

import '../design_system.dart';
import '../host_flow_state.dart';
import '../host_strings.dart';
import 'hand_over_screen.dart';
import 'know_me_screen.dart';
import 'patient_basics_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

/// C4 Caregiver Home: what actually happened, what needs a decision, and the
/// way in to everything else.
///
/// "Patient status" is the recorded activity history only — never live health
/// monitoring, and never a score. A suggested activity change is shown here
/// because it needs a person to approve it; nothing is applied automatically.
class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  bool _busy = false;

  HostFlowState get flow => widget.flowState;

  Future<void> _selectPatient() async {
    setState(() => _busy = true);
    try {
      await flow.refreshPatients();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not load patients. Check connection and try again.')));
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final id = await showDialog<String>(
        context: context,
        builder: (context) =>
            SimpleDialog(title: const Text('Choose a patient'), children: [
              for (final p in flow.availablePatients)
                SimpleDialogOption(
                    onPressed: () =>
                        Navigator.pop(context, p['patient_id'] as String),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(p['display_name'] as String))),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'new'),
                  child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Create a patient'))),
            ]));
    if (id == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (id == 'new') {
        await flow.startNewPatient();
      } else {
        await flow.selectPatient(id);
      }
      if (mounted && id == 'new') {
        await Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) => PatientBasicsScreen(flowState: flow)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not change patient. Check your connection and try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      await flow.synchronize();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _decide(
    Map<String, dynamic> recommendation,
    String decision, {
    Map<String, Object?>? modifiedConfig,
  }) async {
    setState(() => _busy = true);
    try {
      await flow.decideRecommendation(
        recommendation['recommendation_id'] as String,
        decision: decision,
        modifiedConfig: modifiedConfig,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(switch (decision) {
        'accept' => 'Approved. The new activity is ready for the next session.',
        'modify' => 'Saved your choice. That is what will be offered next.',
        _ => 'Kept the current activity. Nothing has changed.',
      })));
    } catch (error) {
      if (!mounted) {
        return;
      }
      // A stale proposal or a lost connection must be visible, not retried
      // quietly behind the caregiver's back.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('That could not be saved. Nothing was changed. ($error)')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _chooseDifferentLevel(
      Map<String, dynamic> recommendation) async {
    final Map<String, dynamic> proposed =
        (recommendation['proposed_config'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> current =
        (recommendation['current_config'] as Map).cast<String, dynamic>();
    final int currentLevel = (current['level'] as num?)?.toInt() ?? 1;

    final int? chosen = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Choose the level yourself'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int level = 1; level <= 3; level++)
              ListTile(
                title: Text('Level $level'),
                subtitle: level == currentLevel
                    ? const Text('Current')
                    : (level == (proposed['level'] as num?)?.toInt()
                        ? const Text('Suggested')
                        : null),
                onTap: () => Navigator.of(context).pop(level),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (chosen == null) {
      return;
    }
    await _decide(recommendation, 'modify',
        modifiedConfig: <String, Object?>{...proposed, 'level': chosen});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Map<String, dynamic>> pending = flow.pendingRecommendations;
    final List<ActivityRecord> recent =
        flow.activityHistory.reversed.take(5).toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  TesseractDesign.gutter, 8, TesseractDesign.gutter, 32),
              children: <Widget>[
                _header(theme),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                if (flow.synthetic)
                  const StatusNote(
                    icon: Icons.science_outlined,
                    tone: StatusTone.attention,
                    text: 'Preview data. This is not a real patient record.',
                  ),
                if (flow.storageError != null)
                  StatusNote(
                    icon: Icons.warning_amber_outlined,
                    tone: StatusTone.attention,
                    text: flow.storageError!,
                  ),
                StatusNote(
                  icon: flow.api == null
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_done_outlined,
                  text: flow.syncStatus,
                ),
                if (pending.isNotEmpty) ...<Widget>[
                  const SectionHeading('Needs your decision'),
                  for (final Map<String, dynamic> item in pending)
                    _recommendationCard(theme, item),
                ],
                const SectionHeading('Recent activity'),
                if (recent.isEmpty)
                  const TesseractCard(
                    child: Text(
                        'No activities recorded yet. Once a session is played it '
                        'will appear here.'),
                  )
                else
                  for (final ActivityRecord record in recent)
                    _activityRow(theme, record),
                const SectionHeading('Set up'),
                if (flow.api != null)
                  OutlinedButton.icon(
                      onPressed: _busy ? null : _selectPatient,
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Choose or create a patient')),
                _navCard(
                  icon: Icons.badge_outlined,
                  title: 'Patient basics',
                  subtitle: 'Name, age, language',
                  screen: () => PatientBasicsScreen(flowState: flow),
                ),
                _navCard(
                  icon: Icons.favorite_border,
                  title: 'Know Me',
                  subtitle:
                      '${flow.knowMePeoplePlaces.length} people and places, '
                      '${flow.knowMeWords.length} familiar words',
                  screen: () => KnowMeScreen(flowState: flow),
                ),
                _navCard(
                  icon: Icons.notifications_outlined,
                  title: 'Reminders',
                  subtitle: flow.reminders.isEmpty
                      ? 'None set up'
                      : '${flow.reminders.where((ReminderItem r) => r.enabled).length} '
                          'of ${flow.reminders.length} switched on',
                  screen: () => RemindersScreen(flowState: flow),
                ),
                _navCard(
                  icon: Icons.settings_outlined,
                  title: 'Settings & sync',
                  subtitle: 'Text size, sound, sign out',
                  screen: () => SettingsScreen(flowState: flow),
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: 'Hand over to patient',
                  icon: Icons.smartphone,
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => HandOverScreen(flowState: flow),
                    ));
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              flow.caregiverName.isEmpty
                  ? 'Welcome back'
                  : 'Hello, ${flow.caregiverName}',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: TesseractDesign.inkSoft),
            ),
            const SizedBox(height: 2),
            Text(
              flow.patientName.isEmpty
                  ? 'No patient set up yet'
                  : flow.patientName,
              style: theme.textTheme.headlineMedium,
            ),
          ],
        ),
      );

  /// A proposal is explained in the caregiver's own terms, and every route out
  /// of it is offered with equal weight — approving is not the default path.
  Widget _recommendationCard(ThemeData theme, Map<String, dynamic> item) {
    final Map<String, dynamic> reason =
        (item['reason'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> proposed =
        (item['proposed_config'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> current =
        (item['current_config'] as Map).cast<String, dynamic>();
    final String gameId = proposed['game_id'] as String? ?? '';

    return TesseractCard(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.lightbulb_outline, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text('A suggested change',
                    style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            // Spelled out rather than using an arrow glyph: the caregiver may
            // be at a large text size, and a screen reader reads words.
            '${HostStrings.gameName(gameId)}: from level '
            '${current['level']} to level ${proposed['level']}',
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            reason['summary'] as String? ??
                'Based on recent recorded sessions.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          // The thresholds behind this are unreviewed prototype settings. Say
          // so here rather than letting the card imply clinical authority.
          if (reason['thresholds_status'] == 'prototype_unreviewed')
            const StatusNote(
              icon: Icons.info_outline,
              text: 'This is a suggestion from recorded activity only, using '
                  'settings that are still being tested. You decide.',
            ),
          const SizedBox(height: 6),
          PillButton(
            label: 'Use level ${proposed['level']}',
            icon: Icons.check,
            onPressed: _busy ? null : () => _decide(item, 'accept'),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _chooseDifferentLevel(item),
                  child: const Text('Choose level'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _decide(item, 'reject'),
                  child: const Text('Keep as is'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityRow(ThemeData theme, ActivityRecord record) {
    final String when = _friendlyDate(record.completedAt);
    // Status is spelled out, never conveyed by colour alone.
    final String outcome = switch (record.status) {
      'completed' => 'Finished',
      'stopped_by_user' => 'Stopped early',
      'interrupted' => 'Interrupted',
      _ => record.status,
    };
    return TesseractCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: <Widget>[
          const Icon(Icons.event_available_outlined, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(HostStrings.displayName(record.displayNameKey),
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('$outcome · $when',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: TesseractDesign.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget Function() screen,
  }) =>
      TesseractCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        onTap: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => screen()));
          if (mounted) {
            setState(() {});
          }
        },
        child: Row(
          children: <Widget>[
            Icon(icon, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: TesseractDesign.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 24),
          ],
        ),
      );

  String _friendlyDate(DateTime when) {
    final DateTime local = when.toLocal();
    final DateTime today = DateTime.now();
    final DateTime day = DateTime(local.year, local.month, local.day);
    final DateTime todayDay = DateTime(today.year, today.month, today.day);
    final int difference = todayDay.difference(day).inDays;
    final String time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return switch (difference) {
      0 => 'Today at $time',
      1 => 'Yesterday at $time',
      _ => '${local.day}/${local.month} at $time',
    };
  }
}
