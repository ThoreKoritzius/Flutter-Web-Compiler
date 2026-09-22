import 'dart:convert';
import 'dart:io';
import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

void main() {
  test(
    'health compiles to five accessible SVG charts without scripts or Flutter',
    () {
      final source = File('examples/health/lib/main.dart').readAsStringSync();
      final config =
          jsonDecode(
                File('examples/health/flutter_dom.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final result = FlutterDomCompiler().compile(
        source,
        config,
        domOnly: true,
      );
      expect('<svg'.allMatches(result.html).length, 5);
      expect(result.html, contains('Daily values'));
      expect(result.html, isNot(contains('<script')));
      expect(result.island, isNull);
      expect(
        () => FlutterDomCompiler().compile(
          source.replaceFirst('[7.2,', '[-7.2,'),
          config,
        ),
        throwsA(isA<CompileException>()),
      );
    },
  );
}
