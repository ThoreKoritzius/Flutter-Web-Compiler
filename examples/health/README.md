# Native health dashboard

Synthetic seven-day data, responsive metric cards and native SVG bar/line charts.

From the repository root:

```sh
dart run bin/flutter_dom.dart build --project examples/health --dom-only --output build/showcase/health
dart run tool/showcase.dart --no-build
```

Open http://127.0.0.1:8097/health/. The full showcase build also includes this demo.

`MetricGrid` and `MetricChart` are explicit native adapter contracts. The Flutter implementations are supplied in the same source; arbitrary CustomPainter or third-party chart packages are not converted. Native charts contain accessible labels and expandable data tables, with no JavaScript or Flutter engine. This first version has fixed mock data; live data, range switching and chart gestures are outside its scope. Values use a zero-based scale.
