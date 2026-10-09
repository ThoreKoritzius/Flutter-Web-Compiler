import 'dart:convert';

import 'package:flutter_dom_compiler/src/state_dom.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  test(
    'patch paths update text, styles, disabled and empty text in either direction',
    () {
      const off =
          '<div style="color:red"><span>Week</span><span></span>'
          '<button disabled>Change</button></div>';
      const on =
          '<div style="color:blue"><span>Month</span><span>Extra</span>'
          '<button data-dom-next="false">Change</button></div>';
      for (final initial in [false, true]) {
        final owner = parseFragment(
          bindBooleanDom(off, on, initial, 0),
        ).children.single;
        final view = owner.children.single;
        final originalButton = view.querySelector('button');
        final bindings =
            jsonDecode(owner.attributes['data-dom-bindings']!) as List;
        for (final state in [1, 0, 1]) {
          for (final binding in bindings) {
            Node node = view;
            for (final index in binding['path'] as List) {
              node = node.nodes[index as int];
            }
            final value = binding['values'][state] as String?;
            switch (binding['kind']) {
              case 'text':
                (node as Text).data = value!;
              case 'content':
                node.text = value!;
              case 'attribute':
                final attributes = (node as Element).attributes;
                if (value == null) {
                  attributes.remove(binding['name']);
                } else {
                  attributes[binding['name'] as String] = value;
                }
            }
          }
          final expected = parseFragment(state == 1 ? on : off);
          // Attribute order does not affect DOM behavior.
          expect(view.text, expected.text);
          expect(
            view.children.single.attributes,
            expected.children.single.attributes,
          );
          expect(
            view.querySelector('button')!.attributes,
            expected.querySelector('button')!.attributes,
          );
          expect(
            identical(originalButton, view.querySelector('button')),
            isTrue,
          );
        }
      }
    },
  );

  test('binding data cannot escape into markup', () {
    const payload = '</section><script>alert("x")</script>&';
    final output = bindBooleanDom(
      '<span>safe</span>',
      '<span>${const HtmlEscape().convert(payload)}</span>',
      false,
      0,
    );
    final document = parseFragment(output);
    expect(document.querySelector('script'), isNull);
    final data =
        jsonDecode(document.children.single.attributes['data-dom-bindings']!)
            as List;
    expect(data.single['values'][1], payload);
    expect(document.querySelector('[data-dom-view]')!.text, 'safe');
  });

  test('structural changes fail explicitly; unchanged DOM has no bindings', () {
    for (final pair in [
      ['<div></div>', '<span></span>'],
      ['<div><span>A</span></div>', '<div><span>A</span><span>B</span></div>'],
    ]) {
      expect(
        () => bindBooleanDom(pair[0], pair[1], false, 0),
        throwsArgumentError,
      );
    }
    final owner = parseFragment(
      bindBooleanDom('<span>A</span>', '<span>A</span>', false, 0),
    ).children.single;
    expect(jsonDecode(owner.attributes['data-dom-bindings']!), isEmpty);
  });
}
