part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Keyboard focus, shortcuts and actions. Key events come from DOM keyboard
// events, which bubble from the focused element through its ancestors in
// the same order Flutter dispatches from the primary focus upwards; a
// handled event stops there and its default action is prevented.

enum KeyEventResult { handled, ignored, skipRemainingHandlers }

typedef FocusOnKeyEventCallback =
    KeyEventResult Function(FocusNode node, KeyEvent event);

KeyEvent _keyEventOf(_Event event, String type) => domKeyEvent(
  type: type,
  key: event.key ?? '',
  repeat: event.repeat ?? false,
  timeStamp: event.timeStamp ?? 0,
  control: event.ctrlKey ?? false,
  shift: event.shiftKey ?? false,
  alt: event.altKey ?? false,
  meta: event.metaKey ?? false,
);

/// Applies a handler result to the DOM event.
bool _consumeKey(_Event event, KeyEventResult result) {
  if (result == KeyEventResult.ignored) return false;
  if (result == KeyEventResult.handled) event.preventDefault();
  event.stopPropagation();
  return true;
}

bool _moveDomFocus(int step) {
  final document = _document as JSObject;
  final candidates = document.callMethod<JSObject>(
    'querySelectorAll'.toJS,
    'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])'
        .toJS,
  );
  final count = _jsNumber(candidates, 'length').toInt();
  if (count == 0) return false;
  final active = document.getProperty<JSObject?>('activeElement'.toJS);
  var index = -1;
  for (var i = 0; i < count; i++) {
    final node = candidates.callMethod<JSObject>('item'.toJS, i.toJS);
    if (identical(node, active)) index = i;
  }
  final next = index < 0
      ? (step > 0 ? 0 : count - 1)
      : (index + step + count) % count;
  candidates
      .callMethod<JSObject>('item'.toJS, next.toJS)
      .callMethod<JSAny?>('focus'.toJS);
  return true;
}

/// Wraps [child] without affecting layout (`display:contents`) unless the
/// wrapper must take focus itself.
abstract class _KeyScope extends _DomWidget {
  const _KeyScope({required this.child});
  final Widget child;
  bool get _focusable;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css(
      _focusable
          ? 'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;outline:none;'
          : 'display:contents;',
    );
    if (_focusable) out.attributes['tabindex'] = '-1';
    out.child(child);
  }
}

class Focus extends StatefulWidget {
  const Focus({
    super.key,
    required this.child,
    this.focusNode,
    this.parentNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onKeyEvent,
    this.canRequestFocus,
    this.skipTraversal,
    this.descendantsAreFocusable,
    this.descendantsAreTraversable,
    this.includeSemantics = true,
    this.debugLabel,
  });
  final Widget child;
  final FocusNode? focusNode, parentNode;
  final bool autofocus, includeSemantics;
  final ValueChanged<bool>? onFocusChange;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool? canRequestFocus, skipTraversal;
  final bool? descendantsAreFocusable, descendantsAreTraversable;
  final String? debugLabel;

  static FocusNode of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No Focus ancestor in this context.'));
  static FocusNode? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FocusMarker>()?.node;

  @override
  State<Focus> createState() => _FocusState();
}

class _FocusMarker extends InheritedWidget {
  const _FocusMarker({required this.node, required super.child});
  final FocusNode node;
  @override
  bool updateShouldNotify(_FocusMarker oldWidget) => oldWidget.node != node;
}

class _FocusState extends State<Focus> {
  FocusNode? _own;
  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: widget.debugLabel));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = _node;
    if (widget.canRequestFocus != null) {
      node.canRequestFocus = widget.canRequestFocus!;
    }
    final focusable =
        widget.focusNode != null ||
        widget.autofocus ||
        widget.canRequestFocus == true;
    return _FocusMarker(
      node: node,
      child: _FocusBox(
        state: this,
        focusable: focusable && node.canRequestFocus,
        child: widget.child,
      ),
    );
  }
}

