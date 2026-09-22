import 'dart:convert';
import 'dart:io';
import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

String source(String body) =>
    '''
class App extends StatelessWidget { Widget build(BuildContext context) => $body; }
class SearchPanel extends StatefulWidget {}
''';
void main() {
  final compiler = FlutterDomCompiler();
  final config = {
    'nativeAdapters': {'SearchPanel': 'filter-list'},
  };
  test(
    'emits escaped native controls and initial results in strict DOM mode',
    () {
      final result = compiler.compile(
        source(
          'const SearchPanel(items: ["<script>", "Flutter"], label: "Find <items>", hintText: "Type here")',
        ),
        config,
        domOnly: true,
      );
      expect(result.html, contains('<input'));
      expect(result.html, contains('&lt;script&gt;'));
      expect(result.html, contains('Find &lt;items&gt;'));
      expect(result.html, contains('2 of 2 features'));
      expect(result.html, contains('src="native.js"'));
      expect(result.html, isNot(contains('islands.js')));
      expect(result.report['nativeAdapterInstances'], 1);
    },
  );
  test('rejects unknown adapters and non-string list data', () {
    expect(
      () => compiler.compile(source('const SearchPanel(items: [1])'), config),
      throwsA(isA<CompileException>()),
    );
    expect(
      () => compiler.compile(source('const SearchPanel(items: [])'), {
        'nativeAdapters': {'SearchPanel': 'unknown'},
      }),
      throwsA(isA<CompileException>()),
    );
  });
  test('multiple adapters have distinct scoped controls', () {
    final result = compiler.compile(
      source(
        'const Column(children: [SearchPanel(items: ["A"]), SearchPanel(items: ["B"])])',
      ),
      config,
    );
    expect(result.html, contains('id="dom-filter-0"'));
    expect(result.html, contains('id="dom-filter-1"'));
  });
  test(
    'compiles the shared showcase source with native search and Flutter counter',
    () {
      final result = compiler.compile(
        File('examples/showcase/lib/main.dart').readAsStringSync(),
        jsonDecode(
              File('examples/showcase/flutter_dom.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      expect(result.report['nativeAdapterInstances'], 1);
      expect(result.island, 'CounterPanel');
      expect(result.html, contains('6 of 6 features'));
    },
  );
}
