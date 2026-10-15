part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Pointer gestures: tap details, long press and drags recognized from DOM
// pointer events. Clicks still deliver `onTap`, so keyboard and assistive
// activation keep working.

enum PointerDeviceKind {
  touch,
  mouse,
  stylus,
  invertedStylus,
  trackpad,
  unknown,
}

const kTouchSlop = 18.0;
const kPrecisePointerPanSlop = 2.0;
const kLongPressTimeout = Duration(milliseconds: 500);

class Velocity {
  const Velocity({required this.pixelsPerSecond});
  final Offset pixelsPerSecond;
  static const zero = Velocity(pixelsPerSecond: Offset.zero);
  @override
  bool operator ==(Object other) =>
      other is Velocity && other.pixelsPerSecond == pixelsPerSecond;
  @override
  int get hashCode => pixelsPerSecond.hashCode;
  @override
  String toString() => 'Velocity(${pixelsPerSecond.dx}, ${pixelsPerSecond.dy})';
}

class TapDownDetails {
  TapDownDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.kind,
  }) : localPosition = localPosition ?? globalPosition;
  final Offset globalPosition, localPosition;
  final PointerDeviceKind? kind;
}

class TapUpDetails {
  TapUpDetails({
    required this.kind,
    this.globalPosition = Offset.zero,
    Offset? localPosition,
  }) : localPosition = localPosition ?? globalPosition;
  final Offset globalPosition, localPosition;
  final PointerDeviceKind kind;
}

class LongPressStartDetails {
  const LongPressStartDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
  }) : localPosition = localPosition ?? globalPosition;
  final Offset globalPosition, localPosition;
}

class LongPressEndDetails {
  const LongPressEndDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.velocity = Velocity.zero,
  }) : localPosition = localPosition ?? globalPosition;
  final Offset globalPosition, localPosition;
  final Velocity velocity;
}

class DragDownDetails {
  DragDownDetails({this.globalPosition = Offset.zero, Offset? localPosition})
    : localPosition = localPosition ?? globalPosition;
  final Offset globalPosition, localPosition;
}

class DragStartDetails {
  DragStartDetails({
    this.sourceTimeStamp,
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.kind,
  }) : localPosition = localPosition ?? globalPosition;
  final Duration? sourceTimeStamp;
  final Offset globalPosition, localPosition;
  final PointerDeviceKind? kind;
}

class DragUpdateDetails {
  DragUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    required this.globalPosition,
    Offset? localPosition,
  }) : localPosition = localPosition ?? globalPosition;
  final Duration? sourceTimeStamp;
  final Offset delta, globalPosition, localPosition;
  final double? primaryDelta;
}

class DragEndDetails {
  DragEndDetails({
    this.velocity = Velocity.zero,
    this.primaryVelocity,
    this.globalPosition = Offset.zero,
    Offset? localPosition,
  }) : localPosition = localPosition ?? globalPosition;
  final Velocity velocity;
  final double? primaryVelocity;
  final Offset globalPosition, localPosition;
}

typedef GestureTapCallback = void Function();
typedef GestureTapDownCallback = void Function(TapDownDetails details);
typedef GestureTapUpCallback = void Function(TapUpDetails details);
typedef GestureTapCancelCallback = void Function();
typedef GestureLongPressCallback = void Function();
typedef GestureLongPressStartCallback =
    void Function(LongPressStartDetails details);
typedef GestureLongPressEndCallback =
    void Function(LongPressEndDetails details);
typedef GestureDragDownCallback = void Function(DragDownDetails details);
typedef GestureDragStartCallback = void Function(DragStartDetails details);
typedef GestureDragUpdateCallback = void Function(DragUpdateDetails details);
typedef GestureDragEndCallback = void Function(DragEndDetails details);
typedef GestureDragCancelCallback = void Function();

enum _DragAxis { free, horizontal, vertical }

/// The callbacks of one detector; handlers read the latest set through the
/// element's DOM node, so rebuilds during a gesture keep its state.
class _GestureCallbacks {
  const _GestureCallbacks({
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.drags = const {},
  });
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureLongPressCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;
  final Map<_DragAxis, _DragCallbacks> drags;

