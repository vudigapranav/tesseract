import 'package:flutter/material.dart';

import '../host_flow_state.dart';
import 'caregiver_home_screen.dart';

/// C1 Sign In: authenticate the caregiver and resolve assigned patient
/// membership.
///
/// Placeholder only — no identity provider or backend exists yet. This just
/// records a display name and flips [HostFlowState.caregiverSignedIn]. Real
/// sign-in needs loading/invalid-login/offline/expired-session states this
/// skeleton does not attempt.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _signIn() {
    widget.flowState.caregiverSignedIn = true;
    widget.flowState.caregiverName = _nameController.text.trim().isEmpty
        ? 'Caregiver'
        : _nameController.text.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CaregiverHomeScreen(flowState: widget.flowState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Tesseract',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Caregiver sign in',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Your name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                    labelText: 'Password (placeholder)',
                    border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                    onPressed: _signIn, child: const Text('Sign in')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
