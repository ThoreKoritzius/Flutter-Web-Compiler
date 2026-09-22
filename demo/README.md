# Interactive comparison showcase

```sh
dart pub get
dart run tool/showcase.dart
```

This builds both targets and serves [127.0.0.1:8097](http://127.0.0.1:8097). Use `--port 8098` for a different port or `--no-serve` to build without starting a server.

## What is shared

Both builds consume `examples/showcase/lib/main.dart`:

- Native target: static Flutter UI becomes HTML; `FeatureSearch` uses an explicit native filter-list adapter; `CounterPanel` stays a lazy Flutter island.
- Flutter target: the normal Flutter toolchain builds the entire app, including its Dart search implementation and counter.

The comparison shell in this folder is ordinary hand-written HTML/CSS/JS. It is clearly separate from compiler output. `tool/showcase.dart` copies it into `build/showcase/` and generates actual artifact-size metadata for this particular build.

## Why one toggle and two targets

The shell switches an iframe between `/native/` and `/flutter/`. Only one target loads at a time; there is no hidden Flutter preload on the initial native visit. Each also has an independent link. They share a local origin, not application state. Switching reloads the target and resets local search/counter state. Browser caches can persist, so toggling is not a cold-start speed benchmark.

This is a comparison of two builds from the same source, not dynamic renderer replacement inside a running Flutter application.

## Try it

1. Select a paragraph in the native target.
2. Search `HTML`: one feature should remain. Search a nonsense string: none should remain. Clear the input: all six should return.
3. Activate the Flutter counter and increment it. The surrounding content should remain visible.
4. Switch to Flutter Web and perform the same search. Its counter starts immediately.
5. Open each target independently to inspect the document and requests without the comparison shell.

Search is intentionally a limited adapter. Matching these two implementations does not imply arbitrary StatefulWidget, TextField or Riverpod support. The source uses ordinary Flutter imports; adapter intent is in the sidecar config.

## Measurements

The sidebar shows raw selected build artifacts for native initial, native after counter activation, and Flutter initial. Hover for per-file gzip level-9 totals. The shell, HTTP overhead, browser caches, alternate renderer variants and external fallback fonts are excluded. The standalone benchmark in `tool/benchmark.dart` uses different, smaller fixtures; do not mix its numbers with this showcase.

For desktop Lighthouse performance and SEO audits, leave the server running and use a second terminal (Node >=22.19 and Chrome required):

```sh
npm ci --prefix tool/browser
npm run audit --prefix tool/browser
# Optional URL and run count:
npm run audit --prefix tool/browser -- http://127.0.0.1:8097/ 5
```

The script opens a fresh headless Chrome for each run and audits each independent target. It saves raw Lighthouse reports under ignored `build/browser-audits/` and a portable summary in `benchmarks/results/showcase-browser.json`. Reload the comparison page after running. Recorded results are displayed only when their hash matches current artifact metadata, including content hashes. A new build without matching results shows “not audited”.

The summary includes all samples, medians, ranges, settings, Chrome environment, Lighthouse version and caveats. Both targets have equivalent description metadata. A perfect Lighthouse SEO score does not establish indexability or ranking. Flutter's canvas can produce no LCP candidate while Lighthouse supplies an estimate; its LCP and derived performance score need special caution. FCP is not application readiness. This desktop, simulated-throttling, localhost run does not measure real mobile networks or island activation latency.
