part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Canvas 2D interop.

extension type _Ctx(JSObject _) implements JSObject {
  external void save();
  external void restore();
  external void translate(double x, double y);
  external void scale(double x, double y);
  external void rotate(double angle);
  external void transform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  );
  external void setTransform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  );
  external void beginPath();
  external void moveTo(double x, double y);
  external void lineTo(double x, double y);
  external void quadraticCurveTo(double x1, double y1, double x, double y);
  external void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  );
  external void ellipse(
    double x,
    double y,
    double rx,
    double ry,
    double rotation,
    double start,
    double end,
    bool counterClockwise,
  );
  external void closePath();
  external void fill(String fillRule);
  external void stroke();
  external void clip(String fillRule);
  external void clearRect(double x, double y, double w, double h);
  external void fillText(String text, double x, double y);
  external _TextMetrics measureText(String text);
  external void setLineDash(JSArray<JSNumber> segments);
  external set fillStyle(JSAny value);
  external set strokeStyle(JSAny value);
  external set lineWidth(double value);
  external set lineCap(String value);
  external set lineJoin(String value);
  external set miterLimit(double value);
  external set font(String value);
  external set textBaseline(String value);
  external set textAlign(String value);
  external set globalAlpha(double value);
  external set shadowColor(String value);
  external set shadowBlur(double value);
  external set shadowOffsetY(double value);
  external _CanvasGradient createLinearGradient(
    double x0,
    double y0,
    double x1,
    double y1,
  );
  external _CanvasGradient createRadialGradient(
    double x0,
    double y0,
    double r0,
    double x1,
    double y1,
    double r1,
  );
}

extension type _CanvasGradient(JSObject _) implements JSObject {
  external void addColorStop(double offset, String color);
}

extension type _TextMetrics(JSObject _) implements JSObject {
  external double get width;
}

extension on _Node {
  _Ctx get _context2d => _Ctx(
    (this as JSObject).callMethod<JSObject>('getContext'.toJS, '2d'.toJS),
  );
  double get _clientHeight => (this as JSObject)
      .getProperty<JSNumber>('clientHeight'.toJS)
      .toDartDouble;
  set _canvasWidth(int value) =>
      (this as JSObject).setProperty('width'.toJS, value.toJS);
  set _canvasHeight(int value) =>
      (this as JSObject).setProperty('height'.toJS, value.toJS);
}

double _devicePixelRatio() {
  final window = _window as JSObject;
  final ratio = window.getProperty<JSNumber?>('devicePixelRatio'.toJS);
  final value = ratio?.toDartDouble ?? 1;
  return value.isFinite && value > 0 ? math.min(value, 4) : 1;
}

_Ctx? _measureContext;
_Ctx get _measurer =>
    _measureContext ??= _document.createElement('canvas')._context2d;

// ---------------------------------------------------------------------------
// Canvas implementation.

class _DomCanvas implements Canvas, PathSink {
  _DomCanvas(this._ctx);
  final _Ctx _ctx;
  int _saveCount = 1;

  @override
  void moveTo(double x, double y) => _ctx.moveTo(x, y);
  @override
  void lineTo(double x, double y) => _ctx.lineTo(x, y);
  @override
  void quadraticTo(double x1, double y1, double x2, double y2) =>
      _ctx.quadraticCurveTo(x1, y1, x2, y2);
  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => _ctx.bezierCurveTo(x1, y1, x2, y2, x3, y3);
  @override
  void ellipse(
    double cx,
    double cy,
    double rx,
    double ry,
    double start,
    double end,
    bool counterClockwise,
  ) =>
      _ctx.ellipse(cx, cy, rx.abs(), ry.abs(), 0, start, end, counterClockwise);
  @override
  void close() => _ctx.closePath();

  JSAny _style(Paint paint) {
    final shader = paint.shader;
    if (shader == null) return colorCss(paint.color).toJS;
    final spec = shaderSpec(shader);
    final gradient = spec.radial
        ? _ctx.createRadialGradient(
            spec.from.dx,
            spec.from.dy,
            0,
            spec.from.dx,
            spec.from.dy,
            spec.radius,
          )
        : _ctx.createLinearGradient(
            spec.from.dx,
            spec.from.dy,
            spec.to.dx,
            spec.to.dy,
          );
    for (var i = 0; i < spec.colors.length; i++) {
      gradient.addColorStop(
        spec.stops[i].clamp(0.0, 1.0),
        colorCss(spec.colors[i]),
      );
    }
    return gradient;
  }

