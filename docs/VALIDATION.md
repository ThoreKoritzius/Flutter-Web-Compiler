# Prototype verification

## Flutter-source Dart runtime target (2026-10-12)

The full suite has 158 passing tests and analysis is clean. The runtime target
builds through `flutter_dom build web --dart-runtime`; CI also builds its demo.
The actual compiled original fixture source passes a local HTTP/Node DOM contract
test covering initState, loading, repository/model decoding, setState, overlapping
requests, stale results, detached event handlers, failure and retry. Unsupported
imports/APIs fail, source files remain unchanged and failed CLI compilation does
not create output. Manual Chromium checks verify success, HTTP 503 and recovery.

This target substitutes an explicit, bounded Flutter-shaped API. It supports one
root state and replaces DOM on updates. No provider compatibility, retained focus,
static app HTML, authenticated service integration or production readiness is
claimed. See [the target contract](DART_RUNTIME_TARGET.md).

## Official Dart logic experiment (2026-10-12)

`dart analyze` passes and the complete suite has 155 passing tests. The separate
logic experiment builds with `dart run tool/logic_demo.dart --no-serve`.
An automated Node DOM contract harness runs actual dart2js output against a live
local HTTP server and verifies decoding, loading, HTTP failure, retained data and
retry. Pure-Dart tests also verify stale successes/errors, disposal, unsubscribe
and reentrant refresh behavior.

Manual in-app Chromium verification confirms initial loading, native text/list
updates, a real synthetic HTTP 503 and successful retry. The view is an explicit
adapter, not automatically translated Flutter lifecycle/provider logic. This is
an experimental architecture check, not production or cross-browser certification.
See [the runtime contract and release gates](LOGIC_RUNTIME.md).

## Historical prototype checks

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


## Stateful inputs and native collections — 2026-10-10

83 tests pass; `dart analyze` and the real multifile fixture's `flutter analyze`
pass. Coverage includes constructor/list type checks, input-derived initialization,
loop scope, shared prefixes, rejected operations and shipped runtime visibility
updates. The resolved DOM-only records build accepts 18/18 visited boundaries,
with one state owner, no adapters/island and 8.8 KiB initial files. Counts include
compiled hidden content and do not represent whole-app coverage.

Browser verification at localhost:8113 confirms mouse expansion from two to five
rows and keyboard collapse to two, with the button retained. The same source is
valid Flutter. This is a synthetic records fixture, not a live application feature.
The artifact benchmark command also passes; historical showcase performance/SEO
measurements above were not rerun or updated by this change.


## Immutable model inputs — 2026-10-10

87 tests pass and `dart analyze` is clean. New tests cover configured and source
constructors, nested models, isolated getter scope, recursive/unsupported behavior
and imported same-name model identity rejection. The real Flutter multifile fixture
passes `flutter analyze`. The resolved DOM-only records fixture now uses imported
RecordEntry fields/getters, with 18/18 visited boundaries, one state owner, five
static model instances, zero adapters/island and 8.9 KiB initial files. These are
synthetic snapshot inputs and artifact sizes, not whole-app or performance scores.
Browser checks confirm the derived duration labels and native expand/collapse.

The required artifact benchmark also completes successfully; prior published
performance/SEO claims are unchanged.


## Pure instance helpers — 2026-10-10

90 tests pass; Dart and real Flutter fixture analysis are clean. Helper coverage
includes widget/model/state expressions, caller-argument versus instance scope,
named defaults, annotated model inputs, recursion, rejected mutations/block/async
bodies and imported resolved calls. The prior unsupported-helper diagnostic test
now uses a block body, since its former expression body is supported.

The records fixture now calls original row and duration-format helpers with
18/18 visited boundaries, zero adapters/island and 8.9 KiB initial files. Browser
verification confirms duration labels, mouse expansion and keyboard collapse.
The required artifact benchmark completes successfully; existing published
performance/SEO measurements remain unchanged. Helpers lower original expressions
during compilation; this does not demonstrate arbitrary runtime Dart execution.


## Static build branches and visual inputs — 2026-10-10

94 tests pass; Dart analysis and the real Flutter multifile fixture analysis
are clean. New cases cover static early returns, nested scope, rejected visited
statements, uniform borders, SVG icon semantics, visual descriptors and resolved
prefixed class constants with forward references. The independent summary fixture
builds DOM-only and is included in CI. The required artifact benchmark succeeds.
Historical performance/SEO claims are unchanged.

