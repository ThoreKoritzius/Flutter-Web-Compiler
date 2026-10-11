import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
const suffix = '!';
String decorate(String input, {int count = 2}) {
 final label = '$input/$count';
 if (count == 0) return 'Empty';
 return label + suffix;
}
String category(String input) {
 switch (input) {
  case 'run':
  case 'walk': return decorate(input);
  default: return 'Other';
 }
}
class Page extends StatelessWidget {
 String get suffix => 'caller';
 Widget build(BuildContext context) => Column(children: [Text(category('run')), Text(category('swim')), Text(decorate('x', count:0))]);
}
''';
  test(
    'top-level block helpers lower final locals, static branches and grouped switch returns',
    () {
      final result = compiler.compile(source, {'root': 'Page'});
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        'run/2!',
        'Other',
        'Empty',
      ]);
      expect(result.report['pureHelperInvocations'], 4);
    },
  );
  test(
    'helpers cannot capture callers, mutate, recurse or run async/statement loops',
    () {
      for (final body in [
        'return missingCaller;',
        'return this.suffix;',
        'return decorate(input);',
        'var x = input; return x;',
        'input = "changed"; return input;',
        'while (true) {} return input;',
      ]) {
        final replaced = source.replaceFirst(
          "final label = '\$input/\$count';\n if (count == 0) return 'Empty';\n return label + suffix;",
          body,
        );
        expect(
          () => compiler.compile(replaced, {'root': 'Page'}),
          throwsA(isA<CompileException>()),
        );
      }
      expect(
        () => compiler.compile(
          source.replaceFirst(
            'String decorate(String input, {int count = 2}) {',
            'String decorate(String input, {int count = 2}) async {',
          ),
          {'root': 'Page'},
        ),
        throwsA(isA<CompileException>()),
      );
    },
  );
  test(
    'switch case scope is isolated and unsupported case flow fails closed',
    () {
      const scoped = r"""
String label(String input) {
 final text = 'outer';
 switch (input) {
  case 'run': final text = 'inner'; return text;
 }
 return text;
}
class Page extends StatelessWidget { Widget build(BuildContext context) => Column(children:[Text(label('run')), Text(label('walk'))]); }
""";
      final result = compiler.compile(scoped, {'root': 'Page'});
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        'inner',
        'outer',
      ]);
      for (final replacement in [
        "case 'run': break;",
        "case final value: return value;",
        "case 'run' when true: return 'guarded';",
      ]) {
        expect(
          () => compiler.compile(
            scoped.replaceFirst(
              "case 'run': final text = 'inner'; return text;",
              replacement,
            ),
            {'root': 'Page'},
          ),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
}
