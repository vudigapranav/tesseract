import 'package:flutter/material.dart';

abstract final class TesseractDesign {
  static const cream = Color(0xFFFFF8EC);
  static const peach = Color(0xFFFFE2D4);
  static const coral = Color(0xFFF47F78);
  static const ink = Color(0xFF24211F);
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
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
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
