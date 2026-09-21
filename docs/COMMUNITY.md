# Community and upstream path

## Positioning

An independent experiment in document-first output from existing Flutter source. Supported UI becomes native HTML; explicit complex regions can remain real Flutter. The purpose is to investigate a useful extra web target, with published limits and reproducible evidence.

This repository is not an official Flutter renderer or a proposal accepted by the Flutter team.

## Evidence of interest

Flutter's [web guidance](https://docs.flutter.dev/platform-integration/web) distinguishes app-centric use cases from document-centric content. Existing community discussions include a [DOM renderer request](https://github.com/flutter/flutter/issues/139292) and a [route-level document rendering proposal](https://github.com/flutter/flutter/issues/187663). These show interest, not a commitment by maintainers to implement or accept this architecture.

Related work includes [Jaspr](https://docs.jaspr.site/), which provides a Dart DOM framework and Flutter embedding, and [FlutterJS](https://github.com/flutterjsdev/flutterjs), which documents a Flutter-to-JavaScript/runtime approach. Reuse or contribute upstream where possible. Do not describe any of these as having been outperformed without a controlled comparison.

## Recommended sequence

1. Maintain an independent CLI with a clear compatibility contract. Do not patch Flutter SDK installations or claim to provide `flutter build dom`.
2. Publish original fixtures, failure cases, a repeatable benchmark and an architecture document. Explain layout and state tradeoffs as carefully as benefits.
3. Validate the approach across unrelated projects and at least two SDK releases. Share only examples that their owners authorize for redistribution.
4. Ask for technical feedback in the relevant existing discussions. A post should request review of specific findings and integration needs; avoid a duplicate feature request or promotional benchmark claims.
5. If maintainers express interest, propose a narrowly defined integration surface before a framework-sized upstream change: supported bootstrap/embedding hooks, tooling contracts or explicit document-route metadata.
6. Use the Flutter [RFC process](https://github.com/flutter/rfc) and [design document guidance](https://github.com/flutter/flutter/blob/master/docs/contributing/Design-Documents.md) for substantial technical designs. The [contribution guide](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md) links these processes.

## Submission readiness gates

- Native links and forms, data flow and imports work on representative examples.
- Public document content does not depend on a Flutter engine download.
- State ownership, island lifecycle and failure behavior are documented and tested.
- Benchmarks disclose initial and post-activation costs, gzip method, renderer and SDK versions.
- Browser timings, when claimed, use repeated cold runs with stated hardware and network settings.
- No universal compatibility, perfect SEO, automatic coverage percentage or guaranteed upstream acceptance claim.

## Draft discussion outline — not submitted

**Title:** Experimental document-first compilation of a Flutter widget subset with explicit Flutter islands

**Problem:** Teams reusing Flutter UI for public web content need native documents, while complex interactions can still benefit from Flutter.

**Experiment:** A standalone Dart CLI emits static HTML/CSS for a documented subset, with selected regions compiled separately by Flutter and loaded on activation. The repository includes paired source fixtures and artifact-size measurements.

**Current limits:** Static data, narrow widget coverage, approximate layout, one island and no general state bridge. Native DOM interaction and multi-file resolution remain substantial work.

**Feedback sought:** Is the route/component boundary useful? Which supported integration hooks would reduce toolchain coupling? Which representative fixtures would best test layout and lifecycle assumptions?

This document is preparation only; no external discussion or submission has been posted.
