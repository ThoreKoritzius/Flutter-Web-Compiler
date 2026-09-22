import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'src/artifact_sizes.dart';

/// Rebuilds paired fixtures and measures explicitly listed artifacts.
/// This is not a browser timing or production transfer benchmark.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', defaultsTo: 'build/benchmarks')
    ..addFlag('help', abbr: 'h', negatable: false);
  try {
    final args = parser.parse(arguments);
    if (args['help'] as bool) {
      stdout.writeln('dart run tool/benchmark.dart [options]\n${parser.usage}');
      return;
    }
    if (args.rest.isNotEmpty)
      throw ArgumentError('Unexpected arguments: ${args.rest}');
    final root = p.normalize(
      p.join(p.dirname(Platform.script.toFilePath()), '..'),
    );
    final project = p.join(root, 'examples', 'catalog');
    final output = p.absolute(args['output'] as String);
    final fixture = File(p.join(project, 'lib', 'main.dart'));
    final compilerFiles = [
      File(p.join(root, 'bin', 'flutter_dom.dart')),
      ...Directory(p.join(root, 'lib'))
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    ]..sort((a, b) => a.path.compareTo(b.path));
    final compilerDigest = sha256
        .convert(
          utf8.encode(
            compilerFiles
                .map(
                  (file) =>
                      '${p.relative(file.path, from: root)}\n${file.readAsStringSync()}',
                )
                .join('\n'),
          ),
        )
        .toString();
    final flutterVersion = await Process.run('flutter', [
      '--version',
      '--machine',
    ]);
    if (flutterVersion.exitCode != 0)
      throw StateError('Could not read Flutter version.');
    final version =
        jsonDecode(flutterVersion.stdout as String) as Map<String, dynamic>;
    final runs = <Map<String, Object?>>[];
    await _run('flutter', ['pub', 'get'], project);
    for (final (workload, widget, config) in [
      ('static', 'StaticApp', 'flutter_dom.static.json'),
      ('hybrid', 'App', 'flutter_dom.json'),
    ]) {
      final domOutput = p.join(output, 'dom-$workload');
      final flutterOutput = p.join(output, 'flutter-$workload');
      await _run(Platform.resolvedExecutable, [
        'run',
        'bin/flutter_dom.dart',
        'build',
        '--project',
        project,
        '--config',
        config,
        '--output',
        domOutput,
        if (workload == 'static') '--dom-only',
      ], root);
      final entry = File(
        p.join(
          project,
          '.dart_tool',
          'flutter_dom',
          'benchmark_$workload.dart',
        ),
      );
      entry.parent.createSync(recursive: true);
      entry.writeAsStringSync(
        "import 'package:flutter/material.dart';\n"
        "import '${fixture.uri}' as source;\nvoid main() => runApp(const source.$widget());\n",
      );
      await _run('flutter', [
        'build',
        'web',
        '--release',
        '--no-web-resources-cdn',
        '--pwa-strategy=none',
        '--target',
        entry.path,
        '--output',
        flutterOutput,
      ], project);
      final initial = [
        'index.html',
        'styles.css',
        if (workload == 'hybrid') 'islands.js',
      ];
      final after = [
        ...initial,
        if (workload == 'hybrid')
          ...flutterArtifacts(
            p.join(domOutput, 'flutter'),
            bootstrap: 'island_bootstrap.js',
            includeHtml: false,
          ).map((path) => 'flutter/$path'),
      ];
      runs.add({
        'workload': workload,
        'target': 'flutter_dom',
        'root': widget,
        'initial': measureArtifacts(domOutput, initial),
        'afterActivation': measureArtifacts(domOutput, after),
      });
      final baseline = measureArtifacts(
        flutterOutput,
        flutterArtifacts(flutterOutput),
      );
      runs.add({
        'workload': workload,
        'target': 'flutter_web',
        'root': widget,
        'initial': baseline,
        'afterActivation': baseline,
      });
    }
    final report = <String, Object?>{
      'schemaVersion': 1,
      'kind': 'selected-build-artifact-sizes-not-browser-timings',
      'fixture': 'examples/catalog/lib/main.dart',
      'fixtureSha256': sha256.convert(fixture.readAsBytesSync()).toString(),
      'compilerSha256': compilerDigest,
      'flutter': version['frameworkVersion'],
      'engine': version['engineRevision'],
      'dart': version['dartSdkVersion'],
      'platform': Platform.operatingSystem,
      'renderer': 'CanvasKit Chromium, JavaScript release build',
      'gzip': 'Each file independently compressed with GZipCodec(level: 9)',
      'runs': runs,
      'limitations': [
        'Toy fixtures; these are not representative application benchmarks.',
        'Same source widget per pair; CSS layout and system fonts differ from Flutter rendering.',
        'Hybrid requires explicit activation; Flutter Web exposes the counter immediately.',
        'Sizes are selected build artifacts, not observed network bytes, FCP, LCP, TTI or memory.',
        'Selected local CanvasKit Chromium variant; alternate browser/Wasm variants are excluded.',
        'Includes declared fonts; excludes HTTP headers, compression negotiation, caches and external fallback fonts.',
        'Excludes debug maps and unused renderer variants; full deployment directories are larger.',
        'No SEO score or ranking improvement has been measured.',
      ],
    };
    Directory(output).createSync(recursive: true);
    File(p.join(output, 'results.json')).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
    final table = StringBuffer(
      '| Workload | Build | Initial KiB | Initial gzip KiB | After activation KiB | After activation gzip KiB |\n',
    )..writeln('| --- | --- | ---: | ---: | ---: | ---: |');
    String size(Map stage, String field) =>
        ((stage[field] as int) / 1024).toStringAsFixed(2);
    for (final run in runs) {
      final before = run['initial'] as Map,
          after = run['afterActivation'] as Map;
      table.writeln(
        '| ${run['workload']} | ${run['target']} | ${size(before, 'bytes')} | ${size(before, 'gzipBytes')} | ${size(after, 'bytes')} | ${size(after, 'gzipBytes')} |',
      );
    }
    File(p.join(output, 'table.md')).writeAsStringSync(table.toString());
    stdout.writeln('\n$table\nRaw results: ${p.join(output, 'results.json')}');
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

Future<void> _run(String executable, List<String> args, String cwd) async {
  stdout.writeln('$executable ${args.join(' ')}');
  final process = await Process.start(
    executable,
    args,
    workingDirectory: cwd,
    mode: ProcessStartMode.inheritStdio,
  );
  if (await process.exitCode != 0)
    throw StateError('Benchmark build failed: $executable');
}
