import 'package:flutter/material.dart';

/// Design tokens.
///
/// Warm cream/peach ground, decorative coral, white rounded cards, black pill
/// actions. Coral is **decorative only**: it never carries meaning on its own
/// and is never used for body text, because a caregiver may be colour-blind
/// and a patient may have reduced contrast sensitivity. Anything meaningful
/// is also stated in words and usually an icon.
abstract final class TesseractDesign {
  static const cream = Color(0xFFFFF8EC);
  static const peach = Color(0xFFFFE2D4);
  static const coral = Color(0xFFF47F78);
  static const ink = Color(0xFF24211F);

  /// Muted ink for supporting text. Kept well above the 4.5:1 contrast floor
  /// on cream and on white.
  static const inkSoft = Color(0xFF5B5450);

  /// Page background wash used behind caregiver and patient screens.
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFFF3E2), cream],
  );

  static const gutter = 20.0;
  static const cardRadius = 24.0;

  /// Minimum patient-facing target. Above the 48dp guidance, because the
  /// people using patient mode may have tremor or low precision.
  static const patientTarget = 64.0;
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        // Named explicitly rather than left to the platform default. Roboto is
        // the Android system font, and button labels in particular resolve
        // their style outside textTheme, so without this they fall back to a
        // family the golden renderer has no glyphs for and draw as blocks.
        fontFamily: 'Roboto',
        // Bengali-Assamese and Meetei Mayek fall back to bundled Noto faces,
        // so those scripts render even on a device without system fonts for
        // them. Without this they would draw as empty boxes.
        fontFamilyFallback: const <String>[
          'NotoSansBengali',
          'NotoSansMeeteiMayek',
        ],
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
            seedColor: coral,
            primary: ink,
            onPrimary: Colors.white,
            surface: cream,
            onSurface: ink),
        textTheme: const TextTheme(
            headlineMedium: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.8),
            headlineSmall: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
            titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontSize: 18, height: 1.45),
            bodyMedium: TextStyle(fontSize: 16, height: 1.45)),
        appBarTheme: const AppBarTheme(
            backgroundColor: cream, foregroundColor: ink, centerTitle: false),
        cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24))),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                minimumSize: const Size(64, 56),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                // ThemeData.fontFamily reaches textTheme, not a raw TextStyle
                // inside a button theme, so the family is named again here.
                textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    // Bengali-Assamese and Meetei Mayek fall back to bundled Noto faces,
                    // so those scripts render even on a device without system fonts for
                    // them. Without this they would draw as empty boxes.
                    fontFamilyFallback: <String>[
                      'NotoSansBengali',
                      'NotoSansMeeteiMayek',
                    ],
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
                shape: const StadiumBorder())),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 56), foregroundColor: ink)),
        inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(18)),
      );
}

class ActivityIllustration extends StatelessWidget {
  const ActivityIllustration({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Tesseract: connected activities, at your pace',
      image: true,
      child: Container(
          height: 190,
          width: 220,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.white,
                TesseractDesign.peach,
                TesseractDesign.cream
              ])),
          child: const Stack(alignment: Alignment.center, children: [
            Icon(Icons.view_in_ar_outlined,
                size: 110, color: TesseractDesign.ink),
            Positioned(
                top: 18,
                right: 20,
                child: Icon(Icons.route_rounded,
                    size: 38, color: TesseractDesign.ink)),
            Positioned(
                bottom: 24,
                left: 16,
                child: Icon(Icons.favorite,
                    size: 32, color: TesseractDesign.coral))
          ])));
}

/// Page background wash. Use instead of a bare Scaffold colour so caregiver
/// and patient screens share one ground.
class TesseractBackground extends StatelessWidget {
  const TesseractBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(gradient: TesseractDesign.pageGradient),
        child: child,
      );
}

/// White rounded card. The one container shape used across the app.
class TesseractCard extends StatelessWidget {
  const TesseractCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.accent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Warm peach fill for a card that should draw the eye. Decorative only —
  /// never the sole indication that something needs attention.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius =
        BorderRadius.circular(TesseractDesign.cardRadius);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: accent ? TesseractDesign.peach : Colors.white,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Section label above a group of cards.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: TesseractDesign.ink),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Black pill action, the app's primary button shape.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label, textAlign: TextAlign.center),
      style: FilledButton.styleFrom(
        backgroundColor: TesseractDesign.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            TesseractDesign.inkSoft.withValues(alpha: 0.35),
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 56),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A short status line with an icon and words.
///
/// Never colour alone: the icon and the text carry the meaning, so this stays
/// readable in greyscale and to a screen reader.
class StatusNote extends StatelessWidget {
  const StatusNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.tone = StatusTone.neutral,
  });

  final String text;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final Color colour = switch (tone) {
      StatusTone.neutral => TesseractDesign.inkSoft,
      StatusTone.attention => const Color(0xFF8A4B1F),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: colour),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { neutral, attention }

/// A large, plainly labelled patient action.
///
/// Patient screens use these instead of ordinary buttons: generous target,
/// icon plus words, and no reliance on colour to say what it does.
class BigPatientAction extends StatelessWidget {
  const BigPatientAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.primary = true,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = primary ? TesseractDesign.ink : Colors.white;
    final Color foreground = primary ? Colors.white : TesseractDesign.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        button: true,
        label: subtitle == null ? label : '$label. $subtitle',
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(TesseractDesign.cardRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(TesseractDesign.cardRadius),
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(
                  minHeight: TesseractDesign.patientTarget),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 32, color: foreground),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(label,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: foreground)),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: primary
                                      ? Colors.white70
                                      : TesseractDesign.inkSoft)),
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
