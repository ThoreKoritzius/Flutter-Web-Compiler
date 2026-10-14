part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// DOM interop. Only these operations are used, so the DOM contract tests can
// supply a small, explicit stand-in.

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Node? querySelector(String selector);
  external _Node createElement(String tag);
}

extension type _Node(JSObject _) implements JSObject {
  external set textContent(String value);
  external void appendChild(_Node child);
  external void insertBefore(_Node child, _Node? reference);
  external void removeChild(_Node child);
  external void replaceChildren();
  external void setAttribute(String key, String value);
  external void removeAttribute(String key);
  external void addEventListener(String event, JSFunction listener);
  external double get clientWidth;
  external void focus();
  external void blur();
}

extension type _Event(JSObject _) implements JSObject {
  external String? get key;
  external void preventDefault();
  external double? get offsetX;
  external double? get offsetY;
  external double? get clientX;
  external double? get clientY;
  external int? get button;
  external int? get pointerId;
  external String? get pointerType;
  external double? get timeStamp;
  external JSObject? get currentTarget;
}

@JS('window')
external _Window get _window;

extension type _Window(JSObject _) implements JSObject {
  external double get innerWidth;
  external double get innerHeight;
  external void addEventListener(String event, JSFunction listener);
  external void removeEventListener(String event, JSFunction listener);
}

// ---------------------------------------------------------------------------
// Keys.

abstract class Key {
  const factory Key(String value) = ValueKey<String>;
  const Key.empty();
}

abstract class LocalKey extends Key {
  const LocalKey() : super.empty();
}

class ValueKey<T> extends LocalKey {
  const ValueKey(this.value);
  final T value;
  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ValueKey<T> &&
      other.value == value;
  @override
  int get hashCode => Object.hash(runtimeType, value);
  @override
  String toString() => '[<$value>]';
}

class ObjectKey extends LocalKey {
  const ObjectKey(this.value);
  final Object? value;
  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ObjectKey &&
      identical(other.value, value);
  @override
  int get hashCode => Object.hash(runtimeType, identityHashCode(value));
}

class UniqueKey extends LocalKey {
  // ignore: prefer_const_constructors_in_immutables
  UniqueKey();
}

final _globalKeys = <GlobalKey, Element>{};

/// Global keys give access to the current element, widget and state. Moving
/// a keyed subtree to a different parent recreates it; reparenting is not
/// supported by this runtime.
abstract class GlobalKey<T extends State<StatefulWidget>> extends Key {
  factory GlobalKey({String? debugLabel}) => LabeledGlobalKey<T>(debugLabel);
  const GlobalKey.constructor() : super.empty();
  Element? get _currentElement => _globalKeys[this];
  BuildContext? get currentContext => _currentElement;
  Widget? get currentWidget => _currentElement?._widget;
  T? get currentState {
    final element = _currentElement;
    if (element is StatefulElement) {
      final state = element.state;
      if (state is T) return state;
    }
    return null;
  }
}

class LabeledGlobalKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  // ignore: prefer_const_constructors_in_immutables
  LabeledGlobalKey(this.debugLabel) : super.constructor();
  final String? debugLabel;
}

class GlobalObjectKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  const GlobalObjectKey(this.value) : super.constructor();
  final Object value;
  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is GlobalObjectKey<T> &&
      identical(other.value, value);
  @override
  int get hashCode => identityHashCode(value);
}

// ---------------------------------------------------------------------------
// Widgets.

abstract class Widget {
  const Widget({this.key});
  final Key? key;
  Element createElement();
  static bool canUpdate(Widget oldWidget, Widget newWidget) =>
      oldWidget.runtimeType == newWidget.runtimeType &&
      oldWidget.key == newWidget.key;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context);
  @override
  StatelessElement createElement() => StatelessElement(this);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState();
  @override
  StatefulElement createElement() => StatefulElement(this);
}

/// Optional build hooks for integrations such as provider consumers.
abstract interface class DomBuildLifecycle {
  void beginDomBuild();
  void endDomBuild();
  void disposeDomBuild();
}

abstract class State<T extends StatefulWidget> {
  T? _widget;
  T get widget => _widget!;
  StatefulElement? _element;
  BuildContext get context {
    final element = _element;
    if (element == null)
      throw StateError('This widget has been unmounted; context is gone.');
    return element;
  }

  bool get mounted => _element != null;
  void initState() {}
  void didUpdateWidget(covariant T oldWidget) {}
  void didChangeDependencies() {}
  void reassemble() {}
  void deactivate() {}
  void activate() {}
  void dispose() {}
  Widget build(BuildContext context);
  void setState(VoidCallback fn) {
    final element = _element;
    if (element == null) throw StateError('setState after disposal.');
    final Object? result = (fn as dynamic)();
    if (result is Future)
      throw StateError('setState callbacks must be synchronous.');
    element.markNeedsBuild();
  }
}

abstract class ProxyWidget extends Widget {
  const ProxyWidget({super.key, required this.child});
  final Widget child;
}

abstract class InheritedWidget extends ProxyWidget {
  const InheritedWidget({super.key, required super.child});
  @override
  InheritedElement createElement() => InheritedElement(this);
  bool updateShouldNotify(covariant InheritedWidget oldWidget);
}