  bool get longPress =>
      onLongPress != null || onLongPressStart != null || onLongPressEnd != null;
  bool get isEmpty =>
      onTapDown == null &&
      onTapUp == null &&
      onTapCancel == null &&
      !longPress &&
      drags.isEmpty;
}

class _DragCallbacks {
  const _DragCallbacks({
    this.onDown,
    this.onStart,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
  });
  final GestureDragDownCallback? onDown;
  final GestureDragStartCallback? onStart;
  final GestureDragUpdateCallback? onUpdate;
  final GestureDragEndCallback? onEnd;
  final GestureDragCancelCallback? onCancel;
  bool get isEmpty =>
      onDown == null &&
      onStart == null &&
      onUpdate == null &&
      onEnd == null &&
      onCancel == null;
}

/// Per-node state of the pointer sequence in progress.
class _PointerTrack {
  _PointerTrack(this.pointer, this.kind, this.origin, this.originLocal);
  final int pointer;
  final PointerDeviceKind kind;
  final Offset origin, originLocal;
  Offset last = Offset.zero;
  double lastTime = 0;
  Offset velocity = Offset.zero;
  _DragAxis? dragging;
  bool longPressed = false, suppressClick = false;
  Timer? longPressTimer;
}

final _pointerTracks = Expando<_PointerTrack>('pointer');
final _gestureCallbacks = Expando<_GestureCallbacks>('gestures');

PointerDeviceKind _pointerKind(String? type) => switch (type) {
  'touch' => PointerDeviceKind.touch,
  'pen' => PointerDeviceKind.stylus,
  'mouse' => PointerDeviceKind.mouse,
  _ => PointerDeviceKind.unknown,
};

(Offset, Offset) _pointerPositions(_Event event) {
  final global = Offset(event.clientX ?? 0, event.clientY ?? 0);
  final target = event.currentTarget;
  if (target == null || !target.has('getBoundingClientRect')) {
    return (global, global);
  }
  final box = target.callMethod<JSObject>('getBoundingClientRect'.toJS);
  double read(String name) =>
      box.getProperty<JSNumber?>(name.toJS)?.toDartDouble ?? 0;
  return (global, global - Offset(read('left'), read('top')));
}

