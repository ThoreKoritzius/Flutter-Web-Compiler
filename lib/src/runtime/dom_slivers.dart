part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Scroll positions and controllers.
//
// A vertical scroll view scrolls itself only when an ancestor bounds its
// height; otherwise it grows with its content and the page scrolls, as a
// document does. Each view measures which case applies after layout, and
// positions, controllers and pinned headers follow the element that
// actually scrolls.

enum ScrollDirection { idle, forward, reverse }

enum AxisDirection { up, right, down, left }

enum GrowthDirection { forward, reverse }

double _jsNumber(JSObject object, String name) =>
    object.getProperty<JSNumber?>(name.toJS)?.toDartDouble ?? 0;

JSObject? _liveNode(BuildContext context) {
  if (context is! Element || !context.mounted) return null;
  return context._domNode as JSObject;
}

Rect? _clientRect(JSObject node) {
  if (!node.has('getBoundingClientRect')) return null;
  final box = node.callMethod<JSObject>('getBoundingClientRect'.toJS);
  return Rect.fromLTWH(
    _jsNumber(box, 'left'),
    _jsNumber(box, 'top'),
    _jsNumber(box, 'width'),
    _jsNumber(box, 'height'),
  );
}

/// A pixel length from a CSS custom property inherited by [node].
double _cssPixels(JSObject node, String property) {
  final window = _window as JSObject;
  if (!window.has('getComputedStyle')) return 0;
  final style = window.callMethod<JSObject?>('getComputedStyle'.toJS, node);
  if (style == null || !style.has('getPropertyValue')) return 0;
  final value = style
      .callMethod<JSString?>('getPropertyValue'.toJS, property.toJS)
      ?.toDart
      .trim();
  return double.tryParse((value ?? '').replaceAll('px', '')) ?? 0;
}

class ScrollPosition extends ChangeNotifier {
  ScrollPosition._(this._view);
  final _ScrollableState _view;

  Axis get axis => _view.widget.axis;
  AxisDirection get axisDirection => axis == Axis.vertical
      ? (_view.widget.reverse ? AxisDirection.up : AxisDirection.down)
      : (_view.widget.reverse ? AxisDirection.left : AxisDirection.right);
  double get pixels => _view._offset();
  double get minScrollExtent => 0;
  double get maxScrollExtent => _view._maxExtent();
  double get viewportDimension => _view._viewportExtent();
  bool get hasPixels => true;
  bool get hasContentDimensions => true;
  bool get hasViewportDimension => true;
  bool get outOfRange => pixels < minScrollExtent || pixels > maxScrollExtent;
  bool get atEdge => pixels <= minScrollExtent || pixels >= maxScrollExtent;
  double get extentBefore => math.max(pixels - minScrollExtent, 0);
  double get extentAfter => math.max(maxScrollExtent - pixels, 0);
  double get extentInside => viewportDimension;
  double get extentTotal => maxScrollExtent + viewportDimension;
  ScrollDirection get userScrollDirection => _view._direction;
  final isScrollingNotifier = ValueNotifier<bool>(false);

  void jumpTo(double value) => _view._scrollTo(value, smooth: false);

  /// Uses the browser's smooth scrolling; [curve] is not applied.
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    _view._scrollTo(to, smooth: true);
    return Future<void>.delayed(duration);
  }

  void _changed() => notifyListeners();
}

class ScrollController extends ChangeNotifier {
  ScrollController({
    this.initialScrollOffset = 0,
    this.keepScrollOffset = true,
    this.debugLabel,
    this.onAttach,
    this.onDetach,
  });
  final double initialScrollOffset;
  final bool keepScrollOffset;
  final String? debugLabel;
  final void Function(ScrollPosition position)? onAttach, onDetach;
  final _positions = <ScrollPosition>[];

  Iterable<ScrollPosition> get positions => _positions;
  bool get hasClients => _positions.isNotEmpty;

  ScrollPosition get position {
    if (_positions.length != 1) {
      throw StateError(
        'ScrollController is attached to ${_positions.length} scroll views.',
      );
    }
    return _positions.single;
  }

  double get offset => position.pixels;

  void jumpTo(double value) {
    for (final position in List.of(_positions)) {
      position.jumpTo(value);
    }
  }

  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) => Future.wait([
    for (final position in List.of(_positions))
      position.animateTo(offset, duration: duration, curve: curve),
  ]);

  void attach(ScrollPosition position) {
    _positions.add(position);
    position.addListener(notifyListeners);
    onAttach?.call(position);
  }

  void detach(ScrollPosition position) {
    position.removeListener(notifyListeners);
    _positions.remove(position);
    onDetach?.call(position);
  }
}

/// Gives descendants (pinned headers, refresh indicators) the enclosing
/// scroll view.
class _ScrollScope extends InheritedWidget {
  const _ScrollScope({required this.view, required super.child});
  final _ScrollableState view;
  @override
  bool updateShouldNotify(_ScrollScope oldWidget) => oldWidget.view != view;

  static _ScrollableState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScrollScope>()?.view;
}

class _Scrollable extends StatefulWidget {
  const _Scrollable({
    required this.axis,
    required this.padding,
    required this.scrolls,
    required this.children,
    this.controller,
    this.reverse = false,
  });
  final Axis axis;
  final EdgeInsetsGeometry? padding;
  final bool scrolls, reverse;
  final List<Widget> children;
  final ScrollController? controller;
  @override
  State<_Scrollable> createState() => _ScrollableState();
}

class _ScrollableState extends State<_Scrollable> {
  late final position = ScrollPosition._(this);

  /// Whether this element scrolls itself (an ancestor bounds it); null until
  /// measured.
  bool? _ownScroll;
  JSObject? _listeningTo;
  JSFunction? _scrollListener;
  JSObject? _resizeObserver, _mutationObserver;
  ScrollDirection _direction = ScrollDirection.idle;
  double _lastOffset = 0;
  bool _initialApplied = false;
  Timer? _idle;

