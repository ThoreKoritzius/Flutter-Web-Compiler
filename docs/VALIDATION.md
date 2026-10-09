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


## Static-data parser update — 2026-10-08

`dart analyze` passes and the compiler suite now has 39 passing tests. Added coverage includes forward constant references, conditional/spread lists, null-aware spreads, constructor shadowing/defaults, isolated top-level scope, cycles, invalid conditions/spreads, unsupported patterns/loops and bounded collection expansion. Earlier browser/benchmark results above retain their original date; this parser change does not constitute a new performance audit.


## Resolved project parser — 2026-10-08

`dart analyze` passes; 49 tests pass, including ten resolver cases for prefixes, exports, duplicate class names, constants, package-local imports, parts, import cycles, private roots, missing/ambiguous imports, source diagnostics and rejection of function-name impersonation/conditional imports. Resolver unit tests use minimal framework declarations to run without Flutter; separate real Flutter checks compile the catalog and the five-file `examples/multifile` fixture with `--resolve-imports`. The latter also passes `flutter analyze` and emits static HTML/CSS with no adapters or engine. CI now installs/analyzes/builds that fixture. These are local results; remote CI completion is not implied.

The health fixture also builds with resolved analysis. Its five SVG charts match the existing syntax-mode build exactly; resolved Paint/Path/Rect constructors are checked against dart:ui declarations.


## Web conditional resolution and inspection — 2026-10-08

53 tests pass and `dart analyze` is clean. New cases verify web import/export selection on the native host, first-match ordering, explicit string equality, prefixed constants, fallback branches, rejection of custom condition variables and resolved inspection scope. Required constructor inputs remain blockers; unrelated libraries do not enter the resolved score. Resolution failure produces no score.

The real multi-file Flutter fixture passes `flutter analyze`, builds to DOM with `platform_web.dart` selected, and resolves inspection through the CLI. It accepts one of two parameterless roots: its Page compiles with the actual Heading arguments, while Heading fails in isolation without its required title. This demonstrates why independent-root percentages are not application conversion coverage. CI includes both commands. Analyzer is pinned to 7.7.1 because target environment configuration currently uses an isolated internal factory.


## Input-aware inspection — 2026-10-08

56 tests pass and analysis is clean. Regression cases distinguish a non-web fallback from an unsupported selected web implementation, compile real constructor arguments without guessing missing inputs, retain runtime identifiers as context requirements, and verify the 1,000-site cap reports skipped work explicitly.

The real multi-file CLI inspection reports one static root and one input-dependent root, while both actual constructor sites compile. This verifies the distinction between declaration-level acceptance and supplied-input evaluation. It does not establish runtime reachability or full application conversion. Resolved inspection schema 4 keeps legacy root fields for readers and adds categories, diagnostic codes and call-site records.


## Static component previews — 2026-10-08

62 tests pass, `dart analyze` is clean, and the reusable sample-stat fixture passes Flutter analysis and a resolved DOM-only CLI build. Coverage includes local scope and field shadowing, arithmetic, positional/default constructor inputs, scalar type promotion, explicit theme snapshots, null copyWith behavior, color alpha/decoration and rejection of mutable locals, side effects and unsafe CSS values. A previous unsupported-maxLines test now uses unsupported softWrap; maxLines has a supported approximate CSS mapping. Preview layout was checked at desktop and 390 px phone width.

This validates static components with supplied inputs. It does not establish live theme parity, provider/lifecycle behavior, full app startup or interactive application conversion. Existing full-showcase benchmark snapshots were not regenerated for this feature.

## Bounded native state — 2026-10-09

67 tests pass and Dart analysis is clean. New coverage checks initial boolean
state, both variant transitions, literal assignments, independent instances and
rejection of lifecycle methods, extra fields, arbitrary/async callbacks,
unsupported inactive branches, nested state and state-shadowing locals.
The shared period-selector fixture passes Flutter analysis and a resolved
DOM-only CLI build. Browser checks verified mouse activation, Enter activation,
changed totals and retained keyboard focus. This is a finite-state compiler
experiment; it does not validate providers or full application conversion.

## Targeted boolean-state bindings — 2026-10-09

70 tests pass and Dart analysis is clean. DOM binding tests apply transitions in
both directions and check text, empty text, styles, attribute removal/disabled,
escaping and retained button identity. Structural changes and app-context/theme
rebuilding fail explicitly. Existing static-site tests still require no JS.
The resolved period-selector build emits one tree with binding metadata and no
HTML templates. Browser click and Enter checks update both totals and labels
while preserving keyboard focus without runtime focus restoration.
The compiler still evaluates both boolean states; general reactive expression
lowering and providers remain unimplemented. No performance benchmark was rerun.

## Typed local-state expressions — 2026-10-09

73 tests pass; Dart and Flutter fixture analysis are clean. The state tree is now
compiled once. Coverage includes multi-field state, derived/interpolated text,
reactive stateless constructor inputs, dependency filtering, disabled guards,
instance isolation, escaping, short-circuit evaluation, safe-integer boundaries
(including host multiplication overflow), and bounded expression expansion.
Node-based tests run the emitted JavaScript and compare it with Dart evaluation.
Runtime overflow leaves both state and bound content unchanged and shows status.

The shared fixture builds through resolved imports. Browser checks exercised
mouse and Enter increments/decrements, derived minutes, disabling at zero, and
period changes independent of the counter. The updated demo has 22 visited
boundaries and 10.7 KiB initial uncompressed HTML/CSS/JS; this is artifact size,
not browser timing. The catalog artifact benchmark was rerun successfully with
raw results under ignored `build/expression-benchmarks/`; published historical
benchmark snapshots and performance claims were not changed.

Boolean DOM-diff tests and the old implementation were replaced by expression
and runtime tests. Reactive CSS and structural widget changes are explicitly
unsupported by this typed backend; static styling remains available. This does
not establish general Dart, lifecycle, provider or whole-application conversion.

## Composed static components — 2026-10-09

78 tests pass and Dart/Flutter fixture analysis are clean. New coverage checks
original nested widget declarations selected through preview configuration,
lexically scoped getter evaluation, null assertions, absent optional content,
getter recursion/unsupported bodies, descriptor validation and nesting limits,
positive Expanded flex, and Card radius/border validation. The independent
multi-file InfoPanel/SampleStat composition passes a resolved CLI build; CI now
runs it alongside the existing fixtures. The selected composed preview was
visually checked at the normal browser size and 390 px phone width.

The catalog artifact benchmark was rerun under ignored
`build/composition-benchmarks/`. Existing historical benchmark snapshots were not
changed. These checks establish configured read-only composition with approximate
CSS, not application startup, data loading, provider state or full-page parity.
