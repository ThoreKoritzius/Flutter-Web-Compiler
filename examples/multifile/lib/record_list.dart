import 'package:flutter/material.dart';
import 'record_entry.dart';

void main() => runApp(
  const MaterialApp(
    home: Scaffold(
      body: RecordList(
        title: 'Recent deliveries',
        items: [
          RecordEntry('Design review', minutes: 30),
          RecordEntry('Documentation', minutes: 45),
          RecordEntry('Release notes', minutes: 20),
          RecordEntry('Accessibility audit', minutes: 60),
          RecordEntry('Integration checks', minutes: 40),
        ],
      ),
    ),
  ),
);

class RecordList extends StatefulWidget {
  const RecordList({
    super.key,
    required this.title,
    required this.items,
    this.visibleCount = 2,
    this.initiallyExpanded = false,
  });
  final String title;
  final List<RecordEntry> items;
  final int visibleCount;
  final bool initiallyExpanded;

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  late bool expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final shown = expanded
        ? widget.items
        : widget.items.take(widget.visibleCount).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              for (final item in shown) ...[
                Text(item.label),
                const SizedBox(height: 12),
              ],
              if (widget.items.length > widget.visibleCount)
                OutlinedButton(
                  onPressed: () => setState(() => expanded = !expanded),
                  child: Text(
                    expanded ? 'Show fewer' : 'Show all ${widget.items.length}',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