  bool get _vertical => widget.axis == Axis.vertical;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(position);
  }

  @override
  void didUpdateWidget(_Scrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(position);
      widget.controller?.attach(position);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(position);
    _stopListening();
    _resizeObserver?.callMethod<JSAny?>('disconnect'.toJS);
    _mutationObserver?.callMethod<JSAny?>('disconnect'.toJS);
    _idle?.cancel();
    super.dispose();
  }

  JSObject? get _node => _liveNode(context);

  /// Whether the scrolling element is this view rather than the page.
  bool get _scrollsItself => !_vertical || _ownScroll != false;

  void _measure() {
    if (!mounted) return;
    final node = _node;
    if (node == null) return;
    if (_vertical && widget.scrolls && node.has('scrollHeight')) {
      final client = _jsNumber(node, 'clientHeight');
      final content = _jsNumber(node, 'scrollHeight');
      // An unbounded view is exactly as tall as its content. A bounded one
      // either overflows or leaves room below its last child.
      var bounded = content > client + 1;
      final last = node.getProperty<JSObject?>('lastElementChild'.toJS);
      final box = _clientRect(node);
      final lastBox = last == null ? null : _clientRect(last);
      if (!bounded && box != null && lastBox != null) {
        bounded =
            lastBox.bottom <
            box.bottom - 1 - _cssPixels(node, 'padding-bottom');
      }
      if (bounded != _ownScroll) {
        setState(() => _ownScroll = bounded);
      }
    }
    _listen(node);
    _observe(node);
    if (!_initialApplied) {
      _initialApplied = true;
      final initial = widget.controller?.initialScrollOffset ?? 0;
      if (initial > 0) _scrollTo(initial, smooth: false);
    }
  }

  void _observe(JSObject node) {
    final window = _window as JSObject;
    if (_resizeObserver == null && window.has('ResizeObserver')) {
      final constructor = window.getProperty<JSFunction>('ResizeObserver'.toJS);
      _resizeObserver = constructor.callAsConstructor<JSObject>(
        ((JSAny? _, JSAny? _) => _remeasure()).toJS,
      );
      _resizeObserver!.callMethod<JSAny?>('observe'.toJS, node);
    }
    if (_mutationObserver == null && window.has('MutationObserver')) {
      final constructor = window.getProperty<JSFunction>(
        'MutationObserver'.toJS,
      );
      _mutationObserver = constructor.callAsConstructor<JSObject>(
        ((JSAny? _, JSAny? _) => _remeasure()).toJS,
      );
      _mutationObserver!.callMethod<JSAny?>(
        'observe'.toJS,
        node,
        {'childList': true, 'subtree': true}.jsify(),
      );
    }
  }

  bool _remeasureScheduled = false;
  void _remeasure() {
    if (_remeasureScheduled) return;
    _remeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remeasureScheduled = false;
      _measure();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _listen(JSObject node) {
    final target = _scrollsItself ? node : _window as JSObject;
    if (identical(target, _listeningTo)) return;
    _stopListening();
    _scrollListener = ((JSAny? _) => _scrolled()).toJS;
    target.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'scroll'.toJS,
      _scrollListener,
      {'passive': true}.jsify(),
    );
    _listeningTo = target;
  }

  void _stopListening() {
    final target = _listeningTo;
    if (target != null && _scrollListener != null) {
      target.callMethod<JSAny?>(
        'removeEventListener'.toJS,
        'scroll'.toJS,
        _scrollListener,
      );
    }
    _listeningTo = null;
  }

  void _scrolled() {
    if (!mounted) return;
    final offset = _offset();
    if (offset != _lastOffset) {
      // Flutter calls scrolling towards the end "reverse".
      _direction = offset > _lastOffset
          ? ScrollDirection.reverse
          : ScrollDirection.forward;
      _lastOffset = offset;
    }
    position.isScrollingNotifier.value = true;
    _idle?.cancel();
    _idle = Timer(const Duration(milliseconds: 150), () {
      position.isScrollingNotifier.value = false;
      _direction = ScrollDirection.idle;
    });
    position._changed();
  }

  /// Where the view's content starts in page scroll coordinates, below any
  /// pinned app bar.
  double _pageStart(JSObject node) {
    final window = _window as JSObject;
    final box = _clientRect(node);
    if (box == null) return 0;
    return math.max(
      0,
      box.top +
          _jsNumber(window, 'scrollY') -
          _cssPixels(node, '--fd-sticky-top'),
    );
  }

  double _offset() {
    final node = _node;
    if (node == null) return 0;
    if (_scrollsItself) {
      return _jsNumber(node, _vertical ? 'scrollTop' : 'scrollLeft');
    }
    final scrollY = _jsNumber(_window as JSObject, 'scrollY');
    return (scrollY - _pageStart(node)).clamp(0, _maxExtent()).toDouble();
  }

  double _viewportExtent() {
    final node = _node;
    if (node == null) return 0;
    if (_scrollsItself) {
      return _jsNumber(node, _vertical ? 'clientHeight' : 'clientWidth');
    }
    return _jsNumber(_window as JSObject, 'innerHeight') -
        _cssPixels(node, '--fd-sticky-top');
  }

  double _maxExtent() {
    final node = _node;
    if (node == null) return 0;
    if (_scrollsItself) {
      return math.max(
        0,
        _vertical
            ? _jsNumber(node, 'scrollHeight') - _jsNumber(node, 'clientHeight')
            : _jsNumber(node, 'scrollWidth') - _jsNumber(node, 'clientWidth'),
      );
    }
    final root = (_document as JSObject).getProperty<JSObject?>(
      'documentElement'.toJS,
    );
    final pageMax = root == null
        ? 0.0
        : _jsNumber(root, 'scrollHeight') -
              _jsNumber(_window as JSObject, 'innerHeight');
    return math.max(0, pageMax - _pageStart(node));
  }

  void _scrollTo(double value, {required bool smooth}) {
    final node = _node;
    if (node == null) return;
    final target = value.clamp(0, double.infinity).toDouble();
    final behavior = smooth ? 'smooth' : 'instant';
    if (_scrollsItself) {
      if (node.has('scrollTo')) {
        node.callMethod<JSAny?>(
          'scrollTo'.toJS,
          {
            if (_vertical) 'top': target else 'left': target,
            'behavior': behavior,
          }.jsify(),
        );
      } else {
        node.setProperty(
          (_vertical ? 'scrollTop' : 'scrollLeft').toJS,
          target.toJS,
        );
      }
    } else {
      final window = _window as JSObject;
      window.callMethod<JSAny?>(
        'scrollTo'.toJS,
        {'top': target + _pageStart(node), 'behavior': behavior}.jsify(),
      );
    }
    _scrolled();
  }

  /// The viewport edge pinned headers stick to, in client coordinates.
  double _stickyEdge(JSObject header) {
    final node = _node;
    if (node != null && _scrollsItself) return _clientRect(node)?.top ?? 0;
    return _cssPixels(header, '--fd-sticky-top');
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return _ScrollScope(
      view: this,
      child: _ScrollList(
        axis: widget.axis,
        padding: widget.padding,
        scrolls: widget.scrolls,
        overflowVisible: _vertical && _ownScroll == false,
        children: widget.reverse
            ? widget.children.reversed.toList()
            : widget.children,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom scroll views and slivers. Slivers build eagerly and stack in a
// column (or row); pinned headers use CSS sticky positioning.

class CustomScrollView extends StatelessWidget {
  const CustomScrollView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.scrollBehavior,
    this.shrinkWrap = false,
    this.center,
    this.anchor = 0,
    this.cacheExtent,
    this.slivers = const [],
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
  });
  final Axis scrollDirection;
  final bool reverse, shrinkWrap;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final Object? scrollBehavior, dragStartBehavior, keyboardDismissBehavior;
  final Key? center;
  final double anchor;
  final double? cacheExtent;
  final List<Widget> slivers;
  final int? semanticChildCount;
  final String? restorationId;
  final Clip clipBehavior;
  final HitTestBehavior hitTestBehavior;

  @override
  Widget build(BuildContext context) => _Scrollable(
    axis: scrollDirection,
    padding: null,
    scrolls: physics is! NeverScrollableScrollPhysics,
    controller: controller,
    reverse: reverse,
    children: slivers,
  );
}

class SliverToBoxAdapter extends StatelessWidget {
  const SliverToBoxAdapter({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class SliverPadding extends StatelessWidget {
  const SliverPadding({super.key, required this.padding, this.sliver});
  final EdgeInsetsGeometry padding;
  final Widget? sliver;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'display:flex;flex-direction:column;box-sizing:border-box;min-width:0;${edgeInsetsCss('padding', padding)}',
    layout: _DomLayout.column,
    fill: _Fill.expand,
    children: [?sliver],
  );
}

abstract class SliverChildDelegate {
  const SliverChildDelegate();
  Widget? build(BuildContext context, int index);
  int? get estimatedChildCount => null;
}

class SliverChildBuilderDelegate extends SliverChildDelegate {
  const SliverChildBuilderDelegate(
    this.builder, {
    this.findChildIndexCallback,
    this.childCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexOffset = 0,
  });
  final NullableIndexedWidgetBuilder builder;
  final int? Function(Key key)? findChildIndexCallback;
  final int? childCount;
  final bool addAutomaticKeepAlives, addRepaintBoundaries, addSemanticIndexes;
  final int semanticIndexOffset;
  @override
  Widget? build(BuildContext context, int index) =>
      childCount != null && index >= childCount!
      ? null
      : builder(context, index);
  @override
  int? get estimatedChildCount => childCount;
}

class SliverChildListDelegate extends SliverChildDelegate {
  const SliverChildListDelegate(
    this.children, {
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexOffset = 0,
  });
  final List<Widget> children;
  final bool addAutomaticKeepAlives, addRepaintBoundaries, addSemanticIndexes;
  final int semanticIndexOffset;
  @override
  Widget? build(BuildContext context, int index) =>
      index < children.length ? children[index] : null;
  @override
  int? get estimatedChildCount => children.length;
}

/// Builds every child of [delegate] eagerly, within the native item limit.
List<Widget> _sliverChildren(
  BuildContext context,
  SliverChildDelegate delegate,
) {
  final children = <Widget>[];
  for (var i = 0; ; i++) {
    if (i >= _eagerItemLimit)
      throw ArgumentError('Sliver child count exceeds the native limit.');
    final child = delegate.build(context, i);
    if (child == null) break;
    children.add(child);
  }
  return children;
}

Widget _sliverColumn(List<Widget> children, {double? itemExtent}) => _Box(
  css: 'display:flex;flex-direction:column;min-width:0;',
  layout: _DomLayout.column,
  fill: _Fill.expand,
  children: itemExtent == null
      ? children
      : [
          for (final child in children)
            SizedBox(key: child.key, height: itemExtent, child: child),
        ],
);

class SliverList extends StatelessWidget {
  const SliverList({super.key, required this.delegate});

  SliverList.builder({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? Function(Key key)? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : delegate = SliverChildBuilderDelegate(
         itemBuilder,
         findChildIndexCallback: findChildIndexCallback,
         childCount: itemCount,
       );

  SliverList.separated({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? Function(Key key)? findChildIndexCallback,
    required NullableIndexedWidgetBuilder separatorBuilder,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : delegate = SliverChildBuilderDelegate(
         (context, index) => index.isEven
             ? itemBuilder(context, index ~/ 2)
             : separatorBuilder(context, index ~/ 2),
         childCount: itemCount == null ? null : math.max(0, itemCount * 2 - 1),
       );

  SliverList.list({
    super.key,
    required List<Widget> children,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : delegate = SliverChildListDelegate(children);

  final SliverChildDelegate delegate;
  @override
  Widget build(BuildContext context) =>
      _sliverColumn(_sliverChildren(context, delegate));
}

class SliverFixedExtentList extends StatelessWidget {
  const SliverFixedExtentList({
    super.key,
    required this.delegate,
    required this.itemExtent,
  });
  SliverFixedExtentList.builder({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    required this.itemExtent,
    int? itemCount,
  }) : delegate = SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
       );
  SliverFixedExtentList.list({
    super.key,
    required List<Widget> children,
    required this.itemExtent,
  }) : delegate = SliverChildListDelegate(children);
  final SliverChildDelegate delegate;
  final double itemExtent;
  @override
  Widget build(BuildContext context) =>
      _sliverColumn(_sliverChildren(context, delegate), itemExtent: itemExtent);
}

class SliverGrid extends StatelessWidget {
  const SliverGrid({
    super.key,
    required this.delegate,
    required this.gridDelegate,
  });
  SliverGrid.builder({
    super.key,
    required this.gridDelegate,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
  }) : delegate = SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
       );
  SliverGrid.count({
    super.key,
    required int crossAxisCount,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    double childAspectRatio = 1,
    List<Widget> children = const [],
  }) : delegate = SliverChildListDelegate(children),
       gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       );
  SliverGrid.extent({
    super.key,
    required double maxCrossAxisExtent,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    double childAspectRatio = 1,
    List<Widget> children = const [],
  }) : delegate = SliverChildListDelegate(children),
       gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
         maxCrossAxisExtent: maxCrossAxisExtent,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       );
  final SliverChildDelegate delegate;
  final SliverGridDelegate gridDelegate;
  @override
  Widget build(BuildContext context) => GridView(
    gridDelegate: gridDelegate,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: _sliverChildren(context, delegate),
  );
}

class SliverFillRemaining extends StatelessWidget {
  const SliverFillRemaining({
    super.key,
    this.child,
    this.hasScrollBody = true,
    this.fillOverscroll = false,
  });
  final Widget? child;
  final bool hasScrollBody, fillOverscroll;
  @override
  Widget build(BuildContext context) => _Box(
    css: 'flex:1 0 auto;display:grid;grid-template-columns:minmax(0,1fr);',
    layout: _DomLayout.grid,
    fill: _Fill.expand,
    children: [?child],
  );
}

class SliverFillViewport extends StatelessWidget {
  const SliverFillViewport({
    super.key,
    required this.delegate,
    this.viewportFraction = 1,
    this.padEnds = true,
  });
  final SliverChildDelegate delegate;
  final double viewportFraction;
  final bool padEnds;
  @override
  Widget build(BuildContext context) => _sliverColumn([
    for (final child in _sliverChildren(context, delegate))
      _Box(
        key: child.key,
        css: 'height:${cssNumber(viewportFraction * 100)}vh;display:grid;',
        layout: _DomLayout.grid,
        fill: _Fill.expand,
        children: [child],
      ),
  ]);
}

/// Slivers that wrap one sliver keep its layout and add one effect.
class SliverOpacity extends StatelessWidget {
  const SliverOpacity({
    super.key,
    required this.opacity,
    this.alwaysIncludeSemantics = false,
    this.sliver,
  });
  final double opacity;
  final bool alwaysIncludeSemantics;
  final Widget? sliver;
  @override
  Widget build(BuildContext context) =>
      Opacity(opacity: opacity, child: sliver ?? const SizedBox.shrink());
}

class SliverVisibility extends StatelessWidget {
  const SliverVisibility({
    super.key,
    required this.sliver,
    this.replacementSliver = const SliverToBoxAdapter(),
    this.visible = true,
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
    this.maintainSemantics = false,
    this.maintainInteractivity = false,
  });
  final Widget sliver, replacementSliver;
  final bool visible, maintainState, maintainAnimation, maintainSize;
  final bool maintainSemantics, maintainInteractivity;
  @override
  Widget build(BuildContext context) => visible
      ? sliver
      : maintainState
      ? Offstage(child: sliver)
      : replacementSliver;
}

class SliverIgnorePointer extends StatelessWidget {
  const SliverIgnorePointer({super.key, this.ignoring = true, this.sliver});
  final bool ignoring;
  final Widget? sliver;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: ignoring,
    child: sliver ?? const SizedBox.shrink(),
  );
}

class SliverSafeArea extends StatelessWidget {
  const SliverSafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    required this.sliver,
  });
  final bool left, top, right, bottom;
  final EdgeInsets minimum;
  final Widget sliver;
  @override
  Widget build(BuildContext context) =>
      SliverPadding(padding: minimum, sliver: sliver);
}

class SliverMainAxisGroup extends StatelessWidget {
  const SliverMainAxisGroup({super.key, required this.slivers});
  final List<Widget> slivers;
  @override
  Widget build(BuildContext context) => _sliverColumn(slivers);
}

class DecoratedSliver extends StatelessWidget {
  const DecoratedSliver({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    this.sliver,
  });
  final Decoration decoration;
  final DecorationPosition position;
  final Widget? sliver;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: decoration,
    position: position,
    child: sliver ?? const SizedBox.shrink(),
  );
}

class SliverConstraints {
  const SliverConstraints({
    this.axisDirection = AxisDirection.down,
    this.growthDirection = GrowthDirection.forward,
    this.userScrollDirection = ScrollDirection.idle,
    this.scrollOffset = 0,
    this.precedingScrollExtent = 0,
    this.overlap = 0,
    required this.remainingPaintExtent,
    required this.crossAxisExtent,
    this.crossAxisDirection = AxisDirection.right,
    required this.viewportMainAxisExtent,
    required this.remainingCacheExtent,
    this.cacheOrigin = 0,
  });
  final AxisDirection axisDirection, crossAxisDirection;
  final GrowthDirection growthDirection;
  final ScrollDirection userScrollDirection;
  final double scrollOffset, precedingScrollExtent, overlap;
  final double remainingPaintExtent, crossAxisExtent, viewportMainAxisExtent;
  final double remainingCacheExtent, cacheOrigin;
  Axis get axis =>
      axisDirection == AxisDirection.up || axisDirection == AxisDirection.down
      ? Axis.vertical
      : Axis.horizontal;
  BoxConstraints asBoxConstraints({
    double minExtent = 0,
    double maxExtent = double.infinity,
    double? crossAxisExtent,
  }) => BoxConstraints(
    minWidth: crossAxisExtent ?? this.crossAxisExtent,
    maxWidth: crossAxisExtent ?? this.crossAxisExtent,
    minHeight: minExtent,
    maxHeight: maxExtent,
  );
}

typedef SliverLayoutWidgetBuilder =
    Widget Function(BuildContext context, SliverConstraints constraints);

/// Builds from the cross-axis width; the main-axis extents describe the
/// browser viewport, and the scroll offset is always zero.
class SliverLayoutBuilder extends StatelessWidget {
  const SliverLayoutBuilder({super.key, required this.builder});
  final SliverLayoutWidgetBuilder builder;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = MediaQuery.maybeSizeOf(context)?.height ?? 768;
      return builder(
        context,
        SliverConstraints(
          remainingPaintExtent: viewport,
          crossAxisExtent: constraints.maxWidth,
          viewportMainAxisExtent: viewport,
          remainingCacheExtent: viewport,
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Persistent headers.

abstract class SliverPersistentHeaderDelegate {
  const SliverPersistentHeaderDelegate();
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent);
  double get minExtent;
  double get maxExtent;
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate);
  Object? get snapConfiguration => null;
  Object? get stretchConfiguration => null;
  Object? get showOnScreenConfiguration => null;
  TickerProvider? get vsync => null;
}

/// Pinned headers stick at their minimum extent; other headers shrink to
/// nothing as they scroll away. Either way the header's box keeps its
/// maximum extent in the flow (height plus bottom margin), so content
/// scrolls past it one-to-one as in Flutter. Floating headers behave like
/// unpinned ones.
class SliverPersistentHeader extends StatefulWidget {
  const SliverPersistentHeader({
    super.key,
    required this.delegate,
    this.pinned = false,
    this.floating = false,
  });
  final SliverPersistentHeaderDelegate delegate;
  final bool pinned, floating;
  @override
  State<SliverPersistentHeader> createState() => _SliverPersistentHeaderState();
}

class _SliverPersistentHeaderState extends State<SliverPersistentHeader> {
  double _shrink = 0;
  _ScrollableState? _view;
  JSFunction? _windowListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final view = _ScrollScope.of(context);
    if (view == _view && (view != null || _windowListener != null)) return;
    _view?.position.removeListener(_update);
    _removeWindowListener();
    _view = view;
    if (view != null) {
      view.position.addListener(_update);
    } else {
      _windowListener = ((JSAny? _) => _update()).toJS;
      _window.addEventListener('scroll', _windowListener!);
    }
  }

  void _removeWindowListener() {
    if (_windowListener != null) {
      _window.removeEventListener('scroll', _windowListener!);
      _windowListener = null;
    }
  }

  @override
  void dispose() {
    _view?.position.removeListener(_update);
    _removeWindowListener();
    super.dispose();
  }

  void _update() {
    final node = _liveNode(context);
    if (node == null) return;
    final delegate = widget.delegate;
    final range = math.max(
      0.0,
      delegate.maxExtent - (widget.pinned ? delegate.minExtent : 0),
    );
    // The header's flow position: below its previous sibling (and that
    // sibling's margin), or at the top of its parent's content box.
    final previous = node.getProperty<JSObject?>('previousElementSibling'.toJS);
    double natural;
    if (previous != null) {
      natural =
          (_clientRect(previous)?.bottom ?? 0) +
          _cssPixels(previous, 'margin-bottom');
    } else {
      final parent = node.getProperty<JSObject?>('parentElement'.toJS);
      natural = parent == null
          ? 0
          : (_clientRect(parent)?.top ?? 0) + _cssPixels(parent, 'padding-top');
    }
    final edge =
        _view?._stickyEdge(node) ?? _cssPixels(node, '--fd-sticky-top');
    final shrink = (edge - natural).clamp(0.0, range).toDouble();
    if ((shrink - _shrink).abs() > 0.5 ||
        (shrink != _shrink && (shrink == 0 || shrink == range))) {
      setState(() => _shrink = shrink);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _update();
    });
    final delegate = widget.delegate;
    final maxExtent = math.max(delegate.maxExtent, delegate.minExtent);
    final minExtent = widget.pinned ? delegate.minExtent : 0.0;
    final shrink = _shrink
        .clamp(0.0, math.max(0.0, maxExtent - minExtent))
        .toDouble();
    final extent = math.max(minExtent, maxExtent - shrink);
    final ownScroll = _view?._scrollsItself ?? false;
    return _Box(
      css:
          'position:sticky;top:${ownScroll ? '0px' : 'var(--fd-sticky-top,0px)'};z-index:1;box-sizing:border-box;height:${px(extent)};margin-bottom:${px(maxExtent - extent)};overflow:hidden;display:grid;grid-template-columns:minmax(0,1fr);flex-shrink:0;',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [delegate.build(context, shrink, shrink > 0)],
    );
  }
}

