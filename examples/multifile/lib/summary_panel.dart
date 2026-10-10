import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(
    home: Scaffold(
      body: SummaryPanel(
        icon: Icons.favorite,
        color: Color(0xffef747c),
        title: 'Service status',
        value: 'Ready',
      ),
    ),
  ),
);

class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.note,
    this.compact = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? note;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panel = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, semanticLabel: 'Status'),
          const SizedBox(height: 12),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(value, style: theme.textTheme.titleLarge),
          Text(note ?? 'Synthetic sample'),
        ],
      ),
    );
    if (compact) return panel;
    return Padding(padding: const EdgeInsets.all(24), child: panel);
  }
}
