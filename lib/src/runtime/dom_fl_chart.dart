part of 'flutter_dom.dart';

// An independent implementation of the fl_chart 1.x public API for line, bar
// and pie charts, mapped from `package:fl_chart/fl_chart.dart`. Plots paint
// on canvas; axis titles, tooltips and pie titles are DOM widgets. Scatter,
// radar and candlestick charts, error bars, rotation and zooming are not
// provided.

// ---------------------------------------------------------------------------
// Shared data.

class FlSpot {
  const FlSpot(this.x, this.y, {this.xError, this.yError});
  final double x, y;
  final Object? xError, yError;
  static const nullSpot = FlSpot(double.nan, double.nan);
  bool isNull() => x.isNaN || y.isNaN;
  bool isNotNull() => !isNull();
  FlSpot copyWith({double? x, double? y}) => FlSpot(x ?? this.x, y ?? this.y);
  static FlSpot lerp(FlSpot a, FlSpot b, double t) {
    if (a.isNull() || b.isNull()) return t < 0.5 ? a : b;
    return FlSpot(_flMix(a.x, b.x, t), _flMix(a.y, b.y, t));
  }

  @override
  bool operator ==(Object other) =>
      other is FlSpot &&
      (other.x == x || (other.x.isNaN && x.isNaN)) &&
      (other.y == y || (other.y.isNaN && y.isNaN));
  @override
  int get hashCode => Object.hash(x, y);
  @override
  String toString() => 'FlSpot($x, $y)';
}

double _flMix(double a, double b, double t) => a + (b - a) * t;

const _flBlueGrey = Color(0xff607d8b);
const _flCyan = Color(0xff00bcd4);
const _flGreen = Color(0xff4caf50);

Color _darken(Color color, int percent) {
  final factor = 1 - percent / 100;
  return Color.fromARGB(
    color.alpha,
    (color.red * factor).round(),
    (color.green * factor).round(),
    (color.blue * factor).round(),
  );
}

class FlLine {
  const FlLine({
    Color? color,
    this.gradient,
    this.strokeWidth = 2,
    this.dashArray,
  }) : color = color ?? (gradient == null ? _flBlueGrey : null);
  final Color? color;
  final Gradient? gradient;
  final double strokeWidth;
  final List<int>? dashArray;
}

typedef GetDrawingGridLine = FlLine Function(double value);
typedef CheckToShowGrid = bool Function(double value);

FlLine defaultGridLine(double value) =>
    const FlLine(color: _flBlueGrey, strokeWidth: 0.4, dashArray: [8, 4]);
bool showAllGrids(double value) => true;

class FlGridData {
  const FlGridData({
    this.show = true,
    this.drawHorizontalLine = true,
    this.horizontalInterval,
    this.getDrawingHorizontalLine = defaultGridLine,
    this.checkToShowHorizontalLine = showAllGrids,
    this.drawVerticalLine = true,
    this.verticalInterval,
    this.getDrawingVerticalLine = defaultGridLine,
    this.checkToShowVerticalLine = showAllGrids,
  });
  final bool show, drawHorizontalLine, drawVerticalLine;
  final double? horizontalInterval, verticalInterval;
  final GetDrawingGridLine getDrawingHorizontalLine, getDrawingVerticalLine;
  final CheckToShowGrid checkToShowHorizontalLine, checkToShowVerticalLine;
}

class FlBorderData {
  FlBorderData({bool? show, Border? border})
    : show = show ?? true,
      border = border ?? Border.all();
  final bool show;
  final Border border;
}

class FlClipData {
  const FlClipData({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });
  const FlClipData.all() : top = true, bottom = true, left = true, right = true;
  const FlClipData.none()
    : top = false,
      bottom = false,
      left = false,
      right = false;
  const FlClipData.horizontal()
    : top = false,
      bottom = false,
      left = true,
      right = true;
  const FlClipData.vertical()
    : top = true,
      bottom = true,
      left = false,
      right = false;
  final bool top, bottom, left, right;
  bool get any => top || bottom || left || right;
}

class FlTransformationConfig {
  const FlTransformationConfig({
    this.scaleAxis = FlScaleAxis.none,
    this.minScale = 1,
    this.maxScale = 2.5,
    this.panEnabled = true,
    this.scaleEnabled = true,
  });
  final FlScaleAxis scaleAxis;
  final double minScale, maxScale;
  final bool panEnabled, scaleEnabled;
}

enum FlScaleAxis { horizontal, vertical, free, none }

enum AxisSide { left, top, right, bottom }

enum SideTitleAlignment { inside, outside, border }

enum LabelDirection { horizontal, vertical }

enum FLHorizontalAlignment { center, left, right }

enum TooltipDirection { auto, top, bottom }

enum BarChartAlignment {
  start,
  end,
  center,
  spaceEvenly,
  spaceAround,
  spaceBetween,
}

enum LineChartGradientArea { rectAroundTheLine, wholeChart }

// ---------------------------------------------------------------------------
// Titles.

class TitleMeta {
  TitleMeta({
    required this.min,
    required this.max,
    required this.parentAxisSize,
    required this.axisPosition,
    required this.appliedInterval,
    required this.sideTitles,
    required this.formattedValue,
    required this.axisSide,
    required this.rotationQuarterTurns,
  });
  final double min, max, parentAxisSize, axisPosition, appliedInterval;
  final SideTitles sideTitles;
  final String formattedValue;
  final AxisSide axisSide;
  final int rotationQuarterTurns;
}

typedef GetTitleWidgetFunction = Widget Function(double value, TitleMeta meta);

Widget defaultGetTitle(double value, TitleMeta meta) =>
    SideTitleWidget(meta: meta, child: Text(meta.formattedValue));

class SideTitles {
  const SideTitles({
    this.showTitles = false,
    this.getTitlesWidget = defaultGetTitle,
    this.reservedSize = 22,
    this.interval,
    this.minIncluded = true,
    this.maxIncluded = true,
  });
  final bool showTitles, minIncluded, maxIncluded;
  final GetTitleWidgetFunction getTitlesWidget;
  final double reservedSize;
  final double? interval;
}

class AxisTitles {
  const AxisTitles({
    this.axisNameWidget,
    this.axisNameSize = 16,
    this.sideTitles = const SideTitles(),
    this.drawBelowEverything = true,
    this.sideTitleAlignment = SideTitleAlignment.outside,
  });
  final Widget? axisNameWidget;
  final double axisNameSize;
  final SideTitles sideTitles;
  final bool drawBelowEverything;
  final SideTitleAlignment sideTitleAlignment;
  bool get showAxisTitles => axisNameWidget != null && axisNameSize != 0;
  bool get showSideTitles =>
      sideTitles.showTitles && sideTitles.reservedSize != 0;
  double get totalReservedSize =>
      (showAxisTitles ? axisNameSize : 0) +
      (showSideTitles ? sideTitles.reservedSize : 0);
}

class FlTitlesData {
  const FlTitlesData({
    this.show = true,
    this.leftTitles = const AxisTitles(
      sideTitles: SideTitles(reservedSize: 44, showTitles: true),
    ),
    this.topTitles = const AxisTitles(
      sideTitles: SideTitles(reservedSize: 30, showTitles: true),
    ),
    this.rightTitles = const AxisTitles(
      sideTitles: SideTitles(reservedSize: 44, showTitles: true),
    ),
    this.bottomTitles = const AxisTitles(
      sideTitles: SideTitles(reservedSize: 30, showTitles: true),
    ),
  });
  final bool show;
  final AxisTitles leftTitles, topTitles, rightTitles, bottomTitles;
}

class SideTitleFitInsideData {
  const SideTitleFitInsideData({
    required this.enabled,
    required this.distanceFromEdge,
    required this.parentAxisSize,
    required this.axisPosition,
  });
  factory SideTitleFitInsideData.disable() => const SideTitleFitInsideData(
    enabled: false,
    distanceFromEdge: 0,
    parentAxisSize: 0,
    axisPosition: 0,
  );
  factory SideTitleFitInsideData.fromTitleMeta(
    TitleMeta meta, {
    bool enabled = true,
    double distanceFromEdge = 6,
  }) => SideTitleFitInsideData(
    enabled: enabled,
    distanceFromEdge: distanceFromEdge,
    parentAxisSize: meta.parentAxisSize,
    axisPosition: meta.axisPosition,
  );
  final bool enabled;
  final double distanceFromEdge, parentAxisSize, axisPosition;
}

/// Places a title [space] pixels away from the chart edge.
class SideTitleWidget extends StatelessWidget {
  const SideTitleWidget({
    super.key,
    required this.child,
    required this.meta,
    this.space = 8.0,
    this.angle = 0.0,
    this.fitInside = const SideTitleFitInsideData(
      enabled: false,
      distanceFromEdge: 0,
      parentAxisSize: 0,
      axisPosition: 0,
    ),
  });
  final Widget child;
  final TitleMeta meta;
  final double space, angle;
  final SideTitleFitInsideData fitInside;
  @override
  Widget build(BuildContext context) {
    final padding = switch (meta.axisSide) {
      AxisSide.left => EdgeInsets.only(right: space),
      AxisSide.right => EdgeInsets.only(left: space),
      AxisSide.top => EdgeInsets.only(bottom: space),
      AxisSide.bottom => EdgeInsets.only(top: space),
    };
    Widget result = DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 12),
      child: child,
    );
    if (angle != 0) result = Transform.rotate(angle: angle, child: result);
    return Padding(padding: padding, child: result);
  }
}

String _flFormat(double min, double max, double value) {
  final negative = value < 0;
  var v = value.abs();
  String number;
  var symbol = '';
  if (v >= 1e9) {
    number = (v / 1e9).toStringAsFixed(1);
    symbol = 'B';
  } else if (v >= 1e6) {
    number = (v / 1e6).toStringAsFixed(1);
    symbol = 'M';
  } else if (v >= 1e3) {
    number = (v / 1e3).toStringAsFixed(1);
    symbol = 'K';
  } else {
    final diff = (min - max).abs();
    var digits = 1;
    for (var bound = 1.0; bound > 1e-9 && diff < bound; bound /= 10) {
      digits++;
    }
    number = v.toStringAsFixed(diff >= 1 ? 1 : digits);
  }
  if (number.endsWith('.0')) number = number.substring(0, number.length - 2);
  return '${negative ? '-' : ''}$number$symbol';
}

