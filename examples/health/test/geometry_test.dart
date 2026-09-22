import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

class RecordedCanvas implements Canvas {
  final commands = <Map<String, Object?>>[];
  @override
  void scale(double sx, [double? sy]) {
    commands.add({
      'scale': [sx, sy ?? sx],
    });
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    commands.add({
      'rect': [rect.left, rect.top, rect.width, rect.height],
    });
  }

  @override
  void drawPath(Path path, Paint paint) {
    final box = path.getBounds();
    commands.add({
      'bounds': [box.left, box.top, box.right, box.bottom],
      'length': path.computeMetrics().fold<double>(
        0,
        (sum, metric) => sum + metric.length,
      ),
      'strokeWidth': paint.strokeWidth,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unrecorded Canvas operation: ${invocation.memberName}',
  );
}

void main() {
  testWidgets(
    'record actual Flutter painter geometry for compiler comparison',
    (tester) async {
      final result = <String, Object?>{};
      for (final kind in ['bar', 'line']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MetricChart(
                label: 'Test',
                display: 'Test',
                values: const [0, 10, 20],
                color: '#123456',
                kind: kind,
              ),
            ),
          ),
        );
        final widget = tester.widget<CustomPaint>(
          find
              .descendant(
                of: find.byType(MetricChart),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        final canvas = RecordedCanvas();
        widget.painter!.paint(canvas, const Size(320, 110));
        result[kind] = canvas.commands;
      }
      final file = File('../../build/health-flutter-geometry.json');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(result));
    },
  );
}
