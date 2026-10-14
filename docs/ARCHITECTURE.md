# Architecture and scaling strategy

## Implemented prototype

The package exposes a Dart CLI with `build` and `inspect` commands. Default builds parse a single source file. With `--resolve-imports`, analyzer resolves selected project libraries under a fixed web target; conditional imports, prefixes and declaration identity are retained. Both paths evaluate a restricted static subset and emit escaped HTML. Resolved inspection reuses that library graph for independent widget-root checks. Named final constructor fields are bound separately for each stateless instance. Configuration supplies document metadata, heading levels and one explicit Flutter island.

The island is compiled separately using Flutter. The initial document loads a small host script; only activation loads the island bootstrap, engine, application and fonts. Island state remains inside Flutter. A separate opt-in filter-list adapter supports native local search with its own isolated state; there is no shared-state runtime.

Inspection is a separate read-only syntax inventory plus a static-HTML acceptance score. With `--dart-runtime`, `src/runtime_inspection.dart` also walks the entry's import graph using read-only copies of the runtime builder's facade and bridge tables, and can optionally run the real build. It is not semantic analysis or an automatic renderer partitioner.

## Why a standalone CLI first

One CLI can run locally, in CI and behind an editor extension. It avoids maintaining a Flutter SDK fork and makes version compatibility explicit. The initial distribution is path activation; a versioned pub.dev release should follow only after package-readiness and compatibility checks. An editor extension should invoke this CLI, not contain an independent compiler.

Do not market an official `flutter build dom` command. Upstream tooling integration can be discussed later; it is not required for a useful independent tool.

## Target pipeline — not yet implemented

```text
Resolved Dart libraries and symbols
             |
Supported Flutter semantics + explicit adapters
             |
Typed UI/data-flow intermediate representation
             |
    +--------+---------+
    |                  |
DOM target         Flutter entry points
    |                  |
SSG/SSR + JS       lazy engine/views
    +--------+---------+
      route/host contracts
```

Prefer generating Dart for a maintained DOM framework such as Jaspr and using Dart's compiler for language semantics. Evaluate that against a custom runtime on native form and list fixtures before committing. The current HTML emitter is a disposable proof, not the final architecture.

## Path to complex applications

1. **Imports and data:** Resolve source libraries, bind immutable constructor/model data, produce source-located diagnostics and a typed IR. Do not statically execute arbitrary app initialization.
2. **Browser primitives:** Implement real links, images and forms, controlled/uncontrolled values, validation, selection and focus. Establish keyboard and input-method behavior.
3. **State:** Define supported `setState`, lifecycle and key behavior. Add one state-management adapter; do not assume a Flutter widget framework integration can be reused unchanged by a DOM runtime.
4. **Routing and data loading:** Explicit route manifests, public data loaders and document metadata. Keep request/auth state isolated and private routes private. Client-side data screens are a separate target from SEO documents.
5. **Fallback boundaries:** Begin at routes or self-contained components. Inputs/events must be explicit. Never duplicate an application's provider graph in two renderers without a defined state owner.
6. **Multi-view:** Multiple islands should share one Flutter engine where appropriate. Define disposal, sizing, overlays, focus and navigation before automatic cuts.
7. **Compatibility:** Pin supported SDK versions, maintain reference fixtures and make adapters independently testable. Unsupported behavior should remain a diagnostic, not silent fallback inflation.

## What “mostly DOM” must mean

Count user-visible routes and interactions with correct native behavior, not constructor occurrences. Track initial engine independence, code/download size, renderer-boundary count, visual differences and manual adapter effort. A source file containing many `Text` calls may still depend entirely on state, theme and rendering behavior that the compiler cannot reproduce.

## Scalability

Static output scales through normal CDN delivery; the compiler need not run per visitor. Dynamic server rendering has conventional data/cache scaling concerns. The hard scaling problem is compatibility and maintenance across APIs, packages and SDK releases. A narrow, useful contract is more sustainable than promising arbitrary transparent Flutter conversion.
