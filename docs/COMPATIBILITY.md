# Compatibility contract

This document describes implemented behavior. The roadmap is not part of the compatibility promise.

## Static source model

- Default mode: one Dart source file selected with `--source` (default `lib/main.dart`). Opt-in resolved project mode is described below.
- Local classes directly extending `StatelessWidget`.
- A return expression in `build`, either arrow syntax or a block with initialized `final`/`const` locals followed by one return. Mutable/late locals, side-effect statements and control-flow statements remain unsupported.
- Literal strings, adjacent strings, numbers, booleans, null and literal lists.
- Same-file top-level `const` values (including forward references), boolean `!`, list `if`/`else`, list spreads and null-aware spreads. Only selected branches are evaluated.
- Named or positional `this.field` parameters bound to final instance fields, including required inputs and supported static defaults. `super.key` is allowed.
- Static data is resolved per widget instance; child widgets can be passed through constructor fields too.
- No named/factory/redirecting constructors, constructor bodies, initializer lists or mutable fields.
- No imported custom widgets, aliases, complete symbol/type resolution, runtime getters, collection `for`/patterns, async builders or API data loading.

The parser recognizes unprefixed constructor names syntactically. This assumes they refer to the expected Flutter APIs; shadowed names are not resolved. Input should also pass `flutter analyze`. Parsing is not evidence of semantic compatibility.

## Widget subset

| Widget | Supported arguments |
| --- | --- |
| `MaterialApp` | `home`, `title`, `debugShowCheckedModeBanner` |
| `Scaffold` | `body` |
| `SingleChildScrollView` | `child`; browser document scrolling, no controller/physics mapping |
| `Text` | String content, `style`, `textAlign`, literal `ValueKey` |
| `TextStyle` | `fontSize`, `fontWeight` |
| `Row`, `Column` | Literal `children`, common main/cross alignment, `MainAxisSize.min` |
| `Padding` | `padding`, `child` |
| `Container` | `padding`, literal `width`/`height`, `child` |
| `SizedBox` | Literal `width`/`height`, optional `child` |
| `Center` | `child` |

Insets support `EdgeInsets.all` and `EdgeInsets.symmetric`. Dimensions must be finite and non-negative. Unsupported arguments produce errors. `ValueKey` controls explicitly configured heading semantics; Flutter element identity is not emulated on the DOM side.

## Layout and document semantics

Rows/columns use CSS flex with content-driven sizing. Explicit `MainAxisSize.max` is rejected, while omitted sizing uses the documented web approximation. Browser fonts and intrinsic sizing differ from Flutter. The base stylesheet is a prototype presentation theme, not a Material theme translator.

Text becomes an escaped paragraph by default; sidecar heading declarations map keys to H1–H6. Automatic document outline inference, images, anchors, canonical URLs, structured data, routing and general native form controls remain unimplemented.

## Explicit native filter-list adapter

The sidecar can declare `"nativeAdapters": { "WidgetName": "filter-list" }`. The widget must exist in the same input file. Its supported arguments are static `items: List<String>`, optional `label` and `hintText`, and a literal key. It emits a labeled search input, an initial HTML list and a live result count. Filtering trims whitespace, lowercases text and performs substring matching. Empty queries restore all items. Multiple instances have independent controls.

This is a deliberately written adapter contract. It does not analyze or translate the widget's arbitrary Dart callbacks, asynchronous logic or state. The standard Flutter implementation supplied by the application must match this contract if behavioral equivalence is desired. No selection callback or state sharing is supported.

## Flutter islands

One explicitly configured, parameterless public widget in the input file. Its state and context stay in Flutter. The entry point wraps it in `MaterialApp`; application-specific inherited state or initialization may need a future adapter. No automatic boundary inference or cross-renderer state synchronization exists.

The page loads an external bootstrap only after activation. The compiler derives it from Flutter's default output and rejects custom bootstrap formats. This is temporary SDK coupling. The loader configures the host element, local assets and CanvasKit; the engine still costs megabytes when activated.

## Project inspection

`inspect` scans non-generated Dart files under `lib/`, all conditional branches included. It reports class bases, constructor-like call names, dependency names, parser diagnostics and review signals. It excludes dependencies and symlinks and does not execute or modify the application.

It does **not** establish reachability, package compatibility, rendered widget counts, safe island cuts or a DOM conversion percentage. Private reports should remain in ignored output directories.

### Conservative compatibility score

The CLI also dry-runs every recognized direct widget subclass as a parameterless, DOM-only root. The score is accepted entry points divided by tested entry points; zero candidates yields N/A. Reports list each widget, file, declaration line and its first blocking compiler diagnostic. This exercises the real compiler, including arguments and expressions, instead of counting familiar widget names.

