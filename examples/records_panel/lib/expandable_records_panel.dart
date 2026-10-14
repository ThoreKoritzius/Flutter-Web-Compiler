import 'package:flutter/material.dart';

import 'widgets/record_tiles.dart';

class RecordEntry {
  const RecordEntry({
    required this.label,
    required this.formattedValue,
    this.date,
    this.itemId,
  });

  final String label;
  final String formattedValue;
  final DateTime? date;
  final String? itemId;
}

class SummaryTileData {
  const SummaryTileData({required this.label, required this.value});
  final String label;
  final String value;
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// A titled list of records that shows six entries until expanded.
class ExpandableRecordsPanel extends StatefulWidget {
  const ExpandableRecordsPanel({
    super.key,
    required this.title,
    required this.records,
    this.summary,
    this.coverageNote,
    this.onRecordTap,
    this.collapsedCount = 6,
  });

  final String title;
  final List<RecordEntry> records;
  final List<SummaryTileData>? summary;
  final String? coverageNote;
  final ValueChanged<RecordEntry>? onRecordTap;
  final int collapsedCount;

  @override
  State<ExpandableRecordsPanel> createState() => _ExpandableRecordsPanelState();
}

class _ExpandableRecordsPanelState extends State<ExpandableRecordsPanel> {
  bool expanded = false;

  @override
  void didUpdateWidget(ExpandableRecordsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Collapse again if the list shrinks below the toggle threshold.
    if (widget.records.length <= widget.collapsedCount) expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final records = widget.records;
    final canExpand = records.length > widget.collapsedCount;
    final visible = expanded || !canExpand
        ? records
        : records.take(widget.collapsedCount).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        return RoundedSurface(
          color: scheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.title, style: theme.textTheme.titleMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${records.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.summary != null && widget.summary!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SummaryTiles(tiles: widget.summary!, wide: wide),
              ],
              const SizedBox(height: 8),
              if (records.isEmpty)
                const _EmptyState()
              else
                for (final record in visible)
                  RecordRow(
                    key: ValueKey(record.itemId ?? record.label),
                    label: record.label,
                    value: record.formattedValue,
                    detail: record.date == null ? null : _formatDate(record.date!),
                    compact: !wide,
                    onTap: widget.onRecordTap == null || record.itemId == null
                        ? null
                        : () => widget.onRecordTap!(record),
                  ),
              if (canExpand)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => expanded = !expanded),
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(expanded ? 'Show fewer' : 'Show all'),
                  ),
                ),
              if (widget.coverageNote != null) ...[
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.coverageNote!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.tiles, required this.wide});

  final List<SummaryTileData> tiles;
  final bool wide;

  static const _icons = [
    Icons.functions_rounded,
    Icons.show_chart_rounded,
    Icons.format_list_numbered_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final children = [
      for (var i = 0; i < tiles.length; i++)
        SummaryTile(
          label: tiles[i].label,
          value: tiles[i].value,
          icon: _icons[i % _icons.length],
        ),
    ];
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: scheme.outline),
          const SizedBox(height: 8),
          Text(
            'No records yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
