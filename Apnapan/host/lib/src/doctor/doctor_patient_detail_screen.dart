import 'package:flutter/material.dart';

import '../data/doctor_service.dart';
import '../design_system.dart';
import '../host_flow_state.dart';
import '../host_strings.dart';

/// D3-D8 for one assigned patient: overview, session history, observed
/// measures, a generated draft report and attributed notes.
///
/// Everything shown is computed by the backend. This screen does not derive
/// any measure of its own, so the doctor and the caregiver can never be shown
/// different numbers for the same sessions.
///
/// It shows **observed application-performance signals**, never a cognitive
/// score, diagnosis or progression claim — and where the backend says a metric
/// is unavailable, it says "not measured" rather than showing zero.
class DoctorPatientDetailScreen extends StatefulWidget {
  const DoctorPatientDetailScreen({
    super.key,
    required this.flowState,
    required this.patientId,
    required this.displayName,
  });

  final HostFlowState flowState;
  final String patientId;
  final String displayName;

  @override
  State<DoctorPatientDetailScreen> createState() =>
      _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _sessions = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _notes = const <Map<String, dynamic>>[];
  Map<String, dynamic>? _report;

  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _windowDays = 30;

  DoctorService? get _service => widget.flowState.doctorService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final DoctorService? service = _service;
    if (service == null) {
      setState(() {
        _loading = false;
        _error = 'Not connected.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> summary =
          await service.summary(widget.patientId, windowDays: _windowDays);
      final List<Map<String, dynamic>> sessions =
          await service.sessions(widget.patientId);
      final List<Map<String, dynamic>> notes =
          await service.notes(widget.patientId);
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _sessions = sessions;
        _notes = notes;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Could not load this patient. $error';
      });
    }
  }

  Future<void> _generateReport() async {
    final DoctorService? service = _service;
    if (service == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final Map<String, dynamic> report =
          await service.createReport(widget.patientId, windowDays: _windowDays);
      if (!mounted) {
        return;
      }
      setState(() => _report = report);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate a draft. $error')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addNote() async {
    final TextEditingController controller = TextEditingController();
    final String? body = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Add a note'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Your note is recorded against your name.'),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (body == null || body.isEmpty || _service == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _service!.addNote(widget.patientId, body);
      final List<Map<String, dynamic>> notes =
          await _service!.notes(widget.patientId);
      if (mounted) {
        setState(() => _notes = notes);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save the note. $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<dynamic> games =
        (_summary?['games'] as List?) ?? const <dynamic>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  TesseractDesign.gutter, 8, TesseractDesign.gutter, 32),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                Text(widget.displayName, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                if (_loading || _busy)
                  const LinearProgressIndicator(minHeight: 2),
                if (_error != null)
                  StatusNote(
                    icon: Icons.error_outline,
                    tone: StatusTone.attention,
                    text: _error!,
                  ),

                // The one framing sentence that keeps this screen honest.
                const StatusNote(
                  icon: Icons.info_outline,
                  text: 'Observed activity in the app. Not a cognitive score, '
                      'diagnosis, or measure of disease progression.',
                ),

                _windowSelector(theme),

                const SectionHeading('Observed measures'),
                if (games.isEmpty && !_loading)
                  const TesseractCard(
                    child: Text('No completed sessions in this window.'),
                  ),
                for (final dynamic game in games)
                  _gameCard(theme, game as Map<String, dynamic>),

                const SectionHeading('Session history'),
                if (_sessions.isEmpty && !_loading)
                  const TesseractCard(child: Text('No sessions recorded yet.')),
                for (final Map<String, dynamic> session in _sessions.take(12))
                  _sessionRow(theme, session),

                SectionHeading(
                  'Draft report',
                  trailing: TextButton(
                    onPressed: _busy ? null : _generateReport,
                    child: const Text('Generate'),
                  ),
                ),
                if (_report != null) _reportCard(theme, _report!),

                SectionHeading(
                  'Notes',
                  trailing: TextButton(
                    onPressed: _busy ? null : _addNote,
                    child: const Text('Add'),
                  ),
                ),
                if (_notes.isEmpty)
                  const TesseractCard(child: Text('No notes yet.')),
                for (final Map<String, dynamic> note in _notes)
                  TesseractCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(note['body'] as String? ?? '',
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Recorded ${_shortDate(note['created_at'] as String?)}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: TesseractDesign.inkSoft),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _windowSelector(ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: <Widget>[
            Text('Window:', style: theme.textTheme.bodyLarge),
            const SizedBox(width: 12),
            for (final int days in <int>[7, 30])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$days days'),
                  selected: _windowDays == days,
                  onSelected: (_) {
                    setState(() => _windowDays = days);
                    _load();
                  },
                ),
              ),
          ],
        ),
      );

  /// Per-game observations, including how many sessions were actually
  /// comparable and why others were set aside. Sample counts are shown
  /// because a median of three sessions is not the same claim as a median of
  /// thirty.
  Widget _gameCard(ThemeData theme, Map<String, dynamic> game) {
    final Map<String, dynamic> baseline =
        (game['baseline'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> values =
        (baseline['values'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> excluded =
        (game['excluded'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    final Set<String> unavailable = <String>{
      for (final dynamic session
          in (game['recent_sessions'] as List? ?? const <dynamic>[]))
        ...((session as Map)['unavailable_metrics'] as Map?)
                ?.keys
                .cast<String>() ??
            const <String>[],
    };

    return TesseractCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(HostStrings.gameName(game['game_id'] as String? ?? ''),
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '${game['sessions_total'] ?? 0} sessions, '
            '${game['sessions_comparable'] ?? 0} directly comparable',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: TesseractDesign.inkSoft),
          ),
          const SizedBox(height: 10),
          if (baseline['state'] == 'established')
            for (final MapEntry<String, dynamic> entry in values.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${_pretty(entry.key)}: ${_round(entry.value)}',
                    style: theme.textTheme.bodyLarge),
              )
          else
            Text(
              'Not enough comparable sessions yet for a reference.',
              style: theme.textTheme.bodyLarge,
            ),
          if (excluded.values.any((dynamic v) => (v as int) > 0)) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Set aside: ${excluded.entries.where((e) => (e.value as int) > 0).map((e) => '${e.value} ${_pretty(e.key)}').join(', ')}.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: TesseractDesign.inkSoft),
            ),
          ],
          if (unavailable.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            // Never shown as zero. The game does not export what these need.
            StatusNote(
              icon: Icons.remove_circle_outline,
              text: 'Not measured: ${unavailable.map(_pretty).join(', ')}.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _sessionRow(ThemeData theme, Map<String, dynamic> session) {
    final String outcome = switch (session['status'] as String?) {
      'completed' => 'Finished',
      'stopped_by_user' => 'Stopped early',
      'interrupted' => 'Interrupted',
      _ => '${session['status']}',
    };
    final List<String> flags = <String>[
      if (session['is_tutorial'] == true) 'tutorial',
      if (session['assisted'] == true) 'assisted',
      if (session['input_mode_unverified'] == true) 'input mode unverified',
    ];
    return TesseractCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${HostStrings.gameName(session['game_id'] as String? ?? '')} '
            '· level ${session['level']}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          Text(
            '$outcome · ${_shortDate(session['completed_at'] as String? ?? session['created_at'] as String?)}'
            '${flags.isEmpty ? '' : ' · ${flags.join(', ')}'}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: TesseractDesign.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(ThemeData theme, Map<String, dynamic> report) {
    final Map<String, dynamic> content =
        (report['content'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final List<dynamic> limitations =
        (content['limitations'] as List?) ?? const <dynamic>[];
    return TesseractCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(content['narrative'] as String? ?? '',
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          // Provenance, always: who wrote it and what it is based on.
          Text(
            'Draft · written by ${report['generator'] == 'llm' ? 'a language model, from computed figures' : 'template'} '
            '· ${(report['source_session_ids'] as List?)?.length ?? 0} source sessions',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: TesseractDesign.inkSoft),
          ),
          const SizedBox(height: 10),
          for (final dynamic limitation in limitations)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $limitation',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: TesseractDesign.inkSoft)),
            ),
        ],
      ),
    );
  }

  String _pretty(String key) => key.replaceAll('_', ' ');

  String _round(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }
    return '$value';
  }

  String _shortDate(String? iso) {
    if (iso == null) {
      return 'unknown date';
    }
    final DateTime? when = DateTime.tryParse(iso);
    if (when == null) {
      return iso;
    }
    final DateTime local = when.toLocal();
    return '${local.day}/${local.month} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