  void _render(Paint paint, {PathFillType fillType = PathFillType.nonZero}) {
    if (paint.blendMode != BlendMode.srcOver)
      throw UnsupportedError('Only BlendMode.srcOver is supported.');
    if (paint.invertColors)
      throw UnsupportedError('Inverted paint colors are unsupported.');
    final mask = paint.maskFilter;
    if (mask != null) {
      _ctx.save();
      _ctx.shadowColor = colorCss(paint.color);
      _ctx.shadowBlur = mask.sigma * 2;
    }
    if (paint.style == PaintingStyle.stroke) {
      _ctx.strokeStyle = _style(paint);
      _ctx.lineWidth = paint.strokeWidth <= 0 ? 1 : paint.strokeWidth;
      _ctx.lineCap = paint.strokeCap.name;
      _ctx.lineJoin = paint.strokeJoin.name;
      _ctx.miterLimit = paint.strokeMiterLimit;
      _ctx.stroke();
    } else {
      _ctx.fillStyle = _style(paint);
      _ctx.fill(fillType == PathFillType.evenOdd ? 'evenodd' : 'nonzero');
    }
    if (mask != null) _ctx.restore();
  }

  @override
  void save() {
    _ctx.save();
    _saveCount++;
  }

  /// Layers are flattened; the paint's alpha applies to subsequent drawing.
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    save();
    _ctx.globalAlpha = paint.color.alpha / 255;
  }

  @override
  void restore() {
    if (_saveCount <= 1) return;
    _ctx.restore();
    _saveCount--;
  }

  @override
  int getSaveCount() => _saveCount;
  @override
  void translate(double dx, double dy) => _ctx.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => _ctx.scale(sx, sy ?? sx);
  @override
  void rotate(double radians) => _ctx.rotate(radians);
  @override
  void skew(double sx, double sy) => _ctx.transform(1, sy, sx, 1, 0, 0);

  @override
  void transform(Float64List matrix4) {
    if (matrix4.length != 16)
      throw ArgumentError('A 4x4 matrix has 16 entries.');
    // Column-major 4x4 to the 2D affine part.
    _ctx.transform(
      matrix4[0],
      matrix4[1],
      matrix4[4],
      matrix4[5],
      matrix4[12],
      matrix4[13],
    );
  }

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    if (clipOp != ClipOp.intersect)
      throw UnsupportedError('Difference clips are unsupported.');
    clipPath(Path()..addRect(rect));
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      clipPath(Path()..addRRect(rrect));

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    _ctx.beginPath();
    replayPath(path, this);
    _ctx.clip(path.fillType == PathFillType.evenOdd ? 'evenodd' : 'nonzero');
  }

  @override
  void drawColor(Color color, BlendMode blendMode) => drawPaint(
    Paint()
      ..color = color
      ..blendMode = blendMode,
  );

  @override
  void drawPaint(Paint paint) {
    _ctx.save();
    _ctx.setTransform(1, 0, 0, 1, 0, 0);
    _ctx.beginPath();
    _ctx.moveTo(-1e6, -1e6);
    _ctx.lineTo(1e6, -1e6);
    _ctx.lineTo(1e6, 1e6);
    _ctx.lineTo(-1e6, 1e6);
    _ctx.closePath();
    _render(
      Paint()
        ..color = paint.color
        ..shader = paint.shader
        ..blendMode = paint.blendMode,
    );
    _ctx.restore();
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    _ctx.beginPath();
    _ctx.moveTo(p1.dx, p1.dy);
    _ctx.lineTo(p2.dx, p2.dy);
    final stroke = Paint()
      ..color = paint.color
      ..shader = paint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = paint.strokeCap
      ..blendMode = paint.blendMode;
    _render(stroke);
  }

  void _drawPath(Path path, Paint paint) {
    _ctx.beginPath();
    replayPath(path, this);
    _render(paint, fillType: path.fillType);
  }

  @override
  void drawRect(Rect rect, Paint paint) =>
      _drawPath(Path()..addRect(rect), paint);
  @override
  void drawRRect(RRect rrect, Paint paint) =>
      _drawPath(Path()..addRRect(rrect), paint);
  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => _drawPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner),
    paint,
  );
  @override
  void drawOval(Rect rect, Paint paint) =>
      _drawPath(Path()..addOval(rect), paint);
  @override
  void drawCircle(Offset c, double radius, Paint paint) => _drawPath(
    Path()..addOval(Rect.fromCircle(center: c, radius: radius)),
    paint,
  );

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    final path = Path();
    if (useCenter) {
      path
        ..moveTo(rect.center.dx, rect.center.dy)
        ..arcTo(rect, startAngle, sweepAngle, false)
        ..close();
    } else {
      path.arcTo(rect, startAngle, sweepAngle, true);
    }
    _drawPath(path, paint);
  }

  @override
  void drawPath(Path path, Paint paint) => _drawPath(path, paint);

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {
    switch (pointMode) {
      case PointMode.points:
        final radius = (paint.strokeWidth <= 0 ? 1 : paint.strokeWidth) / 2;
        for (final point in points) {
          drawCircle(point, radius, Paint()..color = paint.color);
        }
      case PointMode.lines:
        for (var i = 0; i + 1 < points.length; i += 2) {
          drawLine(points[i], points[i + 1], paint);
        }
      case PointMode.polygon:
        final path = Path()..addPolygon(points, false);
        _drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) {
    _ctx.save();
    _ctx.shadowColor = colorCss(color);
    _ctx.shadowBlur = elevation * 2;
    _ctx.shadowOffsetY = elevation / 2;
    _ctx.beginPath();
    replayPath(path, this);
    _ctx.fillStyle = colorCss(color).toJS;
    _ctx.fill('nonzero');
    _ctx.restore();
  }
}