double _roundInterval(double input) {
  if (input <= 0 || !input.isFinite) return 1;
  final exponent = (math.log(input) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final scaled = input / magnitude;
  final nice = scaled >= 7.6
      ? 10
      : scaled >= 2.6
      ? 5
      : scaled >= 1.6
      ? 2
      : 1;
  return nice * magnitude;
}

/// fl_chart's interval choice: roughly one title per 40 pixels.
double _efficientInterval(double axisPixels, double range) {
  final allowed = math.max(axisPixels ~/ 40, 1);
  if (range == 0) return 1;
  final accurate = range / allowed;
  return allowed <= 2 ? accurate : _roundInterval(accurate);
}

List<double> _axisValues(
  double min,
  double max,
  double interval, {
  required bool minIncluded,
  required bool maxIncluded,
}) {
  if (!(interval > 0) || !min.isFinite || !max.isFinite) return const [];
  final values = <double>[];
  if (minIncluded) values.add(min);
  var value = (min / interval).floor() * interval;
  if (value <= min) value += interval;
  var guard = 0;
  while (value < max - interval * 1e-6 && guard++ < 1000) {
    values.add(double.parse(value.toStringAsFixed(10)));
    value += interval;
  }
  if (maxIncluded && max > min) values.add(max);
  return values;
}

// ---------------------------------------------------------------------------
// Extra lines and range annotations.

class FlLineLabel {
  const FlLineLabel({
    required this.show,
    required this.padding,
    required this.style,
    required this.alignment,
    required this.direction,
  });
  final bool show;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;
  final Alignment alignment;
  final LabelDirection direction;
}

class HorizontalLineLabel extends FlLineLabel {
  const HorizontalLineLabel({
    super.padding = const EdgeInsets.all(6),
    super.style,
    super.alignment = Alignment.topLeft,
    super.show = false,
    super.direction = LabelDirection.horizontal,
    this.labelResolver = HorizontalLineLabel.defaultLineLabelResolver,
  });
  final String Function(HorizontalLine line) labelResolver;
  static String defaultLineLabelResolver(HorizontalLine line) =>
      line.y.toStringAsFixed(1);
}

class VerticalLineLabel extends FlLineLabel {
  const VerticalLineLabel({
    super.padding = const EdgeInsets.all(6),
    super.style = const TextStyle(
      color: Color(0xff000000),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    ),
    super.alignment = Alignment.bottomRight,
    super.show = false,
    super.direction = LabelDirection.horizontal,
    this.labelResolver = VerticalLineLabel.defaultLineLabelResolver,
  });
  final String Function(VerticalLine line) labelResolver;
  static String defaultLineLabelResolver(VerticalLine line) =>
      line.x.toStringAsFixed(1);
}

class HorizontalLine extends FlLine {
  HorizontalLine({
    required this.y,
    HorizontalLineLabel? label,
    super.color,
    super.gradient,
    super.strokeWidth,
    super.dashArray,
    this.image,
    this.sizedPicture,
    this.strokeCap = StrokeCap.butt,
  }) : label = label ?? const HorizontalLineLabel();
  final double y;
  final HorizontalLineLabel label;
  final Object? image, sizedPicture;
  final StrokeCap strokeCap;
}

class VerticalLine extends FlLine {
  VerticalLine({
    required this.x,
    VerticalLineLabel? label,
    super.color,
    super.gradient,
    super.strokeWidth,
    super.dashArray,
    this.image,
    this.sizedPicture,
    this.strokeCap = StrokeCap.butt,
  }) : label = label ?? const VerticalLineLabel();
  final double x;
  final VerticalLineLabel label;
  final Object? image, sizedPicture;
  final StrokeCap strokeCap;
}

class ExtraLinesData {
  const ExtraLinesData({
    this.horizontalLines = const [],
    this.verticalLines = const [],
    this.extraLinesOnTop = true,
  });
  final List<HorizontalLine> horizontalLines;
  final List<VerticalLine> verticalLines;
  final bool extraLinesOnTop;
}

class HorizontalRangeAnnotation {
  HorizontalRangeAnnotation({
    required this.y1,
    required this.y2,
    Color? color,
    this.gradient,
  }) : color = color ?? (gradient == null ? const Color(0xffffffff) : null);
  final double y1, y2;
  final Color? color;
  final Gradient? gradient;
}

class VerticalRangeAnnotation {
  VerticalRangeAnnotation({
    required this.x1,
    required this.x2,
    Color? color,
    this.gradient,
  }) : color = color ?? (gradient == null ? const Color(0xffffffff) : null);
  final double x1, x2;
  final Color? color;
  final Gradient? gradient;
}

class RangeAnnotations {
  const RangeAnnotations({
    this.horizontalRangeAnnotations = const [],
    this.verticalRangeAnnotations = const [],
  });
  final List<HorizontalRangeAnnotation> horizontalRangeAnnotations;
  final List<VerticalRangeAnnotation> verticalRangeAnnotations;
}

class FlErrorIndicatorData<T> {
  const FlErrorIndicatorData({this.show = true});
  final bool show;
}

class LineChartSpotErrorRangeCallbackInput {
  const LineChartSpotErrorRangeCallbackInput();
}

// ---------------------------------------------------------------------------
// Touch.

/// Pointer events delivered to touch callbacks, positioned in chart pixels.
abstract class FlTouchEvent {
  const FlTouchEvent(this.localPosition);
  final Offset? localPosition;
  bool get isInterestedForInteractions => true;
}

class FlPointerHoverEvent extends FlTouchEvent {
  const FlPointerHoverEvent(super.localPosition);
}

class FlPointerEnterEvent extends FlTouchEvent {
  const FlPointerEnterEvent(super.localPosition);
}

class FlPointerExitEvent extends FlTouchEvent {
  const FlPointerExitEvent(super.localPosition);
  @override
  bool get isInterestedForInteractions => false;
}

class FlTapDownEvent extends FlTouchEvent {
  const FlTapDownEvent(super.localPosition);
}

class FlTapUpEvent extends FlTouchEvent {
  const FlTapUpEvent(super.localPosition);
  @override
  bool get isInterestedForInteractions => false;
}

typedef BaseTouchCallback<R> = void Function(FlTouchEvent event, R? response);
typedef MouseCursorResolver<R> =
    MouseCursor Function(FlTouchEvent event, R? response);

class BaseTouchResponse {
  BaseTouchResponse({required this.touchLocation});
  final Offset touchLocation;
}

class AxisBaseTouchResponse extends BaseTouchResponse {
  AxisBaseTouchResponse({
    required super.touchLocation,
    required this.touchChartCoordinate,
  });
  final Offset touchChartCoordinate;
}

class FlTouchData<R> {
  const FlTouchData(
    this.enabled,
    this.touchCallback,
    this.mouseCursorResolver,
    this.longPressDuration,
  );
  final bool enabled;
  final BaseTouchCallback<R>? touchCallback;
  final MouseCursorResolver<R>? mouseCursorResolver;
  final Duration? longPressDuration;
}

// ---------------------------------------------------------------------------
// Dots.

abstract class FlDotPainter {
  const FlDotPainter();
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas);
  Size getSize(FlSpot spot);
  Color get mainColor;
}

class FlDotCirclePainter extends FlDotPainter {
  FlDotCirclePainter({
    this.color = _flGreen,
    double? radius,
    this.strokeColor = const Color.fromARGB(255, 76, 175, 80),
    this.strokeWidth = 0.0,
  }) : radius = radius ?? 4.0;
  final Color color, strokeColor;
  final double radius, strokeWidth;
  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    if (strokeWidth != 0 && strokeColor.alpha != 0) {
      canvas.drawCircle(
        offsetInCanvas,
        radius + strokeWidth / 2,
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawCircle(offsetInCanvas, radius, Paint()..color = color);
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);
  @override
  Color get mainColor => color;
}

class FlDotSquarePainter extends FlDotPainter {
  FlDotSquarePainter({
    this.color = _flGreen,
    this.size = 4.0,
    this.strokeColor = const Color.fromARGB(255, 76, 175, 80),
    this.strokeWidth = 1.0,
  });
  final Color color, strokeColor;
  final double size, strokeWidth;
  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final rect = Rect.fromCenter(
      center: offsetInCanvas,
      width: size,
      height: size,
    );
    if (strokeWidth != 0)
      canvas.drawRect(
        rect.inflate(strokeWidth / 2),
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    canvas.drawRect(rect, Paint()..color = color);
  }

  @override
  Size getSize(FlSpot spot) => Size(size, size);
  @override
  Color get mainColor => color;
}

class FlDotCrossPainter extends FlDotPainter {
  FlDotCrossPainter({this.color = _flGreen, this.size = 8.0, this.width = 2.0});
  final Color color;
  final double size, width;
  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final h = size / 2;
    canvas.drawLine(
      offsetInCanvas.translate(-h, -h),
      offsetInCanvas.translate(h, h),
      paint,
    );
    canvas.drawLine(
      offsetInCanvas.translate(-h, h),
      offsetInCanvas.translate(h, -h),
      paint,
    );
  }

  @override
  Size getSize(FlSpot spot) => Size(size, size);
  @override
  Color get mainColor => color;
}

typedef CheckToShowDot = bool Function(FlSpot spot, LineChartBarData barData);
typedef GetDotPainterCallback =
    FlDotPainter Function(
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index,
    );

bool showAllDots(FlSpot spot, LineChartBarData barData) => true;

Color _barColor(LineChartBarData bar) =>
    bar.color ?? bar.gradient?.colors.first ?? _flBlueGrey;

FlDotPainter _defaultGetDotPainter(
  FlSpot spot,
  double xPercentage,
  LineChartBarData bar,
  int index,
) => FlDotCirclePainter(
  color: _barColor(bar),
  strokeColor: _darken(_barColor(bar), 40),
);

class FlDotData {
  const FlDotData({
    this.show = true,
    this.checkToShowDot = showAllDots,
    this.getDotPainter = _defaultGetDotPainter,
  });
  final bool show;
  final CheckToShowDot checkToShowDot;
  final GetDotPainterCallback getDotPainter;
}

// ---------------------------------------------------------------------------
// Line charts.

class BarAreaSpotsLine {
  const BarAreaSpotsLine({this.show = false});
  final bool show;
}

class BarAreaData {
  BarAreaData({
    this.show = false,
    Color? color,
    this.gradient,
    this.spotsLine = const BarAreaSpotsLine(),
    this.cutOffY = 0,
    this.applyCutOffY = false,
  }) : color =
           color ??
           (gradient == null ? _flBlueGrey.withValues(alpha: 0.5) : null);
  final bool show, applyCutOffY;
  final Color? color;
  final Gradient? gradient;
  final BarAreaSpotsLine spotsLine;
  final double cutOffY;
}

class BetweenBarsData {
  BetweenBarsData({
    required this.fromIndex,
    required this.toIndex,
    Color? color,
    this.gradient,
  }) : color =
           color ??
           (gradient == null ? _flBlueGrey.withValues(alpha: 0.5) : null);
  final int fromIndex, toIndex;
  final Color? color;
  final Gradient? gradient;
}

class LineChartBarData {
  LineChartBarData({
    this.spots = const [],
    this.show = true,
    Color? color,
    this.gradient,
    this.gradientArea = LineChartGradientArea.rectAroundTheLine,
    this.barWidth = 2.0,
    this.isCurved = false,
    this.curveSmoothness = 0.35,
    this.preventCurveOverShooting = false,
    this.preventCurveOvershootingThreshold = 10.0,
    this.isStrokeCapRound = false,
    this.isStrokeJoinRound = false,
    BarAreaData? belowBarData,
    BarAreaData? aboveBarData,
    this.dotData = const FlDotData(),
    this.errorIndicatorData =
        const FlErrorIndicatorData<LineChartSpotErrorRangeCallbackInput>(),
    this.showingIndicators = const [],
    this.dashArray,
    this.shadow = const Shadow(color: Color(0x00000000)),
    this.isStepLineChart = false,
    this.lineChartStepData = const LineChartStepData(),
  }) : color = color ?? (gradient == null ? _flCyan : null),
       belowBarData = belowBarData ?? BarAreaData(),
       aboveBarData = aboveBarData ?? BarAreaData();
  final List<FlSpot> spots;
  final bool show, isCurved, preventCurveOverShooting;
  final Color? color;
  final Gradient? gradient;
  final LineChartGradientArea gradientArea;
  final double barWidth, curveSmoothness, preventCurveOvershootingThreshold;
  final bool isStrokeCapRound, isStrokeJoinRound, isStepLineChart;
  final BarAreaData belowBarData, aboveBarData;
  final FlDotData dotData;
  final FlErrorIndicatorData<LineChartSpotErrorRangeCallbackInput>
  errorIndicatorData;
  final List<int> showingIndicators;
  final List<int>? dashArray;
  final Shadow shadow;
  final LineChartStepData lineChartStepData;