/// Installs pointer handlers for [callbacks] on [out]; `click` handlers
/// added by the caller run only when no long press or drag claimed the
/// pointer.
void _installGestures(_DomBuilder out, _GestureCallbacks callbacks) {
  if (callbacks.isEmpty) return;
  final axes = callbacks.drags.keys.toSet();
  if (axes.contains(_DragAxis.free) ||
      axes.containsAll({_DragAxis.horizontal, _DragAxis.vertical})) {
    out.css('touch-action:none;user-select:none;');
  } else if (axes.contains(_DragAxis.horizontal)) {
    out.css('touch-action:pan-y;user-select:none;');
  } else if (axes.contains(_DragAxis.vertical)) {
    out.css('touch-action:pan-x;user-select:none;');
  }
  if (callbacks.longPress) out.css('-webkit-touch-callout:none;');

  _GestureCallbacks current(_Event event) =>
      (event.currentTarget == null
          ? null
          : _gestureCallbacks[event.currentTarget!]) ??
      callbacks;

  void cancelTap(_GestureCallbacks callbacks) => callbacks.onTapCancel?.call();

  out.on('pointerdown', (event) {
    if (event == null || (event.button ?? 0) != 0) return;
    final target = event.currentTarget;
    if (target == null) return;
    _gestureCallbacks[target] = callbacks;
    _suppressedClicks[target] = null;
    _pointerTracks[target]?.longPressTimer?.cancel();
    final (global, local) = _pointerPositions(event);
    final track =
        _PointerTrack(
            event.pointerId ?? 0,
            _pointerKind(event.pointerType),
            global,
            local,
          )
          ..last = global
          ..lastTime = event.timeStamp ?? 0;
    _pointerTracks[target] = track;
    if (callbacks.drags.isNotEmpty && target.has('setPointerCapture')) {
      try {
        target.callMethod<JSAny?>('setPointerCapture'.toJS, track.pointer.toJS);
      } catch (_) {}
    }
    callbacks.onTapDown?.call(
      TapDownDetails(
        globalPosition: global,
        localPosition: local,
        kind: track.kind,
      ),
    );
    for (final drag in callbacks.drags.values) {
      drag.onDown?.call(
        DragDownDetails(globalPosition: global, localPosition: local),
      );
    }
    if (callbacks.longPress) {
      track.longPressTimer = Timer(kLongPressTimeout, () {
        if (!identical(_pointerTracks[target], track) ||
            track.dragging != null) {
          return;
        }
        final latest = _gestureCallbacks[target] ?? callbacks;
        track
          ..longPressed = true
          ..suppressClick = true;
        cancelTap(latest);
        latest.onLongPressStart?.call(
          LongPressStartDetails(globalPosition: global, localPosition: local),
        );
        latest.onLongPress?.call();
      });
    }
  });

  out.on('pointermove', (event) {
    if (event == null) return;
    final target = event.currentTarget;
    final track = target == null ? null : _pointerTracks[target];
    if (track == null || track.pointer != (event.pointerId ?? 0)) return;
    final callbacks = current(event);
    final (global, local) = _pointerPositions(event);
    final time = event.timeStamp ?? track.lastTime;
    final delta = global - track.last;
    if (time > track.lastTime) {
      track.velocity = delta / ((time - track.lastTime) / 1000);
    }
    track
      ..last = global
      ..lastTime = time;
    final moved = global - track.origin;
    final slop = track.kind == PointerDeviceKind.mouse
        ? kPrecisePointerPanSlop
        : kTouchSlop;
    if (track.dragging == null) {
      if (moved.distance > kTouchSlop) {
        track.longPressTimer?.cancel();
        if (!track.longPressed && track.suppressClick == false) {
          // Leaving the tap slop cancels the tap, as in Flutter.
          track.suppressClick = true;
          cancelTap(callbacks);
        }
      }
      if (track.longPressed) return;
      _DragAxis? axis;
      if (callbacks.drags.containsKey(_DragAxis.free) &&
          moved.distance > slop) {
        axis = _DragAxis.free;
      } else if (callbacks.drags.containsKey(_DragAxis.horizontal) &&
          moved.dx.abs() > slop &&
          moved.dx.abs() >= moved.dy.abs()) {
        axis = _DragAxis.horizontal;
      } else if (callbacks.drags.containsKey(_DragAxis.vertical) &&
          moved.dy.abs() > slop) {
        axis = _DragAxis.vertical;
      }
      if (axis == null) return;
      track
        ..dragging = axis
        ..suppressClick = true;
      track.longPressTimer?.cancel();
      if (moved.distance <= kTouchSlop) cancelTap(callbacks);
      event.preventDefault();
      callbacks.drags[axis]!.onStart?.call(
        DragStartDetails(
          globalPosition: track.origin,
          localPosition: track.originLocal,
          kind: track.kind,
        ),
      );
    }
    final axis = track.dragging!;
    final drag = callbacks.drags[axis];
    if (drag == null) return;
    event.preventDefault();
    final total = global - track.origin;
    // The first update carries the movement since the pointer went down.
    final step = delta == Offset.zero ? total : delta;
    final restricted = switch (axis) {
      _DragAxis.free => step,
      _DragAxis.horizontal => Offset(step.dx, 0),
      _DragAxis.vertical => Offset(0, step.dy),
    };
    drag.onUpdate?.call(
      DragUpdateDetails(
        delta: restricted,
        primaryDelta: switch (axis) {
          _DragAxis.free => null,
          _DragAxis.horizontal => restricted.dx,
          _DragAxis.vertical => restricted.dy,
        },
        globalPosition: global,
        localPosition: local,
      ),
    );
  });

  void finish(_Event? event, {required bool cancelled}) {
    final target = event?.currentTarget;
    final track = target == null ? null : _pointerTracks[target];
    if (event == null || track == null) return;
    if (track.pointer != (event.pointerId ?? 0)) return;
    final callbacks = current(event);
    _pointerTracks[target!] = null;
    track.longPressTimer?.cancel();
    final (global, local) = _pointerPositions(event);
    if (track.dragging case final axis?) {
      final drag = callbacks.drags[axis];
      if (cancelled) {
        drag?.onCancel?.call();
      } else {
        final velocity = Velocity(
          pixelsPerSecond: switch (axis) {
            _DragAxis.free => track.velocity,
            _DragAxis.horizontal => Offset(track.velocity.dx, 0),
            _DragAxis.vertical => Offset(0, track.velocity.dy),
          },
        );
        drag?.onEnd?.call(
          DragEndDetails(
            velocity: velocity,
            primaryVelocity: switch (axis) {
              _DragAxis.free => null,
              _DragAxis.horizontal => velocity.pixelsPerSecond.dx,
              _DragAxis.vertical => velocity.pixelsPerSecond.dy,
            },
            globalPosition: global,
            localPosition: local,
          ),
        );
      }
    } else {
      for (final drag in callbacks.drags.values) {
        drag.onCancel?.call();
      }
    }
    if (track.longPressed) {
      callbacks.onLongPressEnd?.call(
        LongPressEndDetails(globalPosition: global, localPosition: local),
      );
    } else if (cancelled) {
      if (!track.suppressClick) cancelTap(callbacks);
    } else if (!track.suppressClick) {
      callbacks.onTapUp?.call(
        TapUpDetails(
          kind: track.kind,
          globalPosition: global,
          localPosition: local,
        ),
      );
    }
    if (track.suppressClick) _suppressedClicks[target] = true;
  }

  out.on('pointerup', (event) => finish(event, cancelled: false));
  out.on('pointercancel', (event) => finish(event, cancelled: true));
}

