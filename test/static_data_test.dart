import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

String page(String declarations, String body) =>
    '''
$declarations
class App extends StatelessWidget {
  Widget build(BuildContext context) => $body;
}
''';

void main() {
  final compiler = FlutterDomCompiler();
  test(
    'forward constants, collection branches and spreads compile together',
    () {
      final result = compiler.compile(
        page(
          '''
const title = later;
const later = 'Shared <title>';
const enabled = true;
const children = [Text(title)];
const absent = null;
''',
          '''Column(children: [
...children, ...?absent,
if (!enabled) UnsupportedWidget() else Text('Visible'),
if (enabled) ...[Text('Nested')]
])''',
        ),
        {},
      );
      expect(result.html, contains('Shared &lt;title&gt;'));
      expect(result.html, contains('Visible'));
      expect(result.html, contains('Nested'));
      expect(result.html, isNot(contains('UnsupportedWidget')));
    },
  );

  test('top-level constants cannot capture constructor fields', () {
    final source = page('''
const title = local;
class Child extends StatelessWidget {
  final String local;
  const Child({required this.local});
  Widget build(BuildContext context) => Text(title);
}
''', "Child(local: 'must not leak')");
    expect(
      () => compiler.compile(source, {}),
      throwsA(isA<CompileException>()),
    );
  });

  test(
    'constructor bindings shadow top-level names without altering constants',
    () {
      final source = page('''
const title = 'Global';
const alias = title;
class Child extends StatelessWidget {
  final String title;
  const Child({this.title = alias});
  Widget build(BuildContext context) => Text(title);
}
''', "Column(children: [Child(title: 'Local'), Child(), Text(alias)])");
      final html = compiler.compile(source, {}).html;
      expect(html, contains('Local'));
      expect('Global'.allMatches(html), hasLength(2));
    },
  );

  test(
    'cycles, runtime variables, bad spreads and conditions fail explicitly',
    () {
      for (final source in [
        page('const a = b; const b = a;', 'Text(a)'),
        page("final title = 'runtime';", 'Text(title)'),
        page('', 'Column(children: [if (true case false) Text("bad")])'),
        page('', 'Column(children: [...null])'),
        page('', 'Column(children: [...1])'),
        page('', 'Column(children: [if (1) Text("bad")])'),
        page('', 'Column(children: [for (final x in []) Text("bad")])'),
      ]) {
        expect(
          () => compiler.compile(source, {}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );

  test('expanding shared collections is bounded', () {
    final declarations = StringBuffer('const c0 = [Text("x")];');
    for (var i = 1; i < 17; i++) {
      declarations.write('const c$i = [...c${i - 1}, ...c${i - 1}];');
    }
    expect(
      () =>
          compiler.compile(page('$declarations', 'Column(children: c16)'), {}),
      throwsA(
        isA<CompileException>().having(
          (e) => e.message,
          'diagnostic',
          contains('size limit'),
        ),
      ),
    );
  });
}
