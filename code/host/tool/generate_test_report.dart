// Runs `flutter test`, captures a pass/fail line per test, and writes
// test_report.html — a plain HTML+CSS page (no build step) showing that
// table plus every golden PNG inline in a phone-shaped frame with its name
// underneath.
//
// Run from code/host/:
//   dart run tool/generate_test_report.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  stdout.writeln('Running flutter test --reporter json ...');
  final Process process = await Process.start(
      'flutter',
      <String>[
        'test',
        '--reporter',
        'json',
      ],
      workingDirectory: Directory.current.path);

  final List<String> outLines = <String>[];
  final List<StreamSubscription<void>> subs = <StreamSubscription<void>>[];
  subs.add(process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(outLines.add));
  final StringBuffer errBuffer = StringBuffer();
  subs.add(process.stderr.transform(utf8.decoder).listen(errBuffer.write));

  final int exitCode = await process.exitCode;
  for (final StreamSubscription<void> sub in subs) {
    await sub.cancel();
  }

  final Map<int, String> namesById = <int, String>{};
  final List<_TestResult> results = <_TestResult>[];

  for (final String line in outLines) {
    if (line.trim().isEmpty || line.trim()[0] != '{') {
      continue;
    }
    final Map<String, Object?> event;
    try {
      event = jsonDecode(line) as Map<String, Object?>;
    } catch (_) {
      continue;
    }
    switch (event['type']) {
      case 'testStart':
        final Map<String, Object?> test =
            event['test']! as Map<String, Object?>;
        namesById[test['id']! as int] = test['name']! as String;
      case 'testDone':
        final int id = event['testID']! as int;
        final String? name = namesById[id];
        if (name == null || name.startsWith('loading ')) {
          continue;
        }
        final bool skipped = event['skipped'] == true;
        final String result =
            skipped ? 'skipped' : (event['result']! as String);
        results.add(_TestResult(name: name, result: result));
    }
  }

  final int passed =
      results.where((_TestResult r) => r.result == 'success').length;
  final int failed = results
      .where((_TestResult r) => r.result != 'success' && r.result != 'skipped')
      .length;
  final int skipped =
      results.where((_TestResult r) => r.result == 'skipped').length;

  final Directory goldensDir = Directory('test/goldens');
  final List<File> goldens = goldensDir.existsSync()
      ? goldensDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.png'))
          .toList()
      : <File>[];
  goldens.sort((File a, File b) => a.path.compareTo(b.path));

  final String html = _buildHtml(
    results: results,
    passed: passed,
    failed: failed,
    skipped: skipped,
    goldens: goldens,
    processExitCode: exitCode,
  );

  final File reportFile = File('test_report.html');
  await reportFile.writeAsString(html);

  stdout.writeln('$passed passed, $failed failed, $skipped skipped');
  stdout.writeln('Wrote ${reportFile.absolute.path}');
  if (errBuffer.isNotEmpty && exitCode != 0) {
    stderr.writeln(errBuffer.toString());
  }
  exit(exitCode);
}

class _TestResult {
  _TestResult({required this.name, required this.result});
  final String name;
  final String result;
}

String _escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String _goldenLabel(String path) {
  final String base = path.split(Platform.pathSeparator).last;
  return base.substring(0, base.length - '.png'.length);
}

String _buildHtml({
  required List<_TestResult> results,
  required int passed,
  required int failed,
  required int skipped,
  required List<File> goldens,
  required int processExitCode,
}) {
  final StringBuffer rows = StringBuffer();
  for (final _TestResult r in results) {
    final String cls = switch (r.result) {
      'success' => 'pass',
      'skipped' => 'skip',
      _ => 'fail',
    };
    final String label = switch (r.result) {
      'success' => 'PASS',
      'skipped' => 'SKIP',
      _ => 'FAIL',
    };
    rows.writeln('''
      <tr class="$cls">
        <td>${_escapeHtml(r.name)}</td>
        <td class="status">$label</td>
      </tr>''');
  }

  final StringBuffer gallery = StringBuffer();
  for (final File golden in goldens) {
    final String relPath = golden.path.replaceAll(Platform.pathSeparator, '/');
    gallery.writeln('''
      <figure class="phone-frame">
        <div class="phone-screen"><img src="$relPath" alt="${_escapeHtml(_goldenLabel(relPath))}"></div>
        <figcaption>${_escapeHtml(_goldenLabel(relPath))}</figcaption>
      </figure>''');
  }

  final String generatedAt = DateTime.now().toIso8601String();

  return '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Tesseract host — test report</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f4f6f5; color: #1a1f1c; margin: 0; padding: 32px; }
  h1 { margin-top: 0; }
  .summary { display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
  .summary .card { background: white; border-radius: 12px; padding: 16px 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); min-width: 120px; }
  .summary .card .n { font-size: 28px; font-weight: 700; }
  .summary .pass .n { color: #2e7d5b; }
  .summary .fail .n { color: #c0392b; }
  .summary .skip .n { color: #b08900; }
  table { border-collapse: collapse; width: 100%; max-width: 900px; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); margin-bottom: 40px; }
  th, td { text-align: left; padding: 10px 16px; border-bottom: 1px solid #eee; }
  th { background: #eef3f0; }
  tr.fail { background: #fdecea; }
  tr.skip { background: #fff8e1; }
  td.status { font-weight: 700; white-space: nowrap; }
  tr.pass td.status { color: #2e7d5b; }
  tr.fail td.status { color: #c0392b; }
  tr.skip td.status { color: #b08900; }
  h2 { margin-top: 40px; }
  .gallery { display: flex; flex-wrap: wrap; gap: 24px; }
  .phone-frame { margin: 0; background: #1a1f1c; border-radius: 28px; padding: 10px; width: 180px; box-shadow: 0 2px 8px rgba(0,0,0,0.25); }
  .phone-screen { width: 160px; height: 328px; border-radius: 18px; overflow: hidden; background: white; }
  .phone-screen img { width: 100%; height: 100%; object-fit: cover; display: block; }
  figcaption { color: #1a1f1c; text-align: center; font-size: 12px; margin-top: 8px; word-break: break-word; }
  footer { margin-top: 40px; color: #667; font-size: 12px; }
</style>
</head>
<body>
  <h1>Tesseract host — test report</h1>
  <div class="summary">
    <div class="card pass"><div class="n">$passed</div>passed</div>
    <div class="card fail"><div class="n">$failed</div>failed</div>
    <div class="card skip"><div class="n">$skipped</div>skipped</div>
  </div>

  <h2>Every test</h2>
  <table>
    <thead><tr><th>Test</th><th>Result</th></tr></thead>
    <tbody>
$rows
    </tbody>
  </table>

  <h2>Golden screenshots (${goldens.length})</h2>
  <div class="gallery">
$gallery
  </div>

  <footer>Generated $generatedAt · flutter test exit code $processExitCode · tool/generate_test_report.dart</footer>
</body>
</html>
''';
}