// ---------------------------------------------------------------------------
// Text painting with greedy word wrapping over styled runs.

enum TextWidthBasis { parent, longestLine }

class _TextRun {
  _TextRun(this.text, this.style);
  final String text;
  final TextStyle style;
  String get font {
    final size = style.fontSize ?? 14;
    final weight = style.fontWeight?.value ?? 400;
    final italic = style.fontStyle == FontStyle.italic ? 'italic ' : '';
    final family = fontFamilyCss(style);
    final families = family.isEmpty
        ? 'system-ui,sans-serif'
        : family.substring('font-family:'.length, family.length - 1);
    return '$italic$weight ${cssNumber(size)}px $families';
  }
}

class _Line {
  final runs = <(String, _TextRun, double)>[];
  double width = 0;
  double height = 0;
}

class TextPainter {
  TextPainter({
    InlineSpan? text,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.maxLines,
    this.ellipsis,
    this.textScaler = TextScaler.noScaling,
    this.textWidthBasis = TextWidthBasis.parent,
  }) : _text = text;
  InlineSpan? _text;
  InlineSpan? get text => _text;
  set text(InlineSpan? value) {
    _text = value;
    _lines = null;
  }

  TextAlign textAlign;
  TextDirection? textDirection;
  int? maxLines;
  String? ellipsis;
  TextScaler textScaler;
  TextWidthBasis textWidthBasis;
  List<_Line>? _lines;
  double _width = 0, _height = 0, _maxIntrinsic = 0;
  bool _exceeded = false;

  double get width => _laidOut(_width);
  double get height => _laidOut(_height);
  Size get size => Size(width, height);
  bool get didExceedMaxLines => _laidOut(_exceeded);
  double get maxIntrinsicWidth => _laidOut(_maxIntrinsic);
  double get minIntrinsicWidth => _laidOut(_maxIntrinsic);
  double get preferredLineHeight =>
      (_runs().firstOrNull?.style.fontSize ?? 14) * 1.2;

  T _laidOut<T>(T value) {
    if (_lines == null) throw StateError('TextPainter.layout() not called.');
    return value;
  }

