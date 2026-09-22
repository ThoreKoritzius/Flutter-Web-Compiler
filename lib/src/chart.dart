import 'dart:convert';

/// Static native chart contract. No arbitrary CustomPainter conversion.
String nativeChart(Map<String, Object?> options) {
  String escape(Object? value) => const HtmlEscape().convert('$value');
  final values = options['values'];
  final label = options['label'];
  final display = options['display'];
  final color = options['color'] ?? '#8b9dff';
  final kind = options['kind'] ?? 'bar';
  if (values is! List ||
      values.isEmpty ||
      values.length > 60 ||
      values.any((v) => v is! num || !v.isFinite || v < 0) ||
      label is! String ||
      display is! String ||
      color is! String ||
      !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color) ||
      !['bar', 'line'].contains(kind)) {
    throw ArgumentError(
      'metric-chart needs label/display strings, 1–60 nonnegative finite values, a hex color and bar/line kind.',
    );
  }
  final data = values.cast<num>();
  final maximum = data.fold<num>(1, (a, b) => a > b ? a : b);
  final step = 320 / data.length;
  final points = <String>[];
  final shapes = StringBuffer();
  for (var i = 0; i < data.length; i++) {
    final x = (i + .5) * step, y = 100 - data[i] / maximum * 88;
    points.add('${x.toStringAsFixed(2)},${y.toStringAsFixed(2)}');
    if (kind == 'bar')
      shapes.write(
        '<rect x="${(i * step + 2).toStringAsFixed(2)}" y="$y" width="${step - 4}" height="${100 - y}" rx="3" fill="$color"><title>Day ${i + 1}: ${data[i]}</title></rect>',
      );
  }
  if (kind == 'line')
    shapes.write(
      '<polyline points="${points.join(' ')}" fill="none" stroke="$color" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>',
    );
  return '<article class="metric-card"><p class="metric-label"><span style="background:$color"></span>${escape(label)}</p>'
      '<h2>${escape(display)}</h2><p class="metric-period">7-day sample · mock data</p>'
      '<svg viewBox="0 0 320 108" preserveAspectRatio="none" role="img" aria-label="${escape(label)}: ${escape(data.join(', '))}">'
      '<path d="M0 100H320 M0 55H320 M0 12H320" stroke="currentColor" opacity=".08"/>$shapes</svg>'
      '<details><summary>Daily values</summary><table><thead><tr><th>Day</th><th>${escape(label)}</th></tr></thead><tbody>'
      '${[for (var i = 0; i < data.length; i++) '<tr><td>${i + 1}</td><td>${data[i]}</td></tr>'].join()}'
      '</tbody></table></details></article>';
}
