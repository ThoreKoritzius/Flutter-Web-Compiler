import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'custom painters draw on a sized canvas and repaint on demand',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-paint-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

final pulse = ValueNotifier<int>(0);
void main() => runApp(const MaterialApp(home: Chart()));

class Bars extends CustomPainter {
  Bars(this.values, {super.repaint});
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    print('paint ${size.width}x${size.height} ${values.join(',')} ${pulse.value}');
    final paint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xff3366ff), Color(0xff99ccff)]);
    final width = size.width / values.length;
    for (var i = 0; i < values.length; i++) {
      final height = size.height * values[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(i * width + 2, size.height - height, width - 4, height), const Radius.circular(4)),
        paint,
      );
    }
    final line = Path()..moveTo(0, size.height);
    for (var i = 0; i < values.length; i++) {
      line.lineTo((i + 0.5) * width, size.height * (1 - values[i]));
    }
    canvas.drawPath(line, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xffff0000));
    canvas.drawArc(Rect.fromCircle(center: const Offset(20, 20), radius: 10), 0, math.pi, true, Paint());
    final label = TextPainter(
      text: const TextSpan(text: 'Weekly total', style: TextStyle(fontSize: 12, color: Color(0xff222222))),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    label.paint(canvas, Offset(size.width - label.width, 0));
  }

  @override
  bool shouldRepaint(Bars oldDelegate) => oldDelegate.values.join() != values.join();
}

class Marker extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, Paint());
  @override
  bool shouldRepaint(Marker oldDelegate) => false;
}

class Chart extends StatefulWidget {
  const Chart({super.key});
  @override
  State<Chart> createState() => ChartState();
}

class ChartState extends State<Chart> {
  List<double> values = [0.2, 0.8, 0.5];
  int unrelated = 0;
  bool shown = true;
  @override
  Widget build(BuildContext context) => Column(children: [
    ElevatedButton(onPressed: () => setState(() => unrelated++), child: Text('Rebuild $unrelated')),
    ElevatedButton(onPressed: () => setState(() => values = [0.4, 0.4, 0.9]), child: const Text('Change data')),
    ElevatedButton(onPressed: () => pulse.value++, child: const Text('Pulse')),
    ElevatedButton(onPressed: () => setState(() => shown = false), child: const Text('Hide')),
    if (shown)
      SizedBox(
        height: 120,
        child: CustomPaint(painter: Bars(values, repaint: pulse), foregroundPainter: Marker()),
      ),
  ]);
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/native_paint_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Custom painting passed'));
    },
  );
}
