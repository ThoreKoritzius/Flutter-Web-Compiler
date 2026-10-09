# Contributing

This project is experimental. Help establish correctness and useful boundaries before expanding the supported-widget list.

## Development

Use Dart 3.11.4 and Flutter 3.41.6 to reproduce the checked-in baseline. Runtime parity tests also require Node.js (CI uses Node 22). The package minimum is Dart 3.8; other SDK combinations are not yet certified.

```sh
dart pub get
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze
dart test
dart run bin/flutter_dom.dart build --project examples/catalog --output build/demo
```

Run `dart run tool/benchmark.dart` when changing emitted code or the island runtime. Commit raw measurements with their methodology if updating performance claims. Distinguish artifact sizes from observed transfer, cache behavior and browser timings.

## Useful contributions

- Reduced, original Flutter fixtures with clear expected HTML or browser behavior.
- Constructor/data-flow support, resolved symbols, useful diagnostics and a typed IR.
- Native links, inputs and keyboard interactions with explicit semantics.
- Reproducible layout differences and island lifecycle failures.
- Documented, narrowly scoped package adapters.

For a new capability, include a supported case and a meaningful unsupported/ambiguous case. Do not silently approximate a behavior without documenting the compromise. Source-name counts are not conversion percentages.

## Data and attribution

Use synthetic or explicitly redistributable examples. Do not commit private application source, customer identifiers, local absolute paths, credentials or private inspection reports. Default build and inspection output belongs under ignored `build/`. Preserve third-party license notices when incorporating code or assets.

## Review and conduct

Discuss major runtime or compatibility changes in an issue before implementing them. Keep pull requests focused, document limitations and describe verification. Be respectful and specific: critique ideas and code, and make room for contributors with different backgrounds. Do not harass contributors or publish their private information.

Contributions are made under the repository's BSD-3-Clause license. This project has no affiliation with or endorsement from the Flutter team.
