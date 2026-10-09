import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

const fixture = '''
class Panel extends StatelessWidget {
 const Panel({required this.child, this.caption});
 final Widget child;
 final String? caption;
 bool get visible => caption != null && caption != '';
 Widget build(BuildContext context) {
   final caption = 'local shadow';
   return Card(child: Column(children: [
     if (visible) Text(this.caption!),
     Row(children: [Expanded(flex: 2, child: child)]),
   ]));
 }
}
class Label extends StatelessWidget {
 const Label(this.label);
 final String label;
 Widget build(BuildContext context) => Text(label);
}
''';

void main() {
  final compiler = FlutterDomCompiler();
  Map<String, dynamic> config([String? caption]) => {
    'root': 'Panel',
    'arguments': {
      'caption': caption,
      'child': {
        'widget': 'Label',
        'positionalArguments': ['Original child'],
      },
    },
  };

  test(
    'widget descriptors compile original composition and scoped getters',
    () {
      final result = compiler.compile(fixture, config('A caption'));
      expect(result.html, contains('Original child'));
      expect(result.html, contains('A caption'));
      expect(result.html, isNot(contains('local shadow')));
      expect(result.html, contains('flex:2 1 0%'));
      expect(result.html, contains('class="dom-card"'));
      expect(result.report['nativeAdapterInstances'], 0);
      expect(result.html, isNot(contains('<script')));
      final absent = compiler.compile(fixture, config());
      expect(absent.html, isNot(contains('local shadow')));
      expect(absent.html, contains('Original child'));
    },
  );

  test('card radius and border use validated theme values', () {
    final shaped = fixture.replaceFirst(
      'Card(child:',
      'Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 2)), child:',
    );
    final options = config();
    options['staticTheme'] = {
      'colorScheme': {'outlineVariant': '#aabbcc'},
    };
    final result = compiler.compile(shaped, options);
    expect(result.html, contains('border-radius:18px'));
    expect(
      compiler
          .compile(
            shaped.replaceFirst(
              'borderRadius: BorderRadius.circular(18), ',
              '',
            ),
            options,
          )
          .html,
      contains('border-radius:0'),
    );
    expect(result.html, contains('border:2px solid rgba(170,187,204,0.5)'));
    expect(
      () => compiler.compile(
        shaped.replaceFirst('width: 2', 'width: -1'),
        options,
      ),
      throwsA(isA<CompileException>()),
    );
  });

  test('getters cannot capture build locals or recurse', () {
    for (final input in [
      fixture.replaceFirst("caption != null && caption != ''", 'visible'),
      fixture.replaceFirst("caption != null && caption != ''", 'missingLocal'),
      fixture
          .replaceFirst(
            "final caption = 'local shadow';",
            'final missingLocal = true;',
          )
          .replaceFirst("caption != null && caption != ''", 'missingLocal'),
      fixture.replaceFirst('bool get visible =>', 'bool get visible async =>'),
    ]) {
      expect(
        () => compiler.compile(input, config()),
        throwsA(isA<CompileException>()),
      );
    }
  });

  test('null assertions and unsupported shape properties fail', () {
    expect(
      () =>
          compiler.compile(fixture.replaceFirst('if (visible) ', ''), config()),
      throwsA(isA<CompileException>()),
    );
    for (final input in [
      fixture.replaceFirst('Card(child:', 'Card(elevation: 20, child:'),
      fixture.replaceFirst('flex: 2', 'flex: 0'),
      fixture.replaceFirst('Card(child:', 'Card(shape: CircleBorder(), child:'),
    ]) {
      expect(
        () => compiler.compile(input, config()),
        throwsA(isA<CompileException>()),
      );
    }
  });

  test('invalid preview descriptors and excessive nesting fail', () {
    for (final child in [
      {
        'widget': 'Text',
        'positionalArguments': ['not a local declaration'],
      },
      {'widget': 'Label', 'code': 'anything'},
      {'arbitrary': 'data'},
    ]) {
      final options = config();
      (options['arguments'] as Map)['child'] = child;
      expect(
        () => compiler.compile(fixture, options),
        throwsA(isA<CompileException>()),
      );
    }
    Object child = {
      'widget': 'Label',
      'positionalArguments': ['Deep'],
    };
    for (var i = 0; i < 20; i++) {
      child = {
        'widget': 'Panel',
        'arguments': {'child': child},
      };
    }
    final options = config();
    (options['arguments'] as Map)['child'] = child;
    expect(
      () => compiler.compile(fixture, options),
      throwsA(isA<CompileException>()),
    );
  });
}
