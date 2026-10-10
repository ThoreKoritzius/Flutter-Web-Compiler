import 'dart:convert';

/// A typed, serializable expression. Never contains executable application code.
class ReactiveValue {
  ReactiveValue(
    this.type,
    this.code,
    this.dependencies, {
    this.nodeCount = 1,
    this.depth = 1,
  });
  final int nodeCount;
  final int depth;
  final String type;
  final List<Object?> code;
  final Set<String> dependencies;

  static ReactiveValue literal(Object? value) {
    final type = switch (value) {
      bool _ => 'bool',
      int _ => 'int',
      String _ => 'String',
      _ => throw ArgumentError('Reactive values require bool, int or String.'),
    };
    if (value is int) safeInt(value);
    return ReactiveValue(type, ['literal', value], {});
  }

  static ReactiveValue field(String name, Object value) =>
      ReactiveValue(literal(value).type, ['field', name], {name});

  static ReactiveValue of(Object? value) =>
      value is ReactiveValue ? value : literal(value);

  static ReactiveValue operation(String op, List<Object?> values) {
    final args = values.map(of).toList();
    final nodes = 1 + args.fold<int>(0, (n, arg) => n + arg.nodeCount);
    final depth =
        1 + args.fold<int>(0, (n, arg) => n > arg.depth ? n : arg.depth);
    if (nodes > 4096 || depth > 64)
      throw ArgumentError('Reactive expression complexity limit exceeded.');
    final types = args.map((a) => a.type).toList();
    final String type;
    if (op == 'string' && args.length == 1) {
      type = 'String';
    } else if (op == 'choose' &&
        types.length == 3 &&
        types[0] == 'bool' &&
        types[1] == types[2]) {
      type = types[1];
    } else if (op == '!' && types.length == 1 && types[0] == 'bool') {
      type = 'bool';
    } else if (op == 'negate' && types.length == 1 && types[0] == 'int') {
      type = 'int';
    } else if (types.length == 2 && types[0] == types[1]) {
      if (['==', '!='].contains(op)) {
        type = 'bool';
      } else if (['&&', '||'].contains(op) && types[0] == 'bool') {
        type = 'bool';
      } else if (['<', '<=', '>', '>='].contains(op) && types[0] == 'int') {
        type = 'bool';
      } else if (['+', '-', '*'].contains(op) && types[0] == 'int') {
        type = 'int';
      } else if (op == '+' && types[0] == 'String') {
        type = 'String';
      } else {
        throw ArgumentError('Unsupported reactive operator $op for $types.');
      }
    } else {
      throw ArgumentError('Unsupported reactive operator $op for $types.');
    }
    return ReactiveValue(
      type,
      [op, ...args.map((a) => a.code)],
      {for (final a in args) ...a.dependencies},
      nodeCount: nodes,
      depth: depth,
    );
  }

  Object evaluate(Map<String, Object> state) => evaluateCode(code, state);
}

int safeInt(int value) {
  if (value < -9007199254740991 || value > 9007199254740991) {
    throw ArgumentError(
      'Reactive integers must stay within JavaScript safe-integer bounds.',
    );
  }
  return value;
}

int safeProduct(int a, int b) {
  final value = BigInt.from(a) * BigInt.from(b);
  if (value.abs() > BigInt.from(9007199254740991)) {
    throw ArgumentError(
      'Reactive integers must stay within JavaScript safe-integer bounds.',
    );
  }
  return value.toInt();
}

Object evaluateCode(List code, Map<String, Object> state) {
  Object arg(int i) => evaluateCode(code[i] as List, state);
  final op = code[0];
  if (op == 'literal') return code[1] as Object;
  if (op == 'field') return state[code[1]]!;
  if (op == 'choose') return arg(1) == true ? arg(2) : arg(3);
  if (op == '&&') return arg(1) == true && arg(2) == true;
  if (op == '||') return arg(1) == true || arg(2) == true;
  if (op == 'string') return arg(1).toString();
  if (op == '!') return !(arg(1) as bool);
  if (op == 'negate') return safeInt(-(arg(1) as int));
  final a = arg(1), b = arg(2);
  return switch (op) {
    '+' => a is String ? a + (b as String) : safeInt((a as int) + (b as int)),
    '-' => safeInt((a as int) - (b as int)),
    '*' => safeProduct(a as int, b as int),
    '<' => (a as int) < (b as int),
    '<=' => (a as int) <= (b as int),
    '>' => (a as int) > (b as int),
    '>=' => (a as int) >= (b as int),
    '==' => a == b,
    '!=' => a != b,
    _ => throw ArgumentError('Unknown reactive operation $op.'),
  };
}

