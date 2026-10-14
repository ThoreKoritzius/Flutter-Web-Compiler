/// `dart:ui` painting values for the native runtime: paints, paths, shaders
/// and the [Canvas] interface implemented over an HTML canvas. Pure data;
/// the DOM-backed canvas lives in the widget runtime.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'material_style.dart';
import 'visual_metadata.dart';

enum PaintingStyle { fill, stroke }

enum StrokeCap { butt, round, square }

enum StrokeJoin { miter, round, bevel }

enum PathFillType { nonZero, evenOdd }

enum TileMode { clamp, repeated, mirror, decal }

enum ClipOp { difference, intersect }

enum PointMode { points, lines, polygon }

enum FilterQuality { none, low, medium, high }

enum BlurStyle { normal, solid, outer, inner }

/// Only [srcOver] (the default) is supported when painting.
enum BlendMode {
  clear,
  src,
  dst,
  srcOver,
  dstOver,
  srcIn,
  dstIn,
  srcOut,
  dstOut,
  srcATop,
  dstATop,
  xor,
  plus,
  modulate,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  multiply,
  hue,
  saturation,
  color,
  luminosity,
}

class MaskFilter {
  const MaskFilter.blur(this.style, this.sigma);
  final BlurStyle style;
  final double sigma;
}

/// A linear or radial gradient in canvas coordinates.
class Shader {
  Shader.linear(
    Offset from,
    Offset to,
    List<Color> colors, [
    List<double>? stops,
  ]) : this._(0, from, to, 0, colors, stops);
  Shader.radial(
    Offset center,
    double radius,
    List<Color> colors, [
    List<double>? stops,
  ]) : this._(1, center, center, radius, colors, stops);
  Shader._(
    this._kind,
    this._from,
    this._to,
    this._radius,
    this._colors,
    this._stops,
  ) {
    if (_colors.length < 2) throw ArgumentError('Shaders need two colors.');
    if (_stops != null && _stops.length != _colors.length)
      throw ArgumentError('Shader stops must match colors.');
  }
  final int _kind;
  final Offset _from, _to;
  final double _radius;
  final List<Color> _colors;
  final List<double>? _stops;
}

/// Read access for the DOM canvas; not part of the public `dart:ui` surface.
({
  bool radial,
  Offset from,
  Offset to,
  double radius,
  List<Color> colors,
  List<double> stops,
})
shaderSpec(Shader shader) => (
  radial: shader._kind == 1,
  from: shader._from,
  to: shader._to,
  radius: shader._radius,
  colors: shader._colors,
  stops:
      shader._stops ??
      [
        for (var i = 0; i < shader._colors.length; i++)
          i / (shader._colors.length - 1),
      ],
);

class Paint {
  Paint();
  Color color = const Color(0xff000000);
  PaintingStyle style = PaintingStyle.fill;
  double strokeWidth = 0;
  StrokeCap strokeCap = StrokeCap.butt;
  StrokeJoin strokeJoin = StrokeJoin.miter;
  double strokeMiterLimit = 4;
  Shader? shader;
  bool isAntiAlias = true;
  BlendMode blendMode = BlendMode.srcOver;
  MaskFilter? maskFilter;
  FilterQuality filterQuality = FilterQuality.none;
  bool invertColors = false;
}

/// Receives replayed path commands.
abstract interface class PathSink {
  void moveTo(double x, double y);
  void lineTo(double x, double y);
  void quadraticTo(double x1, double y1, double x2, double y2);
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  );
  void ellipse(
    double cx,
    double cy,
    double rx,
    double ry,
    double start,
    double end,
    bool counterClockwise,
  );
  void close();
}

sealed class _PathCommand {}

class _Move extends _PathCommand {
  _Move(this.x, this.y);
  final double x, y;
}

class _Line extends _PathCommand {
  _Line(this.x, this.y);
  final double x, y;
}

class _Quad extends _PathCommand {
  _Quad(this.x1, this.y1, this.x2, this.y2);
  final double x1, y1, x2, y2;
}

