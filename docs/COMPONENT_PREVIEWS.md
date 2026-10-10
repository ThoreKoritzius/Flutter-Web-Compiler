# Preview existing components with explicit static inputs

Compile real widget declarations without running application startup. This is useful for bringing a small read-only part of a larger application into DOM before its state, routing and services are supported.

```sh
dart run bin/flutter_dom.dart build --project examples/multifile \
  --source lib/sample_stat.dart --config flutter_dom.preview.json \
  --resolve-imports --dom-only --output build/component-preview
python3 -m http.server 8111 --bind 127.0.0.1 --directory build/component-preview
```

The fixture is ordinary Flutter source. Its local variables, positional constructor data, arithmetic and theme-based text styles are compiled. Configuration supplies mock values and a static theme snapshot; it does not replace the widget's implementation.

## Configuration

See [the complete example](../examples/multifile/flutter_dom.preview.json). A `preview` list selects 1–60 components. Each entry has a `root`, named `arguments` and/or `positionalArguments`. Arguments accept finite primitive JSON values, lists, and explicit project-local widget descriptors (below). Arbitrary model-object maps and executable callbacks are not accepted. A root may be visible from the entry library, or identified as `lib/path.dart::ClassName` in the resolved library graph, including private declarations for local component evaluation.

The compiler renders those original widget bodies inside a responsive preview grid. The grid is configuration-driven preview UI, not a translation of the application's screen layout. Mock data is labelled visibly. Outside preview mode, `arguments` and `positionalArguments` can supply data to a single configured root. No application startup is executed.

`staticTheme` is an explicit environment snapshot:

- `textTheme` maps requested names to supported TextStyle properties: `fontSize`, `fontWeight` and `color`.
- `colorScheme` maps requested names to six-digit hex colors.
- `Theme.of(context)` reads this snapshot only when it is explicitly configured. Missing slots fail; actual ThemeData, inherited themes, brightness changes and theme extensions are not inferred.
- TextStyle `copyWith` supports those properties and retains prior values for null arguments. Static colors support `withValues(alpha:)` only.

This is a static component preview, not a working whole app. Authentication, routing, provider state, live data and general event callbacks remain unsupported. The bounded native
state subset supports explicit synchronous local actions. Its output size and boundary counts cannot be compared with the full application's build as a like-for-like benchmark.

Keep private preview configuration, build output and reports outside version control. Reusable fixtures in this repository contain only synthetic data.


## Composed previews

Widget-valued slots can refer to another original declaration:

```json
{
  "root": "InfoPanel",
  "positionalArguments": ["Delivery status"],
  "arguments": {
    "description": "This week",
    "child": {
      "widget": "lib/sample_stat.dart::SampleStat",
      "positionalArguments": ["Completed tasks"],
      "arguments": {"value": "24"}
    }
  }
}
```

Descriptors instantiate the referenced declaration through the normal compiler;
they do not inject HTML or replace its build method. Names must resolve to local
classes in the selected import graph. The compiler limits input nesting to 16
levels and input traversal to 2,000 values. A list can supply supported list-valued
constructor inputs. Unsupported objects or widget behavior still fail explicitly.

Run the independent composed fixture:

```sh
dart run bin/flutter_dom.dart build --project examples/multifile \
  --source lib/info_panel.dart --config flutter_dom.composed.json \
  --resolve-imports --dom-only --output build/composed-preview
```

Expression-bodied instance getters on supported stateless components are evaluated with instance fields, without
capturing build-local variables. Cycles and excessive nesting are rejected.
Primitive/null equality and checked null assertions allow optional content slots.
Card and Expanded map to approximate CSS; Card shadows, Material theme resolution
and Flutter constraint/layout parity are not implemented.


Supported StatefulWidget roots can also receive explicit primitive/list inputs.
The state runtime reads an immutable `widget.field` snapshot, not application
startup or provider data. See [records configuration](../examples/multifile/flutter_dom.records.json)
and [the native state contract](NATIVE_STATE.md). Lifecycle and model objects
remain unsupported.