  LineChartBarData copyWith({List<FlSpot>? spots, Color? color}) =>
      LineChartBarData(
        spots: spots ?? this.spots,
        show: show,
        color: color ?? this.color,
        gradient: gradient,
        gradientArea: gradientArea,
        barWidth: barWidth,
        isCurved: isCurved,
        curveSmoothness: curveSmoothness,
        preventCurveOverShooting: preventCurveOverShooting,
        preventCurveOvershootingThreshold: preventCurveOvershootingThreshold,
        isStrokeCapRound: isStrokeCapRound,
        isStrokeJoinRound: isStrokeJoinRound,
        belowBarData: belowBarData,
        aboveBarData: aboveBarData,
        dotData: dotData,
        showingIndicators: showingIndicators,
        dashArray: dashArray,
        shadow: shadow,
        isStepLineChart: isStepLineChart,
        lineChartStepData: lineChartStepData,
      );
}

class LineChartStepData {
  const LineChartStepData({this.stepDirection = stepDirectionMiddle});
  final double stepDirection;
  static const stepDirectionMiddle = 0.5;
  static const stepDirectionForward = 0.0;
  static const stepDirectionBackward = 1.0;
}

class LineBarSpot extends FlSpot {
  LineBarSpot(this.bar, this.barIndex, FlSpot spot)
    : spotIndex = bar.spots.indexOf(spot),
      super(spot.x, spot.y);
  final LineChartBarData bar;
  final int barIndex, spotIndex;
}

class TouchLineBarSpot extends LineBarSpot {
  TouchLineBarSpot(super.bar, super.barIndex, super.spot, this.distance);
  final double distance;
}

class LineTooltipItem {
  const LineTooltipItem(
    this.text,
    this.textStyle, {
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.children,
  });
  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final List<TextSpan>? children;
}

typedef GetLineTooltipItems =
    List<LineTooltipItem?> Function(List<LineBarSpot> touchedSpots);
typedef GetLineTooltipColor = Color Function(LineBarSpot touchedSpot);

List<LineTooltipItem> defaultLineTooltipItem(
  List<LineBarSpot> touchedSpots,
) => [
  for (final spot in touchedSpots)
    LineTooltipItem(
      spot.y.toString(),
      TextStyle(
        color: spot.bar.gradient?.colors.first ?? spot.bar.color ?? _flBlueGrey,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
];

Color defaultLineTooltipColor(LineBarSpot touchedSpot) =>
    _darken(_flBlueGrey, 15);

class LineTouchTooltipData {
  const LineTouchTooltipData({
    BorderRadius? tooltipBorderRadius,
    this.tooltipPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    this.tooltipMargin = 16,
    this.tooltipHorizontalAlignment = FLHorizontalAlignment.center,
    this.tooltipHorizontalOffset = 0,
    this.maxContentWidth = 120,
    this.getTooltipItems = defaultLineTooltipItem,
    this.getTooltipColor = defaultLineTooltipColor,
    this.fitInsideHorizontally = false,
    this.fitInsideVertically = false,
    this.showOnTopOfTheChartBoxArea = false,
    this.rotateAngle = 0.0,
    this.tooltipBorder = BorderSide.none,
  }) : _tooltipBorderRadius = tooltipBorderRadius;
  final BorderRadius? _tooltipBorderRadius;
  BorderRadius get tooltipBorderRadius =>
      _tooltipBorderRadius ?? BorderRadius.circular(4);
  final EdgeInsets tooltipPadding;
  final double tooltipMargin, tooltipHorizontalOffset, maxContentWidth;
  final FLHorizontalAlignment tooltipHorizontalAlignment;
  final GetLineTooltipItems getTooltipItems;
  final GetLineTooltipColor getTooltipColor;
  final bool fitInsideHorizontally, fitInsideVertically;
  final bool showOnTopOfTheChartBoxArea;
  final double rotateAngle;
  final BorderSide tooltipBorder;
}

class TouchedSpotIndicatorData {
  const TouchedSpotIndicatorData(
    this.indicatorBelowLine,
    this.touchedSpotDotData,
  );
  final FlLine indicatorBelowLine;
  final FlDotData touchedSpotDotData;
}

typedef GetTouchedSpotIndicator =
    List<TouchedSpotIndicatorData?> Function(
      LineChartBarData barData,
      List<int> spotIndexes,
    );

List<TouchedSpotIndicatorData> defaultTouchedIndicators(
  LineChartBarData barData,
  List<int> indicators,
) => [
  for (final _ in indicators)
    TouchedSpotIndicatorData(
      FlLine(color: _barColor(barData), strokeWidth: 4),
      FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 8,
          color: _barColor(bar),
          strokeWidth: 2,
          strokeColor: _darken(_barColor(bar), 40),
        ),
      ),
    ),
];

typedef GetTouchLineY =
    double Function(LineChartBarData barData, int spotIndex);

double defaultGetTouchLineStart(LineChartBarData barData, int spotIndex) =>
    -double.infinity;
double defaultGetTouchLineEnd(LineChartBarData barData, int spotIndex) =>
    barData.spots[spotIndex].y;

typedef CalculateTouchDistance =
    double Function(Offset touchPoint, Offset spotPixelCoordinates);

double _xDistance(Offset touchPoint, Offset spot) =>
    (touchPoint.dx - spot.dx).abs();

class LineTouchResponse extends AxisBaseTouchResponse {
  LineTouchResponse({
    required super.touchLocation,
    required super.touchChartCoordinate,
    this.lineBarSpots,
  });
  final List<TouchLineBarSpot>? lineBarSpots;
}

class LineTouchData extends FlTouchData<LineTouchResponse> {
  const LineTouchData({
    bool enabled = true,
    BaseTouchCallback<LineTouchResponse>? touchCallback,
    MouseCursorResolver<LineTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
    this.touchTooltipData = const LineTouchTooltipData(),
    this.getTouchedSpotIndicator = defaultTouchedIndicators,
    this.touchSpotThreshold = 10,
    this.distanceCalculator = _xDistance,
    this.handleBuiltInTouches = true,
    this.getTouchLineStart = defaultGetTouchLineStart,
    this.getTouchLineEnd = defaultGetTouchLineEnd,
  }) : super(enabled, touchCallback, mouseCursorResolver, longPressDuration);
  final LineTouchTooltipData touchTooltipData;
  final GetTouchedSpotIndicator getTouchedSpotIndicator;
  final double touchSpotThreshold;
  final CalculateTouchDistance distanceCalculator;
  final bool handleBuiltInTouches;
  final GetTouchLineY getTouchLineStart, getTouchLineEnd;
}

class ShowingTooltipIndicators {
  ShowingTooltipIndicators(this.showingSpots);
  final List<LineBarSpot> showingSpots;
}

abstract class AxisChartData {
  AxisChartData({
    FlGridData? gridData,
    required this.titlesData,
    RangeAnnotations? rangeAnnotations,
    required this.minX,
    required this.maxX,
    double? baselineX,
    required this.minY,
    required this.maxY,
    double? baselineY,
    FlClipData? clipData,
    Color? backgroundColor,
    FlBorderData? borderData,
    required ExtraLinesData extraLinesData,
    this.rotationQuarterTurns = 0,
  }) : gridData = gridData ?? const FlGridData(),
       rangeAnnotations = rangeAnnotations ?? const RangeAnnotations(),
       baselineX = baselineX ?? 0,
       baselineY = baselineY ?? 0,
       clipData = clipData ?? const FlClipData.none(),
       backgroundColor = backgroundColor ?? const Color(0x00000000),
       borderData = borderData ?? FlBorderData(),
       extraLinesData = extraLinesData;
  final FlGridData gridData;
  final FlTitlesData titlesData;
  final RangeAnnotations rangeAnnotations;
  final double minX, maxX, baselineX, minY, maxY, baselineY;
  final FlClipData clipData;
  final Color backgroundColor;
  final FlBorderData borderData;
  final ExtraLinesData extraLinesData;
  final int rotationQuarterTurns;
  double get verticalDiff => maxY - minY;
  double get horizontalDiff => maxX - minX;
}

(double, double) _bounds(Iterable<double> values, double? min, double? max) {
  var low = double.infinity, high = -double.infinity;
  for (final value in values) {
    if (value.isNaN) continue;
    low = math.min(low, value);
    high = math.max(high, value);
  }
  if (!low.isFinite) {
    low = 0;
    high = 0;
  }
  return (min ?? low, max ?? high);
}

class LineChartData extends AxisChartData {
  LineChartData._(
    this.lineBarsData,
    this.betweenBarsData,
    this.lineTouchData,
    this.showingTooltipIndicators, {
    required super.titlesData,
    required super.extraLinesData,
    required super.gridData,
    required super.borderData,
    required super.rangeAnnotations,
    required super.minX,
    required super.maxX,
    required super.baselineX,
    required super.minY,
    required super.maxY,
    required super.baselineY,
    required super.clipData,
    required super.backgroundColor,
    required super.rotationQuarterTurns,
  });
  factory LineChartData({
    List<LineChartBarData> lineBarsData = const [],
    List<BetweenBarsData> betweenBarsData = const [],
    FlTitlesData titlesData = const FlTitlesData(),
    ExtraLinesData extraLinesData = const ExtraLinesData(),
    LineTouchData lineTouchData = const LineTouchData(),
    List<ShowingTooltipIndicators> showingTooltipIndicators = const [],
    FlGridData gridData = const FlGridData(),
    FlBorderData? borderData,
    RangeAnnotations rangeAnnotations = const RangeAnnotations(),
    double? minX,
    double? maxX,
    double? baselineX,
    double? minY,
    double? maxY,
    double? baselineY,
    FlClipData clipData = const FlClipData.none(),
    Color? backgroundColor,
    int rotationQuarterTurns = 0,
  }) {
    final spots = [
      for (final bar in lineBarsData)
        if (bar.show) ...bar.spots,
    ];
    final (x0, x1) = _bounds(spots.map((s) => s.x), minX, maxX);
    final (y0, y1) = _bounds(spots.map((s) => s.y), minY, maxY);
    return LineChartData._(
      lineBarsData,
      betweenBarsData,
      lineTouchData,
      showingTooltipIndicators,
      titlesData: titlesData,
      extraLinesData: extraLinesData,
      gridData: gridData,
      borderData: borderData,
      rangeAnnotations: rangeAnnotations,
      minX: x0,
      maxX: x1,
      baselineX: baselineX,
      minY: y0,
      maxY: y1,
      baselineY: baselineY,
      clipData: clipData,
      backgroundColor: backgroundColor,
      rotationQuarterTurns: rotationQuarterTurns,
    );
  }
  final List<LineChartBarData> lineBarsData;
  final List<BetweenBarsData> betweenBarsData;
  final LineTouchData lineTouchData;
  final List<ShowingTooltipIndicators> showingTooltipIndicators;

  LineChartData _with(List<LineChartBarData> bars, double y0, double y1) =>
      LineChartData._(
        bars,
        betweenBarsData,
        lineTouchData,
        showingTooltipIndicators,
        titlesData: titlesData,
        extraLinesData: extraLinesData,
        gridData: gridData,
        borderData: borderData,
        rangeAnnotations: rangeAnnotations,
        minX: minX,
        maxX: maxX,
        baselineX: baselineX,
        minY: y0,
        maxY: y1,
        baselineY: baselineY,
        clipData: clipData,
        backgroundColor: backgroundColor,
        rotationQuarterTurns: rotationQuarterTurns,
      );

  static LineChartData lerp(LineChartData a, LineChartData b, double t) {
    if (a.lineBarsData.length != b.lineBarsData.length) return b;
    final bars = <LineChartBarData>[];
    for (var i = 0; i < b.lineBarsData.length; i++) {
      final from = a.lineBarsData[i].spots, to = b.lineBarsData[i].spots;
      if (from.length != to.length) return b;
      bars.add(
        b.lineBarsData[i].copyWith(
          spots: [
            for (var k = 0; k < to.length; k++) FlSpot.lerp(from[k], to[k], t),
          ],
        ),
      );
    }
    return b._with(bars, _flMix(a.minY, b.minY, t), _flMix(a.maxY, b.maxY, t));
  }
}

