part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Layout, painting and composition helpers mapped to CSS.

/// Scales its child to fit; the child's natural size is measured after
/// layout and a CSS transform applies [fit].
class FittedBox extends StatefulWidget {
  const FittedBox({
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.none,
    this.child,
  });
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Clip clipBehavior;
  final Widget? child;
  @override
  State<FittedBox> createState() => _FittedBoxState();
}

class _FittedBoxState extends State<FittedBox> {
  double _scale = 1;

  void _measure() {
    if (!mounted) return;
    final outer = _liveNode(context);
    final inner = outer?.getProperty<JSObject?>('firstElementChild'.toJS);
    if (outer == null || inner == null) return;
    final box = _clientRect(outer);
    final width = _jsNumber(inner, 'scrollWidth');
    final height = _jsNumber(inner, 'scrollHeight');
    if (box == null || width <= 0 || height <= 0 || box.width <= 0) return;
    final sx = box.width / width;
    final sy = box.height > 0 ? box.height / height : sx;
    var scale = switch (widget.fit) {
      BoxFit.contain || BoxFit.scaleDown => math.min(sx, sy),
      BoxFit.cover => math.max(sx, sy),
      BoxFit.fitWidth => sx,
      BoxFit.fitHeight => sy,
      BoxFit.fill || BoxFit.none => 1.0,
    };
    if (widget.fit == BoxFit.scaleDown) scale = math.min(scale, 1);
    if ((scale - _scale).abs() > 0.001) setState(() => _scale = scale);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final a = widget.alignment.resolve(Directionality.maybeOf(context));
    final origin =
        '${cssNumber((a.x + 1) * 50)}% ${cssNumber((a.y + 1) * 50)}%';
    final justify = a.x < 0 ? 'start' : (a.x > 0 ? 'end' : 'center');
    final alignItems = a.y < 0 ? 'start' : (a.y > 0 ? 'end' : 'center');
    return _Box(
      css:
          'display:grid;justify-items:$justify;align-items:$alignItems;min-width:0;${widget.clipBehavior == Clip.none ? '' : 'overflow:hidden;'}',
      layout: _DomLayout.grid,
      fill: _Fill.child,
      children: [
        _Box(
          css:
              'width:max-content;transform:scale(${cssNumber(_scale)});transform-origin:$origin;',
          fill: _Fill.none,
          children: [?widget.child],
        ),
      ],
    );
  }
}

/// Intrinsic sizing is the browser's default for content-sized boxes; rows
/// inside an [IntrinsicHeight] stretch children to the tallest one.
class IntrinsicHeight extends _DomWidget {
  const IntrinsicHeight({super.key, this.child});
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css(
      'display:grid;grid-template-columns:minmax(0,1fr);align-items:stretch;',
    );
    if (child != null) out.child(child!);
  }
}

class IntrinsicWidth extends _DomWidget {
  const IntrinsicWidth({
    super.key,
    this.stepWidth,
    this.stepHeight,
    this.child,
  });
  final double? stepWidth, stepHeight;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    out.css('display:grid;width:max-content;max-width:100%;');
    if (child != null) out.child(child!);
  }
}

class OverflowBox extends _DomWidget {
  const OverflowBox({
    super.key,
    this.alignment = Alignment.center,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.fit = OverflowBoxFit.max,
    this.child,
  });
  final AlignmentGeometry alignment;
  final double? minWidth, maxWidth, minHeight, maxHeight;
  final OverflowBoxFit fit;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    final a = alignment.resolve(TextDirection.ltr);
    out.css(
      'display:grid;overflow:visible;justify-items:${a.x < 0 ? 'start' : (a.x > 0 ? 'end' : 'center')};align-items:${a.y < 0 ? 'start' : (a.y > 0 ? 'end' : 'center')};',
    );
    if (child != null) {
      out.child(
        _Box(
          css:
              '${minWidth == null ? '' : 'min-width:${px(minWidth!)};'}${maxWidth == null || !maxWidth!.isFinite ? '' : 'max-width:${px(maxWidth!)};'}${minHeight == null ? '' : 'min-height:${px(minHeight!)};'}${maxHeight == null || !maxHeight!.isFinite ? '' : 'max-height:${px(maxHeight!)};'}',
          fill: _Fill.child,
          children: [child!],
        ),
      );
    }
  }
}

