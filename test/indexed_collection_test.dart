import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Page extends StatelessWidget {
 Widget build(BuildContext context) {
  final items = ['Run', 'Walk', 'Ride'];
  final index = 99;
  return Column(children: [
   for (var index = 0; index < items.length; index++) ...[
    if (index > 0) Text('separator'), Text('$index: ${items[index]}'),
   ],
   Text('Outside $index'),
  ]);
 }
}
''';
  test(
    'indexed collection expands static rows and separators with isolated scope',
    () {
      final result = compiler.compile(source, {'root': 'Page'});
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        '0: Run',
        'separator',
        '1: Walk',
        'separator',
        '2: Ride',
        'Outside 99',
      ]);
      expect(result.report['nativeAdapterInstances'], 0);
    },
  );
  test(
    'prefix increments and nonzero starts work; empty collections terminate',
    () {
      final result = compiler.compile(
        source
            .replaceFirst('var index = 0', 'int index = 1')
            .replaceFirst('index++', '++index'),
        {'root': 'Page'},
      );
      expect(result.html, contains('1: Walk'));
      expect(result.html, isNot(contains('0: Run')));
      final empty = compiler.compile(
        source.replaceFirst("['Run', 'Walk', 'Ride']", '<String>[]'),
        {'root': 'Page'},
      );
      expect(parse(empty.html).querySelectorAll('p').map((p) => p.text), [
        'Outside 99',
      ]);
    },
  );
  test(
    'unsupported counters, runtime bounds and excessive expansion fail closed',
    () {
      for (final input in [
        source.replaceFirst('index++', 'index--'),
        source.replaceFirst('index++', 'index += 2'),
        source.replaceFirst('index++', 'other++'),
        source.replaceFirst('index < items.length', 'index <= items.length'),
        source.replaceFirst('var index = 0', 'final index = 0'),
        source.replaceFirst('var index = 0', 'var index = -1'),
        source.replaceFirst('var index = 0', 'double index = 0'),
        source.replaceFirst('items.length; index++', 'index + 2; index++'),
        source.replaceFirst(
          'items.length; index++',
          '(index == 2 ? 5 : 3); index++',
        ),
        source.replaceFirst('items.length; index++', '20001; index++'),
        source.replaceFirst('items.length; index++', 'missing; index++'),
      ]) {
        expect(
          () => compiler.compile(input, {'root': 'Page'}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
  test(
    'reactive bounds and counter mutation are not lowered as static loops',
    () {
      const reactive = r"""
class Page extends StatefulWidget { const Page(); State<Page> createState() => S(); }
class S extends State<Page> {
 int count = 3;
 Widget build(BuildContext context) => Column(children: [for (var i = 0; i < count; i++) Text('$i')]);
}
""";
      expect(
        () => compiler.compile(reactive, {'root': 'Page'}),
        throwsA(isA<CompileException>()),
      );
      expect(
        () => compiler.compile(
          source.replaceFirst("Text('separator')", r"Text('${index++}')"),
          {'root': 'Page'},
        ),
        throwsA(isA<CompileException>()),
      );
    },
  );
}
