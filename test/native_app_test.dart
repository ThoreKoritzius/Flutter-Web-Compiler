import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'explicit library adapters replace only selected reachable sources',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-adapter-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      final main = File('${directory.path}/lib/main.dart')
        ..writeAsStringSync(
          "import 'engine.dart'; void main() => print(result());",
        );
      final original = File('${directory.path}/lib/engine.dart')
        ..writeAsStringSync(
          "import 'package:flutter/rendering.dart'; int result()=>0;",
        );
      final bridge = File('${directory.path}/lib/native.dart')
        ..writeAsStringSync('int result()=>42;');
      final oldSource = original.readAsStringSync();
      await expectLater(
        buildNativeApp(directory.path, 'lib/main.dart'),
        throwsUnsupportedError,
      );
      final app = await buildNativeApp(
        directory.path,
        'lib/main.dart',
        libraryBridges: {'lib/engine.dart': bridge.path},
      );
      expect(app.libraryAdapters, ['lib/engine.dart']);
      expect(original.readAsStringSync(), oldSource);
      expect(main.readAsStringSync(), contains("import 'engine.dart'"));
      final script = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        '-e',
        'global.self=global;require(process.argv[1]);',
        script.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout.toString().trim(), '42');
      final bridges = File('${directory.path}/bridges.json')
        ..writeAsStringSync('{"lib/engine.dart":"lib/native.dart"}');
      final output = '${directory.path}/output';
      final cli = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/flutter_dom.dart',
        'build',
        'web',
        '--project',
        directory.path,
        '--dart-runtime',
        '--runtime-bridges',
        bridges.path,
        '--output',
        output,
      ]);
      expect(cli.exitCode, 0, reason: '${cli.stdout}${cli.stderr}');
      expect(
        File('$output/report.json').readAsStringSync(),
        contains('"nativeLibraryAdapters"'),
      );
      expect(
        File('$output/report.json').readAsStringSync(),
        contains('lib/engine.dart'),
      );
    },
  );

  test(
    'invalid and unreachable adapter selections fail rather than being ignored',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'native-adapter-reject-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File(
        '${directory.path}/lib/main.dart',
      ).writeAsStringSync('void main() {}');
      File(
        '${directory.path}/lib/unused.dart',
      ).writeAsStringSync('void unused() {}');
      final bridge = File('${directory.path}/lib/native.dart')
        ..writeAsStringSync('void main() {}');
      for (final map in [
        {'../outside.dart': bridge.path},
        {'lib/missing.dart': bridge.path},
        {'lib/main.dart': '${directory.path}/missing.dart'},
        {'lib/unused.dart': bridge.path},
      ]) {
        await expectLater(
          buildNativeApp(directory.path, 'lib/main.dart', libraryBridges: map),
          throwsArgumentError,
        );
      }
    },
  );
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
        "import 'package:flutter/services.dart'; void main() {}",
        "import 'a.dart' if (custom.feature) 'b.dart'; void main() {}",
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

  test(
    'web branches and foundation compute execute through official compilation',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'native-foundation-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      // Unselected files intentionally do not exist.
      File('${directory.path}/lib/main.dart').writeAsStringSync(r'''
import 'missing_io.dart' if (dart.library.js_interop) 'web.dart' if (dart.library.html) 'missing_second_match.dart' as platform;
import 'dart:io' if (dart.library.js_interop) 'dart:convert' as codec;
import 'selected.dart' if (dart.library.io) 'missing_io.dart' as fallback;
import 'package:flutter/foundation.dart';
Future<void> main() async {
  print('web:$kIsWeb release:$kReleaseMode profile:$kProfileMode debug:$kDebugMode');
  final result = await compute((int value) => platform.twice(value), 21);
  print('result:$result');
  print('decoded:${codec.jsonDecode('42')}');
  print('fallback:${fallback.twice(21)}');
}
''');
      File('${directory.path}/lib/web.dart').writeAsStringSync(
        "export 'missing_native.dart' if (dart.library.io == 'false') 'selected.dart' show twice;",
      );
      File(
        '${directory.path}/lib/selected.dart',
      ).writeAsStringSync('int twice(int value) => value * 2;');
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      expect(app.libraries, 3);
      final script = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        '-e',
        'global.self=global;require(process.argv[1]);',
        script.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(
        run.stdout,
        contains('web:true release:true profile:false debug:false'),
      );
      expect(run.stdout, contains('result:42'));
      expect(run.stdout, contains('decoded:42'));
      expect(run.stdout, contains('fallback:42'));
    },
  );
}