enum OverflowBoxFit { max, deferToChild }

class SizedOverflowBox extends StatelessWidget {
  const SizedOverflowBox({
    super.key,
    required this.size,
    this.alignment = Alignment.center,
    this.child,
  });
  final Size size;
  final AlignmentGeometry alignment;
  final Widget? child;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size.width,
    height: size.height,
    child: OverflowBox(alignment: alignment, child: child),
  );
}

/// Places the child's top at [baseline] minus its first baseline; the
/// browser aligns text baselines, so this pads the top by the difference
/// from the default ascent.
class Baseline extends StatelessWidget {
  const Baseline({
    super.key,
    required this.baseline,
    required this.baselineType,
    this.child,
  });
  final double baseline;
  final TextBaseline baselineType;
  final Widget? child;
  @override
  Widget build(BuildContext context) => _Box(
    css: 'display:flex;align-items:baseline;min-height:${px(baseline)};',
    layout: _DomLayout.row,
    fill: _Fill.child,
    children: [?child],
  );
}

class RotatedBox extends _DomWidget {
  const RotatedBox({super.key, required this.quarterTurns, this.child});
  final int quarterTurns;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    final turns = quarterTurns % 4;
    // Quarter turns swap width and height; vertical writing mode lets the
    // layout reserve the rotated size for odd turns.
    out.css(
      turns.isOdd
          ? 'display:grid;writing-mode:vertical-lr;${turns == 3 ? 'transform:rotate(180deg);' : ''}'
          : 'display:grid;${turns == 2 ? 'transform:rotate(180deg);' : ''}',
    );
    if (child != null) out.child(child!);
  }
}

// ---------------------------------------------------------------------------
// Clipping and filters.

abstract class CustomClipper<T> extends Listenable {
  const CustomClipper({Listenable? reclip}) : _reclip = reclip;
  final Listenable? _reclip;
  @override
  void addListener(VoidCallback listener) => _reclip?.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _reclip?.removeListener(listener);
  T getClip(Size size);
  Rect getApproximateClipRect(Size size) => Offset.zero & size;
  bool shouldReclip(covariant CustomClipper<T> oldClipper);
}

class ShapeBorderClipper extends CustomClipper<Path> {
  const ShapeBorderClipper({required this.shape, this.textDirection});
  final ShapeBorder shape;
  final TextDirection? textDirection;
  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    final shape = this.shape;
    if (shape is CircleBorder) return Path()..addOval(rect);
    if (shape is StadiumBorder) {
      return Path()..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2)),
      );
    }
    if (shape is RoundedRectangleBorder) {
      final r = shape.borderRadius.resolve(textDirection);
      return Path()..addRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: r.topLeft,
          topRight: r.topRight,
          bottomLeft: r.bottomLeft,
          bottomRight: r.bottomRight,
        ),
      );
    }
    return Path()..addRect(rect);
  }

  @override
  bool shouldReclip(ShapeBorderClipper oldClipper) => oldClipper.shape != shape;
}