class _Cubic extends _PathCommand {
  _Cubic(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);
  final double x1, y1, x2, y2, x3, y3;
}

class _Ellipse extends _PathCommand {
  _Ellipse(this.cx, this.cy, this.rx, this.ry, this.start, this.end, this.ccw);
  final double cx, cy, rx, ry, start, end;
  final bool ccw;
}

class _Close extends _PathCommand {}

class Path {
  Path();
  factory Path.from(Path source) => Path()
    .._commands.addAll(source._commands)
    ..fillType = source.fillType
    .._current = source._current
    .._start = source._start;
  final _commands = <_PathCommand>[];
  PathFillType fillType = PathFillType.nonZero;
  Offset _current = Offset.zero;
  Offset _start = Offset.zero;

  void _point(double x, double y) {
    if (!x.isFinite || !y.isFinite)
      throw ArgumentError('Path coordinates must be finite.');
  }

  void moveTo(double x, double y) {
    _point(x, y);
    _commands.add(_Move(x, y));
    _current = _start = Offset(x, y);
  }

  void relativeMoveTo(double dx, double dy) =>
      moveTo(_current.dx + dx, _current.dy + dy);

  void lineTo(double x, double y) {
    _point(x, y);
    _commands.add(_Line(x, y));
    _current = Offset(x, y);
  }

