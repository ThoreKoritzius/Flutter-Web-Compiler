import 'dart:convert';

import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:flutter_dom_compiler/src/reactivity.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

const source = r'''
class Records extends StatefulWidget {
 const Records({required this.items, this.limit = 2, this.open = false});
 final List<String> items;
 final int limit;
 final bool open;
 State<Records> createState() => _Records();
}
class _Records extends State<Records> {
 late bool expanded = widget.open;
 Widget build(BuildContext context) {
   final shown = expanded ? widget.items : widget.items.take(widget.limit).toList();
   return Column(children: [
     Text('Total ${widget.items.length}'),
     for (final item in shown) Text(item),
     TextButton(onPressed: () => setState(() => expanded = !expanded), child: Text(expanded ? 'Less' : 'More')),
   ]);
 }
}
''';

void main() {
  final compiler = FlutterDomCompiler();
  Map<String, dynamic> options({bool open = false}) => {
    'root': 'Records',
    'arguments': {
      'items': ['One', 'Two', 'Three'],
      'open': open,
    },
  };

  test(
    'stateful inputs initialize state and conditional lists retain a shared prefix',
    () {
      for (final open in [false, true]) {
        final result = compiler.compile(source, options(open: open));
        final dom = parse(result.html);
        final owner = dom.querySelector('[data-dom-state]')!;
        final program =
            jsonDecode(owner.attributes['data-dom-program']!) as Map;
        expect(program['state'], {'expanded': open});
        expect(
          dom.querySelectorAll('p').where((p) => p.text == 'One').length,
          1,
        );
        final group = dom.querySelector('[data-dom-visible]')!;
        expect(group.attributes.containsKey('hidden'), !open);
        expect(group.text, 'Three');
        final visibility = (program['bindings'] as List).firstWhere(
          (b) => b['kind'] == 'visible',
        );
        expect(
          evaluateCode(visibility['expression'] as List, {'expanded': !open}),
          !open,
        );
        expect(result.report['nativeAdapterInstances'], 0);
        expect(result.html, isNot(contains('<template')));
      }
    },
  );

  test('static collection for scopes, list properties and methods compose', () {
    const input = r'''
class ListView extends StatelessWidget {
 const ListView({required this.items}); final List<String> items;
 Widget build(BuildContext context) {
   final item = 'Outside';
   return Column(children: [
     Text('${items.first}/${items.last}/${items.isEmpty}/${items.isNotEmpty}'),
     for (final item in items.skip(1)) ...[Text(item), Text(items.take(1).join(':'))],
     Text(item),
   ]);
 }
}
''';
    final result = compiler.compile(input, {
      'root': 'ListView',
      'arguments': {
        'items': ['A', 'B', 'C'],
      },
    });
    expect(
      parse(result.html).querySelectorAll('p').map((p) => p.text).toList(),
      ['A/C/false/true', 'B', 'A', 'C', 'A', 'Outside'],
    );
    expect(result.html, isNot(contains('native.js')));
  });

  test(
    'unsupported mutations, state initializers and loop forms fail explicitly',
    () {
      for (final input in [
        source.replaceFirst('widget.open', 'loadInitial()'),
        source.replaceFirst(
          'late bool expanded = widget.open;',
          'late bool expanded;',
        ),
        source.replaceFirst(
          'for (final item in shown)',
          'for (var i = 0; i < 3; i++)',
        ),
        source.replaceFirst(
          'widget.items.take(widget.limit)',
          'widget.items.take(-1)',
        ),
        source.replaceFirst(
          'widget.items.take(widget.limit)',
          'widget.items.take(expanded ? 1 : 2)',
        ),
      ]) {
        expect(
          () => compiler.compile(input, options()),
          throwsA(isA<CompileException>()),
        );
      }
      expect(
        () => compiler.compile(source, {'root': 'Records'}),
        throwsA(
          isA<CompileException>().having(
            (e) => e.code,
            'code',
            'requires-inputs',
          ),
        ),
      );
    },
  );

  test(
    'runtime conditions retain both static branches and reject unknown content',
    () {
      final input = source.replaceFirst(
        'for (final item in shown) Text(item),',
        "if (expanded) Text('Open') else Text('Closed'),",
      );
      final dom = parse(compiler.compile(input, options()).html);
      expect(dom.querySelectorAll('[data-dom-visible]').length, 2);
      expect(
        dom.querySelectorAll('[data-dom-visible][hidden]').single.text,
        'Open',
      );
      expect(
        () => compiler.compile(
          input.replaceFirst("Text('Open')", 'UnknownWidget()'),
          options(),
        ),
        throwsA(isA<CompileException>()),
      );
    },
  );
}
