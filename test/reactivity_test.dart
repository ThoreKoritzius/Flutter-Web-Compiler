import 'dart:convert';
import 'dart:io';

import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:flutter_dom_compiler/src/reactivity.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

const counterSource = r'''
class Counter extends StatefulWidget {
 State<Counter> createState() => _Counter();
}
class _Counter extends State<Counter> {
 int count = 0;
 bool verbose = false;
 Widget build(BuildContext context) {
   final doubled = count * 2;
   return Column(children: [
     Text('Count: $count / $doubled'),
     Text(verbose ? 'Details' : ''),
     TextButton(onPressed: () => setState(() => count++), child: Text('Add')),
     TextButton(onPressed: count > 0 ? () => setState(() => count -= 1) : null, child: Text('Remove')),
     TextButton(onPressed: () => setState(() => verbose = !verbose), child: Text('Details')),
   ]);
 }
}
''';

Map<String, dynamic> program(String source) {
  final result = FlutterDomCompiler().compile(source, {'root': 'Counter'});
  return jsonDecode(
        parse(
          result.html,
        ).querySelector('[data-dom-state]')!.attributes['data-dom-program']!,
      )
      as Map<String, dynamic>;
}

void main() {
  test(
    'counter compiles once with typed dependent expressions and disabled action',
    () {
      final p = program(counterSource);
      expect(p['state'], {'count': 0, 'verbose': false});
      final bindings = p['bindings'] as List;
      final count = bindings.firstWhere((b) => b['kind'] == 'text');
      expect(count['dependencies'], ['count']);
      expect(
        evaluateCode(count['expression'] as List, {
          'count': 17,
          'verbose': false,
        }),
        'Count: 17 / 34',
      );
      final remove = (p['actions'] as List)[1];
      expect(
        evaluateCode(remove['enabled'] as List, {'count': 0, 'verbose': false}),
        false,
      );
      expect(
        evaluateCode(remove['enabled'] as List, {
          'count': 17,
          'verbose': false,
        }),
        true,
      );
      final many = counterSource.replaceFirst(
        'int count = 0;',
        'int count = 123456;',
      );
      expect(program(many)['bindings'], p['bindings']);
    },
  );

  test('reactive constructor inputs reach stateless children', () {
    final source =
        counterSource.replaceFirst(
          r"Text('Count: $count / $doubled')",
          r"Label('Count: $count / $doubled')",
        ) +
        """
class Label extends StatelessWidget {
 const Label(this.label);
 final String label;
 Widget build(BuildContext context) => Text(label);
}
""";
    final p = program(source);
    final text = (p['bindings'] as List).firstWhere((b) => b['kind'] == 'text');
    expect(
      evaluateCode(text['expression'] as List, {'count': 7, 'verbose': true}),
      'Count: 7 / 14',
    );
  });

  test(
    'invalid types, floating state, overflow and arbitrary calls are rejected',
    () {
      for (final source in [
        counterSource.replaceFirst('int count = 0;', 'double count = 0;'),
        counterSource.replaceFirst(
          'int count = 0;',
          'int count = 9007199254740992;',
        ),
        counterSource.replaceFirst('count++', 'count = true'),
        counterSource.replaceFirst('count++', 'count = count / 2'),
        counterSource.replaceFirst('count++', 'count = fetchValue()'),
      ]) {
        expect(() => program(source), throwsA(isA<CompileException>()));
      }
      expect(
        () =>
            ReactiveValue.operation('*', [4294967296, 4294967296]).evaluate({}),
        throwsArgumentError,
      );
      var growing = ReactiveValue.field('n', 1);
      expect(() {
        for (var i = 0; i < 20; i++) {
          growing = ReactiveValue.operation('+', [growing, growing]);
        }
      }, throwsArgumentError);
      final count = ReactiveValue.field('count', 0);
      expect(
        () => ReactiveValue.operation('+', [count, true]),
        throwsArgumentError,
      );
      expect(
        () => ReactiveValue.operation('+', [
          count,
          1,
        ]).evaluate({'count': 9007199254740991}),
        throwsArgumentError,
      );
    },
  );

  test('binding payload is escaped and never becomes markup', () {
    final result = FlutterDomCompiler().compile(
      counterSource.replaceFirst(
        "'Details' : ''",
        "'<script>bad()</script>' : ''",
      ),
      {'root': 'Counter'},
    );
    final document = parse(result.html);
    expect(
      document.querySelectorAll('script').length,
      1,
    ); // Only external runtime.
    expect(document.querySelector('script')!.attributes['src'], 'native.js');
    expect(
      document.querySelector('[data-dom-view]')!.text,
      isNot(contains('bad()')),
    );
  });

  test(
    'runtime updates dependent nodes, isolates instances and rolls back overflow',
    () {
      final result = Process.runSync('node', [
        '-e',
        _runtimeHarness + reactiveRuntime + _runtimeChecks,
        jsonEncode(program(counterSource)),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test('runtime changes conditional visibility without replacing nodes', () {
    final input = counterSource.replaceFirst(
      "Text(verbose ? 'Details' : '')",
      "if (verbose) Text('Details')",
    );
    final output = Process.runSync('node', [
      '-e',
      _runtimeHarness +
          reactiveRuntime +
          r"""
const f = fixture();
const binding = f.p.bindings.find(b => b.kind === 'visible');
const group = f.nodes.get('[data-dom-visible="' + binding.id + '"]');
assert.equal(group.hidden, true);
press(f, 2);
assert.equal(group.hidden, false);
press(f, 2);
assert.equal(group.hidden, true);
assert.equal(f.nodes.get('[data-dom-visible="' + binding.id + '"]'), group);
""",
      jsonEncode(program(input)),
    ]);
    expect(output.exitCode, 0, reason: '${output.stdout}\n${output.stderr}');
  });

  test('Dart and JS expression evaluators agree, including short circuiting', () {
    final n = ReactiveValue.field('n', 0),
        flag = ReactiveValue.field('flag', false);
    final expressions = [
      ReactiveValue.operation('+', [n, 7]),
      ReactiveValue.operation('-', [n, 7]),
      ReactiveValue.operation('*', [n, -3]),
      ReactiveValue.operation('negate', [n]),
      for (final op in ['<', '<=', '>', '>=', '==', '!='])
        ReactiveValue.operation(op, [n, 7]),
      ReactiveValue.operation('choose', [flag, 'yes', 'no']),
      ReactiveValue.operation('!', [flag]),
      ReactiveValue.operation('&&', [flag, true]),
      ReactiveValue.operation('||', [flag, true]),
      ReactiveValue.operation('string', [n]),
      ReactiveValue.operation('choose', [
        flag,
        0,
        ReactiveValue.operation('+', [9007199254740991, 1]),
      ]),
    ];
    final state = <String, Object>{'n': -17, 'flag': true};
    final expected = expressions.map((e) => e.evaluate(state)).toList();
    final output = Process.runSync('node', [
      '-e',
      'const document = {addEventListener() {}};\n$reactiveRuntime\n'
          'const input = JSON.parse(process.argv[1]); console.log(JSON.stringify(input.expressions.map(e => domEvaluate(e, input.state))));',
      jsonEncode({
        'expressions': expressions.map((e) => e.code).toList(),
        'state': state,
      }),
    ]);
    expect(output.exitCode, 0, reason: '${output.stderr}');
    expect(jsonDecode(output.stdout as String), expected);
  });
}

// Minimal DOM test doubles exercise the actual shipped runtime without a browser.
const _runtimeHarness = r'''
const assert = require('node:assert/strict');
let click;
const document = {addEventListener(type, listener) {click = listener;},
  createTextNode(value) {return {data: value};}};
function fixture() {
  const p = JSON.parse(process.argv[1]);
  const nodes = new Map();
  const status = {hidden: true};
  const owner = {dataset: {domProgram: JSON.stringify(p)}, querySelector(selector) {
    return selector === '[data-dom-error]' ? status : nodes.get(selector);
  }};
  for (const binding of p.bindings) {
    const initial = domEvaluate(binding.expression, p.state);
    const node = {firstChild: {data: initial}, writes: 0,
      get textContent() {return this.firstChild.data;},
      appendChild(child) {this.firstChild = child;},
      get disabled() {return this._disabled;},
      set disabled(value) {this._disabled = value; this.writes++;}};
    if (binding.kind === 'enabled') node._disabled = !initial;
    if (binding.kind === 'visible') node.hidden = !initial;
    nodes.set('[data-dom-' + binding.kind + '="' + binding.id + '"]', node);
  }
  const buttons = p.actions.map((action, id) => ({dataset: {domAction: String(id)},
    get disabled() {return false;}, closest() {return owner;}}));
  return {owner, nodes, status, buttons, p};
}
function press(f, id) {click({target: {closest() {return f.buttons[id];}}});}
''';

const _runtimeChecks = r'''
const a = fixture(), b = fixture();
const texts = [...a.nodes.entries()].filter(([key]) => key.startsWith('[data-dom-text')).map(([,value]) => value);
press(a, 1); // Guard rejects removal at zero even if a synthetic event bypasses disabled.
assert.equal(texts[0].textContent, 'Count: 0 / 0');
for (let i=0; i<12; i++) press(a, 0);
assert.equal(texts[0].textContent, 'Count: 12 / 24');
assert.equal(texts[1].textContent, '');
assert.equal([...b.nodes.values()][0].textContent, 'Count: 0 / 0');
const before = [...a.nodes.values()].filter(n => n.writes > 0).map(n => n.writes);
press(a, 2);
assert.equal(texts[1].textContent, 'Details');
assert.deepEqual([...a.nodes.values()].filter(n => n.writes > 0).map(n => n.writes), before);
press(a, 1);
assert.equal(texts[0].textContent, 'Count: 11 / 22');
const p = domPrograms.get(a.owner);
p.state.count = 4503599627370495;
press(a, 0); // Action is safe, but derived count * 2 overflows.
assert.equal(p.state.count, 4503599627370495);
assert.equal(texts[0].textContent, 'Count: 11 / 22');
assert.equal(a.status.hidden, false);
console.log('Runtime checks passed');
''';
