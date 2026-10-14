import 'expandable_records_panel.dart';

/// Deterministic synthetic data for the fixture. Not real records.
List<RecordEntry> syntheticRecords(int count, {int offset = 0}) => [
  for (var i = offset; i < offset + count; i++)
    RecordEntry(
      label: 'Sample entry ${i + 1}',
      formattedValue: '${(i * 7 % 23) + 1}.${i % 10} units',
      date: i % 4 == 3 ? null : DateTime(2024, 1 + i % 12, 1 + (i * 3) % 28),
      itemId: i % 3 == 2 ? null : 'item-${i + 1}',
    ),
];

const syntheticSummary = [
  SummaryTileData(label: 'Total', value: '42.0 units'),
  SummaryTileData(label: 'Average', value: '4.7 units'),
  SummaryTileData(label: 'Entries', value: '9'),
];
