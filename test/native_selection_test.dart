import 'dart:io';
import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:flutter_dom_compiler/src/runtime/source_selection.dart';
import 'package:test/test.dart';

void main() {
  test(
    'explicit selection retains dependency bodies, drops unrelated imports/exports',
    () {
      const source = """
import 'package:flutter/material.dart';
import 'unsupported.dart';
export 'unsupported.dart';
const spacing = 10.0;
class Grid { double width() => spacing; }
class Card { final Grid grid = Grid(); }
class Unrelated { Unknown broken = Unknown(); }
""";
      final result = selectNativeSource(
        source,
        const NativeSourceSelection(
          declarations: ['Card'],
          imports: ['package:flutter/material.dart'],
        ),
      );
      expect(result, contains('class Card { final Grid grid = Grid(); }'));
      expect(result, contains('class Grid { double width() => spacing; }'));
      expect(result, contains('const spacing = 10.0;'));
      expect(result, isNot(contains('unsupported.dart')));
      expect(result, isNot(contains('class Unrelated')));
    },
  );
  test('ambiguous library forms and invalid selections fail explicitly', () {
    const selected = NativeSourceSelection(declarations: ['Card'], imports: []);
    for (final source in [
      "part 'other.dart'; class Card {}",
      'class Card {} extension Extra on Card {}',
      "import 'a.dart' if (dart.library.io) 'b.dart'; class Card {}",
    ]) {
      expect(
        () => selectNativeSource(source, selected),
        throwsUnsupportedError,
      );
    }
    expect(
      () => selectNativeSource('class Other {}', selected),
      throwsArgumentError,
    );
    expect(
      () => selectNativeSource(
        'class Card {}',
        const NativeSourceSelection(
          declarations: ['Card'],
          imports: ['missing.dart'],
        ),
      ),
      throwsArgumentError,
    );
  });
  test(
    'official compiler checks selected original bodies and reports selection',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'native-selection-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(
        "import 'package:flutter/material.dart'; import 'components.dart'; void main() => runApp(const Panel());",
      );
      File('${directory.path}/lib/components.dart').writeAsStringSync(
        "import 'package:flutter/material.dart'; class Panel extends StatelessWidget { const Panel(); Widget build(BuildContext context) => const Text('Original'); } class Unsupported { Missing value = Missing(); }",
      );
      const selection = NativeSourceSelection(
        declarations: ['Panel'],
        imports: ['package:flutter/material.dart'],
      );
      final app = await buildNativeApp(
        directory.path,
        'lib/main.dart',
        sourceSelections: {'lib/components.dart': selection},
      );
      expect(app.sourceSelections.keys, ['lib/components.dart']);
      expect(app.libraryAdapters, isEmpty);
      expect(app.javascript, contains('Original'));
      await expectLater(
        buildNativeApp(directory.path, 'lib/main.dart'),
        throwsStateError,
      );
      await expectLater(
        buildNativeApp(
          directory.path,
          'lib/main.dart',
          sourceSelections: {'../outside.dart': selection},
        ),
        throwsArgumentError,
      );
      await expectLater(
        buildNativeApp(
          directory.path,
          'lib/main.dart',
          sourceSelections: {'lib/components.dart': selection},
          libraryBridges: {
            'lib/components.dart': '${directory.path}/lib/components.dart',
          },
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'selected private widgets and metadata are exposed without rewriting bodies',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-expose-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(
        "import 'package:flutter/material.dart'; import 'components.dart'; void main()=>runApp(PublicPanel(label:entries.first.text));",
      );
      const source = r"""
import 'package:flutter/material.dart';
const _entries = [_Entry('Original')];
class _Entry { const _Entry(this.text); final String text; }
class _Panel extends StatelessWidget {
 const _Panel({required this.label}); final String label;
 Widget build(BuildContext context)=>Column(children:[Text(label),const _Badge()]);
}
class _Badge extends StatelessWidget {
 const _Badge(); Widget build(BuildContext context)=>const Text(' retained helper');
}
class Unused { Missing value=Missing(); }
""";
      File('${directory.path}/lib/components.dart').writeAsStringSync(source);
      const selection = NativeSourceSelection(
        declarations: ['_Panel'],
        imports: ['package:flutter/material.dart'],
        expose: {'PublicPanel': '_Panel', 'entries': '_entries'},
      );
      final selected = selectNativeSource(source, selection);
      expect(selected, contains('class _Badge extends StatelessWidget'));
      expect(selected, contains('const _entries = [_Entry(\'Original\')];'));
      expect(selected, isNot(contains('class Unused')));
      final app = await buildNativeApp(
        directory.path,
        'lib/main.dart',
        sourceSelections: {'lib/components.dart': selection},
      );
      expect(
        app.sourceSelections['lib/components.dart']!.expose,
        selection.expose,
      );
      final js = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final result = await Process.run('node', [
        '-e',
        "const {install,label}=require('./tool/browser/dom_shim.cjs');const {host}=install();require(process.argv[1]);if(label(host)!=='Original retained helper')throw Error(label(host));",
        js.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    },
  );
  test('invalid or colliding exposed aliases are rejected', () {
    for (final aliases in <Map<String, String>>[
      {'_hidden': '_Panel'},
      {'_Panel': '_Panel'},
      {'Public': 'Missing'},
      {'class': '_Panel'},
      {'Public': 'helper'},
    ]) {
      expect(
        () => selectNativeSource(
          'class _Panel {} void helper() {}',
          NativeSourceSelection(
            declarations: ['_Panel'],
            imports: [],
            expose: aliases,
          ),
        ),
        throwsA(anyOf(isA<ArgumentError>(), isA<UnsupportedError>())),
      );
    }
  });
}
