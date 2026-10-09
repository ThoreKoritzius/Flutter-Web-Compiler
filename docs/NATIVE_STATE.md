# Native boolean state

This first reactive subset compiles the original widget AST, without a
widget-specific adapter or rewritten Dart fixture. It enumerates two boolean
states at build time, validates both widget trees, and emits initial HTML plus
inert templates. A shared JavaScript listener switches the local subtree.
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
  activation; focus moves to the corresponding button position after replacement.

Lifecycle methods, helpers, mixins, providers, widget inputs, nested state,
controllers, arbitrary callbacks and asynchronous work fail explicitly.
Adapters and Flutter islands inside state variants are also rejected.
Static descendants are supported; callbacks declared inside those descendants
cannot capture the parent's state implicitly.

Both variants contribute to boundary counts and output size. Initial state is
readable without JavaScript; interaction requires the small runtime. Reload
resets state. All three button classes currently share browser button styling.
Subtree replacement does not preserve text selection, descendant DOM state or
Flutter element identity. Focus restoration assumes a stable button order.

Two variants are intentionally bounded: extending this technique to many
independent fields causes exponential output growth. The next general solution
needs typed state/expression IR, dependency bindings and targeted DOM updates;
providers, routing and platform services remain separate work.

Run the example using the command in the main README. Its Flutter and native
targets use `examples/multifile/lib/period_selector.dart`, with synthetic totals.