class _FocusBox extends _KeyScope {
  const _FocusBox({
    required this.state,
    required this.focusable,
    required super.child,
  });
  final _FocusState state;
  final bool focusable;
  @override
  bool get _focusable => focusable;
  @override
  void _render(_DomBuilder out) {
    super._render(out);
    final widget = state.widget;
    final node = state._node;
    if (focusable) {
      final element = out.context;
      node._attach(element.node);
      if (widget.autofocus && !node._autofocused) {
        node._autofocused = true;
        node.requestFocus();
      }
    }
    out.on('focusin', (_) {
      node._setFocus(true);
      widget.onFocusChange?.call(true);
    });
    out.on('focusout', (_) {
      node._setFocus(false);
      widget.onFocusChange?.call(false);
    });
    void key(_Event? event, String type) {
      if (event == null) return;
      final keyEvent = _keyEventOf(event, type);
      var result = widget.onKeyEvent?.call(node, keyEvent);
      if (result == null || result == KeyEventResult.ignored) {
        result = node.onKeyEvent?.call(node, keyEvent) ?? result;
      }
      if (result != null) _consumeKey(event, result);
    }

    out.on('keydown', (event) => key(event, 'keydown'));
    out.on('keyup', (event) => key(event, 'keyup'));
  }
}

class KeyboardListener extends StatelessWidget {
  const KeyboardListener({
    super.key,
    required this.focusNode,
    this.autofocus = false,
    this.includeSemantics = true,
    this.onKeyEvent,
    required this.child,
  });
  final FocusNode focusNode;
  final bool autofocus, includeSemantics;
  final ValueChanged<KeyEvent>? onKeyEvent;
  final Widget child;
  @override
  Widget build(BuildContext context) => Focus(
    focusNode: focusNode,
    autofocus: autofocus,
    includeSemantics: includeSemantics,
    onKeyEvent: (node, event) {
      onKeyEvent?.call(event);
      return KeyEventResult.ignored;
    },
    child: child,
  );
}

/// Focus traversal follows document order; groups and policies are kept for
/// API compatibility.
class FocusTraversalGroup extends StatelessWidget {
  const FocusTraversalGroup({
    super.key,
    this.policy,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    required this.child,
  });
  final FocusTraversalPolicy? policy;
  final bool descendantsAreFocusable, descendantsAreTraversable;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

abstract class FocusTraversalPolicy {
  const FocusTraversalPolicy();
}

class ReadingOrderTraversalPolicy extends FocusTraversalPolicy {
  const ReadingOrderTraversalPolicy();
}

class WidgetOrderTraversalPolicy extends FocusTraversalPolicy {
  const WidgetOrderTraversalPolicy();
}

class OrderedTraversalPolicy extends FocusTraversalPolicy {
  const OrderedTraversalPolicy({this.secondary});
  final FocusTraversalPolicy? secondary;
}

abstract class FocusOrder {
  const FocusOrder();
}

class NumericFocusOrder extends FocusOrder {
  const NumericFocusOrder(this.order);
  final double order;
}

class LexicalFocusOrder extends FocusOrder {
  const LexicalFocusOrder(this.order);
  final String order;
}

class FocusTraversalOrder extends StatelessWidget {
  const FocusTraversalOrder({
    super.key,
    required this.order,
    required this.child,
  });
  final FocusOrder order;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

/// Keeps descendants out of keyboard focus and the accessibility tree via
/// the `inert` attribute (which also blocks pointer input in browsers).
class ExcludeFocus extends _DomWidget {
  const ExcludeFocus({super.key, this.excluding = true, required this.child});
  final bool excluding;
  final Widget child;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('display:contents;');
    if (excluding) out.attributes['inert'] = '';
    out.child(child);
  }
}

// ---------------------------------------------------------------------------
// Intents and actions.

abstract class Intent {
  const Intent();
  static const doNothing = DoNothingIntent();
}

class DoNothingIntent extends Intent {
  const DoNothingIntent();
}

class DoNothingAndStopPropagationIntent extends Intent {
  const DoNothingAndStopPropagationIntent();
}

class ActivateIntent extends Intent {
  const ActivateIntent();
}

class ButtonActivateIntent extends Intent {
  const ButtonActivateIntent();
}

class DismissIntent extends Intent {
  const DismissIntent();
}

class VoidCallbackIntent extends Intent {
  const VoidCallbackIntent(this.callback);
  final VoidCallback callback;
}

class NextFocusIntent extends Intent {
  const NextFocusIntent();
}

class PreviousFocusIntent extends Intent {
  const PreviousFocusIntent();
}

abstract class Action<T extends Intent> with Diagnosticable {
  Action();
  factory Action.overridable({
    required Action<T> defaultAction,
    required BuildContext context,
  }) => defaultAction;

