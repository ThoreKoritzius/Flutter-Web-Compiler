import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  String page(String expression) =>
      'class Page extends StatelessWidget { Widget build(BuildContext context) => Text("\${$expression}"); }';
  test(
    'bounded fold preserves seed, captured static locals and reducer parameter scope',
    () {
      const source =
          r'''class Entry { const Entry(this.minutes); final double minutes; }
class Page extends StatelessWidget { Widget build(BuildContext context) {
 final items=[Entry(20),Entry(65),Entry(12)]; final max=999; final offset=2;
 final peak=items.fold<double>(0,(max,item)=>item.minutes > max ? item.minutes : max);
 final sum=[1,2,3].fold<int>(0,(total,item)=>total+item+offset);
 return Column(children:[Text('$peak'),Text('$sum'),Text('$max')]);
} }''';
      final result = compiler.compile(source, {'root': 'Page'});
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        '65.0',
        '12',
        '999',
      ]);
      expect(
        compiler.compile(
          page('<int>[].fold<int>(7, (total,item)=>total+item)'),
          {'root': 'Page'},
        ).html,
        contains('7'),
      );
    },
  );
  test('explicit double reducer parameters use Dart numeric coercion', () {
    expect(
      compiler.compile(
        page(r"[1].fold<String>('', (String total, double item)=>'$item')"),
        {'root': 'Page'},
      ).html,
      contains('1.0'),
    );
  });
  test(
    'fold rejects mutations, async/block reducers, bad arguments and result types',
    () {
      for (final expression in [
        '[1,2].fold<int>(0,(total,item)=>total++)',
        '[1,2].fold<int>(0,(total,item) async =>total+item)',
        '[1,2].fold<int>(0,(total,item) { return total+item; })',
        '[1,2].fold<int>(0,(total)=>total)',
        '[1,2].fold<int>(0,(total,item)=>1.5)',
        '[1,2].fold<int>(0,(total,total)=>total)',
        '[1,2].fold<int>(0,(total,item)=>Text("bad"))',
      ]) {
        expect(
          () => compiler.compile(page(expression), {'root': 'Page'}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
  test('static clamp accepts finite ordered bounds and preserves type', () {
    expect(
      compiler.compile(page('(1.5).clamp(0.0,1.0)'), {'root': 'Page'}).html,
      contains('1.0'),
    );
    for (final expression in [
      '(1.5).clamp(2,1)',
      '(1.5).clamp(0)',
      '(1.5).clamp("x",1)',
    ]) {
      expect(
        () => compiler.compile(page(expression), {'root': 'Page'}),
        throwsA(isA<CompileException>()),
      );
    }
  });
  test('static fold rejects reducer results dependent on live state', () {
    const source =
        r"""class Page extends StatefulWidget { State<Page> createState()=>S(); }
class S extends State<Page> { int count=1; Widget build(BuildContext context) {
 final sum=[1,2].fold<int>(0,(total,item)=>total+count);
 return Text('$sum');
} }""";
    expect(
      () => compiler.compile(source, {'root': 'Page'}),
      throwsA(isA<CompileException>()),
    );
  });
}
