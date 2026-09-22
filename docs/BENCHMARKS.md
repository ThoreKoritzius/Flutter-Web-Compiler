# Benchmark methodology

## What is measured

Selected build artifacts for two toy workloads, each compiled from the same source widget by Flutter Web and Flutter DOM Compiler:

- **Static:** `StaticApp` in `examples/catalog/lib/main.dart`. Text and layout; no interaction.
- **Hybrid:** `App` in the same file. Document content plus `CounterPanel`. Standard Flutter renders the counter immediately; the DOM build offers an explicit load button before it starts the real Flutter counter.

This is a build-artifact size experiment. It is not a network trace, rendering-speed benchmark, CPU/memory benchmark, Lighthouse test, SEO score or production application benchmark.

## Reproduction

Use Flutter 3.41.6 / Dart 3.11.4 and the committed dependency lockfiles:

```sh
dart pub get --enforce-lockfile
dart run tool/benchmark.dart
```

The script rebuilds both DOM outputs, the real Flutter island and both standard Flutter outputs. Standard Flutter builds use `--release --no-web-resources-cdn --pwa-strategy=none`. The script creates temporary entry points under the example's `.dart_tool/` so the original widget source is reused unchanged.

Results are written to ignored `build/benchmarks/results.json` and `table.md`. The JSON contains SDK versions, fixture/compiler hashes and each selected file's exact size. The recorded snapshot is [results/2026-09-21.json](../benchmarks/results/2026-09-21.json).

## Selected artifact sets

| Stage | Files counted |
| --- | --- |
| Static DOM | `index.html`, `styles.css` |
| Hybrid DOM, initial | HTML, CSS, `islands.js` |
| Flutter runtime | Bootstrap, `main.dart.js`, Chromium CanvasKit JS/WASM, font manifest and all fonts declared there |
| Standard Flutter, initial | HTML plus the Flutter runtime set |
| Hybrid, after activation | Initial DOM set plus the island runtime set |

Each file is independently compressed with Dart `GZipCodec(level: 9)`, then sizes are summed. KiB means 1,024 bytes. Gzip numbers model that compression setting; the local Python server does not actually enable gzip responses.

The chosen renderer is CanvasKit's Chromium variant. Alternate renderer binaries, source maps and unused deployment files are excluded. Files in a full deployment directory are therefore much larger than the counted set. HTTP headers, TLS overhead, caches, compression negotiation and external fallback fonts are not included. Declared fonts may be fetched conditionally, so the selected set must not be described as an observed request list.

## Results

<!-- benchmark-table:start -->
| Workload | Build | Initial KiB | Initial gzip KiB | After activation KiB | After activation gzip KiB |
| --- | --- | ---: | ---: | ---: | ---: |
| static | flutter_dom | 2.32 | 1.17 | 2.32 | 1.17 |
| static | flutter_web | 7328.47 | 2652.64 | 7328.47 | 2652.64 |
| hybrid | flutter_dom | 5.05 | 2.26 | 7356.02 | 2660.49 |
| hybrid | flutter_web | 7380.57 | 2667.49 | 7380.57 | 2667.49 |
<!-- benchmark-table:end -->

## How to interpret the result

The main result is **engine independence for supported initial documents**. The static page has no Flutter runtime dependency. The hybrid delays a substantial engine/application cost until activation. After activation, the selected artifact total is close to a regular Flutter build; another application could have a higher total cost.

The source is paired, but the rendering contracts differ: the DOM side has approximate CSS layout and system fonts, while Flutter preserves its layout, theme and framework behavior. These small examples deliberately exercise a supported subset. Do not extrapolate their size ratios to arbitrary applications or claim equivalent feature coverage.

No `N× faster` or `100/100 SEO` claim is supported by these results. DOM can improve document delivery without proving a search ranking change. A large compatibility runtime, native forms or shared state could increase future output sizes materially.

## Next benchmark gates

1. Add independent data-driven listing/detail and native form fixtures.
2. Use a stable browser harness for cold-cache navigation and island activation; preserve raw request and error records.
3. Run at least five repetitions per workload with documented browser, hardware, viewport, network and CPU settings. Report medians and ranges for content availability, interaction readiness and total transfer.
4. Measure both CanvasKit and supported Wasm configurations rather than presenting a single renderer as all Flutter Web.
5. Include interaction correctness, accessibility and layout checks alongside size/time results.
6. Compare FlutterJS or Jaspr only after running the same workloads and documenting any source adaptation.


## Separate showcase browser audit

Run the showcase server, then `npm ci --prefix tool/browser && npm run audit --prefix tool/browser`. Node >=22.19 and Chrome are required. Unlike the artifact experiment above, this audits the larger shared-source showcase with search and its deferred counter. The default is three fresh headless Chrome runs per target, desktop viewport, simulated 40 ms RTT / 10,240 Kbps / 1× CPU, localhost HTTP without response compression. Counter activation is excluded. Five or more runs and real devices remain a stronger future validation gate.

[The portable result](../benchmarks/results/showcase-browser.json) includes medians, ranges, all samples, Lighthouse version, browser environment and effective settings. Raw Lighthouse reports stay under ignored `build/browser-audits/`. Results are linked to the compiled artifacts by a SHA-256 hash of their size/content-hash manifest. The demo declines to show stale scores after a changed build.

Both targets have matching description metadata. The audit currently gives both an SEO score of 100: it does not measure search ranking or guarantee indexing. Native HTML contains an H1 and search input before JavaScript. Flutter paints app content after startup. FCP is not readiness and does not distinguish these behaviors adequately. Lighthouse's canvas trace can emit `NO_LCP` yet report a synthesized LCP estimate and a derived performance score; do not interpret these as a reliable application-startup comparison. No N× faster claim follows from this audit.

### Expanded renderer comparison

The current showcase includes the generated image and a native semantic table. Its numbers supersede the earlier text-only showcase results; the separate catalog artifact snapshots remain historical fixtures. The benchmark now visits `/native/`, `/flutter/` (Dart JavaScript/CanvasKit), and `/wasm/` (`--wasm`, runtime-selected renderer).

The harness explicitly disables Lighthouse's default mobile user-agent override, in addition to desktop form factor and viewport. Each sample records renderer requests, and the UI labels the observed renderer so a Wasm build falling back to CanvasKit cannot be mistaken for SkWasm. Cross-origin-isolated multithreaded rendering, forced CanvasKit fallback, other browsers/devices and third-party DOM frameworks remain unmeasured. CanvasKit itself also uses WebAssembly; “Wasm build” refers to the Dart compilation target.