// ---------------------------------------------------------------------------
// Bar charts.

class BackgroundBarChartRodData {
  BackgroundBarChartRodData({
    double? fromY,
    double? toY,
    bool? show,
    Color? color,
    this.gradient,
  }) : fromY = fromY ?? 0,
       toY = toY ?? 0,
       show = show ?? false,
       color = color ?? (gradient == null ? _flBlueGrey : null);
  final double fromY, toY;
  final bool show;
  final Color? color;
  final Gradient? gradient;
}

class BarChartRodStackItem {
  BarChartRodStackItem(
    this.fromY,
    this.toY,
    this.color, {
    this.gradient,
    this.label,
    this.labelStyle,
    this.borderSide = const BorderSide(width: 0),
  });
  final double fromY, toY;
  final Color? color;
  final Gradient? gradient;
  final String? label;
  final TextStyle? labelStyle;
  final BorderSide borderSide;
}

class BarChartRodLabel {
  const BarChartRodLabel({this.show = true, this.text, this.style});
  final bool show;
  final String? text;
  final TextStyle? style;
}

BorderRadius? _normalizeRadius(BorderRadius? radius, double width) {
  if (radius == null) return null;
  Radius clamp(Radius r) =>
      r.x > width / 2 || r.y > width / 2 ? Radius.circular(width / 2) : r;
  return BorderRadius.only(
    topLeft: clamp(radius.topLeft),
    topRight: clamp(radius.topRight),
    bottomLeft: clamp(radius.bottomLeft),
    bottomRight: clamp(radius.bottomRight),
  );
}

class BarChartRodData {
  BarChartRodData({
    double? fromY,
    required this.toY,
    this.toYErrorRange,
    Color? color,
    this.gradient,
    double? width,
    BorderRadius? borderRadius,
    this.borderDashArray,
    BorderSide? borderSide,
    BackgroundBarChartRodData? backDrawRodData,
    List<BarChartRodStackItem>? rodStackItems,
    this.label = const BarChartRodLabel(show: false),
  }) : fromY = fromY ?? 0,
       color = color ?? (gradient == null ? _flCyan : null),
       width = width ?? 8,
       borderRadius = _normalizeRadius(borderRadius, width ?? 8),
       borderSide = borderSide ?? const BorderSide(width: 0),
       backDrawRodData = backDrawRodData ?? BackgroundBarChartRodData(),
       rodStackItems = rodStackItems ?? const [];
  final double fromY, toY, width;
  final Object? toYErrorRange;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final List<int>? borderDashArray;
  final BorderSide borderSide;
  final BackgroundBarChartRodData backDrawRodData;
  final List<BarChartRodStackItem> rodStackItems;
  final BarChartRodLabel label;
  BarChartRodData copyWith({double? fromY, double? toY}) => BarChartRodData(
    fromY: fromY ?? this.fromY,
    toY: toY ?? this.toY,
    color: color,
    gradient: gradient,
    width: width,
    borderRadius: borderRadius,
    borderDashArray: borderDashArray,
    borderSide: borderSide,
    backDrawRodData: backDrawRodData,
    rodStackItems: rodStackItems,
    label: label,
  );
}

class BarChartGroupData {
  BarChartGroupData({
    required this.x,
    bool? groupVertically,
    List<BarChartRodData>? barRods,
    double? barsSpace,
    List<int>? showingTooltipIndicators,
  }) : groupVertically = groupVertically ?? false,
       barRods = barRods ?? const [],
       barsSpace = barsSpace ?? 2,
       showingTooltipIndicators = showingTooltipIndicators ?? const [];
  final int x;
  final bool groupVertically;
  final List<BarChartRodData> barRods;
  final double barsSpace;
  final List<int> showingTooltipIndicators;
  double get width {
    if (barRods.isEmpty) return 0;
    if (groupVertically) return barRods.map((r) => r.width).reduce(math.max);
    return barRods.fold<double>(0, (sum, r) => sum + r.width) +
        barsSpace * (barRods.length - 1);
  }
}

class BarTooltipItem {
  const BarTooltipItem(
    this.text,
    this.textStyle, {
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.children,
  });
  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final List<TextSpan>? children;
}

typedef GetBarTooltipItem =
    BarTooltipItem? Function(
      BarChartGroupData group,
      int groupIndex,
      BarChartRodData rod,
      int rodIndex,
    );
typedef GetBarTooltipColor = Color Function(BarChartGroupData group);

BarTooltipItem? defaultBarTooltipItem(
  BarChartGroupData group,
  int groupIndex,
  BarChartRodData rod,
  int rodIndex,
) => BarTooltipItem(
  rod.toY.toString(),
  TextStyle(
    color: rod.gradient?.colors.first ?? rod.color,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  ),
);

Color defaultBarTooltipColor(BarChartGroupData group) =>
    _darken(_flBlueGrey, 15);

class BarTouchTooltipData {
  BarTouchTooltipData({
    BorderRadius? tooltipBorderRadius,
    EdgeInsets? tooltipPadding,
    double? tooltipMargin,
    FLHorizontalAlignment? tooltipHorizontalAlignment,
    double? tooltipHorizontalOffset,
    double? maxContentWidth,
    GetBarTooltipItem? getTooltipItem,
    GetBarTooltipColor? getTooltipColor,
    bool? fitInsideHorizontally,
    bool? fitInsideVertically,
    TooltipDirection? direction,
    double? rotateAngle,
    BorderSide? tooltipBorder,
  }) : tooltipBorderRadius = tooltipBorderRadius ?? BorderRadius.circular(4),
       tooltipPadding =
           tooltipPadding ??
           const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       tooltipMargin = tooltipMargin ?? 16,
       tooltipHorizontalAlignment =
           tooltipHorizontalAlignment ?? FLHorizontalAlignment.center,
       tooltipHorizontalOffset = tooltipHorizontalOffset ?? 0,
       maxContentWidth = maxContentWidth ?? 120,
       getTooltipItem = getTooltipItem ?? defaultBarTooltipItem,
       getTooltipColor = getTooltipColor ?? defaultBarTooltipColor,
       fitInsideHorizontally = fitInsideHorizontally ?? false,
       fitInsideVertically = fitInsideVertically ?? false,
       direction = direction ?? TooltipDirection.auto,
       rotateAngle = rotateAngle ?? 0,
       tooltipBorder = tooltipBorder ?? BorderSide.none;
  final BorderRadius tooltipBorderRadius;
  final EdgeInsets tooltipPadding;
  final double tooltipMargin, tooltipHorizontalOffset, maxContentWidth;
  final FLHorizontalAlignment tooltipHorizontalAlignment;
  final GetBarTooltipItem getTooltipItem;
  final GetBarTooltipColor getTooltipColor;
  final bool fitInsideHorizontally, fitInsideVertically;
  final TooltipDirection direction;
  final double rotateAngle;
  final BorderSide tooltipBorder;
}

class BarTouchedSpot {
  BarTouchedSpot(
    this.touchedBarGroup,
    this.touchedBarGroupIndex,
    this.touchedRodData,
    this.touchedRodDataIndex,
    this.touchedStackItem,
    this.touchedStackItemIndex,
    this.spot,
    this.offset,
  );
  final BarChartGroupData touchedBarGroup;
  final int touchedBarGroupIndex;
  final BarChartRodData touchedRodData;
  final int touchedRodDataIndex;
  final BarChartRodStackItem? touchedStackItem;
  final int touchedStackItemIndex;
  final FlSpot spot;
  final Offset offset;
}

class BarTouchResponse extends AxisBaseTouchResponse {
  BarTouchResponse({
    required super.touchLocation,
    required super.touchChartCoordinate,
    required this.spot,
  });
  final BarTouchedSpot? spot;
}

class BarTouchData extends FlTouchData<BarTouchResponse> {
  BarTouchData({
    bool? enabled,
    BaseTouchCallback<BarTouchResponse>? touchCallback,
    MouseCursorResolver<BarTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
    BarTouchTooltipData? touchTooltipData,
    EdgeInsets? touchExtraThreshold,
    bool? allowTouchBarBackDraw,
    bool? handleBuiltInTouches,
  }) : touchTooltipData = touchTooltipData ?? BarTouchTooltipData(),
       touchExtraThreshold = touchExtraThreshold ?? const EdgeInsets.all(4),
       allowTouchBarBackDraw = allowTouchBarBackDraw ?? false,
       handleBuiltInTouches = handleBuiltInTouches ?? true,
       super(
         enabled ?? true,
         touchCallback,
         mouseCursorResolver,
         longPressDuration,
       );
  final BarTouchTooltipData touchTooltipData;
  final EdgeInsets touchExtraThreshold;
  final bool allowTouchBarBackDraw, handleBuiltInTouches;
}

class BarChartData extends AxisChartData {
  BarChartData._(
    this.barGroups,
    this.groupsSpace,
    this.alignment,
    this.barTouchData, {
    required super.titlesData,
    required super.extraLinesData,
    required super.gridData,
    required super.borderData,
    required super.rangeAnnotations,
    required super.minY,
    required super.maxY,
    required super.baselineY,
    required super.backgroundColor,
    required super.rotationQuarterTurns,
  }) : super(minX: 0, maxX: 1);
  factory BarChartData({
    List<BarChartGroupData>? barGroups,
    double? groupsSpace,
    BarChartAlignment? alignment,
    FlTitlesData? titlesData,
    BarTouchData? barTouchData,
    double? maxY,
    double? minY,
    double? baselineY,
    FlGridData? gridData,
    FlBorderData? borderData,
    RangeAnnotations? rangeAnnotations,
    Color? backgroundColor,
    ExtraLinesData? extraLinesData,
    int rotationQuarterTurns = 0,
    FlErrorIndicatorData<Object?>? errorIndicatorData,
  }) {
    final groups = barGroups ?? const <BarChartGroupData>[];
    final values = <double>[
      for (final group in groups)
        for (final rod in group.barRods) ...[
          rod.toY,
          rod.fromY,
          if (rod.backDrawRodData.show) ...[
            rod.backDrawRodData.toY,
            rod.backDrawRodData.fromY,
          ],
        ],
    ];
    var (y0, y1) = _bounds(values, minY, maxY);
    if (minY == null && y0 > 0) y0 = 0;
    if (maxY == null && y1 < 0) y1 = 0;
    return BarChartData._(
      groups,
      groupsSpace ?? 16,
      alignment ?? BarChartAlignment.spaceEvenly,
      barTouchData ?? BarTouchData(),
      titlesData: titlesData ?? const FlTitlesData(),
      extraLinesData: extraLinesData ?? const ExtraLinesData(),
      gridData: gridData,
      borderData: borderData,
      rangeAnnotations: rangeAnnotations,
      minY: y0,
      maxY: y1,
      baselineY: baselineY,
      backgroundColor: backgroundColor,
      rotationQuarterTurns: rotationQuarterTurns,
    );
  }
  final List<BarChartGroupData> barGroups;
  final double groupsSpace;
  final BarChartAlignment alignment;
  final BarTouchData barTouchData;

