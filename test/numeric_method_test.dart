import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  String page(String expression) =>
      'class Page extends StatelessWidget { Widget build(BuildContext context) => Text($expression); }';
  test(
    'static numeric methods preserve Dart rounding and precision semantics',
    () {
      for (final entry in <String, String>{
        '(2.5).round().toStringAsFixed(0)': '3',
        '(-2.5).round().toStringAsFixed(0)': '-3',
        '(-2.2).floor().toStringAsFixed(0)': '-3',
        '(-2.2).ceil().toStringAsFixed(0)': '-2',
        '(-2.9).truncate().toStringAsFixed(0)': '-2',
        '(5000 / 1000).toStringAsFixed(1)': '5.0',
      }.entries) {
        expect(
          parse(
            compiler.compile(page(entry.key), {'root': 'Page'}).html,
          ).querySelector('p')!.text,
          entry.value,
        );
      }
    },
  );
  test('local model helpers named round retain original helper dispatch', () {
    const source =
        "class Meter { const Meter(); String round() => 'Original'; } class Page extends StatelessWidget { Widget build(BuildContext context) => Text(Meter().round()); }";
    expect(
      compiler.compile(source, {'root': 'Page'}).html,
      contains('Original'),
    );
  });
  test(
    'invalid numeric method arguments and excessive integer range fail closed',
    () {
      for (final expression in [
        "'x'.round()",
        '(2.5).round(1)',
        '(2.5).toStringAsFixed(-1)',
        '(2.5).toStringAsFixed(21)',
        '(2.5).toStringAsFixed(1.5)',
        '(2.5).toStringAsFixed(digits: 1)',
        '(1e20).round()',
      ]) {
        expect(
          () => compiler.compile(page(expression), {'root': 'Page'}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
  test('reactive numeric method calls remain unsupported', () {
    const source =
        r'''class Page extends StatefulWidget { State<Page> createState()=>S(); } class S extends State<Page> { int count=1; Widget build(BuildContext context)=>Text(count.toStringAsFixed(0)); }''';
    expect(
      () => compiler.compile(source, {'root': 'Page'}),
      throwsA(isA<CompileException>()),
    );
  });
}