/// Rebuilds dependents whenever [notifier] notifies.
abstract class InheritedNotifier<T extends Listenable> extends InheritedWidget {
  const InheritedNotifier({super.key, this.notifier, required super.child});
  final T? notifier;
  @override
  bool updateShouldNotify(InheritedNotifier<T> oldWidget) =>
      oldWidget.notifier != notifier;
  @override
  InheritedElement createElement() => _InheritedNotifierElement<T>(this);
}

// ---------------------------------------------------------------------------
// Build context and elements.

abstract class BuildContext {
  Widget get widget;
  bool get mounted;
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  });
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>();
  InheritedElement?
  getElementForInheritedWidgetOfExactType<T extends InheritedWidget>();
  T? findAncestorWidgetOfExactType<T extends Widget>();
  T? findAncestorStateOfType<T extends State<StatefulWidget>>();
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>();
  void visitAncestorElements(bool Function(Element element) visitor);
  void visitChildElements(void Function(Element element) visitor);
}

abstract class Element implements BuildContext {
  Element(Widget widget) : _widget = widget;
  Widget? _widget;
  @override
  Widget get widget => _widget!;
  Element? _parent;
  _DomOwner? _owner;
  int _depth = 0;
  bool _active = false;
  bool _dirty = true;
  Map<Type, InheritedElement> _inherited = const {};
  Set<InheritedElement>? _dependencies;

  @override
  bool get mounted => _widget != null && _active;

  void mount(Element? parent) {
    _parent = parent;
    if (parent != null) {
      _owner = parent._owner;
      _depth = parent._depth + 1;
      _inherited = parent._inherited;
    }
    _active = true;
    _owner!._live.add(this);
    _updateInheritance();
    final key = widget.key;
    if (key is GlobalKey) _globalKeys[key] = this;
  }

  void _updateInheritance() {}

  void update(covariant Widget newWidget) {
    _widget = newWidget;
  }

  /// Called once, after the element's descendants have been unmounted.
  void unmount() {
    if (!_active) return;
    _active = false;
    _owner?._live.remove(this);
    final key = _widget?.key;
    if (key is GlobalKey && identical(_globalKeys[key], this))
      _globalKeys.remove(key);
    for (final dependency in _dependencies ?? const <InheritedElement>{}) {
      dependency._dependents.remove(this);
    }
    _dependencies = null;
    _widget = null;
  }

  void visitChildren(void Function(Element child) visitor) {}

  @override
  void visitChildElements(void Function(Element element) visitor) =>
      visitChildren(visitor);

  /// The DOM node this element contributes to its nearest DOM ancestor.
  _Node get _domNode;

  bool get _fillsWidth => false;

  void markNeedsBuild() {
    if (!_active || _dirty) return;
    _dirty = true;
    _owner!._scheduleBuild(this);
  }

  void rebuild() {
    if (!_active || !_dirty) return;
    performRebuild();
  }

  void performRebuild();

  void didChangeDependencies() => markNeedsBuild();

  _DomParent? get _domAncestor {
    var node = _parent;
    while (node != null) {
      if (node is _DomParent) return node;
      node = node._parent;
    }
    return null;
  }

  Element? updateChild(Element? child, Widget? newWidget) {
    if (newWidget == null) {
      if (child != null) _owner!._unmountTree(child);
      return null;
    }
    if (child != null) {
      if (identical(child._widget, newWidget)) return child;
      if (Widget.canUpdate(child.widget, newWidget)) {
        child.update(newWidget);
        return child;
      }
      _owner!._unmountTree(child);
    }
    return inflateWidget(newWidget);
  }

  Element inflateWidget(Widget newWidget) {
    final element = newWidget.createElement();
    element.mount(this);
    return element;
  }

  /// Keyed reconciliation following Flutter's documented algorithm: match
  /// the top and bottom of the lists in order, then match keyed children in
  /// the middle by key. Unkeyed middle children are not matched.
  List<Element> updateChildren(
    List<Element> oldChildren,
    List<Widget> newWidgets,
  ) {
    final owner = _owner!;
    var newTop = 0, oldTop = 0;
    var newBottom = newWidgets.length - 1;
    var oldBottom = oldChildren.length - 1;
    final result = List<Element?>.filled(newWidgets.length, null);
    while (oldTop <= oldBottom && newTop <= newBottom) {
      final old = oldChildren[oldTop];
      final next = newWidgets[newTop];
      if (!Widget.canUpdate(old.widget, next)) break;
      result[newTop++] = updateChild(old, next);
      oldTop++;
    }
    while (oldTop <= oldBottom && newTop <= newBottom) {
      if (!Widget.canUpdate(
        oldChildren[oldBottom].widget,
        newWidgets[newBottom],
      ))
        break;
      oldBottom--;
      newBottom--;
    }
    final haveOld = oldTop <= oldBottom;
    final oldKeyed = <Key, Element>{};
    if (haveOld) {
      for (; oldTop <= oldBottom; oldTop++) {
        final old = oldChildren[oldTop];
        final key = old.widget.key;
        if (key != null) {
          oldKeyed[key] = old;
        } else {
          owner._unmountTree(old);
        }
      }
    }
    for (; newTop <= newBottom; newTop++) {
      final next = newWidgets[newTop];
      Element? old;
      final key = next.key;
      if (haveOld && key != null) {
        old = oldKeyed[key];
        if (old != null) {
          if (Widget.canUpdate(old.widget, next)) {
            oldKeyed.remove(key);
          } else {
            old = null;
          }
        }
      }
      result[newTop] = updateChild(old, next);
    }
    newBottom = newWidgets.length - 1;
    oldBottom = oldChildren.length - 1;
    for (; oldTop <= oldBottom && newTop <= newBottom; oldTop++, newTop++) {
      result[newTop] = updateChild(oldChildren[oldTop], newWidgets[newTop]);
    }
    for (final old in oldKeyed.values) {
      owner._unmountTree(old);
    }
    return result.cast<Element>();
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) {
    final ancestor = _inherited[T];
    if (ancestor == null) return null;
    (_dependencies ??= HashSet.identity()).add(ancestor);
    ancestor._dependents.add(this);
    return ancestor.widget as T;
  }

