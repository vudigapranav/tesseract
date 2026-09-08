import 'package:flutter/material.dart';

/// The design target every screen is built against.
const double kHostFrameWidth = 360;
const double kHostFrameHeight = 740;

/// Wraps [child] — the app's routed content — in a fixed 360x740 dp phone
/// frame, centred on a dimmed background, uniformly scaled ([FittedBox]) to
/// fit whatever window it runs in.
///
/// Used only for the web development preview, via `MaterialApp.builder`.
/// Android is the product and renders normally, full-screen, with no such
/// wrapper — web rendering differs from Android, so final QA is always on
/// the phone.
class WebPreviewFrame extends StatelessWidget {
  const WebPreviewFrame(
      {super.key, required this.mediaQueryData, required this.child});

  final MediaQueryData mediaQueryData;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: kHostFrameWidth,
            height: kHostFrameHeight,
            child: MediaQuery(
              data: mediaQueryData.copyWith(
                  size: const Size(kHostFrameWidth, kHostFrameHeight)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
