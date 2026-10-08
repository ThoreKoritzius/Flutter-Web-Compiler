# Resolved multi-file example

Ordinary Flutter source with a prefixed entry widget, prefixed framework constructors, a barrel export, a package-local import shared constants and a conditional web export. No native adapters or Flutter islands are configured.

From this repository:

```sh
(cd examples/multifile && flutter pub get && flutter analyze)
dart run bin/flutter_dom.dart build --project examples/multifile \
  --resolve-imports --dom-only --output build/multifile
python3 -m http.server 8098 --directory build/multifile
```

The build emits static HTML/CSS. `report.json` identifies resolved analysis and lists the project libraries/parts loaded. Package configuration must exist; the compiler never runs dependency installation or application startup on your behalf.

This is a parser fixture, not a new visual showcase. It uses the same documented static widget subset. The web build selects `platform_web.dart`; the native branch remains ordinary Flutter source. Arbitrary third-party widget packages, custom conditional variables, state and dynamic logic are unsupported.

Run `dart run bin/flutter_dom.dart inspect --project examples/multifile --resolve-imports` to check both parameterless roots and actual constructor calls in the resolved web graph. `Heading` needs a title in isolation, but its real call with `content.title` compiles.

The separate [sample_stat.dart](lib/sample_stat.dart) fixture and [preview configuration](flutter_dom.preview.json) demonstrate local static calculations, positional fields and explicit theme snapshots. See the [preview guide](../../docs/COMPONENT_PREVIEWS.md).
