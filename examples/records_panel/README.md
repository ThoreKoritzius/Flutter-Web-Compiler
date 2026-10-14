# Expandable records panel fixture

An independently written, generic Flutter fixture for the experimental
`--dart-runtime` target. All records are **synthetic** and generated in
`lib/synthetic_records.dart`; nothing here is taken from a real application.

It exercises:

- a nested `StatefulWidget` (`ExpandableRecordsPanel`) holding `expanded`,
  with six records visible until "Show all" / "Show fewer" is pressed;
- records with a label, formatted value, optional date and optional item ID;
- optional row callbacks: rows are buttons only when a callback exists and the
  record has an item ID;
- an empty state, header badge, optional summary tiles and a coverage note;
- theme-derived colors, rounded `Container`/`BoxDecoration` surfaces,
  `Align`, `TextButton`, `LayoutBuilder` breakpoints and Material icons;
- shared tile and row widgets built from ordinary Flutter widgets.

```sh
dart run bin/flutter_dom.dart build web --project examples/records_panel \
  --dart-runtime --output build/records-panel
```

The same source runs under Flutter (`flutter run -d chrome`) for comparison.
`test/records_panel_test.dart` compiles it with dart2js and checks state
retention, input updates, disposal, stale callbacks, keyboard activation and
responsive layout against a DOM contract harness.
