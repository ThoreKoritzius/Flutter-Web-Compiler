import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';
import 'package:html/parser.dart';

const source = """
class Toggle extends StatefulWidget {
 const Toggle({super.key});
 State<Toggle> createState() => _ToggleState();
}
class _ToggleState extends State<Toggle> {
 bool expanded = false;
 Widget build(BuildContext context) => Column(children: [
   Text(expanded ? 'Expanded' : 'Collapsed'),
   TextButton(onPressed: () => setState(() => expanded = !expanded),
     child: Text(expanded ? 'Close' : 'Open')),
 ]);
}
""";

void main() {
  final compiler = FlutterDomCompiler();
  Compilation compile(String input) =>
      compiler.compile(input, {'root': 'Toggle'}, domOnly: true);

  test('boolean state emits one initial tree and targeted bindings', () {
    final result = compile(source);
    expect(result.report['nativeStateInstances'], 1);
    expect(result.report['nativeAdapterInstances'], 0);
    expect(result.island, isNull);
    final initial = parse(
      result.html,
    ).querySelector('[data-dom-view]')!.outerHtml;
    expect(initial, contains('Collapsed'));
    expect(initial, isNot(contains('Expanded')));
    expect(initial, contains('data-dom-action="0"'));
    expect(result.html, contains('data-dom-program='));
    expect(result.html, isNot(contains('<template')));
    expect(result.nativeRuntime, isNot(contains('replaceChildren')));
    expect(result.nativeRuntime, isNot(contains('.focus(')));
    expect(result.html, contains('native.js'));
    expect(result.nativeRuntime, isNot(contains('eval(')));
  });

  test('true initial value and literal assignment are preserved', () {
    final result = compile(
      source
          .replaceFirst('expanded = false', 'expanded = true')
          .replaceFirst('expanded = !expanded', 'expanded = false'),
    );
    expect(
      parse(result.html).querySelector('[data-dom-view]')!.text,
      contains('Expanded'),
    );
    expect(result.html, contains('&quot;literal&quot;,false'));
  });

  test('unsupported state behavior fails instead of being dropped', () {
    for (final input in [
      source.replaceFirst(
        "Text(expanded ? 'Expanded' : 'Collapsed')",
        "expanded ? Row(children: [Text('Expanded')]) : Text('Collapsed')",
      ),
      source.replaceFirst(
        "Text(expanded ? 'Expanded' : 'Collapsed')",
        "MaterialApp(home: Text('Content'), theme: expanded ? ThemeData.dark() : null)",
      ),
      source.replaceFirst('onPressed: () =>', 'onPressed: () async =>'),
      source.replaceFirst('setState(() =>', 'setState(() async =>'),
      source.replaceFirst('bool expanded = false;', 'int expanded = 0;'),
      source.replaceFirst(
        'bool expanded = false;',
        'bool expanded = false; void initState() {}',
      ),
      source.replaceFirst('expanded = !expanded', 'expanded = loadValue()'),
      source.replaceFirst(
        'setState(() => expanded = !expanded)',
        'print("ignored")',
      ),
      source.replaceFirst(
        'bool expanded = false;',
        'bool expanded = false; double other = 1.5;',
      ),
      source.replaceFirst(
        "Text(expanded ? 'Expanded' : 'Collapsed')",
        "expanded ? UnsupportedWidget() : Text('Collapsed')",
      ),
    ]) {
      expect(() => compile(input), throwsA(isA<CompileException>()));
    }
  });

  test('multiple instances have isolated owners', () {
    final result = compiler.compile(source, {
      'preview': [
        {'root': 'Toggle'},
        {'root': 'Toggle'},
      ],
    });
    expect(result.report['nativeStateInstances'], 2);
    expect(result.html, contains('data-dom-state="0"'));
    expect(result.html, contains('data-dom-state="1"'));
  });

  test('nested state and state-shadowing locals fail explicitly', () {
    expect(
      () => compile(
        source.replaceFirst(
          "Text(expanded ? 'Expanded' : 'Collapsed')",
          'Toggle()',
        ),
      ),
      throwsA(isA<CompileException>()),
    );
    expect(
      () => compile(
        source
            .replaceFirst(
              '=> Column(',
              "{ final expanded = true; return Column(",
            )
            .replaceFirst(']);', ']); }'),
      ),
      throwsA(isA<CompileException>()),
    );
  });
}