// ---------------------------------------------------------------------------
// Sliver app bars.

class FlexibleSpaceBarSettings extends InheritedWidget {
  const FlexibleSpaceBarSettings({
    super.key,
    required this.toolbarOpacity,
    required this.minExtent,
    required this.maxExtent,
    required this.currentExtent,
    required super.child,
    this.isScrolledUnder,
    this.hasLeading,
  });
  final double toolbarOpacity, minExtent, maxExtent, currentExtent;
  final bool? isScrolledUnder, hasLeading;
  @override
  bool updateShouldNotify(FlexibleSpaceBarSettings old) =>
      old.currentExtent != currentExtent ||
      old.minExtent != minExtent ||
      old.maxExtent != maxExtent ||
      old.toolbarOpacity != toolbarOpacity;
}

enum CollapseMode { parallax, pin, none }

enum StretchMode { zoomBackground, blurBackground, fadeTitle }

class FlexibleSpaceBar extends StatelessWidget {
  const FlexibleSpaceBar({
    super.key,
    this.title,
    this.background,
    this.centerTitle,
    this.titlePadding,
    this.collapseMode = CollapseMode.parallax,
    this.stretchModes = const [StretchMode.zoomBackground],
    this.expandedTitleScale = 1.5,
  });
  final Widget? title, background;
  final bool? centerTitle;
  final EdgeInsetsGeometry? titlePadding;
  final CollapseMode collapseMode;
  final List<StretchMode> stretchModes;
  final double expandedTitleScale;