  @override
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() =>
      _inherited[T]?.widget as T?;

  @override
  InheritedElement?
  getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() =>
      _inherited[T];

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    for (var node = _parent; node != null; node = node._parent) {
      if (node._widget.runtimeType == T) return node._widget as T;
    }
    return null;
  }

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() {
    for (var node = _parent; node != null; node = node._parent) {
      if (node is StatefulElement && node.state is T) return node.state as T;
    }
    return null;
  }

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() {
    T? found;
    for (var node = _parent; node != null; node = node._parent) {
      if (node is StatefulElement && node.state is T) found = node.state as T;
    }
    return found;
  }

  @override
  void visitAncestorElements(bool Function(Element element) visitor) {
    for (var node = _parent; node != null; node = node._parent) {
      if (!visitor(node)) return;
    }
  }
}

abstract class ComponentElement extends Element {
  ComponentElement(super.widget);
  Element? _child;

  @override
  _Node get _domNode => _child!._domNode;
  @override
  bool get _fillsWidth => _child?._fillsWidth ?? false;

  @override
  void mount(Element? parent) {
    super.mount(parent);
    _firstBuild();
  }

  void _firstBuild() => rebuild();

  Widget build();

  @override
  void performRebuild() {
    _dirty = false;
    final built = build();
    final previous = _child;
    final oldNode = previous == null ? null : previous._domNode;
    final oldFill = previous?._fillsWidth;
    _child = updateChild(previous, built);
    if (oldNode != null && !identical(oldNode, _child!._domNode)) {
      _domAncestor?._childNodesChanged();
    } else if (oldFill != null && oldFill != _child!._fillsWidth) {
      _domAncestor?._childFillChanged();
    }
  }

  @override
  void visitChildren(void Function(Element child) visitor) {
    final child = _child;
    if (child != null) visitor(child);
  }
}

class StatelessElement extends ComponentElement {
  StatelessElement(StatelessWidget super.widget);
  @override
  Widget build() => (widget as StatelessWidget).build(this);
  @override
  void update(StatelessWidget newWidget) {
    super.update(newWidget);
    _dirty = true;
    rebuild();
  }
}

class StatefulElement extends ComponentElement {
  StatefulElement(StatefulWidget widget)
    : state = widget.createState(),
      super(widget) {
    state._element = this;
    state._widget = widget;
  }
  final State<StatefulWidget> state;
  bool _dependenciesChanged = false;

  @override
  void _firstBuild() {
    state.initState();
    state.didChangeDependencies();
    super._firstBuild();
  }

  @override
  Widget build() {
    final lifecycle = state is DomBuildLifecycle
        ? state as DomBuildLifecycle
        : null;
    lifecycle?.beginDomBuild();
    try {
      return state.build(this);
    } finally {
      lifecycle?.endDomBuild();
    }
  }

  @override
  void performRebuild() {
    if (_dependenciesChanged) {
      _dependenciesChanged = false;
      state.didChangeDependencies();
    }
    super.performRebuild();
  }

  @override
  void update(StatefulWidget newWidget) {
    super.update(newWidget);
    final old = state._widget!;
    state._widget = newWidget;
    state.didUpdateWidget(old);
    _dirty = true;
    rebuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dependenciesChanged = true;
  }

  @override
  void unmount() {
    if (!_active) return;
    try {
      state.deactivate();
      state.dispose();
    } finally {
      if (state is DomBuildLifecycle)
        (state as DomBuildLifecycle).disposeDomBuild();
      super.unmount();
      state._element = null;
    }
  }
}

class InheritedElement extends ComponentElement {
  InheritedElement(InheritedWidget super.widget);
  final _dependents = HashSet<Element>.identity();

  @override
  void _updateInheritance() {
    _inherited = {..._inherited, widget.runtimeType: this};
  }

  @override
  Widget build() => (widget as ProxyWidget).child;

  void notifyClients() {
    for (final dependent in _dependents.toList()) {
      if (dependent._active) dependent.didChangeDependencies();
    }
  }

  @override
  void update(InheritedWidget newWidget) {
    final old = widget as InheritedWidget;
    super.update(newWidget);
    if (newWidget.updateShouldNotify(old)) notifyClients();
    _dirty = true;
    rebuild();
  }

  @override
  void unmount() {
    _dependents.clear();
    super.unmount();
  }
}

class _InheritedNotifierElement<T extends Listenable> extends InheritedElement {
  _InheritedNotifierElement(InheritedNotifier<T> super.widget);
  bool _notified = false;
  T? _listening;

  void _changed() {
    if (!_active) return;
    _notified = true;
    markNeedsBuild();
  }

  void _listen() {
    final notifier = (widget as InheritedNotifier<T>).notifier;
    if (identical(notifier, _listening)) return;
    _listening?.removeListener(_changed);
    _listening = notifier;
    notifier?.addListener(_changed);
  }

