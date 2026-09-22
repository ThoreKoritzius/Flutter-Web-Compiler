# Native health dashboard

Synthetic seven-day data, responsive metric cards and native SVG bar/line charts.

From the repository root:

```sh
dart run tool/health.dart
dart run tool/showcase.dart --no-build
```

Open http://127.0.0.1:8097/health/ and switch Native SVG / Flutter CanvasKit. Direct targets are `/health/native/` and `/health/flutter/`. Both compile the same Dart file and literal mock values. The full showcase build also includes this demo.

## What is compiled

Both targets use the same Dart file, mock values and `_ChartPainter.paint()` method. The `paint-chart` adapter interprets the supported Dart drawing statements at build time and emits SVG rectangles and paths. Changing supported painter geometry changes the SVG; unsupported operations fail compilation.

The supported subset includes arithmetic, bounded loops, conditions, list indexing/fold, `Paint`, `Rect.fromLTWH`, `Path.moveTo/lineTo`, `Canvas.scale`, `drawRect` and `drawPath`. The shared painter uses a normalized 320 × 110 coordinate space. This is a deliberately restricted interpreter, not general Dart execution or arbitrary chart-library support.

`MetricGrid`, the chart card and its interaction layer remain explicit adapter contracts. Hover and keyboard focus reveal daily values in both targets; both also provide expandable daily values. The DOM implementation uses SVG focus targets, CSS and HTML details/table elements, with no JavaScript or Flutter engine. Flutter uses Focus, MouseRegion and ExpansionTile. Arbitrary state-management logic is not translated, and CSS layout is approximate.

All data is fixed and synthetic. Live data, range switching, gestures, shaders and arbitrary painters are outside this demo's scope. Values use a zero-based scale.

## Geometry validation

```sh
dart run tool/check_health_geometry.dart
```

This records drawing commands from the actual Flutter painter and compares rectangle coordinates, path bounds/length, stroke width and scale against compiled SVG for bar and line fixtures (tolerance 0.001). It verifies those geometry cases, not pixel-perfect rendering across browsers or complete widget equivalence.
