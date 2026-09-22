# Compatibility contract

This document describes implemented behavior. The roadmap is not part of the compatibility promise.

## Static source model

- One Dart source file, selected with `--source` (default `lib/main.dart`).
- Local classes directly extending `StatelessWidget`.
- A single return expression in `build`, either arrow syntax or a block with one return.
- Literal strings, adjacent strings, numbers, booleans, null and literal lists.
- Named `this.field` parameters bound to final instance fields, with required arguments or literal defaults. `super.key` is allowed.
- Static data is resolved per widget instance; child widgets can be passed through constructor fields too.
- No named/factory/redirecting constructors, constructor bodies, initializer lists, positional field arguments or mutable fields.
- No imported custom widgets, aliases, complete symbol/type resolution, runtime getters, collection control flow, async builders or API data loading.

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
