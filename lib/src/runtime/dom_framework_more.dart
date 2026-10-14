part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Render objects: read-only views of an element's DOM box, enough for the
// geometry queries apps make (size, position, hit areas). Layout and
// painting stay with the browser.

abstract class RenderObject {
  RenderObject._(this._element);
  final Element _element;
  bool get attached => _element.mounted;
  bool get debugNeedsLayout => false;
  Rect get paintBounds => Offset.zero & (_box?.size ?? Size.zero);
  Rect get semanticBounds => paintBounds;
  RenderObject? get parent => _element._parent?.findRenderObject();
  void markNeedsLayout() {}
  void markNeedsPaint() {}
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final node = _liveNode(_element);
    if (node != null && node.has('scrollIntoView')) {
      node.callMethod<JSAny?>(
        'scrollIntoView'.toJS,
        {
          'block': 'nearest',
          'behavior': duration == Duration.zero ? 'instant' : 'smooth',
        }.jsify(),
      );
    }
  }

  Rect? get _box {
    final node = _liveNode(_element);
    return node == null ? null : _clientRect(node);
  }

  Matrix4 getTransformTo(RenderObject? ancestor) {
    final own = _box?.topLeft ?? Offset.zero;
    final base = ancestor?._box?.topLeft ?? Offset.zero;
    final delta = own - base;
    return Matrix4.translationValues(delta.dx, delta.dy, 0);
  }
}

class RenderBox extends RenderObject {
  RenderBox._(super.element) : super._();

  bool get hasSize => _box != null;
  Size get size => _box?.size ?? Size.zero;
  BoxConstraints get constraints => BoxConstraints.tight(size);

  /// Converts a point in this box to viewport (global) coordinates.
  Offset localToGlobal(Offset point, {RenderObject? ancestor}) {
    final origin = _box?.topLeft ?? Offset.zero;
    final base = ancestor?._box?.topLeft ?? Offset.zero;
    return point + origin - base;
  }

  Offset globalToLocal(Offset point, {RenderObject? ancestor}) {
    final origin = _box?.topLeft ?? Offset.zero;
    final base = ancestor?._box?.topLeft ?? Offset.zero;
    return point - origin + base;
  }

  double getMinIntrinsicWidth(double height) => size.width;
  double getMaxIntrinsicWidth(double height) => size.width;
  double getMinIntrinsicHeight(double width) => size.height;
  double getMaxIntrinsicHeight(double width) => size.height;
  double? getDistanceToBaseline(
    TextBaseline baseline, {
    bool onlyReal = false,
  }) => null;
}

// ---------------------------------------------------------------------------
// Overlays: entries render above the overlay's child in a fixed layer that
// covers the viewport, in insertion order.

class OverlayEntry implements Listenable {
  OverlayEntry({
    required this.builder,
    bool opaque = false,
    bool maintainState = false,
    this.canSizeOverlay = false,
  }) : _opaque = opaque,
       _maintainState = maintainState;
  final WidgetBuilder builder;
  final bool canSizeOverlay;
  bool _opaque, _maintainState;
  OverlayState? _overlay;
  final _key = GlobalKey<_OverlayEntryState>();
  final _listeners = ChangeNotifier();

  bool get opaque => _opaque;
  set opaque(bool value) {
    _opaque = value;
    _overlay?._changed();
  }

  bool get maintainState => _maintainState;
  set maintainState(bool value) {
    _maintainState = value;
    _overlay?._changed();
  }

  bool get mounted => _overlay != null;

  void remove() {
    final overlay = _overlay;
    _overlay = null;
    overlay?._remove(this);
    _listeners.notifyListeners();
  }

  void markNeedsBuild() => _key.currentState?._rebuild();

  void dispose() => _listeners.dispose();

  @override
  void addListener(VoidCallback listener) => _listeners.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _listeners.removeListener(listener);
}

class Overlay extends StatefulWidget {
  const Overlay({
    super.key,
    this.initialEntries = const [],
    this.clipBehavior = Clip.hardEdge,
    this.child,
  });
  final List<OverlayEntry> initialEntries;
  final Clip clipBehavior;
  final Widget? child;

