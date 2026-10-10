import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Panel extends StatelessWidget {
 const Panel({this.title = 'Ready', this.empty = false});
 final String title; final bool empty;
 Widget build(BuildContext context) {
   final title = 'Local';
   if (empty) { final label = 'Empty'; return Text(label); }
   final body = Container(
     decoration: BoxDecoration(color: Color(0xff23252d), border: Border.all(color: Color(0xff778899), width: 2), borderRadius: BorderRadius.circular(12)),
     child: Column(children: [Icon(Icons.favorite, size: 20, semanticLabel: 'Status', color: Color(0xffee6677)), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)]));
   if (!empty) return body;
   return Text('Unreachable');
 }
}
''';
  test(
    'static early return selects original widget body and keeps block locals isolated',
    () {
      for (final empty in [false, true]) {
        final result = compiler.compile(source, {
          'root': 'Panel',
          'arguments': {'empty': empty},
        });
        final dom = parse(result.html);
        expect(dom.querySelectorAll('p').map((p) => p.text), [
          empty ? 'Empty' : 'Local',
        ]);
        expect(dom.querySelectorAll('svg').length, empty ? 0 : 1);
        if (!empty) {
          expect(
            result.html,
            contains('border:2px solid rgba(119,136,153,1.0)'),
          );
          expect(dom.querySelector('svg')!.attributes['aria-label'], 'Status');
        }
      }
    },
  );
  test(
    'typed visual inputs and null coalescing use the same native render path',
    () {
      final result = compiler.compile(
        r'''
class Panel extends StatelessWidget {
 const Panel({required this.icon, required this.color, this.label});
 final IconData icon; final Color color; final String? label;
 Widget build(BuildContext context) => Column(children: [Icon(icon, color: color), Text(label ?? 'Default')]);
}
''',
        {
          'root': 'Panel',
          'arguments': {
            'icon': {'icon': 'bedtime'},
            'color': {'color': '#9988ff'},
          },
        },
      );
      final dom = parse(result.html);
      expect(dom.querySelector('svg')!.attributes['aria-hidden'], 'true');
      expect(dom.querySelector('p')!.text, 'Default');
    },
  );
  test(
    'unsupported visited statements, icons, borders and dynamic conditions fail',
    () {
      for (final input in [
        source.replaceFirst("final title = 'Local';", "var title = 'Local';"),
        source.replaceFirst("final title = 'Local';", "while (true) {}"),
        source.replaceFirst(
          "if (!empty) return body;",
          "if (!empty) { final scoped = 'Only here'; } return Text(scoped);",
        ),
        source.replaceFirst('Icons.favorite', 'Icons.unknown'),
        source.replaceFirst('Border.all(', 'Border.symmetric('),
        source.replaceFirst(
          'Widget build(BuildContext context) {',
          'Widget build(BuildContext context) async {',
        ),
      ]) {
        expect(
          () => compiler.compile(input, {'root': 'Panel'}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
}
