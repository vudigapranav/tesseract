import 'dart:math';

/// A random (v4) UUID. No `uuid` package dependency — consistent with the
/// rest of this project keeping dependencies to a minimum.
String generateUuidV4(Random random) {
  final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10xx

  String hex(int start, int end) {
    return bytes
        .sublist(start, end)
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
