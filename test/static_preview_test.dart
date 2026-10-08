import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Stat extends StatelessWidget {
 const Stat(this.label, {this.amount = 4});
 final String label;
 final double amount;
 Widget build(BuildContext context) {
   final amount = this.amount * 2;
   final theme = Theme.of(context);
   final title = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
   return Column(children: [
     Text('$amount', style: title, maxLines: 1),
     Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
     SizedBox(width: amount / 2),
   ]);
 }
}
''';
  // Raw source avoids host-language interpolation of the fixture.
  final dartSource = source;
  final theme = {
    'textTheme': {
      'titleMedium': {'fontSize': 24},
      'labelMedium': {'fontSize': 12},
    },
    'colorScheme': {'onSurfaceVariant': '#aabbcc'},
  };
  Map<String, dynamic> config() => {
    'root': 'Stat',
    'positionalArguments': ['Steps'],
    'arguments': {'amount': 5},
    'staticTheme': theme,
  };

  test(
    'locals, field shadowing, arithmetic, positional data and explicit theme compose',
    () {
      final result = compiler.compile(dartSource, config());
      expect(
        result.html,
        allOf(
          contains('>10.0<'),
          contains('Steps'),
          contains('width:5px'),
          contains('font-size:24px'),
          contains('font-weight:800'),
          contains('rgba(170,187,204,1.0)'),
          contains('-webkit-line-clamp:1'),
        ),
      );
      expect(result.report['staticThemeProvided'], isTrue);
      expect(result.html, isNot(contains('<script')));
    },
  );

  test('theme-dependent source fails without an explicit snapshot', () {
    expect(
      () => compiler.compile(dartSource, config()..remove('staticTheme')),
      throwsA(
        isA<CompileException>().having(
          (e) => e.message,
          'reason',
          contains('staticTheme'),
        ),
      ),
    );
  });

  test('preview compiles repeated original widgets with distinct inputs', () {
    final result = compiler.compile(dartSource, {
      'title': '<Metrics>',
      'staticTheme': theme,
      'preview': [
        {
          'root': 'Stat',
          'positionalArguments': ['First'],
          'arguments': {'amount': 2},
        },
        {
          'root': 'Stat',
          'positionalArguments': ['Second'],
          'arguments': {'amount': 7},
        },
      ],
    });
    expect(
      result.html,
      allOf(
        contains('&lt;Metrics&gt;'),
        contains('First'),
        contains('Second'),
        contains('>4.0<'),
        contains('>14.0<'),
      ),
    );
    expect(result.report['componentPreview'], isTrue);
  });

  test(
    'mutable locals, side effects, nonfinite arithmetic and CSS injection fail',
    () {
      for (final invalid in [
        dartSource.replaceFirst('final amount =', 'var amount ='),
        dartSource.replaceFirst(
          'final amount = this.amount * 2;',
          'print("side effect");',
        ),
        dartSource.replaceFirst('this.amount * 2', 'this.amount / 0'),
      ]) {
        expect(
          () => compiler.compile(invalid, config()),
          throwsA(isA<CompileException>()),
        );
      }
      expect(
        () => compiler.compile(dartSource, {
          ...config(),
          'staticTheme': {
            'colorScheme': {'onSurfaceVariant': 'red; background:url(x)'},
          },
        }),
        throwsA(isA<CompileException>()),
      );
    },
  );

  test('optional positional defaults and excess positional rejection', () {
    const simple = '''
class App extends StatelessWidget {
 const App([this.label = 'Default']);
 final String label;
 Widget build(BuildContext context) => Text(label);
}
''';
    expect(compiler.compile(simple, {}).html, contains('Default'));
    expect(
      compiler.compile(simple, {
        'positionalArguments': ['Given'],
      }).html,
      contains('Given'),
    );
    expect(
      () => compiler.compile(simple, {
        'positionalArguments': ['A', 'B'],
      }),
      throwsA(isA<CompileException>()),
    );
  });
  test(
    'theme colors and copyWith retain explicit alpha and null semantics',
    () {
      const chip = r"""
class App extends StatelessWidget {
 Widget build(BuildContext context) {
  final theme = Theme.of(context);
  return Container(
   decoration: BoxDecoration(color: theme.colorScheme.surface.withValues(alpha: .5), borderRadius: BorderRadius.circular(12)),
   child: Text('Chip', style: theme.textTheme.titleMedium?.copyWith(fontSize: null)),
  );
 }
}
""";
      final result = compiler.compile(chip, {
        'staticTheme': {
          'textTheme': {
            'titleMedium': {'fontSize': 18},
          },
          'colorScheme': {'surface': '#123456'},
        },
      });
      expect(
        result.html,
        allOf(
          contains('rgba(18,52,86,0.5)'),
          contains('border-radius:12px'),
          contains('font-size:18px'),
        ),
      );
    },
  );
}
