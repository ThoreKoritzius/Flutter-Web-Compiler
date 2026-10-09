import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart';

/// Derives bounded patches from two validated builds, never from application JS.
String bindBooleanDom(String off, String on, bool initial, int id) {
  final roots = [parseFragment(off), parseFragment(on)];
  final bindings = <Map<String, Object?>>[];

  Never incompatible() => throw ArgumentError(
    'Native boolean state requires stable DOM structure. '
    'Keep the widget structure fixed and vary text/styles, or use a Flutter island.',
  );

  void compare(Node a, Node b, List<int> path) {
    if (a is Text && b is Text) {
      if (a.data != b.data) {
        bindings.add({
          'path': path,
          'kind': 'text',
          'values': [a.data, b.data],
        });
      }
      return;
    }
    if (a is Element && b is Element) {
      if (a.localName != b.localName || a.namespaceUri != b.namespaceUri) {
        incompatible();
      }
      for (final name in {...a.attributes.keys, ...b.attributes.keys}) {
        if (name is! String) incompatible();
        if (a.attributes[name] != b.attributes[name]) {
          bindings.add({
            'path': path,
            'kind': 'attribute',
            'name': name,
            'values': [a.attributes[name], b.attributes[name]],
          });
        }
      }
      // Empty Text widgets have no parsed text node. Keep their element stable.
      if ((a.nodes.isEmpty || b.nodes.isEmpty) &&
          a.nodes.every((n) => n is Text) &&
          b.nodes.every((n) => n is Text)) {
        if (a.text != b.text) {
          bindings.add({
            'path': path,
            'kind': 'content',
            'values': [a.text, b.text],
          });
        }
        return;
      }
    } else if (a is! DocumentFragment || b is! DocumentFragment) {
      incompatible();
    }
    if (a.nodes.length != b.nodes.length) incompatible();
    for (var i = 0; i < a.nodes.length; i++) {
      compare(a.nodes[i], b.nodes[i], [...path, i]);
    }
  }

  compare(roots[0], roots[1], []);
  final encoded = const HtmlEscape().convert(jsonEncode(bindings));
  return '<section data-dom-state="$id" data-dom-bindings="$encoded">'
      '<div data-dom-view>${roots[initial ? 1 : 0].outerHtml}</div></section>';
}

const reactiveRuntime = r'''
const domBindings = new WeakMap();
document.addEventListener('click', (event) => {
  const button = event.target.closest('button[data-dom-next]');
  if (!button) return;
  const owner = button.closest('[data-dom-state]');
  let bindings = domBindings.get(owner);
  if (!bindings) {
    const view = owner.querySelector('[data-dom-view]');
    bindings = JSON.parse(owner.dataset.domBindings).map(binding => ({
      ...binding,
      node: binding.path.reduce((node, index) => node.childNodes[index], view)
    }));
    domBindings.set(owner, bindings);
  }
  const state = button.dataset.domNext === 'true' ? 1 : 0;
  for (const binding of bindings) {
    const value = binding.values[state];
    if (binding.kind === 'text') {
      if (binding.node.data !== value) binding.node.data = value;
    } else if (binding.kind === 'content') {
      if (binding.node.textContent !== value) binding.node.textContent = value;
    } else if (value === null) {
      binding.node.removeAttribute(binding.name);
    } else if (binding.node.getAttribute(binding.name) !== value) {
      binding.node.setAttribute(binding.name, value);
    }
  }
});
''';