/// Nodes whose next click was claimed by a long press or drag.
final _suppressedClicks = Expando<bool>('suppressed click');

/// Whether a click on [event]'s target belongs to a claimed gesture.
bool _clickSuppressed(_Event? event) {
  final target = event?.currentTarget;
  if (target == null || _suppressedClicks[target] != true) return false;
  _suppressedClicks[target] = null;
  return true;
}

// ---------------------------------------------------------------------------
// Raw pointer events.

abstract class PointerEvent {
  const PointerEvent({
    this.pointer = 0,
    this.kind = PointerDeviceKind.touch,
    this.position = Offset.zero,
    Offset? localPosition,
    this.delta = Offset.zero,
    this.buttons = 0,
    this.timeStamp = Duration.zero,
  }) : localPosition = localPosition ?? position;
  final int pointer, buttons;
  final PointerDeviceKind kind;
  final Offset position, localPosition, delta;
  final Duration timeStamp;
  Offset get localDelta => delta;
}

class PointerDownEvent extends PointerEvent {
  const PointerDownEvent({
    super.pointer,
    super.kind,
    super.position,
    super.localPosition,
    super.buttons,
    super.timeStamp,
  });
}

class PointerMoveEvent extends PointerEvent {
  const PointerMoveEvent({
    super.pointer,
    super.kind,
    super.position,
    super.localPosition,
    super.delta,
    super.buttons,
    super.timeStamp,
  });
}

class PointerUpEvent extends PointerEvent {
  const PointerUpEvent({
    super.pointer,
    super.kind,
    super.position,
    super.localPosition,
    super.buttons,
    super.timeStamp,
  });
}

class PointerCancelEvent extends PointerEvent {
  const PointerCancelEvent({
    super.pointer,
    super.kind,
    super.position,
    super.localPosition,
    super.timeStamp,
  });
}

class PointerHoverEvent extends PointerEvent {
  const PointerHoverEvent({
    super.kind,
    super.position,
    super.localPosition,
    super.delta,
    super.timeStamp,
  });
}

abstract class PointerSignalEvent extends PointerEvent {
  const PointerSignalEvent({
    super.kind,
    super.position,
    super.localPosition,
    super.timeStamp,
  });
}

class PointerScrollEvent extends PointerSignalEvent {
  const PointerScrollEvent({
    super.kind = PointerDeviceKind.mouse,
    super.position,
    super.localPosition,
    super.timeStamp,
    this.scrollDelta = Offset.zero,
  });
  final Offset scrollDelta;
}

typedef PointerDownEventListener = void Function(PointerDownEvent event);
typedef PointerMoveEventListener = void Function(PointerMoveEvent event);
typedef PointerUpEventListener = void Function(PointerUpEvent event);
typedef PointerCancelEventListener = void Function(PointerCancelEvent event);
typedef PointerHoverEventListener = void Function(PointerHoverEvent event);
typedef PointerSignalEventListener = void Function(PointerSignalEvent event);

/// Last viewport position per node and pointer, for move deltas.
final _lastPointerPositions = Expando<Map<int, Offset>>('pointer positions');

