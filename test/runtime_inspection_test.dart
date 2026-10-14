import 'dart:convert';
import 'dart:io';

import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory directory;
  void write(String path, String content) => (File(
    p.join(directory.path, path),
  )..createSync(recursive: true)).writeAsStringSync(content);

  // A package configuration with the compiler's packages plus synthetic
  // path packages under deps/, laid out as pub would.
  void packages(List<String> names) {
    final compilerConfig =
        jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
            as Map<String, Object?>;
    write(
      '.dart_tool/package_config.json',
      jsonEncode({
        ...compilerConfig,
        'packages': [
          for (final entry
              in (compilerConfig['packages'] as List)
                  .cast<Map<String, Object?>>())
            {
              ...entry,
              'rootUri': Directory.current.uri
                  .resolve('.dart_tool/')
                  .resolve(entry['rootUri'] as String)
                  .toString(),
            },
          for (final name in names)
            {
              'name': name,
              'rootUri': '../deps/$name',
              'packageUri': 'lib/',
              'languageVersion': '3.6',
            },
          {
            'name': 'sample_app',
            'rootUri': '../',
            'packageUri': 'lib/',
            'languageVersion': '3.6',
          },
        ],
      }),
    );
  }

  setUp(() {
    directory = Directory.systemTemp.createTempSync('dom-runtime-inspect-');
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    'separates original libraries, replacements, rewritten packages and blockers',
    () async {
      packages(['plain_text', 'badge_kit', 'paint_kit']);
      write('deps/plain_text/lib/plain_text.dart', '''
String shout(String value) => value.toUpperCase();
''');
      write('deps/badge_kit/lib/badge_kit.dart', '''
import 'package:flutter/material.dart';
import 'package:plain_text/plain_text.dart';
class Badge extends StatelessWidget {
  const Badge(this.label);
  final String label;
  Widget build(BuildContext context) => Text(shout(label));
}
''');
      write('deps/paint_kit/lib/paint_kit.dart', "export 'src/box.dart';\n");
      write('deps/paint_kit/lib/src/box.dart', '''
import 'package:flutter/physics.dart';
class Box extends RenderProxyBox {}
''');
      write('lib/main.dart', '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_app/screens/home.dart';
void main() => runApp(MaterialApp.router(
  routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (c, s) => const Home(title: 'Hi'))]),
));
''');
      write('lib/screens/home.dart', '''
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badge_kit/badge_kit.dart';
import 'package:paint_kit/paint_kit.dart';
import 'storage.dart';
class Home extends StatefulWidget {
  const Home({required this.title});
  final String title;
  State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  Widget build(BuildContext context) => Badge(widget.title);
}
''');
      write('lib/screens/storage.dart', '''
import 'dart:io';
String read() => File('data').readAsStringSync();
''');

      final report = await inspectDartRuntime(directory.path);
      expect(report['target'], 'dart-runtime');
      expect(report['packageConfiguration'], 'project');
      expect(report['status'], 'blocked');

      final original = report['original'] as List;
      expect(original.map((e) => e['library']), [
        'lib/main.dart',
        'lib/screens/home.dart',
        'lib/screens/storage.dart',
      ]);
      expect(original[1]['status'], 'original');
      expect(original[1]['widgets'], ['Home']);

      final replacements = {
        for (final item in report['replacements'] as List) item['import']: item,
      };
      expect(
        replacements['package:go_router/go_router.dart']['kind'],
        'built-in-bridge',
      );
      expect(
        replacements['package:go_router/go_router.dart']['bridge'],
        'go_router',
      );
      expect(
        replacements['package:url_launcher/url_launcher.dart']['importedBy'],
        ['lib/screens/home.dart'],
      );
      expect(
        replacements['package:flutter/material.dart']['kind'],
        'flutter-facade',
      );

      expect(report['rewrittenPackages'], {
        'badge_kit': ['package:badge_kit/badge_kit.dart'],
        'paint_kit': [
          'package:paint_kit/paint_kit.dart',
          'package:paint_kit/src/box.dart',
        ],
      });
      expect(report['purePackages'], ['plain_text']);

      final unsupported = report['unsupported'] as List;
      final blocker = unsupported.singleWhere(
        (e) => e['severity'] == 'blocking',
      );
      expect(blocker['feature'], 'package:flutter/physics.dart');
      expect(blocker['library'], 'package:paint_kit/src/box.dart');
      expect(blocker['line'], 1);
      expect(blocker['chain'], [
        'lib/main.dart',
        'lib/screens/home.dart',
        'package:paint_kit/paint_kit.dart',
        'package:paint_kit/src/box.dart',
        'package:flutter/physics.dart',
      ]);
      final risk = unsupported.singleWhere(
        (e) => e['severity'] == 'runtime-risk',
      );
      expect(risk['feature'], 'dart:io');
      expect(risk['library'], 'lib/screens/storage.dart');

      final libraries = {
        for (final item in report['libraries'] as List) item['library']: item,
      };
      expect(libraries['package:paint_kit/src/box.dart']['status'], 'blocked');
      expect(
        libraries['package:badge_kit/badge_kit.dart']['status'],
        'rewritten-package',
      );

      final summary = report['summary'] as Map;
      expect(summary['originalLibraries'], 3);
      expect(summary['originalWidgets'], 1);
      expect(summary['builtInBridges'], 2);
      expect(summary['rewrittenPackages'], 2);
      expect(summary['blockingImports'], 1);
      expect(summary['runtimeRisks'], 1);
      expect((report['compile'] as Map)['attempted'], false);
      expect((report['notes'] as List).first, contains('SEO'));

      // The same project scored by the static HTML compiler: the stateful
      // screen fails there although its graph is explained above.
      final inspector = ProjectInspector();
      final combined = inspector.inspect(directory.path)
        ..['domRuntime'] = {'measured': true, ...report};
      final markdown = inspector.markdown(combined);
      expect(markdown, contains(staticCompatibilityLabel));
      expect(markdown, contains('Not whole-app coverage'));
      expect(markdown, contains('### Original components'));
      expect(markdown, contains('### Replacements'));
      expect(markdown, contains('### Unsupported features'));
      expect(
        markdown,
        contains(
          'lib/main.dart → lib/screens/home.dart → package:paint_kit/paint_kit.dart',
        ),
      );
      expect(markdown, contains('no SEO'));
      final home = ((combined['compatibility'] as Map)['entries'] as List)
          .singleWhere((e) => e['widget'] == 'Home');
      expect(home['category'], 'needs-inputs');
    },
  );

  test(
    'library bridges, unknown conditions and missing packages are attributed',
    () async {
      packages([]);
      write('lib/main.dart', '''
import 'package:flutter/widgets.dart';
import 'api.dart';
import 'config.dart' if (app.flavor) 'other.dart';
import 'package:absent_pkg/absent_pkg.dart';
void main() => runApp(const SizedBox());
''');
      write('lib/api.dart', "import 'package:flutter/cupertino.dart';\n");
      write('lib/config.dart', '');
      write('bridges/api.dart', "String endpoint() => '/api';\n");

      final report = await inspectDartRuntime(
        directory.path,
        libraryBridges: {
          'lib/api.dart': p.join(directory.path, 'bridges/api.dart'),
        },
      );
      final libraries = {
        for (final item in report['libraries'] as List) item['library']: item,
      };
      // The bridge implementation replaces the unsupported original import.
      expect(libraries['lib/api.dart']['status'], 'replaced-by-library-bridge');
      final bridge = (report['replacements'] as List).singleWhere(
        (e) => e['kind'] == 'library-bridge',
      );
      expect(bridge['import'], 'lib/api.dart');
      expect(bridge['bridge'], 'bridges/api.dart');
      final features = [
        for (final item in report['unsupported'] as List) item['feature'],
      ];
      expect(features, [
        'if (app.flavor)',
        'package:absent_pkg/absent_pkg.dart',
      ]);
      expect(
        (report['unsupported'] as List).last['reason'],
        contains('not in the package configuration'),
      );
    },
  );

  test('a graph with runtime paths for every import is graph-ready', () async {
    write('lib/main.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
void main() => runApp(const MaterialApp(home: Markdown(data: '# Hi')));
''');
    final report = await inspectDartRuntime(directory.path);
    expect(report['status'], 'graph-ready');
    expect(report['packageConfiguration'], 'compiler-fallback');
    expect(
      (report['replacements'] as List).map((e) => e['bridge']),
      containsAll(['flutter_markdown', 'flutter_dom runtime']),
    );
  });

  test('compiler errors map temporary paths back to source paths', () {
    final errors = compileErrors('''
Official Dart compilation failed:
/tmp/flutter-dom-runtime-AbC123/source/lib/main.dart:4:12:
Error: Method not found: 'Stepper'.
  Stepper(),
/tmp/flutter-dom-runtime-AbC123/packages/paint_kit/src/box.dart:2:20:
Error: Type 'RenderProxyBox' not found.
''');
    expect(errors, [
      {
        'location': 'lib/main.dart:4:12',
        'message': "Method not found: 'Stepper'.",
      },
      {
        'location': 'package:paint_kit/src/box.dart:2:20',
        'message': "Type 'RenderProxyBox' not found.",
      },
    ]);
    expect(
      compileErrors(
        'Bad state: Unsupported conditional environment',
      ).single['message'],
      contains('Unsupported conditional environment'),
    );
  });

  test('bridge tables cover every package URI the runtime builder handles', () {
    // Library URIs the builder substitutes, excluding its own imports.
    final builder = File('lib/native_app_builder.dart')
        .readAsLinesSync()
        .where(
          (line) => !line.startsWith('import ') && !line.startsWith('export '),
        )
        .join('\n');
    final uris = RegExp(r"'(package:[\w/.]+\.dart)'")
        .allMatches(builder)
        .map((m) => m[1]!)
        .where(
          (uri) =>
              !uri.startsWith('package:flutter_dom_compiler/') &&
              uri != 'package:meta/meta.dart',
        )
        .toSet();
    final known = {...runtimeBuiltInBridges.keys, ...runtimeFrameworkFacades};
    expect(
      uris.difference(known),
      isEmpty,
      reason:
          'Add new builder bridges/facades to lib/src/runtime_inspection.dart.',
    );
  });

  test(
    'opt-in compile reports the first official compiler errors',
    () async {
      write('lib/main.dart', '''
import 'package:flutter/material.dart';
void main() => runApp(const MissingWidget());
''');
      final report = await inspectDartRuntime(directory.path, compile: true);
      expect(report['status'], 'graph-ready');
      final compile = report['compile'] as Map;
      expect(compile['attempted'], true);
      expect(compile['succeeded'], false);
      final first = (compile['errors'] as List).first as Map;
      expect(first['location'], startsWith('lib/main.dart:2:'));
      expect(first['message'], contains('MissingWidget'));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