/// Writes path commands as SVG path data.
class _SvgPathData implements PathSink {
  final _out = StringBuffer();
  String n(double v) => cssNumber(v);
  @override
  void moveTo(double x, double y) => _out.write('M${n(x)} ${n(y)}');
  @override
  void lineTo(double x, double y) => _out.write('L${n(x)} ${n(y)}');
  @override
  void quadraticTo(double x1, double y1, double x2, double y2) =>
      _out.write('Q${n(x1)} ${n(y1)} ${n(x2)} ${n(y2)}');
  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => _out.write('C${n(x1)} ${n(y1)} ${n(x2)} ${n(y2)} ${n(x3)} ${n(y3)}');
  @override
  void ellipse(
    double cx,
    double cy,
    double rx,
    double ry,
    double start,
    double end,
    bool counterClockwise,
  ) {
    Offset at(double angle) =>
        Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle));
    var sweep = counterClockwise ? start - end : end - start;
    final from = at(start);
    _out.write('L${n(from.dx)} ${n(from.dy)}');
    // SVG arcs cannot draw a full turn; split it in halves.
    if (sweep.abs() >= 2 * math.pi - 1e-6) {
      final mid = at(start + (counterClockwise ? -math.pi : math.pi));
      final flag = counterClockwise ? 0 : 1;
      _out.write('A${n(rx)} ${n(ry)} 0 0 $flag ${n(mid.dx)} ${n(mid.dy)}');
      _out.write('A${n(rx)} ${n(ry)} 0 0 $flag ${n(from.dx)} ${n(from.dy)}');
      return;
    }
    sweep = sweep.abs();
    final to = at(end);
    _out.write(
      'A${n(rx)} ${n(ry)} 0 ${sweep > math.pi ? 1 : 0} ${counterClockwise ? 0 : 1} ${n(to.dx)} ${n(to.dy)}',
    );
  }

  @override
  void close() => _out.write('Z');
  @override
  String toString() => _out.toString();
}

String _svgPath(Path path) {
  final sink = _SvgPathData();
  replayPath(path, sink);
  return sink.toString();
}

/// Clips to a path computed from the measured size, via CSS `clip-path`.
class ClipPath extends StatelessWidget {
  const ClipPath({
    super.key,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    this.child,
  });
  static Widget shape({
    Key? key,
    required ShapeBorder shape,
    Clip clipBehavior = Clip.antiAlias,
    Widget? child,
  }) => ClipPath(
    key: key,
    clipper: ShapeBorderClipper(shape: shape),
    clipBehavior: clipBehavior,
    child: child,
  );
  final CustomClipper<Path>? clipper;
  final Clip clipBehavior;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final clipper = this.clipper;
    if (clipper == null || clipBehavior == Clip.none) {
      return child ?? const SizedBox.shrink();
    }
    return _MeasuredClip(
      clip: (size) => 'clip-path:path("${_svgPath(clipper.getClip(size))}");',
      child: child,
    );
  }
}

class _MeasuredClip extends StatefulWidget {
  const _MeasuredClip({required this.clip, this.child});
  final String Function(Size size) clip;
  final Widget? child;
  @override
  State<_MeasuredClip> createState() => _MeasuredClipState();
}

class _MeasuredClipState extends State<_MeasuredClip> {
  Size? _size;
  void _measure() {
    if (!mounted) return;
    final node = _liveNode(context);
    final box = node == null ? null : _clientRect(node);
    if (box == null) return;
    final size = Size(box.width, box.height);
    if (size != _size) setState(() => _size = size);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final size = _size;
    return _Box(
      css:
          'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;${size == null ? '' : widget.clip(size)}',
      layout: _DomLayout.grid,
      fill: _Fill.child,
      children: [?widget.child],
    );
  }
}

class ColorFiltered extends _DomWidget {
  const ColorFiltered({super.key, required this.colorFilter, this.child});
  final ColorFilter colorFilter;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    final filter = colorFilterCss(colorFilter);
    out.css(
      'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;${filter.isEmpty ? '' : 'filter:$filter;'}',
    );
    if (child != null) out.child(child!);
  }
}

class ImageFiltered extends _DomWidget {
  const ImageFiltered({
    super.key,
    required this.imageFilter,
    this.enabled = true,
    this.child,
  });
  final ImageFilter imageFilter;
  final bool enabled;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    final filter = enabled ? imageFilterCss(imageFilter) : '';
    out.css(
      'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;${filter.isEmpty ? '' : 'filter:$filter;'}',
    );
    if (child != null) out.child(child!);
  }
}

/// Filters what is painted behind the child (CSS `backdrop-filter`).
class BackdropFilter extends _DomWidget {
  const BackdropFilter({
    super.key,
    required this.filter,
    this.child,
    this.blendMode = BlendMode.srcOver,
    this.enabled = true,
    this.backdropGroupKey,
  });
  final ImageFilter filter;
  final Widget? child;
  final BlendMode blendMode;
  final bool enabled;
  final Object? backdropGroupKey;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    final css = enabled ? imageFilterCss(filter) : '';
    out.css(
      'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;${css.isEmpty ? '' : 'backdrop-filter:$css;-webkit-backdrop-filter:$css;'}',
    );
    if (child != null) out.child(child!);
  }
}

