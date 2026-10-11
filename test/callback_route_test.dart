import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Tile extends StatelessWidget {
 const Tile({required this.onOpen, required this.id});
 final ValueChanged<String> onOpen; final String id;
 Widget build(BuildContext context) => InkWell(onTap: () => onOpen(id), borderRadius: BorderRadius.circular(12), child: Text('Open $id'));
}
class Page extends StatefulWidget {
 const Page({required this.onOpen}); final ValueChanged<String> onOpen;
 State<Page> createState() => S();
}
class S extends State<Page> {
 bool expanded=false;
 Widget build(BuildContext context) => Column(children:[
 Tile(onOpen: widget.onOpen, id:'one'),
 InkWell(onTap:()=>widget.onOpen('two'),child:Text('Two')),
 TextButton(onPressed:()=>setState(()=>expanded=!expanded),child:Text(expanded?'Less':'More'))]);
}
''';
  Map<String, dynamic> config(Object input) => {
    'root': 'Page',
    'arguments': {'onOpen': input},
  };
  test(
    'explicit route bridges lower original callbacks to escaped browser links',
    () {
      final result = compiler.compile(
        source,
        config({
          'callback': 'open',
          'routes': {
            'one': 'activities/one/',
            'two': 'activities/two/#details',
          },
        }),
      );
      final links = parse(result.html).querySelectorAll('a');
      expect(links.map((a) => a.attributes['href']), [
        'activities/one/',
        'activities/two/#details',
      ]);
      expect(result.report['nativeCallbackRouteBridges'], 1);
      expect(result.report['nativeNavigationLinks'], 2);
      expect(result.report['nativeStateInstances'], 1);
      expect(
        result.report['limitations'],
        contains(
          'Explicit callback route adapters replace host navigation; original async callback bodies are not compiled',
        ),
      );
    },
  );
  test('opaque callbacks and missing or unsafe routes remain rejected', () {
    for (final input in [
      {'callback': 'open'},
      {
        'callback': 'open',
        'routes': {'one': 'ok/'},
      },
      for (final path in [
        'https://example.com/',
        'javascript:alert(1)',
        '//example.com/',
        '../secret',
        '/absolute',
        'a/../../secret',
        'a/..#details',
        'x" onclick="alert(1)',
      ])
        {
          'callback': 'open',
          'routes': {'one': path, 'two': 'ok/'},
        },
    ]) {
      expect(
        () => compiler.compile(source, config(input)),
        throwsA(isA<CompileException>()),
      );
    }
    final options = config({
      'callback': 'open',
      'routes': {'one': 'ok/', 'two': 'ok/'},
    });
    for (final input in [
      source.replaceFirst('()=>widget.onOpen', '() async =>widget.onOpen'),
      source.replaceFirst(
        '()=>widget.onOpen(\'two\')',
        '()=>widget.onOpen(expanded)',
      ),
      source.replaceFirst("onOpen(id)", "onOpen(id, id)"),
    ]) {
      expect(
        () => compiler.compile(input, options),
        throwsA(isA<CompileException>()),
      );
    }
  });
}
