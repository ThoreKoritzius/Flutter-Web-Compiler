/// Experimental Flutter-shaped API for a deliberately bounded DOM target.
/// This is not the Flutter framework and does not claim layout parity.
library;

import 'dart:async';
import 'dart:js_interop';

@JS('document')
external _Document get _document;
extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _Element createElement(String tag);
}
extension type _Element(JSObject _) implements JSObject {
  external set textContent(String value);
  external void appendChild(_Element child);
  external void replaceChildren();
  external void setAttribute(String key, String value);
  external void addEventListener(String event, JSFunction listener);
}

class Key {
  const Key(this.value);
  final String value;
}

class BuildContext {
  const BuildContext();
}

abstract class Widget {
  const Widget({this.key});
  final Key? key;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState();
}

abstract class State<T extends StatefulWidget> {
  late T widget;
  bool _mounted = false;
  bool get mounted => _mounted;
  final context = const BuildContext();
  void Function()? _invalidate;
  void initState() {}
  void dispose() {}
  Widget build(BuildContext context);
  void setState(void Function() update) {
    if (!mounted) throw StateError('setState after disposal.');
    update();
    _invalidate!();
  }
}

class Text extends Widget {
  const Text(this.data, {super.key});
  final String data;
}

enum CrossAxisAlignment { start, center, end, stretch }

class Column extends Widget {
  const Column({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    super.key,
  });
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
}

class Row extends Widget {
  const Row({required this.children, super.key});
  final List<Widget> children;
}

class SizedBox extends Widget {
  const SizedBox({this.height, this.width, this.child, super.key});
  final double? height;
  final double? width;
  final Widget? child;
}

class ElevatedButton extends Widget {
  const ElevatedButton({
    required this.onPressed,
    required this.child,
    super.key,
  });
  final void Function()? onPressed;
  final Widget child;
}

class MaterialApp extends Widget {
  const MaterialApp({required this.home, super.key});
  final Widget home;
}

class Scaffold extends Widget {
  const Scaffold({required this.body, super.key});
  final Widget body;
}

/// Root-only state lifecycle. Descendant StatefulWidgets fail explicitly.
/// Each update replaces the view; retained focus/child reconciliation is pending.
class DomMount {
  DomMount._(this._host);
  final _Element _host;
  State? _state;
  Widget? _root;
  bool _disposed = false;
  bool _scheduled = false;
  int _renderGeneration = 0;

  void _schedule() {
    if (_disposed || _scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (!_disposed) _render();
    });
  }

  void _render() {
    final generation = ++_renderGeneration;
    final node = _node(
      _state?.build(const BuildContext()) ?? _root!,
      generation,
    );
    _host.replaceChildren();
    _host.appendChild(node);
  }

  _Element _node(Widget widget, int generation) {
    if (widget.key != null)
      throw UnsupportedError(
        'Widget keys are not supported by the root-only runtime.',
      );
    if (widget is StatelessWidget)
      return _node(widget.build(const BuildContext()), generation);
    if (widget is StatefulWidget)
      throw UnsupportedError('Only a root StatefulWidget is supported.');
    if (widget is MaterialApp) return _node(widget.home, generation);
    if (widget is Scaffold) return _node(widget.body, generation);
    final node = _document.createElement(
      widget is ElevatedButton
          ? 'button'
          : widget is Text
          ? 'p'
          : 'div',
    );
    if (widget is Text) {
      node.textContent = widget.data;
    } else if (widget is Column) {
      final alignment = switch (widget.crossAxisAlignment) {
        CrossAxisAlignment.start => 'flex-start',
        CrossAxisAlignment.end => 'flex-end',
        CrossAxisAlignment.center => 'center',
        CrossAxisAlignment.stretch => 'stretch',
      };
      node.setAttribute(
        'style',
        'display:flex;flex-direction:column;align-items:$alignment;gap:8px',
      );
      for (final child in widget.children) {
        node.appendChild(_node(child, generation));
      }
    } else if (widget is Row) {
      node.setAttribute(
        'style',
        'display:flex;flex-wrap:wrap;gap:12px;align-items:center',
      );
      for (final child in widget.children) {
        node.appendChild(_node(child, generation));
      }
    } else if (widget is SizedBox) {
      for (final size in [widget.height, widget.width]) {
        if (size != null && (!size.isFinite || size < 0))
          throw ArgumentError('Invalid size.');
      }
      node.setAttribute(
        'style',
        '${widget.height == null ? '' : 'height:${widget.height}px;'}${widget.width == null ? '' : 'width:${widget.width}px;'}',
      );
      if (widget.child != null)
        node.appendChild(_node(widget.child!, generation));
    } else if (widget is ElevatedButton) {
      node.setAttribute('type', 'button');
      node.appendChild(_node(widget.child, generation));
      if (widget.onPressed == null) {
        node.setAttribute('disabled', '');
      } else {
        node.addEventListener(
          'click',
          (() {
            if (!_disposed && generation == _renderGeneration)
              widget.onPressed!();
          }).toJS,
        );
      }
    } else {
      throw UnsupportedError('Unsupported DOM widget: ${widget.runtimeType}');
    }
    return node;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _renderGeneration++;
    final state = _state;
    if (state != null) {
      state._mounted = false;
      state._invalidate = null;
      state.dispose();
    }
    _host.replaceChildren();
  }
}

DomMount? _activeMount;

void runApp(Widget root) {
  if (root.key != null) throw UnsupportedError('Root keys are not supported.');
  final host = _document.querySelector('#app');
  if (host == null) throw StateError('Missing #app DOM host.');
  _activeMount?.dispose();
  final mount = DomMount._(host);
  _activeMount = mount;
  // Allow standard application wrappers around the stateful entry.
  while (root is MaterialApp || root is Scaffold) {
    if (root.key != null)
      throw UnsupportedError('Wrapper keys are not supported.');
    root = root is MaterialApp ? root.home : (root as Scaffold).body;
  }
  if (root.key != null) throw UnsupportedError('Root keys are not supported.');
  if (root is StatefulWidget) {
    final state = root.createState();
    mount._state = state;
    state.widget = root;
    state._mounted = true;
    state._invalidate = mount._schedule;
    state.initState();
  } else {
    mount._root = root;
  }
  mount._render();
}
