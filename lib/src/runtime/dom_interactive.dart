part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Animated lists.

typedef AnimatedItemBuilder =
    Widget Function(
      BuildContext context,
      int index,
      Animation<double> animation,
    );
typedef AnimatedRemovedItemBuilder =
    Widget Function(BuildContext context, Animation<double> animation);

class _AnimatedItem {
  _AnimatedItem(this.key, this.controller);
  final ValueKey<int> key;
  final AnimationController? controller;
  AnimatedRemovedItemBuilder? removedBuilder;
}

class AnimatedList extends StatefulWidget {
  const AnimatedList({
    super.key,
    required this.itemBuilder,
    this.initialItemCount = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.clipBehavior = Clip.hardEdge,
  });
  final AnimatedItemBuilder itemBuilder;
  final int initialItemCount;
  final Axis scrollDirection;
  final bool reverse, shrinkWrap;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  static AnimatedListState of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No AnimatedList ancestor in this context.'));
  static AnimatedListState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<AnimatedListState>();

  @override
  State<AnimatedList> createState() => AnimatedListState();
}

class AnimatedListState extends State<AnimatedList>
    with TickerProviderStateMixin {
  late final List<_AnimatedItem> _items = [
    for (var i = 0; i < widget.initialItemCount; i++)
      _AnimatedItem(ValueKey(_nextKey++), null),
  ];
  int _nextKey = 0;

  /// Indices visible to the item builder skip items being removed.
  int _visibleIndex(int listIndex) {
    var index = 0;
    for (var i = 0; i < listIndex; i++) {
      if (_items[i].removedBuilder == null) index++;
    }
    return index;
  }

  int _listIndex(int visibleIndex) {
    var index = 0;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].removedBuilder != null) continue;
      if (index == visibleIndex) return i;
      index++;
    }
    return _items.length;
  }

  void insertItem(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final controller = AnimationController(vsync: this, duration: duration);
    final item = _AnimatedItem(ValueKey(_nextKey++), controller);
    setState(() => _items.insert(_listIndex(index), item));
    controller.forward().whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  void insertAllItems(
    int index,
    int length, {
    Duration duration = const Duration(milliseconds: 300),
    bool isAsync = false,
  }) {
    for (var i = 0; i < length; i++) {
      insertItem(index + i, duration: duration);
    }
  }

  void removeItem(
    int index,
    AnimatedRemovedItemBuilder builder, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final listIndex = _listIndex(index);
    if (listIndex >= _items.length) return;
    final old = _items[listIndex];
    final controller = AnimationController(
      vsync: this,
      duration: duration,
      value: 1,
    );
    final item = _AnimatedItem(old.key, controller)..removedBuilder = builder;
    setState(() => _items[listIndex] = item);
    controller.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() => _items.remove(item));
      controller.dispose();
    });
  }

  void removeAllItems(
    AnimatedRemovedItemBuilder builder, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final count = _items.where((item) => item.removedBuilder == null).length;
    for (var i = count - 1; i >= 0; i--) {
      removeItem(i, builder, duration: duration);
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Scrollable(
    axis: widget.scrollDirection,
    padding: widget.padding,
    scrolls: widget.physics is! NeverScrollableScrollPhysics,
    controller: widget.controller,
    reverse: widget.reverse,
    children: [
      for (var i = 0; i < _items.length; i++)
        KeyedSubtree(
          key: _items[i].key,
          child: _items[i].removedBuilder != null
              ? _items[i].removedBuilder!(context, _items[i].controller!)
              : widget.itemBuilder(
                  context,
                  _visibleIndex(i),
                  _items[i].controller ?? kAlwaysCompleteAnimation,
                ),
        ),
    ],
  );
}

class SliverAnimatedList extends AnimatedList {
  const SliverAnimatedList({
    super.key,
    required super.itemBuilder,
    super.initialItemCount,
  }) : super(physics: const NeverScrollableScrollPhysics());
}

// ---------------------------------------------------------------------------
// Wheel lists: a snapping list of fixed-extent items.

class FixedExtentScrollController extends ScrollController {
  FixedExtentScrollController({this.initialItem = 0, super.onAttach});
  final int initialItem;
  double _itemExtent = 1;
  int get selectedItem => hasClients && _itemExtent > 0
      ? (offset / _itemExtent).round()
      : initialItem;
  void jumpToItem(int itemIndex) => jumpTo(itemIndex * _itemExtent);
  Future<void> animateToItem(
    int itemIndex, {
    required Duration duration,
    required Curve curve,
  }) => animateTo(itemIndex * _itemExtent, duration: duration, curve: curve);
}

abstract class ListWheelChildDelegate {
  Widget? build(BuildContext context, int index);
  int? get estimatedChildCount;
}

class ListWheelChildListDelegate extends ListWheelChildDelegate {
  ListWheelChildListDelegate({required this.children});
  final List<Widget> children;
  @override
  Widget? build(BuildContext context, int index) =>
      index < children.length ? children[index] : null;
  @override
  int? get estimatedChildCount => children.length;
}

class ListWheelChildBuilderDelegate extends ListWheelChildDelegate {
  ListWheelChildBuilderDelegate({required this.builder, this.childCount});
  final NullableIndexedWidgetBuilder builder;
  final int? childCount;
  @override
  Widget? build(BuildContext context, int index) =>
      childCount != null && index >= childCount!
      ? null
      : builder(context, index);
  @override
  int? get estimatedChildCount => childCount;
}

/// Items snap to the center of a bounded viewport; the 3D wheel effect is
/// not drawn.
class ListWheelScrollView extends StatefulWidget {
  ListWheelScrollView({
    super.key,
    this.controller,
    this.physics,
    this.diameterRatio = 2,
    this.perspective = 0.003,
    this.offAxisFraction = 0,
    this.useMagnifier = false,
    this.magnification = 1,
    this.overAndUnderCenterOpacity = 1,
    required this.itemExtent,
    this.squeeze = 1,
    this.onSelectedItemChanged,
    this.renderChildrenOutsideViewport = false,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.restorationId,
    this.scrollBehavior,
    this.dragStartBehavior,
    required List<Widget> children,
  }) : childDelegate = ListWheelChildListDelegate(children: children);
  const ListWheelScrollView.useDelegate({
    super.key,
    this.controller,
    this.physics,
    this.diameterRatio = 2,
    this.perspective = 0.003,
    this.offAxisFraction = 0,
    this.useMagnifier = false,
    this.magnification = 1,
    this.overAndUnderCenterOpacity = 1,
    required this.itemExtent,
    this.squeeze = 1,
    this.onSelectedItemChanged,
    this.renderChildrenOutsideViewport = false,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.restorationId,
    this.scrollBehavior,
    this.dragStartBehavior,
    required this.childDelegate,
  });
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double diameterRatio, perspective, offAxisFraction, magnification;
  final double overAndUnderCenterOpacity, itemExtent, squeeze;
  final bool useMagnifier, renderChildrenOutsideViewport;
  final ValueChanged<int>? onSelectedItemChanged;
  final Clip clipBehavior;
  final HitTestBehavior hitTestBehavior;
  final String? restorationId;
  final ScrollBehavior? scrollBehavior;
  final Object? dragStartBehavior;
  final ListWheelChildDelegate childDelegate;
  @override
  State<ListWheelScrollView> createState() => _ListWheelScrollViewState();
}

class _ListWheelScrollViewState extends State<ListWheelScrollView> {
  late final ScrollController _controller =
      widget.controller ?? FixedExtentScrollController();
  int? _selected;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    final controller = _controller;
    if (controller is FixedExtentScrollController) {
      controller._itemExtent = widget.itemExtent;
      if (controller.initialItem > 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => controller.jumpToItem(controller.initialItem),
        );
      }
    }
  }

  void _changed() {
    if (!_controller.hasClients) return;
    final item = (_controller.offset / widget.itemExtent).round();
    if (item != _selected) {
      _selected = item;
      widget.onSelectedItemChanged?.call(item);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; ; i++) {
      if (i >= _eagerItemLimit) {
        throw ArgumentError('Wheel item count exceeds the native limit.');
      }
      final child = widget.childDelegate.build(context, i);
      if (child == null) break;
      children.add(child);
    }
    return _Box(
      css:
          'display:flex;flex-direction:column;height:100%;min-height:${px(widget.itemExtent)};overflow-y:auto;scroll-snap-type:y mandatory;scrollbar-width:none;',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        _Scrollable(
          axis: Axis.vertical,
          padding: null,
          scrolls: widget.physics is! NeverScrollableScrollPhysics,
          controller: _controller,
          pageFraction: 0,
          children: [
            // Half-viewport spacers let the first and last items center.
            const SizedBox(key: ValueKey('start'), height: 0),
            for (final (index, child) in children.indexed)
              SizedBox(
                key: child.key ?? ValueKey(index),
                height: widget.itemExtent,
                child: Center(child: child),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dismissible.

enum DismissDirection {
  vertical,
  horizontal,
  endToStart,
  startToEnd,
  up,
  down,
  none,
}

typedef ConfirmDismissCallback =
    Future<bool?> Function(DismissDirection direction);
typedef DismissDirectionCallback = void Function(DismissDirection direction);
typedef DismissUpdateCallback = void Function(DismissUpdateDetails details);

class DismissUpdateDetails {
  DismissUpdateDetails({
    this.direction = DismissDirection.horizontal,
    this.reached = false,
    this.previousReached = false,
    this.progress = 0,
  });
  final DismissDirection direction;
  final bool reached, previousReached;
  final double progress;
}

class Dismissible extends StatefulWidget {
  const Dismissible({
    required Key super.key,
    required this.child,
    this.background,
    this.secondaryBackground,
    this.confirmDismiss,
    this.onResize,
    this.onUpdate,
    this.onDismissed,
    this.direction = DismissDirection.horizontal,
    this.resizeDuration = const Duration(milliseconds: 300),
    this.dismissThresholds = const {},
    this.movementDuration = const Duration(milliseconds: 200),
    this.crossAxisEndOffset = 0,
    this.dragStartBehavior,
    this.behavior = HitTestBehavior.opaque,
  });
  final Widget child;
  final Widget? background, secondaryBackground;
  final ConfirmDismissCallback? confirmDismiss;
  final VoidCallback? onResize;
  final DismissUpdateCallback? onUpdate;
  final DismissDirectionCallback? onDismissed;
  final DismissDirection direction;
  final Duration? resizeDuration;
  final Map<DismissDirection, double> dismissThresholds;
  final Duration movementDuration;
  final double crossAxisEndOffset;
  final Object? dragStartBehavior;
  final HitTestBehavior behavior;
  @override
  State<Dismissible> createState() => _DismissibleState();
}

class _DismissibleState extends State<Dismissible> {
  double _drag = 0;
  bool _animating = false, _dismissed = false, _resized = false;
  bool _reached = false;

  bool get _vertical =>
      widget.direction == DismissDirection.vertical ||
      widget.direction == DismissDirection.up ||
      widget.direction == DismissDirection.down;

  double get _extent {
    final node = _liveNode(context);
    final box = node == null ? null : _clientRect(node);
    return (_vertical ? box?.height : box?.width) ?? 0;
  }

  DismissDirection _directionFor(double drag) => _vertical
      ? (drag < 0 ? DismissDirection.up : DismissDirection.down)
      : (drag < 0 ? DismissDirection.endToStart : DismissDirection.startToEnd);

  bool _allowed(double drag) => switch (widget.direction) {
    DismissDirection.horizontal || DismissDirection.vertical => true,
    DismissDirection.endToStart || DismissDirection.up => drag < 0,
    DismissDirection.startToEnd || DismissDirection.down => drag > 0,
    DismissDirection.none => false,
  };

  void _update(double delta) {
    if (_animating || _dismissed) return;
    var next = _drag + delta;
    if (!_allowed(next)) next = 0;
    final extent = _extent;
    final direction = _directionFor(next);
    final threshold = widget.dismissThresholds[direction] ?? 0.4;
    final progress = extent <= 0 ? 0.0 : (next.abs() / extent).clamp(0.0, 1.0);
    final reached = progress >= threshold;
    widget.onUpdate?.call(
      DismissUpdateDetails(
        direction: direction,
        reached: reached,
        previousReached: _reached,
        progress: progress,
      ),
    );
    _reached = reached;
    setState(() => _drag = next);
  }

  Future<void> _end(double velocity) async {
    if (_animating || _dismissed || _drag == 0) return;
    final direction = _directionFor(_drag);
    final extent = _extent;
    final threshold = widget.dismissThresholds[direction] ?? 0.4;
    final fling = velocity.abs() > 700 && velocity.sign == _drag.sign;
    if (!(fling || (extent > 0 && _drag.abs() / extent >= threshold))) {
      setState(() => _drag = 0);
      return;
    }
    _animating = true;
    final confirmed =
        await (widget.confirmDismiss?.call(direction) ??
            Future<bool?>.value(true));
    if (!mounted) return;
    if (confirmed != true) {
      setState(() {
        _animating = false;
        _drag = 0;
      });
      return;
    }
    setState(() => _drag = _drag.sign * math.max(extent, 1));
    await Future<void>.delayed(widget.movementDuration);
    if (!mounted) return;
    if (widget.resizeDuration == null) {
      _dismissed = true;
      widget.onDismissed?.call(direction);
      return;
    }
    setState(() => _resized = true);
    widget.onResize?.call();
    await Future<void>.delayed(widget.resizeDuration!);
    if (!mounted) return;
    _dismissed = true;
    widget.onDismissed?.call(direction);
  }

  @override
  Widget build(BuildContext context) {
    final background = _drag < 0 && widget.secondaryBackground != null
        ? widget.secondaryBackground
        : widget.background;
    final offset = _vertical
        ? 'translateY(${px(_drag)})'
        : 'translateX(${px(_drag)})';
    final duration = _animating ? widget.movementDuration.inMilliseconds : 0;
    final content = _Box(
      css:
          'position:relative;display:grid;grid-template-columns:minmax(0,1fr);overflow:hidden;${_resized ? '${_vertical ? 'max-width' : 'max-height'}:0;transition:max-height ${widget.resizeDuration?.inMilliseconds ?? 0}ms,max-width ${widget.resizeDuration?.inMilliseconds ?? 0}ms;' : ''}',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [
        if (background != null && _drag != 0)
          _Box(
            css: 'position:absolute;inset:0;display:grid;',
            layout: _DomLayout.grid,
            fill: _Fill.expand,
            children: [background],
          ),
        _Box(
          css:
              'position:relative;display:grid;grid-template-columns:minmax(0,1fr);transform:$offset;transition:transform ${duration}ms ease-out;',
          layout: _DomLayout.grid,
          fill: _Fill.expand,
          children: [widget.child],
        ),
      ],
    );
    if (widget.direction == DismissDirection.none) return content;
    return _vertical
        ? GestureDetector(
            onVerticalDragUpdate: (d) => _update(d.primaryDelta ?? 0),
            onVerticalDragEnd: (d) => _end(d.primaryVelocity ?? 0),
            child: content,
          )
        : GestureDetector(
            onHorizontalDragUpdate: (d) => _update(d.primaryDelta ?? 0),
            onHorizontalDragEnd: (d) => _end(d.primaryVelocity ?? 0),
            child: content,
          );
  }
}

// ---------------------------------------------------------------------------
// Drag and drop.

class DraggableDetails {
  DraggableDetails({
    this.wasAccepted = false,
    required this.velocity,
    required this.offset,
  });
  final bool wasAccepted;
  final Velocity velocity;
  final Offset offset;
}

class DragTargetDetails<T> {
  DragTargetDetails({required this.data, required this.offset});
  final T data;
  final Offset offset;
}

enum DragAnchor { child, pointer }

typedef DragAnchorStrategy =
    Offset Function(
      Draggable<Object> draggable,
      BuildContext context,
      Offset position,
    );

Offset childDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) {
  final node = _liveNode(context);
  final box = node == null ? null : _clientRect(node);
  return box == null ? Offset.zero : position - box.topLeft;
}

Offset pointerDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) => Offset.zero;

typedef DragTargetWillAcceptWithDetails<T> =
    bool Function(DragTargetDetails<T> details);
typedef DragTargetAcceptWithDetails<T> =
    void Function(DragTargetDetails<T> details);
typedef DragTargetLeave<T> = void Function(T? data);
typedef DragTargetMove<T> = void Function(DragTargetDetails<T> details);
typedef DragTargetBuilder<T> =
    Widget Function(
      BuildContext context,
      List<T?> candidateData,
      List<dynamic> rejectedData,
    );
typedef DraggableCanceledCallback =
    void Function(Velocity velocity, Offset offset);
typedef DragEndCallback = void Function(DraggableDetails details);

/// DOM nodes of mounted drag targets.
final _dragTargets = Expando<_DragTargetState<Object>>('drag target');

class Draggable<T extends Object> extends StatefulWidget {
  const Draggable({
    super.key,
    required this.child,
    required this.feedback,
    this.data,
    this.axis,
    this.childWhenDragging,
    this.feedbackOffset = Offset.zero,
    this.dragAnchorStrategy = childDragAnchorStrategy,
    this.affinity,
    this.maxSimultaneousDrags,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.ignoringFeedbackSemantics = true,
    this.ignoringFeedbackPointer = true,
    this.rootOverlay = false,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
    this.allowedButtonsFilter,
  }) : _delay = null;
  const Draggable._delayed({
    super.key,
    required this.child,
    required this.feedback,
    this.data,
    this.axis,
    this.childWhenDragging,
    this.feedbackOffset = Offset.zero,
    this.dragAnchorStrategy = childDragAnchorStrategy,
    this.maxSimultaneousDrags,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.ignoringFeedbackSemantics = true,
    this.ignoringFeedbackPointer = true,
    this.rootOverlay = false,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
    this.allowedButtonsFilter,
    required Duration delay,
  }) : affinity = null,
       _delay = delay;
  final Widget child, feedback;
  final T? data;
  final Axis? axis, affinity;
  final Widget? childWhenDragging;
  final Offset feedbackOffset;
  final DragAnchorStrategy dragAnchorStrategy;
  final int? maxSimultaneousDrags;
  final VoidCallback? onDragStarted;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;
  final DraggableCanceledCallback? onDraggableCanceled;
  final DragEndCallback? onDragEnd;
  final VoidCallback? onDragCompleted;
  final bool ignoringFeedbackSemantics, ignoringFeedbackPointer, rootOverlay;
  final HitTestBehavior hitTestBehavior;
  final bool Function(int buttons)? allowedButtonsFilter;
  final Duration? _delay;
  @override
  State<Draggable<T>> createState() => _DraggableState<T>();
}

class LongPressDraggable<T extends Object> extends Draggable<T> {
  const LongPressDraggable({
    super.key,
    required super.child,
    required super.feedback,
    super.data,
    super.axis,
    super.childWhenDragging,
    super.feedbackOffset,
    super.dragAnchorStrategy,
    super.maxSimultaneousDrags,
    super.onDragStarted,
    super.onDragUpdate,
    super.onDraggableCanceled,
    super.onDragEnd,
    super.onDragCompleted,
    this.hapticFeedbackOnStart = true,
    super.ignoringFeedbackSemantics,
    super.ignoringFeedbackPointer,
    this.delay = kLongPressTimeout,
    super.allowedButtonsFilter,
    super.hitTestBehavior,
    super.rootOverlay,
  }) : super._delayed(delay: delay);
  final bool hapticFeedbackOnStart;
  final Duration delay;
}

class _DraggableState<T extends Object> extends State<Draggable<T>> {
  Offset? _start, _position, _anchor;
  double _lastTime = 0;
  Offset _velocity = Offset.zero;
  bool _dragging = false;
  Timer? _delay;
  JSFunction? _move, _up;
  _DragTargetState<Object>? _over;

  void _down(PointerDownEvent event) {
    if (_dragging) return;
    _start = event.position;
    _listen();
    final delay = widget._delay;
    if (delay != null) {
      _delay = Timer(delay, () => _begin(_start!));
    }
  }

  void _listen() {
    _move ??= ((JSObject event) {
      final position = Offset(
        _jsNumber(event, 'clientX'),
        _jsNumber(event, 'clientY'),
      );
      final time = _jsNumber(event, 'timeStamp');
      _moved(position, time);
      if (_dragging) event.callMethod<JSAny?>('preventDefault'.toJS);
    }).toJS;
    _up ??= ((JSAny? _) => _finish()).toJS;
    _window.addEventListener('pointermove', _move!);
    _window.addEventListener('pointerup', _up!);
    _window.addEventListener('pointercancel', _up!);
  }

  void _unlisten() {
    if (_move != null) _window.removeEventListener('pointermove', _move!);
    if (_up != null) {
      _window.removeEventListener('pointerup', _up!);
      _window.removeEventListener('pointercancel', _up!);
    }
  }

  void _begin(Offset position) {
    if (!mounted || _dragging) return;
    _anchor = widget.dragAnchorStrategy(
      widget as Draggable<Object>,
      context,
      position,
    );
    setState(() {
      _dragging = true;
      _position = position;
    });
    widget.onDragStarted?.call();
  }

  void _moved(Offset position, double time) {
    final start = _start;
    if (start == null) return;
    if (!_dragging) {
      if ((position - start).distance <= kTouchSlop) return;
      if (widget._delay != null) {
        // Moving before the long press completes cancels it.
        _delay?.cancel();
        _cancel();
        return;
      }
      _begin(start);
    }
    var next = position;
    if (widget.axis == Axis.horizontal) next = Offset(position.dx, start.dy);
    if (widget.axis == Axis.vertical) next = Offset(start.dx, position.dy);
    final previous = _position ?? next;
    if (time > _lastTime && _lastTime > 0) {
      _velocity = (next - previous) / ((time - _lastTime) / 1000);
    }
    _lastTime = time;
    setState(() => _position = next);
    widget.onDragUpdate?.call(
      DragUpdateDetails(
        delta: next - previous,
        globalPosition: next,
        localPosition: next,
      ),
    );
    _hover(next);
  }

  _DragTargetState<Object>? _targetAt(Offset position) {
    final document = _document as JSObject;
    if (!document.has('elementFromPoint')) return null;
    var node = document.callMethod<JSObject?>(
      'elementFromPoint'.toJS,
      position.dx.toJS,
      position.dy.toJS,
    );
    while (node != null) {
      final target = _dragTargets[node];
      if (target != null && target.mounted) return target;
      node = node.getProperty<JSObject?>('parentElement'.toJS);
    }
    return null;
  }

  void _hover(Offset position) {
    final target = _targetAt(position);
    if (!identical(target, _over)) {
      _over?._leave(widget.data);
      _over = target;
      target?._enter(widget.data, position);
    } else {
      target?._moveOver(widget.data, position);
    }
  }

  void _finish() {
    _delay?.cancel();
    _unlisten();
    if (!_dragging) {
      _start = null;
      return;
    }
    final position = _position ?? Offset.zero;
    final feedback =
        position - (_anchor ?? Offset.zero) + widget.feedbackOffset;
    final target = _over;
    final accepted = target != null && target._drop(widget.data, feedback);
    final velocity = Velocity(pixelsPerSecond: _velocity);
    if (accepted) {
      widget.onDragCompleted?.call();
    } else {
      widget.onDraggableCanceled?.call(velocity, feedback);
    }
    widget.onDragEnd?.call(
      DraggableDetails(
        wasAccepted: accepted,
        velocity: velocity,
        offset: feedback,
      ),
    );
    _cancel();
  }

  void _cancel() {
    _unlisten();
    _over = null;
    _start = null;
    _lastTime = 0;
    if (mounted && _dragging) {
      setState(() {
        _dragging = false;
        _position = null;
      });
    }
    _dragging = false;
  }

  @override
  void dispose() {
    _delay?.cancel();
    _unlisten();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final feedback = position == null
        ? Offset.zero
        : position - (_anchor ?? Offset.zero) + widget.feedbackOffset;
    return Listener(
      onPointerDown: _down,
      child: _Box(
        css:
            'display:grid;grid-template-columns:minmax(0,1fr);touch-action:none;',
        layout: _DomLayout.grid,
        fill: _Fill.child,
        children: [
          if (_dragging)
            widget.childWhenDragging ?? widget.child
          else
            widget.child,
          if (_dragging)
            _Box(
              css:
                  'position:fixed;left:${px(feedback.dx)};top:${px(feedback.dy)};z-index:1000;${widget.ignoringFeedbackPointer ? 'pointer-events:none;' : ''}',
              attributes: {
                if (widget.ignoringFeedbackSemantics) 'aria-hidden': 'true',
              },
              fill: _Fill.none,
              children: [widget.feedback],
            ),
        ],
      ),
    );
  }
}

class DragTarget<T extends Object> extends StatefulWidget {
  const DragTarget({
    super.key,
    required this.builder,
    this.onWillAcceptWithDetails,
    this.onAcceptWithDetails,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
  });
  final DragTargetBuilder<T> builder;
  final DragTargetWillAcceptWithDetails<T>? onWillAcceptWithDetails;
  final DragTargetAcceptWithDetails<T>? onAcceptWithDetails;
  final DragTargetLeave<T>? onLeave;
  final DragTargetMove<T>? onMove;
  final HitTestBehavior hitTestBehavior;
  @override
  State<DragTarget<T>> createState() => _DragTargetState<T>();
}

class _DragTargetState<T extends Object> extends State<DragTarget<T>> {
  final _candidates = <T?>[];
  final _rejected = <Object?>[];

  bool _accepts(Object? data, Offset position) {
    if (data is! T?) return false;
    final check = widget.onWillAcceptWithDetails;
    if (data == null) return check == null;
    return check?.call(DragTargetDetails<T>(data: data, offset: position)) ??
        true;
  }

  void _enter(Object? data, Offset position) {
    setState(() {
      if (_accepts(data, position)) {
        _candidates.add(data as T?);
      } else {
        _rejected.add(data);
      }
    });
    _moveOver(data, position);
  }

  void _moveOver(Object? data, Offset position) {
    if (data is T) {
      widget.onMove?.call(DragTargetDetails<T>(data: data, offset: position));
    }
  }

  void _leave(Object? data) {
    if (!mounted) return;
    setState(() {
      _candidates.remove(data);
      _rejected.remove(data);
    });
    widget.onLeave?.call(data is T ? data : null);
  }

  bool _drop(Object? data, Offset offset) {
    final accepted = _candidates.contains(data);
    setState(() {
      _candidates.remove(data);
      _rejected.remove(data);
    });
    if (accepted && data is T) {
      widget.onAcceptWithDetails?.call(
        DragTargetDetails<T>(data: data, offset: offset),
      );
    }
    return accepted;
  }

  @override
  Widget build(BuildContext context) => _DragTargetBox(
    state: this as _DragTargetState<Object>,
    child: widget.builder(
      context,
      List.unmodifiable(_candidates),
      List.unmodifiable(_rejected),
    ),
  );
}

class _DragTargetBox extends _DomWidget {
  const _DragTargetBox({required this.state, required this.child});
  final _DragTargetState<Object> state;
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('display:grid;grid-template-columns:minmax(0,1fr);min-width:0;');
    _dragTargets[out.context.node as JSObject] = state;
    out.child(child);
  }
}

// ---------------------------------------------------------------------------
// Interactive viewer: pan by dragging, zoom with the wheel (around the
// pointer); the transformation applies as a CSS matrix.

class TransformationController extends ValueNotifier<Matrix4> {
  TransformationController([Matrix4? value])
    : super(value ?? Matrix4.identity());

  Offset toScene(Offset viewportPoint) {
    final inverse = Matrix4.inverted(value);
    final v = inverse.transform3(
      Vector3(viewportPoint.dx, viewportPoint.dy, 0),
    );
    return Offset(v.x, v.y);
  }
}

class ScaleStartDetails {
  ScaleStartDetails({
    this.focalPoint = Offset.zero,
    Offset? localFocalPoint,
    this.pointerCount = 0,
  }) : localFocalPoint = localFocalPoint ?? focalPoint;
  final Offset focalPoint, localFocalPoint;
  final int pointerCount;
}

class ScaleUpdateDetails {
  ScaleUpdateDetails({
    this.focalPoint = Offset.zero,
    Offset? localFocalPoint,
    this.scale = 1,
    this.horizontalScale = 1,
    this.verticalScale = 1,
    this.rotation = 0,
    this.pointerCount = 0,
    this.focalPointDelta = Offset.zero,
  }) : localFocalPoint = localFocalPoint ?? focalPoint;
  final Offset focalPoint, localFocalPoint, focalPointDelta;
  final double scale, horizontalScale, verticalScale, rotation;
  final int pointerCount;
}

class ScaleEndDetails {
  ScaleEndDetails({
    this.velocity = Velocity.zero,
    this.scaleVelocity = 0,
    this.pointerCount = 0,
  });
  final Velocity velocity;
  final double scaleVelocity;
  final int pointerCount;
}

class InteractiveViewer extends StatefulWidget {
  const InteractiveViewer({
    super.key,
    this.clipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boundaryMargin = EdgeInsets.zero,
    this.constrained = true,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.interactionEndFrictionCoefficient = 0.0000135,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.scaleFactor = 200,
    this.transformationController,
    this.alignment,
    this.trackpadScrollCausesScale = false,
    required this.child,
  });
  final Clip clipBehavior;
  final PanAxis panAxis;
  final EdgeInsets boundaryMargin;
  final bool constrained, panEnabled, scaleEnabled, trackpadScrollCausesScale;
  final double maxScale, minScale, interactionEndFrictionCoefficient;
  final double scaleFactor;
  final GestureScaleEndCallback? onInteractionEnd;
  final GestureScaleStartCallback? onInteractionStart;
  final GestureScaleUpdateCallback? onInteractionUpdate;
  final TransformationController? transformationController;
  final Alignment? alignment;
  final Widget child;
  @override
  State<InteractiveViewer> createState() => _InteractiveViewerState();
}

enum PanAxis { horizontal, vertical, aligned, free }

typedef GestureScaleStartCallback = void Function(ScaleStartDetails details);
typedef GestureScaleUpdateCallback = void Function(ScaleUpdateDetails details);
typedef GestureScaleEndCallback = void Function(ScaleEndDetails details);

class _InteractiveViewerState extends State<InteractiveViewer> {
  TransformationController? _own;
  TransformationController get _controller =>
      widget.transformationController ?? (_own ??= TransformationController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(InteractiveViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      (oldWidget.transformationController ?? _own)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  double get _scale => _controller.value.getMaxScaleOnAxis();

  void _pan(Offset delta) {
    var d = delta;
    if (widget.panAxis == PanAxis.horizontal) d = Offset(delta.dx, 0);
    if (widget.panAxis == PanAxis.vertical) d = Offset(0, delta.dy);
    _controller.value = Matrix4.translationValues(d.dx, d.dy, 0)
      ..multiply(_controller.value);
  }

  void _zoom(double factor, Offset focal) {
    final current = _scale;
    final target = (current * factor).clamp(widget.minScale, widget.maxScale);
    final applied = target / current;
    if (applied == 1) return;
    _controller.value = Matrix4.translationValues(focal.dx, focal.dy, 0)
      ..multiply(Matrix4.diagonal3Values(applied, applied, 1))
      ..multiply(Matrix4.translationValues(-focal.dx, -focal.dy, 0))
      ..multiply(_controller.value);
  }

  @override
  Widget build(BuildContext context) {
    final m = _controller.value.storage;
    final matrix = [for (final v in m) cssNumber(v)].join(',');
    Widget result = _Box(
      css:
          'display:grid;grid-template-columns:minmax(0,1fr);transform-origin:0 0;transform:matrix3d($matrix);',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [widget.child],
    );
    result = GestureDetector(
      onPanStart: widget.panEnabled
          ? (d) => widget.onInteractionStart?.call(
              ScaleStartDetails(
                focalPoint: d.globalPosition,
                localFocalPoint: d.localPosition,
                pointerCount: 1,
              ),
            )
          : null,
      onPanUpdate: widget.panEnabled
          ? (d) {
              _pan(d.delta);
              widget.onInteractionUpdate?.call(
                ScaleUpdateDetails(
                  focalPoint: d.globalPosition,
                  localFocalPoint: d.localPosition,
                  focalPointDelta: d.delta,
                  pointerCount: 1,
                ),
              );
            }
          : null,
      onPanEnd: widget.panEnabled
          ? (d) => widget.onInteractionEnd?.call(
              ScaleEndDetails(velocity: d.velocity, pointerCount: 0),
            )
          : null,
      child: result,
    );
    if (widget.scaleEnabled) {
      result = Listener(
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent) return;
          final factor = math.exp(-event.scrollDelta.dy / widget.scaleFactor);
          _zoom(factor, event.localPosition);
          widget.onInteractionUpdate?.call(
            ScaleUpdateDetails(
              focalPoint: event.position,
              localFocalPoint: event.localPosition,
              scale: factor,
              horizontalScale: factor,
              verticalScale: factor,
            ),
          );
        },
        child: result,
      );
    }
    return _Box(
      css:
          'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;${widget.clipBehavior == Clip.none ? '' : 'overflow:hidden;'}',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [result],
    );
  }
}

// ---------------------------------------------------------------------------
// Annotated regions and search.

class AnnotatedRegion<T extends Object> extends StatelessWidget {
  const AnnotatedRegion({
    super.key,
    required this.child,
    required this.value,
    this.sized = true,
  });
  final Widget child;
  final T value;
  final bool sized;
  @override
  Widget build(BuildContext context) => child;
}

abstract class SearchDelegate<T> {
  SearchDelegate({
    this.searchFieldLabel,
    this.searchFieldStyle,
    this.searchFieldDecorationTheme,
    this.keyboardType,
    this.textInputAction = TextInputAction.search,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });
  final String? searchFieldLabel;
  final TextStyle? searchFieldStyle;
  final Object? searchFieldDecorationTheme;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool autocorrect, enableSuggestions;

  Widget buildSuggestions(BuildContext context);
  Widget buildResults(BuildContext context);
  Widget? buildLeading(BuildContext context);
  List<Widget>? buildActions(BuildContext context);
  PreferredSizeWidget? buildBottom(BuildContext context) => null;
  Widget? buildFlexibleSpace(BuildContext context) => null;
  ThemeData appBarTheme(BuildContext context) => Theme.of(context);

  final _query = TextEditingController();
  _SearchPageState<T>? _page;

  String get query => _query.text;
  set query(String value) {
    _query.text = value;
    _page?._refresh();
  }

  void showResults(BuildContext context) => _page?._show(results: true);
  void showSuggestions(BuildContext context) => _page?._show(results: false);
  void close(BuildContext context, T result) =>
      Navigator.of(context).pop<T>(result);

  Animation<double> get transitionAnimation => kAlwaysCompleteAnimation;
}

Future<T?> showSearch<T>({
  required BuildContext context,
  required SearchDelegate<T> delegate,
  String? query = '',
  bool useRootNavigator = false,
  bool maintainState = false,
}) {
  delegate._query.text = query ?? '';
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    MaterialPageRoute<T>(builder: (context) => _SearchPage<T>(delegate)),
  );
}

class _SearchPage<T> extends StatefulWidget {
  const _SearchPage(this.delegate);
  final SearchDelegate<T> delegate;
  @override
  State<_SearchPage<T>> createState() => _SearchPageState<T>();
}

class _SearchPageState<T> extends State<_SearchPage<T>> {
  bool _results = false;

  @override
  void initState() {
    super.initState();
    widget.delegate._page = this;
    widget.delegate._query.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.delegate._query.removeListener(_refresh);
    if (identical(widget.delegate._page, this)) widget.delegate._page = null;
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _show({required bool results}) {
    if (mounted) setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    final delegate = widget.delegate;
    return Scaffold(
      appBar: AppBar(
        leading: delegate.buildLeading(context),
        title: TextField(
          controller: delegate._query,
          autofocus: true,
          keyboardType: delegate.keyboardType,
          textInputAction: delegate.textInputAction,
          style: delegate.searchFieldStyle,
          decoration: InputDecoration(
            hintText:
                delegate.searchFieldLabel ??
                MaterialLocalizations.of(context).searchFieldLabel,
            border: InputBorder.none,
          ),
          onChanged: (_) {
            if (_results) setState(() => _results = false);
          },
          onSubmitted: (_) => delegate.showResults(context),
        ),
        actions: delegate.buildActions(context),
        bottom: delegate.buildBottom(context),
      ),
      body: _results
          ? delegate.buildResults(context)
          : delegate.buildSuggestions(context),
    );
  }
}
