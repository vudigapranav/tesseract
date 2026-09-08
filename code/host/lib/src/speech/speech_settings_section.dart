/// "Speaking and listening" in caregiver Settings.
///
/// This is the honest answer to "does speech work in our language?". It does
/// not read a compiled-in table — it asks the engines installed on this phone
/// and reports exactly what they said, per language, in both directions.
///
/// Until the caregiver taps the check, every row says "not checked on this
/// phone yet", because that is the truth.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design_system.dart';
import '../host_flow_state.dart';
import '../l10n/language_catalogue.dart';
import 'speech_capability.dart';
import 'voice_input_service.dart';

class SpeechSettingsSection extends StatefulWidget {
  const SpeechSettingsSection({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<SpeechSettingsSection> createState() => _SpeechSettingsSectionState();
}

class _SpeechSettingsSectionState extends State<SpeechSettingsSection> {
  /// language code -> (can speak, can listen). Empty until a check is run.
  final Map<String, (bool, bool)> _results = <String, (bool, bool)>{};
  final Map<String, String?> _tags = <String, String?>{};
  bool _checking = false;
  bool _checked = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final HostFlowState flow = widget.flowState;
    final VoiceInputController probe = VoiceInputController(engine: flow.stt);
    try {
      for (final LanguageOption option in LanguageCatalogue.all) {
        // Output and input are asked separately. Support for one direction
        // has never implied the other, and on these languages it usually
        // does not.
        final SpeechProbe out = await flow.speech.probe(option.code);
        final SpeechProbe inp = await probe.probe(option.code);
        _results[option.code] = (out.available, inp.available);
        _tags[option.code] = out.resolvedTag ?? inp.resolvedTag;
      }
    } finally {
      // Only ever probed; this controller never listened, so there is nothing
      // recorded to discard.
      probe.dispose();
      if (mounted) {
        setState(() {
          _checking = false;
          _checked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 32),
        SectionHeading(l10n.speechSettingsTitle),
        Text(l10n.speechSettingsSubtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: TesseractDesign.inkSoft)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _checking ? null : _check,
          icon: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.speaker_notes_outlined),
          label: Text(l10n.speechCheckThisPhone),
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 56)),
        ),
        const SizedBox(height: 8),
        for (final LanguageOption option in LanguageCatalogue.all)
          _row(option, l10n, theme),
        const SizedBox(height: 8),
        // Applies to every row above, including any that came back available.
        // A working voice is not a good voice.
        StatusNote(
            icon: Icons.record_voice_over_outlined,
            text: l10n.speechDraftWarning),
      ],
    );
  }

  Widget _row(LanguageOption option, AppLocalizations l10n, ThemeData theme) {
    final (bool, bool)? r = _results[option.code];
    final String? tag = _tags[option.code];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${option.endonym} · ${option.englishName}',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          if (!_checked && r == null)
            Text(l10n.speechNotCheckedYet,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: TesseractDesign.inkSoft))
          else ...<Widget>[
            _line(
                r?.$1 ?? false,
                r?.$1 ?? false
                    ? l10n.speechReadAloudAvailable
                    : l10n.speechReadAloudUnavailable,
                theme),
            _line(
                r?.$2 ?? false,
                r?.$2 ?? false
                    ? l10n.speechListeningAvailable
                    : l10n.speechListeningUnavailable,
                theme),
            if (tag != null)
              Text(tag,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: TesseractDesign.inkSoft)),
          ],
        ],
      ),
    );
  }

  /// Icon and words both carry the state, so this reads correctly in
  /// greyscale and to a screen reader.
  Widget _line(bool ok, String text, ThemeData theme) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ok ? Icons.check_circle_outline : Icons.do_not_disturb_alt,
              size: 18, color: TesseractDesign.inkSoft),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: TesseractDesign.inkSoft))),
        ],
      );
}