  void relativeLineTo(double dx, double dy) =>
      lineTo(_current.dx + dx, _current.dy + dy);

  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _point(x1, y1);
    _point(x2, y2);
    _commands.add(_Quad(x1, y1, x2, y2));
    _current = Offset(x2, y2);
  }

  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    final o = _current;
    quadraticBezierTo(o.dx + x1, o.dy + y1, o.dx + x2, o.dy + y2);
  }

  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    _point(x1, y1);
    _point(x2, y2);
    _point(x3, y3);
    _commands.add(_Cubic(x1, y1, x2, y2, x3, y3));
    _current = Offset(x3, y3);
  }

  void relativeCubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    final o = _current;
    cubicTo(o.dx + x1, o.dy + y1, o.dx + x2, o.dy + y2, o.dx + x3, o.dy + y3);
  }

  /// Conics are approximated by quadratics (exact only for weight 1).
  void conicTo(double x1, double y1, double x2, double y2, double w) =>
      quadraticBezierTo(x1, y1, x2, y2);

  void _ellipse(Rect oval, double start, double sweep) {
    final end = start + sweep;
    _commands.add(
      _Ellipse(
        oval.center.dx,
        oval.center.dy,
        oval.width / 2,
        oval.height / 2,
        start,
        end,
        sweep < 0,
      ),
    );
    _current = Offset(
      oval.center.dx + oval.width / 2 * math.cos(end),
      oval.center.dy + oval.height / 2 * math.sin(end),
    );
  }

  void arcTo(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool forceMoveTo,
  ) {
    final start = Offset(
      rect.center.dx + rect.width / 2 * math.cos(startAngle),
      rect.center.dy + rect.height / 2 * math.sin(startAngle),
    );
    if (forceMoveTo || _commands.isEmpty) {
      moveTo(start.dx, start.dy);
    } else {
      lineTo(start.dx, start.dy);
    }
    _ellipse(rect, startAngle, sweepAngle);
  }

  /// SVG-style endpoint arcs, converted to center parameterization.
  void arcToPoint(
    Offset arcEnd, {
    Radius radius = Radius.zero,
    double rotation = 0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    if (rotation != 0)
      throw UnsupportedError('Rotated path arcs are unsupported.');
    var rx = radius.x.abs(), ry = radius.y.abs();
    final p0 = _current;
    if (rx == 0 || ry == 0 || p0 == arcEnd) {
      lineTo(arcEnd.dx, arcEnd.dy);
      return;
    }
    final dx = (p0.dx - arcEnd.dx) / 2, dy = (p0.dy - arcEnd.dy) / 2;
    final lambda = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry);
    if (lambda > 1) {
      rx *= math.sqrt(lambda);
      ry *= math.sqrt(lambda);
    }
    final sign = largeArc == clockwise ? -1 : 1;
    final numerator = rx * rx * ry * ry - rx * rx * dy * dy - ry * ry * dx * dx;
    final denominator = rx * rx * dy * dy + ry * ry * dx * dx;
    final coefficient = sign * math.sqrt(math.max(0, numerator / denominator));
    final cxp = coefficient * rx * dy / ry;
    final cyp = coefficient * -ry * dx / rx;
    final cx = cxp + (p0.dx + arcEnd.dx) / 2;
    final cy = cyp + (p0.dy + arcEnd.dy) / 2;
    double angle(double ux, double uy, double vx, double vy) {
      final a = math.atan2(ux * vy - uy * vx, ux * vx + uy * vy);
      return a;
    }

    final start = angle(1, 0, (dx - cxp) / rx, (dy - cyp) / ry);
    var sweep = angle(
      (dx - cxp) / rx,
      (dy - cyp) / ry,
      (-dx - cxp) / rx,
      (-dy - cyp) / ry,
    );
    if (clockwise && sweep < 0) sweep += 2 * math.pi;
    if (!clockwise && sweep > 0) sweep -= 2 * math.pi;
    _ellipse(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      start,
      sweep,
    );
    _current = arcEnd;
  }

  void addRect(Rect rect) {
    moveTo(rect.left, rect.top);
    lineTo(rect.right, rect.top);
    lineTo(rect.right, rect.bottom);
    lineTo(rect.left, rect.bottom);
    close();
  }

  void addOval(Rect oval) {
    moveTo(oval.right, oval.center.dy);
    _ellipse(oval, 0, 2 * math.pi);
    close();
  }

  void addArc(Rect oval, double startAngle, double sweepAngle) =>
      arcTo(oval, startAngle, sweepAngle, true);

  void addRRect(RRect rrect) {
    final l = rrect.left, t = rrect.top, r = rrect.right, b = rrect.bottom;
    final tl = rrect.topLeft, tr = rrect.topRight;
    final br = rrect.bottomRight, bl = rrect.bottomLeft;
    moveTo(l + tl.x, t);
    lineTo(r - tr.x, t);
    if (tr.x > 0 && tr.y > 0)
      _ellipse(
        Rect.fromLTWH(r - tr.x * 2, t, tr.x * 2, tr.y * 2),
        -math.pi / 2,
        math.pi / 2,
      );
    lineTo(r, b - br.y);
    if (br.x > 0 && br.y > 0)
      _ellipse(
        Rect.fromLTWH(r - br.x * 2, b - br.y * 2, br.x * 2, br.y * 2),
        0,
        math.pi / 2,
      );
    lineTo(l + bl.x, b);
    if (bl.x > 0 && bl.y > 0)
      _ellipse(
        Rect.fromLTWH(l, b - bl.y * 2, bl.x * 2, bl.y * 2),
        math.pi / 2,
        math.pi / 2,
      );
    lineTo(l, t + tl.y);
    if (tl.x > 0 && tl.y > 0)
      _ellipse(Rect.fromLTWH(l, t, tl.x * 2, tl.y * 2), math.pi, math.pi / 2);
    close();
  }

  void addPolygon(List<Offset> points, bool close) {
    if (points.isEmpty) return;
    moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      lineTo(point.dx, point.dy);
    }
    if (close) this.close();
  }

  void addPath(Path path, Offset offset, {Float64List? matrix4}) {
    if (matrix4 != null)
      throw UnsupportedError('Path matrices are unsupported.');
    final shifted = path.shift(offset);
    _commands.addAll(shifted._commands);
    _current = shifted._current;
  }

  void extendWithPath(Path path, Offset offset, {Float64List? matrix4}) =>
      addPath(path, offset, matrix4: matrix4);

  void close() {
    _commands.add(_Close());
    _current = _start;
  }

  void reset() {
    _commands.clear();
    _current = _start = Offset.zero;
  }

  Path shift(Offset offset) {
    final dx = offset.dx, dy = offset.dy;
    final path = Path()..fillType = fillType;
    for (final c in _commands) {
      path._commands.add(switch (c) {
        _Move() => _Move(c.x + dx, c.y + dy),
        _Line() => _Line(c.x + dx, c.y + dy),
        _Quad() => _Quad(c.x1 + dx, c.y1 + dy, c.x2 + dx, c.y2 + dy),
        _Cubic() => _Cubic(
          c.x1 + dx,
          c.y1 + dy,
          c.x2 + dx,
          c.y2 + dy,
          c.x3 + dx,
          c.y3 + dy,
        ),
        _Ellipse() => _Ellipse(
          c.cx + dx,
          c.cy + dy,
          c.rx,
          c.ry,
          c.start,
          c.end,
          c.ccw,
        ),
        _Close() => _Close(),
      });
    }
    path._current = _current + offset;
    path._start = _start + offset;
    return path;
  }

  /// Bounds of the control points (a superset of the exact bounds).
  Rect getBounds() {
    if (_commands.isEmpty) return Rect.zero;
    var left = double.infinity, top = double.infinity;
    var right = -double.infinity, bottom = -double.infinity;
    void add(double x, double y) {
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }

    for (final c in _commands) {
      switch (c) {
        case _Move():
          add(c.x, c.y);
        case _Line():
          add(c.x, c.y);
        case _Quad():
          add(c.x1, c.y1);
          add(c.x2, c.y2);
        case _Cubic():
          add(c.x1, c.y1);
          add(c.x2, c.y2);
          add(c.x3, c.y3);
        case _Ellipse():
          add(c.cx - c.rx, c.cy - c.ry);
          add(c.cx + c.rx, c.cy + c.ry);
        case _Close():
      }
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Object computeMetrics({bool forceClosed = false}) =>
      throw UnsupportedError('Path metrics are unsupported.');
}

/// Replays [path] into [sink]; used by the DOM canvas.
void replayPath(Path path, PathSink sink) {
  for (final c in path._commands) {
    switch (c) {
      case _Move():
        sink.moveTo(c.x, c.y);
      case _Line():
        sink.lineTo(c.x, c.y);
      case _Quad():
        sink.quadraticTo(c.x1, c.y1, c.x2, c.y2);
      case _Cubic():
        sink.cubicTo(c.x1, c.y1, c.x2, c.y2, c.x3, c.y3);
      case _Ellipse():
        sink.ellipse(c.cx, c.cy, c.rx, c.ry, c.start, c.end, c.ccw);
      case _Close():
        sink.close();
    }
  }
}

/// Flutter's painting surface. Instances are provided by `CustomPaint`.
abstract interface class Canvas {
  void save();
  void saveLayer(Rect? bounds, Paint paint);
  void restore();
  int getSaveCount();
  void translate(double dx, double dy);
  void scale(double sx, [double? sy]);
  void rotate(double radians);
  void skew(double sx, double sy);
  void transform(Float64List matrix4);
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  });
  void clipRRect(RRect rrect, {bool doAntiAlias = true});
  void clipPath(Path path, {bool doAntiAlias = true});
  void drawColor(Color color, BlendMode blendMode);
  void drawPaint(Paint paint);
  void drawLine(Offset p1, Offset p2, Paint paint);
  void drawRect(Rect rect, Paint paint);
  void drawRRect(RRect rrect, Paint paint);
  void drawDRRect(RRect outer, RRect inner, Paint paint);
  void drawOval(Rect rect, Paint paint);
  void drawCircle(Offset c, double radius, Paint paint);
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  );
  void drawPath(Path path, Paint paint);
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint);
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  );
}

