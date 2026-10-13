import 'dart:convert';
import 'dart:io';
import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  late Directory project;
  late File adapter;
  setUp(() {
    project = Directory.systemTemp.createTempSync('package-adapter-');
    Directory('${project.path}/lib').createSync();
    File('${project.path}/lib/main.dart').writeAsStringSync(
      "import 'package:legacy/service.dart'; void main() { print(result()); print(const String.fromEnvironment('ENDPOINT')); }",
    );
    adapter = File('${project.path}/adapter.dart')
      ..writeAsStringSync('int result()=>42;');
  });
  tearDown(() => project.deleteSync(recursive: true));
  test(
    'CLI package adapters and definitions preserve values and attribution',
    () async {
      final config = File('${project.path}/packages.json')
        ..writeAsStringSync(
          jsonEncode({'package:legacy/service.dart': 'adapter.dart'}),
        );
      final run = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/flutter_dom.dart',
        'build',
        'web',
        '--project',
        project.path,
        '--dart-runtime',
        '--package-bridges',
        config.path,
        '--dart-define',
        'ENDPOINT=/api?q=a,b=x',
        '--output',
        '${project.path}/web',
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      final report =
          jsonDecode(File('${project.path}/web/report.json').readAsStringSync())
              as Map;
      expect(report['nativePackageAdapters'], ['package:legacy/service.dart']);
      expect(report['dartDefinitionKeys'], ['ENDPOINT']);
      expect(jsonEncode(report), isNot(contains('/api?q=')));
      final node = await Process.run('node', [
        '-e',
        'global.self=global;require(process.argv[1]);',
        '${project.path}/web/app.js',
      ]);
      expect(node.exitCode, 0, reason: '${node.stdout}${node.stderr}');
      expect(node.stdout.toString().trim(), '42\n/api?q=a,b=x');
    },
  );
  test(
    'invalid, missing and unreachable package adapters fail explicitly',
    () async {
      for (final key in [
        'dart:io',
        'package:legacy/../service.dart',
        'package:flutter/material.dart',
        'package:legacy/service.dart?x=1',
      ]) {
        await expectLater(
          buildNativeApp(
            project.path,
            'lib/main.dart',
            packageBridges: {key: adapter.path},
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        buildNativeApp(
          project.path,
          'lib/main.dart',
          packageBridges: {'package:legacy/unused.dart': adapter.path},
        ),
        throwsArgumentError,
      );
      await expectLater(
        buildNativeApp(
          project.path,
          'lib/main.dart',
          packageBridges: {
            'package:legacy/service.dart': '${project.path}/missing.dart',
          },
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'reserved and malformed definition keys fail before compilation',
    () async {
      for (final key in ['dart.vm.product', 'bad-key', '']) {
        await expectLater(
          buildNativeApp(
            project.path,
            'lib/main.dart',
            dartDefines: {key: 'x'},
          ),
          throwsArgumentError,
        );
      }
    },
  );
}
