import 'package:flutter/material.dart';

import '../data/doctor_service.dart';
import '../design_system.dart';
import '../host_flow_state.dart';
import 'doctor_patient_detail_screen.dart';

/// D1/D2: the doctor's caseload.
///
/// Only patients the backend says this doctor is assigned to appear. There is
/// no client-side filtering to bypass: an unassigned patient is refused by the
/// server, including by direct id.
class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  List<Map<String, dynamic>>? _patients;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final DoctorService? service = widget.flowState.doctorService;
    if (service == null) {
      setState(() {
        _loading = false;
        _error = 'Not connected. Sign in to see your patients.';
      });
      return;
    }
    try {
      final List<Map<String, dynamic>> items = await service.assignedPatients();
      if (!mounted) {
        return;
      }
      setState(() {
        _patients = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Could not load your patients. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  TesseractDesign.gutter, 16, TesseractDesign.gutter, 32),
              children: <Widget>[
                Text('My patients', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Patients assigned to you.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: TesseractDesign.inkSoft),
                ),
                const SizedBox(height: 20),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                if (_error != null)
                  StatusNote(
                    icon: Icons.error_outline,
                    tone: StatusTone.attention,
                    text: _error!,
                  ),
                if (!_loading && _error == null && (_patients?.isEmpty ?? true))
                  const TesseractCard(
                    child: Text(
                      'No patients are assigned to you yet. Assignment is done '
                      'on the server, not from this app.',
                    ),
                  ),
                for (final Map<String, dynamic> patient
                    in _patients ?? const <Map<String, dynamic>>[])
                  TesseractCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DoctorPatientDetailScreen(
                          flowState: widget.flowState,
                          patientId: patient['patient_id'] as String,
                          displayName:
                              patient['display_name'] as String? ?? 'Patient',
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.person_outline, size: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                patient['display_name'] as String? ?? 'Patient',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Language: ${patient['language'] ?? 'unknown'}',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: TesseractDesign.inkSoft),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 24),
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
}
