import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Item {
 const Item({required this.key, this.value}); final String key; final int? value;
 static Item fromJson(Map<String, dynamic> map) { throw Exception('Must never execute'); }
 bool get present => value != null;
}
class Panel extends StatelessWidget {
 const Panel({required this.item, required this.onOpen}); final Item item; final VoidCallback onOpen;
 Widget build(BuildContext context) {
   final v = 'Outer';
   return Column(children: [
     if (item.value case final v?) Text('$v') else Text('Absent'),
     if ([item.key] case final values when values.isNotEmpty) Text(values.join(',')),
     Text(v), Text(item.present ? 'Present' : 'Missing'),
   ]);
 }
}
''';
  Map<String, dynamic> options(int? value) => {
    'root': 'Panel',
    'arguments': {
      'item': {
        'model': 'Item',
        'arguments': {'key': 'Sample', 'value': value},
      },
      'onOpen': {'callback': 'open'},
    },
  };
  test(
    'nullable and guarded final bindings isolate scope and use original model getter',
    () {
      for (final value in [null, 42]) {
        final result = compiler.compile(source, options(value));
        expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
          value == null ? 'Absent' : '42',
          'Sample',
          'Outer',
          value == null ? 'Missing' : 'Present',
        ]);
        expect(result.report['externalCallbackInputs'], 1);
        expect(result.report['nativeAdapterInstances'], 0);
      }
    },
  );
  test(
    'unreachable static serializers remain declarations; calls and external events fail',
    () {
      for (final input in [
        source.replaceFirst("Text(v)", r"Text('${onOpen()}')"),
        source.replaceFirst("Text(v)", r"Text('${Item.fromJson({})}')"),
        source.replaceFirst('final v?', 'var v?'),
        source.replaceFirst('final v?', 'final int v?'),
        source.replaceFirst('values.isNotEmpty', 'values.length'),
        source.replaceFirst('Text(v)', 'Text(values.join())'),
      ]) {
        expect(
          () => compiler.compile(input, options(42)),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
  test('restricted Align preserves child and rejects unsupported alignment', () {
    const input =
        "class Panel extends StatelessWidget { Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft, child: Text('Ready')); }";
    final result = compiler.compile(input, {'root': 'Panel'});
    expect(result.html, contains('justify-content:flex-start'));
    expect(parse(result.html).querySelector('p')!.text, 'Ready');
    expect(
      () => compiler.compile(
        input.replaceFirst('Alignment.centerLeft', 'Alignment.topLeft'),
        {'root': 'Panel'},
      ),
      throwsA(isA<CompileException>()),
    );
  });
}
