# Flutter DOM Compiler

**Flutter source. Native documents. Flutter islands when needed.**

An experimental Dart CLI that compiles a supported subset of existing Flutter UI into HTML and CSS, while retaining explicit interactive regions as lazy-loaded Flutter web islands.

**Early research prototype, not a drop-in Flutter Web replacement.** It does not yet compile arbitrary applications or provide a complete native DOM state runtime.

[Quick start](#quick-start) · [Comparison](#compared-with-flutter-web) · [Benchmarks](#benchmarks) · [Compatibility](docs/COMPATIBILITY.md) · [Roadmap](docs/PLAN.md) · [Contributing](CONTRIBUTING.md)

## Why this approach?

- **Content before engine startup.** Supported text and layout are present in the initial HTML response.
- **Native document structure.** Real paragraphs and explicitly configured headings; ordinary browser text selection and document inspection.
- **No JavaScript for static routes.** The static example emits only HTML and CSS.
- **Preserve complex Flutter regions.** A declared island is compiled by Flutter itself, with its engine cost deferred until activation.
- **Keep supported Flutter source intact.** Metadata, heading intent and island policy live in a sidecar configuration.
- **Make limitations visible.** Unsupported code fails the build; inspection dry-runs widget entry points and lists concrete blockers.

Supported static content includes same-file constants and conditional/spread lists, with bounded evaluation and explicit diagnostics. These benefits depend on the supported subset. One explicit filter-list adapter provides native search; general input widgets, anchors, routing and arbitrary data-driven interaction remain roadmap items.

## Quick start

Use Dart 3.11.4 / Flutter 3.41.6 to reproduce the benchmark. The package minimum is Dart 3.8; other SDK combinations are not yet certified. Python 3 is needed only for the preview command below.

```sh
git clone https://github.com/ThoreKoritzius/Flutter-Web-Compiler.git
cd Flutter-Web-Compiler
dart pub get

# Build all three targets and start the comparison page.
dart run tool/showcase.dart
```

Open [127.0.0.1:8097](http://127.0.0.1:8097). Toggle **Native DOM / CanvasKit / Wasm**, select text, search the features and try the counter. All targets use [the same Dart source](examples/showcase/lib/main.dart). Only the active target loads. Switching resets local state; this is not a state-preserving renderer swap.

Direct targets are `/native/`, `/flutter/` and `/wasm/` on the same server. Use `--port 8098` if needed, or `--no-serve` to build only. The small comparison shell is hand-written HTML; the native target inside it is compiler output. Search uses the documented explicit adapter, not general state transpilation. See [the demo guide](demo/README.md).

For the original minimal counter fixture:

```sh
dart run bin/flutter_dom.dart build --project examples/catalog --output build/demo
python3 -m http.server 8097 --bind 127.0.0.1 --directory build/demo
```

Build the static-only example:

```sh
dart run bin/flutter_dom.dart build --project examples/catalog \
  --config flutter_dom.static.json --dom-only --output build/static
```

The example is also ordinary Flutter source: run `flutter pub get` and `flutter run -d chrome` from `examples/catalog`.

## One CLI

Install from this checkout; it is not published to pub.dev yet:

```sh
dart pub global activate --source path .
flutter_dom --help
flutter_dom inspect --project examples/catalog --output build/inspection.json
flutter_dom build --project examples/catalog --output build/site
```

The executable must be on your `PATH`, usually from Dart's `.pub-cache/bin`. Alternatively, replace `flutter_dom` with `dart pub global run flutter_dom_compiler:flutter_dom`.

`build` (or `build web`) defaults to the current project, `lib/main.dart` and `build/dom`. It discovers a direct `runApp(MyApp())` root; `flutter_dom.json` is optional for plain supported pages and required for explicit adapter/island configuration. `inspect` requires no configuration and does not execute the input app; it scans non-generated Dart files under `lib/` and writes local JSON/Markdown inventories plus a conservative native compatibility score. Each recognized direct widget subclass is compiled as a parameterless DOM-only root; failures include source locations and reasons. This measures compiler acceptance, not the fraction of an entire application that works. Keep private inspection reports outside version control.

For project-local imports, opt into analyzer-backed resolution:

```sh
# First run flutter pub get inside your Flutter project.
flutter_dom build web --resolve-imports
flutter_dom inspect --resolve-imports
```

This resolves relative/package-local imports, exports, prefixes, parts and same-project constants, preserving declaration identity. See the [multi-file example](examples/multifile/README.md). Standard web conditional imports select the web branch independently of the host OS; custom condition variables and unsupported external widget packages fail explicitly; arbitrary application state is still outside the subset. Without the flag, builds and `inspect` retain their existing single-file syntax behavior. Resolved inspection separates static roots, roots needing inputs and unsupported roots. It also checks actual constructor calls using supplied static values, with runtime values reported as needing context. These are isolated checks, not application-wide conversion percentages.

This is an independent tool. It does not patch the SDK or add an official `flutter build dom` command. An editor extension can later wrap the same CLI.

Inside your own Flutter app, after installing the CLI, use:

```sh
flutter_dom inspect
flutter_dom build web
```

The SDK is unchanged: `flutter build dom` is not an official command. Builds show elapsed time, native boundary counts, adapter/island counts and initial file size. Flutter subprocess output is saved to `flutter-build.log`; use `--verbose` to display it. Terminal colors respect `NO_COLOR`. Inspection shows the first five blockers with the complete list in JSON/Markdown.

## Preview a component before porting the whole app

Use explicit constructor inputs and a static theme snapshot to compile existing stateless components without booting application services. See the [component preview guide](docs/COMPONENT_PREVIEWS.md) and [reproducible fixture](examples/multifile/flutter_dom.preview.json). Preview composition and mock data are explicit; this does not infer the application's live theme, state or screen layout.

## Compared with Flutter Web

| Concern | Flutter Web | This prototype |
| --- | --- | --- |
| Existing app compatibility | Broad Flutter APIs, subject to web/plugin constraints | Narrow, explicit subset |
| Initial public content | App content rendered after startup | Supported content in initial HTML |
| Static route JavaScript | Flutter application/runtime | None required |
| Complex graphics and interaction | Core strength | Explicit real Flutter island |
| Flutter engine cost | Required for the application | Deferred until island activation |
| Visual consistency | Flutter layout and rendering | Approximate CSS; differences expected |
| Accessibility | Flutter semantics support | Native structure for supported content; Flutter semantics in islands |
| State, navigation and packages | Existing Flutter implementation | No general DOM equivalents yet |
| SEO foundations | Document-heavy sites need additional consideration | HTML and metadata; no ranking guarantee |
| Maintenance | Supported Flutter toolchain | Additional compiler/adapters and SDK compatibility burden |

Flutter's [web guidance](https://docs.flutter.dev/platform-integration/web) discusses document-oriented scenarios. Flutter Web is not universally slow, inaccessible or unsuitable for the web; it optimizes for a different rendering contract.

### Disadvantages

An activated island still downloads a substantial Flutter bundle. A mixed page can have **higher total cost** than plain Flutter Web, despite a smaller initial document. CSS differs from Flutter's constraint system, and native document behavior can conflict with pixel parity. An unsupported component may require a much larger fallback boundary when it shares state or context.

For authenticated applications, SEO may be irrelevant. Native browser behavior and startup cost are separate motivations. Do not prerender private user data merely to make it indexable.

## Benchmarks

The benchmark builds **the same source widget for each pair**, using release Flutter Web and this compiler. It measures selected initial and post-activation artifacts, with each file separately gzip-compressed at level 9.

<!-- benchmark-table:start -->
| Workload | Build | Initial KiB | Initial gzip KiB | After activation KiB | After activation gzip KiB |
| --- | --- | ---: | ---: | ---: | ---: |
| static | flutter_dom | 2.32 | 1.17 | 2.32 | 1.17 |
| static | flutter_web | 7328.47 | 2652.64 | 7328.47 | 2652.64 |
| hybrid | flutter_dom | 5.05 | 2.26 | 7356.02 | 2660.49 |
| hybrid | flutter_web | 7380.57 | 2667.49 | 7380.57 | 2667.49 |
<!-- benchmark-table:end -->

**Toy-fixture artifact sizes, not observed transfer, browser latency or SEO scores.** The DOM version uses approximate CSS and system fonts. Flutter supplies broader framework behavior. The hybrid version waits for activation; the Flutter baseline exposes its counter immediately. Alternate renderer variants, HTTP overhead, caches and external fallback fonts are excluded.

```sh
dart run tool/benchmark.dart
```

See [methodology and raw results](docs/BENCHMARKS.md). We have not benchmarked FlutterJS or claimed to outperform it.

### Showcase browser audits

The comparison page also displays measured desktop Lighthouse performance/SEO results and server-HTML structure. Run `npm ci --prefix tool/browser` and `npm run audit --prefix tool/browser` with the showcase server running. Requires Node >=22.19 and Chrome. Three fresh-browser runs per target are the default; samples, ranges, settings and limitations are saved in [the audit summary](benchmarks/results/showcase-browser.json).

These are lab diagnostics. Both targets can score 100 for SEO while delivering content differently. Canvas rendering complicates LCP and performance-score comparisons; FCP is not interaction readiness. See [the demo methodology](demo/README.md#measurements).

## How it works

```text
Flutter source + explicit web configuration
                 |
          Dart AST analysis
                 |
       +---------+----------+
       |                    |
 supported static UI    explicit island
       |                    |
    HTML + CSS         Flutter release build
       |                    |
 immediate document    load on activation
```

The current implementation directly evaluates a restricted static AST subset, plus explicit native adapters. A typed intermediate representation and resolved multi-file analysis are planned, not implemented.

## Source and configuration

Supported layout includes `MaterialApp(home:)`, `Scaffold(body:)`, `SingleChildScrollView`, `Text`, `Row`, `Column`, `Padding`, `Container`, `SizedBox` and `Center`, with restricted arguments. Local stateless widgets can pass static data through named final constructor fields and literal defaults. Builds must return a single expression. See the [compatibility contract](docs/COMPATIBILITY.md).

```dart
class Label extends StatelessWidget {
  const Label({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(title);
}
```

```json
{
  "root": "App",
  "title": "My document",
  "description": "A normal HTML description.",
  "lang": "en",
  "headings": { "page-title": 1 },
  "islands": {
    "CounterPanel": { "height": 240, "label": "Load counter" }
  }
}
```

Heading keys match literal `ValueKey` values on `Text`. Omit `islands` for a static build. An island must currently be a public, parameterless widget in the same file; only one instance is supported. The CLI generates its entry point under `.dart_tool/flutter_dom/` without rewriting input Dart files.

The showcase additionally declares `"nativeAdapters": { "FeatureSearch": "filter-list" }`. That opt-in maps a known string-list contract to a native input and local filtering. The same widget's Dart implementation runs in the standard Flutter build.

## Roadmap and related work

Next: resolved imports and data flow, native links/forms, one state-management integration, document routes and safe multi-island boundaries. Compatibility will be measured on independent fixtures, not promised as a percentage of arbitrary apps. See [the plan](docs/PLAN.md) and [the largest engineering gaps](docs/NEXT_STEPS.md).

[Jaspr](https://docs.jaspr.site/) provides a Dart DOM framework and Flutter embedding; it is a candidate output/runtime layer. [FlutterJS](https://github.com/flutterjsdev/flutterjs) documents a broader Flutter-to-JavaScript/runtime approach. Our experiment focuses on the explicit document/real-Flutter boundary. Embedding alone is not a novel feature.

A community proposal may be useful after stronger evidence. Upstream integration is neither assumed nor required. See [the community path and draft discussion](docs/COMMUNITY.md); nothing has been submitted.

## Development and license

```sh
dart analyze
dart test
```

[Contributing](CONTRIBUTING.md) · [Validation](docs/VALIDATION.md) · [Security](SECURITY.md) · [BSD-3-Clause license](LICENSE)

Independent community experiment. Not affiliated with or endorsed by the Flutter team.

## Native health demo

A second [synthetic-data dashboard](examples/health/README.md) demonstrates responsive metric cards, native SVG charts and expandable data tables with no Flutter runtime or JavaScript. Build both native and Flutter targets with `dart run tool/health.dart`, then open `/health/` on the showcase server. Chart geometry is compiled from a restricted subset of the shared Dart `paint()` method; hover, keyboard focus and daily values are available in both targets. Widget and interaction adapters remain explicit; arbitrary chart libraries and state logic are not supported.

### Native local state

A bounded StatefulWidget subset compiles once to HTML and typed expression
bindings. Local booleans/integers, derived text and conditional button enablement
use a shared runtime; no widget-name adapter or state enumeration is used.
Try the [period selector](examples/multifile/lib/period_selector.dart):

```sh
dart run bin/flutter_dom.dart build --project examples/multifile \
  --source lib/period_selector.dart --config flutter_dom.state.json \
  --resolve-imports --dom-only --output build/reactive-demo
python3 -m http.server 8112 --directory build/reactive-demo
```

Open http://localhost:8112 to switch periods, add/remove sessions and see derived
minutes update. Buttons support mouse and keyboard activation.
The same source runs in Flutter with
`flutter run -d chrome -t lib/period_selector.dart` from `examples/multifile`.
Providers, lifecycle methods and general Dart logic remain unsupported. See [supported state and limitations](docs/NATIVE_STATE.md).


### Compose original components

Preview configuration can pass another project-local widget into a `child` slot.
Simple instance getters, optional content, Card and Expanded now support richer
read-only compositions without rewriting widget bodies. See the
[composed preview example](docs/COMPONENT_PREVIEWS.md#composed-previews).


### Native records with constructor inputs

The [records fixture](examples/multifile/lib/record_list.dart) compiles original
StatefulWidget inputs, `widget.field`, collection for-in and a conditional static
list into DOM. An imported immutable model supplies typed fields, pure getters and expression
helpers; the state class constructs rows through its own helper.
Show all / Show fewer retains existing rows and uses native buttons.
No adapter or Flutter engine is involved.

```sh
dart run bin/flutter_dom.dart build --project examples/multifile \
  --source lib/record_list.dart --config flutter_dom.records.json \
  --resolve-imports --dom-only --output build/record-list
python3 -m http.server 8113 --bind 127.0.0.1 --directory build/record-list
```

Open http://localhost:8113. For the same Flutter implementation, run
`flutter run -d chrome -t lib/record_list.dart` from `examples/multifile`.
These are synthetic static inputs, not live model loading. See the
[exact state contract](docs/NATIVE_STATE.md) for unsupported behavior.
