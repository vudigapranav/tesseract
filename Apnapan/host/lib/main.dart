import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'src/l10n/language_catalogue.dart';
import 'src/caregiver/sign_in_screen.dart';
import 'src/host_flow_state.dart';
import 'src/home_screen.dart';
import 'src/design_system.dart';
import 'src/data/local_repository.dart';
import 'src/patient_reminders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final repository = kIsWeb ? null : await LocalRepository.open();
    // Reopen the partition belonging to whoever was signed in last. Until a
    // caregiver signs in, this stays on the anonymous scope and no patient
    // content is readable.
    final String? activeScope = await repository?.readActiveScope();
    if (repository != null && activeScope != null) {
      await repository.useScope(activeScope);
    }
    final flow = HostFlowState(repository: repository);
    await flow.restore();
    try {
      await flow.reminderService.restore(flow.reminders,
          sound: flow.audioEnabled,
          languageCode: flow.effectivePatientLanguageCode);
    } catch (_) {
      flow.reminderService.status =
          'Notification scheduling unavailable. Your reminders are saved.';
    }
    runApp(HostApp(flowState: flow));
  } catch (_) {
    runApp(MaterialApp(
        theme: TesseractDesign.theme,
        home: const Scaffold(
            body: SafeArea(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Your saved data could not be opened. Close and reopen the app. Existing data has not been reset.')))))));
  }
}

class HostApp extends StatefulWidget {
  const HostApp({super.key, this.flowState});
  final HostFlowState? flowState;
  @override
  State<HostApp> createState() => _HostAppState();
}

class _HostAppState extends State<HostApp> with WidgetsBindingObserver {
  late final flow = widget.flowState ?? HostFlowState();

  /// Lets a notification tap navigate without a BuildContext of its own.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Speech must not carry on out of a backgrounded app: it would talk over
    // whatever the person opened next, and a reminder read aloud after
    // handover could be overheard by someone the caregiver did not intend.
    WidgetsBinding.instance.addObserver(this);
    // Text size and reduced motion are applied by the MediaQuery below, so
    // the shell has to rebuild when the caregiver changes them.
    flow.addListener(_onDisplayPreferencesChanged);
    // Tapping a reminder should open the reminder view, not just whatever
    // screen the app happened to be showing.
    flow.reminderService.onReminderTapped = _openReminders;
  }

  void _openReminders(int reminderId) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => PatientRemindersScreen(flowState: flow),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      flow.stopSpeaking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    flow.stopSpeaking();
    flow.removeListener(_onDisplayPreferencesChanged);
    flow.reminderService.onReminderTapped = null;
    super.dispose();
  }

  void _onDisplayPreferencesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Tesseract',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: TesseractDesign.theme,
      // Changing this rebuilds the tree in place: the language switch is
      // immediate, and does not restart, sign out or drop a running session.
      locale: Locale(flow.interfaceLanguageCode),
      supportedLocales: LanguageCatalogue.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: flow.patientMode
          ? HomeScreen(flowState: flow)
          : SignInScreen(flowState: flow),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
            data: media.copyWith(
                textScaler: TextScaler.linear(
                    media.textScaler.scale(1) * flow.textScalePreference),
                disableAnimations:
                    media.disableAnimations || flow.reducedMotion),
            child: child ?? const SizedBox.shrink());
      });
}
