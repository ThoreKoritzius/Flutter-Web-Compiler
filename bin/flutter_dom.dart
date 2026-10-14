import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty && arguments.first == 'inspect') {
    await _inspect(arguments.skip(1).toList());
    return;
  }
  if (arguments.isNotEmpty && arguments.first == 'build') {
    arguments = arguments.skip(1).toList();
    if (arguments.isNotEmpty && arguments.first == 'web')
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
      'data',
      help: 'Local JSON snapshot relative to the current directory.',
    )
    ..addOption(
      'output',
      defaultsTo: 'build/dom',
      help: 'Output relative to current directory.',
    )
    ..addFlag(
      'resolve-imports',
      negatable: false,
      help: 'Resolve project-local imports (requires flutter pub get).',
    )
    ..addFlag('verbose', abbr: 'v', negatable: false)
    ..addFlag(
      'dart-runtime',
      negatable: false,
      help: 'Experimental official Dart compiler + bounded DOM widget runtime.',
    )
    ..addOption(
      'runtime-bridges',
      help:
          'Explicit library bridge JSON file relative to current directory; requires --dart-runtime.',
    )
    ..addOption(
      'runtime-selections',
      help:
          'Explicit component declaration/import selection JSON; requires --dart-runtime.',
    )
    ..addOption(
      'package-bridges',
      help: 'Explicit package URI adapter JSON; requires --dart-runtime.',
    )
    ..addOption(
      'material-icons-font',
      help:
          'MaterialIcons-Regular.otf for --dart-runtime; defaults to the Flutter SDK on FLUTTER_ROOT or PATH.',
    )
    ..addFlag(
      'tree-shake-icons',
      defaultsTo: true,
      help: 'Ship only the Material icon glyphs the app uses (--dart-runtime).',
    )
    ..addMultiOption(
      'dart-define',
      splitCommas: false,
      help: 'Compile-time KEY=VALUE; requires --dart-runtime.',
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
    if (!input.existsSync())
      throw ArgumentError(
        'No ${input.path}. Run inside a Flutter app or pass --project examples/catalog.',
      );
    final configFile = File(p.join(project, args['config'] as String));
    if (args['dart-runtime'] as bool) {
      if (args.wasParsed('config') || args.wasParsed('data')) {
        throw ArgumentError(
          'The experimental Dart runtime does not accept static config or snapshot inputs.',
        );
      }
      stdout.writeln('\nFlutter DOM  Compiling experimental Dart runtime…');
      final bridges = <String, String>{};
      if (args.wasParsed('runtime-bridges')) {
        final file = File(p.absolute(args['runtime-bridges'] as String));
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is! Map ||
            decoded.entries.any(
              (e) => e.key is! String || e.value is! String,
            )) {
          throw ArgumentError(
            'Runtime bridges must be a JSON object mapping source paths to Dart files.',
          );
        }
        for (final item in decoded.entries) {
          bridges[item.key as String] = p.normalize(
            p.join(file.parent.path, item.value as String),
          );
        }
      }
      final packageBridges = <String, String>{};
      if (args.wasParsed('package-bridges')) {
        final file = File(p.absolute(args['package-bridges'] as String));
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is! Map ||
            decoded.entries.any((e) => e.key is! String || e.value is! String))
          throw ArgumentError(
            'Package bridges must map package URIs to Dart files.',
          );
        for (final item in decoded.entries) {
          packageBridges[item.key as String] = p.normalize(
            p.join(file.parent.path, item.value as String),
          );
        }
      }
      final selections = <String, NativeSourceSelection>{};
      if (args.wasParsed('runtime-selections')) {
        final decoded = jsonDecode(
          File(args['runtime-selections'] as String).readAsStringSync(),
        );
        if (decoded is! Map)
          throw ArgumentError('Runtime selections must be a JSON object.');
        for (final item in decoded.entries) {
          final value = item.value;
          if (item.key is! String ||
              value is! Map ||
              value.length != 2 ||
              value['declarations'] is! List ||
              value['imports'] is! List ||
              (value['declarations'] as List).any((e) => e is! String) ||
              (value['imports'] as List).any((e) => e is! String)) {
            throw ArgumentError(
              'Each selection requires declarations and imports string lists.',
            );
          }
          selections[item.key as String] = NativeSourceSelection(
            declarations: (value['declarations'] as List).cast<String>(),
            imports: (value['imports'] as List).cast<String>(),
          );
        }
      }
      final defines = <String, String>{};
      for (final item in args['dart-define'] as List<String>) {
        final separator = item.indexOf('=');
        if (separator < 1)
          throw ArgumentError('Dart definitions require KEY=VALUE.');
        final key = item.substring(0, separator);
        if (defines.containsKey(key))
          throw ArgumentError('Duplicate Dart definition key.');
        defines[key] = item.substring(separator + 1);
      }
      final app = await buildNativeApp(
        project,
        args['source'] as String,
        libraryBridges: bridges,
        packageBridges: packageBridges,
        dartDefines: defines,
        sourceSelections: selections,
        materialIconsFont: args['material-icons-font'] as String?,
        treeShakeIcons: args['tree-shake-icons'] as bool,
      );
      if (app.usesMaterialIcons && app.materialIconsFont == null) {
        throw StateError(
          'This app renders Material icons, but MaterialIcons-Regular.otf was not found. '
          'Install the Flutter SDK (FLUTTER_ROOT or flutter on PATH, then run `flutter precache --web`) '
          'or pass --material-icons-font <path>.',
        );
      }
      final output = Directory(p.absolute(args['output'] as String))
        ..createSync(recursive: true);
      final written = writeNativeApp(app, output.path);
      File(p.join(output.path, 'report.json')).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'target': 'experimental-dart-runtime',
          'logicCompiler': 'dart2js',
          'viewBackend': 'bounded-dom-compatibility-layer',
          'sourceLibraries': app.libraries,
          'nativeLibraryAdapters': app.libraryAdapters,
          'nativePackageAdapters': app.packageAdapters,
          'builtInPackageBridges': app.builtInBridges,
          'rewrittenPackages': app.rewrittenPackages,
          'nativeSourceSelections': {
            for (final item in app.sourceSelections.entries)
              item.key: {
                'declarations': item.value.declarations,
                'imports': item.value.imports,
              },
          },
          'dartDefinitionKeys': defines.keys.toList(),
          'javascriptBytes': utf8.encode(app.javascript).length,
          'automaticFlutterCompatibility': false,
          'stateLifecycle': 'keyed-element-tree-retained-dom',
          'providerIntegration': app.riverpodConsumers
              ? 'riverpod-2.6.1-element-scopes'
              : 'none',
          'materialIconsFont': app.materialIconsFont == null
              ? null
              : 'assets/fonts/MaterialIcons-Regular.otf',
          'materialIconsSubset': app.materialIconsFont == null
              ? null
              : app.iconCodePoints == null
              ? 'full-font'
              : '${app.iconCodePoints!.length} glyphs',
          'fontFamilies': {
            for (final face in app.fontFaces) face.family,
          }.toList(),
          'assets': app.assets.keys.toList(),
          'files': written,
        }),
      );
      stdout.writeln(
        '  ✓ Built ${output.path}\n  Dart source graph · ${app.libraries} libraries · ${app.libraryAdapters.length} library adapters · ${app.packageAdapters.length} package adapters · ${app.sourceSelections.length} explicit component selections\n  ${app.assets.length + app.generatedAssets.length} assets${app.iconCodePoints == null ? '' : ' · ${app.iconCodePoints!.length} icon glyphs'}\n  Experimental: keyed element tree with retained DOM; ${app.riverpodConsumers ? 'Riverpod 2.6.1 scopes and consumers' : 'no provider integration'}.',
      );
      return;
    }
    if (args.wasParsed('package-bridges') || args.wasParsed('dart-define'))
      throw ArgumentError(
        'Package adapters and Dart definitions require --dart-runtime.',
      );
    if (args.wasParsed('runtime-selections'))
      throw ArgumentError('--runtime-selections requires --dart-runtime.');
    if (args.wasParsed('runtime-bridges'))
      throw ArgumentError('--runtime-bridges requires --dart-runtime.');
    if (args.wasParsed('config') && !configFile.existsSync())
      throw ArgumentError('Configuration not found: ${configFile.path}');
    var config = configFile.existsSync()
        ? jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>
        : <String, dynamic>{};
    SnapshotBinding? snapshot;
    if (args['data'] != null) {
      final file = File(p.absolute(args['data'] as String));
      if (!file.existsSync()) throw ArgumentError('Snapshot file not found.');
      if (file.lengthSync() > 5 * 1024 * 1024)
        throw ArgumentError('Snapshot file exceeds 5 MiB.');
      Object? payload;
      try {
        payload = jsonDecode(file.readAsStringSync());
      } on FormatException {
        throw ArgumentError('Snapshot file must contain valid JSON.');
      }
      snapshot = bindDataSnapshot(config, payload);
      config = snapshot.config;
    }
    final watch = Stopwatch()..start();
    stdout.writeln(
      '\n${_accent('Flutter DOM')}  Building ${p.basename(project)}',
    );
    final compiled = args['resolve-imports'] as bool
        ? await FlutterDomCompiler().compileProject(
            project,
            input.path,
            config,
            domOnly: args['dom-only'] as bool,
          )
        : FlutterDomCompiler().compile(
            input.readAsStringSync(),
            config,
            domOnly: args['dom-only'] as bool,
          );
    if (snapshot != null) {
      compiled.report['dataSnapshot'] = {
        'source': 'local-json',
        'references': snapshot.references,
      };
      stdout.writeln(
        '  Data input         Local JSON snapshot · ${snapshot.references} bindings',
      );
    }
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
          '--no-wasm-dry-run',
          '--pwa-strategy=none',
          '--target',
          generated.path,
          '--output',
          p.join(output.path, 'flutter'),
        ],
      ]) {
        stdout.writeln(
          '  ${command.first == 'pub' ? 'Resolve dependencies' : 'Compile Flutter island'}…',
        );
        final process = await Process.run(
          'flutter',
          command,
          workingDirectory: project,
        );
        final log = '${process.stdout}${process.stderr}';
        File(
          p.join(output.path, 'flutter-build.log'),
        ).writeAsStringSync(log, mode: FileMode.append);
        if (args['verbose'] as bool || process.exitCode != 0) stdout.write(log);
        if (process.exitCode != 0)
          throw CompileException(
            'Flutter island build failed. See flutter-build.log.',
          );
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
    for (final asset in compiled.report['assets'] as List<String>) {
      final original = File(p.join(project, asset));
      if (!original.existsSync() ||
          !p.isWithin(
            Directory(project).resolveSymbolicLinksSync(),
            original.resolveSymbolicLinksSync(),
          )) {
        throw CompileException('Asset missing or outside project: $asset');
      }
      final destination = File(p.join(output.path, asset));
      destination.parent.createSync(recursive: true);
      original.copySync(destination.path);
    }
    File(p.join(output.path, 'index.html')).writeAsStringSync(compiled.html);
    File(p.join(output.path, 'styles.css')).writeAsStringSync(_styles);
    if (((compiled.report['nativeFilterInstances'] as int) > 0 ||
        (compiled.report['nativeStateInstances'] as int) > 0)) {
      File(p.join(output.path, 'native.js')).writeAsStringSync(
        ((compiled.report['nativeFilterInstances'] as int) > 0
                ? _nativeAdapters
                : '') +
            ((compiled.report['nativeStateInstances'] as int) > 0
                ? compiled.nativeRuntime
                : ''),
      );
    }
    compiled.report['initialFilesBytesUncompressed'] = {
      for (final name in [
        'index.html',
        'styles.css',
        ...compiled.report['assets'] as List<String>,
        if (((compiled.report['nativeFilterInstances'] as int) > 0 ||
            (compiled.report['nativeStateInstances'] as int) > 0))
          'native.js',
        if (compiled.island != null) 'islands.js',
      ])
        name: File(p.join(output.path, name)).lengthSync(),
    };
    File(p.join(output.path, 'report.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(compiled.report),
    );
    final counts = compiled.report['widgets'] as Map<String, int>;
    final total = counts.values.fold(0, (sum, count) => sum + count);
    final native = total - (compiled.island == null ? 0 : 1);
    final sizes =
        compiled.report['initialFilesBytesUncompressed'] as Map<String, int>;
    final bytes = sizes.values.fold(0, (sum, size) => sum + size);
    stdout.writeln(
      '  ${_accent('✓ Built')}  ${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s',
    );
    stdout.writeln(
      '  Native boundaries  $native/$total (${total == 0 ? 'N/A' : (100 * native / total).toStringAsFixed(1)}%) · ${compiled.report['nativeAdapterInstances']} adapters · ${compiled.island == null ? 0 : 1} Flutter island',
    );
    if ((compiled.report['nativeStateInstances'] as int) > 0) {
      stdout.writeln(
        '  Native state       ${compiled.report['nativeStateInstances']} instance(s) · typed bindings · single build',
      );
    }
    if ((compiled.report['nativeCallbackRouteBridges'] as int? ?? 0) > 0) {
      stdout.writeln(
        '  Host navigation    ${compiled.report['nativeCallbackRouteBridges']} explicit route bridge(s) · ${compiled.report['nativeNavigationLinks']} native links',
      );
    }
    stdout.writeln(
      '  Initial files      ${(bytes / 1024).toStringAsFixed(1)} KiB (including images)',
    );
    stdout.writeln(
      '  Output             ${p.relative(output.path)}/index.html',
    );
    stdout.writeln(
      '  Counts stop at adapters/islands; not whole-app conversion.\n',
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
    ..addOption('source', defaultsTo: 'lib/main.dart')
    ..addFlag(
      'resolve-imports',
      negatable: false,
      help: 'Check roots in the resolved web library graph.',
    )
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
    final report = args['resolve-imports'] as bool
        ? await inspector.inspectResolved(
            args['project'] as String,
            source: args['source'] as String,
          )
        : inspector.inspect(args['project'] as String);
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
    final sites = report['callSites'] as Map<String, Object?>?;
    if (sites != null) {
      stdout.writeln(
        '${_accent('Widget roots')}: ${coverage['native']} native · '
        '${coverage['needsInputs']} need inputs · ${coverage['unsupported']} unsupported '
        '(${coverage['total']} checked).',
      );
      stdout.writeln(
        '${_accent('Constructor sites')}: ${sites['native']} native · '
        '${sites['needsContext']} need context · ${sites['unsupported']} unsupported '
        '(${sites['checked']}/${sites['total']} checked).',
      );
      if ((sites['skipped'] as int) > 0)
        stdout.writeln(
          '  ${sites['skipped']} sites skipped at the analysis limit.',
        );
      stdout.writeln(
        '  Isolated checks in the web library graph; not app conversion coverage.',
      );
      for (final site
          in (sites['entries'] as List)
              .where((e) => e['status'] == 'native')
              .take(3)) {
        stdout.writeln(
          '  ✓ ${site['file']}:${site['line']}:${site['column']} ${site['widget']}',
        );
      }
    } else {
      final score = coverage['percent'] as num?;
      stdout.writeln(
        '${_accent('Native entry compatibility')}: ${score?.toStringAsFixed(1) ?? 'N/A'}'
        '${score == null ? '' : '%'} (${coverage['native']}/${coverage['total']}).',
      );
      stdout.writeln('  Independent widget roots · adapters/islands excluded');
    }
    var shown = 0;
    for (final entry in coverage['entries'] as List) {
      if (entry['status'] == 'blocked' &&
          entry['category'] != 'needs-inputs' &&
          shown++ < 5)
        stdout.writeln(
          '  ${entry['file']}:${entry['line']} ${entry['widget']}: ${entry['blocker']}',
        );
    }
    if (shown > 5)
      stdout.writeln('  … ${shown - 5} more blockers in the report');
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
.dom-preview { padding:clamp(20px,5vw,64px); }
.dom-preview > p { color:#949aac; margin:12px 0 28px; }
.dom-preview-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(min(100%,200px),1fr)); gap:16px; }
.dom-preview-card:has(> .dom-card) { padding:0; border:0; }
.dom-preview-card > .dom-card { margin:0; height:100%; }
.dom-branch { display:contents; }
.dom-branch[hidden] { display:none; }
.dom-card { margin:4px; border-radius:12px; background:#f5f6fa; min-width:0; }
.theme-dark .dom-card { background:#23252d; }
.dom-preview-card { padding:24px; border:1px solid #353842; border-radius:18px; min-width:0; }

body { margin: 0; background: #faf9f6; color: #202422;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; }
main { max-width: 960px; margin: 0 auto; background: #fff; border-radius: 0;
  overflow: hidden; }
p, h1, h2, h3, h4, h5, h6 { margin: 0; white-space: pre-wrap; }
.island-shell { position: relative; width: 100%; border: 1px solid #dbe2ea;
  border-radius: 12px; overflow: hidden; background: #f4f6f9; }
#flutter-island { position: relative; width: 100%; overflow: hidden; }
.island-placeholder { position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 16px; padding: 24px; text-align: center; }
button { font: inherit; border: 0; border-radius: 8px; padding: 12px 20px;
  background: #165dcc; color: white; cursor: pointer; }
.dom-column:has(> .dom-row-max) { width:100%; }
.dom-list-tile p { margin:0; }
.dom-list-tile-title { font-weight:600; }
.dom-list-tile-subtitle { font-size:14px; opacity:.75; margin-top:4px; }
a.dom-list-tile { border-radius:8px; transition:background-color .12s; }
a.dom-list-tile:hover { background:rgba(128,128,128,.12); }
a.dom-list-tile:focus-visible { outline:2px solid currentColor; outline-offset:4px; }
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
img { display:block; border-radius:12px; width:100%; }
h1 { letter-spacing:-.045em; line-height:1.12; }
h2 { letter-spacing:-.025em; }
.table-scroll { max-width:100%; overflow-x:auto; }
table { border-collapse:collapse; width:100%; text-align:left; font-size:13px; }
th,td { padding:16px 18px; border-bottom:1px solid #e7e7e2; white-space:nowrap; }
th { font-size:11px; color:#68726c; text-transform:uppercase; letter-spacing:.06em; }
.responsive-grid { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:16px; }
.metric-card { background:#23252d; border:1px solid #353842; border-radius:18px; padding:20px; min-width:0; }
.metric-label { display:flex; align-items:center; gap:9px; color:#b5bacb; font-size:13px; }
.metric-label span { width:8px; height:8px; border-radius:50%; }
.metric-card h2 { margin:12px 0 2px; font-size:28px; }
.metric-period { font-size:11px; color:#949aac; }
.metric-card svg { display:block; width:100%; height:200px; margin-top:18px; }
.responsive-grid .metric-card svg { height:90px; }
.metric-card details { font-size:11px; color:#949aac; margin-top:10px; }
.metric-card summary { cursor:pointer; }
.chart-hit { outline:none; }
.chart-hit rect { opacity:0; }
.chart-hit text { opacity:0; fill:#fff; font-size:10px; pointer-events:none; }
.chart-hit:hover rect,.chart-hit:focus rect { opacity:.12; }
.chart-hit:hover text,.chart-hit:focus text { opacity:1; }
.chart-hit:focus rect { stroke:#aabafa; stroke-width:1; }
.theme-dark { background:#101116; color:#ebedf7; }
.theme-dark main { max-width:1320px; background:transparent; }
.theme-dark h1 { font-size:34px !important; }
.theme-dark th,.theme-dark td { border-color:#353842; }
@media(max-width:1050px) { .responsive-grid { grid-template-columns:repeat(2,minmax(0,1fr)); } }
@media(max-width:560px) { .responsive-grid { grid-template-columns:minmax(0,1fr); } }
@media (max-width: 600px) { main { margin: 0; } h1 { font-size:32px !important; } }

''';

String _accent(String value) =>
    stdout.supportsAnsiEscapes && !Platform.environment.containsKey('NO_COLOR')
    ? '\x1b[1;36m$value\x1b[0m'
    : value;