A local external-app evaluation also compiles original read-only metric widget
bodies with explicit synthetic inputs/theme, no adapters, engine or JavaScript.
Its separate Flutter Web counterpart uses the same original widget declarations
and mock values. Both browser targets render the metric labels, values and
footnotes. Private evaluation source, harness, configuration and results are
excluded from Git. This is component preview composition, not the original page
layout, startup, live data or navigation. SVG glyphs and CSS remain approximate.

## Static collection patterns and read-only inputs — 2026-10-11

97 tests pass and `dart analyze` is clean. New coverage includes scoped final
pattern bindings, nullable bindings, static guards, rejected mutable/typed
patterns, unused model serializers, model fields named `key`, opaque callback
inputs and restricted Align mappings. Callback invocation remains unsupported;
supplying an opaque callback does not establish native event coverage. The
required artifact benchmark passes; published performance/SEO claims are unchanged.

A private external-app evaluation compiles an original stateful records card's
empty branch and original model getter with synthetic inputs: 21/21 visited
boundaries, zero adapters/island and 9.1 KiB initial files. The state runtime is
emitted. Browser verification confirms the empty-state and derived coverage text.
These counts apply only to the selected branch; populated records, activity
navigation and full-app startup are not validated. Private inputs and artifacts
remain excluded from Git.

## Static helper resolution — 2026-10-11

100 tests pass and Dart analysis is clean. New cases cover class-qualified static
expression helpers/getters, nested helper calls, defaults, class constants, caller
scope isolation, rejected unsafe bodies/arguments and imported duplicate class
names. Nullable unsupported model field types accept only absent null values;
non-null snapshots remain rejected. The artifact benchmark passes; no browser
timing or SEO measurements were updated.

The private populated-records probe now passes model construction and reaches an
unsupported indexed theme-extension expression. No populated feature output or
interaction coverage is claimed. The existing verified empty-state demo remains
the latest original-component browser deliverable.

## Original theme snapshots and populated records — 2026-10-11

104 tests pass and Dart analysis is clean. New coverage includes source-constant
theme extensions, typed enum map keys, imported enum/class identity, expression
index operators, missing snapshots and rejected mutation/invalid bounds. Focused
checks also cover chained color alpha, read-only Material surfaces and text line
height. The artifact benchmark passes; historical timing/SEO claims are unchanged.

A private external-app evaluation now compiles the original populated records
card, original row/style helpers and original palette constant using eight mock
records with absent dates and activity IDs. It accepts 137/137 visited boundaries,
with one state owner, one theme-extension snapshot, zero adapters/island and
19.2 KiB initial files. Browser verification confirms six-to-eight row expansion
and keyboard collapse with the control retained. This supersedes the prior
populated-records blocker, but does not establish whole-app coverage, date support,
activity navigation or live-data behavior. Private inputs and results remain
Git-ignored; CSS and schematic icons remain approximate.

## Calendar dates and paired original components — 2026-10-11

107 tests pass and Dart analysis is clean. Date tests cover snapshot input,
original model getters, nullable patterns, leap-day validation, bounded source
constructors, resolved dart:core identity and rejection of invalid dates, clocks,
time/offset strings and unsupported temporal fields. The artifact benchmark
passes; browser speed/SEO measurements remain unchanged.

The private original-component preview now uses eight dated mock records:
137/137 visited boundaries, zero adapters/island and 19.3 KiB initial files.
A generated Git-ignored Flutter Web harness reads the same configuration and
imports the same original widget/model declarations and palette constant. Both
browser targets show matching dates and six-to-eight row expansion followed by
keyboard collapse. Preview shells and rendering geometry differ; this is content
and interaction validation rather than pixel parity, whole-app coverage or a
performance comparison. Activity IDs/callback behavior remain absent.

## Explicit host navigation and mock feature flow — 2026-10-11

110 tests pass and Dart analysis is clean. New tests cover forwarded callback
fields, resolved function-field invocation, native anchor emission, coexistence
with local state, rejected async/reactive/missing routes and relative-path
validation. Focused checks include parent traversal before fragments. The artifact
benchmark passes; existing browser performance/SEO claims remain unchanged.

