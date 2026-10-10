# Native local state

The compiler lowers supported Dart expressions into typed, serializable data.
It builds the widget tree once, emits initial HTML and an expression program,
and updates dependent text/button/visibility bindings with a shared JavaScript interpreter.
It does not enumerate states, enumerate alternate state trees, evaluate source strings,
or use widget-specific adapters. Static pages still need no JavaScript.

## Supported subset

- A direct StatefulWidget with supported final constructor inputs, including static
  primitive lists. `widget.field` reads an immutable input snapshot.
- An expression-body createState returning a zero-argument direct State class.
- 1–16 mutable bool/int fields with explicit, supported pure initializers.
  Lazy `late` initialization from static `widget.field` inputs is supported.
- Initialized final/const build locals and supported stateless descendants,
  including reactive String/int/bool constructor inputs.
- Reactive Text strings: interpolation, string concatenation, same-type primitive
  conditionals, integer `+`, `-`, `*`, comparisons and equality, boolean `!`,
  `&&`, `||`, and unary integer negation.
- TextButton, OutlinedButton and ElevatedButton callbacks shaped like
  `() => setState(() => count++)`, `count--`, `count += 2`, `count -= 1`, or
  `count = expression`. Exactly one assignment per synchronous arrow callback.
- Conditional button enablement: `count > 0 ? callback : null` (or the reverse).
- Static collection for-in with a declared variable; list length/isEmpty/isNotEmpty,
  first/last, take/skip, toList and primitive join. Counts must be static.
- Reactive collection if/else and for-in over a ternary selecting two static lists.
  Both branches compile; hidden DOM groups reveal content in place. Matching
  primitive list prefixes render once. Unsupported hidden content still fails.
- Independent sibling instances, native mouse/keyboard activation, and existing
  elements retained during updates. Disabling a focused button follows browser
  behavior and can remove focus.

Each binding records its field dependencies. An event evaluates its assignment
and affected bindings against a candidate state before committing. Integer
arithmetic stays within ±9,007,199,254,740,991 for Dart/JavaScript agreement.
Overflow cancels the update and shows an accessible error status. Expressions
are bounded to 4,096 expanded nodes and depth 64 to avoid exponential growth
from repeated local expressions. This is a bounded interpreter, not arbitrary
Dart execution or a complete implementation of Dart numeric semantics.

## Explicit gaps

Lifecycle methods, helpers, mixins, providers, nested state, controllers,
arbitrary callbacks, block callbacks and async work
are rejected. Adapters, Flutter islands and MaterialApp context/theme rebuilding
inside state are also rejected. Callbacks declared inside stateless descendants
cannot implicitly capture a parent's state; pass a supported callback instead.

The typed backend binds text, button enablement and retained collection visibility.
Other state-dependent widget structure, layout/styles, string state fields, doubles,
division, mutable/runtime-loaded lists, forms and general navigation remain unsupported.
Constructor inputs cannot change after initialization; didUpdateWidget is unsupported.
Hidden groups retain their DOM and have no mount/dispose semantics. Reports count
all compiled branches and expose `nativeConditionalGroups`, not visible-row coverage. The earlier boolean DOM-diff
backend was removed; conditional styling formerly accepted through enumeration
now fails explicitly until CSS bindings receive typed support. Static styles
continue to work. No Flutter element/key reconciliation or provider bridge is
implemented. Reload resets state; modified text can lose its selection.

## Demo and validation

Use the native-state command in the main README. Both Flutter and DOM targets use
`examples/multifile/lib/period_selector.dart`: a period toggle and session counter
with derived minutes and conditional decrement enablement. The records fixture
adds constructor inputs, static list evaluation and expand/collapse. Both fixtures
run unchanged in Flutter; values are synthetic.

Tests compare Dart and JavaScript expression results, exercise the actual shipped
runtime with DOM test doubles, verify dependency filtering and instance isolation,
and reject unsafe operations. Browser checks cover mouse, keyboard and disabled
button behavior. Node.js is required for the runtime parity tests (CI uses 22).