  List<_TextRun> _runs() {
    final runs = <_TextRun>[];
    void visit(InlineSpan span, TextStyle inherited) {
      final style = inherited.merge(span.style);
      if (span is TextSpan) {
        if (span.text != null && span.text!.isNotEmpty)
          runs.add(_TextRun(span.text!, style));
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child, style);
        }
      } else {
        throw UnsupportedError('Only TextSpans can be painted.');
      }
    }

    final root = _text;
    if (root != null) {
      visit(root, const TextStyle(fontSize: 14, color: Color(0xff000000)));
    }
    return [
      for (final run in runs)
        textScaler.textScaleFactor == 1
            ? run
            : _TextRun(
                run.text,
                run.style.copyWith(
                  fontSize:
                      (run.style.fontSize ?? 14) * textScaler.textScaleFactor,
                ),
              ),
    ];
  }

  double _measure(String text, _TextRun run) {
    _measurer.font = run.font;
    return _measurer.measureText(text).width;
  }

  void layout({double minWidth = 0, double maxWidth = double.infinity}) {
    final runs = _runs();
    final lines = <_Line>[_Line()];
    var exceeded = false;
    var longest = 0.0;
    void addPiece(String piece, _TextRun run) {
      var line = lines.last;
      final pieceWidth = _measure(piece, run);
      if (line.runs.isNotEmpty &&
          line.width + pieceWidth > maxWidth &&
          piece.trim().isNotEmpty) {
        line = _Line();
        lines.add(line);
      }
      if (line.runs.isEmpty && piece.trim().isEmpty) return;
      if (line.runs.isNotEmpty && identical(line.runs.last.$2, run)) {
        // Merge with the previous piece of the same run: one fillText call.
        final (text, _, width) = line.runs.removeLast();
        line.runs.add((text + piece, run, width + pieceWidth));
      } else {
        line.runs.add((piece, run, pieceWidth));
      }
      line.width += pieceWidth;
      final size = run.style.fontSize ?? 14;
      line.height = math.max(line.height, size * (run.style.height ?? 1.2));
    }

    for (final run in runs) {
      final paragraphs = run.text.split('\n');
      for (var p = 0; p < paragraphs.length; p++) {
        if (p > 0) {
          lines.add(
            _Line()
              ..height = (run.style.fontSize ?? 14) * (run.style.height ?? 1.2),
          );
        }
        for (final match in RegExp(r'\S+|\s+').allMatches(paragraphs[p])) {
          addPiece(match.group(0)!, run);
        }
      }
    }
    for (final line in lines) {
      if (line.height == 0) {
        line.height = (runs.firstOrNull?.style.fontSize ?? 14) * 1.2;
      }
      // Trailing spaces do not count towards the line width.
      while (line.runs.isNotEmpty) {
        final (text, run, width) = line.runs.last;
        final trimmed = text.trimRight();
        if (trimmed.length == text.length) break;
        line.runs.removeLast();
        line.width -= width;
        if (trimmed.isNotEmpty) {
          final kept = _measure(trimmed, run);
          line.runs.add((trimmed, run, kept));
          line.width += kept;
        }
      }
      longest = math.max(longest, line.width);
    }
    final limit = maxLines;
    if (limit != null && lines.length > limit) {
      lines.removeRange(limit, lines.length);
      exceeded = true;
      final marker = ellipsis;
      if (marker != null && lines.last.runs.isNotEmpty) {
        final last = lines.last;
        final run = last.runs.last.$2;
        final markerWidth = _measure(marker, run);
        while (last.runs.isNotEmpty && last.width + markerWidth > maxWidth) {
          final (text, lastRun, width) = last.runs.removeLast();
          last.width -= width;
          final cut = text.trimRight().lastIndexOf(RegExp(r'\s'));
          if (cut > 0) {
            final kept = text.substring(0, cut);
            final keptWidth = _measure(kept, lastRun);
            last.runs.add((kept, lastRun, keptWidth));
            last.width += keptWidth;
          }
        }
        last.runs.add((marker, run, markerWidth));
        last.width += markerWidth;
      }
    }
    _maxIntrinsic = longest;
    _lines = lines;
    _exceeded = exceeded;
    _width =
        (textWidthBasis == TextWidthBasis.longestLine || !maxWidth.isFinite
                ? longest
                : math.max(longest, math.min(maxWidth, longest)))
            .clamp(minWidth, math.max(minWidth, maxWidth));
    _height = lines.fold(0.0, (sum, line) => sum + line.height);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    final first = _laidOut(_lines!).firstOrNull;
    return first == null ? 0 : first.height * 0.8;
  }

  void paint(Canvas canvas, Offset offset) {
    final lines = _laidOut(_lines!);
    if (canvas is! _DomCanvas)
      throw UnsupportedError('TextPainter paints on the DOM canvas only.');
    final ctx = canvas._ctx;
    ctx.save();
    ctx.textBaseline = 'middle';
    ctx.textAlign = 'left';
    var y = offset.dy;
    for (final line in lines) {
      final free = _width - line.width;
      var x =
          offset.dx +
          switch (textAlign) {
            TextAlign.center => free / 2,
            TextAlign.right || TextAlign.end => free,
            _ => 0,
          };
      for (final (text, run, width) in line.runs) {
        ctx.font = run.font;
        ctx.fillStyle = colorCss(
          run.style.color ?? const Color(0xff000000),
        ).toJS;
        ctx.fillText(text, x, y + line.height / 2);
        x += width;
      }
      y += line.height;
    }
    ctx.restore();
  }

  void dispose() {}
}

