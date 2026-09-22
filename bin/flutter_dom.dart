import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty && arguments.first == 'inspect') {
    await _inspect(arguments.skip(1).toList());
    return;
  }
  if (arguments.isNotEmpty && arguments.first == 'build') {
    arguments = arguments.skip(1).toList();
  }
  final parser = ArgParser()
    ..addOption('project', defaultsTo: '.', help: 'Flutter project directory.')
    ..addOption(
      'source',
      defaultsTo: 'lib/main.dart',
      help: 'Input relative to project.',
    )
    ..addOption(
      'config',
      defaultsTo: 'flutter_dom.json',
      help: 'Configuration relative to project.',
    )
    ..addOption(
      'output',
      defaultsTo: 'build/dom',
      help: 'Output relative to current directory.',
    )
    ..addFlag('dom-only', negatable: false, help: 'Reject any Flutter island.')
    ..addFlag('help', abbr: 'h', negatable: false);
  try {
    final args = parser.parse(arguments);
    if (args['help'] as bool) {
      stdout.writeln(
        'flutter_dom build [options]\n${parser.usage}\n\n'
        'flutter_dom inspect --project <path> --output build/inspection.json',
      );
      return;
    }
    if (args.rest.isNotEmpty)
      throw ArgumentError('Unexpected arguments: ${args.rest}');
    final project = p.absolute(args['project'] as String);
    final input = File(p.join(project, args['source'] as String));
    final config =
        jsonDecode(
              File(
                p.join(project, args['config'] as String),
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final compiled = FlutterDomCompiler().compile(
      input.readAsStringSync(),
      config,
      domOnly: args['dom-only'] as bool,
    );
    final output = Directory(p.absolute(args['output'] as String));
    output.createSync(recursive: true);
    if (compiled.island != null) {
      final generated = File(
        p.join(project, '.dart_tool', 'flutter_dom', 'island.dart'),
      );
      generated.parent.createSync(recursive: true);
      final titleLiteral = jsonEncode(
        config['title'] as String? ?? 'Flutter island',
      ).replaceAll(r'$', r'\$');
      generated.writeAsStringSync(
        "import 'package:flutter/material.dart';\n"
        "import '${input.uri}' as source;\n"
        'void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, '
        'title: $titleLiteral, home: source.${compiled.island}()));\n',
      );
      for (final command in [
        ['pub', 'get'],
        [
          'build',
          'web',
          '--release',
          '--no-web-resources-cdn',
          '--pwa-strategy=none',
          '--target',
          generated.path,
          '--output',
          p.join(output.path, 'flutter'),
        ],
      ]) {
        stdout.writeln('flutter ${command.join(' ')}');
        final process = await Process.start(
          'flutter',
          command,
          workingDirectory: project,
          mode: ProcessStartMode.inheritStdio,
        );
        if (await process.exitCode != 0) {
          throw CompileException(
            'Flutter island build failed. No new HTML was emitted.',
          );
        }
      }
      final bootstrap = File(
        p.join(output.path, 'flutter', 'flutter_bootstrap.js'),
      ).readAsStringSync();
      const defaultStart = '_flutter.loader.load();';
      if (!bootstrap.trimRight().endsWith(defaultStart)) {
        throw CompileException(
          'Expected the default Flutter bootstrap. Custom '
          'web/flutter_bootstrap.js files are not supported in v0.1.',
        );
      }
      File(
        p.join(output.path, 'flutter', 'island_bootstrap.js'),
      ).writeAsStringSync(
        bootstrap.substring(0, bootstrap.lastIndexOf(defaultStart)),
      );
      File(p.join(output.path, 'islands.js')).writeAsStringSync(_loader);
    }
    File(p.join(output.path, 'index.html')).writeAsStringSync(compiled.html);
    File(p.join(output.path, 'styles.css')).writeAsStringSync(_styles);
    if ((compiled.report['nativeAdapterInstances'] as int) > 0) {
      File(p.join(output.path, 'native.js')).writeAsStringSync(_nativeAdapters);
    }
    compiled.report['initialFilesBytesUncompressed'] = {
      for (final name in [
        'index.html',
        'styles.css',
        if ((compiled.report['nativeAdapterInstances'] as int) > 0) 'native.js',
        if (compiled.island != null) 'islands.js',
      ])
        name: File(p.join(output.path, name)).lengthSync(),
    };
    File(p.join(output.path, 'report.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(compiled.report),
    );
    stdout.writeln('Built ${p.join(output.path, 'index.html')}');
    stdout.writeln(
      'Static HTML ready. Flutter island: ${compiled.island ?? 'none'}.',
    );
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

Future<void> _inspect(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', defaultsTo: '.')
    ..addOption('output', defaultsTo: 'build/inspection.json')
    ..addFlag('help', abbr: 'h', negatable: false);
  try {
    final args = parser.parse(arguments);
    if (args['help'] as bool) {
      stdout.writeln('flutter_dom inspect [options]\n${parser.usage}');
      return;
    }
    if (args.rest.isNotEmpty)
      throw ArgumentError('Unexpected arguments: ${args.rest}');
    final inspector = ProjectInspector();
    final report = inspector.inspect(args['project'] as String);
    final output = File(args['output'] as String);
    if (p.extension(output.path) != '.json')
      throw ArgumentError('Inspection output must end in .json.');
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    File(
      p.setExtension(output.path, '.md'),
    ).writeAsStringSync(inspector.markdown(report));
    stdout.writeln(
      'Inspected ${report['dartFiles']} Dart files; ${report['parserDiagnostics']} parser diagnostics.',
    );
    final coverage = report['compatibility'] as Map<String, Object?>;
    final score = coverage['percent'] as num?;
    stdout.writeln(
      'Native entry compatibility: ${score?.toStringAsFixed(1) ?? 'N/A'}'
      '${score == null ? '' : '%'} (${coverage['native']}/${coverage['total']}).',
    );
    stdout.writeln(coverage['definition']);
    for (final entry in coverage['entries'] as List) {
      if (entry['status'] == 'blocked')
        stdout.writeln(
          '  ${entry['file']}:${entry['line']} ${entry['widget']}: ${entry['blocker']}',
        );
    }
    stdout.writeln('Full report: ${output.path}');
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

const _loader = r'''
// No Flutter resources are requested until the user activates the island.
const button = document.getElementById('load-island');
const status = document.getElementById('island-status');
button.addEventListener('click', async () => {
  button.disabled = true;
  status.textContent = 'Loading Flutter…';
  try {
    const base = new URL('flutter/', document.baseURI).href;
    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = new URL('island_bootstrap.js', base).href;
      script.onload = resolve;
      script.onerror = () => reject(new Error('Flutter bootstrap request failed'));
      document.head.appendChild(script);
    });
    const config = {entrypointBaseUrl: base, assetBase: base,
      canvasKitBaseUrl: `${base}canvaskit/`,
      hostElement: document.getElementById('flutter-island')};
    const documentTitle = document.title;
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('Flutter startup timed out')), 30000);
      window._flutter.loader.load({
        config,
        onEntrypointLoaded: async (initializer) => {
          try {
            const engine = await initializer.initializeEngine(config);
            await engine.runApp();
            clearTimeout(timeout);
            resolve();
          } catch (error) { clearTimeout(timeout); reject(error); }
        }
      }).catch(error => { clearTimeout(timeout); reject(error); });
    });
    document.title = documentTitle;
    document.querySelector('.island-placeholder').remove();
  } catch (error) {
    status.textContent = `Could not load Flutter: ${error.message || error}. Reload the page to retry.`;
  }
});
''';

const _nativeAdapters = r'''
// Explicit filter-list adapter. This does not transpile arbitrary Dart callbacks.
for (const region of document.querySelectorAll('[data-filter-list]')) {
  const input = region.querySelector('input');
  const rows = [...region.querySelectorAll('li')];
  const status = region.querySelector('[role="status"]');
  input.addEventListener('input', () => {
    const query = input.value.trim().toLowerCase();
    let visible = 0;
    for (const row of rows) {
      row.hidden = !row.textContent.toLowerCase().includes(query);
      if (!row.hidden) visible++;
    }
    status.textContent = `${visible} of ${rows.length} features`;
  });
}
''';

const _styles = '''
* { box-sizing: border-box; }
body { margin: 0; background: #f4f6f9; color: #182b42;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; }
main { max-width: 960px; margin: 48px auto; background: white; border-radius: 20px;
  border: 1px solid #dbe2ea; overflow: hidden; }
p, h1, h2, h3, h4, h5, h6 { margin: 0; white-space: pre-wrap; }
.island-shell { position: relative; width: 100%; border: 1px solid #dbe2ea;
  border-radius: 12px; overflow: hidden; background: #f4f6f9; }
#flutter-island { position: relative; width: 100%; overflow: hidden; }
.island-placeholder { position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 16px; padding: 24px; text-align: center; }
button { font: inherit; border: 0; border-radius: 8px; padding: 12px 20px;
  background: #165dcc; color: white; cursor: pointer; }
button:focus-visible { outline: 3px solid #142e54; outline-offset: 4px; }
button:disabled { opacity: .65; cursor: wait; }
.dom-filter { margin: 0; }
.dom-filter label { display:block; font-weight:600; margin-bottom:10px; }
.dom-filter input { width:100%; font:inherit; padding:14px 16px; border:1px solid #bccbd9;
  border-radius:10px; background:#fff; color:#182b42; }
.dom-filter input:focus { outline:3px solid #c5ddff; border-color:#165dcc; }
.filter-status { font-size:13px; color:#51647b; padding:10px 0; }
.dom-filter ul { list-style:none; padding:0; margin:0; }
.dom-filter li { padding:12px 16px; border:1px solid #dbe2ea; border-radius:8px; margin-bottom:8px; }
@media (max-width: 600px) { main { margin: 12px; } }
''';
