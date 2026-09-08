import 'package:flutter/material.dart';
import '../host_flow_state.dart';
import '../data/identity_service.dart';
import '../design_system.dart';
import 'caregiver_home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.flowState});
  final HostFlowState flowState;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
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
      await widget.flowState.identity.signIn(email.text.trim(), password.text);
      await widget.flowState.connect();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => CaregiverHomeScreen(flowState: widget.flowState)));
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Could not verify sign-in and caregiver access. Check your details and connection.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> preview() async {
    widget.flowState.synthetic = true;
    widget.flowState.caregiverName = 'Synthetic caregiver';
    await widget.flowState.save();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => CaregiverHomeScreen(flowState: widget.flowState)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TesseractDesign.cream, TesseractDesign.peach])),
          child: SafeArea(
              child: ListView(padding: const EdgeInsets.all(28), children: [
            const Center(child: ActivityIllustration()),
            Text('A familiar moment.\nA little joy.',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text(
                'Welcome to Tesseract. Set up meaningful activities and everyday reminders, together.'),
            const SizedBox(height: 28),
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration:
                    const InputDecoration(labelText: 'Caregiver email')),
            const SizedBox(height: 16),
            TextField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password')),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(error!, semanticsLabel: error)),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: busy || !IdentityService.configured ? null : signIn,
                child: Text(busy ? 'Verifying access…' : 'Sign in')),
            if (!IdentityService.configured)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                      'Real sign-in is not configured in this build. Public Firebase project and backend configuration are required.')),
            if (const bool.fromEnvironment('TESSERACT_ALLOW_PREVIEW'))
              TextButton(
                  onPressed: busy ? null : preview,
                  child: const Text('Open synthetic development preview')),
          ]))));
}