  static BarChartData lerp(BarChartData a, BarChartData b, double t) {
    if (a.barGroups.length != b.barGroups.length) return b;
    final groups = <BarChartGroupData>[];
    for (var g = 0; g < b.barGroups.length; g++) {
      final from = a.barGroups[g], to = b.barGroups[g];
      if (from.barRods.length != to.barRods.length) return b;
      groups.add(
        BarChartGroupData(
          x: to.x,
          groupVertically: to.groupVertically,
          barsSpace: to.barsSpace,
          showingTooltipIndicators: to.showingTooltipIndicators,
          barRods: [
            for (var r = 0; r < to.barRods.length; r++)
              to.barRods[r].copyWith(
                fromY: _flMix(from.barRods[r].fromY, to.barRods[r].fromY, t),
                toY: _flMix(from.barRods[r].toY, to.barRods[r].toY, t),
              ),
          ],
        ),
      );
    }
    return BarChartData._(
      groups,
      b.groupsSpace,
      b.alignment,
      b.barTouchData,
      titlesData: b.titlesData,
      extraLinesData: b.extraLinesData,
      gridData: b.gridData,
      borderData: b.borderData,
      rangeAnnotations: b.rangeAnnotations,
      minY: _flMix(a.minY, b.minY, t),
      maxY: _flMix(a.maxY, b.maxY, t),
      baselineY: b.baselineY,
      backgroundColor: b.backgroundColor,
      rotationQuarterTurns: b.rotationQuarterTurns,
    );
  }
}

// ---------------------------------------------------------------------------
// Pie charts.

class PieChartSectionData {
  PieChartSectionData({
    double? value,
    Color? color,
    this.gradient,
    double? radius,
    bool? showTitle,
    this.titleStyle,
    String? title,
    BorderSide? borderSide,
    double? cornerRadius,
    this.badgeWidget,
    double? titlePositionPercentageOffset,
    double? badgePositionPercentageOffset,
  }) : value = value ?? 10,
       color = color ?? _flCyan,
       radius = (radius ?? 40).clamp(0, double.infinity).toDouble(),
       showTitle = showTitle ?? true,
       title = title ?? (value == null ? '' : value.toString()),
       borderSide = borderSide ?? const BorderSide(width: 0),
       cornerRadius = cornerRadius ?? 0,
       titlePositionPercentageOffset = titlePositionPercentageOffset ?? 0.5,
       badgePositionPercentageOffset = badgePositionPercentageOffset ?? 0.5;
  final double value, radius, cornerRadius;
  final Color color;
  final Gradient? gradient;
  final bool showTitle;
  final TextStyle? titleStyle;
  final String title;
  final BorderSide borderSide;
  final Widget? badgeWidget;
  final double titlePositionPercentageOffset, badgePositionPercentageOffset;
  PieChartSectionData copyWith({double? value, double? radius}) =>
      PieChartSectionData(
        value: value ?? this.value,
        color: color,
        gradient: gradient,
        radius: radius ?? this.radius,
        showTitle: showTitle,
        titleStyle: titleStyle,
        title: title,
        borderSide: borderSide,
        cornerRadius: cornerRadius,
        badgeWidget: badgeWidget,
        titlePositionPercentageOffset: titlePositionPercentageOffset,
        badgePositionPercentageOffset: badgePositionPercentageOffset,
      );
}

class PieTouchedSection {
  PieTouchedSection(
    this.touchedSection,
    this.touchedSectionIndex,
    this.touchAngle,
    this.touchRadius,
  );
  final PieChartSectionData? touchedSection;
  final int touchedSectionIndex;
  final double touchAngle, touchRadius;
}

class PieTouchResponse extends BaseTouchResponse {
  PieTouchResponse({
    required super.touchLocation,
    required this.touchedSection,
  });
  final PieTouchedSection? touchedSection;
}

class PieTouchData extends FlTouchData<PieTouchResponse> {
  PieTouchData({
    bool? enabled,
    BaseTouchCallback<PieTouchResponse>? touchCallback,
    MouseCursorResolver<PieTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
  }) : super(
         enabled ?? true,
         touchCallback,
         mouseCursorResolver,
         longPressDuration,
       );
}

class PieChartData {
  PieChartData({
    List<PieChartSectionData>? sections,
    double? centerSpaceRadius,
    Color? centerSpaceColor,
    double? sectionsSpace,
    double? startDegreeOffset,
    PieTouchData? pieTouchData,
    FlBorderData? borderData,
    bool? titleSunbeamLayout,
  }) : sections = sections ?? const [],
       centerSpaceRadius = centerSpaceRadius ?? double.infinity,
       centerSpaceColor = centerSpaceColor ?? const Color(0x00000000),
       sectionsSpace = sectionsSpace ?? 2,
       startDegreeOffset = startDegreeOffset ?? 0,
       pieTouchData = pieTouchData ?? PieTouchData(),
       borderData = borderData ?? FlBorderData(show: false),
       titleSunbeamLayout = titleSunbeamLayout ?? false;
  final List<PieChartSectionData> sections;
  final double centerSpaceRadius, sectionsSpace, startDegreeOffset;
  final Color centerSpaceColor;
  final PieTouchData pieTouchData;
  final FlBorderData borderData;
  final bool titleSunbeamLayout;
  double get sumValue => sections.fold(0, (sum, s) => sum + s.value);

  static PieChartData lerp(PieChartData a, PieChartData b, double t) {
    if (a.sections.length != b.sections.length) return b;
    return PieChartData(
      sections: [
        for (var i = 0; i < b.sections.length; i++)
          b.sections[i].copyWith(
            value: _flMix(a.sections[i].value, b.sections[i].value, t),
            radius: _flMix(a.sections[i].radius, b.sections[i].radius, t),
          ),
      ],
      centerSpaceRadius: b.centerSpaceRadius,
      centerSpaceColor: b.centerSpaceColor,
      sectionsSpace: b.sectionsSpace,
      startDegreeOffset: b.startDegreeOffset,
      pieTouchData: b.pieTouchData,
      borderData: b.borderData,
      titleSunbeamLayout: b.titleSunbeamLayout,
    );
  }
}

// ---------------------------------------------------------------------------
// Drawing helpers.

void _flDrawLine(
  Canvas canvas,
  Offset a,
  Offset b,
  FlLine line, {
  StrokeCap cap = StrokeCap.butt,
}) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = line.strokeWidth
    ..strokeCap = cap
    ..color = line.color ?? _flBlueGrey;
  if (line.gradient != null)
    paint.shader = line.gradient!.createShader(Rect.fromPoints(a, b));
  final dashes = line.dashArray;
  if (dashes == null || dashes.isEmpty || dashes.every((d) => d <= 0)) {
    canvas.drawLine(a, b, paint);
    return;
  }
  final total = (b - a).distance;
  if (total == 0) return;
  final direction = (b - a) / total;
  var travelled = 0.0, index = 0;
  var draw = true;
  while (travelled < total) {
    final length = math.max(1, dashes[index % dashes.length]).toDouble();
    final end = math.min(total, travelled + length);
    if (draw)
      canvas.drawLine(a + direction * travelled, a + direction * end, paint);
    travelled = end;
    draw = !draw;
    index++;
  }
}

Paint _fill(Color? color, Gradient? gradient, Rect bounds) {
  final paint = Paint()..color = color ?? _flBlueGrey;
  if (gradient != null) paint.shader = gradient.createShader(bounds);
  return paint;
}

/// Geometry of an axis chart within its box.
class _AxisGeometry {
  _AxisGeometry(this.size, this.titles, this.data)
    : chart = Rect.fromLTRB(
        titles.show ? titles.leftTitles.totalReservedSize : 0,
        titles.show ? titles.topTitles.totalReservedSize : 0,
        size.width - (titles.show ? titles.rightTitles.totalReservedSize : 0),
        size.height - (titles.show ? titles.bottomTitles.totalReservedSize : 0),
      );
  final Size size;
  final FlTitlesData titles;
  final AxisChartData data;
  final Rect chart;

  double x(double value) {
    final range = data.maxX - data.minX;
    return chart.left +
        (range == 0 ? 0 : (value - data.minX) / range * chart.width);
  }

  double y(double value) {
    final range = data.maxY - data.minY;
    return chart.bottom -
        (range == 0 ? 0 : (value - data.minY) / range * chart.height);
  }

  double xValue(double pixel) =>
      data.minX + (pixel - chart.left) / chart.width * (data.maxX - data.minX);
  double yValue(double pixel) =>
      data.minY +
      (chart.bottom - pixel) / chart.height * (data.maxY - data.minY);
}

void _paintAxisBackground(Canvas canvas, _AxisGeometry g) {
  final data = g.data;
  if (data.backgroundColor.alpha != 0)
    canvas.drawRect(g.chart, Paint()..color = data.backgroundColor);
  for (final range in data.rangeAnnotations.horizontalRangeAnnotations) {
    final rect = Rect.fromLTRB(
      g.chart.left,
      g.y(math.max(range.y1, range.y2)),
      g.chart.right,
      g.y(math.min(range.y1, range.y2)),
    );
    canvas.drawRect(rect, _fill(range.color, range.gradient, rect));
  }
  for (final range in data.rangeAnnotations.verticalRangeAnnotations) {
    final rect = Rect.fromLTRB(
      g.x(math.min(range.x1, range.x2)),
      g.chart.top,
      g.x(math.max(range.x1, range.x2)),
      g.chart.bottom,
    );
    canvas.drawRect(rect, _fill(range.color, range.gradient, rect));
  }
  final grid = data.gridData;
  if (!grid.show) return;
  if (grid.drawHorizontalLine && data.verticalDiff > 0) {
    final interval =
        grid.horizontalInterval ??
        _efficientInterval(g.chart.height, data.verticalDiff);
    for (final value in _axisValues(
      data.minY,
      data.maxY,
      interval,
      minIncluded: false,
      maxIncluded: false,
    )) {
      if (!grid.checkToShowHorizontalLine(value)) continue;
      final y = g.y(value);
      _flDrawLine(
        canvas,
        Offset(g.chart.left, y),
        Offset(g.chart.right, y),
        grid.getDrawingHorizontalLine(value),
      );
    }
  }
  if (grid.drawVerticalLine && data.horizontalDiff > 0) {
    final interval =
        grid.verticalInterval ??
        _efficientInterval(g.chart.width, data.horizontalDiff);
    for (final value in _axisValues(
      data.minX,
      data.maxX,
      interval,
      minIncluded: false,
      maxIncluded: false,
    )) {
      if (!grid.checkToShowVerticalLine(value)) continue;
      final x = g.x(value);
      _flDrawLine(
        canvas,
        Offset(x, g.chart.top),
        Offset(x, g.chart.bottom),
        grid.getDrawingVerticalLine(value),
      );
    }
  }
}

void _paintExtraLines(Canvas canvas, _AxisGeometry g) {
  final lines = g.data.extraLinesData;
  for (final line in lines.horizontalLines) {
    if (line.y < g.data.minY || line.y > g.data.maxY) continue;
    final y = g.y(line.y);
    _flDrawLine(
      canvas,
      Offset(g.chart.left, y),
      Offset(g.chart.right, y),
      line,
      cap: line.strokeCap,
    );
    if (line.label.show) {
      final painter = TextPainter(
        text: TextSpan(
          text: line.label.labelResolver(line),
          style: line.label.style ?? TextStyle(color: line.color, fontSize: 12),
        ),
      )..layout();
      final padding = line.label.padding.resolve(TextDirection.ltr);
      final a = line.label.alignment;
      final x = a.x < 0
          ? g.chart.left + padding.left
          : a.x > 0
          ? g.chart.right - painter.width - padding.right
          : g.chart.center.dx - painter.width / 2;
      final top = a.y <= 0
          ? y - painter.height - padding.bottom
          : y + padding.top;
      painter.paint(canvas, Offset(x, top));
    }
  }
  for (final line in lines.verticalLines) {
    if (line.x < g.data.minX || line.x > g.data.maxX) continue;
    final x = g.x(line.x);
    _flDrawLine(
      canvas,
      Offset(x, g.chart.top),
      Offset(x, g.chart.bottom),
      line,
      cap: line.strokeCap,
    );
  }
}