  static Widget createSettings({
    double? toolbarOpacity,
    double? minExtent,
    double? maxExtent,
    bool? isScrolledUnder,
    bool? hasLeading,
    required double currentExtent,
    required Widget child,
  }) => FlexibleSpaceBarSettings(
    toolbarOpacity: toolbarOpacity ?? 1,
    minExtent: minExtent ?? currentExtent,
    maxExtent: maxExtent ?? currentExtent,
    currentExtent: currentExtent,
    isScrolledUnder: isScrolledUnder,
    hasLeading: hasLeading,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final range = settings == null
        ? 0.0
        : settings.maxExtent - settings.minExtent;
    // 1 when fully expanded, 0 when collapsed.
    final t = range <= 0
        ? 1.0
        : ((settings!.currentExtent - settings.minExtent) / range).clamp(
            0.0,
            1.0,
          );
    final theme = Theme.of(context);
    final centered = centerTitle ?? false;
    final hasLeading = settings?.hasLeading ?? false;
    final padding =
        titlePadding ??
        EdgeInsetsDirectional.only(
          start: centered ? 0 : (hasLeading ? 72 : 16),
          bottom: 16,
        );
    final scale = 1 + (expandedTitleScale - 1) * t;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (background != null)
          Positioned.fill(
            child: Opacity(
              // The background fades out over the last half of collapsing.
              opacity: (t * 2).clamp(0.0, 1.0),
              child: background!,
            ),
          ),
        if (title != null)
          Positioned.fill(
            child: Padding(
              padding: padding,
              child: Align(
                alignment: centered
                    ? Alignment.bottomCenter
                    : AlignmentDirectional.bottomStart,
                child: Transform.scale(
                  scale: scale,
                  alignment: centered
                      ? Alignment.bottomCenter
                      : Alignment.bottomLeft,
                  child: DefaultTextStyle(
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title!,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

const kToolbarHeight = 56.0;

class SliverAppBar extends StatelessWidget {
  const SliverAppBar({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.forceElevated = false,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100,
    this.onStretchTrigger,
    this.shape,
    this.toolbarHeight = kToolbarHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
    this.actionsPadding,
  });
  final Widget? leading, title, flexibleSpace;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? elevation, scrolledUnderElevation, titleSpacing;
  final double? collapsedHeight, expandedHeight, leadingWidth;
  final Color? shadowColor, surfaceTintColor, backgroundColor, foregroundColor;
  final bool forceElevated, primary, excludeHeaderSemantics;
  final IconThemeData? iconTheme, actionsIconTheme;
  final bool? centerTitle;
  final bool floating, pinned, snap, stretch, forceMaterialTransparency;
  final double stretchTriggerOffset, toolbarHeight;
  final Future<void> Function()? onStretchTrigger;
  final ShapeBorder? shape;
  final TextStyle? toolbarTextStyle, titleTextStyle;
  final Object? systemOverlayStyle;
  final Clip? clipBehavior;
  final EdgeInsetsGeometry? actionsPadding;

  @override
  Widget build(BuildContext context) {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final collapsed =
        math.max(collapsedHeight ?? toolbarHeight, toolbarHeight) +
        bottomHeight;
    return SliverPersistentHeader(
      pinned: pinned,
      floating: floating,
      delegate: _SliverAppBarDelegate(
        bar: this,
        minExtent: collapsed,
        maxExtent: math.max(expandedHeight ?? 0, collapsed),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.bar,
    required this.minExtent,
    required this.maxExtent,
  });
  final SliverAppBar bar;
  @override
  final double minExtent, maxExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final scheme = Theme.of(context).colorScheme;
    final current = math.max(minExtent, maxExtent - shrinkOffset);
    final background = bar.forceMaterialTransparency
        ? const Color(0x00000000)
        : (bar.backgroundColor ?? scheme.surface);
    final elevated = bar.forceElevated || overlaps;
    final toolbar = AppBar(
      leading: bar.leading,
      automaticallyImplyLeading: bar.automaticallyImplyLeading,
      title: bar.title,
      actions: bar.actions,
      bottom: bar.bottom,
      backgroundColor: const Color(0x00000000),
      foregroundColor: bar.foregroundColor,
      elevation: 0,
      centerTitle: bar.centerTitle,
      titleSpacing: bar.titleSpacing,
      toolbarHeight: bar.toolbarHeight,
      titleTextStyle: bar.titleTextStyle,
    );
    return FlexibleSpaceBarSettings(
      toolbarOpacity: 1,
      minExtent: minExtent,
      maxExtent: maxExtent,
      currentExtent: current,
      isScrolledUnder: overlaps,
      hasLeading: bar.leading != null,
      child: _Box(
        tag: 'header',
        css:
            'position:relative;display:grid;grid-template-columns:minmax(0,1fr);grid-template-rows:minmax(0,1fr);height:100%;background-color:${colorCss(background)};${elevated ? elevationCss(bar.scrolledUnderElevation ?? bar.elevation ?? 3, bar.shadowColor ?? scheme.shadow) : ''}',
        layout: _DomLayout.grid,
        fill: _Fill.expand,
        children: [
          if (bar.flexibleSpace != null)
            _Box(
              css: 'grid-area:1/1;display:grid;min-height:0;overflow:hidden;',
              layout: _DomLayout.grid,
              fill: _Fill.expand,
              children: [bar.flexibleSpace!],
            ),
          _Box(
            css: 'grid-area:1/1;align-self:start;position:relative;',
            fill: _Fill.expand,
            children: [toolbar],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Pull to refresh.

enum RefreshIndicatorTriggerMode { onEdge, anywhere }

class RefreshIndicator extends StatefulWidget {
  const RefreshIndicator({
    super.key,
    required this.child,
    this.displacement = 40,
    this.edgeOffset = 0,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.notificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = 2.5,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.elevation = 2,
  });
  const RefreshIndicator.adaptive({
    super.key,
    required this.child,
    this.displacement = 40,
    this.edgeOffset = 0,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.notificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = 2.5,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.elevation = 2,
  });
  final Widget child;
  final double displacement, edgeOffset, strokeWidth, elevation;
  final Future<void> Function() onRefresh;
  final Color? color, backgroundColor;
  final bool Function(Object notification)? notificationPredicate;
  final String? semanticsLabel, semanticsValue;
  final RefreshIndicatorTriggerMode triggerMode;
  @override
  State<RefreshIndicator> createState() => RefreshIndicatorState();
}

/// Touch pulls past the top of the page (or of the scroll view below)
/// trigger [RefreshIndicator.onRefresh]; [show] triggers it from code.
class RefreshIndicatorState extends State<RefreshIndicator> {
  static const _threshold = 80.0;
  double? _start;
  double _pull = 0;
  bool _refreshing = false;

  bool _atTop() {
    final node = _liveNode(context);
    if (_jsNumber(_window as JSObject, 'scrollY') > 0) return false;
    // A scroll view that scrolls itself must be at its top too.
    final scroller = node?.callMethod<JSObject?>(
      'querySelector'.toJS,
      '*'.toJS,
    );
    return scroller == null || _jsNumber(scroller, 'scrollTop') <= 0;
  }

  Future<void> show({bool atTop = true}) async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _pull = 0;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (_pull / _threshold).clamp(0.0, 1.0);
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.touch && !_refreshing && _atTop()) {
          _start = event.position.dy;
        }
      },
      onPointerMove: (event) {
        final start = _start;
        if (start == null) return;
        final pull = math.max(0.0, event.position.dy - start);
        if (pull != _pull) setState(() => _pull = pull);
      },
      onPointerUp: (_) {
        final trigger = _pull >= _threshold;
        _start = null;
        if (trigger) {
          show();
        } else if (_pull != 0) {
          setState(() => _pull = 0);
        }
      },
      onPointerCancel: (_) {
        _start = null;
        if (_pull != 0) setState(() => _pull = 0);
      },
      child: _Box(
        css:
            'position:relative;display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
        layout: _DomLayout.grid,
        fill: _Fill.expand,
        children: [
          widget.child,
          if (_refreshing || _pull > 0)
            _Box(
              css:
                  'position:absolute;left:50%;top:${px(widget.edgeOffset + (_refreshing ? widget.displacement : widget.displacement * progress))};transform:translateX(-50%);z-index:3;box-sizing:border-box;width:40px;height:40px;padding:8px;border-radius:50%;background-color:${colorCss(widget.backgroundColor ?? scheme.surfaceContainerHigh)};${elevationCss(widget.elevation, scheme.shadow)}',
              attributes: {
                'role': 'progressbar',
                'aria-label': widget.semanticsLabel ?? 'Refresh',
              },
              fill: _Fill.none,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _refreshing ? null : progress,
                    strokeWidth: widget.strokeWidth,
                    color: widget.color,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draggable scrollable sheets.

typedef ScrollableWidgetBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);

class DraggableScrollableController extends ChangeNotifier {
  _DraggableScrollableSheetState? _sheet;
  bool get isAttached => _sheet != null;
  double get size => _sheet?._size ?? (throw StateError('Not attached.'));
  double get pixels => sizeToPixels(size);
  double sizeToPixels(double size) =>
      size * (_sheet?._available ?? (throw StateError('Not attached.')));
  double pixelsToSize(double pixels) =>
      pixels / (_sheet?._available ?? (throw StateError('Not attached.')));
  void jumpTo(double size) => _sheet?._resize(size);
  Future<void> animateTo(
    double size, {
    required Duration duration,
    required Curve curve,
  }) async => _sheet?._resize(size);
  void reset() => _sheet?._resize(_sheet!.widget.initialChildSize);
}

/// A sheet sized as a fraction of the viewport height. It does not resize
/// by dragging its content; its controller changes the size.
class DraggableScrollableSheet extends StatefulWidget {
  const DraggableScrollableSheet({
    super.key,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 1,
    this.expand = true,
    this.snap = false,
    this.snapSizes,
    this.snapAnimationDuration,
    this.controller,
    this.shouldCloseOnMinExtent = true,
    required this.builder,
  });
  final double initialChildSize, minChildSize, maxChildSize;
  final bool expand, snap, shouldCloseOnMinExtent;
  final List<double>? snapSizes;
  final Duration? snapAnimationDuration;
  final DraggableScrollableController? controller;
  final ScrollableWidgetBuilder builder;
  @override
  State<DraggableScrollableSheet> createState() =>
      _DraggableScrollableSheetState();
}

class _DraggableScrollableSheetState extends State<DraggableScrollableSheet> {
  late double _size = widget.initialChildSize;
  final _scrollController = ScrollController();
  double _available = 768;

  @override
  void initState() {
    super.initState();
    widget.controller?._sheet = this;
  }

  @override
  void didUpdateWidget(DraggableScrollableSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._sheet = null;
      widget.controller?._sheet = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._sheet == this) widget.controller!._sheet = null;
    _scrollController.dispose();
    super.dispose();
  }

  void _resize(double size) {
    final next = size.clamp(widget.minChildSize, widget.maxChildSize);
    if (next == _size) return;
    setState(() => _size = next.toDouble());
    widget.controller?.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    _available = MediaQuery.maybeSizeOf(context)?.height ?? 768;
    return _Box(
      css:
          'box-sizing:border-box;height:${px(_size * _available)};display:grid;grid-template-columns:minmax(0,1fr);grid-template-rows:minmax(0,1fr);min-width:0;',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [widget.builder(context, _scrollController)],
    );
  }
}

// ---------------------------------------------------------------------------
// Reorderable lists.

typedef ReorderCallback = void Function(int oldIndex, int newIndex);
typedef ReorderItemProxyDecorator =
    Widget Function(Widget child, int index, Animation<double> animation);

class _ReorderScope extends InheritedWidget {
  const _ReorderScope({required this.list, required super.child});
  final _ReorderableListViewState list;
  @override
  bool updateShouldNotify(_ReorderScope oldWidget) => oldWidget.list != list;
}

/// Starts dragging item [index] when a pointer goes down on [child].
class ReorderableDragStartListener extends StatelessWidget {
  const ReorderableDragStartListener({
    super.key,
    required this.child,
    required this.index,
    this.enabled = true,
  });
  final Widget child;
  final int index;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final list = context
        .dependOnInheritedWidgetOfExactType<_ReorderScope>()
        ?.list;
    if (!enabled || list == null) return child;
    return Listener(
      onPointerDown: (event) => list._start(index, event.position.dy),
      child: _Box(
        css: 'cursor:grab;touch-action:none;display:grid;',
        layout: _DomLayout.grid,
        fill: _Fill.none,
        children: [child],
      ),
    );
  }
}

/// Drag starts after a long press, as on touch devices in Flutter.
class ReorderableDelayedDragStartListener extends StatelessWidget {
  const ReorderableDelayedDragStartListener({
    super.key,
    required this.child,
    required this.index,
    this.enabled = true,
  });
  final Widget child;
  final int index;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final list = context
        .dependOnInheritedWidgetOfExactType<_ReorderScope>()
        ?.list;
    if (!enabled || list == null) return child;
    return GestureDetector(
      onLongPressStart: (details) =>
          list._start(index, details.globalPosition.dy),
      child: child,
    );
  }
}

class ReorderableListView extends StatefulWidget {
  ReorderableListView({
    super.key,
    required List<Widget> children,
    required this.onReorder,
    this.onReorderStart,
    this.onReorderEnd,
    this.itemExtent,
    this.prototypeItem,
    this.proxyDecorator,
    this.buildDefaultDragHandles = true,
    this.padding,
    this.header,
    this.footer,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0,
    this.cacheExtent,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.autoScrollerVelocityScalar,
  }) : itemCount = children.length,
       itemBuilder = ((context, index) => children[index]);

  const ReorderableListView.builder({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    this.onReorderStart,
    this.onReorderEnd,
    this.itemExtent,
    this.prototypeItem,
    this.proxyDecorator,
    this.buildDefaultDragHandles = true,
    this.padding,
    this.header,
    this.footer,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0,
    this.cacheExtent,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.autoScrollerVelocityScalar,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ReorderCallback onReorder;
  final void Function(int index)? onReorderStart, onReorderEnd;
  final double? itemExtent, cacheExtent, autoScrollerVelocityScalar;
  final Widget? prototypeItem, header, footer;
  final ReorderItemProxyDecorator? proxyDecorator;
  final bool buildDefaultDragHandles, reverse, shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final ScrollController? scrollController;
  final bool? primary;
  final ScrollPhysics? physics;
  final double anchor;
  final Object? dragStartBehavior, keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  @override
  State<ReorderableListView> createState() => _ReorderableListViewState();
}

class _ReorderableListViewState extends State<ReorderableListView> {
  final _items = <int, BuildContext>{};
  int? _dragging, _target;
  double _startY = 0, _dy = 0;
  List<Rect> _rects = const [];
  JSFunction? _move, _up;

  void _start(int index, double y) {
    if (_dragging != null) return;
    final rects = <Rect>[];
    for (var i = 0; i < widget.itemCount; i++) {
      final item = _items[i];
      final node = item == null ? null : _liveNode(item);
      rects.add(node == null ? Rect.zero : (_clientRect(node) ?? Rect.zero));
    }
    setState(() {
      _dragging = index;
      _target = index;
      _startY = y;
      _dy = 0;
      _rects = rects;
    });
    widget.onReorderStart?.call(index);
    _move = ((JSObject event) {
      final clientY = _jsNumber(event, 'clientY');
      event.callMethod<JSAny?>('preventDefault'.toJS);
      _drag(clientY);
    }).toJS;
    _up = ((JSAny? _) => _finish()).toJS;
    _window.addEventListener('pointermove', _move!);
    _window.addEventListener('pointerup', _up!);
    _window.addEventListener('pointercancel', _up!);
  }

  void _drag(double y) {
    final dragging = _dragging;
    if (dragging == null || !mounted) return;
    final dy = y - _startY;
    final moved = _rects[dragging].center.dy + dy;
    // The target is the slot whose midpoint the dragged item has passed.
    var target = dragging;
    for (var i = 0; i < _rects.length; i++) {
      final mid = _rects[i].center.dy;
      if (i < dragging && moved < mid) {
        target = i;
        break;
      }
      if (i > dragging && moved > mid) target = i;
    }
    setState(() {
      _dy = dy;
      _target = target;
    });
  }

  void _finish() {
    _window.removeEventListener('pointermove', _move!);
    _window.removeEventListener('pointerup', _up!);
    _window.removeEventListener('pointercancel', _up!);
    final from = _dragging, to = _target;
    if (!mounted) return;
    setState(() {
      _dragging = null;
      _target = null;
      _dy = 0;
    });
    if (from == null || to == null) return;
    widget.onReorderEnd?.call(to);
    // Flutter reports the index before the item is removed.
    if (to != from) widget.onReorder(from, to > from ? to + 1 : to);
  }

  @override
  void dispose() {
    if (_move != null) {
      _window.removeEventListener('pointermove', _move!);
      _window.removeEventListener('pointerup', _up!);
      _window.removeEventListener('pointercancel', _up!);
    }
    super.dispose();
  }

  double _shiftFor(int index) {
    final dragging = _dragging, target = _target;
    if (dragging == null || target == null) return 0;
    if (index == dragging) return _dy;
    final height = _rects[dragging].height;
    if (target > dragging && index > dragging && index <= target) {
      return -height;
    }
    if (target < dragging && index < dragging && index >= target) {
      return height;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ?widget.header,
      for (var i = 0; i < widget.itemCount; i++)
        () {
          final item = widget.itemBuilder(context, i);
          final shift = _shiftFor(i);
          Widget content = item;
          if (widget.buildDefaultDragHandles) {
            content = Row(
              children: [
                Expanded(child: item),
                ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ],
            );
          }
          return _ReorderItem(
            key: item.key ?? ValueKey(i),
            index: i,
            list: this,
            css:
                'position:relative;${shift == 0 ? '' : 'transform:translateY(${px(shift)});'}${i == _dragging ? 'z-index:2;opacity:0.9;' : 'transition:transform 150ms ease;'}',
            child: content,
          );
        }(),
      ?widget.footer,
    ];
    return _ReorderScope(
      list: this,
      child: _Scrollable(
        axis: widget.scrollDirection,
        padding: widget.padding,
        scrolls: widget.physics is! NeverScrollableScrollPhysics,
        controller: widget.scrollController,
        reverse: widget.reverse,
        children: children,
      ),
    );
  }
}

class _ReorderItem extends StatefulWidget {
  const _ReorderItem({
    super.key,
    required this.index,
    required this.list,
    required this.css,
    required this.child,
  });
  final int index;
  final _ReorderableListViewState list;
  final String css;
  final Widget child;
  @override
  State<_ReorderItem> createState() => _ReorderItemState();
}

class _ReorderItemState extends State<_ReorderItem> {
  @override
  Widget build(BuildContext context) {
    widget.list._items[widget.index] = context;
    return _Box(
      css: widget.css,
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [widget.child],
    );
  }

  @override
  void dispose() {
    if (widget.list._items[widget.index] == context) {
      widget.list._items.remove(widget.index);
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Pointer exclusion.

class IgnorePointer extends _DomWidget {
  const IgnorePointer({
    super.key,
    this.ignoring = true,
    this.ignoringSemantics,
    this.child,
  });
  final bool ignoring;
  final bool? ignoringSemantics;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    out.css('display:grid;grid-template-columns:minmax(0,1fr);min-width:0;');
    if (ignoring) out.css('pointer-events:none;');
    if (child != null) out.child(child!);
  }
}

/// Blocks pointer input to its subtree; the box itself still absorbs it.
class AbsorbPointer extends _DomWidget {
  const AbsorbPointer({
    super.key,
    this.absorbing = true,
    this.ignoringSemantics,
    this.child,
  });
  final bool absorbing;
  final bool? ignoringSemantics;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    out.css('display:grid;grid-template-columns:minmax(0,1fr);min-width:0;');
    // The subtree ignores pointers, so hits land on (and stop at) this box.
    if (child != null) {
      out.child(
        absorbing
            ? _Box(
                css:
                    'pointer-events:none;display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
                layout: _DomLayout.grid,
                fill: _Fill.expand,
                children: [child!],
              )
            : child!,
      );
    }
  }
}
