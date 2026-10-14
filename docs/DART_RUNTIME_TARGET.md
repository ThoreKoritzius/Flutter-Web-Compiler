# Experimental Flutter-source DOM runtime target

This target uses the official Dart compiler for executable code and a small
Flutter-shaped DOM API for supported presentation classes. It avoids translating
async methods, exceptions, JSON factories or collection semantics ourselves.
It is an experiment, not a production-ready alternate Flutter framework.

## Run

```sh
dart run bin/flutter_dom.dart build web --project examples/logic \
  --dart-runtime --output build/native-app
dart run tool/logic_demo.dart --native-app
```

The second command rebuilds and serves the app at http://127.0.0.1:8122/ with
a synthetic live local API. `--no-serve` builds without starting the server.
The installed CLI also accepts `flutter_dom build web --dart-runtime` from an
app directory. The target defaults to `lib/main.dart`; `--source` selects another
entry. Existing static/hybrid builds remain the default.

## What executes

The original `examples/logic/lib/main.dart` imports Flutter material and defines
a normal `StatefulWidget`. Its `initState`, async request method, generation
guard, `mounted` check, loading/error/data assignments, `setState`, build method,
collection children and callbacks run as compiled Dart. The original repository,
transport and JSON factories run too. The browser view is built by those widget
bodies rather than the hand-authored DOM adapter in the earlier experiment.

The builder copies the reachable relative source graph to a temporary directory.
It rewrites the URIs of supported Flutter material/widgets/foundation/services imports and exports
to explicit compatibility libraries, selects supported web conditional branches
and rewrites relative library URIs to copied files. It does not edit input sources
or replace method bodies. It invokes `dart compile js -O2 -Ddart.vm.product=true
--no-source-maps`; temporary sources are removed afterward.
Reports distinguish this backend from static compilation and do not invent a
whole-app conversion percentage.

The HTML shell is supplied by the tool. It is not inferred from the application.
The target currently needs its own loading bootstrap; app content is not static
HTML and therefore has no pre-rendered SEO advantage. Runtime bundle sizes must
be measured separately from existing static benchmarks.

## Supported contract

### Explicit library adapters

For a component that requires Flutter's engine, an application can deliberately
select a different native implementation. This replaces the entire selected
library; it is **not translation of its original internals**. It must provide
the public API required by its consumers, which the official compiler checks.
Never use this to silently report unsupported behavior as converted.

```sh
flutter_dom build web --dart-runtime --runtime-bridges runtime-bridges.json
```

Example `runtime-bridges.json`:

```json
{"lib/widgets/animated_mark.dart":"native/animated_mark.dart"}
```

Keys are normalized project-relative paths to existing source libraries. Values
are replacement Dart files relative to the JSON file, or absolute paths. The
JSON file itself is relative to the CLI working directory. Implementations may
live outside the application; any relative dependencies they import must still
be project-local. Use supported Flutter material/foundation APIs or pure Dart.
Input sources stay untouched. Built-in API bridges remain separate from these
application-selected library replacements.

Invalid, missing, duplicate source identities and unreachable mappings fail;
there is a 50-adapter limit. `--runtime-bridges` requires `--dart-runtime` and
works independently of static preview configuration. Reports list replaced
project-relative libraries under `nativeLibraryAdapters`, and CLI output shows
the count. These adapters are not included in any automatic conversion claim.
Private implementations and mapping files should remain outside tracked source.

The adapter tests execute an explicit replacement through dart2js, verify report
attribution and confirm original files remain unchanged. A library adapter does
not supply missing provider wiring, platform plugins or authentication behavior.

### Widget runtime

Widgets inflate into a retained **element tree** that follows Flutter's
documented framework contract rather than a static template:

- Elements reconcile by runtime type and key (`ValueKey`, `ObjectKey`,
  `UniqueKey`, `GlobalKey`), using Flutter's top/bottom/keyed-middle list
  algorithm. Keyed children keep their state and DOM node when reordered.
- `setState`, inherited dependencies and listenables mark single elements
  dirty. Dirty elements rebuild in depth order in one microtask; ancestors
  that did not change are not rebuilt, and identical widget instances are
  skipped.
- Each DOM-producing element owns one DOM node and patches only changed
  attributes, text and child order. Focus, caret position, text selection and
  scroll position therefore survive rebuilds.
