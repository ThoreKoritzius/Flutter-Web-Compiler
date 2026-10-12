# Official Dart logic + DOM experiment

Run `dart run tool/logic_demo.dart` from the repository root, then open
http://127.0.0.1:8121/. Use refresh, failure and retry to exercise live synthetic
HTTP responses. No Flutter engine is loaded.

`lib/repository.dart` is pure Dart shared unchanged between VM tests and official
JavaScript compilation. `lib/browser.dart` supplies explicit browser transport
and DOM adapters. The host is handwritten, not converted from a Flutter widget.

See [the architecture and limitations](../../docs/LOGIC_RUNTIME.md).
