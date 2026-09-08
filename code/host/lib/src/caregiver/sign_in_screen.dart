import 'package:flutter/material.dart';

import '../data/identity_service.dart';
import '../design_system.dart';
import '../doctor/doctor_patients_screen.dart';
import '../host_flow_state.dart';
import 'caregiver_home_screen.dart';

/// C1 / D1 sign in.
///
/// One screen, two roles. A caregiver sets up and hands the device to the
/// patient; a doctor signs in to read the patients assigned to them. The
/// patient never signs in themselves — the caregiver hands over, which is why
/// there is no patient option here.
///
/// The role chosen here only decides which screen opens. It grants nothing:
/// the backend decides what an identity can actually see, and a caregiver
/// choosing "Doctor" simply gets an empty, refused caseload.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.flowState});
  final HostFlowState flowState;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool busy = false;
  String? error;
  String role = 'caregiver';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      widget.flowState.role = role;
      await widget.flowState.identity.signIn(email.text.trim(), password.text);
      await widget.flowState.connect();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => role == 'doctor'
            ? DoctorPatientsScreen(flowState: widget.flowState)
            : CaregiverHomeScreen(flowState: widget.flowState),
      ));
    } catch (_) {
      if (mounted) {
        // Never fall through to any offline or synthetic access on a failed
        // real sign-in: a refused identity must stay refused.
        setState(() => error =
            'Could not verify sign-in and access. Check your details and connection.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  /// Development fixture only, behind a build flag. Visibly labelled
  /// everywhere it leads, and never reachable from a failed real sign-in.
  Future<void> preview() async {
    widget.flowState.synthetic = true;
    widget.flowState.role = role;
    widget.flowState.caregiverName = 'Synthetic caregiver';
    await widget.flowState.save();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => CaregiverHomeScreen(flowState: widget.flowState)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: <Widget>[
              const Center(child: ActivityIllustration()),
              const SizedBox(height: 8),
              Text('A familiar moment.\nA little joy.',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'Set up meaningful activities and everyday reminders, together.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: TesseractDesign.inkSoft),
              ),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                      value: 'caregiver',
                      label: Text('Caregiver'),
                      icon: Icon(Icons.favorite_border)),
                  ButtonSegment<String>(
                      value: 'doctor',
                      label: Text('Doctor'),
                      icon: Icon(Icons.medical_information_outlined)),
                ],
                selected: <String>{role},
                onSelectionChanged: (Set<String> value) =>
                    setState(() => role = value.first),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.username],
                decoration: InputDecoration(
                    labelText:
                        role == 'doctor' ? 'Doctor email' : 'Caregiver email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: const <String>[AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: StatusNote(
                    icon: Icons.error_outline,
                    tone: StatusTone.attention,
                    text: error!,
                  ),
                ),
              const SizedBox(height: 24),
              PillButton(
                label: busy ? 'Verifying access…' : 'Sign in',
                onPressed: busy || !IdentityService.configured ? null : signIn,
              ),
              if (!IdentityService.configured)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: StatusNote(
                    icon: Icons.info_outline,
                    tone: StatusTone.attention,
                    text: 'Sign-in is not configured in this build. It needs a '
                        'Firebase project and a backend address, which are '
                        'supplied at build time. Nothing is signed in until '
                        'then — there is no offline substitute.',
                  ),
                ),
              if (const bool.fromEnvironment('TESSERACT_ALLOW_PREVIEW'))
                TextButton(
                  onPressed: busy ? null : preview,
                  child: const Text('Open synthetic development preview'),
                ),
              const SizedBox(height: 8),
              Text(
                'The person using the activities does not sign in. A caregiver '
                'sets things up and hands the device over.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: TesseractDesign.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