  static OverlayState of(
    BuildContext context, {
    bool rootOverlay = false,
    Widget? debugRequiredFor,
  }) =>
      maybeOf(context, rootOverlay: rootOverlay) ??
      (throw StateError('No Overlay widget found.'));

  static OverlayState? maybeOf(
    BuildContext context, {
    bool rootOverlay = false,
  }) => rootOverlay
      ? context.findRootAncestorStateOfType<OverlayState>()
      : context.findAncestorStateOfType<OverlayState>();

  @override
  State<Overlay> createState() => OverlayState();
}

class OverlayState extends State<Overlay> {
  final _entries = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    insertAll(widget.initialEntries);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void insert(OverlayEntry entry, {OverlayEntry? below, OverlayEntry? above}) {
    entry._overlay = this;
    final anchor = below ?? above;
    final index = anchor == null ? -1 : _entries.indexOf(anchor);
    if (index < 0) {
      _entries.add(entry);
    } else {
      _entries.insert(below != null ? index : index + 1, entry);
    }
    _changed();
  }

  void insertAll(
    Iterable<OverlayEntry> entries, {
    OverlayEntry? below,
    OverlayEntry? above,
  }) {
    for (final entry in entries) {
      insert(entry, below: below, above: above);
    }
  }

  void rearrange(
    Iterable<OverlayEntry> newEntries, {
    OverlayEntry? below,
    OverlayEntry? above,
  }) {
    _entries
      ..clear()
      ..addAll(newEntries);
    for (final entry in _entries) {
      entry._overlay = this;
    }
    _changed();
  }

  void _remove(OverlayEntry entry) {
    _entries.remove(entry);
    _changed();
  }

  @override
  Widget build(BuildContext context) => _Box(
    css: 'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
    layout: _DomLayout.grid,
    fill: _Fill.expand,
    children: [
      ?widget.child,
      if (_entries.isNotEmpty)
        _Box(
          key: const ValueKey('overlay-layer'),
          css:
              'position:fixed;inset:0;z-index:30;pointer-events:none;display:grid;',
          fill: _Fill.none,
          children: [
            for (final entry in _entries)
              _OverlayEntryHost(key: entry._key, entry: entry),
          ],
        ),
    ],
  );
}

class _OverlayEntryHost extends StatefulWidget {
  const _OverlayEntryHost({super.key, required this.entry});
  final OverlayEntry entry;
  @override
  State<_OverlayEntryHost> createState() => _OverlayEntryState();
}

class _OverlayEntryState extends State<_OverlayEntryHost> {
  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => _Box(
    // Each entry fills the layer; its own content receives pointers.
    css:
        'grid-area:1/1;position:relative;width:100%;height:100%;pointer-events:none;',
    attributes: const {'class': 'fd-overlay-entry'},
    fill: _Fill.expand,
    children: [
      // The entry is a direct Stack child so it can be Positioned.
      Builder(
        builder: (context) => Stack(
          fit: StackFit.expand,
          children: [widget.entry.builder(context)],
        ),
      ),
    ],
  );
}

/// Draws [overlayChildBuilder] in the nearest [Overlay] while shown.
class OverlayPortal extends StatefulWidget {
  const OverlayPortal({
    super.key,
    required this.controller,
    required this.overlayChildBuilder,
    this.child,
  });
  const OverlayPortal.targetsRootOverlay({
    super.key,
    required this.controller,
    required this.overlayChildBuilder,
    this.child,
  });
  final OverlayPortalController controller;
  final WidgetBuilder overlayChildBuilder;
  final Widget? child;
  @override
  State<OverlayPortal> createState() => _OverlayPortalState();
}

class OverlayPortalController {
  OverlayPortalController({this.debugLabel});
  final String? debugLabel;
  _OverlayPortalState? _portal;
  bool _showing = false;
  bool get isShowing => _showing;
  void show() {
    _showing = true;
    _portal?._sync();
  }

  void hide() {
    _showing = false;
    _portal?._sync();
  }

  void toggle() => isShowing ? hide() : show();
}

