# Implementation plan

## Product boundary

Compile a documented subset of existing Flutter UI into document-oriented web output. Preserve mobile source; allow sidecar configuration and explicit adapters. Reject unsupported semantics. Keep public document routes independent of Flutter startup.

Start with content/detail pages. Do not promise arbitrary app conversion or pixel equivalence.

## Milestone 0 — feasibility prototype (this repository)

- [x] Dart package, CLI, Git project and documented scope.
- [x] Parse input using Dart analyzer.
- [x] Expand simple local stateless compositions into static HTML.
- [x] Escape HTML and emit metadata and heading structure.
- [x] Explicit Flutter island entry point and lazy loading.
- [x] Real Flutter counter example using unchanged input source.
- [x] Strict rejection and compiler regression tests.
- [x] Browser verification of initial resource requests, lazy activation and counter behavior.

Acceptance: visible document content exists without JavaScript; no Flutter resource downloads before activation; counter increments after activation; static compilation fails clearly on unsupported code. Measure HTML/CSS/JS transfer and total island transfer independently.

## Follow-up prototype — generalized tooling and comparison

- [x] `build` and read-only `inspect` commands, with project-relative defaults.
- [x] Named final constructor fields and static defaults.
- [x] Explicit native filter-list adapter; no arbitrary state transpilation claim.
- [x] Shared-source landing-page showcase with independent native and Flutter targets.
- [x] Repeatable same-source release-build artifact benchmarks, including post-activation cost.
- [x] Compatibility contract, contribution guidance, BSD-3-Clause licensing and CI configuration.
- [x] Community discussion outline and upstream readiness gates; not submitted.

The next milestone must establish resolved imports and general data flow. A growing list of handcrafted adapters alone does not prove automatic application conversion. See [ARCHITECTURE.md](ARCHITECTURE.md) for the path to complex applications.

## Milestone 1 — trustworthy static conversion

1. Resolve symbols across imports with analyzer sessions, rather than recognizing names alone.
2. Introduce a typed IR separating source analysis, layout, semantics and HTML generation.
3. Support constructor arguments, immutable data models, safe constant evaluation and conditional/list builds.
4. Add images with explicit alt text, anchors with explicit destinations, assets and web fonts.
5. Add route manifests, canonical URLs, sitemaps and static data-loader contracts.
6. Replace implicit presentation defaults with an explicit theme/layout policy.

Gate: convert three real public page patterns; verify emitted document structure, links and layouts at multiple widths. Every unsupported feature must have a source-located diagnostic.

## Milestone 2 — native DOM interaction

Evaluate Jaspr as the generated Dart output/runtime layer before implementing a custom reconciler. Prototype a counter, a validated native form and a filtered list using generated code. Use the existing Dart-to-JavaScript compiler for language semantics.

Define supported `setState`, lifecycle and key semantics. Add one state management integration only after that contract is proven. Design hydration with deterministic server/browser data rather than evaluating arbitrary Flutter code on a server.

Gate: real `<input>`, `<button>` and `<a>` behavior, keyboard access and preserved interaction state; no Flutter dependency on DOM-only routes; measured bundle budget.

## Milestone 3 — robust hybrid boundaries

- Use supported custom bootstrap output and CSP-compatible script loading.
- Support multiple islands with one shared engine using Flutter multi-view.
- Define serializable inputs/events, state ownership and disposal rules.
- Add stable sizing, loading/error states, focus handoff and navigation adapters.
- Attribute why an island pulls particular code into the bundle.
- Start with route or explicit component boundaries; do not infer arbitrary cuts.

Gate: two islands communicate through an explicit host contract without duplicated state or lifecycle leaks. Static routes remain engine-free.

## Milestone 4 — production pilot

Choose a narrow application category and 3–5 partner applications. Pin supported Flutter versions, add upgrade fixtures, differential layout/interaction checks and browser accessibility checks. Add incremental builds and useful source maps. Establish performance budgets against standard Flutter Web and a hand-written DOM baseline.

## Highest-risk assumptions

| Risk | Earliest experiment |
| --- | --- |
| Source reuse collapses under constructor/data flow | Convert a real data-driven detail page in milestone 1 |
| CSS changes layout materially | Compare flex/text fixtures at several widths |
| Tiny island forces engine into initial load | Browser network check in milestone 0 |
| State requires Flutter context everywhere | Native form plus one shared-state example in milestone 2 |
| Maintenance exceeds benefit | Run the same fixtures on two Flutter SDK releases |

The initial direct HTML emitter is disposable. The durable work should be compatibility contracts, source analysis, a typed IR and evidence from real applications.
