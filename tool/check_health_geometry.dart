import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_dom_compiler/src/painter.dart';

Future<void> main() async {
  final test = await Process.run('flutter', [
    'test',
    'test/geometry_test.dart',
  ], workingDirectory: 'examples/health');
  if (test.exitCode != 0) {
    stderr.write('${test.stdout}${test.stderr}');
    exitCode = 1;
    return;
  }
  final reference =
      jsonDecode(File('build/health-flutter-geometry.json').readAsStringSync())
          as Map;
  final painter =
      parseString(
        content: File('examples/health/lib/main.dart').readAsStringSync(),
      ).unit.declarations.whereType<ClassDeclaration>().singleWhere(
        (c) => c.name.lexeme == '_ChartPainter',
      );
  void compare(List<num> actual, List expected) {
    if (actual.length != expected.length)
      throw StateError('Geometry length differs');
    for (var i = 0; i < actual.length; i++) {
      if ((actual[i] - (expected[i] as num)).abs() > .001)
        throw StateError('Geometry mismatch: $actual versus $expected');
    }
  }

  for (final kind in ['bar', 'line']) {
    final svg = SvgPainter().compile(painter, {
      'values': [0.0, 10.0, 20.0],
      'color': '#123456',
      'kind': kind,
    });
    final commands = reference[kind] as List;
    compare([1, 1], commands.first['scale']);
    if (kind == 'bar') {
      final rects = RegExp(
        r'<rect x="([^"]+)" y="([^"]+)" width="([^"]+)" height="([^"]+)"',
      ).allMatches(svg).toList();
      if (rects.length != commands.length - 1)
        throw StateError('Rectangle count differs');
      for (var i = 0; i < rects.length; i++) {
        compare([
          for (var j = 1; j <= 4; j++) num.parse(rects[i][j]!),
        ], commands[i + 1]['rect']);
      }
    } else {
      final d = RegExp(r'd="([^"]+)"').firstMatch(svg)![1]!;
      final points = RegExp(r'[ML]([\d.e+-]+) ([\d.e+-]+)')
          .allMatches(d)
          .map((m) => [double.parse(m[1]!), double.parse(m[2]!)])
          .toList();
      final xs = points.map((p) => p[0]), ys = points.map((p) => p[1]);
      compare([
        xs.reduce(math.min),
        ys.reduce(math.min),
        xs.reduce(math.max),
        ys.reduce(math.max),
      ], commands[1]['bounds']);
      var length = 0.0;
      for (var i = 1; i < points.length; i++) {
        length += math.sqrt(
          math.pow(points[i][0] - points[i - 1][0], 2) +
              math.pow(points[i][1] - points[i - 1][1], 2),
        );
      }
      compare([length], [commands[1]['length']]);
      compare(
        [double.parse(RegExp(r'stroke-width="([^"]+)"').firstMatch(svg)![1]!)],
        [commands[1]['strokeWidth']],
      );
    }
  }
  stdout.writeln(
    'PASS: Flutter Canvas and compiled SVG geometry agree for bar and line cases (tolerance 0.001).',
  );
}