void _paintBorder(Canvas canvas, _AxisGeometry g, FlBorderData border) {
  if (!border.show) return;
  final b = border.border;
  final r = g.chart;
  void side(BorderSide s, Offset a, Offset c) {
    if (s.width <= 0 || s.style == BorderStyle.none) return;
    canvas.drawLine(
      a,
      c,
      Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke,
    );
  }

  side(b.top, r.topLeft, r.topRight);
  side(b.right, r.topRight, r.bottomRight);
  side(b.bottom, r.bottomLeft, r.bottomRight);
  side(b.left, r.topLeft, r.bottomLeft);
}

// ---------------------------------------------------------------------------
// Titles and tooltips as DOM widgets.

class _TitleSlot extends _DomWidget {
  const _TitleSlot({
    super.key,
    required this.side,
    required this.position,
    required this.extent,
    required this.offset,
    required this.child,
  });
  final AxisSide side;
  final double position, extent, offset;
  final Widget child;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    final p = cssNumber(position), o = cssNumber(offset), e = px(extent);
    out.css(
      'position:absolute;display:flex;box-sizing:border-box;white-space:nowrap;${switch (side) {
        AxisSide.left => 'top:${p}px;right:calc(100% - ${o}px);width:$e;justify-content:flex-end;align-items:center;transform:translateY(-50%);',
        AxisSide.right => 'top:${p}px;left:${o}px;width:$e;justify-content:flex-start;align-items:center;transform:translateY(-50%);',
        AxisSide.top => 'left:${p}px;bottom:calc(100% - ${o}px);height:$e;align-items:flex-end;transform:translateX(-50%);',
        AxisSide.bottom => 'left:${p}px;top:${o}px;height:$e;align-items:flex-start;transform:translateX(-50%);',
      }}',
    );
    out.child(child);
  }
}

List<Widget> _axisTitles(_AxisGeometry g, {List<double>? bottomValues}) {
  final titles = g.titles;
  if (!titles.show) return const [];
  final data = g.data;
  final out = <Widget>[];
  void axis(AxisTitles axisTitles, AxisSide side) {
    final vertical = side == AxisSide.left || side == AxisSide.right;
    final chart = g.chart;
    if (axisTitles.showAxisTitles) {
      final size = axisTitles.axisNameSize;
      out.add(
        _Box(
          css:
              'position:absolute;display:flex;align-items:center;justify-content:center;${switch (side) {
                AxisSide.left => 'left:0;top:${px(chart.top)};width:${px(size)};height:${px(chart.height)};',
                AxisSide.right => 'right:0;top:${px(chart.top)};width:${px(size)};height:${px(chart.height)};',
                AxisSide.top => 'top:0;left:${px(chart.left)};height:${px(size)};width:${px(chart.width)};',
                AxisSide.bottom => 'bottom:0;left:${px(chart.left)};height:${px(size)};width:${px(chart.width)};',
              }}',
          fill: _Fill.none,
          children: [axisTitles.axisNameWidget!],
        ),
      );
    }
    if (!axisTitles.showSideTitles) return;
    final sideTitles = axisTitles.sideTitles;
    final min = vertical ? data.minY : data.minX;
    final max = vertical ? data.maxY : data.maxX;
    final axisPixels = vertical ? chart.height : chart.width;
    final interval =
        sideTitles.interval ?? _efficientInterval(axisPixels, max - min);
    final values = (!vertical && bottomValues != null)
        ? bottomValues
        : _axisValues(
            min,
            max,
            interval,
            minIncluded: sideTitles.minIncluded,
            maxIncluded: sideTitles.maxIncluded,
          );
    for (final value in values) {
      final position = vertical ? g.y(value) : g.x(value);
      final meta = TitleMeta(
        min: min,
        max: max,
        parentAxisSize: axisPixels,
        axisPosition: vertical ? position - chart.top : position - chart.left,
        appliedInterval: interval,
        sideTitles: sideTitles,
        formattedValue: _flFormat(min, max, value),
        axisSide: side,
        rotationQuarterTurns: data.rotationQuarterTurns,
      );
      out.add(
        _TitleSlot(
          key: ValueKey('$side/$value'),
          side: side,
          position: position,
          extent: sideTitles.reservedSize,
          offset: switch (side) {
            AxisSide.left => chart.left,
            AxisSide.right => chart.right,
            AxisSide.top => chart.top,
            AxisSide.bottom => chart.bottom,
          },
          child: sideTitles.getTitlesWidget(value, meta),
        ),
      );
    }
  }

  axis(titles.leftTitles, AxisSide.left);
  axis(titles.topTitles, AxisSide.top);
  axis(titles.rightTitles, AxisSide.right);
  axis(titles.bottomTitles, AxisSide.bottom);
  return out;
}

Widget _tooltip({
  required Offset anchor,
  required Color color,
  required BorderRadius radius,
  required EdgeInsets padding,
  required double margin,
  required double maxWidth,
  required BorderSide border,
  required List<(String, TextStyle, TextAlign, List<TextSpan>?)> items,
}) => KeyedSubtree(
  key: const ValueKey('fl-tooltip'),
  child: _Box(
    css:
        'position:absolute;left:${px(math.max(0, anchor.dx))};top:${cssNumber(anchor.dy - margin)}px;transform:translate(-50%,-100%);z-index:2;pointer-events:none;box-sizing:border-box;max-width:${px(maxWidth + padding.horizontal)};${edgeInsetsCss('padding', padding)}background-color:${colorCss(color)};${borderRadiusCss(radius)}${borderSideCss('border', border)}',
    attributes: const {'role': 'tooltip'},
    fill: _Fill.none,
    children: [
      for (final (text, style, align, children) in items)
        Text.rich(
          TextSpan(text: text, style: style, children: children),
          textAlign: align,
        ),
    ],
  ),
);

/// Shared state for chart widgets: animated data and pointer handling.
abstract class _ChartState<W extends StatefulWidget, D> extends State<W>
    with SingleTickerProviderStateMixin<W> {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration.zero,
  )..addListener(() => setState(() {}));
  late D _from = _target, _shown = _target;
  Offset? _pointer;
  bool _pointerDown = false;

  D get _target;
  Duration get _duration;
  Curve get _curve;
  D _lerp(D a, D b, double t);

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _from = _shown;
    _controller.duration = _duration;
    if (_duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  D get _current {
    final t = _curve.transform(_controller.value);
    return _shown = t >= 1 ? _target : _lerp(_from, _target, t);
  }

  Map<String, _DomHandler> _pointerHandlers(
    void Function(FlTouchEvent event) dispatch,
  ) {
    Offset? at(_Event? event) {
      final x = event?.offsetX, y = event?.offsetY;
      return x == null || y == null ? null : Offset(x, y);
    }

    return {
      'pointermove': (event) {
        final point = at(event);
        setState(() => _pointer = point);
        dispatch(FlPointerHoverEvent(point));
      },
      'pointerdown': (event) {
        _pointerDown = true;
        dispatch(FlTapDownEvent(at(event)));
      },
      'pointerup': (event) {
        if (!_pointerDown) return;
        _pointerDown = false;
        final point = at(event);
        setState(() => _pointer = point);
        dispatch(FlTapUpEvent(point));
      },
      'pointerleave': (event) {
        _pointerDown = false;
        setState(() => _pointer = null);
        dispatch(FlPointerExitEvent(at(event)));
      },
    };
  }
}

Widget _overlay(
  _AxisGeometry g,
  Map<String, _DomHandler> handlers,
  bool enabled,
) => KeyedSubtree(
  key: const ValueKey('fl-overlay'),
  child: _overlayBox(g, handlers, enabled),
);

Widget _overlayBox(
  _AxisGeometry g,
  Map<String, _DomHandler> handlers,
  bool enabled,
) => _Box(
  css:
      'position:absolute;left:${px(g.chart.left)};top:${px(g.chart.top)};width:${px(math.max(0, g.chart.width))};height:${px(math.max(0, g.chart.height))};touch-action:pan-y;',
  handlers: enabled ? handlers : const {},
  fill: _Fill.none,
);

// ---------------------------------------------------------------------------
// LineChart.

class LineChart extends StatefulWidget {
  const LineChart(
    this.data, {
    this.chartRendererKey,
    super.key,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.linear,
    this.transformationConfig = const FlTransformationConfig(),
  });
  final LineChartData data;
  final Key? chartRendererKey;
  final Duration duration;
  final Curve curve;
  final FlTransformationConfig transformationConfig;
  @override
  State<LineChart> createState() => _LineChartState();
}

List<Offset?> _linePoints(LineChartBarData bar, _AxisGeometry g) => [
  for (final spot in bar.spots)
    spot.isNull() ? null : Offset(g.x(spot.x), g.y(spot.y)),
];