- `State` lifecycle: `initState`, `didChangeDependencies`, `didUpdateWidget`,
  `deactivate`/`dispose` (descendants first), `mounted` and `context`.
  Event handlers of removed elements are inert; a failed build disposes the
  whole mount, including partially built subtrees.
- `InheritedWidget`, `InheritedNotifier`, `dependOnInheritedWidgetOfExactType`,
  `findAncestorStateOfType` and `GlobalKey.currentState/currentContext`.
  Reparenting a `GlobalKey` subtree recreates it rather than moving state.
- `Builder`, `StatefulBuilder`, `ListenableBuilder`, `AnimatedBuilder`,
  `ValueListenableBuilder`, `FutureBuilder` and `StreamBuilder`.

Text is written with `textContent` and is never parsed as HTML. Native
`<button>`, `<input>`, `<select>`, `<label>`, `<form>` and `<nav>` elements carry
their browser semantics; clickable regions (`InkWell`, `ListTile`) get
`role="button"`, `tabindex="0"` and Enter/Space activation only when a callback
is present. Reports describe this model as `keyed-element-tree-retained-dom`.

### Supported widget catalogue

The bridge implements a bounded subset with Flutter's public constructors.
Undeclared classes or parameters fail official compilation; unsupported
behaviour inside a supported widget throws `UnsupportedError` at runtime.

- **Text:** `Text`, `Text.rich`/`TextSpan`/`WidgetSpan`, `RichText`,
  `DefaultTextStyle` (`merge`), `maxLines`, `overflow`, `softWrap`,
  `textAlign`, `TextStyle` (color, size, weight, style, spacing, height,
  decoration, families, `FontFeature`s).
- **Layout:** `Row`, `Column`, `Flex` (main/cross alignment, `mainAxisSize`,
  `spacing`), `Expanded`, `Flexible`, `Spacer`, `SizedBox` variants,
  `Padding`, `Align`, `Center`, `Container`, `DecoratedBox`, `ColoredBox`,
  `ConstrainedBox`, `AspectRatio`, `FractionallySizedBox`, `Wrap`, `Stack`,
  `Positioned`, `Opacity`, `Visibility`, `Offstage`, `ClipRRect`, `ClipOval`,
  `LayoutBuilder`, `MediaQuery`, `SafeArea`, `SingleChildScrollView`,
  `ListView` (+`builder`/`separated`), `GridView` (`count`, `extent`,
  `builder` with fixed-count or max-extent delegates).
- **Painting:** `BoxDecoration` (color, gradient, image, border, radius,
  shadows, circle), `ShapeDecoration`, rounded/stadium/circle borders,
  `LinearGradient`, `RadialGradient`, `BoxShadow`, `Alignment(Directional)`,
  `EdgeInsets(Directional)`, `BorderRadius(Directional)`.
- **Material:** `MaterialApp` (theme, dark theme/mode, routes, `builder`,
  title; `home` always runs inside a `Navigator`), `Theme`, `ThemeData` (`colorScheme`, `colorSchemeSeed`,
  `textTheme`, `fontFamily`, extensions), full Material 3 `ColorScheme`
  roles including `ColorScheme.fromSeed` (computed with the same
  `material_color_utilities` 0.13.0 schemes Flutter 3.41 uses), the Material 3
  type scale, `Colors`, `Scaffold` (app bar, body, FAB, bottom bar, drawers,
  `Scaffold.of`), `AppBar` (implied back/menu buttons, actions, `bottom`),
  `Material`, `Card` (+`filled`/`outlined`), `ElevatedButton`, `FilledButton`
  (+`tonal`), `OutlinedButton`, `TextButton`, `IconButton`,
  `FloatingActionButton`, `.icon` constructors and `styleFrom`/`ButtonStyle`
  with `WidgetStateProperty`, `InkWell`, `ListTile`, `ExpansionTile`,
  `Divider`, `CircleAvatar`, `Chip`, `Badge`, `Tooltip`, linear/circular
  progress indicators, `NavigationBar`, `BottomNavigationBar`, `TabBar`,
  `TabBarView`, `DefaultTabController`, `Drawer`, `SnackBar` via
  `ScaffoldMessenger`, `AlertDialog`, `SimpleDialog`, `Dialog`.