  Object? invoke(T intent);
  bool isEnabled(T intent) => isActionEnabled;
  bool get isActionEnabled => true;
  bool consumesKey(T intent) => true;
  Type get intentType => T;
}

abstract class ContextAction<T extends Intent> extends Action<T> {
  @override
  Object? invoke(T intent, [BuildContext? context]);
}

class CallbackAction<T extends Intent> extends Action<T> {
  CallbackAction({required this.onInvoke});
  final Object? Function(T intent) onInvoke;
  @override
  Object? invoke(T intent) => onInvoke(intent);
}

class DoNothingAction extends Action<Intent> {
  DoNothingAction({bool consumesKey = true}) : _consumesKey = consumesKey;
  final bool _consumesKey;
  @override
  bool consumesKey(Intent intent) => _consumesKey;
  @override
  void invoke(Intent intent) {}
}

class VoidCallbackAction extends Action<VoidCallbackIntent> {
  @override
  Object? invoke(VoidCallbackIntent intent) {
    intent.callback();
    return null;
  }
}

/// Actions registered on DOM nodes, for dispatch from key events below.
final _actionsByNode = Expando<Actions>('actions');

class Actions extends _DomWidget {
  const Actions({
    super.key,
    this.dispatcher,
    required this.actions,
    required this.child,
  });
  final ActionDispatcher? dispatcher;
  final Map<Type, Action<Intent>> actions;
  final Widget child;

  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('display:contents;');
    _actionsByNode[out.context.node as JSObject] = this;
    out.child(child);
  }

  Action<Intent>? _find(Intent intent) {
    final action = actions[intent.runtimeType];
    return action != null && action.isEnabled(intent) ? action : null;
  }

  static Action<T>? maybeFind<T extends Intent>(
    BuildContext context, {
    T? intent,
  }) {
    Action<T>? found;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Actions) {
        final action = intent == null
            ? widget.actions[T]
            : widget._find(intent);
        if (action != null) {
          found = action as Action<T>;
          return false;
        }
      }
      return true;
    });
    return found;
  }

  static Action<T> find<T extends Intent>(BuildContext context, {T? intent}) =>
      maybeFind<T>(context, intent: intent) ??
      (throw StateError('No Actions ancestor handles $T.'));

  static VoidCallback? handler<T extends Intent>(
    BuildContext context,
    T intent,
  ) {
    final action = maybeFind<T>(context, intent: intent);
    return action == null ? null : () => action.invoke(intent);
  }

  static Object? invoke<T extends Intent>(BuildContext context, T intent) =>
      find<T>(context, intent: intent).invoke(intent);

  static Object? maybeInvoke<T extends Intent>(
    BuildContext context,
    T intent,
  ) => maybeFind<T>(context, intent: intent)?.invoke(intent);
}

class ActionDispatcher {
  const ActionDispatcher();
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) => action.invoke(intent);
}

// ---------------------------------------------------------------------------
// Shortcuts.

abstract class ShortcutActivator {
  const ShortcutActivator();
  Iterable<LogicalKeyboardKey>? get triggers;
  bool accepts(KeyEvent event, HardwareKeyboard state);
}

class SingleActivator extends ShortcutActivator {
  const SingleActivator(
    this.trigger, {
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
    this.numLock = LockState.ignored,
    this.includeRepeats = true,
  });
  final LogicalKeyboardKey trigger;
  final bool control, shift, alt, meta, includeRepeats;
  final LockState numLock;
  @override
  Iterable<LogicalKeyboardKey> get triggers => [trigger];
  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      (event is KeyDownEvent || (includeRepeats && event is KeyRepeatEvent)) &&
      event.logicalKey == trigger &&
      state.isControlPressed == control &&
      state.isShiftPressed == shift &&
      state.isAltPressed == alt &&
      state.isMetaPressed == meta;
}

enum LockState { ignored, locked, unlocked }

class CharacterActivator extends ShortcutActivator {
  const CharacterActivator(
    this.character, {
    this.alt = false,
    this.control = false,
    this.meta = false,
    this.includeRepeats = true,
  });
  final String character;
  final bool alt, control, meta, includeRepeats;
  @override
  Iterable<LogicalKeyboardKey>? get triggers => null;
  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      (event is KeyDownEvent || (includeRepeats && event is KeyRepeatEvent)) &&
      event.character == character &&
      state.isControlPressed == control &&
      state.isAltPressed == alt &&
      state.isMetaPressed == meta;
}

class LogicalKeySet extends ShortcutActivator {
  LogicalKeySet(
    LogicalKeyboardKey key1, [
    LogicalKeyboardKey? key2,
    LogicalKeyboardKey? key3,
    LogicalKeyboardKey? key4,
  ]) : keys = {key1, ?key2, ?key3, ?key4};
  LogicalKeySet.fromSet(this.keys);
  final Set<LogicalKeyboardKey> keys;

