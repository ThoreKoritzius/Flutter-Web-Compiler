import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Entry {
 const Entry(this.title); final String title;
 String label({String suffix = '!'}) => title + suffix;
 String get display => label();
}
class Page extends StatelessWidget {
 const Page({this.title = 'field'}); final String title;
 String decorate(String title, {int count = 2}) => '$title/$count';
 String readField() => title;
 Widget row(Entry entry) => Text(entry.label(suffix: '?'));
 Widget build(BuildContext context) {
   final title = 'local';
   return Column(children: [Text(decorate(title)), Text(readField()), row(Entry('Record')), Text(Entry('Getter').display)]);
 }
}
''';
  test(
    'model and widget helpers bind parameters/defaults in isolated instance scope',
    () {
      final result = compiler.compile(source, {'root': 'Page'});
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        'local/2',
        'field',
        'Record?',
        'Getter!',
      ]);
      expect(result.report['pureHelperInvocations'], 5);
      expect(result.report['nativeAdapterInstances'], 0);
    },
  );
  test(
    'pure state helpers lower reactive scalar expressions and widget rows',
    () {
      final result = compiler.compile(
        r'''
class Page extends StatefulWidget { const Page(); State<Page> createState() => S(); }
class S extends State<Page> {
 int count = 1;
 String label(int value) => 'Count ${value * 2}';
 Widget row(String title) => Text(title);
 Widget build(BuildContext context) => Column(children: [row(label(count)), TextButton(onPressed: () => setState(() => count++), child: Text('Add'))]);
}
''',
        {'root': 'Page'},
      );
      expect(result.html, contains('Count 2'));
      expect(result.html, contains('data-dom-text'));
      expect(result.report['pureHelperInvocations'], 2);
    },
  );
  test(
    'unsafe helper operations, recursion and argument mismatches fail closed',
    () {
      for (final input in [
        source.replaceFirst(
          'String readField() => title;',
          'String readField() => readField();',
        ),
        source.replaceFirst(
          'String readField() => title;',
          'String readField() => decorate(readField());',
        ),
        source.replaceFirst(
          'String readField() => title;',
          "String readField() { var value = title; return value; }",
        ),
        source.replaceFirst(
          'String readField() => title;',
          "String readField() async => title;",
        ),
        source.replaceFirst(
          'String readField() => title;',
          "String readField() => title = 'changed';",
        ),
        source.replaceFirst(
          'String readField() => title;',
          'String readField() => missingCallerLocal;',
        ),
        source.replaceFirst('decorate(title)', 'decorate()'),
        source.replaceFirst('decorate(title)', 'decorate(title, nope: 2)'),
        source.replaceFirst('decorate(title)', 'decorate(42)'),
        source.replaceFirst("row(Entry('Record'))", "row('wrong model')"),
        source.replaceFirst(
          "String readField() => title;",
          "String readField() => decorate(title, count: 'wrong');",
        ),
        source.replaceFirst(
          "String label({String suffix = '!'})",
          "String label<T>({String suffix = '!'})",
        ),
      ]) {
        expect(
          () => compiler.compile(input, {'root': 'Page'}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
}
