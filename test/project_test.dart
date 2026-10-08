import 'dart:convert';
import 'dart:io';

import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory directory;
  void write(String path, String content) {
    final file = File(p.join(directory.path, path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  Future<Compilation> compile() => FlutterDomCompiler().compileProject(
    directory.path,
    p.join(directory.path, 'lib/main.dart'),
    {},
    domOnly: true,
  );

  setUp(() {
    directory = Directory.systemTemp.createTempSync('resolved-dom-');
    // Minimal framework declarations keep resolver tests independent of a Flutter SDK.
    // Real Flutter fixtures are exercised separately by the CLI/CI.
    write('framework/lib/widgets.dart', '''
class Widget { const Widget(); }
class BuildContext {}
abstract class StatelessWidget extends Widget {
 const StatelessWidget();
 Widget build(BuildContext context);
}
class Text extends Widget { const Text(String value); }
class Column extends Widget { const Column({required List<Widget> children}); }
void runApp(Widget widget) {}
''');
    write(
      '.dart_tool/package_config.json',
      jsonEncode({
        'configVersion': 2,
        'packages': [
          {
            'name': 'sample',
            'rootUri': '../',
            'packageUri': 'lib/',
            'languageVersion': '3.8',
          },
          {
            'name': 'flutter',
            'rootUri': '../framework/',
            'packageUri': 'lib/',
            'languageVersion': '3.8',
          },
        ],
      }),
    );
    write('lib/main.dart', '''
import 'package:flutter/widgets.dart';
import 'page.dart';
void main() => runApp(const Page());
''');
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    'imports, exports, prefixes and duplicate short names preserve identity',
    () async {
      write(
        'lib/main.dart',
        "import 'package:flutter/widgets.dart'; import 'page.dart' as pages; void main() => runApp(pages.Page());",
      );
      write('lib/page.dart', '''
import 'package:flutter/widgets.dart' as f;
import 'barrel.dart' as a;
import 'other.dart' as b;
class Page extends f.StatelessWidget {
 const Page();
 f.Widget build(f.BuildContext context) => f.Column(children: [a.Card(), b.Card(), f.Text(a.title)]);
}
''');
      write('lib/barrel.dart', "export 'card.dart' show Card, title;");
      write('lib/card.dart', '''
import 'package:flutter/widgets.dart';
const title = 'Imported constant';
class Card extends StatelessWidget {
 const Card();
 Widget build(BuildContext context) => Text('First');
}
''');
      write('lib/other.dart', '''
import 'package:flutter/widgets.dart';
class Card extends StatelessWidget {
 const Card();
 Widget build(BuildContext context) => Text('Second');
}
''');
      final output = await compile();
      expect(
        output.html,
        allOf(
          contains('First'),
          contains('Second'),
          contains('Imported constant'),
        ),
      );
      expect(output.report['analysis'], 'resolved project');
      expect(output.report['sourceFiles'], hasLength(5));
    },
  );

  test('package imports and library parts are resolved', () async {
    write('lib/page.dart', '''
import 'package:flutter/widgets.dart';
import 'package:sample/values.dart';
part 'body.dart';
''');
    write('lib/values.dart', "const title = 'From package';");
    write('lib/body.dart', '''
part of 'page.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text(title);
}
''');
    expect((await compile()).html, contains('From package'));
  });

  test('local Text is expanded, not mistaken for Flutter Text', () async {
    write('lib/page.dart', '''
import 'package:flutter/widgets.dart' as f;
class Page extends f.StatelessWidget {
 const Page();
 f.Widget build(f.BuildContext context) => Text();
}
class Text extends f.StatelessWidget {
 const Text();
 f.Widget build(f.BuildContext context) => f.Text('Local identity');
}
''');
    expect((await compile()).html, contains('Local identity'));
  });

  test(
    'imported unsupported widget diagnostic includes its source file',
    () async {
      write('lib/page.dart', '''
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => unsupported();
 Widget unsupported() => Text('runtime');
}
''');
      await expectLater(
        compile(),
        throwsA(
          isA<CompileException>().having(
            (e) => e.message,
            'location',
            contains('lib/page.dart:'),
          ),
        ),
      );
    },
  );

  test('missing imports fail resolution', () async {
    write('lib/page.dart', "import 'missing.dart';");
    await expectLater(compile(), throwsA(isA<CompileException>()));
  });

  test(
    'import cycles terminate and only reachable libraries are loaded',
    () async {
      write('lib/page.dart', '''
import 'package:flutter/widgets.dart';
import 'values.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text(title);
}
''');
      write('lib/values.dart', "import 'page.dart'; const title = 'Cycle';");
      write('lib/unrelated.dart', 'invalid dart');
      final result = await compile();
      expect(result.html, contains('Cycle'));
      expect(result.report['sourceFiles'], hasLength(3));
    },
  );
  test('ambiguous imports cannot select an arbitrary widget', () async {
    write(
      'lib/page.dart',
      "import 'one.dart'; import 'two.dart'; class Page { final value = Card(); }",
    );
    write('lib/one.dart', 'class Card {}');
    write('lib/two.dart', 'class Card {}');
    await expectLater(compile(), throwsA(isA<CompileException>()));
  });

  test(
    'a function named Text is not mistaken for a framework constructor',
    () async {
      write('lib/page.dart', """
import 'package:flutter/widgets.dart' as f;
f.Widget Text(String text) => f.Text('Different');
class Page extends f.StatelessWidget {
 const Page();
 f.Widget build(f.BuildContext context) => Text('Incorrect');
}
""");
      await expectLater(
        compile(),
        throwsA(
          isA<CompileException>().having(
            (e) => e.message,
            'diagnostic',
            contains('Function/method calls'),
          ),
        ),
      );
    },
  );
  test('private entry roots resolve in their own library', () async {
    write('lib/main.dart', """
import 'package:flutter/widgets.dart';
void main() => runApp(_Page());
class _Page extends StatelessWidget {
 Widget build(BuildContext context) => Text('Private root');
}
""");
    expect((await compile()).html, contains('Private root'));
  });

  test(
    'conditional imports fail explicitly instead of selecting the host branch',
    () async {
      write(
        'lib/page.dart',
        "export 'one.dart' if (dart.library.html) 'two.dart';",
      );
      const widget = """
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text('branch');
}
""";
      write('lib/one.dart', widget);
      write('lib/two.dart', widget);
      await expectLater(
        compile(),
        throwsA(
          isA<CompileException>().having(
            (e) => e.message,
            'diagnostic',
            contains('Conditional imports/exports'),
          ),
        ),
      );
    },
  );
}
