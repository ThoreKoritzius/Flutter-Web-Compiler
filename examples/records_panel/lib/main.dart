import 'package:flutter/material.dart';

import 'expandable_records_panel.dart';
import 'synthetic_records.dart';

void main() => runApp(const FixtureApp());

class FixtureApp extends StatelessWidget {
  const FixtureApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Records panel fixture',
    theme: ThemeData(
      colorScheme: const ColorScheme.light(primary: Color(0xff3f51b5)),
    ),
    home: const FixtureHost(),
  );
}

/// Host controls exercise the panel's lifecycle with synthetic records only.
class FixtureHost extends StatefulWidget {
  const FixtureHost({super.key});

  @override
  State<FixtureHost> createState() => _FixtureHostState();
}

class _FixtureHostState extends State<FixtureHost> {
  List<RecordEntry> records = syntheticRecords(9);
  int rebuilds = 0;
  bool showPanel = true;
  bool selectable = true;
  String selected = 'none';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Synthetic records fixture')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => rebuilds++),
                child: const Text('Rebuild host'),
              ),
              OutlinedButton(
                onPressed: () => setState(
                  () => records = [
                    ...records,
                    ...syntheticRecords(1, offset: records.length),
                  ],
                ),
                child: const Text('Add record'),
              ),
              OutlinedButton(
                onPressed: () => setState(() => records = const []),
                child: const Text('Clear records'),
              ),
              OutlinedButton(
                onPressed: () => setState(() => selectable = !selectable),
                child: Text(selectable ? 'Disable selection' : 'Enable selection'),
              ),
              OutlinedButton(
                onPressed: () => setState(() => showPanel = !showPanel),
                child: Text(showPanel ? 'Remove panel' : 'Restore panel'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Host rebuilds: $rebuilds · Selected: $selected'),
          const SizedBox(height: 16),
          if (showPanel)
            ExpandableRecordsPanel(
              title: 'Synthetic records',
              records: records,
              summary: syntheticSummary,
              coverageNote:
                  'Synthetic fixture data; coverage notes appear here.',
              onRecordTap: selectable
                  ? (record) => setState(() => selected = record.label)
                  : null,
            ),
        ],
      ),
    ),
  );
}
