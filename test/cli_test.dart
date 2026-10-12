import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'CLI binds local JSON inputs and fails before output on missing references',
    () async {
      final directory = Directory.systemTemp.createTempSync('dom-data-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory(p.join(directory.path, 'lib')).createSync();
      File(p.join(directory.path, 'lib/main.dart')).writeAsStringSync(
        "class Page extends StatelessWidget { const Page({required this.title}); final String title; Widget build(BuildContext context)=>Text(title); }",
      );
      File(p.join(directory.path, 'flutter_dom.json')).writeAsStringSync(
        '{"root":"Page","arguments":{"title":{"data":"/title"}}}',
      );
      final data = File(p.join(directory.path, 'input.json'))
        ..writeAsStringSync('{"title":"Imported data"}');
      final output = p.join(directory.path, 'output');
      Future<ProcessResult> build(String target) =>
          Process.run(Platform.resolvedExecutable, [
            'run',
            'bin/flutter_dom.dart',
            'build',
            '--project',
            directory.path,
            '--data',
            data.path,
            '--dom-only',
            '--output',
            target,
          ]);
      final result = await build(output);
      expect(result.exitCode, 0, reason: '${result.stdout} ${result.stderr}');
      expect(
        File(p.join(output, 'index.html')).readAsStringSync(),
        contains('Imported data'),
      );
      expect(
        File(p.join(output, 'report.json')).readAsStringSync(),
        contains('"dataSnapshot"'),
      );
      data.writeAsStringSync('{}');
      final invalid = p.join(directory.path, 'invalid');
      expect((await build(invalid)).exitCode, 1);
      expect(Directory(invalid).existsSync(), isFalse);
    },
  );
  test(
    'CLI emits a standalone static site without Flutter or JavaScript',
    () async {
      final directory = Directory.systemTemp.createTempSync('flutter-dom-cli-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/flutter_dom.dart',
        'build',
        '--project',
        'examples/catalog',
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

  test('build web discovers a root without sidecar configuration', () async {
    final directory = Directory.systemTemp.createTempSync('dom-project-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory(p.join(directory.path, 'lib')).createSync();
    File(p.join(directory.path, 'lib/main.dart')).writeAsStringSync(
      '''void main() => runApp(const Landing());
class Landing extends StatelessWidget { Widget build(BuildContext c) => Text('Hello'); }''',
    );
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/flutter_dom.dart',
      'build',
      'web',
      '--project',
      directory.path,
      '--output',
      p.join(directory.path, 'build/dom'),
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout} ${result.stderr}');
    expect(result.stdout, contains('Native boundaries'));
    expect(
      File(p.join(directory.path, 'build/dom/index.html')).readAsStringSync(),
      contains('Hello'),
    );
  });

  test('DOM-only CLI fails before creating output for a hybrid page', () async {
    final directory = Directory.systemTemp.createTempSync('flutter-dom-cli-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final output = p.join(directory.path, 'output');
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/flutter_dom.dart',
      'build',
      '--project',
      'examples/catalog',
      '--dom-only',
      '--output',
      output,
    ]);
    expect(result.exitCode, 1);
    expect(result.stderr, contains('DOM-only build forbids'));
    expect(Directory(output).existsSync(), isFalse);
  });
}
