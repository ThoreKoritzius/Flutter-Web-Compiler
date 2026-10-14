# Changelog

## Unreleased

- Add `Localizations`, locale resolution from the browser, `<html lang>`, `SynchronousFuture`/`FlutterError`, and a `flutter_localizations` bridge so gen_l10n code compiles unchanged.
- Map `shared_preferences` to localStorage (compatible with Flutter web's layout) and `url_launcher` to `window.open`.

- Map `flutter_markdown` and `flutter_markdown_plus` imports to a markdown renderer built on the official `markdown` parser; add `Table`, tappable `TextSpan` recognizers and `package:flutter/gestures.dart` mapping.

- Map `package:go_router` imports to a built-in router with redirects, named and nested routes, stateful shell branches, typed push results, hash URLs and browser back; add declarative `Navigator(pages:)`, `MaterialApp.router` and `IndexedStack`.

- Map `package:fl_chart` imports to a built-in implementation of its line, bar and pie chart API on the native canvas, with DOM titles, tooltips, touch callbacks and animated data changes.
- Keep keyed children of `Stack` and `GridView` across rebuilds.

- Add animation controllers on `requestAnimationFrame`, curves, tweens, explicit transitions, implicit animations, `AnimatedSwitcher`, `Transform` with `Matrix4`, post-frame callbacks, and color/painting interpolation.

- Add `CustomPaint`, `Canvas`, `Paint`, `Path`, `TextPainter` and a `dart:ui` facade backed by HTML canvas, repainting only on resize, `shouldRepaint` or repaint listenables.

- Tree-shake Material icons in native builds with a pure-Dart CFF subsetter (1.6 MB font to a few KB for typical screens); fall back to the full font when usage cannot be determined statically.
- Rebind Riverpod consumers when an ancestor scope supplies a different container.

- Replace the native runtime's full-view rendering with a keyed element tree that patches retained DOM nodes: Flutter's list reconciliation, `GlobalKey`, `InheritedWidget`/`InheritedNotifier`, per-element dirty rebuilds, `didChangeDependencies`, and preserved focus, caret and selection.
- Add Flutter-shaped layout, painting and Material widgets (Container, Align, Stack, scroll views, grids, buttons with `ButtonStyle`, InkWell/ListTile with keyboard activation, ExpansionTile, chips, badges, progress indicators, app bars, drawers, tabs and navigation bars), full Material 3 color roles, `ColorScheme.fromSeed` via `material_color_utilities` 0.13.0, and the Material 3 type scale.
- Add native text fields, forms, input formatters and controlled selection controls; Navigator routes with browser history and hash URLs, dialogs, bottom sheets, `PopScope` and snack bars; foundation listenables and async builders.
- Render Material icons with Flutter's icon font and generated code points (no substitutes), copy pubspec assets and fonts, link runtime CSS instead of inlining it, and fail builds that use icons without a resolvable font.
- Support nested Riverpod scopes, `ConsumerWidget`, `Consumer` and build-scoped `ref.listen`.
- Add a generic synthetic records panel fixture and DOM contract tests on a shared shim that enforces real tree operations.

- Add scoped native runtime themes, typed text styles, padding, flexible rows and rounded cards; verify compiled state updates and reject unsupported icon painting explicitly.

- Compile the native runtime in dart2js CSP mode and document same-origin hosting for authenticated request slices.

- Add explicit package URI adapters and native `--dart-define` configuration with attribution and strict validation; expose foundation typed-data exports and official testing annotations.

- Use the official Riverpod 2.6.1 engine for bounded root ProviderScope/ConsumerState read/watch integration; preserve subscriptions across builds, dispose owned containers, reject incompatible versions and report integration explicitly.

- Compile bounded color/icon metadata and ThemeExtension declarations in native source graphs; resolve official immutable annotations without requiring an input package configuration, and reject unsupported visual operations explicitly.

- Add an explicit GraphQL JSON client and browser POST transport with same-origin endpoints, strict response handling and aborting timeouts; verify compiled output against real HTTP.

- Add bounded services imports with explicit in-process method-channel registration, missing-plugin failures, typed results and safe unregistration; expose supported core widgets through a restricted widgets import.

- Add explicit `--runtime-bridges` library replacements for engine-dependent components; validate reachable mappings, preserve source files and report adapters separately from original libraries.

- Add a bounded foundation bridge for web/release flags, compute and explicit console logging; select fixed web conditional import/export branches and report unsupported dependency source locations.

- Add an experimental `--dart-runtime` build target that copies local sources, substitutes a bounded Flutter material API and compiles original lifecycle/request/build methods with dart2js; verify live requests, stale-response guards and retry.

- Add an official dart2js request-flow experiment and a pure-Dart async resource primitive with stale-response suppression, explicit states and disposal; keep the browser view/transport adapters explicit.

- Bind local JSON snapshots through `--data`, explicit JSON Pointer references and model projections; validate inputs before writing output and label supplied data separately from mocks.

- Lower explicitly configured callback route bridges into native links through original synchronous arrow callbacks; report host navigation separately from widget adapters.
- Add bounded InkWell navigation links and a schematic chevron icon.

- Add strict calendar date snapshots, bounded DateTime calendar constructors and original year/month/day access with resolved dart:core identity.

- Lower explicitly selected original ThemeExtension constants, plain enum-keyed maps and bounded index operators with a static build-context token.
- Add read-only Material surfaces, finite BoxConstraints, TextStyle height, stretched column width and a schematic timer icon.

- Compile bounded synchronous static expression helpers and static expression getters, including imported class identity and class constants.
- Accept unsupported nullable model field types only when their snapshot value is null; non-null values remain rejected.

- Add bounded static final-variable collection patterns, nullable matching and boolean guards with isolated branch scope.
- Permit unused static serializer declarations on model snapshots; distinguish model key fields from Flutter keys.
- Add explicit opaque callback inputs that fail when invoked, a restricted Align mapping and one additional schematic icon.

- Compile bounded static build if/else/return blocks and null coalescing.
- Resolve project-local static const class fields, including prefixed imports.
- Add uniform decoration borders, explicit color/icon inputs and a small schematic SVG Icon subset.
- Add an independent summary fixture and CI build.

- Lower bounded pure instance expression helpers on widgets/models, with isolated parameters/defaults and resolved method identity.
- Support reactive scalar derivation through State helpers; report helper evaluations and exercise original row/format helpers in the records fixture.

- Evaluate original plain immutable model constructors, scoped expression getters and explicit model inputs; validate imported model identity in fields/lists.
- Upgrade the shared records fixture to imported typed model data without adapters.

- Bind static StatefulWidget constructor inputs through widget fields and pure local-state initializers.
- Compile bounded collection for-in/list operations and conditional static collections with retained native visibility groups.
- Add a shared Flutter/native records fixture, runtime visibility tests and CI compilation.

- Compile composed previews with bounded widget-valued inputs, scoped expression getters, primitive/null equality and checked null assertions.
- Add approximate Card/Expanded CSS rendering and a generic resolved composition fixture.

- Replace two-state enumeration with typed bool/int expression bindings, dependency-based updates, guarded integer arithmetic and native conditional button enablement.
- Add a shared session-counter demo and Dart/JavaScript runtime parity tests. The typed backend currently rejects conditional CSS formerly accepted by boolean enumeration.

- Replace boolean-state HTML templates with targeted text/attribute patches that preserve existing elements and keyboard focus. Reject structural state changes explicitly.

- Add a bounded native boolean StatefulWidget subset, HTML buttons and a shared event runtime.
- Add a shared Flutter period-selector fixture; report state instances and variant counts explicitly.

- Compile initialized static locals, numeric arithmetic and positional field constructors.
- Add explicit theme snapshots, supported text-style/color operations and basic decoration.
- Add configuration-driven previews of original components with primitive mock inputs.

- Separate missing constructor inputs from unsupported root behavior in resolved inspection.
- Evaluate actual resolved constructor call sites, with explicit context requirements and bounded, reported work.
- Replace the resolved CLI headline percentage with root and call-site outcome counts.

- Resolve standard conditional imports/exports against a fixed web target; report selected branches.
- Add resolved compatibility inspection with an explicitly scoped denominator.
- Pin analyzer 7.7.1 and isolate its environment-configuration API.

- Add opt-in `build --resolve-imports` with analyzer-backed local imports, exports, prefixes, parts and constants.
- Preserve declaration identity and file locations across project libraries; add a multi-file Flutter fixture and CI build.

- Evaluate same-file top-level constants with isolated scope, cycle detection and resource limits.
- Compile static collection `if`/`else`, list spreads and null-aware spreads.
- Reject unsupported collection patterns and runtime data explicitly.

- Add explicit `build` and `inspect` CLI commands, defaulting to the current project.
- Add local project syntax inventories with JSON/Markdown output and explicit confidence limits.
- Compile named final constructor fields and literal defaults in simple stateless widgets.
- Add an explicit native filter-list adapter and browser document scrolling.
- Add a shared-source landing-page showcase with native/Flutter target toggle.
- Add reproducible paired Flutter Web / DOM artifact-size benchmarks.
- Prepare OSS licensing, contribution guidance, CI and a community proposal roadmap.

## 0.1.0

- Initial static Flutter widget compiler, metadata and heading configuration.
- Single explicit, lazy-loaded Flutter island.
- Strict DOM-only mode, example app and compiler/CLI tests.

- Experimental runtime: explicit declaration/import selection preserves original
  component bodies, records selections separately from adapters, and rejects
  ambiguous library forms. Added attached-DOM horizontal `LayoutBuilder`, viewport
  `MediaQuery.sizeOf`, responsive `Wrap`, and resize-listener disposal. Removed
  compiler-authored demo framing from the native app host.

- Experimental runtime: plain unkeyed descendant state persists by structural
  position and ancestor type, receives widget updates, and disposes on removal.
  Failed builds clean up all mounted state. Nested consumer scopes, keys and
  retained DOM reconciliation remain unsupported.