class ReactiveAction {
  ReactiveAction(this.field, this.value, {ReactiveValue? enabled})
    : enabled = enabled ?? ReactiveValue.literal(true);
  final String field;
  final ReactiveValue value;
  final ReactiveValue enabled;
}

class ReactiveFrame {
  ReactiveFrame(this.initial);
  final Map<String, Object> initial;
  final bindings = <Map<String, Object?>>[];
  final actions = <Map<String, Object?>>[];

  int bind(String kind, ReactiveValue value) {
    final id = bindings.length;
    bindings.add({
      'id': id,
      'kind': kind,
      'expression': value.code,
      'dependencies': value.dependencies.toList(),
    });
    return id;
  }

  int action(ReactiveAction action) {
    final id = actions.length;
    actions.add({
      'field': action.field,
      'expression': action.value.code,
      'enabled': action.enabled.code,
    });
    return id;
  }

  String wrap(String html, int id) {
    final data = const HtmlEscape().convert(
      jsonEncode({'state': initial, 'bindings': bindings, 'actions': actions}),
    );
    return '<section data-dom-state="$id" data-dom-program="$data"><div data-dom-view>$html</div><span data-dom-error role="status" hidden></span></section>';
  }
}

const reactiveRuntime = r'''
const domPrograms = new WeakMap();
function domInteger(value) {
  if (!Number.isSafeInteger(value)) throw new Error('Native integer overflow');
  return value;
}
function domEvaluate(code, state) {
  const op = code[0], a = () => domEvaluate(code[1], state), b = () => domEvaluate(code[2], state);
  switch (op) {
    case 'literal': return code[1];
    case 'field': return state[code[1]];
    case 'choose': return a() ? b() : domEvaluate(code[3], state);
    case '&&': return a() && b();
    case '||': return a() || b();
    case 'string': return String(a());
    case '!': return !a();
    case 'negate': return domInteger(-a());
    case '+': { const left = a(), right = b(); return typeof left === 'string' ? left + right : domInteger(left + right); }
    case '-': return domInteger(a() - b());
    case '*': return domInteger(a() * b());
    case '<': return a() < b();
    case '<=': return a() <= b();
    case '>': return a() > b();
    case '>=': return a() >= b();
    case '==': return a() === b();
    case '!=': return a() !== b();
    default: throw new Error('Unsupported native expression');
  }
}
document.addEventListener('click', (event) => {
  const button = event.target.closest('button[data-dom-action]');
  if (!button || button.disabled) return;
  const owner = button.closest('[data-dom-state]');
  let program = domPrograms.get(owner);
  if (!program) {
    program = JSON.parse(owner.dataset.domProgram);
    program.bindings = program.bindings.map(binding => ({...binding,
      node: owner.querySelector('[data-dom-' + binding.kind + '="' + binding.id + '"]')
    }));
    domPrograms.set(owner, program);
  }
  const status = owner.querySelector('[data-dom-error]');
  try {
    const action = program.actions[Number(button.dataset.domAction)];
    if (!domEvaluate(action.enabled, program.state)) return;
    const next = {...program.state, [action.field]: domEvaluate(action.expression, program.state)};
    // Evaluate before committing: overflow leaves state and the DOM unchanged.
    const updates = program.bindings.filter(binding => binding.dependencies.includes(action.field))
      .map(binding => ({binding, value: domEvaluate(binding.expression, next)}));
    program.state = next;
    for (const {binding, value} of updates) {
      if (binding.kind === 'text') {
        if (binding.node.textContent !== value) {
          if (binding.node.firstChild) binding.node.firstChild.data = value;
          else binding.node.appendChild(document.createTextNode(value));
        }
      } else if (binding.kind === 'enabled') binding.node.disabled = !value;
      else if (binding.kind === 'visible') binding.node.hidden = !value;
    }
    status.hidden = true;
  } catch (error) {
    status.textContent = error.message;
    status.hidden = false;
  }
});
''';