  @override
  void mount(Element? parent) {
    super.mount(parent);
    _listen();
  }

  @override
  void update(InheritedNotifier<T> newWidget) {
    super.update(newWidget);
    _listen();
  }

  @override
  void performRebuild() {
    if (_notified) {
      _notified = false;
      notifyClients();
    }
    super.performRebuild();
  }

  @override
  void unmount() {
    _listening?.removeListener(_changed);
    _listening = null;
    super.unmount();
  }
}

// ---------------------------------------------------------------------------
// DOM-producing elements.

mixin _DomParent on Element {
  bool _updatingChildren = false;
  final _placed = <_Node>[];
  _Node get _containerNode;
  Iterable<Element> get _domChildren;

  void _childNodesChanged() {
    if (!_updatingChildren && _active) _syncDom();
  }

  void _childFillChanged() {}

  /// Moves, inserts and removes only the child nodes that changed position.
  void _syncDom() {
    final desired = [for (final child in _domChildren) child._domNode];
    var same = desired.length == _placed.length;
    for (var i = 0; same && i < desired.length; i++) {
      same = identical(desired[i], _placed[i]);
    }
    if (same) return;
    final container = _containerNode;
    final keep = HashSet<_Node>.identity()..addAll(desired);
    for (final node in _placed) {
      if (!keep.contains(node)) container.removeChild(node);
    }
    _placed.removeWhere((node) => !keep.contains(node));
    for (var i = 0; i < desired.length; i++) {
      final node = desired[i];
      if (i < _placed.length && identical(_placed[i], node)) continue;
      container.insertBefore(node, i < _placed.length ? _placed[i] : null);
      final previous = _placed.indexWhere((n) => identical(n, node));
      if (previous >= 0) _placed.removeAt(previous);
      _placed.insert(i, node);
    }
  }
}

typedef _DomHandler = void Function(_Event? event);

/// Accumulates one DOM element's declarative description during a build.
class _DomBuilder {
  _DomBuilder(this.context);
  final _DomElement context;
  final attributes = <String, String>{};
  final style = StringBuffer();
  final handlers = <String, _DomHandler>{};

  /// Live DOM properties (such as `value` or `checked`). Each is compared
  /// with the current DOM value and written only when it differs, so user
  /// edits, caret position and selection are not disturbed.
  final properties = <String, Object?>{};
  String? text;
  List<Widget> children = const [];

  void css(String declarations) => style.write(declarations);
  void on(String event, _DomHandler handler) => handlers[event] = handler;
  void child(Widget widget) => children = [widget];
}

/// How a DOM container lays out its children.
enum _DomLayout { block, row, column, wrap, align, grid, stack }

/// Whether a widget expands to the available width, as Flutter boxes do
/// under bounded constraints. Wrappers expand when any child expands.
enum _Fill { none, child, expand }

/// A widget that renders exactly one DOM element owned by its element.
abstract class _DomWidget extends Widget {
  const _DomWidget({super.key});
  String get _tag => 'div';
  _DomLayout get _layout => _DomLayout.block;
  _Fill get _fill => _Fill.child;
  void _render(_DomBuilder out);
  @override
  Element createElement() => _DomElement(this);
}

class _DomElement extends Element with _DomParent {
  _DomElement(_DomWidget super.widget);
  late final _Node node = _document.createElement((widget as _DomWidget)._tag);
  List<Element> _children = const [];
  Map<String, String> _attributes = const {};
  String _renderedStyle = '';
  String? _appliedStyle;
  bool _fills = false;
  String? _text;
  Map<String, _DomHandler> _handlers = const {};
  final _listening = <String>{};

  @override
  _Node get _domNode => node;
  @override
  _Node get _containerNode => node;
  @override
  Iterable<Element> get _domChildren => _children;
  @override
  bool get _fillsWidth => _fills;

  /// The DOM layout of the nearest DOM ancestor, for flex/stretch decisions.
  _DomLayout get parentLayout {
    final parent = _domAncestor;
    return parent is _DomElement
        ? (parent.widget as _DomWidget)._layout
        : _DomLayout.block;
  }

  Widget? get parentDomWidget {
    final parent = _domAncestor;
    return parent is _DomElement ? parent.widget : null;
  }

  @override
  void mount(Element? parent) {
    super.mount(parent);
    rebuild();
  }

  @override
  void update(_DomWidget newWidget) {
    super.update(newWidget);
    _dirty = true;
    rebuild();
  }

  @override
  void performRebuild() {
    _dirty = false;
    final out = _DomBuilder(this);
    (widget as _DomWidget)._render(out);
    for (final key in _attributes.keys) {
      if (!out.attributes.containsKey(key)) node.removeAttribute(key);
    }
    for (final entry in out.attributes.entries) {
      if (_attributes[entry.key] != entry.value)
        node.setAttribute(entry.key, entry.value);
    }
    _attributes = out.attributes;
    _renderedStyle = out.style.toString();
    for (final type in out.handlers.keys) {
      if (_listening.add(type)) {
        node.addEventListener(
          type,
          ((JSObject? event) => _dispatch(type, event)).toJS,
        );
      }
    }
    _handlers = out.handlers;
    for (final entry in out.properties.entries) {
      _setLiveProperty(entry.key, entry.value);
    }
    final text = out.text;
    if (text != null) {
      // Text content replaces any child nodes, so remove children first.
      if (_children.isNotEmpty) _updateChildWidgets(const []);
      if (text != _text) node.textContent = text;
      _text = text;
    } else {
      if (_text != null) node.textContent = '';
      _text = null;
      _updateChildWidgets(out.children);
    }
    _recomputeFill(notify: true);
    _applyStyle();
  }

