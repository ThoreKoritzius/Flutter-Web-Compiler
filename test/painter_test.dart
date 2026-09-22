import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:flutter_dom_compiler/src/painter.dart';
import 'package:test/test.dart';

String renderPaint(String statements) {
  final unit = parseString(
    content:
        'class Painter extends CustomPainter { void paint(Canvas c, Size s) {$statements} }',
  ).unit;
  return SvgPainter().compile(
    unit.declarations.whereType<ClassDeclaration>().single,
    {},
  );
}

void main() {
  test('Canvas arguments, loops and scalar updates determine geometry', () {
    final svg = renderPaint('''
      final p = Paint()..color = '#123456';
      var x = 0;
      for (var i = 0; i < 3; i++) { x = x + 10; }
      c.drawRect(Rect.fromLTWH(x, 4, 20, 9), p);
    ''');
    expect(svg, contains('x="30" y="4" width="20" height="9"'));
  });
  test('path commands, scale and Paint settings are derived from Dart', () {
    final svg = renderPaint('''
      c.scale(2, 3);
      final path = Path(); path.moveTo(1, 2); path.lineTo(9, 8);
      c.drawPath(path, Paint()..color = '#aabbcc'..style = PaintingStyle.stroke..strokeWidth = 4);
    ''');
    expect(svg, contains('d="M1 2 L9 8"'));
    expect(svg, contains('stroke-width="4"'));
    expect(svg, contains('scale(2 3)'));
  });
  test(
    'unsupported operations and unbounded loops fail, never use fallback geometry',
    () {
      expect(
        () => renderPaint('c.drawCircle(1, 2, Paint());'),
        throwsArgumentError,
      );
      expect(
        () => renderPaint('for(var i=0; i >= 0; i++) {}'),
        throwsArgumentError,
      );
    },
  );
  test('changing the actual health paint method changes SVG coordinates', () {
    final source = File('examples/health/lib/main.dart').readAsStringSync();
    final config =
        jsonDecode(File('examples/health/flutter_dom.json').readAsStringSync())
            as Map<String, dynamic>;
    final original = FlutterDomCompiler().compile(source, config).html;
    final modified = FlutterDomCompiler()
        .compile(source.replaceFirst('max * .88', 'max * .5'), config)
        .html;
    expect(modified, isNot(original));
    expect(original, isNot(contains('rx="3"')));
    expect(
      () => FlutterDomCompiler().compile(
        source.replaceFirst('canvas.scale(', 'canvas.unsupportedOperation('),
        config,
      ),
      throwsA(isA<CompileException>()),
    );
  });
}
