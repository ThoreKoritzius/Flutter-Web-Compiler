# From prototype to a useful compiler

The practical product is an additional web build target for document-oriented parts of Flutter applications, with explicit native contracts and Flutter fallback. Universal unchanged-app conversion is a much larger research project.

## Largest engineering gaps

1. **Resolved, multi-file Dart analysis.** Today constructor recognition is syntactic and local to one source file. Resolve imports, symbols, generic types and reachable widget definitions before expanding the supported subset. Keep source locations and actionable diagnostics in an intermediate representation.
2. **Layout semantics.** Flutter constraints, intrinsic sizing, scrolling, slivers, text measurement and CSS layout are different models. Publish supported mappings and test them across viewport sizes. Exact pixel fidelity would undermine much of the advantage of using the browser's layout engine.
3. **State and lifecycle.** `setState`, element identity/keys, inherited context, providers, controllers, disposal, effects and asynchronous rebuilding need a coherent DOM runtime. Implement a small stateful vertical slice, then provider integrations. Do not translate arbitrary callbacks by substituting strings.
4. **Application boundaries.** Routing, URLs, hydration, API calls, authentication, plugin initialization and state crossing between DOM and Flutter islands need explicit contracts. Server-rendered data must agree with client state without exposing server-only values.
5. **Packages and platform behavior.** A Dart package may compile to JavaScript and still require Flutter rendering or platform channels. Maintain tested support by capability, SDK version and package integration; fail visibly outside it.

## Should we compile Dart logic to JavaScript ourselves?

Prefer Dart's existing JavaScript compiler for supported business logic. Translating syntax is not the primary missing piece: Flutter framework behavior assumes a widget/element/render pipeline. The research question is how to bind a supported subset to DOM updates while preserving lifecycle and behavior, and how to tree-shake away rendering-engine dependencies. The current native filter adapter is handwritten and does not demonstrate general state compilation.

## Feasible milestones

- Resolved cross-file static pages, dependency graph and richer diagnostics.
- A small native reactive runtime: local scalar state, events, conditional content and keyed lists, with interaction parity tests against Flutter.
- Router and data-loading contracts, native forms and accessibility semantics.
- Tested state/package adapters and robust island initialization/state boundaries.
- A versioned CLI and reproducible external app evaluations before proposing deeper upstream integration.

A standalone CLI is the least coupled starting point. An IDE extension can surface the same reports later. Community feedback and an experimental RFC become useful once the compatibility contract and reproducible benchmarks demonstrate a stable benefit. Upstream adoption is uncertain; no submission has been made.


## Immediate coverage priorities after images and tables

1. Resolve imported widget definitions and symbols, preserving per-file diagnostics. This is the most useful next step for ordinary project structure.
2. Extend the implemented same-file constants, collection `if` and spreads to collection `for`, then `Wrap` and constrained responsive layout.
3. Add native links and a small controlled form/event contract with interaction parity tests.
4. Implement one local-state slice before attempting broad Provider/Riverpod compatibility.

Image assets and static tables are implemented. Styling remains an approximate CSS mapping, not a translation of arbitrary Material themes.


## Parser architecture and release gates

Same-file static constants and list branches/spreads now share the compiler's bounded evaluator. The next architectural milestone is **resolved symbols**, before adding more name-based special cases:

1. Use analyzer project contexts and package configuration to resolve the entry library and reachable declarations. Preserve library identity rather than merging source files or matching imported classes by short name. Test prefixes, exports, duplicate names, cycles and unavailable packages.
2. Separate source analysis, static evaluation and rendering using a typed intermediate representation with source spans. Keep explicit adapters distinguishable from automatically lowered widgets in reports.
3. Add a capability diagnostic for every unsupported reachable operation. Keep existing fail-closed behavior; do not silently replace unknown widgets with placeholders or count adapters as translated internals.
4. Compare representative supported fixtures against Flutter for content, geometry and interactions; distinguish semantic equivalence from approximate CSS layout. Version the supported subset alongside SDK fixtures.

Before an initial public experimental release: complete a repository/license/assets review, keep private fixture reports excluded, verify clean-checkout CI and CLI installation, publish reproducible examples and known limitations, and review the package API/version. Publication and repository visibility changes require a separate decision; this work keeps both disabled.