  String _fillCss() {
    if (!_fills) return '';
    return switch (parentLayout) {
      _DomLayout.column => 'align-self:stretch;',
      _DomLayout.align || _DomLayout.wrap || _DomLayout.stack => 'width:100%;',
      _ => '',
    };
  }

  void _applyStyle() {
    final style = _renderedStyle + _fillCss();
    if (style == _appliedStyle) return;
    if (style.isEmpty) {
      node.removeAttribute('style');
    } else {
      node.setAttribute('style', style);
    }
    _appliedStyle = style;
  }

  void _recomputeFill({required bool notify}) {
    final fills = switch ((widget as _DomWidget)._fill) {
      _Fill.none => false,
      _Fill.expand => true,
      _Fill.child => _children.any((child) => child._fillsWidth),
    };
    if (fills == _fills) return;
    _fills = fills;
    _applyStyle();
    if (notify) _domAncestor?._childFillChanged();
  }

  @override
  void _childFillChanged() {
    if (_updatingChildren || !_active) return;
    _recomputeFill(notify: true);
  }

  @override
  void _childNodesChanged() {
    super._childNodesChanged();
    _childFillChanged();
  }

  Object? _liveProperty(String name) =>
      (node as JSObject).getProperty<JSAny?>(name.toJS).dartify();

  void _setLiveProperty(String name, Object? value) {
    if (_liveProperty(name) == value) return;
    (node as JSObject).setProperty(name.toJS, value.jsify());
  }

  void _dispatch(String type, JSObject? event) {
    // Removed elements keep their listeners but can no longer reach state.
    if (!_active || _owner!._disposed) return;
    _handlers[type]?.call(event == null ? null : _Event(event));
  }

  void _updateChildWidgets(List<Widget> widgets) {
    _updatingChildren = true;
    try {
      _children = updateChildren(_children, widgets);
    } finally {
      _updatingChildren = false;
    }
    _syncDom();
  }

  @override
  void visitChildren(void Function(Element child) visitor) {
    for (final child in _children) {
      visitor(child);
    }
  }
}

// ---------------------------------------------------------------------------
// Root, media and owner.

enum Orientation { portrait, landscape }

class TextScaler {
  const TextScaler.linear(this.textScaleFactor);
  static const noScaling = TextScaler.linear(1);
  final double textScaleFactor;
  double scale(double fontSize) => fontSize * textScaleFactor;
}

/// Browser viewport metrics. Padding and insets are zero in documents.
class MediaQueryData {
  const MediaQueryData({
    this.size = Size.zero,
    this.devicePixelRatio = 1,
    this.textScaler = TextScaler.noScaling,
    this.platformBrightness = Brightness.light,
    this.padding = EdgeInsets.zero,
    this.viewPadding = EdgeInsets.zero,
    this.viewInsets = EdgeInsets.zero,
  });
  final Size size;
  final double devicePixelRatio;
  final TextScaler textScaler;
  final Brightness platformBrightness;
  final EdgeInsets padding, viewPadding, viewInsets;
  Orientation get orientation =>
      size.width > size.height ? Orientation.landscape : Orientation.portrait;
  MediaQueryData copyWith({Size? size, Brightness? platformBrightness}) =>
      MediaQueryData(
        size: size ?? this.size,
        devicePixelRatio: devicePixelRatio,
        textScaler: textScaler,
        platformBrightness: platformBrightness ?? this.platformBrightness,
        padding: padding,
        viewPadding: viewPadding,
        viewInsets: viewInsets,
      );
}

class MediaQuery extends InheritedWidget {
  const MediaQuery({super.key, required this.data, required super.child});
  final MediaQueryData data;
  static MediaQueryData of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No MediaQuery ancestor in this context.'));
  static MediaQueryData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MediaQuery>()?.data;
  static Size sizeOf(BuildContext context) => of(context).size;
  static Size? maybeSizeOf(BuildContext context) => maybeOf(context)?.size;
  static EdgeInsets paddingOf(BuildContext context) => of(context).padding;
  static EdgeInsets viewInsetsOf(BuildContext context) =>
      of(context).viewInsets;
  static Orientation orientationOf(BuildContext context) =>
      of(context).orientation;
  static TextScaler textScalerOf(BuildContext context) =>
      of(context).textScaler;
  static Brightness platformBrightnessOf(BuildContext context) =>
      of(context).platformBrightness;
  @override
  bool updateShouldNotify(MediaQuery oldWidget) =>
      oldWidget.data.size != data.size ||
      oldWidget.data.platformBrightness != data.platformBrightness;
}

Brightness _platformBrightness() {
  final window = _window as JSObject;
  if (!window.has('matchMedia')) return Brightness.light;
  final query = window.callMethod<JSObject?>(
    'matchMedia'.toJS,
    '(prefers-color-scheme: dark)'.toJS,
  );
  final matches = query?.getProperty<JSBoolean?>('matches'.toJS);
  return matches?.toDart == true ? Brightness.dark : Brightness.light;
}

MediaQueryData _viewportData() => MediaQueryData(
  size: Size(_window.innerWidth, _window.innerHeight),
  platformBrightness: _platformBrightness(),
);