/// Smooth curve through points, following fl_chart's tangent construction.
Path _linePath(LineChartBarData bar, List<Offset?> points) {
  final path = Path();
  var segmentStart = true;
  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    if (point == null) {
      segmentStart = true;
      continue;
    }
    if (segmentStart) {
      path.moveTo(point.dx, point.dy);
      segmentStart = false;
      continue;
    }
    final previous = points[i - 1]!;
    if (bar.isStepLineChart) {
      final step =
          previous.dx +
          (point.dx - previous.dx) * bar.lineChartStepData.stepDirection;
      path
        ..lineTo(step, previous.dy)
        ..lineTo(step, point.dy)
        ..lineTo(point.dx, point.dy);
    } else if (bar.isCurved) {
      final beforePrevious = i >= 2 ? points[i - 2] ?? previous : previous;
      final next = i + 1 < points.length ? points[i + 1] ?? point : point;
      final s = bar.curveSmoothness;
      final c1 = previous + (point - beforePrevious) * (s / 2);
      var c2 = point - (next - previous) * (s / 2);
      if (bar.preventCurveOverShooting &&
          (point.dy - previous.dy).abs() <
              bar.preventCurveOvershootingThreshold) {
        c2 = Offset(c2.dx, point.dy);
      }
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path;
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.data, this.touched);
  final LineChartData data;
  final List<TouchLineBarSpot> touched;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _AxisGeometry(size, data.titlesData, data);
    if (g.chart.width <= 0 || g.chart.height <= 0) return;
    _paintAxisBackground(canvas, g);
    if (!data.extraLinesData.extraLinesOnTop) _paintExtraLines(canvas, g);
    canvas.save();
    if (data.clipData.any) canvas.clipRect(g.chart);
    final paths = <int, (Path, List<Offset?>)>{};
    for (var i = 0; i < data.lineBarsData.length; i++) {
      final bar = data.lineBarsData[i];
      if (!bar.show || bar.spots.isEmpty) continue;
      final points = _linePoints(bar, g);
      paths[i] = (_linePath(bar, points), points);
    }
    for (final between in data.betweenBarsData) {
      final from = paths[between.fromIndex], to = paths[between.toIndex];
      if (from == null || to == null) continue;
      final polygon = [
        ...from.$2.whereType<Offset>(),
        ...to.$2.whereType<Offset>().toList().reversed,
      ];
      if (polygon.length < 3) continue;
      final path = Path()..addPolygon(polygon, true);
      canvas.drawPath(
        path,
        _fill(between.color, between.gradient, path.getBounds()),
      );
    }
    for (final entry in paths.entries) {
      final bar = data.lineBarsData[entry.key];
      final (line, points) = entry.value;
      final valid = points.whereType<Offset>().toList();
      if (valid.isEmpty) continue;
      void area(BarAreaData area, bool below) {
        if (!area.show) return;
        final edge = area.applyCutOffY
            ? g.y(area.cutOffY)
            : (below ? g.chart.bottom : g.chart.top);
        final path = Path.from(line)
          ..lineTo(valid.last.dx, edge)
          ..lineTo(valid.first.dx, edge)
          ..close();
        final bounds = Rect.fromLTRB(
          valid.first.dx,
          below ? g.chart.top : edge,
          valid.last.dx,
          below ? edge : g.chart.bottom,
        );
        canvas.drawPath(path, _fill(area.color, area.gradient, bounds));
      }

      area(bar.belowBarData, true);
      area(bar.aboveBarData, false);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bar.barWidth
        ..strokeCap = bar.isStrokeCapRound ? StrokeCap.round : StrokeCap.butt
        ..strokeJoin = bar.isStrokeJoinRound
            ? StrokeJoin.round
            : StrokeJoin.miter
        ..color = bar.color ?? _flBlueGrey;
      if (bar.gradient != null) {
        stroke.shader = bar.gradient!.createShader(
          bar.gradientArea == LineChartGradientArea.wholeChart
              ? g.chart
              : line.getBounds(),
        );
      }
      if (bar.barWidth > 0) {
        if (bar.dashArray != null && bar.dashArray!.isNotEmpty) {
          for (var k = 1; k < points.length; k++) {
            final a = points[k - 1], b = points[k];
            if (a == null || b == null) continue;
            _flDrawLine(
              canvas,
              a,
              b,
              FlLine(
                color: bar.color,
                gradient: bar.gradient,
                strokeWidth: bar.barWidth,
                dashArray: bar.dashArray,
              ),
            );
          }
        } else {
          canvas.drawPath(line, stroke);
        }
      }
      if (bar.dotData.show) {
        for (var k = 0; k < bar.spots.length; k++) {
          final spot = bar.spots[k];
          final point = points[k];
          if (point == null || !bar.dotData.checkToShowDot(spot, bar)) continue;
          final percent = data.horizontalDiff == 0
              ? 0.0
              : (spot.x - data.minX) / data.horizontalDiff;
          bar.dotData
              .getDotPainter(spot, percent, bar, k)
              .draw(canvas, spot, point);
        }
      }
    }
    // Touch indicators.
    final indicators = <int, List<int>>{};
    for (final spot in touched) {
      (indicators[spot.barIndex] ??= []).add(spot.spotIndex);
    }
    for (final entry in indicators.entries) {
      final bar = data.lineBarsData[entry.key];
      final datas = data.lineTouchData.getTouchedSpotIndicator(
        bar,
        entry.value,
      );
      for (var k = 0; k < entry.value.length && k < datas.length; k++) {
        final indicator = datas[k];
        final index = entry.value[k];
        if (indicator == null || index < 0) continue;
        final spot = bar.spots[index];
        final point = Offset(g.x(spot.x), g.y(spot.y));
        final start = data.lineTouchData.getTouchLineStart(bar, index);
        final end = data.lineTouchData.getTouchLineEnd(bar, index);
        _flDrawLine(
          canvas,
          Offset(point.dx, start.isFinite ? g.y(start) : g.chart.bottom),
          Offset(point.dx, end.isFinite ? g.y(end) : g.chart.top),
          indicator.indicatorBelowLine,
        );
        if (indicator.touchedSpotDotData.show) {
          indicator.touchedSpotDotData
              .getDotPainter(spot, 0, bar, index)
              .draw(canvas, spot, point);
        }
      }
    }
    canvas.restore();
    if (data.extraLinesData.extraLinesOnTop) _paintExtraLines(canvas, g);
    _paintBorder(canvas, g, data.borderData);
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      !identical(oldDelegate.data, data) ||
      !listEquals(oldDelegate.touched, touched);
}

class _LineChartState extends _ChartState<LineChart, LineChartData> {
  @override
  LineChartData get _target => widget.data;
  @override
  Duration get _duration => widget.duration;
  @override
  Curve get _curve => widget.curve;
  @override
  LineChartData _lerp(LineChartData a, LineChartData b, double t) =>
      LineChartData.lerp(a, b, t);

