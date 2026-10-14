import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('fl_chart imports render line, bar and pie charts natively', () async {
    final directory = Directory.systemTemp.createTempSync('native-chart-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: Charts()));

class Charts extends StatefulWidget {
  const Charts({super.key});
  @override
  State<Charts> createState() => ChartsState();
}

class ChartsState extends State<Charts> {
  List<double> values = [3, 5, 4, 8];
  String touched = 'none';
  @override
  Widget build(BuildContext context) => Column(children: [
    ElevatedButton(onPressed: () => setState(() => values = [6, 2, 7, 1]), child: const Text('Update')),
    Text('touched $touched'),
    SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              color: const Color(0xff2196f3),
              barWidth: 3,
              belowBarData: BarAreaData(show: true, gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x662196f3), Color(0x002196f3)])),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 24,
              getTitlesWidget: (value, meta) => SideTitleWidget(meta: meta, child: Text('D${value.toInt()}')))),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: 5, color: const Color(0xffff0000), dashArray: [4, 4])]),
          lineTouchData: LineTouchData(touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots?.isNotEmpty == true) {
              setState(() => touched = 'line ${response!.lineBarSpots!.first.x.toInt()}');
            }
          }),
        ),
      ),
    ),
    SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        maxY: 10,
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [BarChartRodData(toY: values[i], width: 16, borderRadius: BorderRadius.circular(4), color: const Color(0xff4caf50))]),
        ],
        titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
        barTouchData: BarTouchData(touchCallback: (event, response) {
          if (event is FlTapUpEvent && response?.spot != null) {
            setState(() => touched = 'bar ${response!.spot!.touchedBarGroupIndex}');
          }
        }),
      )),
    ),
    SizedBox(
      height: 200,
      child: PieChart(PieChartData(
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(value: 40, title: 'Run', color: const Color(0xffe91e63)),
          PieChartSectionData(value: 60, title: 'Walk', color: const Color(0xff9c27b0), badgeWidget: const Icon(Icons.directions_walk)),
        ],
        pieTouchData: PieTouchData(touchCallback: (event, response) {
          final section = response?.touchedSection;
          if (event is FlTapUpEvent && section != null && section.touchedSectionIndex >= 0) {
            setState(() => touched = 'pie ${section.touchedSection!.title}');
          }
        }),
      )),
    ),
  ]);
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    expect(app.builtInBridges, ['fl_chart']);
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      'tool/browser/native_fl_chart_test.cjs',
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Charts passed'));
  });
}
