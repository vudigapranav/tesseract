import 'package:flutter/material.dart';

import '../host_flow_state.dart';
import 'know_me_screen.dart';

const List<String> _conditionOptions = <String>[
  "Alzheimer's",
  'Frontotemporal',
  'Lewy body',
  'Vascular',
  'Mixed/other',
  'Unknown',
];

/// C2 Patient Basics: name, age, optional photo, language and accessibility.
/// Known type/stage is optional clinical context, never inferred from games.
class PatientBasicsScreen extends StatefulWidget {
  const PatientBasicsScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<PatientBasicsScreen> createState() => _PatientBasicsScreenState();
}

class _PatientBasicsScreenState extends State<PatientBasicsScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.flowState.patientName);
  late final TextEditingController _ageController = TextEditingController(
      text: widget.flowState.patientAge?.toString() ?? '');
  String? _condition;

  @override
  void initState() {
    super.initState();
    _condition = widget.flowState.knownConditionType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _next() {
    widget.flowState.patientName = _nameController.text.trim();
    widget.flowState.patientAge = int.tryParse(_ageController.text.trim());
    widget.flowState.knownConditionType = _condition;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            KnowMeScreen(flowState: widget.flowState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient basics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Age (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(
                labelText: 'Known type/stage (optional)',
                border: OutlineInputBorder(),
                helperText:
                    'Optional clinical context — never inferred from gameplay.',
                helperMaxLines: 2,
              ),
              items: _conditionOptions
                  .map((String c) =>
                      DropdownMenuItem<String>(value: c, child: Text(c)))
                  .toList(),
              onChanged: (String? value) => setState(() => _condition = value),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child:
                  FilledButton(onPressed: _next, child: const Text('Continue')),
            ),
          ],
        ),
      ),
    );
  }
}
