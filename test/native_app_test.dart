import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('runtime CLI rejects unsupported apps before creating output', () async {
    final directory = Directory.systemTemp.createTempSync('native-cli-reject-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(
      "import 'package:flutter/material.dart'; void main() => runApp(const UnknownWidget());",
    );
    final output = '${directory.path}/output';
    final run = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/flutter_dom.dart',
      'build',
      'web',
      '--project',
      directory.path,
      '--dart-runtime',
      '--output',
      output,
    ]);
    expect(run.exitCode, 1);
    expect(Directory(output).existsSync(), isFalse);
  });
  test(
    'original Flutter source executes requests and setState via dart2js',
    () async {
      final source = File('examples/logic/lib/main.dart').readAsStringSync();
      final app = await buildNativeApp('examples/logic', 'lib/main.dart');
      expect(app.libraries, 3);
      expect(File('examples/logic/lib/main.dart').readAsStringSync(), source);
      final directory = Directory.systemTemp.createTempSync('native-app-test-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/native_app_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('retry passed'));
    },
  );

  test(
    'unsupported framework APIs and conditional imports fail explicitly',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'native-app-reject-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      final entry = File('${directory.path}/lib/main.dart');
      for (final source in [
        "import 'dart:ui'; void main() {}",
        "import 'package:flutter/foundation.dart'; void main() {}",
        "import 'a.dart' if (dart.library.js_interop) 'b.dart'; void main() {}",
        "import 'package:flutter/material.dart'; void main() => runApp(const UnknownWidget());",
      ]) {
        entry.writeAsStringSync(source);
        await expectLater(
          buildNativeApp(directory.path, 'lib/main.dart'),
          throwsA(anything),
        );
        expect(entry.readAsStringSync(), source);
      }
    },
  );
}
