# Prototype verification

Verified locally on 2026-09-21 using Flutter 3.41.6, Dart 3.11.4, macOS and the Codex in-app Chromium browser.

## Automated checks

- `dart analyze`: no issues.
- `dart test`: 13 passing tests, including two CLI integration tests.
- `flutter analyze` in `examples/catalog`: no issues.
- Hybrid example: release Flutter build succeeds.
- Static example: CLI emits HTML/CSS and no JavaScript or Flutter directory into a fresh output directory.
- Strict DOM-only mode rejects a configured island before creating output.

Compiler coverage includes HTML/metadata escaping, explicit heading semantics, custom static composition, unsupported widgets/arguments, dynamic expressions, recursive builds, stateful DOM rejection, multiple island rejection, invalid source/layout and the real example input.

## Browser checks

Served `build/demo` using Python's HTTP server on `127.0.0.1:8097`.

1. Initial document has a real H1, H2 and visible paragraphs before island activation.
2. Server access logs show requests for `/`, `/styles.css` and `/islands.js` before activation, with no Flutter asset requests. A browser favicon request is incidental.
3. Clicking the native load button requests the generated island bootstrap, Flutter application JavaScript, CanvasKit and fonts. Cached resources do not necessarily reappear in subsequent request logs.
4. Flutter renders inside `#flutter-island`; the surrounding document stays visible.
5. Enabled Flutter accessibility and clicked **Increment**: the counter changed from 0 to 1.
6. The final build retains the configured document title after activation.

The HTML-only CLI test verifies content and headings are present in the emitted file and that it contains no script tags. A separate browser run with JavaScript disabled was not performed. No Lighthouse score, SEO ranking claim, cross-browser certification or mobile layout parity claim is made.

## Size observations

These are **uncompressed file sizes**, not a compressed network benchmark. The development HTTP server does not gzip responses. Browser caches and optional assets affect actual transfer.

| Hybrid initial resource | Bytes |
| --- | ---: |
| HTML | 1,826 |
| CSS | 1,079 |
| Lazy loader JavaScript | 1,720 |
| Total | 4,625 |

On activation, the release application JavaScript is about **1.74 MB**, and the Chromium CanvasKit WASM file is about **5.69 MB**, with additional bootstrap, CanvasKit JavaScript and font resources. These are decimal MB. Other browsers may select different CanvasKit assets.

This demonstrates deferred Flutter cost, not a tiny Flutter runtime. The initial DOM page is small; the island still carries substantial engine cost. `report.json` records actual initial file sizes for each build.

## Remaining limitations and build notes

- Single source file, literal data, approximate CSS layout, one explicit island and no shared state bridge.
- Source constructors are recognized syntactically; whole-program symbol resolution is still planned.
- Island bootstrap extraction accepts only the default generated Flutter bootstrap format.
- Flutter reports a deprecated `--pwa-strategy` option and a font-family diagnostic during the build. The browser successfully loads the configured font manifest and the counter remains functional. These SDK integration details should be revisited when pinning a supported production toolchain.
- No CI or hosted deployment is configured yet. The repository contains source and lockfiles; generated bundles remain local and ignored by Git.
