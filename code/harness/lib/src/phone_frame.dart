import 'package:flutter/material.dart';

/// The design target every screen in the real app is built against.
const double kPhoneWidth = 360;
const double kPhoneHeight = 740;

/// Renders [child] inside a fixed 360x740 dp phone-shaped frame, centred on
/// a dimmed surface.
///
/// [child] is always laid out at exactly [kPhoneWidth]x[kPhoneHeight] —
/// never reflowed — and the whole result is then uniformly scaled with
/// [FittedBox] to fit whatever space the harness itself has, so it always
/// looks like a phone even when the harness runs on a larger screen, and
/// never overflows on a smaller one. This is not a responsive layout: the
/// child never sees different constraints, only a different render scale.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: kPhoneWidth,
            height: kPhoneHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
