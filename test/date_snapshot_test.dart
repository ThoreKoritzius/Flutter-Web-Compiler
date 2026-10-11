import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Entry {
 const Entry({this.date}); final DateTime? date;
 String get label => date == null ? 'Missing' : '${date!.day}.${date!.month}.${date!.year}';
}
class Page extends StatelessWidget {
 const Page({required this.entry}); final Entry entry;
 Widget build(BuildContext context) => Column(children: [
 Text(entry.label),
 if (entry.date case final date?) Text('${date.day}.${date.month}.${date.year}'),
 Text('${DateTime.utc(2024, 2, 29).day}'),
 ]);
}
''';
  Map<String, dynamic> config(Object? date) => {
    'root': 'Page',
    'arguments': {
      'entry': {
        'model': 'Entry',
        'arguments': {'date': date},
      },
    },
  };
  test(
    'calendar snapshots drive original model getters and nullable date patterns',
    () {
      final result = compiler.compile(source, config({'date': '2024-02-29'}));
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        '29.2.2024',
        '29.2.2024',
        '29',
      ]);
      expect(result.report['staticDateValues'], 2);
      final missing = compiler.compile(source, config(null));
      expect(parse(missing.html).querySelectorAll('p').map((p) => p.text), [
        'Missing',
        '29',
      ]);
    },
  );
  test(
    'invalid or ambiguous date inputs and unsupported temporal operations fail',
    () {
      for (final date in [
        '2023-02-29',
        '2024-13-01',
        '0000-01-01',
        '2024-01-00',
        '2024-2-01',
        '2024-01-01T00:00:00Z',
      ]) {
        expect(
          () => compiler.compile(source, config({'date': date})),
          throwsA(isA<CompileException>()),
        );
      }
      expect(
        () => compiler.compile(source, config('2024-02-29')),
        throwsA(isA<CompileException>()),
      );
      for (final constructor in [
        'DateTime.now()',
        'DateTime(2024, 2, 30)',
        'DateTime.utc(2024, 2, 29, 12)',
        'DateTime.parse("2024-02-29")',
      ]) {
        expect(
          () => compiler.compile(
            source.replaceFirst('DateTime.utc(2024, 2, 29)', constructor),
            config(null),
          ),
          throwsA(isA<CompileException>()),
        );
      }
      expect(
        () => compiler.compile(
          source.replaceFirst('date!.day', 'date!.hour'),
          config({'date': '2024-02-29'}),
        ),
        throwsA(isA<CompileException>()),
      );
    },
  );
}