/// Delivers DOM pointer and wheel events as Flutter pointer events. Wheel
/// events with an `onPointerSignal` handler do not scroll the page.
class Listener extends _DomWidget {
  const Listener({
    super.key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerHover,
    this.onPointerCancel,
    this.onPointerSignal,
    this.behavior = HitTestBehavior.deferToChild,
    this.child,
  });
  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerHoverEventListener? onPointerHover;
  final PointerCancelEventListener? onPointerCancel;
  final PointerSignalEventListener? onPointerSignal;
  final HitTestBehavior behavior;
  final Widget? child;

  @override
  void _render(_DomBuilder out) {
    out.css(
      'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;min-height:0;',
    );
    Duration stamp(_Event event) =>
        Duration(microseconds: ((event.timeStamp ?? 0) * 1000).round());
    Offset move(_Event event, Offset global, {bool end = false}) {
      final target = event.currentTarget;
      if (target == null) return Offset.zero;
      final last = _lastPointerPositions[target] ??= {};
      final id = event.pointerId ?? 0;
      final previous = last[id];
      if (end) {
        last.remove(id);
      } else {
        last[id] = global;
      }
      return previous == null ? Offset.zero : global - previous;
    }

    if (onPointerDown != null || onPointerMove != null) {
      out.on('pointerdown', (event) {
        if (event == null) return;
        final (global, local) = _pointerPositions(event);
        move(event, global);
        onPointerDown?.call(
          PointerDownEvent(
            pointer: event.pointerId ?? 0,
            kind: _pointerKind(event.pointerType),
            position: global,
            localPosition: local,
            buttons: event.buttons ?? 0,
            timeStamp: stamp(event),
          ),
        );
      });
    }
    if (onPointerMove != null || onPointerHover != null) {
      out.on('pointermove', (event) {
        if (event == null) return;
        final (global, local) = _pointerPositions(event);
        final delta = move(event, global);
        if ((event.buttons ?? 0) == 0 && event.pointerType == 'mouse') {
          onPointerHover?.call(
            PointerHoverEvent(
              kind: PointerDeviceKind.mouse,
              position: global,
              localPosition: local,
              delta: delta,
              timeStamp: stamp(event),
            ),
          );
          return;
        }
        onPointerMove?.call(
          PointerMoveEvent(
            pointer: event.pointerId ?? 0,
            kind: _pointerKind(event.pointerType),
            position: global,
            localPosition: local,
            delta: delta,
            buttons: event.buttons ?? 0,
            timeStamp: stamp(event),
          ),
        );
      });
    }
    if (onPointerUp != null || onPointerMove != null) {
      out.on('pointerup', (event) {
        if (event == null) return;
        final (global, local) = _pointerPositions(event);
        move(event, global, end: true);
        onPointerUp?.call(
          PointerUpEvent(
            pointer: event.pointerId ?? 0,
            kind: _pointerKind(event.pointerType),
            position: global,
            localPosition: local,
            timeStamp: stamp(event),
          ),
        );
      });
    }
    if (onPointerCancel != null || onPointerMove != null) {
      out.on('pointercancel', (event) {
        if (event == null) return;
        final (global, local) = _pointerPositions(event);
        move(event, global, end: true);
        onPointerCancel?.call(
          PointerCancelEvent(
            pointer: event.pointerId ?? 0,
            kind: _pointerKind(event.pointerType),
            position: global,
            localPosition: local,
            timeStamp: stamp(event),
          ),
        );
      });
    }
    if (onPointerSignal != null) {
      out.on('wheel', (event) {
        if (event == null) return;
        event.preventDefault();
        final (global, local) = _pointerPositions(event);
        // Line and page deltas are scaled to pixels as browsers do.
        final scale = switch (event.deltaMode ?? 0) {
          1 => 16.0,
          2 => 400.0,
          _ => 1.0,
        };
        onPointerSignal!(
          PointerScrollEvent(
            position: global,
            localPosition: local,
            timeStamp: stamp(event),
            scrollDelta: Offset(
              (event.deltaX ?? 0) * scale,
              (event.deltaY ?? 0) * scale,
            ),
          ),
        );
      });
    }
    if (child != null) out.child(child!);
  }
}

enum DragStartBehavior { down, start }
