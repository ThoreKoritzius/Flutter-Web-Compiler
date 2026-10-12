import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'official compiled Dart repository handles live HTTP and DOM state',
    () async {
      final directory = Directory.systemTemp.createTempSync('dom-logic-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final output = '${directory.path}/logic.js';
      final compilation = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '--no-source-maps',
        '-o',
        output,
        'examples/logic/lib/browser.dart',
      ]);
      expect(
        compilation.exitCode,
        0,
        reason: '${compilation.stdout}${compilation.stderr}',
      );
      final run = await Process.run('node', [
        'tool/browser/logic_runtime_test.cjs',
        output,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('retry passed'));
    },
  );
}