typedef ShaderCallback = Shader Function(Rect bounds);

/// Gradient shaders map to CSS: `dstIn`/`dstATop`/`modulate` mask the
/// child, `srcIn`/`srcATop` paint the gradient through glyphs (gradient
/// text and icons). Other blend modes leave the child unchanged.
class ShaderMask extends _DomWidget {
  const ShaderMask({
    super.key,
    required this.shaderCallback,
    this.blendMode = BlendMode.modulate,
    this.child,
  });
  final ShaderCallback shaderCallback;
  final BlendMode blendMode;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('display:grid;grid-template-columns:minmax(0,1fr);min-width:0;');
    // A 100×100 rect makes shader coordinates read as percentages.
    final spec = shaderSpec(
      shaderCallback(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    final stops = [
      for (var i = 0; i < spec.colors.length; i++)
        '${colorCss(spec.colors[i])} ${cssNumber(spec.stops[i] * 100)}%',
    ].join(',');
    final String gradient;
    if (spec.radial) {
      gradient =
          'radial-gradient(circle ${cssNumber(spec.radius)}% at ${cssNumber(spec.from.dx)}% ${cssNumber(spec.from.dy)}%,$stops)';
    } else {
      final delta = spec.to - spec.from;
      final angle = math.atan2(delta.dx, -delta.dy) * 180 / math.pi;
      gradient = 'linear-gradient(${cssNumber(angle)}deg,$stops)';
    }
    switch (blendMode) {
      case BlendMode.dstIn || BlendMode.dstATop || BlendMode.modulate:
        out.css('-webkit-mask-image:$gradient;mask-image:$gradient;');
      case BlendMode.srcIn || BlendMode.srcATop:
        out.css(
          'background-image:$gradient;-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent;',
        );
      default:
        break;
    }
    if (child != null) out.child(child!);
  }
}

// ---------------------------------------------------------------------------
// Miscellaneous framework widgets.

class FlutterLogo extends StatelessWidget {
  const FlutterLogo({
    super.key,
    this.size,
    this.textColor = const Color(0xFF757575),
    this.style = FlutterLogoStyle.markOnly,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.fastOutSlowIn,
  });
  final double? size;
  final Color textColor;
  final FlutterLogoStyle style;
  final Duration duration;
  final Curve curve;
  @override
  Widget build(BuildContext context) {
    final extent = size ?? IconTheme.of(context).size ?? 24;
    return SizedBox(
      width: extent,
      height: extent,
      child: CustomPaint(painter: _FlutterLogoPainter()),
    );
  }
}

enum FlutterLogoStyle { markOnly, horizontal, stacked }

class _FlutterLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 166;
    Path poly(List<double> points) {
      final path = Path()..moveTo(points[0] * s, points[1] * s);
      for (var i = 2; i < points.length; i += 2) {
        path.lineTo(points[i] * s, points[i + 1] * s);
      }
      return path..close();
    }

    canvas.drawPath(
      poly([37.7, 128.9, 9.8, 101, 100.4, 10.4, 156.2, 10.4]),
      Paint()..color = const Color(0xFF42A5F5),
    );
    canvas.drawPath(
      poly([156.2, 94, 100.4, 94, 79.5, 114.9, 107.4, 142.8]),
      Paint()..color = const Color(0xFF42A5F5),
    );
    canvas.drawPath(
      poly([79.5, 170.7, 100.4, 191.6, 156.2, 191.6, 107.4, 142.8]),
      Paint()..color = const Color(0xFF0D47A1),
    );
    canvas.drawPath(
      poly([79.5, 114.9, 107.4, 142.8, 79.5, 170.7, 51.6, 142.8]),
      Paint()..color = const Color(0xFF1E88E5),
    );
  }

  @override
  bool shouldRepaint(_FlutterLogoPainter oldDelegate) => false;
}