/// The `dart:ui` gradient shader (distinct from the painting `Gradient`).
class UiGradient extends Shader {
  UiGradient.linear(
    super.from,
    super.to,
    super.colors, [
    super.stops,
    TileMode tileMode = TileMode.clamp,
    Float64List? matrix4,
  ]) : super.linear() {
    if (tileMode != TileMode.clamp || matrix4 != null)
      throw UnsupportedError('Only clamped, untransformed gradients.');
  }
  UiGradient.radial(
    super.center,
    super.radius,
    super.colors, [
    super.stops,
    TileMode tileMode = TileMode.clamp,
    Float64List? matrix4,
  ]) : super.radial() {
    if (tileMode != TileMode.clamp || matrix4 != null)
      throw UnsupportedError('Only clamped, untransformed gradients.');
  }
}

double? lerpDouble(num? a, num? b, double t) {
  if (a == b || (a?.isNaN ?? false) && (b?.isNaN ?? false))
    return a?.toDouble();
  a ??= 0.0;
  b ??= 0.0;
  return a * (1.0 - t) + b * t;
}

/// Image filters map to CSS filters where the runtime applies them
/// (`BackdropFilter`, `ImageFiltered`).
class ImageFilter {
  ImageFilter.blur({
    this.sigmaX = 0,
    this.sigmaY = 0,
    this.tileMode = TileMode.clamp,
  }) : _matrix = null,
       _inner = null,
       _outer = null;
  ImageFilter.matrix(
    Float64List matrix4, {
    FilterQuality filterQuality = FilterQuality.low,
  }) : sigmaX = 0,
       sigmaY = 0,
       tileMode = TileMode.clamp,
       _matrix = matrix4,
       _inner = null,
       _outer = null;
  ImageFilter.compose({required ImageFilter outer, required ImageFilter inner})
    : sigmaX = 0,
      sigmaY = 0,
      tileMode = TileMode.clamp,
      _matrix = null,
      _inner = inner,
      _outer = outer;
  final double sigmaX, sigmaY;
  final TileMode tileMode;
  final Float64List? _matrix;
  final ImageFilter? _inner, _outer;
}

