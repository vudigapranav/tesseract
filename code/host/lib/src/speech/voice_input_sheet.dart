/// The tap-to-speak sheet.
///
/// One listen, started by a tap, with the microphone state stated in words the
/// whole time. Nothing leaves this sheet without the user pressing "Use this"
/// — the sheet returns the confirmed text to its caller and the caller does
/// the saving, so there is exactly one place where a spoken word can turn into
/// a stored one and it is behind an explicit press.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design_system.dart';
import '../l10n/language_catalogue.dart';
import 'speech_engine.dart';
import 'voice_input_service.dart';

/// Opens the sheet and resolves with the confirmed text, or null if the user
/// cancelled, discarded, or speech did not work.
Future<String?> showVoiceInputSheet({
  required BuildContext context,
  required SttEngine engine,
  required String languageCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => VoiceInputSheet(
      controller: VoiceInputController(engine: engine),
      languageCode: languageCode,
    ),
  );
}

class VoiceInputSheet extends StatefulWidget {
  const VoiceInputSheet({
    super.key,
    required this.controller,
    required this.languageCode,
  });

  final VoiceInputController controller;
  final String languageCode;

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // The sheet only ever opens from a tap on a microphone control, so
    // starting here is still an explicit, user-initiated listen. Nothing
    // listens before this point.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.start(widget.languageCode);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    widget.controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String _failureText(AppLocalizations l10n, VoiceInputFailure f) {
    switch (f) {
      case VoiceInputFailure.permissionDenied:
        return l10n.voicePermissionDenied;
      case VoiceInputFailure.permissionPermanentlyDenied:
        return l10n.voicePermissionBlocked;
      case VoiceInputFailure.recognitionUnavailable:
        return l10n.voiceUnavailable;
      case VoiceInputFailure.languageUnavailable:
        // Named, so it is obvious this is a gap in this language rather than
        // a fault the user caused — and so nobody assumes the app quietly
        // listened in English instead.
        return l10n.voiceLanguageUnavailable(
            LanguageCatalogue.byCode(widget.languageCode).endonym);
      case VoiceInputFailure.timeout:
        return l10n.voiceNothingHeard;
      case VoiceInputFailure.network:
        return l10n.voiceNetworkNeeded;
      case VoiceInputFailure.cancelled:
      case VoiceInputFailure.engineError:
        return l10n.voiceError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n =
        lookupAppLocalizations(Locale(widget.languageCode));
    final ThemeData theme = Theme.of(context);
    final VoiceInputController c = widget.controller;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TesseractDesign.cardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _body(l10n, theme, c),
        ),
      ),
    );
  }

  List<Widget> _body(
      AppLocalizations l10n, ThemeData theme, VoiceInputController c) {
    switch (c.phase) {
      case VoicePhase.requestingPermission:
      case VoicePhase.listening:
        final bool listening = c.phase == VoicePhase.listening;
        return <Widget>[
          // The indicator is an icon *and* a sentence: a person who cannot
          // interpret a pulsing dot still knows the microphone is open.
          Semantics(
            liveRegion: true,
            child: Row(
              children: <Widget>[
                Icon(listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 32, color: TesseractDesign.coral),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(listening ? l10n.listening : l10n.tapToSpeak,
                      style: theme.textTheme.titleLarge),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.listeningHint,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: TesseractDesign.inkSoft)),
          const SizedBox(height: 20),
          PillButton(
            label: l10n.cancelListening,
            icon: Icons.close_rounded,
            onPressed: () async {
              await c.cancel();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ];

      case VoicePhase.awaitingConfirmation:
        return <Widget>[
          Text(l10n.youSaid, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          // Shown before anything happens with it. This screen is the whole
          // point of the feature's safety story.
          Text(c.transcript, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          StatusNote(
              icon: Icons.lock_outline_rounded,
              text: l10n.voiceNeedsConfirmation),
          const SizedBox(height: 12),
          PillButton(
            label: l10n.useThis,
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(c.confirm()),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.tryAgain),
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 56)),
            onPressed: () {
              c.discard();
              c.start(widget.languageCode);
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              c.discard();
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancelListening),
          ),
        ];

      case VoicePhase.failed:
      case VoicePhase.idle:
        final VoiceInputFailure f = c.failure ?? VoiceInputFailure.engineError;
        final bool retryable = f != VoiceInputFailure.recognitionUnavailable &&
            f != VoiceInputFailure.languageUnavailable &&
            f != VoiceInputFailure.permissionPermanentlyDenied;
        return <Widget>[
          StatusNote(
              icon: Icons.mic_off_rounded,
              tone: StatusTone.attention,
              text: _failureText(l10n, f)),
          const SizedBox(height: 16),
          if (retryable)
            PillButton(
              label: l10n.tryAgain,
              icon: Icons.refresh_rounded,
              onPressed: () => c.start(widget.languageCode),
            ),
          const SizedBox(height: 8),
          // Always present. Whatever went wrong with speech, the typing and
          // touch path the user already had is still there.
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 56)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ];
    }
  }
}