/// The widget Flutter shows for build errors; [builder] can be replaced.
class ErrorWidget extends StatelessWidget {
  ErrorWidget(Object exception) : message = '$exception', super(key: null);
  ErrorWidget.withDetails({this.message = '', Object? error})
    : super(key: null);
  final String message;
  static Widget Function(Object details) builder = (details) =>
      ErrorWidget(details);
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'box-sizing:border-box;padding:8px;background:#b71c1c;color:#ffff00;font:14px monospace;white-space:pre-wrap;',
    attributes: const {'role': 'alert'},
    fill: _Fill.expand,
    children: [Text(message)],
  );
}

class TickerMode extends StatelessWidget {
  const TickerMode({super.key, required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TickerModeScope>()?.enabled ??
      true;
  @override
  Widget build(BuildContext context) =>
      _TickerModeScope(enabled: enabled, child: child);
}

class _TickerModeScope extends InheritedWidget {
  const _TickerModeScope({required this.enabled, required super.child});
  final bool enabled;
  @override
  bool updateShouldNotify(_TickerModeScope oldWidget) =>
      oldWidget.enabled != enabled;
}

/// Paints a decoration on the enclosing [Material]; the decoration sits
/// under ink splashes, which the runtime draws with CSS state layers.
class Ink extends StatelessWidget {
  Ink({
    super.key,
    this.padding,
    Color? color,
    Decoration? decoration,
    this.width,
    this.height,
    this.child,
  }) : decoration =
           decoration ?? (color == null ? null : BoxDecoration(color: color));
  Ink.image({
    super.key,
    this.padding,
    required ImageProvider image,
    ImageErrorListener? onImageError,
    ColorFilter? colorFilter,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Rect? centerSlice,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    bool matchTextDirection = false,
    this.width,
    this.height,
    this.child,
  }) : decoration = BoxDecoration(
         image: DecorationImage(image: image, fit: fit, alignment: alignment),
       );
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final double? width, height;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    padding: padding,
    decoration: decoration,
    child: child,
  );
}

typedef ImageErrorListener =
    void Function(Object exception, StackTrace? stackTrace);

typedef OrientationWidgetBuilder =
    Widget Function(BuildContext context, Orientation orientation);

class OrientationBuilder extends StatelessWidget {
  const OrientationBuilder({super.key, required this.builder});
  final OrientationWidgetBuilder builder;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = MediaQuery.maybeSizeOf(context)?.height ?? 0;
      return builder(
        context,
        constraints.maxWidth > height
            ? Orientation.landscape
            : Orientation.portrait,
      );
    },
  );
}

