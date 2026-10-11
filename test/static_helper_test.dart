import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
abstract final class Labels {
 static const suffix = '!';
 static String get ending => suffix;
 static String format(String value, {int count = 2}) => repeat(value, count) + ending;
 static String repeat(String value, int count) => '$value/$count';
}
class Entry {
 const Entry({this.date}); final DateTime? date;
}
class Page extends StatelessWidget {
 String get suffix => 'caller';
 Widget build(BuildContext context) => Column(children: [
 Text(Labels.format('Record')), Text(Labels.ending),
 Text(Entry().date == null ? 'No date' : 'Has date')]);
}
''';
  test(
    'static helper parameters, defaults, constants and getters isolate caller scope',
    () {
      final result = compiler.compile(source, {'root': 'Page'});
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        'Record/2!',
        '!',
        'No date',
      ]);
      expect(result.report['pureHelperInvocations'], 2);
    },
  );
  test(
    'static helper mutations, async, recursion and caller capture fail closed',
    () {
      for (final input in [
        source.replaceFirst("repeat(value, count) + ending", "format(value)"),
        source.replaceFirst(
          "=> repeat(value, count) + ending;",
          "{ var mutable = value; return mutable; }",
        ),
        source.replaceFirst(
          "=> repeat(value, count) + ending;",
          "async => value;",
        ),
        source.replaceFirst("=> repeat(value, count) + ending;", "=> context;"),
        source.replaceFirst(
          "=> repeat(value, count) + ending;",
          "=> this.suffix;",
        ),
        source.replaceFirst("Labels.format('Record')", "Labels.format(42)"),
        source.replaceFirst("Entry()", "Entry(date: 'not a date')"),
        source.replaceFirst("DateTime? date", "DateTime date"),
      ]) {
        expect(
          () => compiler.compile(input, {'root': 'Page'}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
}