class _OverlayPortalState extends State<OverlayPortal> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    widget.controller._portal = this;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    if (widget.controller.isShowing && _entry == null) {
      _entry = OverlayEntry(builder: widget.overlayChildBuilder);
      Overlay.maybeOf(context)?.insert(_entry!);
    } else if (!widget.controller.isShowing && _entry != null) {
      _entry!.remove();
      _entry = null;
    } else {
      _entry?.markNeedsBuild();
    }
  }

  @override
  void didUpdateWidget(OverlayPortal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._portal = this;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}

// ---------------------------------------------------------------------------
// State restoration: values live for the page's lifetime; nothing is
// persisted across reloads.

class RestorationBucket {
  RestorationBucket.empty({required this.restorationId, Object? debugOwner});
  final String restorationId;
  final _values = <String, Object?>{};
  T? read<T>(String key) => _values[key] as T?;
  void write<T>(String key, T value) => _values[key] = value;
  T? remove<T>(String key) => _values.remove(key) as T?;
  bool contains(String key) => _values.containsKey(key);
}

abstract class RestorableProperty<T> extends ChangeNotifier {
  RestorableProperty();
  T createDefaultValue();
  T fromPrimitives(Object? data);
  void initWithValue(T value);
  Object? toPrimitives();
  bool get enabled => true;
  bool get isRegistered => _registered;
  bool _registered = false;
}

abstract class RestorableValue<T> extends RestorableProperty<T> {
  RestorableValue();
  late T _value;
  bool _initialized = false;
  T get value {
    if (!_initialized) {
      _value = createDefaultValue();
      _initialized = true;
    }
    return _value;
  }

  set value(T newValue) {
    final old = _initialized ? _value : null;
    _value = newValue;
    _initialized = true;
    if (old != newValue) {
      didUpdateValue(old);
      notifyListeners();
    }
  }

  @override
  void initWithValue(T value) {
    _value = value;
    _initialized = true;
  }

  void didUpdateValue(T? oldValue) {}
}

class _RestorablePrimitive<T> extends RestorableValue<T> {
  _RestorablePrimitive(this._default);
  final T _default;
  @override
  T createDefaultValue() => _default;
  @override
  T fromPrimitives(Object? data) => data as T;
  @override
  Object? toPrimitives() => value;
}

class RestorableNum<T extends num> extends _RestorablePrimitive<T> {
  RestorableNum(super.defaultValue);
}

class RestorableInt extends _RestorablePrimitive<int> {
  RestorableInt(super.defaultValue);
}

class RestorableDouble extends _RestorablePrimitive<double> {
  RestorableDouble(super.defaultValue);
}

class RestorableBool extends _RestorablePrimitive<bool> {
  RestorableBool(super.defaultValue);
}

class RestorableString extends _RestorablePrimitive<String> {
  RestorableString(super.defaultValue);
}

class RestorableIntN extends _RestorablePrimitive<int?> {
  RestorableIntN(super.defaultValue);
}

class RestorableDoubleN extends _RestorablePrimitive<double?> {
  RestorableDoubleN(super.defaultValue);
}

class RestorableBoolN extends _RestorablePrimitive<bool?> {
  RestorableBoolN(super.defaultValue);
}

class RestorableStringN extends _RestorablePrimitive<String?> {
  RestorableStringN(super.defaultValue);
}

class RestorableDateTime extends _RestorablePrimitive<DateTime> {
  RestorableDateTime(super.defaultValue);
}

class RestorableDateTimeN extends _RestorablePrimitive<DateTime?> {
  RestorableDateTimeN(super.defaultValue);
}

class RestorableEnum<T extends Enum> extends _RestorablePrimitive<T> {
  RestorableEnum(super.defaultValue, {required Iterable<T> values});
}

class RestorableEnumN<T extends Enum> extends _RestorablePrimitive<T?> {
  RestorableEnumN(super.defaultValue, {required Iterable<T> values});
}

abstract class RestorableListenable<T extends Listenable>
    extends RestorableProperty<T> {
  T? _value;
  T get value => _value ??= createDefaultValue();
  @override
  void initWithValue(T value) => _value = value;
}

abstract class RestorableChangeNotifier<T extends ChangeNotifier>
    extends RestorableListenable<T> {
  @override
  void dispose() {
    _value?.dispose();
    super.dispose();
  }
}

