import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'CLI emits a standalone static site without Flutter or JavaScript',
    () async {
      final directory = Directory.systemTemp.createTempSync('flutter-dom-cli-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/flutter_dom.dart',
        '--config',
        'flutter_dom.static.json',
        '--dom-only',
        '--output',
        directory.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        File(p.join(directory.path, 'index.html')).readAsStringSync(),
        allOf(contains('<h1'), isNot(contains('<script'))),
      );
      expect(File(p.join(directory.path, 'styles.css')).existsSync(), isTrue);
      expect(File(p.join(directory.path, 'report.json')).existsSync(), isTrue);
      expect(
        Directory(p.join(directory.path, 'flutter')).existsSync(),
        isFalse,
      );
      expect(File(p.join(directory.path, 'islands.js')).existsSync(), isFalse);
    },
  );

  test('DOM-only CLI fails before creating output for a hybrid page', () async {
    final directory = Directory.systemTemp.createTempSync('flutter-dom-cli-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final output = p.join(directory.path, 'output');
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/flutter_dom.dart',
      '--dom-only',
      '--output',
      output,
    ]);
    expect(result.exitCode, 1);
    expect(result.stderr, contains('DOM-only build forbids'));
    expect(Directory(output).existsSync(), isFalse);
  });
}