/// The CSS `filter` value for [filter]; matrix filters are not mapped.
String imageFilterCss(ImageFilter filter) {
  if (filter._inner != null) {
    return '${imageFilterCss(filter._inner)} ${imageFilterCss(filter._outer!)}'
        .trim();
  }
  if (filter._matrix != null) return '';
  final sigma = (filter.sigmaX + filter.sigmaY) / 2;
  return sigma <= 0 ? '' : 'blur(${sigma.toStringAsFixed(2)}px)';
}

class ColorFilter {
  const ColorFilter.mode(Color this.color, BlendMode this.blendMode)
    : matrix = null,
      _kind = 0;
  const ColorFilter.matrix(List<double> this.matrix)
    : color = null,
      blendMode = null,
      _kind = 1;
  const ColorFilter.linearToSrgbGamma()
    : color = null,
      blendMode = null,
      matrix = null,
      _kind = 2;
  const ColorFilter.srgbToLinearGamma()
    : color = null,
      blendMode = null,
      matrix = null,
      _kind = 3;
  final Color? color;
  final BlendMode? blendMode;
  final List<double>? matrix;
  final int _kind;
}

/// The CSS `filter` approximating [filter]: saturation and color modes
/// with a transparent or grey source become `grayscale`/`opacity`; a
/// greyscale matrix becomes `grayscale(1)`. Other filters are not mapped.
String colorFilterCss(ColorFilter filter) {
  if (filter._kind == 0) {
    final color = filter.color!;
    switch (filter.blendMode) {
      case BlendMode.saturation:
        return 'grayscale(1)';
      case BlendMode.dstIn:
        return 'opacity(${(color.a).toStringAsFixed(3)})';
      default:
        return '';
    }
  }
  final m = filter.matrix;
  if (filter._kind == 1 && m != null && m.length == 20) {
    bool near(double a, double b) => (a - b).abs() < 0.02;
    final grey =
        near(m[0], m[5]) &&
        near(m[5], m[10]) &&
        near(m[1], m[6]) &&
        near(m[6], m[11]) &&
        near(m[2], m[7]) &&
        near(m[7], m[12]);
    if (grey) return 'grayscale(1)';
  }
  return '';
}
