import 'package:flutter/material.dart';

void main() => runApp(const HealthApp());

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('VITAL / HEALTH', style: TextStyle(fontSize: 12)),
              SizedBox(height: 28),
              Text(
                'Your week, at a glance.',
                key: ValueKey('title'),
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('14–20 September  •  7 days  •  Synthetic demo data'),
              SizedBox(height: 30),
              MetricGrid(
                children: [
                  MetricChart(
                    label: 'Sleep · hours',
                    display: '7.4h avg',
                    values: [7.2, 6.8, 8, 7.6, 7.1, 8.2, 7],
                    color: '#a090f4',
                  ),
                  MetricChart(
                    label: 'Resting heart rate · bpm',
                    display: '56 bpm',
                    values: [59, 56, 55, 57, 54, 55, 56],
                    color: '#ef7f89',
                    kind: 'line',
                  ),
                  MetricChart(
                    label: 'Active minutes',
                    display: '245 min',
                    values: [30, 20, 50, 35, 25, 60, 25],
                    color: '#dc78b2',
                  ),
                  MetricChart(
                    label: 'Training · minutes',
                    display: '150 min',
                    values: [0, 40, 0, 35, 0, 75, 0],
                    color: '#f6aa6b',
                    kind: 'line',
                  ),
                ],
              ),
              SizedBox(height: 20),
              MetricChart(
                label: 'Daily steps',
                display: '52,400 steps',
                values: [8200, 5400, 7600, 9200, 6100, 10400, 5500],
                color: '#6b9ff8',
              ),
              SizedBox(height: 20),
              Text(
                'Mock data only. Charts use native SVG; daily values are available below each chart.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Explicit reusable adapter contracts. Flutter equivalents remain runnable.
class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth > 1000
          ? 4
          : box.maxWidth > 500
          ? 2
          : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children)
            SizedBox(
              width: (box.maxWidth - (columns - 1) * 16) / columns,
              child: child,
            ),
        ],
      );
    },
  );
}

class MetricChart extends StatelessWidget {
  const MetricChart({
    super.key,
    required this.label,
    required this.display,
    required this.values,
    required this.color,
    this.kind = 'bar',
  });
  final String label, display, color, kind;
  final List<double> values;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xff23252d),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          display,
          style: const TextStyle(fontSize: 28, color: Colors.white),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartPainter(
              values,
              Color(int.parse(color.replaceFirst('#', 'ff'), radix: 16)),
              kind,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.values, this.color, this.kind);
  final List<double> values;
  final Color color;
  final String kind;
  @override
  void paint(Canvas canvas, Size size) {
    final max = values.fold<double>(1, (a, b) => a > b ? a : b);
    final step = size.width / values.length;
    final paint = Paint()..color = color;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final y = size.height * (1 - values[i] / max * .88);
      if (kind == 'bar') {
        canvas.drawRect(
          Rect.fromLTWH(i * step + 2, y, step - 4, size.height - y),
          paint,
        );
      } else if (i == 0) {
        path.moveTo((i + .5) * step, y);
      } else {
        path.lineTo((i + .5) * step, y);
      }
    }
    if (kind == 'line')
      canvas.drawPath(
        path,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