class _RootWidget extends Widget {
  const _RootWidget();
  @override
  Element createElement() => throw UnsupportedError('Internal root widget.');
}

class _RootElement extends Element with _DomParent {
  _RootElement(this._app, _DomOwner owner) : super(const _RootWidget()) {
    _owner = owner;
  }
  final Widget _app;
  Element? _child;
  MediaQueryData _media = _viewportData();

  @override
  _Node get _domNode => _owner!.host;
  @override
  _Node get _containerNode => _owner!.host;
  @override
  Iterable<Element> get _domChildren => [?_child];

  void _resize() {
    final next = _viewportData();
    if (next.size == _media.size &&
        next.platformBrightness == _media.platformBrightness)
      return;
    _media = next;
    markNeedsBuild();
  }

  bool get _mediaHasDependents =>
      _child is InheritedElement &&
      (_child as InheritedElement)._dependents.isNotEmpty;

  @override
  void mount(Element? parent) {
    super.mount(parent);
    rebuild();
  }

  @override
  void performRebuild() {
    _dirty = false;
    _updatingChildren = true;
    try {
      _child = updateChild(_child, MediaQuery(data: _media, child: _app));
    } finally {
      _updatingChildren = false;
    }
    _syncDom();
  }

  @override
  void visitChildren(void Function(Element child) visitor) {
    final child = _child;
    if (child != null) visitor(child);
  }
}

/// Owns one mounted tree: dirty elements, deferred measurement and disposal.
class _DomOwner {
  _DomOwner(this.host);
  final _Node host;
  // Insertion order: parents always precede their descendants.
  final _live = LinkedHashSet<Element>.identity();
  final _dirtyElements = <Element>[];
  final _layoutQueue = LinkedHashSet<_LayoutBuilderElement>.identity();
  final _layoutBuilders = HashSet<_LayoutBuilderElement>.identity();
  final _paintQueue = LinkedHashSet<_PaintElement>.identity();
  final _painters = HashSet<_PaintElement>.identity();
  _RootElement? _root;
  bool _scheduled = false, _disposed = false, _flushing = false;
  JSFunction? _resizeListener;

  void _scheduleBuild(Element element) {
    _dirtyElements.add(element);
    _scheduleFrame();
  }

  void _schedulePaint(_PaintElement element) {
    _paintQueue.add(element);
    _scheduleFrame();
  }

  void _scheduleLayout(_LayoutBuilderElement element) {
    _layoutQueue.add(element);
    _scheduleFrame();
  }

  void _scheduleFrame() {
    if (_disposed || _scheduled || _flushing) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (!_disposed) _guard(_flush);
    });
  }

  void _guard(void Function() action) {
    try {
      action();
    } catch (_) {
      dispose();
      rethrow;
    }
  }

  void _flush() {
    _flushing = true;
    try {
      var passes = 0;
      while (_dirtyElements.isNotEmpty ||
          _layoutQueue.isNotEmpty ||
          _paintQueue.isNotEmpty) {
        if (++passes > 10000)
          throw StateError('Native rebuild limit exceeded.');
        if (_dirtyElements.isNotEmpty) {
          final batch = List.of(_dirtyElements)
            ..sort((a, b) => a._depth - b._depth);
          _dirtyElements.clear();
          for (final element in batch) {
            element.rebuild();
          }
          continue;
        }
        if (_layoutQueue.isNotEmpty) {
          // Measure attached DOM boxes, rather than estimating constraints.
          final jobs = List.of(_layoutQueue)
            ..sort((a, b) => a._depth - b._depth);
          _layoutQueue.clear();
          for (final job in jobs) {
            if (job._active) job._performLayout();
          }
          continue;
        }
        // Paint once layout has settled.
        final paints = List.of(_paintQueue);
        _paintQueue.clear();
        for (final job in paints) {
          if (job._active) job._performPaint();
        }
      }
      _updateResizeListener();
    } finally {
      _flushing = false;
    }
    WidgetsBinding.instance._runPostFrame();
  }

  void _updateResizeListener() {
    final needed =
        _layoutBuilders.isNotEmpty ||
        _painters.isNotEmpty ||
        (_root?._mediaHasDependents ?? false);
    if (needed && _resizeListener == null) {
      _resizeListener = (() {
        if (_disposed) return;
        _root?._resize();
        _layoutQueue.addAll(_layoutBuilders);
        _paintQueue.addAll(_painters);
        _scheduleFrame();
      }).toJS;
      _window.addEventListener('resize', _resizeListener!);
    } else if (!needed && _resizeListener != null) {
      _window.removeEventListener('resize', _resizeListener!);
      _resizeListener = null;
    }
  }

  void _unmountTree(Element element) {
    element.visitChildren(_unmountTree);
    element.unmount();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_resizeListener != null) {
      _window.removeEventListener('resize', _resizeListener!);
      _resizeListener = null;
    }
    _dirtyElements.clear();
    _layoutQueue.clear();
    _paintQueue.clear();
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

    // Reverse insertion order disposes descendants before their ancestors,
    // including partially built subtrees left behind by a failed build.
    for (final element in _live.toList().reversed) {
      cleanup(element.unmount);
    }
    _live.clear();
    _layoutBuilders.clear();
    _painters.clear();
    cleanup(() => host.replaceChildren());
    if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
  }
}

_DomOwner? _activeOwner;

