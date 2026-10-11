import 'dart:convert';
import 'dart:io';

import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:html/parser.dart';
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
    'resolved function-field callbacks lower through explicit local routes',
    () async {
      final framework = File(
        p.join(directory.path, 'framework/lib/widgets.dart'),
      );
      write(
        'framework/lib/widgets.dart',
        framework.readAsStringSync() +
            '''
typedef ValueChanged<T> = void Function(T);
class InkWell extends Widget { const InkWell({void Function()? onTap, required Widget child}); }
''',
      );
      write('lib/main.dart', "import 'page.dart'; void main() {}\n");
      write('lib/page.dart', '''
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page({required this.onOpen}); final ValueChanged<String> onOpen;
 Widget build(BuildContext context) => InkWell(onTap: () => onOpen('mock'), child: Text('Open record'));
}
''');
      final result = await FlutterDomCompiler().compileProject(
        directory.path,
        p.join(directory.path, 'lib/main.dart'),
        {
          'root': 'Page',
          'arguments': {
            'onOpen': {
              'callback': 'open',
              'routes': {'mock': 'activities/mock/'},
            },
          },
        },
        domOnly: true,
      );
      expect(
        parse(result.html).querySelector('a')!.attributes['href'],
        'activities/mock/',
      );
      expect(result.report['nativeNavigationLinks'], 1);
      expect(result.report['nativeCallbackRouteBridges'], 1);
    },
  );

  test(
    'resolved dart:core calendar constructors preserve date field reads',
    () async {
      write('lib/page.dart', r'''
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) {
   final date = DateTime.utc(2024, 2, 29);
   return Text('${date.day}.${date.month}.${date.year}');
 }
}
''');
      final result = await compile();
      expect(result.html, contains('29.2.2024'));
      expect(result.report['staticDateValues'], 1);
    },
  );

  test(
    'resolved extension constants preserve imported enum map identity',
    () async {
      final framework = File(
        p.join(directory.path, 'framework/lib/widgets.dart'),
      );
      write(
        'framework/lib/widgets.dart',
        framework.readAsStringSync().replaceFirst(
              'const Text(String value)',
              'const Text(String value, {TextStyle? style})',
            ) +
            '''
abstract class ThemeExtension<T> { const ThemeExtension(); }
class Theme {
 static Theme of(BuildContext context) => Theme();
 T? extension<T>() => null;
}
class Color { const Color(int value); }
class TextStyle { const TextStyle({Color? color}); }
''',
      );
      write('lib/palette.dart', '''
import 'package:flutter/widgets.dart';
enum Slot { primary }
class Palette extends ThemeExtension<Palette> {
 const Palette({required this.slots}); final Map<Slot, Color> slots;
 static const dark = Palette(slots: {Slot.primary: Color(0xff3987e5)});
 Color operator [](Slot slot) => slots[slot]!;
 static Palette of(BuildContext context) => Theme.of(context).extension<Palette>()!;
}
''');
      write('lib/page.dart', '''
import 'package:flutter/widgets.dart'; import 'palette.dart' as a;
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text('Palette', style: TextStyle(color: a.Palette.of(context)[a.Slot.primary]));
}
''');
      final result = await FlutterDomCompiler().compileProject(
        directory.path,
        p.join(directory.path, 'lib/main.dart'),
        {
          'staticTheme': {
            'extensions': {
              'lib/palette.dart::Palette': 'lib/palette.dart::Palette.dark',
            },
          },
        },
        domOnly: true,
      );
      expect(result.html, contains('rgba(57,135,229,1.0)'));
      expect(result.report['staticThemeExtensionSnapshots'], 1);
    },
  );

  test(
    'imported static helpers and getters preserve resolved class identity',
    () async {
      write('lib/labels.dart', '''
abstract final class Labels {
 static const suffix = '!';
 static String get ending => suffix;
 static String format(String input) => input + ending;
}
''');
      write('lib/other.dart', '''
abstract final class Labels { static String format(String input) => 'Wrong'; }
''');
      write('lib/page.dart', '''
import 'package:flutter/widgets.dart';
import 'labels.dart' as a;
import 'other.dart' as b;
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Column(children: [Text(a.Labels.format('Record')), Text(a.Labels.ending), Text(b.Labels.format('Record'))]);
}
''');
      final result = await compile();
      expect(result.html, contains('Record!'));
      expect(result.html, contains('Wrong'));
      expect(result.report['pureHelperInvocations'], 2);
    },
  );

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
 Widget unsupported() { return Text('runtime'); }
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

  test('conditional exports choose web on a native compiler host', () async {
    write(
      'lib/page.dart',
      "export 'stub.dart' if (dart.library.html) 'web.dart';",
    );
    write('lib/stub.dart', 'class WrongPlatform {}');
    write('lib/web.dart', """
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text('Web selected');
}
""");
    final result = await compile();
    expect(result.html, contains('Web selected'));
    expect(result.report['sourceFiles'], isNot(contains('lib/stub.dart')));
    expect(result.report['analysisTarget'], 'web-js');
    expect(
      (result.report['conditionalDirectives'] as List)
          .single['selectedLibrary'],
      endsWith('/web.dart'),
    );
  });

  test(
    'conditional imports use first matching branch and preserve prefixed constants',
    () async {
      write('lib/page.dart', """
import 'package:flutter/widgets.dart';
import 'stub.dart' if (dart.library.io) 'native.dart'
 if (dart.library.js_interop == 'true') 'web.dart'
 if (dart.library.html) 'second.dart' as platform;
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text(platform.title);
}
""");
      write('lib/stub.dart', "const title = 'Stub';");
      write('lib/native.dart', "const title = 'Native';");
      write('lib/web.dart', "const title = 'First web match';");
      write('lib/second.dart', "const title = 'Wrong second match';");
      final result = await compile();
      expect(result.html, contains('First web match'));
      expect(result.report['sourceFiles'], isNot(contains('lib/native.dart')));
      expect(result.report['sourceFiles'], isNot(contains('lib/second.dart')));
    },
  );

  test(
    'false conditions retain the fallback and custom conditions fail explicitly',
    () async {
      const page = """
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text('Fallback');
}
""";
      write(
        'lib/page.dart',
        "export 'stub.dart' if (dart.library.io) 'native.dart';",
      );
      write('lib/stub.dart', page);
      write('lib/native.dart', 'class WrongPlatform {}');
      expect((await compile()).html, contains('Fallback'));
      write(
        'lib/page.dart',
        "export 'stub.dart' if (custom.flag) 'native.dart';",
      );
      await expectLater(
        compile(),
        throwsA(
          isA<CompileException>().having(
            (e) => e.message,
            'diagnostic',
            contains('Unsupported conditional-import variable custom.flag'),
          ),
        ),
      );
    },
  );
  test(
    'resolved inspection checks imported roots and does not invent constructor inputs',
    () async {
      write('lib/page.dart', """
import 'package:flutter/widgets.dart' as f;
import 'child.dart';
class Page extends f.StatelessWidget {
 const Page();
 f.Widget build(f.BuildContext context) => Child(label: 'Resolved content');
}
""");
      write('lib/child.dart', """
import 'package:flutter/widgets.dart';
class Child extends StatelessWidget {
 const Child({required this.label});
 final String label;
 Widget build(BuildContext context) => Text(label);
}
""");
      write('lib/unrelated.dart', """
import 'package:flutter/widgets.dart';
class Unrelated extends StatelessWidget {
 Widget build(BuildContext context) => Text('Outside entry graph');
}
""");
      final report = await ProjectInspector().inspectResolved(directory.path);
      final coverage = report['compatibility'] as Map;
      expect(report['schemaVersion'], 4);
      expect(report['analysisTarget'], 'web-js');
      expect(coverage['total'], 2);
      expect(coverage['native'], 1);
      expect(coverage['needsInputs'], 1);
      expect(coverage['unsupported'], 0);
      final sites = report['callSites'] as Map;
      expect(sites['native'], 2); // Page() and Child(label: literal).
      expect(sites['needsContext'], 0);
      expect(sites['unsupported'], 0);
      final entries = coverage['entries'] as List;
      expect(
        entries.singleWhere((e) => e['widget'] == 'Page')['status'],
        'native',
      );
      expect(
        entries.singleWhere((e) => e['widget'] == 'Child')['blocker'],
        contains('missing required argument label'),
      );
      expect(report['sourceFiles'], isNot(contains('lib/unrelated.dart')));
      expect(
        ProjectInspector().markdown(report),
        contains('Imports and constants are resolved'),
      );
    },
  );

  test(
    'inspection does not emit a score when project resolution fails',
    () async {
      write('lib/page.dart', "import 'missing.dart';");
      await expectLater(
        ProjectInspector().inspectResolved(directory.path),
        throwsA(isA<CompileException>()),
      );
    },
  );
  test(
    'call sites separate static arguments from enclosing runtime context',
    () async {
      write('lib/page.dart', """
import 'package:flutter/widgets.dart';
const title = 'Known';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Label(text: title);
}
class Label extends StatelessWidget {
 const Label({required this.text});
 final String text;
 Widget build(BuildContext context) => Text(text);
}
Widget makeLabel(String runtimeText) => Label(text: runtimeText);
""");
      final report = await ProjectInspector().inspectResolved(directory.path);
      final sites = report['callSites'] as Map;
      expect(sites['total'], 3);
      expect(sites['native'], 2);
      expect(sites['needsContext'], 1);
      final dynamic = (sites['entries'] as List).singleWhere(
        (e) => e['status'] == 'needs-context',
      );
      expect(dynamic['code'], 'requires-context');
      expect(dynamic['file'], 'lib/page.dart');
    },
  );

  test(
    'a selected web implementation can fail while its non-web fallback passes',
    () async {
      write(
        'lib/page.dart',
        "export 'stub.dart' if (dart.library.html) 'web.dart';",
      );
      write('lib/stub.dart', """
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text('Unavailable on this platform');
}
""");
      write('lib/web.dart', """
import 'package:flutter/widgets.dart';
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text(DateTime.now().toString());
}
""");
      final syntax = ProjectInspector().inspect(directory.path);
      final resolved = await ProjectInspector().inspectResolved(directory.path);
      expect((syntax['compatibility'] as Map)['native'], 1);
      expect((resolved['compatibility'] as Map)['native'], 0);
      expect(resolved['sourceFiles'], isNot(contains('lib/stub.dart')));
    },
  );
  test(
    'call-site limit reports skipped work without assigning it an outcome',
    () async {
      final calls = List.filled(1001, "Label(text: 'sample')").join(',');
      write('lib/page.dart', """
import 'package:flutter/widgets.dart';
const samples = [$calls];
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text('Page');
}
class Label extends StatelessWidget {
 const Label({required this.text});
 final String text;
 Widget build(BuildContext context) => Text(text);
}
""");
      final report = await ProjectInspector().inspectResolved(directory.path);
      final sites = report['callSites'] as Map;
      expect(sites['total'], 1002);
      expect(sites['checked'], 1000);
      expect(sites['skipped'], 2);
      expect(sites['native'], 1000);
      expect(sites['entries'], hasLength(1000));
    },
  );
  test(
    'imported models preserve constructor and annotated field identities',
    () async {
      write(
        'lib/main.dart',
        "import 'package:flutter/widgets.dart'; import 'page.dart'; void main() => runApp(Page());",
      );
      write(
        'lib/model.dart',
        "class Entry { const Entry(this.title); final String title; String format({String suffix = '!'}) => title + suffix; String get label => format(); }",
      );
      write(
        'lib/other.dart',
        "class Entry { const Entry(this.title); final String title; }",
      );
      write('lib/page.dart', """
import 'package:flutter/widgets.dart';
import 'model.dart' as m;
import 'other.dart' as o;
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Label(items: [m.Entry('Imported')]);
}
class Label extends StatelessWidget {
 const Label({required this.items}); final List<m.Entry> items;
 Widget build(BuildContext context) => Column(children: [for (final item in items) Text(item.label)]);
}
""");
      final result = await compile();
      expect(result.html, contains('Imported!'));
      final file = File(p.join(directory.path, 'lib/page.dart'));
      file.writeAsStringSync(
        file.readAsStringSync().replaceFirst(
          "m.Entry('Imported')",
          "o.Entry('Wrong')",
        ),
      );
      await expectLater(compile(), throwsA(isA<CompileException>()));
    },
  );
  test(
    'resolved static class constants preserve identity and forward references',
    () async {
      write('lib/page.dart', r"""
import 'package:flutter/widgets.dart';
import 'tokens.dart' as t;
class Page extends StatelessWidget {
 const Page();
 Widget build(BuildContext context) => Text('Gap ${t.Tokens.gap}');
}
""");
      write(
        'lib/tokens.dart',
        'abstract final class Tokens { static const gap = base * 2; static const base = 6; }',
      );
      expect((await compile()).html, contains('Gap 12'));
    },
  );
}