// ---------------------------------------------------------------------------
// Custom painting.

abstract class CustomPainter extends Listenable {
  const CustomPainter({Listenable? repaint}) : _repaint = repaint;
  final Listenable? _repaint;
  @override
  void addListener(VoidCallback listener) => _repaint?.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _repaint?.removeListener(listener);
  void paint(Canvas canvas, Size size);
  bool shouldRepaint(covariant CustomPainter oldDelegate);
  bool? hitTest(Offset position) => null;
}

/// Paints on a `<canvas>` sized to the laid-out box. Without a child the
/// box takes [size], or fills tight parent constraints when [size] is empty.
class CustomPaint extends StatelessWidget {
  const CustomPaint({
    super.key,
    this.painter,
    this.foregroundPainter,
    this.size = Size.zero,
    this.isComplex = false,
    this.willChange = false,
    this.child,
  });
  final CustomPainter? painter, foregroundPainter;
  final Size size;
  final bool isComplex, willChange;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final sized = child == null && size != Size.zero;
    return _Box(
      css:
          'position:relative;box-sizing:border-box;min-width:0;${child == null ? (sized ? 'width:${px(size.width)};height:${px(size.height)};flex-shrink:0;' : 'width:100%;height:100%;') : 'display:grid;grid-template-columns:minmax(0,1fr);'}',
      layout: _DomLayout.grid,
      fill: child == null ? (sized ? _Fill.none : _Fill.expand) : _Fill.child,
      children: [
        if (painter != null) _PaintLayer(painter: painter!),
        ?child,
        if (foregroundPainter != null)
          _PaintLayer(painter: foregroundPainter!, foreground: true),
      ],
    );
  }
}

class _PaintLayer extends _DomWidget {
  const _PaintLayer({required this.painter, this.foreground = false});
  final CustomPainter painter;
  final bool foreground;
  @override
  String get _tag => 'canvas';
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    out.css(
      'position:absolute;inset:0;width:100%;height:100%;display:block;pointer-events:none;${foreground ? 'z-index:1;' : ''}',
    );
    out.attributes['aria-hidden'] = 'true';
  }

  @override
  Element createElement() => _PaintElement(this);
}

class _PaintElement extends _DomElement {
  _PaintElement(_PaintLayer super.widget);
  Size? _painted;
  bool _needsPaint = true;
  CustomPainter? _repaintSource;

  void _markNeedsPaint() {
    if (!_active) return;
    _needsPaint = true;
    _owner!._schedulePaint(this);
  }

  void _listen() {
    final painter = (widget as _PaintLayer).painter;
    if (identical(painter, _repaintSource)) return;
    _repaintSource?.removeListener(_markNeedsPaint);
    _repaintSource = painter;
    painter.addListener(_markNeedsPaint);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _owner!._painters.add(this);
    _listen();
    _owner!._schedulePaint(this);
  }

  @override
  void update(_PaintLayer newWidget) {
    final old = (widget as _PaintLayer).painter;
    super.update(newWidget);
    final painter = newWidget.painter;
    if (painter.runtimeType != old.runtimeType || painter.shouldRepaint(old)) {
      _markNeedsPaint();
    }
    _listen();
  }

  void _performPaint() {
    final width = checkedDimension(node.clientWidth);
    final height = checkedDimension(node._clientHeight);
    final size = Size(width, height);
    if (!_needsPaint && size == _painted) return;
    _needsPaint = false;
    _painted = size;
    final ratio = _devicePixelRatio();
    // Resizing the backing store also clears it.
    node._canvasWidth = (width * ratio).round();
    node._canvasHeight = (height * ratio).round();
    if (width == 0 || height == 0) return;
    final ctx = node._context2d;
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    final canvas = _DomCanvas(ctx);
    (widget as _PaintLayer).painter.paint(canvas, size);
    while (canvas.getSaveCount() > 1) {
      canvas.restore();
    }
  }

  @override
  void unmount() {
    _repaintSource?.removeListener(_markNeedsPaint);
    _repaintSource = null;
    _owner?._painters.remove(this);
    _owner?._paintQueue.remove(this);
    super.unmount();
  }
}
