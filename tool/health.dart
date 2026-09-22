import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final root = p.normalize(
    p.join(p.dirname(Platform.script.toFilePath()), '..'),
  );
  final project = p.join(root, 'examples/health');
  final output = p.join(root, 'build/showcase/health');
  for (final command in [
    [
      Platform.resolvedExecutable,
      'run',
      'bin/flutter_dom.dart',
      'build',
      '--project',
      project,
      '--dom-only',
      '--output',
      p.join(output, 'native'),
    ],
    [
      'flutter',
      'build',
      'web',
      '--release',
      '--no-web-resources-cdn',
      '--pwa-strategy=none',
      '--no-wasm-dry-run',
      '--base-href',
      '/health/flutter/',
      '--output',
      p.join(output, 'flutter'),
    ],
  ]) {
    final result = await Process.run(
      command.first,
      command.skip(1).toList(),
      workingDirectory: command.first == 'flutter' ? project : root,
    );
    if (result.exitCode != 0) {
      stderr.write('${result.stdout}${result.stderr}');
      exitCode = result.exitCode;
      return;
    }
    if (command.first != 'flutter') stdout.write(result.stdout);
  }
  File(p.join(root, 'demo/health.html')).copySync(p.join(output, 'index.html'));
  stdout.writeln('Health comparison: http://127.0.0.1:8097/health/');
}