A private external-app mock feature flow now serves original overview components,
the original clickable records list and eight detail previews composed from
original stateless components. The records build visits 161/161 widget boundaries,
with zero widget adapters/island, one explicit host route bridge and eight native
links. All 28 generated links resolve within the local output. Browser checks
confirm overview navigation, record click, browser back, expansion and keyboard
activation of a previously hidden record.

The host shell and route map are explicit preview glue. Original async navigation,
provider data loading and the original detail modal are not compiled. This is a
working mock feature flow rather than full-app startup or live-data coverage.
Private application source is unchanged, and configs/output remain Git-ignored.


## Immutable map snapshots

The full compiler suite has **115 passing tests**, and `dart analyze` passes.
New cases cover typed model maps, missing-key fallback, explicit map descriptors,
rejection of callbacks/nonfinite values, nested type mismatches, unused factory
declarations and rejected factory invocation. Resolved tests check imported model
identity inside map values. The required artifact benchmark completes under
ignored `build/map-benchmarks/`; historical browser timing/SEO claims are unchanged.

This permits original static components to read supplied dashboard-shaped models.
It does not compile JSON factory bodies, async repositories, providers or screen
startup. Preview layout remains an explicit host composition around original
components, rather than conversion of the original full screen.


## Indexed collection rows

The compiler now has **120 passing tests**: the full regression run passed with
119, followed by the new reactive-bound/body-mutation test and its focused suite.
`dart analyze` and the required artifact benchmark pass. Raw benchmark artifacts
are ignored under `build/indexed-benchmarks/`; existing browser timing and SEO
claims remain unchanged.

New coverage exercises indexed rows with conditional separators/spreads, prefix
increments, nonzero starts, empty lists and scope restoration. Resolved fixtures
read original model properties through indexed lists. Unsupported loop shapes,
counter-dependent/reactive bounds, mutation and excessive expansion fail closed.
This supports compile-time collection expansion, not live list updates or a
complete activity screen.


## Resolved top-level and bounded block helpers

All **124 tests** pass, `dart analyze` passes, and the required artifact benchmark
completes under ignored `build/helper-benchmarks/`. Tests cover default arguments,
caller-scope isolation, final locals, static branches, grouped constant switch
returns, case-local scope restoration, recursion and unsupported operations.
Resolved fixtures preserve prefixed function identity across duplicate short names;
a local function named Text executes its original body rather than being mistaken
for Flutter's Text constructor. Unsupported statement diagnostics retain their
original source location. Historical timing/SEO claims remain unchanged.

These are bounded compile-time helper evaluations. Numeric method formatting,
model-based navigation callbacks, async repositories and provider startup remain
separate gaps; the full feature-screen compatibility claim is unchanged.


## Numeric formatting, model routes and native list rows

The suite now has **133 tests**, covering Dart numeric rounding/precision, exact
integer-range limits, reactive formatting rejection, immutable model route IDs,
resolved model/SDK identity, semantic list links, read-only rows, avatar SVGs,
separators and rejection of nested interactive controls and unsupported options.
Local helpers named round retain their own bodies; numeric dispatch does not
replace them. Static analysis and required artifact benchmarking are checked;
raw artifacts remain ignored under `build/activities-benchmarks/`.

An original-source list component was compiled with supplied mock models and an
explicit model-ID route bridge. Browser verification checked original formatted
content and keyboard navigation into an existing detail preview. This remains
component composition with host navigation, not full provider startup or an async
detail-sheet conversion. Existing historical speed/SEO claims are unchanged.


## Static reductions and native proportional bars

All **141 tests** pass and `dart analyze` is clean. Added tests cover bounded folds,
empty seeds, captured static values, reducer parameter scope/type coercion,
mutation/async/block rejection, reactive result rejection and resolved SDK/model
identity. Native progress tests verify determinate values, source-provided
accessible labels, clipping, and rejected invalid/indeterminate options.
The required artifact benchmark passes under ignored `build/sport-benchmarks/`;
historical performance/SEO claims remain unchanged.

An original source summary and its original bar widget compile with supplied mock
models and an explicit original palette snapshot. Browser verification showed
three native bars in a narrow layout; generated semantic values match calculated
ratios. No widget adapters or Flutter island are used for this component. The
preview host still composes components around supplied data; provider loading,
async startup, arbitrary chart packages and live chart state remain unsupported.