/// Heroes do not animate between routes; the child renders in place.
class Hero extends StatelessWidget {
  const Hero({
    super.key,
    required this.tag,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
    required this.child,
  });
  final Object tag;
  final Object? createRectTween, flightShuttleBuilder, placeholderBuilder;
  final bool transitionOnUserGestures;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class HeroMode extends StatelessWidget {
  const HeroMode({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  Widget build(BuildContext context) => child;
}

class DefaultAssetBundle extends InheritedWidget {
  const DefaultAssetBundle({
    super.key,
    required this.bundle,
    required super.child,
  });
  final AssetBundle bundle;
  static AssetBundle of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DefaultAssetBundle>()
          ?.bundle ??
      rootBundle;
  @override
  bool updateShouldNotify(DefaultAssetBundle oldWidget) =>
      oldWidget.bundle != bundle;
}

// ---------------------------------------------------------------------------
// Composited transforms: followers are positioned (fixed) relative to
// their target's viewport rectangle, updated after layout and on scroll or
// resize.

class LayerLink {
  LayerLink();
  BuildContext? _target;
  final _followers = <_CompositedTransformFollowerState>{};
  Size? get leaderSize {
    final target = _target;
    final node = target == null ? null : _liveNode(target);
    final box = node == null ? null : _clientRect(node);
    return box?.size;
  }

  void _changed() {
    for (final follower in List.of(_followers)) {
      follower._reposition();
    }
  }
}

class CompositedTransformTarget extends StatefulWidget {
  const CompositedTransformTarget({super.key, required this.link, this.child});
  final LayerLink link;
  final Widget? child;
  @override
  State<CompositedTransformTarget> createState() =>
      _CompositedTransformTargetState();
}

class _CompositedTransformTargetState extends State<CompositedTransformTarget> {
  @override
  Widget build(BuildContext context) {
    widget.link._target = context;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.link._changed());
    return _Box(
      css: 'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
      layout: _DomLayout.grid,
      fill: _Fill.child,
      children: [?widget.child],
    );
  }

  @override
  void dispose() {
    if (identical(widget.link._target, context)) widget.link._target = null;
    super.dispose();
  }
}

class CompositedTransformFollower extends StatefulWidget {
  const CompositedTransformFollower({
    super.key,
    required this.link,
    this.showWhenUnlinked = true,
    this.offset = Offset.zero,
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
    this.child,
  });
  final LayerLink link;
  final bool showWhenUnlinked;
  final Offset offset;
  final Alignment targetAnchor, followerAnchor;
  final Widget? child;
  @override
  State<CompositedTransformFollower> createState() =>
      _CompositedTransformFollowerState();
}

class _CompositedTransformFollowerState
    extends State<CompositedTransformFollower> {
  Offset? _position;
  JSFunction? _listener;

  @override
  void initState() {
    super.initState();
    widget.link._followers.add(this);
    _listener = ((JSAny? _) => _reposition()).toJS;
    (_window as JSObject).callMethod<JSAny?>(
      'addEventListener'.toJS,
      'scroll'.toJS,
      _listener,
      true.toJS,
    );
    _window.addEventListener('resize', _listener!);
  }

  @override
  void didUpdateWidget(CompositedTransformFollower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link != widget.link) {
      oldWidget.link._followers.remove(this);
      widget.link._followers.add(this);
    }
  }

  @override
  void dispose() {
    widget.link._followers.remove(this);
    (_window as JSObject).callMethod<JSAny?>(
      'removeEventListener'.toJS,
      'scroll'.toJS,
      _listener,
      true.toJS,
    );
    _window.removeEventListener('resize', _listener!);
    super.dispose();
  }

  void _reposition() {
    if (!mounted) return;
    final target = widget.link._target;
    final targetNode = target == null ? null : _liveNode(target);
    final targetBox = targetNode == null ? null : _clientRect(targetNode);
    final own = _liveNode(context);
    final ownBox = own == null ? null : _clientRect(own);
    if (targetBox == null) {
      if (_position != null) setState(() => _position = null);
      return;
    }
    final anchor = Offset(
      targetBox.left + (widget.targetAnchor.x + 1) / 2 * targetBox.width,
      targetBox.top + (widget.targetAnchor.y + 1) / 2 * targetBox.height,
    );
    final size = ownBox?.size ?? Size.zero;
    final next =
        anchor +
        widget.offset -
        Offset(
          (widget.followerAnchor.x + 1) / 2 * size.width,
          (widget.followerAnchor.y + 1) / 2 * size.height,
        );
    if (next != _position) setState(() => _position = next);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reposition());
    final position = _position;
    final visible = position != null || widget.showWhenUnlinked;
    return _Box(
      css:
          'position:fixed;z-index:20;left:${px(position?.dx ?? 0)};top:${px(position?.dy ?? 0)};${visible && position != null ? '' : 'visibility:hidden;'}',
      fill: _Fill.none,
      children: [?widget.child],
    );
  }
}

// ---------------------------------------------------------------------------
// Keep-alive and notifications.

