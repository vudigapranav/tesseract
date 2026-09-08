import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../design_system.dart';
import '../host_flow_state.dart';
import '../l10n/language_catalogue.dart';
import '../speech/speech_settings_section.dart';
import '../l10n/language_selector.dart';
import 'about_screen.dart';
import 'sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.flowState});
  final HostFlowState flowState;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> save() async {
    try {
      await widget.flowState.save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Settings could not be saved. Try again.')));
      }
    }
  }

  Future<void> signOut() async {
    // Persist this caregiver's data into their own partition first, then drop
    // the active-identity pointer so the next launch starts signed out
    // instead of reopening their patient's content. Their data is kept for
    // when they sign back in; it is not deleted.
    await save();
    await widget.flowState.identity.signOut();
    await widget.flowState.repository?.clearActiveScope();
    widget.flowState.caregiverSignedIn = false;
    widget.flowState.patientMode = false;
    widget.flowState.api = null;
    widget.flowState.outbox = null;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
            builder: (_) => SignInScreen(flowState: widget.flowState)),
        (_) => false);
  }

  /// Opens the picker for either the interface or the patient language.
  ///
  /// The two are deliberately separate: the caregiver and the person they
  /// care for may not read the same language.
  Future<void> _pickLanguage({required bool forPatient}) async {
    final flow = widget.flowState;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TesseractDesign.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LanguageSelector(
            title: forPatient ? l10n.patientLanguage : l10n.interfaceLanguage,
            subtitle: forPatient
                ? l10n.patientLanguageHelp
                : l10n.interfaceLanguageHelp,
            selectedCode: forPatient
                ? flow.effectivePatientLanguageCode
                : flow.interfaceLanguageCode,
            onSelected: (code) async {
              Navigator.of(sheetContext).pop();
              // Applies at once; does not restart, sign out or disturb a
              // running session.
              if (forPatient) {
                await flow.setPatientLanguage(code);
              } else {
                await flow.setInterfaceLanguage(code);
              }
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flowState;
    return Scaffold(
        appBar: AppBar(title: const Text('Settings & sync')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          DraftLanguageBanner(languageCode: flow.interfaceLanguageCode),
          ListTile(
              leading: const Icon(Icons.translate),
              title: Text(AppLocalizations.of(context).interfaceLanguage),
              subtitle: Text(
                  LanguageCatalogue.byCode(flow.interfaceLanguageCode).endonym),
              onTap: () => _pickLanguage(forPatient: false)),
          ListTile(
              leading: const Icon(Icons.record_voice_over_outlined),
              title: Text(AppLocalizations.of(context).patientLanguage),
              subtitle: Text(
                  LanguageCatalogue.byCode(flow.effectivePatientLanguageCode)
                      .endonym),
              onTap: () => _pickLanguage(forPatient: true)),
          const Divider(height: 32),
          SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text(
                  'Controls sounds for newly scheduled reminders and whether text can be read aloud. Turning this off stops speech immediately. Games have no audio playback of their own.'),
              value: flow.audioEnabled,
              onChanged: (v) async {
                // Goes through the flow state rather than setting the field,
                // so switching off also stops anything mid-sentence.
                await flow.setAudioEnabled(v);
                if (mounted) setState(() {});
              }),
          SwitchListTile(
              title: const Text('Reduce motion'),
              value: flow.reducedMotion,
              onChanged: (v) async {
                setState(() => flow.reducedMotion = v);
                flow.displayPreferencesChanged();
                await save();
              }),
          SpeechSettingsSection(flowState: flow),
          const ListTile(
              title: Text('Text size'),
              subtitle: Text(
                  'Applies straight away, on top of the Android text-size setting.')),
          Slider(
              value: flow.textScalePreference,
              min: 1,
              max: 2,
              divisions: 4,
              label: '${flow.textScalePreference}×',
              onChanged: (v) {
                setState(() => flow.textScalePreference = v);
                flow.displayPreferencesChanged();
              },
              onChangeEnd: (_) => save()),
          const ListTile(
              title: Text('Language'),
              subtitle:
                  Text('English. Regional translations await native review.')),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Synchronization'),
                        const SizedBox(height: 8),
                        Text(flow.synthetic
                            ? 'Synthetic development data • saved locally'
                            : flow.syncStatus),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: () async {
                              await flow.synchronize();
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            child: const Text('Sync now'))
                      ]))),
          FutureBuilder(
              future: flow.repository?.sessions(pendingOnly: true),
              builder: (context, snapshot) => ListTile(
                  title: const Text('Pending session uploads'),
                  subtitle: Text(
                      '${snapshot.data?.length ?? 0} retained on this device'))),
          const SizedBox(height: 12),
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(AppLocalizations.of(context).aboutTesseract),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const AboutScreen()))),
          const SizedBox(height: 24),
          OutlinedButton(
              onPressed: signOut,
              child: Text(AppLocalizations.of(context).signOut)),
        ])));
  }
}
