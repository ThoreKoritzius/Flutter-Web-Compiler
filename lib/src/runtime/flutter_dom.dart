/// Experimental Flutter-shaped API for a deliberately bounded DOM target.
/// This is not the Flutter framework and does not claim layout parity.
library;

export 'foundation_dom.dart';
export 'services_dom.dart';
export 'visual_metadata.dart';
export 'material_icons_metadata.dart';
export 'material_style.dart';

import 'material_style.dart';
import 'visual_metadata.dart';

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
  external double get clientWidth;
}

@JS('window')
external _Window get _window;
extension type _Window(JSObject _) implements JSObject {
  external double get innerWidth;
  external double get innerHeight;
  external void addEventListener(String event, JSFunction listener);
  external void removeEventListener(String event, JSFunction listener);
}

class Size {
  const Size(this.width, this.height);
  final double width, height;
}

class MediaQuery {
  static Size sizeOf(BuildContext context) =>
      Size(_window.innerWidth, _window.innerHeight);
}

/// Horizontal DOM layout only; vertical constraints remain unbounded.
class BoxConstraints {
  const BoxConstraints({required this.maxWidth});
  final double maxWidth;
  double get minWidth => 0;
  double get minHeight => 0;
  double get maxHeight => double.infinity;
}

class LayoutBuilder extends Widget {
  const LayoutBuilder({required this.builder, super.key});
  final Widget Function(BuildContext, BoxConstraints) builder;
}

class Wrap extends Widget {
  const Wrap({
    required this.children,
    this.spacing = 0,
    this.runSpacing = 0,
    super.key,
  });
  final List<Widget> children;
  final double spacing, runSpacing;
}

class Theme extends Widget {
  const Theme({required this.data, required this.child, super.key});
  final ThemeData data;
  final Widget child;
  static ThemeData of(BuildContext context) => context.theme;
}

class Key {
  const Key(this.value);
  final String value;
}

class BuildContext {
  const BuildContext({this.theme = const ThemeData(), this.foreground});
  final Color? foreground;
  final ThemeData theme;
}

/// Extension point for one root scope around the bounded stateful entry.
abstract class DomRootScope extends Widget {
  const DomRootScope({super.key});
  Widget get child;
  void Function() openDomScope(State state);
}

abstract interface class DomBuildLifecycle {
  void beginDomBuild();
  void endDomBuild();
  void disposeDomBuild();
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
  BuildContext _context = const BuildContext();
  BuildContext get context => _context;
  void Function()? _invalidate;
  void initState() {}
  void dispose() {}
  void didUpdateWidget(covariant T oldWidget) {}
  Widget build(BuildContext context);
  void setState(void Function() update) {
    if (!mounted) throw StateError('setState after disposal.');
    update();
    _invalidate!();
  }
}

class Text extends Widget {
  const Text(this.data, {this.style, super.key});
  final String data;
  final TextStyle? style;
}

class Padding extends Widget {
  const Padding({required this.padding, required this.child, super.key});
  final EdgeInsets padding;
  final Widget child;
}

class Expanded extends Widget {
  const Expanded({required this.child, this.flex = 1, super.key});
  final Widget child;
  final int flex;
}

class Card extends Widget {
  const Card({required this.child, this.shape, this.color, super.key});
  final Widget child;
  final RoundedRectangleBorder? shape;
  final Color? color;
}

/// Metadata compiles, but icon painting remains unsupported.
class Icon extends Widget {
  const Icon(this.icon, {this.size, this.color, super.key});
  final IconData? icon;
  final double? size;
  final Color? color;
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
  const Row({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    super.key,
  });
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
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
  const MaterialApp({required this.home, this.theme, super.key});
  final Widget home;
  final ThemeData? theme;
}

class Scaffold extends Widget {
  const Scaffold({required this.body, super.key});
  final Widget body;
}

class _StateSlot {
  _StateSlot(this.state, this.ancestry);
  final State state;
  final List<Type> ancestry;
  bool matches(List<Type> other) =>
      ancestry.length == other.length &&
      List.generate(
        ancestry.length,
        (i) => ancestry[i] == other[i],
      ).every((v) => v);
}

/// Unkeyed state persists by structural position and ancestor widget types.
/// Each update replaces DOM nodes; focus and DOM reconciliation remain pending.
class DomMount {
  DomMount._(this._host);
  final _Element _host;
  State? _state;
  void Function()? _disposeScope;
  Widget? _root;
  BuildContext _context = const BuildContext();
  bool _disposed = false;
  bool _scheduled = false;
  int _renderGeneration = 0;
  final _layoutJobs = <void Function()>[];
  JSFunction? _resizeListener;
  final _childStates = <String, _StateSlot>{};
  final _usedSlots = <String>{};

  void _disposeState(State state) {
    state._mounted = false;
    state._invalidate = null;
    try {
      state.dispose();
    } finally {
      if (state is DomBuildLifecycle)
        (state as DomBuildLifecycle).disposeDomBuild();
    }
  }

