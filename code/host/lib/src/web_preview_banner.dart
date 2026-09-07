import 'package:flutter/material.dart';

/// Shown only on Home, only in the web build: web is a development preview,
/// not a product target. Android is the product; final QA is always on the
/// phone, since web rendering differs from Android.
class WebPreviewBanner extends StatelessWidget {
  const WebPreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Text(
        'Web preview — development only. The product is Android; final QA is always on the phone.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF7A5B00), fontWeight: FontWeight.w600),
      ),
    );
  }
}
