# Prototype verification

Verified locally on 2026-09-21 with Flutter 3.41.6, Dart 3.11.4, macOS and the Codex in-app Chromium browser.

## Automated checks

- `dart analyze`: no issues.
- `dart test`: 22 passing tests, including CLI integration tests.
- The catalog and shared-source showcase compile through real release Flutter builds.
- Static builds emit HTML/CSS with no scripts or Flutter directory into a fresh output directory.
- Strict DOM-only mode rejects configured Flutter islands before creating output.
- Constructor fields, defaults, scope isolation and rejection cases are covered.
- Native adapter tests cover escaped input/list content, multiple controls, invalid contracts and the actual showcase source.
- Project inspection tests verify source-site reporting, generated-file exclusion, parser failures and no input modifications.

## Browser checks

The original counter prototype was verified for real H1/H2 document structure, no initial Flutter requests, host-element embedding, counter increment and page-title preservation. A separate JavaScript-disabled browser run was not performed; static CLI tests assert that emitted content is present without script tags.

The shared-source showcase adds native/Flutter targets and an explicit local filter-list adapter. Its test procedure is in [the demo guide](../demo/README.md).

## Benchmarks

The reproducible paired release-build artifact-size experiment completed successfully. Current raw results, exact artifact sets and interpretation limits are in [BENCHMARKS.md](BENCHMARKS.md) and [the JSON snapshot](../benchmarks/results/2026-09-21.json).

These are file sizes and computed gzip sizes, not cold-network measurements or browser timings. No Lighthouse score, SEO ranking, broad app coverage or cross-browser certification is claimed.

## Toolchain notes

Flutter emits a deprecated `--pwa-strategy` notice and a font-family diagnostic for the small fixtures. Builds succeed and the configured font manifest loads. The island bootstrap currently depends on the default generated format. These integrations require review when changing the supported SDK.

CI is configured for compiler checks, Flutter analysis and showcase release builds. Local results are recorded above; GitHub Actions is the authority for remote CI status. No public deployment or package publication is configured.
