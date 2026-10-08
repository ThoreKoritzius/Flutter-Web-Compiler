import 'dart:convert';
import 'dart:io';

import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

String app(String body) =>
    '''
import 'package:flutter/material.dart';
class App extends StatelessWidget {
  const App({super.key});
  Widget build(BuildContext context) => $body;
}
''';

void main() {
  final compiler = FlutterDomCompiler();

  test('emits HTML with escaped content and metadata, without JavaScript', () {
    final result = compiler.compile(app('const Text("<script>&hello")'), {
      'title': '"quoted" <title>',
      'description': '<description>',
    });
    expect(result.html, contains('&lt;script&gt;&amp;hello'));
    expect(result.html, contains('&lt;title&gt;'));
    expect(result.html, isNot(contains('<script')));
    expect(result.island, isNull);
  });

  test('expands custom static widgets and promotes explicit heading keys', () {
    final source =
        '${app('const Heading()')}\n'
        'class Heading extends StatelessWidget { '
        'Widget build(BuildContext context) { return const Text("Hello", key: ValueKey("title")); }}';
    final result = compiler.compile(source, {
      'headings': {'title': 1},
    });
    expect(result.html, contains('<h1 style="">Hello</h1>'));
  });

  test('rejects unsupported widget instead of silently dropping it', () {
    expect(
      () => compiler.compile(app('const CustomPaint()'), {}),
      throwsA(
        isA<CompileException>().having(
          (e) => e.message,
          'message',
          contains('Unknown widget'),
        ),
      ),
    );
  });

  test('rejects unsupported named arguments with source location', () {
    expect(
      () => compiler.compile(app('const Text("Hello", softWrap: false)'), {}),
      throwsA(
        isA<CompileException>().having(
          (e) => e.message,
          'message',
          contains('Line 4'),
        ),
      ),
    );
  });

  test('rejects dynamic expressions and interpolation', () {
    for (final expression in ['Text(loadTitle())', 'Text("Hello \$name")']) {
      expect(
        () => compiler.compile(app(expression), {}),
        throwsA(isA<CompileException>()),
      );
    }
  });

  test('rejects recursive widget expansion', () {
    expect(
      () => compiler.compile(app('const App()'), {}),
      throwsA(
        isA<CompileException>().having(
          (e) => e.message,
          'message',
          contains('Recursive'),
        ),
      ),
    );
  });

  test('rejects state and constructor data on DOM side', () {
    final stateful = app(
      'const Text("Hello")',
    ).replaceFirst('StatelessWidget', 'StatefulWidget');
    expect(
      () => compiler.compile(stateful, {}),
      throwsA(isA<CompileException>()),
    );
    final field = app(
      'const Text("Hello")',
    ).replaceFirst('const App', 'final int count = 0; const App');
    expect(() => compiler.compile(field, {}), throwsA(isA<CompileException>()));
  });

  test(
    'escapes island label, preserves placeholder, rejects in DOM-only mode',
    () {
      final source =
          '${app('const Counter()')}\nclass Counter extends StatefulWidget {}';
      final config = {
        'islands': {
          'Counter': {'height': 220, 'label': '<Load>'},
        },
      };
      final result = compiler.compile(source, config);
      expect(result.island, 'Counter');
      expect(result.html, contains('&lt;Load&gt;'));
      expect(result.html, contains('height:220px'));
      expect(result.html, contains('src="islands.js"'));
      expect(result.html, isNot(contains('src="flutter/')));
      expect(
        () => compiler.compile(source, config, domOnly: true),
        throwsA(isA<CompileException>()),
      );
    },
  );

  test('rejects multiple island instances', () {
    final source =
        '${app('const Column(children: [Counter(), Counter()])')}\nclass Counter extends StatefulWidget {}';
    expect(
      () => compiler.compile(source, {
        'islands': {'Counter': {}},
      }),
      throwsA(isA<CompileException>()),
    );
  });

  test(
    'rejects malformed source, invalid headings and invalid layout numbers',
    () {
      expect(
        () => compiler.compile('class App {', {}),
        throwsA(isA<CompileException>()),
      );
      expect(
        () => compiler.compile(app('const Text("Hi", key: ValueKey("x"))'), {
          'headings': {'x': 9},
        }),
        throwsA(isA<CompileException>()),
      );
      expect(
        () => compiler.compile(app('const SizedBox(height: -5)'), {}),
        throwsA(isA<CompileException>()),
      );
    },
  );

  test(
    'compiles actual unchanged example source with static HTML and island',
    () {
      final source = File('examples/catalog/lib/main.dart').readAsStringSync();
      final config =
          jsonDecode(
                File('examples/catalog/flutter_dom.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final result = compiler.compile(source, config);
      expect(result.html, contains('Flutter, meet the web.'));
      expect(result.html, contains('<h1'));
      expect(result.html, contains('<h2'));
      expect(result.island, 'CounterPanel');
      expect(result.html, isNot(contains('Count:')));
    },
  );
}
