import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TesseractHarnessApp());
}

class TesseractHarnessApp extends StatelessWidget {
  const TesseractHarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tesseract harness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const SetupScreen(),
    );
  }
}
