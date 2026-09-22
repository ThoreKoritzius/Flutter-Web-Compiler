import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'src/artifact_sizes.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('port', defaultsTo: '8097')
    ..addFlag('serve', defaultsTo: true)
    ..addFlag('help', abbr: 'h', negatable: false);
  try {
    final args = parser.parse(arguments);
    if (args['help'] as bool) {
      stdout.writeln('dart run tool/showcase.dart [options]\n${parser.usage}');
      return;
    }
    if (args.rest.isNotEmpty)
      throw ArgumentError('Unexpected arguments: ${args.rest}');
    final port = int.tryParse(args['port'] as String);
    if (port == null || port < 1 || port > 65535)
      throw ArgumentError('Invalid port.');
    final root = p.normalize(
      p.join(p.dirname(Platform.script.toFilePath()), '..'),
    );
    final project = p.join(root, 'examples', 'showcase');
    final output = p.join(root, 'build', 'showcase');
    Future<void> run(
      String executable,
      List<String> command,
      String cwd,
    ) async {
      stdout.writeln('$executable ${command.join(' ')}');
      final process = await Process.start(
        executable,
        command,
        workingDirectory: cwd,
        mode: ProcessStartMode.inheritStdio,
      );
      if (await process.exitCode != 0)
        throw StateError('Showcase build failed.');
    }

    await run(Platform.resolvedExecutable, [
      'run',
      'bin/flutter_dom.dart',
      'build',
      '--project',
      project,
      '--output',
      p.join(output, 'native'),
    ], root);
    await run('flutter', [
      'build',
      'web',
      '--release',
      '--no-web-resources-cdn',
      '--pwa-strategy=none',
      '--base-href',
      '/flutter/',
      '--output',
      p.join(output, 'flutter'),
    ], project);
    for (final file in ['index.html', 'showcase.css', 'showcase.js']) {
      File(p.join(root, 'demo', file)).copySync(p.join(output, file));
    }
    final nativeRoot = p.join(output, 'native');
    final nativeInitial = [
      'index.html',
      'styles.css',
      'native.js',
      'islands.js',
    ];
    final nativeComplete = [
      ...nativeInitial,
      ...flutterArtifacts(
        p.join(nativeRoot, 'flutter'),
        includeHtml: false,
        bootstrap: 'island_bootstrap.js',
      ).map((name) => 'flutter/$name'),
    ];
    File(p.join(output, 'metrics.json')).writeAsStringSync(
      jsonEncode({
        'kind': 'selected-build-artifact-sizes',
        'nativeInitial': measureArtifacts(nativeRoot, nativeInitial),
        'nativeComplete': measureArtifacts(nativeRoot, nativeComplete),
        'flutterInitial': measureArtifacts(
          p.join(output, 'flutter'),
          flutterArtifacts(p.join(output, 'flutter')),
        ),
      }),
    );
    final savedAudit = File(
      p.join(root, 'benchmarks/results/showcase-browser.json'),
    );
    if (savedAudit.existsSync())
      savedAudit.copySync(p.join(output, 'audits.json'));
    stdout.writeln('\nBuilt paired showcase: $output');
    if (!(args['serve'] as bool)) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    stdout.writeln(
      'Showcase: http://127.0.0.1:$port/\nTargets: /native/ and /flutter/\nCtrl+C to stop.',
    );
    await for (final request in server) {
      final requested = p.normalize(
        p.join(output, request.uri.path.substring(1)),
      );
      if (!p.isWithin(output, requested) && requested != output) {
        request.response.statusCode = 403;
        await request.response.close();
        continue;
      }
      final file = File(
        Directory(requested).existsSync()
            ? p.join(requested, 'index.html')
            : requested,
      );
      if (!file.existsSync()) {
        request.response.statusCode = 404;
        await request.response.close();
        continue;
      }
      final type = {
        '.html': 'text/html; charset=utf-8',
        '.css': 'text/css; charset=utf-8',
        '.js': 'text/javascript; charset=utf-8',
        '.json': 'application/json',
        '.wasm': 'application/wasm',
      }[p.extension(file.path)];
      request.response.headers.set(
        'Content-Type',
        type ?? 'application/octet-stream',
      );
      request.response.headers.set('Cache-Control', 'no-store');
      await request.response.addStream(file.openRead());
      await request.response.close();
    }
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
