import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''class Entry { const Entry(this.id); final String id; }
 class Other { const Other(this.id); final String id; }
 class Page extends StatelessWidget {
 const Page({required this.onOpen}); final ValueChanged<Entry> onOpen;
 Widget build(BuildContext context)=>InkWell(onTap:()=>onOpen(Entry('one')), child:Text('Open'));
 }''';
  Map<String, dynamic> config(Map<String, dynamic> selector) => {
    'root': 'Page',
    'arguments': {
      'onOpen': {
        'callback': 'open',
        'routes': {'one': 'items/one/'},
        'argument': selector,
      },
    },
  };
  test(
    'explicit immutable model ID selectors lower callbacks to native links',
    () {
      final result = compiler.compile(
        source,
        config({'model': 'Entry', 'field': 'id'}),
      );
      expect(
        parse(result.html).querySelector('a')!.attributes['href'],
        'items/one/',
      );
      expect(result.report['nativeCallbackRouteBridges'], 1);
      expect(result.report['nativeNavigationLinks'], 1);
    },
  );
  test(
    'model identity, missing fields and nullable field selectors fail closed',
    () {
      for (final selector in [
        {'model': 'Other', 'field': 'id'},
        {'model': 'Entry', 'field': 'missing'},
        {'model': 'Entry', 'field': 'id', 'extra': 'x'},
      ]) {
        expect(
          () => compiler.compile(source, config(selector)),
          throwsA(isA<CompileException>()),
        );
      }
      expect(
        () => compiler.compile(
          source.replaceFirst('final String id', 'final String? id'),
          config({'model': 'Entry', 'field': 'id'}),
        ),
        throwsA(isA<CompileException>()),
      );
      expect(
        () => compiler.compile(
          source.replaceFirst("Entry('one')", "Entry('unknown')"),
          config({'model': 'Entry', 'field': 'id'}),
        ),
        throwsA(isA<CompileException>()),
      );
    },
  );
}
