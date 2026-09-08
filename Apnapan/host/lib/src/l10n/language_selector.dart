import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design_system.dart';
import 'language_catalogue.dart';

/// Picks a language.
///
/// Every option shows its own name in its own script, so someone who does not
/// read English can still find theirs. Draft languages say so on the option
/// itself, with their measured coverage — a caregiver should never discover
/// after choosing that half the app is still in English.
///
/// Usable before sign-in: it needs nothing but the callback.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.selectedCode,
    required this.onSelected,
    this.title,
    this.subtitle,
  });

  final String selectedCode;
  final ValueChanged<String> onSelected;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title ?? l10n.chooseLanguage, style: theme.textTheme.titleLarge),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: TesseractDesign.inkSoft)),
        ],
        const SizedBox(height: 12),
        for (final LanguageOption option in LanguageCatalogue.all)
          _option(context, theme, l10n, option),
      ],
    );
  }

  Widget _option(BuildContext context, ThemeData theme, AppLocalizations l10n,
      LanguageOption option) {
    final bool selected = option.code == selectedCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        // Screen readers announce the English name too, so the option is
        // identifiable even when the endonym's script is not spoken.
        label: '${option.endonym}, ${option.englishName}'
            '${option.isDraft ? '. ${l10n.draftTranslationNotice}' : ''}',
        child: Material(
          color: selected ? TesseractDesign.peach : Colors.white,
          borderRadius: BorderRadius.circular(TesseractDesign.cardRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(TesseractDesign.cardRadius),
            onTap: () => onSelected(option.code),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: <Widget>[
                  // Selection is shown by a check icon and a filled ground,
                  // never colour alone.
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(option.endonym, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          option.region == null
                              ? option.englishName
                              : '${option.englishName} · ${option.region}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: TesseractDesign.inkSoft),
                        ),
                        if (option.isDraft) ...<Widget>[
                          const SizedBox(height: 6),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.edit_note, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${l10n.translationCoverage(option.coveragePercent)} · '
                                  '${l10n.awaitingReview}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF8A4B1F)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The standing notice shown while a draft language is in use.
///
/// Deliberately persistent rather than a one-time dialog: an untranslated
/// screen must never read as finished, and the person seeing English text in
/// a Mizo interface deserves to know why.
class DraftLanguageBanner extends StatelessWidget {
  const DraftLanguageBanner({super.key, required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final LanguageOption option = LanguageCatalogue.byCode(languageCode);
    if (!option.isDraft) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: StatusNote(
        icon: Icons.translate,
        tone: StatusTone.attention,
        text: '${l10n.draftTranslationNotice} '
            '${l10n.translationCoverage(option.coveragePercent)}. '
            '${l10n.fallsBackToEnglish}',
      ),
    );
  }
}
