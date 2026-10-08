import 'package:flutter/material.dart' as ui;

class SampleStat extends ui.StatelessWidget {
  const SampleStat(
    this.label, {
    super.key,
    required this.value,
    this.spacing = 8,
  });
  final String label;
  final String value;
  final double spacing;

  @override
  ui.Widget build(ui.BuildContext context) {
    final theme = ui.Theme.of(context);
    final gap = spacing / 2;
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: ui.FontWeight.w800,
    );
    return ui.Column(
      crossAxisAlignment: ui.CrossAxisAlignment.start,
      children: [
        ui.Text(value, style: style, maxLines: 1),
        ui.SizedBox(height: gap),
        ui.Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
