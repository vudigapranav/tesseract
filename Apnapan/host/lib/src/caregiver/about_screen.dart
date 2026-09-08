import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';
import '../design_system.dart';
import '../l10n/language_catalogue.dart';

/// Settings → About Tesseract.
///
/// Deliberately contains no team-member names, contact details, affiliations
/// or clinical claims: none of those are established anywhere in the project
/// records, and the attribution line is the exact wording that was asked for.
///
/// The version and build number are read from the installed package metadata
/// rather than typed in, so they cannot drift from the artefact a judge is
/// actually holding.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _info;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Bounded: a spinner that never resolves is worse than an honest dash.
      final PackageInfo info =
          await PackageInfo.fromPlatform().timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _info = info);
      }
    } catch (_) {
      // Platform metadata is unavailable in some contexts (a widget test, a
      // web preview). Say nothing rather than invent a version number.
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TesseractBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                TesseractDesign.gutter, 8, TesseractDesign.gutter, 32),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    tooltip: l10n.goBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // No approved logo exists in the project records, so this uses
              // the app's own activity mark rather than inventing branding.
              const Center(child: ActivityIllustration()),
              const SizedBox(height: 20),

              Center(
                child:
                    Text(l10n.appName, style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 16),

              TesseractCard(
                child: Text(l10n.aboutDescription,
                    style: theme.textTheme.bodyLarge),
              ),

              TesseractCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l10n.builtBy, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (_info != null)
                      Text(
                        l10n.versionLabel(_info!.version, _info!.buildNumber),
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: TesseractDesign.inkSoft),
                      )
                    else if (_failed)
                      Text(
                        '—',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: TesseractDesign.inkSoft),
                      )
                    else
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              const SectionHeading('Languages'),
              TesseractCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final LanguageOption option in LanguageCatalogue.all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${option.endonym} · ${option.englishName}',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              option.isDraft
                                  ? '${option.coveragePercent}% · ${l10n.awaitingReview}'
                                  : '100%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: option.isDraft
                                    ? const Color(0xFF8A4B1F)
                                    : TesseractDesign.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(l10n.fallsBackToEnglish,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: TesseractDesign.inkSoft)),
                    const SizedBox(height: 10),
                    // The scope gap, stated rather than hidden.
                    StatusNote(
                      icon: Icons.info_outline,
                      text: 'No language is included yet for '
                          '${LanguageCatalogue.uncoveredRegions.join(', ')}.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