  static LogicalKeyboardKey _collapse(LogicalKeyboardKey key) =>
      key.synonyms.isEmpty ? key : key.synonyms.first;

  @override
  Iterable<LogicalKeyboardKey> get triggers => keys;
  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final pressed = {
      for (final key in state.logicalKeysPressed) _collapse(key),
      if (state.isControlPressed) LogicalKeyboardKey.control,
      if (state.isShiftPressed) LogicalKeyboardKey.shift,
      if (state.isAltPressed) LogicalKeyboardKey.alt,
      if (state.isMetaPressed) LogicalKeyboardKey.meta,
    };
    final wanted = {for (final key in keys) _collapse(key)};
    return wanted.contains(_collapse(event.logicalKey)) &&
        wanted.length == pressed.length &&
        wanted.every(pressed.contains);
  }

  @override
  bool operator ==(Object other) =>
      other is LogicalKeySet &&
      other.keys.length == keys.length &&
      other.keys.containsAll(keys);
  @override
  int get hashCode => Object.hashAllUnordered(keys);
}

class ShortcutManager extends ChangeNotifier {
  ShortcutManager({
    Map<ShortcutActivator, Intent> shortcuts = const {},
    this.modal = false,
  }) : _shortcuts = shortcuts;
  final bool modal;
  Map<ShortcutActivator, Intent> _shortcuts;
  Map<ShortcutActivator, Intent> get shortcuts => _shortcuts;
  set shortcuts(Map<ShortcutActivator, Intent> value) {
    _shortcuts = value;
    notifyListeners();
  }
}

/// Finds the [Action] for [intent] in `Actions` widgets between the event
/// target and [boundary], then above [context].
bool _dispatchIntent(
  _Event event,
  JSObject boundary,
  BuildContext context,
  Intent intent,
) {
  var node = event.target;
  while (node != null) {
    final actions = _actionsByNode[node];
    final action = actions?._find(intent);
    if (action != null) {
      action.invoke(intent);
      return action.consumesKey(intent);
    }
    if (identical(node, boundary)) break;
    node = node.getProperty<JSObject?>('parentElement'.toJS);
  }
  if (intent is VoidCallbackIntent) {
    intent.callback();
    return true;
  }
  final action = Actions.maybeFind<Intent>(context, intent: intent);
  if (action == null) return false;
  action.invoke(intent);
  return action.consumesKey(intent);
}

class Shortcuts extends _DomWidget {
  const Shortcuts({
    super.key,
    required Map<ShortcutActivator, Intent> shortcuts,
    required this.child,
    this.debugLabel,
    this.includeSemantics = true,
  }) : _shortcuts = shortcuts,
       manager = null;
  const Shortcuts.manager({
    super.key,
    required ShortcutManager this.manager,
    required this.child,
    this.debugLabel,
    this.includeSemantics = true,
  }) : _shortcuts = const {};
  final Map<ShortcutActivator, Intent> _shortcuts;
  final ShortcutManager? manager;
  final Widget child;
  final String? debugLabel;
  final bool includeSemantics;

  Map<ShortcutActivator, Intent> get shortcuts =>
      manager?.shortcuts ?? _shortcuts;

  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('display:contents;');
    final element = out.context;
    out.on('keydown', (event) {
      if (event == null) return;
      final keyEvent = _keyEventOf(event, 'keydown');
      for (final entry in shortcuts.entries) {
        if (!entry.key.accepts(keyEvent, HardwareKeyboard.instance)) continue;
        if (_dispatchIntent(
          event,
          element.node as JSObject,
          element,
          entry.value,
        )) {
          _consumeKey(event, KeyEventResult.handled);
        }
        return;
      }
    });
    out.child(child);
  }
}

class CallbackShortcuts extends _DomWidget {
  const CallbackShortcuts({
    super.key,
    required this.bindings,
    required this.child,
  });
  final Map<ShortcutActivator, VoidCallback> bindings;
  final Widget child;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('display:contents;');
    out.on('keydown', (event) {
      if (event == null) return;
      final keyEvent = _keyEventOf(event, 'keydown');
      for (final entry in bindings.entries) {
        if (entry.key.accepts(keyEvent, HardwareKeyboard.instance)) {
          entry.value();
          _consumeKey(event, KeyEventResult.handled);
          return;
        }
      }
    });
    out.child(child);
  }
}