class RestorableTextEditingController
    extends RestorableChangeNotifier<TextEditingController> {
  RestorableTextEditingController({String? text}) : _text = text ?? '';
  RestorableTextEditingController.fromValue(TextEditingValue value)
    : _text = value.text;
  final String _text;
  @override
  TextEditingController createDefaultValue() =>
      TextEditingController(text: _text);
  @override
  TextEditingController fromPrimitives(Object? data) =>
      TextEditingController(text: data as String?);
  @override
  Object? toPrimitives() => value.text;
}

class RestorableRouteFuture<T> extends RestorableProperty<String?> {
  RestorableRouteFuture({
    this.navigatorFinder = _defaultNavigator,
    required this.onPresent,
    this.onComplete,
  });
  final NavigatorState Function(BuildContext context) navigatorFinder;
  final String Function(NavigatorState navigator, Object? arguments) onPresent;
  final ValueChanged<T>? onComplete;
  BuildContext? _context;
  bool _active = false;
  bool get isPresent => _active;

  static NavigatorState _defaultNavigator(BuildContext context) =>
      Navigator.of(context);

  void present([Object? arguments]) {
    final context = _context;
    if (context == null) return;
    _active = true;
    onPresent(navigatorFinder(context), arguments);
  }

  @override
  String? createDefaultValue() => null;
  @override
  String? fromPrimitives(Object? data) => data as String?;
  @override
  void initWithValue(String? value) {}
  @override
  Object? toPrimitives() => null;
}

mixin RestorationMixin<S extends StatefulWidget> on State<S> {
  String? get restorationId;
  RestorationBucket? get bucket => _bucket;
  RestorationBucket? _bucket;
  bool get restorePending => false;
  void restoreState(RestorationBucket? oldBucket, bool initialRestore);

  void registerForRestoration(
    RestorableProperty<Object?> property,
    String restorationId,
  ) {
    property._registered = true;
    if (property is RestorableValue<Object?> && !property._initialized) {
      property.initWithValue(property.createDefaultValue());
    }
    if (property is RestorableRouteFuture) property._context = context;
  }

  void unregisterFromRestoration(RestorableProperty<Object?> property) =>
      property._registered = false;

  void didUpdateRestorationId() {}
  void didToggleBucket(RestorationBucket? oldBucket) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bucket == null) {
      _bucket = RestorationBucket.empty(restorationId: restorationId ?? '');
      restoreState(null, true);
    }
  }
}

class RootRestorationScope extends StatelessWidget {
  const RootRestorationScope({
    super.key,
    required this.restorationId,
    required this.child,
  });
  final String? restorationId;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class RestorationScope extends StatelessWidget {
  const RestorationScope({
    super.key,
    required this.restorationId,
    required this.child,
  });
  final String? restorationId;
  final Widget child;
  static RestorationBucket? maybeOf(BuildContext context) => null;
  @override
  Widget build(BuildContext context) => child;
}

// ---------------------------------------------------------------------------
// More transitions and implicit animations.

class RelativeRectTween extends Tween<RelativeRect> {
  RelativeRectTween({super.begin, super.end});
  @override
  RelativeRect lerp(double t) => RelativeRect.lerp(begin, end, t)!;
}

class AlignTransition extends AnimatedWidget {
  const AlignTransition({
    super.key,
    required Animation<AlignmentGeometry> alignment,
    required this.child,
    this.widthFactor,
    this.heightFactor,
  }) : super(listenable: alignment);
  Animation<AlignmentGeometry> get alignment =>
      listenable as Animation<AlignmentGeometry>;
  final Widget child;
  final double? widthFactor, heightFactor;
  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment.value,
    widthFactor: widthFactor,
    heightFactor: heightFactor,
    child: child,
  );
}

class PositionedTransition extends AnimatedWidget {
  const PositionedTransition({
    super.key,
    required Animation<RelativeRect> rect,
    required this.child,
  }) : super(listenable: rect);
  Animation<RelativeRect> get rect => listenable as Animation<RelativeRect>;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Positioned.fromRelativeRect(rect: rect.value, child: child);
}

class RelativePositionedTransition extends AnimatedWidget {
  const RelativePositionedTransition({
    super.key,
    required Animation<Rect?> rect,
    required this.size,
    required this.child,
  }) : super(listenable: rect);
  Animation<Rect?> get rect => listenable as Animation<Rect?>;
  final Size size;
  final Widget child;
  @override
  Widget build(BuildContext context) => Positioned.fromRelativeRect(
    rect: RelativeRect.fromSize(rect.value ?? Rect.zero, size),
    child: child,
  );
}

