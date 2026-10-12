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

See [the complete example](../examples/multifile/flutter_dom.preview.json). A `preview` list selects 1–60 components. Each entry has a `root`, named `arguments` and/or `positionalArguments`. Arguments accept finite primitive JSON values, lists, and explicit project-local widget/model descriptors (below). Untyped object maps and executable callbacks are not accepted. A root may be visible from the entry library, or identified as `lib/path.dart::ClassName` in the resolved library graph, including private declarations for local component evaluation.

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
and [the native state contract](NATIVE_STATE.md). Lifecycle and arbitrary model behavior remain unsupported.


## Typed static models

Inputs can instantiate an original project-local data declaration:

```json
{
  "model": "RecordEntry",
  "positionalArguments": ["Design review"],
  "arguments": {"minutes": 30}
}
```

This evaluates the original constructor through the same bounded binder used by
Dart constructor expressions. Models must be plain classes with explicitly typed
final fields, one unnamed field-formal constructor and optional synchronous
expression getters/helpers. Primitive values, lists and nested supported models are
accepted; annotated local model identity is checked, including list elements.
Getters use instance scope and cannot capture enclosing widget/build locals.
Construction and getter recursion are bounded. Reports include
`staticModelInstances`, which counts evaluated instances rather than DOM boundaries.

Inheritance, mixins, generic model classes, arbitrary methods, constructor bodies/initializer
lists, factories, mutable fields, generated serializers, general temporal behavior and external
model classes remain unsupported. Unused static serializers may remain declared. Invoked static methods must satisfy the bounded expression-helper subset. Unsupported nullable types may have null snapshot values; this does not add non-null type support.
No application startup or serialization code is executed. Models are compile-time snapshots, not mutable client-side state.
The [records fixture](../examples/multifile/lib/record_list.dart) uses an imported
model in both Flutter and DOM, with explicit synthetic values in configuration.


## Pure instance helpers

Supported widget/model instance methods with synchronous expression bodies can
be called during compilation. Helpers accept simple positional/named parameters
and static defaults. Arguments evaluate in caller scope; the body sees instance
fields and its parameters, without capturing build locals. Primitive/list/model
parameter annotations use the input validator; this is not a complete Dart type
checker. Supported model receivers preserve resolved method identity. Helper
results can be primitive values, model snapshots or supported widget constructors.

State helpers can derive typed reactive text from bool/int values and return
static widget constructions. Their bodies cannot create event callbacks or perform
state mutation. Called helpers reject async bodies, unsupported statements, generic methods,
recursion, assignments and unsupported calls. Depth is bounded to 64 and uses the
shared static operation budget. Top-level/static helpers and bounded blocks now work as described below. Higher-order functions,
closures and general statement/control-flow lowering remain unsupported.
`pureHelperInvocations` reports compiler evaluations, not browser event calls.
The records fixture uses its original `_recordRow` and `formatDuration` helpers.


## Static visual inputs and early-return builds

Visual constructor inputs accept explicit `{"color":"#ef747c"}` and
`{"icon":"favorite"}` descriptors. Icon names must belong to the small
[schematic SVG subset](COMPATIBILITY.md#static-build-branches-and-visual-primitives).
These configure inputs, not substitute widget implementations. Build blocks
can select static if/else returns; unselected branches are not rendered or
classified. Mutable state conditions still require supported reactive collection
bindings. This permits read-only component slices with optional interaction absent,
without implying that their tapped/navigation branch compiles.


Required callback inputs may be supplied as explicit opaque references, for
example `{"callback":"openItem"}`, when the selected read-only branch does not
call them. Invoked callbacks fail; no handler is silently replaced. The report
counts supplied references separately. This permits inspection of an original
component's empty/read-only state, not a claim that its interactions compile.


Theme-extension previews can select an original constant using
`staticTheme.extensions` (see COMPATIBILITY.md). The original palette constructor,
enum maps and supported expression index operators are interpreted; the snapshot
is an explicit preview input and does not run the application theme setup.


Use `{"date":"2026-09-21"}` for calendar-only DateTime inputs. Original nullable
patterns and year/month/day access work; clocks, timezones, durations and other
DateTime operations remain unsupported. See COMPATIBILITY.md for the exact subset.


## Immutable map inputs

Use an explicit `{"map":{"days":6,"complete":true}}` descriptor for model map
fields. Descriptor keys are strings; values recursively use the same bounded
primitive/list/map/local-model input contract. Reserved descriptor names inside
this map remain ordinary keys. `Map<String, dynamic>` permits heterogeneous static
data, not executable objects or callbacks. Typed map values and nested list/model
annotations are checked, preserving resolved imported model identity.

Original immutable models may declare unused named factories alongside their
simple unnamed constructor. Factories are never executed or translated; calling
them still fails. The unnamed snapshot constructor retains the existing
final-field, parameter, type and evaluation limits. Native map mutation, factories,
serializers and network loading are not implemented by this feature.


## Pure top-level and block helpers

Project-local top-level functions now retain resolved library identity, including
prefixed imports and duplicate short names. Function arguments/defaults are bound
in an isolated scope; helpers cannot capture a caller's locals or instance fields.
Unused functions are not executed. Async/generic functions, higher-order arguments
and external package function bodies remain unsupported.

Top-level, widget and static helpers can use initialized final/const locals,
static if/else, nested blocks and expression returns. Static switch statements
accept primitive selectors with unguarded constant cases, grouped empty labels
and a default. A selected nonempty case must return. Switch case locals do not
leak into the surrounding block. Pattern/guard cases, break/continue, mutation,
statement loops and side effects fail closed. Expression-only model getter/helper
constraints remain unchanged. Evaluation uses the shared operation budget and
64-level depth/recursion guard; this is compile-time interpretation, not general
Dart-to-JavaScript logic translation.


## Model arguments in explicit route bridges

An original callback such as `() => onOpen(entry)` can use a declared model ID:

```json
{"callback":"openEntry","argument":{"model":"lib/entry.dart::Entry","field":"id"},"routes":{"one":"entries/one/"}}
```

The selector must reference a plain local immutable model and a nonnullable final
String field. The argument must have that exact resolved model identity. Missing
IDs/routes, nullable fields and unrelated models fail; getters and arbitrary
selector logic are unsupported. This remains an explicit host route adapter;
the application's callback body, repository fetch and router are not translated.
`nativeCallbackRouteBridges` reports it separately from widget adapters.
