# Resolved multi-file example

Ordinary Flutter source with a prefixed entry widget, prefixed framework constructors, a barrel export, a package-local import and shared constants. No native adapters or Flutter islands are configured.

From this repository:

```sh
(cd examples/multifile && flutter pub get && flutter analyze)
dart run bin/flutter_dom.dart build --project examples/multifile \
  --resolve-imports --dom-only --output build/multifile
python3 -m http.server 8098 --directory build/multifile
```

The build emits static HTML/CSS. `report.json` identifies resolved analysis and lists the project libraries/parts loaded. Package configuration must exist; the compiler never runs dependency installation or application startup on your behalf.

This is a parser fixture, not a new visual showcase. It uses the same documented static widget subset. Arbitrary third-party widget packages, conditional imports, state and dynamic logic are unsupported.
