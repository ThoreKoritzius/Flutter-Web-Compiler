# Native boolean state

This first reactive subset compiles the original widget AST, without a
widget-specific adapter or rewritten Dart fixture. It enumerates two boolean
states at build time, validates both widget trees, and derives text/attribute bindings. The output contains one initial DOM tree
and escaped JSON binding data. A shared JavaScript listener patches only changed
values; it does not replace elements, inject HTML, or restore focus manually.
It is finite-state specialization, **not general Dart-to-JavaScript translation**.

Supported:
- A direct StatefulWidget with no inputs, only an optional unnamed key constructor.
- An expression-body createState returning a zero-argument direct State class.
- Exactly one mutable bool field initialized to true or false.
- A build method using the existing static widget/expression subset.
- TextButton, OutlinedButton and ElevatedButton with a child and onPressed.
- Callbacks shaped like `() => setState(() => expanded = !expanded)`,
  or assignment to a boolean literal. Null onPressed produces a disabled button.
- Multiple sibling instances with isolated state. Browser-native keyboard
  activation; existing buttons and keyboard focus survive updates.

Lifecycle methods, helpers, mixins, providers, widget inputs, nested state,
controllers, arbitrary callbacks and asynchronous work fail explicitly.
Adapters, Flutter islands and MaterialApp context/theme rebuilding inside state
are also rejected.
Static descendants are supported; callbacks declared inside those descendants
cannot capture the parent's state implicitly.

Both analyzed states contribute to boundary counts. Only one tree is emitted;
binding metadata stores values that differ between states. Initial state is
readable without JavaScript; interaction requires the small runtime. Reload
resets state. All three button classes currently share browser button styling.
The two states must have the same element types and child structure. Structural
changes fail with a diagnostic directing users to a fixed tree or an island.
Text (including empty text), styles and disabled/event attributes may change.
Existing elements remain in place; selection inside modified text may still
change. This does not implement Flutter element identity or key reconciliation.

Two variants are intentionally bounded: extending this technique to many
independent fields causes exponential output growth. The next general solution
needs typed state/expression IR and dependency tracking without enumeration;
providers, routing and platform services remain separate work.

Run the example using the command in the main README. Its Flutter and native
targets use `examples/multifile/lib/period_selector.dart`, with synthetic totals.
