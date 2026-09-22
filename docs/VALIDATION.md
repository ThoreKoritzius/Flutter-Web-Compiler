# Prototype verification

Verified locally on 2026-09-22 with Flutter 3.41.6, Dart 3.11.4, macOS and the Codex in-app Chromium browser.

## Automated checks

- `dart analyze`: no issues.
- `dart test`: 34 passing tests, including CLI integration tests.
- The catalog and shared-source showcase compile through real release Flutter builds.
- Static builds emit HTML/CSS with no scripts or Flutter directory into a fresh output directory.
- Strict DOM-only mode rejects configured Flutter islands before creating output.
- Constructor fields, defaults, scope isolation and rejection cases are covered.
- Native adapter tests cover escaped input/list content, multiple controls, invalid contracts and the actual showcase source.
- Project inspection tests verify source-site reporting, generated-file exclusion, parser failures and no input modifications.

## Browser checks

The original counter prototype was verified for real H1/H2 document structure, no initial Flutter requests, host-element embedding, counter increment and page-title preservation. A separate JavaScript-disabled browser run was not performed; static CLI tests assert that emitted content is present without script tags.

The shared-source showcase native and Flutter search controls were checked for filtering, zero matches and clearing; the Flutter counter increments. The global toggle changes independent targets and resets local state. Its test procedure is in [the demo guide](../demo/README.md).

## Benchmarks

The reproducible paired release-build artifact-size experiment completed successfully. Current raw results, exact artifact sets and interpretation limits are in [BENCHMARKS.md](BENCHMARKS.md) and [the JSON snapshot](../benchmarks/results/2026-09-22.json).

These are file sizes and computed gzip sizes, not cold-network measurements or browser timings. A separate three-run desktop Lighthouse audit now measures the showcase; see `benchmarks/results/showcase-browser.json`. Both targets score 100 for SEO in this audit. Canvas LCP estimates and derived performance scores need special caution. No SEO ranking, broad app coverage or cross-browser certification is claimed.

## Toolchain notes

Flutter emits a deprecated `--pwa-strategy` notice and a font-family diagnostic for the small fixtures. Builds succeed and the configured font manifest loads. The island bootstrap currently depends on the default generated format. These integrations require review when changing the supported SDK.

CI is configured for compiler checks, Flutter analysis and showcase release builds. Local results are recorded above; GitHub Actions is the authority for remote CI status. No public deployment or package publication is configured.

The catalog inspection currently accepts 3 of 6 direct widget entry points (50%). This is the documented parameterless-entry dry-run metric, not general application compatibility. Static interpolation and conditional branches have regression tests. Current development-only Node dependencies pass `npm audit` with no reported vulnerabilities at installation time.


The revised demo was visually checked at 1440 px desktop and 390 px phone widths. The Wasm build renders the shared illustration and data table; search returns one match for HTML and its counter increments. Three-target browser results replace the prior text-only showcase measurements. CLI tests now cover root discovery without a sidecar and `build web` invocation. Image/table tests cover escaping, safe paths and mismatched rows.


The final renderer audit uses a real desktop user-agent with GPU support enabled. Recorded requests confirm CanvasKit for the JavaScript build and SkWasm plus `main.dart.wasm` for the Wasm build. Median Lighthouse performance scores are 100 / 70 / 73 (native / CanvasKit / Wasm); SEO is 100 for all three. Canvas LCP caveats still apply. The current illustration is the supplied refinement and is included in all size/transfer measurements.


The health demo's restricted painter compiler passes `dart run tool/check_health_geometry.dart`: actual Flutter Canvas drawing commands agree with compiled SVG rectangle coordinates, path bounds/length, stroke width and scale for bar and line fixtures (0.001 tolerance). Regression tests verify source geometry changes propagate and unsupported drawing calls fail. This does not establish arbitrary painter coverage or pixel-perfect layout parity.