class DecoratedBoxTransition extends AnimatedWidget {
  const DecoratedBoxTransition({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    required this.child,
  }) : super(listenable: decoration);
  final Animation<Decoration> decoration;
  final DecorationPosition position;
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: decoration.value,
    position: position,
    child: child,
  );
}

class DefaultTextStyleTransition extends AnimatedWidget {
  const DefaultTextStyleTransition({
    super.key,
    required Animation<TextStyle> style,
    required this.child,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  }) : super(listenable: style);
  Animation<TextStyle> get style => listenable as Animation<TextStyle>;
  final Widget child;
  final TextAlign? textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: style.value,
    textAlign: textAlign,
    softWrap: softWrap,
    overflow: overflow,
    maxLines: maxLines,
    child: child,
  );
}

class SliverFadeTransition extends AnimatedWidget {
  const SliverFadeTransition({
    super.key,
    required Animation<double> opacity,
    this.alwaysIncludeSemantics = false,
    this.sliver,
  }) : super(listenable: opacity);
  Animation<double> get opacity => listenable as Animation<double>;
  final bool alwaysIncludeSemantics;
  final Widget? sliver;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity.value.clamp(0.0, 1.0),
    child: sliver ?? const SizedBox.shrink(),
  );
}

class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    this.alignment = Alignment.center,
    this.child,
    this.heightFactor,
    this.widthFactor,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final AlignmentGeometry alignment;
  final Widget? child;
  final double? heightFactor, widthFactor;
  @override
  State<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends _ImplicitState<AnimatedFractionallySizedBox> {
  late final _width = track<double?>(lerpDouble, widget.widthFactor);
  late final _height = track<double?>(lerpDouble, widget.heightFactor);
  @override
  bool retarget() =>
      _width.retarget(widget.widthFactor, t) |
      _height.retarget(widget.heightFactor, t);
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: widget.alignment,
    widthFactor: _width.at(t),
    heightFactor: _height.at(t),
    child: widget.child,
  );
}

class AnimatedPhysicalModel extends ImplicitlyAnimatedWidget {
  const AnimatedPhysicalModel({
    super.key,
    required this.child,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    required this.elevation,
    required this.color,
    this.animateColor = true,
    required this.shadowColor,
    this.animateShadowColor = true,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final Widget child;
  final BoxShape shape;
  final Clip clipBehavior;
  final BorderRadius? borderRadius;
  final double elevation;
  final Color color, shadowColor;
  final bool animateColor, animateShadowColor;
  @override
  State<AnimatedPhysicalModel> createState() => _AnimatedPhysicalModelState();
}

class _AnimatedPhysicalModelState
    extends _ImplicitState<AnimatedPhysicalModel> {
  late final _elevation = track<double>(_lerpNum, widget.elevation);
  late final _color = track<Color?>(Color.lerp, widget.color);
  @override
  bool retarget() =>
      _elevation.retarget(widget.elevation, t) |
      (widget.animateColor && _color.retarget(widget.color, t));
  @override
  Widget build(BuildContext context) => PhysicalModel(
    shape: widget.shape,
    clipBehavior: widget.clipBehavior,
    borderRadius: widget.borderRadius,
    elevation: _elevation.at(t),
    color: widget.animateColor ? _color.at(t)! : widget.color,
    shadowColor: widget.shadowColor,
    child: widget.child,
  );
}

/// Switches themes without interpolating every color.
class AnimatedTheme extends StatelessWidget {
  const AnimatedTheme({
    super.key,
    required this.data,
    this.curve = Curves.linear,
    this.duration = kThemeAnimationDuration,
    this.onEnd,
    required this.child,
  });
  final ThemeData data;
  final Curve curve;
  final Duration duration;
  final VoidCallback? onEnd;
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(data: data, child: child);
}

const kThemeAnimationDuration = Duration(milliseconds: 200);
const kTabScrollDuration = Duration(milliseconds: 300);
const kRadialReactionDuration = Duration(milliseconds: 100);
