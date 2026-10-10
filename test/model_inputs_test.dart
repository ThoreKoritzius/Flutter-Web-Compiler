import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

const source = r'''
class Entry {
 const Entry(this.title, {this.minutes = 15, this.done = false});
 final String title; final int minutes; final bool done;
 String get label => '$title · ${minutes * 2} min';
 String get description => label;
}
class Records extends StatelessWidget {
 const Records({required this.items}); final List<Entry> items;
 String get description => items.first.description;
 Widget build(BuildContext context) {
   final title = 'build-local must not leak';
   return Column(children: [Text(description), for (final item in items) Text(item.label)]);
 }
}
''';

void main() {
  final compiler = FlutterDomCompiler();
  Map<String, dynamic> options(Object? items) => {
    'root': 'Records',
    'arguments': {'items': items},
  };
  final entry = {
    'model': 'Entry',
    'positionalArguments': ['Review'],
    'arguments': {'minutes': 20},
  };

  test(
    'typed model descriptors evaluate original constructor fields and scoped getters',
    () {
      final result = compiler.compile(source, options([entry]));
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        'Review · 40 min',
        'Review · 40 min',
      ]);
      expect(result.report['staticModelInstances'], 1);
      expect(result.report['nativeAdapterInstances'], 0);
    },
  );

  test(
    'Dart model constructors and nested model fields use the same evaluation',
    () {
      final input =
          source +
          r'''
class Envelope {
 const Envelope(this.entry); final Entry entry;
 String get label => entry.description;
}
const data = [Entry('Plan', minutes: 10), Entry('Ship')];
class Page extends StatelessWidget {
 Widget build(BuildContext context) {
   final envelope = Envelope(data.first);
   return Column(children: [Text(envelope.label), Records(items: data)]);
 }
}
''';
      final result = compiler.compile(input, {'root': 'Page'});
      expect(parse(result.html).querySelectorAll('p').map((p) => p.text), [
        'Plan · 20 min',
        'Plan · 20 min',
        'Plan · 20 min',
        'Ship · 30 min',
      ]);
      expect(result.report['staticModelInstances'], 3);
    },
  );

  test('model types, constructors and unsupported behavior fail closed', () {
    for (final input in [
      options(['wrong']),
      options([
        {
          'model': 'Entry',
          'positionalArguments': ['Review'],
          'arguments': {'minutes': 'wrong'},
        },
      ]),
      options([
        {
          'model': 'Records',
          'arguments': {'items': []},
        },
      ]),
      options([
        {
          'widget': 'Entry',
          'positionalArguments': ['Review'],
        },
      ]),
      options([
        {'model': 'Entry', 'widget': 'Entry'},
      ]),
      options([
        {'title': 'untyped object'},
      ]),
    ]) {
      expect(
        () => compiler.compile(source, input),
        throwsA(isA<CompileException>()),
      );
    }
    for (final input in [
      source.replaceFirst('final int minutes;', 'int minutes;'),
      source.replaceFirst(
        'const Entry(this.title, {this.minutes = 15, this.done = false});',
        'Entry(this.title, {this.minutes = 15, this.done = false}) { print(title); }',
      ),
      source.replaceFirst(
        'String get description => label;',
        'String get description => label; void run() {}',
      ),
      source.replaceFirst('final int minutes;', 'final Object minutes;'),
      source.replaceFirst(
        'String get description => label;',
        'String get description => description;',
      ),
      source.replaceFirst(
        r"String get label => '$title · ${minutes * 2} min';",
        'String get label => load();',
      ),
    ]) {
      expect(
        () => compiler.compile(input, options([entry])),
        throwsA(isA<CompileException>()),
      );
    }
  });
}
