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

### Bounded built-in API

`package:flutter/widgets.dart` exposes the supported core widget types with the
same identity as the material bridge. It does not export MaterialApp, Scaffold or
ElevatedButton. This does not add IndexedStack or other undeclared Flutter APIs.

- `runApp`, `MaterialApp(home:)`, `Scaffold(body:)`, nested `StatelessWidget`s.
- One root `StatefulWidget`, optionally inside application wrappers.
- `State.widget`, `context`, `initState`, `mounted`, synchronous `setState`
  callbacks and `dispose` when replacing the root with another `runApp` call.
- `Text`, `Row`, `Column`, `SizedBox` and `ElevatedButton` with the arguments
  declared in `lib/src/runtime/flutter_dom.dart`. Buttons preserve native HTML
  semantics. Text uses `textContent` and never parses application text as HTML.
- Original pure-Dart helpers, repositories, model factories and asynchronous
  control flow through the official compiler.

Updates coalesce in a microtask and replace the root's DOM view. Detached event
handlers become inert after the next render or disposal. Root replacement
invalidates the mounted state before disposal. This is not retained-element
reconciliation: updates can lose focus and native selection. Widget keys,
descendant StatefulWidgets, controllers, inherited context, Flutter themes,
assets and general inherited/provider widget integration are unsupported. A
bounded root Riverpod consumer is supported as described below. CSS approximates layout.

The foundation bridge provides `kIsWeb`, release/profile/debug constants and
`compute`. Like Flutter's web implementation, `compute` yields then executes on
the current event loop; it creates no worker and emits no Flutter profiling
events. `debugPrint` is a replaceable callback using synchronous console output;
Flutter's throttling is not implemented and non-null `wrapWidth` is rejected.
ChangeNotifier, ValueNotifier, diagnostic classes and other foundation APIs are
not implemented and fail official compilation.
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
such as nested StatefulWidgets fail at runtime; they are not yet preflighted.
The local graph limit is 500 libraries; dependencies outside the project through
relative imports are rejected. Package dependencies use the project's existing
package configuration when present. Flutter-dependent transitive packages can
still prevent official compilation.

Static preview configuration and `--data` snapshots are rejected with this
target. A service's runtime data must arrive through executable Dart. The fixture
uses an explicit browser transport and loopback-only synthetic API, without
production authentication or any inferred request behavior.

## Evidence and remaining work

An automated Node DOM contract test runs actual compiled output through initial
loading, HTTP success, two overlapping requests, stale-response suppression,
detached callback rejection, HTTP failure and retry. Separate tests check source
immutability, unsupported imports, unsupported widget APIs and CLI failure before
output creation. Node tests supplement manual Chromium checks; they are not a
cross-browser certification.

Before using a real provider-driven application, address retained-view
reconciliation, lifecycle/subscription cleanup, supported package boundaries and
authenticated browser transport. The source graph still needs package extraction
support. Evaluate Jaspr as the component backend against
these same fixtures before extending this minimal compatibility layer broadly.
The [logic architecture](LOGIC_RUNTIME.md) describes production release gates.

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

The runtime accepts `@immutable`, legacy integer ARGB `Color` values, `IconData`
metadata, a bounded set of rounded Material icon constants, and abstract
`ThemeExtension` declarations. This lets repository/model dependency graphs
include visual registries without replacing their business logic. Annotation
exports resolve to the compiler's official `meta` package even when the input
project has no package configuration.

These declarations do not provide Flutter painting or theme inheritance.
`Theme.of`, `ThemeData.extension` and `Color.lerp` throw explicit
`UnsupportedError`s when executed. No icon font is loaded or rendered. Color
values preserve the low 32 bits and expose integer ARGB channels; floating-point
color spaces and general Flutter Color methods are outside this subset. The
supported icon constants are listed in
`lib/src/runtime/material_icons_metadata.dart`, with source attribution in
`THIRD_PARTY_NOTICES.md`.

## Root Riverpod consumers

The target maps `package:flutter_riverpod/flutter_riverpod.dart` to a small
widget bridge backed by the **official pure-Dart Riverpod 2.6.1 engine**, not a
replacement provider evaluator. Existing `Provider`, `StateProvider`,
`FutureProvider` and dependency callbacks execute in its `ProviderContainer`.
See [Riverpod's container architecture](https://riverpod.dev/docs/concepts2/containers).

Supported widget boundary:

- One root `ProviderScope(child:, overrides:)` around the stateful entry, with
  optional `MaterialApp`/`Scaffold` wrappers.
- `ConsumerStatefulWidget` and `ConsumerState`, attached before `initState`.
- `ref.read` in lifecycle/request callbacks and `ref.watch` during `build`.
- Watched subscriptions trigger coalesced native renders, persist across builds,
  and close when no longer watched. Root disposal closes subscriptions and the
  owned container, independently of an application's call to `super.dispose`.

Nested scopes/consumers, `ConsumerWidget`, widget-ref listen/refresh/invalidate,
Flutter inherited context, generated Flutter-dependent provider packages and
Riverpod 3.x compatibility are not implemented. Missing/incompatible engine
versions fail before compilation. Projects with a package configuration must
provide `riverpod` 2.6.1; fixtures without one use the compiler's configuration.
The report attributes this as `providerIntegration: bounded-root-riverpod-2.6.1`
only when the Flutter Riverpod import is mapped. Root view updates still replace
DOM and can lose focus. None of this automatically adapts an application's
authentication or networking dependencies.
