# Flutter DOM Compiler

An experimental build tool that turns a **small, static subset of existing Flutter source into HTML and CSS**, with an explicitly selected Flutter widget loaded on demand as an island.

The goal is to reuse Flutter UI for fast, indexable native web pages, while keeping Flutter available for complex interactions. This is a feasibility prototype, **not a drop-in replacement for Flutter Web**.

## What works in v0.1

- Parses real Dart source with the Dart analyzer; no regex widget conversion.
- Expands local, field-free `StatelessWidget` classes with a single return expression.
- Converts literal text and basic layout into static HTML and approximate CSS.
- Generates page title, description, language and explicit heading levels from a sidecar configuration.
- Compiles one explicit, parameterless Flutter island using the real Flutter toolchain.
- Loads that island only after a native button is pressed. The document itself needs no Flutter engine.
- Reports unsupported expressions and widget arguments as build errors.
- Supports strict `--dom-only` builds which reject islands.

The included example is also a normal runnable Flutter application. Its source imports only Flutter; web-specific configuration lives in `flutter_dom.json`.

## Run the prototype

Requirements: Dart 3.8+ and a Flutter SDK on `PATH`. Tested versions and verification results are in [docs/VALIDATION.md](docs/VALIDATION.md). The first Flutter build may download SDK artifacts and dependencies.

```sh
dart pub get
dart run bin/flutter_dom.dart
python3 -m http.server 8097 --bind 127.0.0.1 --directory build/demo
```

Open [127.0.0.1:8097](http://127.0.0.1:8097). Text and headings are already HTML. Click **Load Flutter counter** to download Flutter, then use the counter.

To run the original application with ordinary Flutter:

```sh
cd examples/catalog
flutter pub get
flutter run -d chrome
```

Build a different supported project:

```sh
dart run bin/flutter_dom.dart --project path/to/project --source lib/main.dart --output build/site
```

Build the static-only example from the same source file, with **zero JavaScript**:

```sh
dart run bin/flutter_dom.dart --config flutter_dom.static.json --dom-only --output build/static
```

The input project needs `flutter_dom.json`. If it contains an island, it also needs normal Flutter web project scaffolding (`web/index.html`). The CLI generates an island entry point under that project's `.dart_tool/flutter_dom/`; it does not rewrite the input Dart files.

## Configuration

```json
{
  "root": "App",
  "title": "My page",
  "description": "An ordinary HTML description.",
  "lang": "en",
  "headings": { "page-title": 1 },
  "islands": {
    "CounterPanel": { "height": 240, "label": "Load counter" }
  }
}
```

The `headings` keys match literal Flutter `ValueKey` values on `Text` widgets. Omit `islands` for a static page with no generated JavaScript. Only one island instance is supported for now. It must be a public widget in the same source file, with a zero-required-argument constructor.

## Supported subset

| Input | Output / limits |
| --- | --- |
| `MaterialApp(home: ...)` | Compiles home; accepts title and debug banner settings |
| `Scaffold(body: ...)` | `<main>` |
| `Text` | Escaped paragraph or explicitly configured heading |
| `TextStyle` | Literal font size and supported font weights |
| `Column`, `Row` | CSS flex; common alignments; content-driven sizing |
| `Padding`, `Container` | Padding, literal dimensions, child |
| `SizedBox` | Literal dimensions, optional child |
| `Center` | CSS flex centering |
| Local stateless composition | No constructor data flow, instance fields or dynamic build logic |
| Explicit island | Actual Flutter build; isolated state; click to load |

Padding supports `EdgeInsets.all` and `EdgeInsets.symmetric`. Text alignment is supported. Unknown named arguments fail rather than disappearing. `ValueKey` is used only for explicit HTML semantics; Flutter identity is not emulated on the static side.

## Deliberate limits

This is syntax-aware compilation, not whole-program type resolution. It reads one file and recognizes unprefixed Flutter constructor names. It assumes those names refer to Flutter APIs; import aliases, shadowed names and imported custom widgets are not supported. Run `flutter analyze` on input projects as well.

There is no DOM state runtime, hydration, automatic island inference, shared provider/context bridge, route discovery, server data fetching, image support or general Material compatibility yet. The example's counter stays entirely in Flutter. Flutter plugins and widgets that need ancestor context may require explicit wrapper adapters; fallback is not universally safe.

Layout is an approximation. CSS intrinsic sizing differs from Flutter constraints. The generated base stylesheet is a prototype presentation theme, not a pixel-preserving reproduction of Material styles. Defaults for rows/columns use web content sizing; explicit `MainAxisSize.max` is rejected.

The first island activation downloads a real Flutter application and engine. It is **not** a lightweight interactive DOM component. Inspect initial and post-activation transfer separately. Static HTML enables indexing, but does not guarantee rankings or solve routing, canonicals, structured data or content quality.

The island bootstrap currently derives an external script from the default generated Flutter loader format. Projects with custom bootstrap files are rejected. Full CSP support and a stable custom-bootstrap integration are follow-up work. Host the output over HTTP, not `file://`.

## Development

```sh
dart analyze
dart test
```

See [the implementation plan](docs/PLAN.md) for the intended architecture and milestone gates. Generated HTML, Flutter bundles and SDK caches are ignored by Git. Dependency lockfiles are committed for reproducibility.

## Project status

Research prototype. Compatibility is intentionally narrow. No claim of automatic conversion percentages or Flutter behavior parity.