- **Input:** `TextField`, `TextFormField`, `Form`/`FormField`/`FormState`
  (validate, save, reset, autovalidate modes), `InputDecoration` (label,
  hint, helper, error, prefix/suffix, outline/underline/none borders,
  counters), `TextEditingController`, `FocusNode`, `FocusScope`,
  `TextInputType`, `TextInputAction`, `TextInputFormatter`
  (`FilteringTextInputFormatter`, `LengthLimitingTextInputFormatter`),
  `Checkbox` (tristate), `Switch`, `Radio`, `Slider`, `DropdownButton`,
  `DropdownButtonFormField` and `DropdownMenu` (native `<select>`; item
  children must be `Text`).
- **Navigation:** `Navigator` (`push`, `pushNamed` with arguments, replacement,
  remove-until, `pop` with typed results, `maybePop`, `popUntil`),
  `MaterialPageRoute`, `PageRouteBuilder` (no transition animation),
  `ModalRoute.of`, `PopScope`, `NavigatorObserver`, `showDialog` and
  `showModalBottomSheet`. Covered routes stay mounted but hidden and inert.
  The root navigator mirrors routes into browser history using Flutter web's
  default hash URLs (`#/details`); browser back pops routes, `PopScope`
  vetoes are honoured, and the initial hash restores the route stack.
- **Images:** `Image`, `Image.asset`, `Image.network` (http(s) or relative
  URLs only), `AssetImage`, `NetworkImage`, `DecorationImage`, `BoxFit`,
  `errorBuilder`.
- **Gestures:** `GestureDetector` taps with `TapDownDetails`/`TapUpDetails`
  (global and local positions, pointer kind) and `onTapCancel`, long presses
  (`onLongPress`, start/end details; also on `InkWell`, `ListTile` and
  buttons), and pan, horizontal and vertical drags with start/update/end
  details, `primaryDelta` and release velocity, all from DOM pointer events
  with pointer capture and Flutter's touch slop. Clicks still deliver
  `onTap`, so keyboard activation is unchanged; a long press or drag
  swallows the following click. Drag detectors set `touch-action` so the
  browser scrolls along the free axis only.
- **Menus, pickers and selection:** `PopupMenuButton`, `PopupMenuItem`,
  `CheckedPopupMenuItem`, `PopupMenuDivider` and `showMenu` (anchored to the
  button, arrow-key focus), `showDatePicker`, `showDateRangePicker` and
  `showTimePicker` as dialogs on native date/time inputs, `TimeOfDay`,
  `DateTimeRange`, `DateUtils`, `FilterChip`, `ChoiceChip`, `ActionChip`,
  `InputChip` and `SegmentedButton`.
- **Tables and text gestures:** `Table` (CSS grid with fixed, flex,
  fraction, intrinsic, min and max column widths, `TableBorder`, row
  decorations, `TableCell` vertical alignment) and `TextSpan.recognizer`
  with `TapGestureRecognizer` (keyboard-accessible link semantics).
- **Icons:** `Icon`, `IconTheme`, `Icons` (all 8,825 Material constants
  generated from Flutter 3.41.6) and `Icons.adaptive`.
- **Animation:** `AnimationController` (forward, reverse, `animateTo`,
  `repeat`, `toggle`, status listeners, `TickerFuture.orCancel`) driven by
  `requestAnimationFrame` through `SingleTickerProviderStateMixin` and
  `TickerProviderStateMixin`; `Curves` (Flutter's cubic definitions and
  bisection), `Interval`, `Tween`/`ColorTween`/`IntTween`/`SizeTween`/
  `RectTween`/`AlignmentTween`/`EdgeInsetsTween`/`DecorationTween`/
  `TextStyleTween`, `TweenSequence`, `CurvedAnimation`, `chain`/`drive`;
  `FadeTransition`, `ScaleTransition`, `RotationTransition`,
  `SlideTransition`, `SizeTransition`, `AnimatedWidget`; implicit
  `AnimatedContainer`, `AnimatedOpacity`, `AnimatedPadding`, `AnimatedAlign`,
  `AnimatedScale`, `AnimatedRotation`, `AnimatedSlide`, `AnimatedPositioned`,
  `AnimatedDefaultTextStyle`, `TweenAnimationBuilder`, `AnimatedSwitcher`
  (outgoing children stay until faded) and `AnimatedCrossFade`, all
  retargeting mid-flight; `Transform` (`rotate`, `scale`, `translate`,
  `flip`, `Matrix4` from `vector_math`) as CSS 3D transforms;
  `WidgetsBinding.instance.addPostFrameCallback`,
  `WidgetsFlutterBinding.ensureInitialized` and `Color.lerp`/`lerp` statics
  on painting types. `AnimatedSize` changes size immediately.