Required constructor arguments, imported definitions, stateful widgets and unresolved context are conservatively blocked. Adapters and islands are disabled for this measurement. A reusable widget may therefore fail in isolation while compiling when called with static data from a supported parent. Indirect subclasses and aliased types are outside the denominator. This score measures compiler acceptance, not verified behavior or a percentage of the whole application. Run Flutter analysis separately.

Static primitive string interpolation and boolean conditional expressions are now supported, including constructor-bound values. Only the selected static branch is compiled. Runtime conditions remain unsupported.

### Images and tables

`Image.asset` supports a project-relative local path, static width/height, `BoxFit.cover`/`contain`/`fill` and a static `semanticLabel` (HTML alt text). The CLI copies referenced files, rejecting traversal and symlinks escaping the input project. Asset variants, bundles, animated formats and error/loading builders are not implemented. Referenced assets must also be declared in the Flutter pubspec for the Flutter targets.

Static `DataTable`, `DataColumn(label:)`, `DataRow(cells:)` and `DataCell(child)` emit a semantic HTML table with column headers and horizontal overflow. Sorting, selection, callbacks and custom table themes are unsupported. `SingleChildScrollView(scrollDirection: Axis.horizontal)` maps to horizontal browser overflow.

### Entry discovery and build counts

`flutter_dom build` (also `flutter_dom build web`) uses the current directory and `lib/main.dart`. Without a sidecar it infers a single direct `runApp(MyApp())` root; ambiguous startup, conditional startup and extra initialization statements require explicit configuration. Startup logic is never executed or translated. A sidecar is still needed for island/adapter/heading intent. This is project-oriented invocation, not resolved multi-file app compilation.

The build summary counts visited rendering boundaries; a native adapter counts as native, a Flutter island as fallback, and traversal stops at both. Its percentage describes the selected compiled tree only. `inspect` uses the separate, stricter independent-root metric. Neither measures application-wide behavioral compatibility.

### Static chart and grid adapters

`responsive-grid` accepts static `children` and emits a CSS grid (four/two/one columns). `metric-chart` accepts `label`, `display`, `values` (1–60 finite nonnegative numbers), optional six-digit hex `color` and `kind` (`bar` or `line`). It emits native SVG with accessible data and a browser-native expandable table; no script is required. The sidecar can choose `theme: dark`. These are explicit adapters, not arbitrary chart-library or CustomPainter translation. See the synthetic [health fixture](../examples/health/README.md).

`MaterialApp(theme: ThemeData.dark())` selects the approximate dark DOM presentation; custom ThemeData arguments are rejected. This is not general Material theme translation.


### Restricted painter compilation

Configure `"MetricChart": {"type": "paint-chart", "painter": "_ChartPainter"}` to derive geometry from a CustomPainter class in the same source file. The adapter binds static `values`, `color` and `kind` fields and accepts the metric-chart contract above. Supported drawing statements are interpreted at build time with a bounded operation budget; unsupported syntax and Canvas operations fail explicitly. No application Dart is executed.

The initial subset supports numeric arithmetic/comparisons, conditions, simple for loops, list indexing/fold, Paint color/style/strokeWidth, Rect.fromLTWH, Path.moveTo/lineTo, Canvas.scale/drawRect/drawPath. It does not resolve imported painters, arbitrary method calls, shaders, text painting or general state. The chart wrapper, hover/focus targets and daily-values disclosure still use an explicit adapter; the compiler does not infer these from arbitrary widget implementations. See the [health fixture and geometry check](../examples/health/README.md).


### Static data evaluation

Top-level constants are evaluated lazily in their own lexical scope, cached per compilation, and cannot capture a widget's constructor fields. Constructor fields may shadow a top-level name. Defaults can reference supported constants. Cycles, excessive nesting (128 constant references), evaluation beyond 20,000 steps and spread expansion beyond 20,000 items fail with diagnostics. These are protective implementation limits, not a Dart language specification.

```dart
const showDetails = true;
const shared = [Text('Shared content')];
// Within a supported build expression:
// Column(children: [...shared, if (showDetails) Text('Details')])
```

Only `const` declarations are eligible; `final` globals, getters, imported constants, static class fields, arbitrary function calls and collection patterns remain unsupported. This syntax evaluator does not replace `flutter analyze` or perform full Dart type/constant validation. Unselected static branches and unused declarations are not compiled.


### Resolved project analysis (experimental)

`build --resolve-imports` uses analyzer project contexts and `.dart_tool/package_config.json`. Run `flutter pub get` beforehand. The entry must be within project `lib/`. The resolver follows reachable project-local imports/exports and library parts; relative and package-local URIs, prefixes and show/hide combinators use Dart's resolved namespaces. Local declarations are keyed by source path and symbol identity, so duplicate short names remain distinct. Class and constant ASTs retain their source files; compiler failures identify file/line/column. Report `sourceFiles` lists loaded project units, not every transitive SDK dependency.

