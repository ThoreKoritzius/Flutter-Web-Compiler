# Changelog

## Unreleased

- Replace boolean-state HTML templates with targeted text/attribute patches that preserve existing elements and keyboard focus. Reject structural state changes explicitly.

- Add a bounded native boolean StatefulWidget subset, HTML buttons and a shared event runtime.
- Add a shared Flutter period-selector fixture; report state instances and variant counts explicitly.

- Compile initialized static locals, numeric arithmetic and positional field constructors.
- Add explicit theme snapshots, supported text-style/color operations and basic decoration.
- Add configuration-driven previews of original components with primitive mock inputs.

- Separate missing constructor inputs from unsupported root behavior in resolved inspection.
- Evaluate actual resolved constructor call sites, with explicit context requirements and bounded, reported work.
- Replace the resolved CLI headline percentage with root and call-site outcome counts.

- Resolve standard conditional imports/exports against a fixed web target; report selected branches.
- Add resolved compatibility inspection with an explicitly scoped denominator.
- Pin analyzer 7.7.1 and isolate its environment-configuration API.

- Add opt-in `build --resolve-imports` with analyzer-backed local imports, exports, prefixes, parts and constants.
- Preserve declaration identity and file locations across project libraries; add a multi-file Flutter fixture and CI build.

- Evaluate same-file top-level constants with isolated scope, cycle detection and resource limits.
- Compile static collection `if`/`else`, list spreads and null-aware spreads.
- Reject unsupported collection patterns and runtime data explicitly.

- Add explicit `build` and `inspect` CLI commands, defaulting to the current project.
- Add local project syntax inventories with JSON/Markdown output and explicit confidence limits.
- Compile named final constructor fields and literal defaults in simple stateless widgets.
- Add an explicit native filter-list adapter and browser document scrolling.
- Add a shared-source landing-page showcase with native/Flutter target toggle.
- Add reproducible paired Flutter Web / DOM artifact-size benchmarks.
- Prepare OSS licensing, contribution guidance, CI and a community proposal roadmap.

## 0.1.0

- Initial static Flutter widget compiler, metadata and heading configuration.
- Single explicit, lazy-loaded Flutter island.
- Strict DOM-only mode, example app and compiler/CLI tests.