void runApp(Widget app) {
  final host = _document.querySelector('#app');
  if (host == null) throw StateError('Missing #app DOM host.');
  _activeOwner?.dispose();
  final owner = _DomOwner(host);
  _activeOwner = owner;
  owner._guard(() {
    host.replaceChildren();
    final root = _RootElement(app, owner);
    owner._root = root;
    root.mount(null);
    owner._flush();
  });
}

// ---------------------------------------------------------------------------
// Generic builders.

typedef WidgetBuilder = Widget Function(BuildContext context);
typedef TransitionBuilder =
    Widget Function(BuildContext context, Widget? child);
typedef StateSetter = void Function(VoidCallback fn);
typedef StatefulWidgetBuilder =
    Widget Function(BuildContext context, StateSetter setState);
typedef ValueWidgetBuilder<T> =
    Widget Function(BuildContext context, T value, Widget? child);
typedef IndexedWidgetBuilder = Widget Function(BuildContext context, int index);
typedef NullableIndexedWidgetBuilder =
    Widget? Function(BuildContext context, int index);

class Builder extends StatelessWidget {
  const Builder({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => builder(context);
}

class StatefulBuilder extends StatefulWidget {
  const StatefulBuilder({super.key, required this.builder});
  final StatefulWidgetBuilder builder;
  @override
  State<StatefulBuilder> createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
}

/// Rebuilds when [listenable] notifies.
class ListenableBuilder extends StatefulWidget {
  const ListenableBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });
  final Listenable listenable;
  final TransitionBuilder builder;
  final Widget? child;
  @override
  State<ListenableBuilder> createState() => _ListenableBuilderState();
}

class _ListenableBuilderState extends State<ListenableBuilder> {
  void _changed() => setState(() {});
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_changed);
  }

  @override
  void didUpdateWidget(ListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.listenable, widget.listenable)) {
      oldWidget.listenable.removeListener(_changed);
      widget.listenable.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}

class AnimatedBuilder extends ListenableBuilder {
  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required super.builder,
    super.child,
  }) : super(listenable: animation);
}

class ValueListenableBuilder<T> extends StatefulWidget {
  const ValueListenableBuilder({
    super.key,
    required this.valueListenable,
    required this.builder,
    this.child,
  });
  final ValueListenable<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;
  @override
  State<ValueListenableBuilder<T>> createState() =>
      _ValueListenableBuilderState<T>();
}

class _ValueListenableBuilderState<T> extends State<ValueListenableBuilder<T>> {
  late T value;
  void _changed() => setState(() => value = widget.valueListenable.value);
  @override
  void initState() {
    super.initState();
    value = widget.valueListenable.value;
    widget.valueListenable.addListener(_changed);
  }

  @override
  void didUpdateWidget(ValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.valueListenable, widget.valueListenable)) {
      oldWidget.valueListenable.removeListener(_changed);
      value = widget.valueListenable.value;
      widget.valueListenable.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, value, widget.child);
}

// ---------------------------------------------------------------------------
// Async builders.

enum ConnectionState { none, waiting, active, done }

class AsyncSnapshot<T> {
  const AsyncSnapshot._(this.connectionState, this.data, this.error, this.st);
  const AsyncSnapshot.nothing()
    : this._(ConnectionState.none, null, null, null);
  const AsyncSnapshot.waiting()
    : this._(ConnectionState.waiting, null, null, null);
  const AsyncSnapshot.withData(ConnectionState state, T data)
    : this._(state, data, null, null);
  const AsyncSnapshot.withError(
    ConnectionState state,
    Object error, [
    StackTrace stackTrace = StackTrace.empty,
  ]) : this._(state, null, error, stackTrace);
  final ConnectionState connectionState;
  final T? data;
  final Object? error;
  final StackTrace? st;
  StackTrace? get stackTrace => st;
  bool get hasData => data != null;
  bool get hasError => error != null;
  T get requireData {
    if (hasData) return data as T;
    if (hasError) Error.throwWithStackTrace(error!, st ?? StackTrace.empty);
    throw StateError('Snapshot has neither data nor error.');
  }

  AsyncSnapshot<T> inState(ConnectionState state) =>
      AsyncSnapshot._(state, data, error, st);
}

typedef AsyncWidgetBuilder<T> =
    Widget Function(BuildContext context, AsyncSnapshot<T> snapshot);

class FutureBuilder<T> extends StatefulWidget {
  const FutureBuilder({
    super.key,
    required this.future,
    this.initialData,
    required this.builder,
  });
  final Future<T>? future;
  final T? initialData;
  final AsyncWidgetBuilder<T> builder;
  @override
  State<FutureBuilder<T>> createState() => _FutureBuilderState<T>();
}

class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData!);
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future == widget.future) return;
    if (_activeCallbackIdentity != null) {
      _activeCallbackIdentity = null;
      _snapshot = _snapshot.inState(ConnectionState.none);
    }
    _subscribe();
  }

  void _subscribe() {
    final future = widget.future;
    if (future == null) return;
    final identity = Object();
    _activeCallbackIdentity = identity;
    future.then<void>(
      (data) {
        if (identical(_activeCallbackIdentity, identity) && mounted) {
          setState(
            () => _snapshot = AsyncSnapshot<T>.withData(
              ConnectionState.done,
              data,
            ),
          );
        }
      },
      onError: (Object error, StackTrace stack) {
        if (identical(_activeCallbackIdentity, identity) && mounted) {
          setState(
            () => _snapshot = AsyncSnapshot<T>.withError(
              ConnectionState.done,
              error,
              stack,
            ),
          );
        }
      },
    );
    _snapshot = _snapshot.inState(ConnectionState.waiting);
  }

  @override
  void dispose() {
    _activeCallbackIdentity = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}