- **Painting:** `CustomPaint` and `CustomPainter` (`shouldRepaint`,
  `repaint` listenables, foreground painters) on an HTML `<canvas>` sized from
  the laid-out box at the device pixel ratio; `Canvas` (save/restore,
  transforms, rect/rrect/path clips, lines, rects, rounded rects, ovals,
  circles, arcs, paths, points, shadows), `Paint` (fill/stroke, width, caps,
  joins, gradient shaders, blur mask filters), `Path` (lines, quadratic and
  cubic curves, arcs including SVG-style `arcToPoint`, rect/oval/rrect/polygon
  shapes, shifting, even-odd fill), `Rect`, `RRect`, `Offset`/`Size`
  arithmetic, `ui.Gradient` and `Gradient.createShader`, and `TextPainter`
  (styled spans, wrapping, `maxLines` with ellipsis, alignment). `dart:ui`
  imports map to this subset; `package:flutter/painting.dart` maps to the
  widgets facade. Canvases repaint only on size changes, `shouldRepaint` or
  their repaint listenable. Not supported: blend modes other than `srcOver`,
  path metrics, images, paragraphs, and saveLayer compositing (it applies
  alpha to subsequent drawing).

Not yet implemented: `Hero`, page transition animations, slivers and
`CustomScrollView`, lazy/infinite lists (`itemCount` is required; at most
10,000 eagerly built items), scale/pinch gestures, `Draggable`/`DragTarget`,
`Overlay`/`OverlayEntry`, calendar-grid date pickers (pickers use the
browser's native inputs), `DataTable`, `Stepper`, Cupertino widgets, and
`dart:ui` window, image and paragraph APIs. CSS approximates Flutter layout;
widths that Flutter boxes expand to are propagated through wrappers so
expanding rows and tiles fill their column, but heights remain document flow.

The foundation bridge provides `kIsWeb`, release/profile/debug constants and
`compute`. Like Flutter's web implementation, `compute` yields then executes on
the current event loop; it creates no worker and emits no Flutter profiling
events. `debugPrint` is a replaceable callback using synchronous console output;
Flutter's throttling is not implemented and non-null `wrapWidth` is rejected.
`Listenable` (`merge`), `ChangeNotifier`, `ValueNotifier`, `ValueListenable`,
callback typedefs (`VoidCallback`, `ValueChanged`, …) and `listEquals`/
`setEquals`/`mapEquals` follow Flutter's semantics. Diagnostic classes and
other foundation APIs are not implemented and fail official compilation.
The compute contract follows the documented
[Flutter web behavior](https://api.flutter.dev/flutter/foundation/compute.html).

Conditional imports/exports support a fixed dart2js web environment:
`dart.library.js_interop`, `dart.library.html`, `dart.library.js` are true;
`dart.library.io`, `dart.library.ffi` are false. The first matching condition wins,
with the default used if none match. Prefixes and show/hide clauses are retained.
Unknown conditional environments fail explicitly. Other Flutter/engine imports
fail with project-relative source locations.

The services bridge provides a bounded `MethodChannel(name)`, `MethodCall`,
`PlatformException`, `MissingPluginException`, `invokeMethod`, `invokeListMethod`
and `invokeMapMethod`, plus Dart typed-data exports. **No platform plugin is
implemented or registered by default.** Unregistered calls complete with
MissingPluginException, preserving an explicit failure path consistent with
[Flutter's missing-handler contract](https://api.flutter.dev/flutter/services/MethodChannel/invokeMethod.html).

A native implementation can register an in-process Dart handler:

```dart
import 'package:flutter_dom_compiler/runtime.dart';

final unregister = registerDomMethodChannel('example/browser', (call) async {
  if (call.method == 'supportedOperation') return 42;
  throw UnsupportedError('Unsupported operation');
});
// Call unregister() when the owning service is disposed.
```

Original channel calls then invoke that explicit handler. Method names and
arguments are preserved; result type casts and synchronous/asynchronous errors
propagate. Duplicate channel registrations fail. Unregistration is idempotent
and cannot remove a later registration, even if it reuses the same callback.
It does not cancel calls already in flight. These are direct Dart calls, without
Flutter binary codecs, native messaging, plugin discovery, inbound events or
background isolate support. Browser/plugin implementations are application
adapters and require their own behavior tests. Other services APIs are not
provided and fail compilation. A missing-plugin failure is not plugin support.
Undeclared widget classes/properties fail official compilation. Structural cases
such as nested consumer widgets fail at runtime; they are not yet preflighted.
The local graph limit is 500 libraries; dependencies outside the project through
relative imports are rejected. Package dependencies use the project's existing
package configuration when present. Flutter-dependent transitive packages can
still prevent official compilation.

Static preview configuration and `--data` snapshots are rejected with this
target. A service's runtime data must arrive through executable Dart. The fixture
uses an explicit browser transport and loopback-only synthetic API, without
production authentication or any inferred request behavior.

## Evidence and remaining work

Node DOM contract tests (`tool/browser/*.cjs` over a shared shim that enforces
real DOM tree rules) run compiled output for: request flows with stale-response
suppression and retry; keyed reordering, `GlobalKey` access and targeted
disposal; inherited/listenable rebuilds that skip unchanged ancestors;
retained DOM nodes across rebuilds; text input, formatters, controllers,
validation, `aria-invalid`/`aria-describedby` and controlled selection
controls; navigation with typed results, browser history, dialogs, Escape,
`PopScope` and snack bars; nested provider scopes; tabs with arrow keys,
navigation bars, drawers and expansion tiles; and the generic
[records panel fixture](../examples/records_panel/README.md) (state retention
across parent rebuilds and resizes, input updates, disposal, stale callbacks,
Enter/Space activation, breakpoints, icons). Separate tests check source
immutability, unsupported imports and CLI failure before output creation.

These tests are not a cross-browser certification: real-browser layout,
painting and focus behaviour still need Chromium/Firefox/WebKit checks, and
parity checks against the same source running under Flutter. Evaluate Jaspr as
an alternative component backend against these fixtures before broad adoption.
The [logic architecture](LOGIC_RUNTIME.md) describes production release gates.

## Assets, fonts and icons

`writeNativeApp` (used by the CLI) emits `index.html`, `app.js`, `app.css`
and copied assets. Runtime interaction styles live in the linked `app.css`,
so the host page has no inline `<style>`; element style attributes still need
`style-src-attr 'unsafe-inline'` (see [hosting](NATIVE_HOSTING.md)).

- `flutter: assets:` entries (files and directories, as in Flutter) are copied
  to `assets/<key>`, the URL layout Flutter web uses for `Image.asset`.
- `flutter: fonts:` families are copied and declared with `@font-face`
  (weight and style are preserved).
- Material icons render as glyphs of Flutter's own `MaterialIcons-Regular.otf`
  using the code points from Flutter's `icons.dart`; there are no emoji or
  substitute glyphs. The font is taken from `--material-icons-font`,
  `FLUTTER_ROOT` or the Flutter SDK on `PATH`
  (`bin/cache/artifacts/material_fonts`). When compiled code still references
  icon metadata and no font is found, the CLI fails before writing output.
- Icons are tree-shaken by default, like Flutter's release builds: the
  builder keeps `.notdef` plus the glyphs the app can render and rewrites the
  CFF font in pure Dart (`lib/src/font_subset.dart`), dropping the ligature
  tables. Glyph usage comes from `Icons.*` references and literal `IconData`
  code points in project sources, which identify the icon constructor in the
  tree-shaken dart2js output; every literal code point it builds is kept, so
  icons used inside packages are included. If code points are computed at
  runtime, or the constructor cannot be identified, the full font (about
  1.6 MB) is shipped and the report says `full-font`. `--no-tree-shake-icons`
  always ships the full font. Subset output is validated against the
  OpenType Sanitizer that browsers apply to web fonts.

Regenerate icon and color metadata with
`dart run tool/generate_material_metadata.dart <flutter-checkout>`.

## Executable GraphQL boundary

`package:flutter_dom_compiler/browser_runtime.dart` exposes an explicit browser
transport, separate from Flutter service replacements:

```dart
final client = GraphqlClient(BrowserGraphqlTransport('/api/graphql'));
final data = await client.query(document, variables: {'limit': 10});
// Feed data into the original Dart model factories.
```

`GraphqlClient` accepts an injectable `GraphqlTransport`, encodes documents and
variables as JSON, checks HTTP status, rejects GraphQL errors (including partial
data), and returns the `data` map. Failure messages exclude server payloads.
The browser transport accepts only root-relative endpoints, uses same-origin
credentials, rejects redirects, and aborts fetch on timeout across headers and
body consumption. It does not implement tokens, CSRF headers, session refresh,
automatic retry, subscriptions, uploads, persisted queries or a response-size
limit. A `query` call does not inspect GraphQL syntax to prohibit mutations;
read-only policies belong to the application adapter/server.

Existing service classes must still be explicitly adapted to this interface;
importing this library does not automatically port a networking package. These
are experimental primitives, not evidence of production authentication parity.

## Visual metadata dependencies

The runtime accepts `@immutable`, legacy integer ARGB `Color` values with
`withValues(alpha:)`, `IconData`, `ThemeExtension` declarations and
`ThemeData.extension<T>()` (null when not registered). `Color.lerp` and
`ThemeExtension.lerp` interpolation still throw `UnsupportedError`; floating
point color spaces are outside this subset. Annotation exports resolve to the
compiler's official `meta` package even without an input package config.

## Riverpod

`package:flutter_riverpod/flutter_riverpod.dart` maps to widget bindings backed
by the **official pure-Dart Riverpod 2.6.1 engine**; providers always execute
in Riverpod's own `ProviderContainer`.
See [Riverpod's container architecture](https://riverpod.dev/docs/concepts2/containers).

- `ProviderScope` (`overrides`, `observers`, `parent`) anywhere in the tree;
  nested scopes create child containers, so overrides apply to their subtree.
  `UncontrolledProviderScope` and `ProviderScope.containerOf`.
- `ConsumerWidget`, `Consumer`, `ConsumerStatefulWidget`/`ConsumerState` at
  any depth.
- `WidgetRef.watch` and `listen` during build (subscriptions not renewed in a
  build are closed), `read`, `listenManual`, `invalidate`, `refresh`, `exists`.
  Disposal closes all subscriptions before the owning container is disposed.

`ChangeNotifierProvider` (it needs Flutter's `ChangeNotifier` inside Riverpod),
hooks and Riverpod 3.x are not supported. Missing or incompatible engine
versions fail before compilation; projects with a package configuration must
provide `riverpod` 2.6.1. Reports state
`providerIntegration: riverpod-2.6.1-element-scopes` when the import is mapped.
None of this adapts an application's authentication or networking.

## Built-in package bridges

Some widely used packages depend on Flutter's engine and cannot compile on
this runtime. For these, the builder maps the package's public library to an
**independent implementation of its public API**, written for the DOM
runtime; package code is never executed. Reports list them under
`builtInPackageBridges`, separately from translated application code. An
explicit `--package-bridges` mapping takes precedence.

### fl_chart

`package:fl_chart/fl_chart.dart` maps to an implementation of the fl_chart
1.x API for **line, bar and pie charts**: `LineChart`, `BarChart`,
`PieChart` and their data classes (`FlSpot`, `LineChartBarData`,
`BarChartGroupData`, `BarChartRodData`, `PieChartSectionData`, titles, grid,
border, extra lines, range annotations, dot painters, touch and tooltip
data) with fl_chart's defaults, interval selection and number formatting.

- Plots paint on canvas through `CustomPaint`; axis titles
  (`getTitlesWidget`, `SideTitleWidget`), axis names, tooltips and pie
  titles/badges are DOM widgets positioned over the chart, so text is real,
  selectable and themed.
- Curved, stepped and dashed lines, gradient areas, between-bar fills,
  rounded and stacked rods, background rods, sections with spacing and
  centre space.
- Pointer hover and taps drive built-in tooltips and `touchCallback` with
  `FlPointerHoverEvent`, `FlTapDownEvent`, `FlTapUpEvent` and
  `FlPointerExitEvent`, plus `LineTouchResponse`, `BarTouchResponse` and
  `PieTouchResponse` hit results. Events carry `localPosition` rather than
  Flutter gesture details.
- Data changes animate with `duration`/`curve` when the structure matches.

Not provided: scatter, radar and candlestick charts, error indicators,
rotation, zoom/pan transformations, long-press timing and `SizedPicture`
or image line decorations. Charts need bounded height from their parent, as
in Flutter. Visuals approximate fl_chart's rendering; they are not pixel
identical.

### go_router

`package:go_router/go_router.dart` maps to an implementation of the
go_router public API (v14+): `GoRouter` (`initialLocation`, `redirect`,
`redirectLimit`, `refreshListenable`, `errorBuilder`/`errorPageBuilder`,
`onException`, `navigatorKey`, `observers`, `routerNeglect`), `GoRoute`
(paths with `:parameters`, nested sub-routes, `name`, `builder`,
`pageBuilder`, per-route `redirect`, `onExit`, `parentNavigatorKey`),
`ShellRoute`, `StatefulShellRoute.indexedStack` with `StatefulShellBranch`
and `StatefulNavigationShell` (`currentIndex`, `goBranch`), `GoRouterState`
(`uri`, `matchedLocation`, `pathParameters`, `extra`, `pageKey`, `of`),
`NoTransitionPage`, `CustomTransitionPage`, `MaterialApp.router` and the
`BuildContext` helpers (`go`, `goNamed`, `push`/`pushNamed` with typed
results, `pop`, `canPop`, `pushReplacement`, `replace`, `namedLocation`).

- Routing renders through declarative `Navigator(pages:)`, so dialogs,
  sheets and `Navigator.of` work on top of router pages; covered pages keep
  their state, and stateful shell branches stay mounted in an `IndexedStack`.
- Locations use Flutter web's default hash URLs: `go` adds a history entry,
  redirects (including `refreshListenable` refreshes) replace it, browser
  back navigates to the previous location, and the initial hash is honoured
  as a deep link. Imperative pushes write the URL only with
  `GoRouter.optionURLReflectsImperativeAPIs`.
- Redirects may be asynchronous; loops and the redirect limit produce a
  `GoException` shown by the error builder.

Not provided: page transition animations (transition builders receive
completed animations), `GoRouter.routingConfig`, `onEnter`, type-safe
`GoRouteData` code generation, path URL strategy, `extraCodec`
serialization and state restoration.

### flutter_markdown and flutter_markdown_plus

Both `package:flutter_markdown/flutter_markdown.dart` and
`package:flutter_markdown_plus/flutter_markdown_plus.dart` map to an
implementation of their widget API (`MarkdownBody`, `Markdown`,
`MarkdownStyleSheet` with `fromTheme`, `largeFromTheme`, `copyWith` and
`merge`, `onTapLink`, `onTapText`, `imageBuilder`, `checkboxBuilder`,
`bulletBuilder`, `syntaxHighlighter`, `softLineBreak`). Parsing uses the
official `markdown` package (GitHub-flavoured by default, custom
`extensionSet`/syntaxes honoured), so the project's package configuration
must provide it, as Flutter projects using these packages do.

Headings carry heading semantics; links render as keyboard-accessible
`role="link"` spans reporting text, href and title; lists (nested,
ordered with start numbers), task checkboxes, block quotes, horizontally
scrolling code blocks, tables (with column alignment) and images are
supported. Custom element and padding builders (`builders`,
`paddingBuilders`) fail explicitly; selection callbacks are ignored because
document text is natively selectable.

### flutter_localizations

`MaterialApp` supports `locale`, `supportedLocales`,
`localizationsDelegates`, `localeResolutionCallback` and
`localeListResolutionCallback`; without an explicit locale it resolves the
browser's `navigator.languages` with Flutter's basic resolution algorithm
and mirrors the result into `<html lang>`. `Localizations` (with
`override`, `of`, `localeOf`), `LocalizationsDelegate`, `Locale`,
`SynchronousFuture`, `FlutterError`, `WidgetsLocalizations` and
`MaterialLocalizations` follow Flutter's contracts, so code generated by
`gen_l10n` (with `package:intl`) compiles unchanged.

`package:flutter_localizations/flutter_localizations.dart` maps to
`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations` and
`GlobalCupertinoLocalizations` delegates. They report every locale as
supported and load **English** Material/Cupertino strings; locale-specific
framework strings are not bundled, and right-to-left locales are reported but
laid out left-to-right. Application strings come from the app's own code.

### shared_preferences and url_launcher

`package:shared_preferences` maps to `window.localStorage` using the official
web plugin's layout (JSON values; `flutter.` prefix for `SharedPreferences`,
no prefix for `SharedPreferencesAsync`/`SharedPreferencesWithCache`), so a
native build reads values written by a Flutter web build on the same
origin. `setPrefix`, allow lists, `setMockInitialValues` and `reload` are
supported; storage failures return `false`.

`package:url_launcher` (and `url_launcher_string`) opens `http(s)` links with
`window.open(..., '_blank', 'noopener,noreferrer')`, protocol links
(`mailto:`, `tel:`, `sms:`) in place, honours `webOnlyWindowName`, and refuses
other schemes such as `javascript:`. In-app web views are not available.
`package:url_launcher/link.dart` provides `Link` and `LinkTarget`; the
builder's `followLink` opens the URI the same way.

### Third-party packages that use Flutter

Package libraries that (transitively) import `package:flutter/*` or
`dart:ui` are compiled against the runtime too: the build resolves them
through the project's package configuration, copies only those libraries and
rewrites their Flutter, bridged-plugin and relative imports, so widget
packages work without adapters. Libraries that never reach Flutter keep their
`package:` URIs (one type identity whether imported directly or through a
rewritten library). The package sources are not modified; the build report
lists them as `rewrittenPackages`. Their Flutter API use is held to the same
contract as app code: anything the runtime lacks is a compile error.

## Explicit package boundaries and compile-time configuration

`--package-bridges adapters.json` maps exact package library URIs to explicit
Dart adapters. Paths resolve relative to the JSON file. For example, a package
that combines Flutter widgets with a pure-Dart client can explicitly expose the
client through an adapter; unused widget APIs then remain compiler errors.

```json
{ "package:legacy_sdk/legacy_sdk.dart": "adapters/client.dart" }
```

The build reports reached replacements in `nativePackageAdapters`. Missing,
invalid and unused mappings fail. Built-in Flutter framework and root consumer
bridges cannot be replaced through this option. This rewrites selected imports
in the copied graph: app sources and package libraries that reach Flutter.
Adapter source/dependencies are checked by the official compiler. No plugin
implementation is inferred: unavailable operations should explicitly fail.

Repeat `--dart-define KEY=VALUE` to supply original `String.fromEnvironment`/
`bool.fromEnvironment` configuration to dart2js. Values retain commas and equals
signs; duplicate, invalid and reserved `dart.*` keys fail. Reports contain keys,
not values, but compile-time values can be embedded in the public JavaScript.
Both options require `--dart-runtime`.

Compiling an original request service does not establish authenticated access.
Cookie scope, same-site policy, CORS and the page origin still apply. A local
static preview does not inherit a production page's session merely because
it runs the same Dart code. Live verification must use an authenticated browser
and a permitted origin; compilation or loopback replay is insufficient evidence.

Native output uses dart2js CSP mode. See [authenticated hosting](NATIVE_HOSTING.md)
for same-origin preview paths and cookie/CORS boundaries.

### Explicit component selection

For a component inside a large library, `--runtime-selections selections.json`
can select declarations without copying their implementation into an adapter:

```json
{
  "lib/components.dart": {
    "declarations": ["SummaryCard", "SummaryGrid"],
    "imports": ["package:flutter/material.dart", "spacing.dart"]
  }
}
```

Selection retains named declarations and their same-library identifier dependencies
verbatim. The import list is explicit: omitted imports and all exports are removed.
The official Dart compiler checks the resulting graph and rejects missing symbols.
This is a manual component experiment, **not whole-library or whole-app compatibility**.
The report records `nativeSourceSelections` separately from replacement adapters.
Selections cannot overlap adapters or point outside the project; unreachable entries
fail. Parts, extensions, unnamed declarations and conditional imports are rejected
because their dependencies need resolved library analysis.

`LayoutBuilder` measures its attached DOM container's `clientWidth` after the
build pass and rebuilds only when the measured width changes or its builder's
dependencies change; nested builders are measured in depth order. `MediaQuery`
is an inherited viewport snapshot (size, platform brightness): resize and
color-scheme changes rebuild only dependents. A resize listener exists only
while layout builders or media dependents are mounted. Only horizontal
constraints are measured; vertical constraints remain unbounded document
flow. The host page supplies no frame; application source supplies its layout.
