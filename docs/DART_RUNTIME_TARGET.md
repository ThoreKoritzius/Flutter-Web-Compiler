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
It rewrites the URIs of supported Flutter material/foundation imports and exports
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
assets and provider integration are unsupported. CSS approximates layout.

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