All analyzer errors in those project units fail the build, including errors in unused declarations of a loaded unit. Unrelated project files are not compiled. Package/SDK dependencies are resolved for symbol identity, but their custom widget implementations are not expanded. Framework constructors are recognized by resolved Flutter declarations; a local `Text` class or function is not treated as Flutter's `Text`.

Conditional imports/exports use the fixed web-JavaScript analysis environment described below. Imported adapter/island declarations are also rejected; existing entry-file configurations remain supported. Named constructors, general methods/getters, inherited widget implementations and dynamic state retain their existing restrictions. `inspect --resolve-imports` checks the selected web library graph; unflagged inspection retains its original syntax-only behavior. Root configuration accepts a name visible from the entry library, including an import prefix. The unflagged library/CLI API remains syntax-only.

The analyzer 7 element model used here is experimental. Its APIs are isolated primarily in `project.dart`, the dependency is pinned to analyzer 7.7.1, and resolver fixtures run in CI. A stable project-analysis API and typed lowering representation remain future work.


### Web conditions and resolved inspection

Resolved builds and inspection use the same fixed `web-js` target, independent of the host OS. `dart.library.html`, `js`, `js_util`, `js_interop` and `ui` are true; `io`, `ffi` and `isolate` are false (each name uses the `dart.library.` prefix). Analyzer selects the first matching conditional URI, including explicit string equality, and falls back to the unconditional URI when none matches. Unrecognized project condition variables fail explicitly; custom `-D` conditions and Wasm-target selection are not implemented. This chooses source declarations; it does not grant DOM support to their runtime APIs.

The public analyzer factory cannot set declared variables in the pinned release. `analysis_environment.dart` isolates the internal factory needed to supply this environment. Resolver regression tests and real Flutter fixture builds guard the dependency. Build and inspection reports include `analysisTarget`, `conditionalEnvironment` and selected conditional directives.

`inspect --resolve-imports [--source lib/main.dart]` emits schema version 4. Compatibility checks use direct, recognized widget subclasses from selected project libraries/parts, resolved by declaration identity. Each is compiled independently with no arguments, adapters or islands. Required inputs remain blockers; inactive platform implementations and unrelated libraries are excluded from this denominator. Inventory counts remain project-wide syntax counts and can include those files. Generated parts required by the selected graph are resolved even though inventory excludes generated files. Resolution errors abort inspection instead of producing a misleading score. This score is not directly comparable with the unflagged project-wide syntax score.


### Input-aware inspection results

Resolved inspection now presents two separate breakdowns instead of a headline percentage:

- **Widget roots:** static, needs inputs, or unsupported. Required constructor inputs are a distinct first blocker, not evidence that the widget body is incompatible.
- **Constructor sites:** actual project-widget constructor expressions checked independently with their supplied arguments. Static literals, supported constants and nested constructors can compile. Unbound enclosing identifiers need context; unsupported syntax or rendering operations remain unsupported. Categories describe the first blocker; supplying context does not guarantee the remainder will compile.

The compiler evaluates the original resolved constructor AST, so it does not generate guessed arguments or substitute source strings. Calls in unused functions or inactive runtime branches are still source sites, and nested calls may each be counted. This is not runtime reachability, unique screen coverage or verified behavior. Inspection does not perform interprocedural propagation of enclosing locals, parameters or state.

Checks are bounded to 1,000 constructor sites, sorted by source file and offset. `callSites` reports total, checked, skipped, limit, separate outcome counts and located entries. Skipped sites are not classified. Root records keep the prior `status`, `native`, `total` and `percent` fields for consumers, with new `category`, diagnostic `code`, `needsInputs` and `unsupported` fields. The resolved CLI/Markdown view uses categories; the legacy percentage still means parameterless-root acceptance only.

An apparent score decrease can reflect a different graph: a whole-project syntax scan may accept a non-web fallback whose selected web implementation is unsupported. Compare graph and metric before interpreting differences as a regression.


### Static component data flow and themes

Initialized local final/const values are evaluated in order, with per-instance scope and separate `this.field` bindings. Numeric arithmetic (`+`, `-`, `*`, `/`, `~/`, `%`), numeric comparisons, short-circuit boolean operations and string concatenation are supported within the existing operation budget. Division by zero and non-finite results fail. This is bounded static evaluation, not arbitrary Dart execution or runtime state translation. Primitive constructor field types are checked; numeric inputs to explicit double fields are promoted to double.

An explicit `staticTheme` snapshot enables Theme.of, selected textTheme/colorScheme properties, TextStyle.copyWith and Color.withValues(alpha:). No theme values are guessed from application startup. Text supports positive maxLines through browser CSS line clamping; truncation and text metrics are approximate. Container supports BoxDecoration with a static theme color and BorderRadius.circular. Unsupported decoration/style fields still fail.

The [component preview guide](COMPONENT_PREVIEWS.md) documents configuration-driven composition and static constructor arguments. Reports distinguish `componentPreview` and `staticThemeProvided`; neither proves general application compatibility. Inspector runs without these snapshots remain conservative.
