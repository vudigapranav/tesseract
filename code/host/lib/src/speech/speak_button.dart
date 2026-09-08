/// The control that reads the text on a screen aloud.
///
/// Deliberately a plain, labelled button rather than an icon alone: the people
/// using patient mode should not have to know what a speaker glyph means. It
/// says "Read aloud", it says "Stop" while speaking, and when the language has
/// no voice it says so in words instead of quietly doing nothing.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design_system.dart';
import '../l10n/language_catalogue.dart';
import 'speech_output_service.dart';

class SpeakButton extends StatefulWidget {
  const SpeakButton({
    super.key,
    required this.service,
    required this.text,
    required this.languageCode,
    this.compact = false,
  });

  final SpeechOutputService service;

  /// Exactly the words already visible on screen. Speech never says anything
  /// the user cannot also read.
  final String text;

  /// The patient's language. Never coerced to a language the engine happens
  /// to have.
  final String languageCode;

  /// Smaller presentation for a list row, still above the touch-target floor.
  final bool compact;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  SpeechAvailability? _availability;
  bool _busy = false;
  bool _hasPlayedOnce = false;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
    _refreshAvailability();
  }

  @override
  void didUpdateWidget(SpeakButton old) {
    super.didUpdateWidget(old);
    if (old.languageCode != widget.languageCode) {
      _hasPlayedOnce = false;
      _refreshAvailability();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshAvailability() async {
    final SpeechAvailability a =
        await widget.service.availability(widget.languageCode);
    if (mounted) setState(() => _availability = a);
  }

  Future<void> _onPressed() async {
    if (_busy) return;
    if (widget.service.isSpeaking) {
      await widget.service.stop();
      return;
    }
    setState(() => _busy = true);
    final SpeechAvailability a = await widget.service
        .speak(widget.text, languageCode: widget.languageCode);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _availability = a;
      if (a.isAvailable) _hasPlayedOnce = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n =
        lookupAppLocalizations(Locale(widget.languageCode));
    final SpeechAvailability? a = _availability;

    // Still probing. Nothing is drawn rather than a control that might be
    // about to disappear — a button that vanishes under a finger is worse
    // than one that arrives a moment late.
    if (a == null) return const SizedBox.shrink();

    if (!a.isAvailable) {
      return StatusNote(
        icon: Icons.volume_off_outlined,
        text: switch (a.reason!) {
          SpeechUnavailableReason.audioOff => l10n.speechAudioOff,
          SpeechUnavailableReason.noEngine => l10n.speechNoEngine,
          SpeechUnavailableReason.noVoiceForLanguage =>
            l10n.speechUnavailableForLanguage(
                LanguageCatalogue.byCode(widget.languageCode).endonym),
          SpeechUnavailableReason.engineError => l10n.speechFailed,
        },
      );
    }

    final bool speaking = widget.service.isSpeaking;
    final String label = speaking
        ? l10n.stopSpeaking
        : (_hasPlayedOnce ? l10n.readAloudAgain : l10n.speakThis);

    return Semantics(
      button: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton.icon(
          onPressed: _busy && !speaking ? null : _onPressed,
          icon: Icon(speaking
              ? Icons.stop_rounded
              : (_hasPlayedOnce
                  ? Icons.replay_rounded
                  : Icons.volume_up_rounded)),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(widget.compact ? 64 : double.infinity,
                widget.compact ? 48 : TesseractDesign.patientTarget),
            foregroundColor: TesseractDesign.ink,
            side: const BorderSide(color: TesseractDesign.ink, width: 1.5),
            shape: const StadiumBorder(),
          ),
        ),
      ),
    );
  }
}
