# Executable logic: official Dart compiler

The static widget evaluator is not a general Dart runtime. Executable business
logic should use the official Dart-to-JavaScript compiler rather than an expanding
set of AST evaluation rules. This is the direction for runtime integration, not
a claim that arbitrary existing Flutter applications now compile.

## Reproducible request-flow experiment

From the repository root:

```sh
dart pub get
dart run tool/logic_demo.dart
```

Open http://127.0.0.1:8121/. `--no-serve` compiles the experiment without starting
the loopback-only server; CI uses that mode. Output is ignored under
`build/logic-demo/`. The script uses the current SDK's `dart compile js -O2`.

The browser performs an actual same-origin HTTP request to the synthetic local
API. The original fixture repository's `async` method, `jsonDecode`, factories,
numeric validation and collection aggregation execute as official compiled Dart.
There is no Flutter engine, no snapshot binding and no handwritten JavaScript
replacement for repository logic. Transport and DOM view adapters are explicit
Dart source in `examples/logic/lib/browser.dart`. The HTML host is handwritten;
it is **not an automatically converted Flutter screen**. No production endpoint,
credentials or authentication are included in this experiment.

Refresh/retry shows loading and then updates semantic DOM nodes. Test request
failure produces a real HTTP 503; retry recovers. Existing data remains visible
while loading or after failure. Text is assigned with `textContent`, not HTML
injection. Status is a live region and the panel declares `aria-busy`.

## Runtime contract

`package:flutter_dom_compiler/runtime.dart` exports experimental
`AsyncResource<T>` and `ResourceState<T>`. They have no Flutter dependency.

- States: idle, loading, data, error. Errors are retained as objects for the host
  to translate into appropriate user-facing messages.
- `refresh()` starts a new generation. Older successes and errors cannot publish
  over a newer request. This suppresses stale updates; it does not abort HTTP.
- Synchronous load throws and asynchronous failures become error states.
- `listen()` returns an unsubscribe function. It does not replay the current
  state; read `state` when attaching to an existing resource.
- `dispose()` invalidates pending results and removes listeners. New refreshes
  or subscriptions fail. Hosts must call it when removing a view.
- Listener callbacks execute synchronously and must not throw. Listener failures
  are host errors, not network errors.

The fixture transport times out while obtaining response headers; body reading
and true request cancellation need separate policy. This helper is deliberately
small; it does not replace Riverpod's caching, dependency tracking or lifecycle.

## Integration strategy

1. Compile pure-Dart repositories, models and shared services with dart2js.
   Preserve their implementations and use explicit platform dependencies.
2. Establish the supported service boundary: browser HTTP, session cookies,
   CSRF, refresh, timeouts and cancellation. Flutter-dependent imports must be
   isolated or covered by explicit, tested adapters; never silently removed.
3. Evaluate a DOM backend such as Jaspr against generated component/state
   bindings before committing to a second general component runtime.
4. Connect provider subscriptions and disposal to that backend. Flutter's
   `ConsumerState`, `initState`, `mounted`, `setState` and widget identity still
   require supported lowering or adapters.
5. Preserve static HTML for public content and define hydration behavior.
   Runtime-fetched private data does not itself provide pre-rendered SEO content.

Existing static builds and their bounded native-state runtime continue to work.
This experiment is separate from `flutter_dom build web`; there is no automatic
logic extraction, provider conversion or runtime model-to-widget lowering yet.

## Evidence required before production use

The resource tests cover decoding failures, loading/error/retry, retained data,
out-of-order success/error, unsubscribe and disposal. An automated Node DOM
contract harness runs the actual dart2js output against a local HTTP server and
checks decoding, loading, failure and retry. It is not a real browser. CI also
compiles the browser entry; browser failure/retry is checked manually.

Production readiness still requires automated real-browser tests across the
supported engines, disposal and event cleanup in generated views, transport
cancellation, authentication/session tests, SDK compatibility gates, supported
package contracts, reproducible size/performance measurements and realistic
application fixtures. Package publication and repository visibility remain
separate decisions. Current support is experimental.

## Upstream components

- [Official Dart compilation](https://dart.dev/tools/dart-compile#javascript-js)
- [Dart JavaScript interop](https://dart.dev/interop/js-interop)
- [Browser-capable HTTP](https://pub.dev/packages/http)
- [Standalone GraphQL client](https://pub.dev/packages/graphql)
- [Pure-Dart Riverpod](https://pub.dev/packages/riverpod)
- [Jaspr DOM framework](https://docs.jaspr.site/)

These are reuse candidates and platform capabilities, not a verified guarantee
that an arbitrary Flutter dependency graph compiles without changes.
