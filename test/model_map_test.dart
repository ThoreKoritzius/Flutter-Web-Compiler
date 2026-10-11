import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = r'''
class Summary {
 const Summary({required this.coverage, this.sync = const {}});
 final Map<String, dynamic> coverage;
 final Map<String, bool> sync;
 factory Summary.fromJson(Map<String, dynamic> json) {
   throw UnsupportedError('Must never execute');
 }
 String label() => '${coverage['days'] ?? 0} days';
}
class Page extends StatelessWidget {
 const Page({required this.summary}); final Summary summary;
 Widget build(BuildContext context) => Text(summary.label() +
   (summary.sync['complete'] == true ? ' · Ready' : ' · Importing'));
}
''';
  Map<String, dynamic> config(Object? coverage, Object? sync) => {
    'preview': [
      {
        'root': 'Page',
        'arguments': {
          'summary': {
            'model': 'Summary',
            'arguments': {'coverage': coverage, 'sync': sync},
          },
        },
      },
    ],
  };
  test(
    'explicit map snapshots read original model fields without calling factory',
    () {
      final result = compiler.compile(
        source,
        config(
          {
            'map': {'days': 6},
          },
          {
            'map': {'complete': true},
          },
        ),
      );
      expect(
        parse(result.html).querySelector('.dom-preview-card p')!.text,
        '6 days · Ready',
      );
      expect(result.report['nativeAdapterInstances'], 0);
      final empty = compiler.compile(source, config({'map': {}}, {'map': {}}));
      expect(
        parse(empty.html).querySelector('.dom-preview-card p')!.text,
        '0 days · Importing',
      );
    },
  );
  test('typed map entries and descriptor shapes fail closed', () {
    for (final invalid in [
      config(
        {
          'map': {'days': 6},
        },
        {
          'map': {'complete': 'true'},
        },
      ),
      config({'days': 6}, {'map': {}}),
      config(
        {
          'map': {1: 6},
        },
        {'map': {}},
      ),
      config(
        {
          'map': {
            'days': {'callback': 'load'},
          },
        },
        {'map': {}},
      ),
      config(
        {
          'map': {'days': double.infinity},
        },
        {'map': {}},
      ),
    ]) {
      expect(
        () => compiler.compile(source, invalid),
        throwsA(isA<CompileException>()),
      );
    }
  });
  test('map snapshot key and nested value annotations are checked', () {
    final typed = source.replaceFirst(
      'Map<String, dynamic> coverage',
      'Map<int, List<int>> coverage',
    );
    expect(
      () => compiler.compile(
        typed,
        config(
          {
            'map': {
              'days': [6],
            },
          },
          {'map': {}},
        ),
      ),
      throwsA(isA<CompileException>()),
    );
    final nested = source.replaceFirst(
      'Map<String, dynamic> coverage',
      'Map<String, List<int>> coverage',
    );
    expect(
      () => compiler.compile(
        nested,
        config(
          {
            'map': {
              'days': ['6'],
            },
          },
          {'map': {}},
        ),
      ),
      throwsA(isA<CompileException>()),
    );
  });
  test(
    'named generative constructors and invoked factory bodies remain unsupported',
    () {
      expect(
        () => compiler.compile(
          source.replaceFirst('factory Summary.fromJson', 'Summary.fromJson'),
          config({'map': {}}, {'map': {}}),
        ),
        throwsA(isA<CompileException>()),
      );
      expect(
        () => compiler.compile(
          source.replaceFirst(
            "summary.label()",
            "Summary.fromJson({}).label()",
          ),
          config({'map': {}}, {'map': {}}),
        ),
        throwsA(isA<CompileException>()),
      );
    },
  );
}
