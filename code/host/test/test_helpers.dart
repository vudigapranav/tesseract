import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_host/src/design_system.dart';
import 'package:tesseract_host/src/phone_frame.dart';

/// Loads real Roboto weights and the Material Icons font (all shipped with
/// the Flutter SDK itself, copied into test/fonts/ — no added dependency)
/// so golden screenshots render actual text and icons instead of the test
/// environment's default hollow boxes.
Future<void> loadAppFonts() async {
  Future<void> loadFamily(String family, List<String> paths) async {
    final FontLoader loader = FontLoader(family);
    for (final String path in paths) {
      final Uint8List bytes = await File(path).readAsBytes();
      loader.addFont(Future<ByteData>.value(bytes.buffer.asByteData()));
    }
    await loader.load();
  }

  await loadFamily('Roboto', <String>[
    'test/fonts/Roboto-Regular.ttf',
    'test/fonts/Roboto-Medium.ttf',
    'test/fonts/Roboto-Bold.ttf',
  ]);
  await loadFamily(
      'MaterialIcons', <String>['test/fonts/MaterialIcons-Regular.otf']);
}

/// Pumps [screen] at exactly 360x740 dp (device pixel ratio 1), optionally
/// at a scaled-up text size, for a pixel-stable golden screenshot.
///
/// Deliberately a single [WidgetTester.pump], not `pumpAndSettle` — Marble
/// Maze runs a continuous fixed-timestep `Ticker` that never goes idle, so
/// `pumpAndSettle` would hang waiting for a frame that never stops being
/// scheduled. A golden only needs one stable frame anyway.
Future<void> pumpForGolden(WidgetTester tester, Widget screen,
    {double textScale = 1.0}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(kHostFrameWidth, kHostFrameHeight);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // The app's real theme, so a golden shows what ships rather than a
      // stand-in palette that no screen actually uses.
      theme: TesseractDesign.theme,
      home: screen,
    ),
  );
  await tester.pump();
}