class StreamBuilder<T> extends StatefulWidget {
  const StreamBuilder({
    super.key,
    required this.stream,
    this.initialData,
    required this.builder,
  });
  final Stream<T>? stream;
  final T? initialData;
  final AsyncWidgetBuilder<T> builder;
  @override
  State<StreamBuilder<T>> createState() => _StreamBuilderState<T>();
}

class _StreamBuilderState<T> extends State<StreamBuilder<T>> {
  StreamSubscription<T>? _subscription;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData!);
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream == widget.stream) return;
    _unsubscribe();
    _snapshot = _snapshot.inState(ConnectionState.none);
    _subscribe();
  }

  void _subscribe() {
    final stream = widget.stream;
    if (stream == null) return;
    _subscription = stream.listen(
      (data) => setState(
        () =>
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, data),
      ),
      onError: (Object error, StackTrace stack) => setState(
        () => _snapshot = AsyncSnapshot<T>.withError(
          ConnectionState.active,
          error,
          stack,
        ),
      ),
      onDone: () =>
          setState(() => _snapshot = _snapshot.inState(ConnectionState.done)),
    );
    _snapshot = _snapshot.inState(ConnectionState.waiting);
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}

// ---------------------------------------------------------------------------
// Measured layout.

typedef LayoutWidgetBuilder =
    Widget Function(BuildContext context, BoxConstraints constraints);

/// Horizontal constraints come from the attached DOM box; vertical
/// constraints are unbounded because documents flow vertically.
class BoxConstraints {
  const BoxConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });
  const BoxConstraints.tightFor({double? width, double? height})
    : minWidth = width ?? 0,
      maxWidth = width ?? double.infinity,
      minHeight = height ?? 0,
      maxHeight = height ?? double.infinity;
  const BoxConstraints.expand({double? width, double? height})
    : minWidth = width ?? double.infinity,
      maxWidth = width ?? double.infinity,
      minHeight = height ?? double.infinity,
      maxHeight = height ?? double.infinity;
  BoxConstraints.loose(Size size)
    : minWidth = 0,
      maxWidth = size.width,
      minHeight = 0,
      maxHeight = size.height;
  final double minWidth, maxWidth, minHeight, maxHeight;
  bool get hasBoundedWidth => maxWidth < double.infinity;
  bool get hasBoundedHeight => maxHeight < double.infinity;
  Size get biggest => Size(maxWidth, maxHeight);
  Size get smallest => Size(minWidth, minHeight);
}

class LayoutBuilder extends _DomWidget {
  const LayoutBuilder({required this.builder, super.key});
  final LayoutWidgetBuilder builder;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) =>
      out.css('width:100%;min-width:0;box-sizing:border-box;');
  @override
  Element createElement() => _LayoutBuilderElement(this);
}

class _LayoutBuilderElement extends _DomElement {
  _LayoutBuilderElement(LayoutBuilder super.widget);
  double? _width;
  bool _needsLayout = true;

  @override
  void mount(Element? parent) {
    super.mount(parent);
    _owner!._layoutBuilders.add(this);
  }

  @override
  void _updateChildWidgets(List<Widget> widgets) {
    if (_needsLayout && _width != null) return;
    _needsLayout = true;
    _owner!._scheduleLayout(this);
  }

  void _performLayout() {
    final width = checkedDimension(node.clientWidth);
    if (!_needsLayout && width == _width) return;
    _needsLayout = false;
    _width = width;
    _applyBuilt(
      (widget as LayoutBuilder).builder(this, BoxConstraints(maxWidth: width)),
    );
  }

  void _applyBuilt(Widget built) => super._updateChildWidgets([built]);

  @override
  void unmount() {
    _owner?._layoutBuilders.remove(this);
    _owner?._layoutQueue.remove(this);
    super.unmount();
  }
}

/// Measures both dimensions of its box; children must be absolutely
/// positioned so the box height comes from the parent, not its content.
class _SizedBuilder extends LayoutBuilder {
  const _SizedBuilder({required this.sizeBuilder})
    : super(builder: _unusedLayoutBuilder);
  final Widget Function(BuildContext context, Size size) sizeBuilder;
  @override
  void _render(_DomBuilder out) => out.css(
    'position:relative;box-sizing:border-box;width:100%;height:100%;min-width:0;min-height:0;',
  );
  @override
  Element createElement() => _SizedElement(this);
}

Widget _unusedLayoutBuilder(BuildContext context, BoxConstraints c) =>
    throw StateError('Unused');

class _SizedElement extends _LayoutBuilderElement {
  _SizedElement(_SizedBuilder super.widget);
  double? _height;

  @override
  void _performLayout() {
    final width = checkedDimension(node.clientWidth);
    final height = checkedDimension(
      (node as JSObject)
          .getProperty<JSNumber>('clientHeight'.toJS)
          .toDartDouble,
    );
    if (!_needsLayout && width == _width && height == _height) return;
    _needsLayout = false;
    _width = width;
    _height = height;
    _applyBuilt(
      (widget as _SizedBuilder).sizeBuilder(this, Size(width, height)),
    );
  }
}