  Widget _buildState(State state) {
    final lifecycle = state is DomBuildLifecycle
        ? state as DomBuildLifecycle
        : null;
    lifecycle?.beginDomBuild();
    try {
      return state.build(state.context);
    } finally {
      lifecycle?.endDomBuild();
    }
  }

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
    _layoutJobs.clear();
    _usedSlots.clear();
    try {
      final state = _state;
      final built = state == null ? _root! : _buildState(state);
      final node = _node(built, generation, _context);
      _host.replaceChildren();
      _host.setAttribute(
        'style',
        'background:${colorCss(_context.theme.colorScheme.surface)};color:${colorCss(_context.theme.colorScheme.onSurface)};min-height:100vh;',
      );
      _host.appendChild(node);
      // Measure attached DOM boxes, rather than estimating Flutter constraints.
      for (var index = 0; index < _layoutJobs.length; index++) {
        if (index >= 500)
          throw StateError('Native layout builder limit exceeded.');
        _layoutJobs[index]();
      }
      if (_layoutJobs.isNotEmpty && _resizeListener == null) {
        _resizeListener = (() => _schedule()).toJS;
        _window.addEventListener('resize', _resizeListener!);
      }
      for (final slot in _childStates.keys.toList().reversed) {
        if (!_usedSlots.contains(slot))
          _disposeState(_childStates.remove(slot)!.state);
      }
    } catch (_) {
      dispose();
      rethrow;
    }
  }

  _Element _node(
    Widget widget,
    int generation,
    BuildContext context, {
    bool flexChild = false,
    String slot = 'view',
    List<Type> ancestry = const [],
  }) {
    final lineage = [...ancestry, widget.runtimeType];
    var childIndex = 0;
    _Element child(
      Widget value, {
      BuildContext? scope,
      bool flexChild = false,
    }) => _node(
      value,
      generation,
      scope ?? context,
      flexChild: flexChild,
      slot: '$slot/${childIndex++}',
      ancestry: lineage,
    );
    if (widget.key != null)
      throw UnsupportedError(
        'Widget keys are not supported by the structural-state runtime.',
      );
    if (widget is StatelessWidget)
      return child(widget.build(context), flexChild: flexChild);
    if (widget is StatefulWidget) {
      var entry = _childStates[slot];
      if (entry != null && !entry.matches(lineage)) {
        for (final oldSlot in _childStates.keys.toList().reversed) {
          if (oldSlot == slot || oldSlot.startsWith('$slot/')) {
            _disposeState(_childStates.remove(oldSlot)!.state);
          }
        }
        entry = null;
      }
      _usedSlots.add(slot);
      if (entry == null) {
        final state = widget.createState();
        // Provider scopes currently attach only their root consumer.
        if (state is DomBuildLifecycle)
          throw UnsupportedError(
            'Nested consumer lifecycle requires descendant provider scope support.',
          );
        state.widget = widget;
        state._context = context;
        state._mounted = true;
        state._invalidate = _schedule;
        entry = _StateSlot(state, lineage);
        _childStates[slot] = entry;
        state.initState();
      } else {
        final old = entry.state.widget;
        entry.state.widget = widget;
        entry.state._context = context;
        if (!identical(old, widget)) entry.state.didUpdateWidget(old);
      }
      return child(_buildState(entry.state), flexChild: flexChild);
    }
    if (widget is Theme)
      return child(
        widget.child,
        scope: BuildContext(theme: widget.data),
        flexChild: flexChild,
      );
    if (widget is MaterialApp)
      return child(
        widget.home,
        scope: BuildContext(theme: widget.theme ?? context.theme),
      );
    if (widget is Scaffold) return child(widget.body);
    final node = _document.createElement(
      widget is ElevatedButton
          ? 'button'
          : widget is Text
          ? 'p'
          : 'div',
    );
    if (widget is Text) {
      node.textContent = widget.data;
      node.setAttribute(
        'style',
        'margin:0;color:${colorCss(context.foreground ?? context.theme.colorScheme.onSurface)};${textStyleCss(context.theme.textTheme.bodyMedium)}${textStyleCss(widget.style)}',
      );
    } else if (widget is LayoutBuilder) {
      node.setAttribute(
        'style',
        'width:100%;min-width:0;box-sizing:border-box;',
      );
      _layoutJobs.add(() {
        final width = checkedDimension(node.clientWidth);
        node.appendChild(
          child(widget.builder(context, BoxConstraints(maxWidth: width))),
        );
      });
    } else if (widget is Wrap) {
      node.setAttribute(
        'style',
        'display:flex;flex-wrap:wrap;align-items:flex-start;column-gap:${checkedDimension(widget.spacing)}px;row-gap:${checkedDimension(widget.runSpacing)}px;',
      );
      for (final item in widget.children) node.appendChild(child(item));
    } else if (widget is Padding) {
      final p = widget.padding;
      node.setAttribute(
        'style',
        'box-sizing:border-box;padding:${checkedDimension(p.top)}px ${checkedDimension(p.right)}px ${checkedDimension(p.bottom)}px ${checkedDimension(p.left)}px;',
      );
      node.appendChild(child(widget.child));
    } else if (widget is Expanded) {
      if (!flexChild)
        throw UnsupportedError('Expanded requires a Row or Column parent.');
      if (widget.flex < 1)
        throw ArgumentError('Expanded flex must be positive.');
      node.setAttribute(
        'style',
        'flex:${widget.flex} 1 0;min-width:0;min-height:0;',
      );
      node.appendChild(child(widget.child));
    } else if (widget is Card) {
      final shape = widget.shape;
      node.setAttribute(
        'style',
        'box-sizing:border-box;min-width:0;background:${colorCss(widget.color ?? context.theme.colorScheme.surfaceContainerLow)};border-radius:${checkedDimension(shape?.borderRadius.radius ?? 12)}px;border:${checkedDimension(shape?.side.width ?? 0)}px solid ${colorCss(shape?.side.color ?? context.theme.colorScheme.outlineVariant)};',
      );
      node.appendChild(child(widget.child));
    } else if (widget is Column) {
      final alignment = switch (widget.crossAxisAlignment) {
        CrossAxisAlignment.start => 'flex-start',
        CrossAxisAlignment.end => 'flex-end',
        CrossAxisAlignment.center => 'center',
        CrossAxisAlignment.stretch => 'stretch',
      };
      node.setAttribute(
        'style',
        'display:flex;flex-direction:column;align-items:$alignment',
      );
      for (final item in widget.children) {
        node.appendChild(child(item, flexChild: true));
      }
    } else if (widget is Row) {
      node.setAttribute(
        'style',
        'display:flex;flex-direction:row;align-items:${switch (widget.crossAxisAlignment) {
          CrossAxisAlignment.start => 'flex-start',
          CrossAxisAlignment.end => 'flex-end',
          CrossAxisAlignment.center => 'center',
          CrossAxisAlignment.stretch => 'stretch',
        }}',
      );
      for (final item in widget.children) {
        node.appendChild(child(item, flexChild: true));
      }
    } else if (widget is SizedBox) {
      for (final size in [widget.height, widget.width]) {
        if (size != null && (!size.isFinite || size < 0))
          throw ArgumentError('Invalid size.');
      }
      node.setAttribute(
        'style',
        'flex-shrink:0;${widget.height == null ? '' : 'height:${widget.height}px;'}${widget.width == null ? '' : 'width:${widget.width}px;'}',
      );
      if (widget.child != null) node.appendChild(child(widget.child!));
    } else if (widget is ElevatedButton) {
      node.setAttribute('type', 'button');
      node.setAttribute(
        'style',
        'background:${colorCss(context.theme.colorScheme.primary)};border:0;border-radius:10px;padding:10px 16px;',
      );
      node.appendChild(
        child(
          widget.child,
          scope: BuildContext(
            theme: context.theme,
            foreground: context.theme.colorScheme.onPrimary,
          ),
        ),
      );
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
    if (_resizeListener != null)
      _window.removeEventListener('resize', _resizeListener!);
    _layoutJobs.clear();
    _renderGeneration++;
    Object? failure;
    StackTrace? failureStack;
    void cleanup(void Function() action) {
      try {
        action();
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }

    for (final entry in _childStates.values.toList().reversed) {
      cleanup(() => _disposeState(entry.state));
    }
    _childStates.clear();
    if (_state != null) cleanup(() => _disposeState(_state!));
    cleanup(() => _disposeScope?.call());
    cleanup(() => _host.replaceChildren());
    if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
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
  DomRootScope? scope;
  // Allow standard application wrappers and one explicit root scope.
  while (root is MaterialApp ||
      root is Scaffold ||
      root is DomRootScope ||
      root is Theme) {
    if (root.key != null)
      throw UnsupportedError('Wrapper keys are not supported.');
    if (root is DomRootScope) {
      if (scope != null)
        throw UnsupportedError('Nested root scopes are unsupported.');
      scope = root;
      root = root.child;
    } else {
      if (root is Theme) {
        mount._context = BuildContext(theme: root.data);
        root = root.child;
        continue;
      }
      if (root is MaterialApp) {
        mount._context = BuildContext(
          theme: root.theme ?? mount._context.theme,
        );
      }
      root = root is MaterialApp ? root.home : (root as Scaffold).body;
    }
  }
  if (root.key != null) throw UnsupportedError('Root keys are not supported.');
  if (root is StatefulWidget) {
    final state = root.createState();
    mount._state = state;
    state.widget = root;
    state._context = mount._context;
    state._mounted = true;
    state._invalidate = mount._schedule;
    try {
      mount._disposeScope = scope?.openDomScope(state);
      state.initState();
      mount._render();
    } catch (_) {
      mount.dispose();
      rethrow;
    }
  } else {
    if (scope != null)
      throw UnsupportedError('Root scopes require a stateful entry.');
    mount._root = root;
    mount._render();
  }
}
