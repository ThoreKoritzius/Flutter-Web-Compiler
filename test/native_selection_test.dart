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
}