  List<TouchLineBarSpot> _touched(
    LineChartData data,
    _AxisGeometry g,
    Offset? pointer,
  ) {
    if (pointer == null) return const [];
    final touch = data.lineTouchData;
    final location = pointer + g.chart.topLeft;
    final result = <TouchLineBarSpot>[];
    for (var i = 0; i < data.lineBarsData.length; i++) {
      final bar = data.lineBarsData[i];
      if (!bar.show) continue;
      TouchLineBarSpot? best;
      for (final spot in bar.spots) {
        if (spot.isNull()) continue;
        final distance = touch.distanceCalculator(
          location,
          Offset(g.x(spot.x), g.y(spot.y)),
        );
        if (distance <= touch.touchSpotThreshold &&
            (best == null || distance < best.distance)) {
          best = TouchLineBarSpot(bar, i, spot, distance);
        }
      }
      if (best != null) result.add(best);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final data = _current;
    return _SizedBuilder(
      sizeBuilder: (context, size) {
        final g = _AxisGeometry(size, data.titlesData, data);
        final touch = data.lineTouchData;
        final touched = touch.enabled
            ? _touched(data, g, _pointer)
            : const <TouchLineBarSpot>[];
        final shown = touch.handleBuiltInTouches
            ? touched
            : const <TouchLineBarSpot>[];
        final tooltipItems = shown.isEmpty
            ? const <LineTooltipItem?>[]
            : touch.touchTooltipData.getTooltipItems(shown);
        final tip = touch.touchTooltipData;
        final anchor = shown.isEmpty
            ? null
            : Offset(
                g.x(shown.first.x),
                tip.showOnTopOfTheChartBoxArea
                    ? g.chart.top
                    : shown.map((s) => g.y(s.y)).reduce(math.min),
              );
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _LinePainter(data, shown)),
            ),
            ..._axisTitles(g),
            _overlay(
              g,
              _pointerHandlers((event) {
                final callback = touch.touchCallback;
                if (callback == null) return;
                final location = event.localPosition == null
                    ? null
                    : event.localPosition! + g.chart.topLeft;
                callback(
                  event,
                  location == null
                      ? null
                      : LineTouchResponse(
                          touchLocation: location,
                          touchChartCoordinate: Offset(
                            g.xValue(location.dx),
                            g.yValue(location.dy),
                          ),
                          lineBarSpots: _touched(data, g, event.localPosition),
                        ),
                );
              }),
              touch.enabled,
            ),
            if (anchor != null && tooltipItems.any((item) => item != null))
              _tooltip(
                anchor: anchor,
                color: tip.getTooltipColor(shown.first),
                radius: tip.tooltipBorderRadius,
                padding: tip.tooltipPadding,
                margin: tip.tooltipMargin,
                maxWidth: tip.maxContentWidth,
                border: tip.tooltipBorder,
                items: [
                  for (final item in tooltipItems)
                    if (item != null)
                      (
                        item.text,
                        item.textStyle,
                        item.textAlign,
                        item.children,
                      ),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// BarChart.

List<double> _groupCenters(BarChartData data, Rect chart) {
  final groups = data.barGroups;
  if (groups.isEmpty) return const [];
  final widths = [for (final group in groups) group.width];
  final total = widths.fold<double>(0, (a, b) => a + b);
  final free = chart.width - total;
  final centers = <double>[];
  double place(double start, double gap) {
    var x = start;
    for (var i = 0; i < groups.length; i++) {
      centers.add(x + widths[i] / 2);
      x += widths[i] + gap;
    }
    return x;
  }

  final n = groups.length;
  switch (data.alignment) {
    case BarChartAlignment.start:
      place(chart.left, data.groupsSpace);
    case BarChartAlignment.end:
      place(chart.right - total - data.groupsSpace * (n - 1), data.groupsSpace);
    case BarChartAlignment.center:
      place(
        chart.left + (chart.width - total - data.groupsSpace * (n - 1)) / 2,
        data.groupsSpace,
      );
    case BarChartAlignment.spaceEvenly:
      final gap = free / (n + 1);
      place(chart.left + gap, gap);
    case BarChartAlignment.spaceAround:
      final gap = free / n;
      place(chart.left + gap / 2, gap);
    case BarChartAlignment.spaceBetween:
      final gap = n == 1 ? 0.0 : free / (n - 1);
      place(n == 1 ? chart.left + free / 2 : chart.left, gap);
  }
  return centers;
}

/// Rod rectangles per group: (group, rod, rect).
List<(int, int, Rect)> _rodRects(BarChartData data, _AxisGeometry g) {
  final centers = _groupCenters(data, g.chart);
  final out = <(int, int, Rect)>[];
  for (var gi = 0; gi < data.barGroups.length; gi++) {
    final group = data.barGroups[gi];
    var x = centers[gi] - group.width / 2;
    for (var ri = 0; ri < group.barRods.length; ri++) {
      final rod = group.barRods[ri];
      final left = group.groupVertically ? centers[gi] - rod.width / 2 : x;
      final top = g.y(math.max(rod.fromY, rod.toY));
      final bottom = g.y(math.min(rod.fromY, rod.toY));
      out.add((gi, ri, Rect.fromLTRB(left, top, left + rod.width, bottom)));
      x += rod.width + group.barsSpace;
    }
  }
  return out;
}

RRect _rodShape(Rect rect, BorderRadius? radius, bool negative) {
  if (radius == null) return RRect.fromRectAndRadius(rect, Radius.zero);
  // Rounded corners sit at the far end of the rod from the baseline.
  return negative
      ? RRect.fromRectAndCorners(
          rect,
          bottomLeft: radius.topLeft,
          bottomRight: radius.topRight,
          topLeft: radius.bottomLeft,
          topRight: radius.bottomRight,
        )
      : RRect.fromRectAndCorners(
          rect,
          topLeft: radius.topLeft,
          topRight: radius.topRight,
          bottomLeft: radius.bottomLeft,
          bottomRight: radius.bottomRight,
        );
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.data, this.touched);
  final BarChartData data;
  final (int, int)? touched;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _AxisGeometry(size, data.titlesData, data);
    if (g.chart.width <= 0 || g.chart.height <= 0) return;
    _paintAxisBackground(canvas, g);
    if (!data.extraLinesData.extraLinesOnTop) _paintExtraLines(canvas, g);
    for (final (gi, ri, rect) in _rodRects(data, g)) {
      final rod = data.barGroups[gi].barRods[ri];
      final back = rod.backDrawRodData;
      if (back.show) {
        final backRect = Rect.fromLTRB(
          rect.left,
          g.y(math.max(back.fromY, back.toY)),
          rect.right,
          g.y(math.min(back.fromY, back.toY)),
        );
        canvas.drawRRect(
          _rodShape(backRect, rod.borderRadius, back.toY < back.fromY),
          _fill(back.color, back.gradient, backRect),
        );
      }
      final negative = rod.toY < rod.fromY;
      final shape = _rodShape(rect, rod.borderRadius, negative);
      if (rect.height > 0 || rod.width > 0) {
        canvas.drawRRect(shape, _fill(rod.color, rod.gradient, rect));
        if (rod.rodStackItems.isNotEmpty) {
          canvas.save();
          canvas.clipRRect(shape);
          for (final item in rod.rodStackItems) {
            final itemRect = Rect.fromLTRB(
              rect.left,
              g.y(math.max(item.fromY, item.toY)),
              rect.right,
              g.y(math.min(item.fromY, item.toY)),
            );
            canvas.drawRect(
              itemRect,
              _fill(item.color, item.gradient, itemRect),
            );
          }
          canvas.restore();
        }
        if (rod.borderSide.width > 0) {
          canvas.drawRRect(
            shape,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = rod.borderSide.width
              ..color = rod.borderSide.color,
          );
        }
      }
    }
    if (data.extraLinesData.extraLinesOnTop) _paintExtraLines(canvas, g);
    _paintBorder(canvas, g, data.borderData);
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      !identical(oldDelegate.data, data) || oldDelegate.touched != touched;
}

class BarChart extends StatefulWidget {
  const BarChart(
    this.data, {
    this.chartRendererKey,
    super.key,
    @Deprecated('Please use [duration] instead')
    Duration? swapAnimationDuration,
    Duration duration = const Duration(milliseconds: 150),
    @Deprecated('Please use [curve] instead') Curve? swapAnimationCurve,
    Curve curve = Curves.linear,
    this.transformationConfig = const FlTransformationConfig(),
  }) : duration = swapAnimationDuration ?? duration,
       curve = swapAnimationCurve ?? curve;
  final BarChartData data;
  final Key? chartRendererKey;
  final Duration duration;
  final Curve curve;
  final FlTransformationConfig transformationConfig;
  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends _ChartState<BarChart, BarChartData> {
  @override
  BarChartData get _target => widget.data;
  @override
  Duration get _duration => widget.duration;
  @override
  Curve get _curve => widget.curve;
  @override
  BarChartData _lerp(BarChartData a, BarChartData b, double t) =>
      BarChartData.lerp(a, b, t);

  BarTouchedSpot? _hit(BarChartData data, _AxisGeometry g, Offset? pointer) {
    if (pointer == null) return null;
    final location = pointer + g.chart.topLeft;
    final extra = data.barTouchData.touchExtraThreshold;
    for (final (gi, ri, rect) in _rodRects(data, g)) {
      final rod = data.barGroups[gi].barRods[ri];
      var target = rect;
      if (data.barTouchData.allowTouchBarBackDraw && rod.backDrawRodData.show) {
        target = target.expandToInclude(
          Rect.fromLTRB(
            rect.left,
            g.y(rod.backDrawRodData.toY),
            rect.right,
            g.y(rod.backDrawRodData.fromY),
          ),
        );
      }
      final hit = Rect.fromLTRB(
        target.left - extra.left,
        target.top - extra.top,
        target.right + extra.right,
        target.bottom + extra.bottom,
      );
      if (!hit.contains(location)) continue;
      final group = data.barGroups[gi];
      return BarTouchedSpot(
        group,
        gi,
        rod,
        ri,
        null,
        -1,
        FlSpot(group.x.toDouble(), rod.toY),
        Offset(rect.center.dx, rect.top),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = _current;
    return _SizedBuilder(
      sizeBuilder: (context, size) {
        final g = _AxisGeometry(size, data.titlesData, data);
        final touch = data.barTouchData;
        final hit = touch.enabled ? _hit(data, g, _pointer) : null;
        final shown = touch.handleBuiltInTouches ? hit : null;
        final tip = touch.touchTooltipData;
        final item = shown == null
            ? null
            : tip.getTooltipItem(
                shown.touchedBarGroup,
                shown.touchedBarGroupIndex,
                shown.touchedRodData,
                shown.touchedRodDataIndex,
              );
        final centers = _groupCenters(data, g.chart);
        final bottomValues = [
          for (final group in data.barGroups) group.x.toDouble(),
        ];
        // Bottom titles sit at group centers rather than on a linear x axis.
        final titleGeometry = _BarTitleGeometry(size, data, centers);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BarPainter(
                  data,
                  shown == null
                      ? null
                      : (shown.touchedBarGroupIndex, shown.touchedRodDataIndex),
                ),
              ),
            ),
            ..._axisTitles(titleGeometry, bottomValues: bottomValues),
            _overlay(
              g,
              _pointerHandlers((event) {
                final callback = touch.touchCallback;
                if (callback == null) return;
                final location = event.localPosition == null
                    ? null
                    : event.localPosition! + g.chart.topLeft;
                callback(
                  event,
                  location == null
                      ? null
                      : BarTouchResponse(
                          touchLocation: location,
                          touchChartCoordinate: Offset(
                            location.dx,
                            g.yValue(location.dy),
                          ),
                          spot: _hit(data, g, event.localPosition),
                        ),
                );
              }),
              touch.enabled,
            ),
            if (shown != null && item != null)
              _tooltip(
                anchor: shown.offset,
                color: tip.getTooltipColor(shown.touchedBarGroup),
                radius: tip.tooltipBorderRadius,
                padding: tip.tooltipPadding,
                margin: tip.tooltipMargin,
                maxWidth: tip.maxContentWidth,
                border: tip.tooltipBorder,
                items: [
                  (item.text, item.textStyle, item.textAlign, item.children),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Maps group x values to their centers for bottom/top titles.
class _BarTitleGeometry extends _AxisGeometry {
  _BarTitleGeometry(Size size, BarChartData data, this.centers)
    : _xs = [for (final group in data.barGroups) group.x.toDouble()],
      super(size, data.titlesData, data);
  final List<double> centers;
  final List<double> _xs;
  @override
  double x(double value) {
    final index = _xs.indexOf(value);
    return index < 0 ? super.x(value) : centers[index];
  }
}

// ---------------------------------------------------------------------------
// PieChart.

class _PieGeometry {
  _PieGeometry(Size size, this.data)
    : center = Offset(size.width / 2, size.height / 2) {
    final maxRadius = data.sections.isEmpty
        ? 0.0
        : data.sections.map((s) => s.radius).reduce(math.max);
    centerRadius = data.centerSpaceRadius.isFinite
        ? data.centerSpaceRadius
        : math.max(0, size.shortestSide / 2 - maxRadius);
    final total = data.sumValue;
    var angle = data.startDegreeOffset * math.pi / 180;
    for (final section in data.sections) {
      final sweep = total == 0 ? 0.0 : section.value / total * math.pi * 2;
      sweeps.add((angle, sweep));
      angle += sweep;
    }
  }
  final PieChartData data;
  final Offset center;
  late final double centerRadius;
  final sweeps = <(double, double)>[];

  Offset at(double angle, double radius) =>
      center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);

  PieTouchedSection? hit(Offset location) {
    final vector = location - center;
    final radius = vector.distance;
    var angle = vector.direction;
    final start = data.startDegreeOffset * math.pi / 180;
    var relative = (angle - start) % (math.pi * 2);
    if (relative < 0) relative += math.pi * 2;
    for (var i = 0; i < data.sections.length; i++) {
      final (from, sweep) = sweeps[i];
      final local = ((from - start) % (math.pi * 2));
      final section = data.sections[i];
      if (relative >= local &&
          relative < local + sweep &&
          radius >= centerRadius &&
          radius <= centerRadius + section.radius) {
        return PieTouchedSection(section, i, angle * 180 / math.pi, radius);
      }
    }
    angle = angle * 180 / math.pi;
    return PieTouchedSection(null, -1, angle, radius);
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.data);
  final PieChartData data;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _PieGeometry(size, data);
    if (data.centerSpaceColor.alpha != 0 && g.centerRadius > 0)
      canvas.drawCircle(
        g.center,
        g.centerRadius,
        Paint()..color = data.centerSpaceColor,
      );
    final single = data.sections.where((s) => s.value > 0).length == 1;
    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final (start, sweep) = g.sweeps[i];
      if (sweep <= 0) continue;
      final outer = g.centerRadius + section.radius;
      final inner = g.centerRadius;
      final path = Path();
      final bounds = Rect.fromCircle(center: g.center, radius: outer);
      if (single || sweep >= math.pi * 2 - 1e-9) {
        path.addOval(bounds);
        if (inner > 0) {
          path
            ..fillType = PathFillType.evenOdd
            ..addOval(Rect.fromCircle(center: g.center, radius: inner));
        }
      } else {
        // Shrink each section by half the gap on both edges.
        final gapOuter = data.sectionsSpace / 2 / outer;
        final gapInner = inner > 0 ? data.sectionsSpace / 2 / inner : 0.0;
        final outerStart = start + gapOuter, outerSweep = sweep - gapOuter * 2;
        if (outerSweep <= 0) continue;
        path.arcTo(bounds, outerStart, outerSweep, true);
        if (inner > 0 && sweep - gapInner * 2 > 0) {
          path.arcTo(
            Rect.fromCircle(center: g.center, radius: inner),
            start + sweep - gapInner,
            -(sweep - gapInner * 2),
            false,
          );
        } else {
          final apex = g.at(
            start + sweep / 2,
            data.sectionsSpace / 2 / math.sin(math.max(sweep / 2, 1e-6)),
          );
          path.lineTo(apex.dx, apex.dy);
        }
        path.close();
      }
      canvas.drawPath(path, _fill(section.color, section.gradient, bounds));
      if (section.borderSide.width > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = section.borderSide.width
            ..color = section.borderSide.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PiePainter oldDelegate) =>
      !identical(oldDelegate.data, data);
}

class _PieLabel extends _DomWidget {
  const _PieLabel({super.key, required this.position, required this.child});
  final Offset position;
  final Widget child;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    out.css(
      'position:absolute;left:${cssNumber(position.dx)}px;top:${cssNumber(position.dy)}px;transform:translate(-50%,-50%);white-space:nowrap;pointer-events:none;',
    );
    out.child(child);
  }
}

class PieChart extends StatefulWidget {
  const PieChart(
    this.data, {
    super.key,
    @Deprecated('Please use [duration] instead')
    Duration? swapAnimationDuration,
    Duration duration = const Duration(milliseconds: 150),
    @Deprecated('Please use [curve] instead') Curve? swapAnimationCurve,
    Curve curve = Curves.linear,
  }) : duration = swapAnimationDuration ?? duration,
       curve = swapAnimationCurve ?? curve;
  final PieChartData data;
  final Duration duration;
  final Curve curve;
  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends _ChartState<PieChart, PieChartData> {
  @override
  PieChartData get _target => widget.data;
  @override
  Duration get _duration => widget.duration;
  @override
  Curve get _curve => widget.curve;
  @override
  PieChartData _lerp(PieChartData a, PieChartData b, double t) =>
      PieChartData.lerp(a, b, t);

  @override
  Widget build(BuildContext context) {
    final data = _current;
    return _SizedBuilder(
      sizeBuilder: (context, size) {
        final g = _PieGeometry(size, data);
        final touch = data.pieTouchData;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _PiePainter(data))),
            for (var i = 0; i < data.sections.length; i++) ...[
              if (data.sections[i].showTitle &&
                  data.sections[i].title.isNotEmpty)
                _PieLabel(
                  key: ValueKey('title$i'),
                  position: g.at(
                    g.sweeps[i].$1 + g.sweeps[i].$2 / 2,
                    g.centerRadius +
                        data.sections[i].radius *
                            data.sections[i].titlePositionPercentageOffset,
                  ),
                  child: Text(
                    data.sections[i].title,
                    style: const TextStyle(
                      color: Color(0xffffffff),
                      fontSize: 16,
                    ).merge(data.sections[i].titleStyle),
                  ),
                ),
              if (data.sections[i].badgeWidget != null)
                _PieLabel(
                  key: ValueKey('badge$i'),
                  position: g.at(
                    g.sweeps[i].$1 + g.sweeps[i].$2 / 2,
                    g.centerRadius +
                        data.sections[i].radius *
                            data.sections[i].badgePositionPercentageOffset,
                  ),
                  child: data.sections[i].badgeWidget!,
                ),
            ],
            if (touch.enabled)
              _Box(
                key: const ValueKey('fl-overlay'),
                css: 'position:absolute;inset:0;touch-action:pan-y;',
                handlers: _pointerHandlers((event) {
                  final callback = touch.touchCallback;
                  final location = event.localPosition;
                  callback?.call(
                    event,
                    location == null
                        ? null
                        : PieTouchResponse(
                            touchLocation: location,
                            touchedSection: g.hit(location),
                          ),
                  );
                }),
                fill: _Fill.none,
              ),
          ],
        );
      },
    );
  }
}
