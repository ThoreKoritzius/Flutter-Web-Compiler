# Native health dashboard

Synthetic seven-day data, responsive metric cards and native SVG bar/line charts.

From the repository root:

```sh
dart run tool/health.dart
dart run tool/showcase.dart --no-build
```

Open http://127.0.0.1:8097/health/ and switch Native SVG / Flutter CanvasKit. Direct targets are `/health/native/` and `/health/flutter/`. Both compile the same Dart file and literal mock values. The full showcase build also includes this demo.

`MetricGrid` and `MetricChart` are explicit native adapter contracts. The Flutter implementations are supplied in the same source; arbitrary CustomPainter or third-party chart packages are not converted. Native charts contain accessible labels and expandable data tables, with no JavaScript or Flutter engine. This first version has fixed mock data; live data, range switching and chart gestures are outside its scope. Values use a zero-based scale.


## What is and is not compiled

The native output contains real SVG geometry and HTML tables. It has no Flutter canvas, screenshot or engine. However, the compiler uses a handwritten adapter for the named chart contract; it does not derive geometry from `_ChartPainter.paint`. Flutter uses the supplied CustomPainter. This is a useful backend adapter, not proof of general chart conversion.

A stronger next milestone is a shared drawing intermediate representation (rectangles, paths, text and transforms) with Flutter and SVG backends, or a deliberately restricted translator for supported Canvas operations. Both need parity tests for geometry, scales and labels. Unsupported shaders, blending, fonts and gestures must remain explicit blockers or Flutter islands. Live data additionally needs state and event integration.