/// Covered routes and offstage children stay mounted in this runtime, so
/// keep-alive needs no bookkeeping; the mixin keeps Flutter's API.
mixin AutomaticKeepAliveClientMixin<T extends StatefulWidget> on State<T> {
  bool get wantKeepAlive;
  void updateKeepAlive() {}
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class KeepAlive extends StatelessWidget {
  const KeepAlive({super.key, required this.keepAlive, required this.child});
  final bool keepAlive;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class AutomaticKeepAlive extends StatelessWidget {
  const AutomaticKeepAlive({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class RepaintBoundary extends StatelessWidget {
  const RepaintBoundary({super.key, this.child});
  RepaintBoundary.wrap(Widget child, int childIndex)
    : this(key: ValueKey<Object>(child.key ?? childIndex), child: child);
  final Widget? child;
  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

enum OverflowBarAlignment { start, end, center }

/// Lays children in a row and wraps them when they do not fit.
class OverflowBar extends StatelessWidget {
  const OverflowBar({
    super.key,
    this.spacing = 0,
    this.alignment,
    this.overflowSpacing = 0,
    this.overflowAlignment = OverflowBarAlignment.start,
    this.overflowDirection = VerticalDirection.down,
    this.textDirection,
    this.clipBehavior = Clip.none,
    this.children = const [],
  });
  final double spacing, overflowSpacing;
  final MainAxisAlignment? alignment;
  final OverflowBarAlignment overflowAlignment;
  final VerticalDirection overflowDirection;
  final TextDirection? textDirection;
  final Clip clipBehavior;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: spacing,
    runSpacing: overflowSpacing,
    alignment: switch (alignment) {
      MainAxisAlignment.end => WrapAlignment.end,
      MainAxisAlignment.center => WrapAlignment.center,
      MainAxisAlignment.spaceBetween => WrapAlignment.spaceBetween,
      MainAxisAlignment.spaceAround => WrapAlignment.spaceAround,
      MainAxisAlignment.spaceEvenly => WrapAlignment.spaceEvenly,
      _ => WrapAlignment.start,
    },
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

enum ButtonBarLayoutBehavior { constrained, padded }

class ButtonBar extends StatelessWidget {
  const ButtonBar({
    super.key,
    this.alignment,
    this.mainAxisSize,
    this.buttonTextTheme,
    this.buttonMinWidth,
    this.buttonHeight,
    this.buttonPadding,
    this.buttonAlignedDropdown,
    this.layoutBehavior,
    this.overflowDirection,
    this.overflowButtonSpacing,
    this.children = const [],
  });
  final MainAxisAlignment? alignment;
  final MainAxisSize? mainAxisSize;
  final Object? buttonTextTheme;
  final double? buttonMinWidth, buttonHeight, overflowButtonSpacing;
  final EdgeInsetsGeometry? buttonPadding;
  final bool? buttonAlignedDropdown;
  final ButtonBarLayoutBehavior? layoutBehavior;
  final VerticalDirection? overflowDirection;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: OverflowBar(
      spacing: 8,
      overflowSpacing: overflowButtonSpacing ?? 0,
      alignment: alignment ?? MainAxisAlignment.end,
      children: children,
    ),
  );
}

/// The browser window as Flutter's view.
class FlutterView {
  FlutterView._();
  double get devicePixelRatio =>
      (_window as JSObject)
          .getProperty<JSNumber?>('devicePixelRatio'.toJS)
          ?.toDartDouble ??
      1;
  Size get physicalSize =>
      Size(_window.innerWidth, _window.innerHeight) * devicePixelRatio;
  int get viewId => 0;
}

final _flutterView = FlutterView._();

class View extends InheritedWidget {
  const View({super.key, required this.view, required super.child});
  final FlutterView view;
  static FlutterView of(BuildContext context) => _flutterView;
  static FlutterView? maybeOf(BuildContext context) => _flutterView;
  @override
  bool updateShouldNotify(View oldWidget) => false;
}

/// Runtime support for bridge libraries: paints [color] through the image
/// at [url] used as a mask (tinted icons). Facades hide it from apps.
class NativeMaskedImage extends _DomWidget {
  const NativeMaskedImage({
    super.key,
    required this.url,
    required this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
  final String url;
  final Color color;
  final double? width, height;
  final BoxFit fit;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    final size = switch (fit) {
      BoxFit.cover => 'cover',
      BoxFit.fill => '100% 100%',
      _ => 'contain',
    };
    final mask = cssUrl(url);
    out.attributes['role'] = 'img';
    out.css(
      'display:inline-block;flex-shrink:0;box-sizing:border-box;width:${width == null ? '100%' : px(width!)};height:${height == null ? (width == null ? '100%' : px(width!)) : px(height!)};background-color:${colorCss(color)};-webkit-mask:$mask center/$size no-repeat;mask:$mask center/$size no-repeat;',
    );
  }
}
