import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''class Page extends StatelessWidget {
 const Page({required this.onOpen}); final ValueChanged<String> onOpen;
 Widget build(BuildContext context)=>Column(children:[
 ListTile(contentPadding:EdgeInsets.zero, leading:CircleAvatar(backgroundColor:Color(0xffe8733a), child:Icon(Icons.directions_run_rounded)), title:Text('Run'), subtitle:Text('24m · 5.0 km'), trailing:Icon(Icons.chevron_right_rounded), onTap:()=>onOpen('one')),
 Divider(height:1), ListTile(title:Text('Read only'))]);
}''';
  final config = {
    'root': 'Page',
    'arguments': {
      'onOpen': {
        'callback': 'open',
        'routes': {'one': 'activities/one/'},
      },
    },
  };
  test('minimal list rows emit semantic links, avatar SVG and separators', () {
    final result = compiler.compile(source, config);
    final doc = parse(result.html);
    expect(
      doc.querySelector('a.dom-list-tile')!.attributes['href'],
      'activities/one/',
    );
    expect(doc.querySelectorAll('[role=separator]'), hasLength(1));
    expect(doc.querySelectorAll('svg'), hasLength(2));
    expect(doc.querySelectorAll('div.dom-list-tile'), hasLength(1));
    expect(result.report['nativeAdapterInstances'], 0);
  });
  test(
    'unsupported widget options, geometry and nested interactive links fail',
    () {
      for (final input in [
        source.replaceFirst('CircleAvatar(', 'CircleAvatar(radius:0,'),
        source.replaceFirst(
          'Divider(height:1)',
          'Divider(height:1,thickness:2)',
        ),
        source.replaceFirst(
          'title:Text(\'Run\')',
          "title:InkWell(onTap:()=>onOpen('one'),child:Text('Nested'))",
        ),
        source.replaceFirst(
          'ListTile(contentPadding:',
          'ListTile(selected:true,contentPadding:',
        ),
      ]) {
        expect(
          () => compiler.compile(input, config),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
}
