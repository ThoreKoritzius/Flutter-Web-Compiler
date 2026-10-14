/// Bounded painting and material values translated to CSS by the native
/// runtime. Defaults follow the Material 3 baseline; this is not Flutter's
/// painting library and does not claim pixel parity.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_color_utilities/material_color_utilities.dart';

import 'material_colors.dart';
import 'painting_ui.dart';
import 'ui_enums.dart';

export 'ui_enums.dart';
import 'visual_metadata.dart';

enum FontWeight {
  w100,
  w200,
  w300,
  w400,
  w500,
  w600,
  w700,
  w800,
  w900;

  static const normal = w400;
  static const bold = w700;
  int get value => (index + 1) * 100;
}

enum FontStyle { normal, italic }

enum TextAlign { left, right, center, justify, start, end }

enum TextOverflow { clip, fade, ellipsis, visible }

enum TextDirection { ltr, rtl }

enum TextBaseline { alphabetic, ideographic }

enum TextDecorationStyle { solid, double, dotted, dashed, wavy }

enum TextLeadingDistribution { proportional, even }

class TextHeightBehavior {
  const TextHeightBehavior({
    this.applyHeightToFirstAscent = true,
    this.applyHeightToLastDescent = true,
    this.leadingDistribution = TextLeadingDistribution.proportional,
  });
  final bool applyHeightToFirstAscent, applyHeightToLastDescent;
  final TextLeadingDistribution leadingDistribution;
}

/// A variable-font axis setting (`font-variation-settings`).
class FontVariation {
  const FontVariation(this.axis, this.value);
  const FontVariation.weight(this.value) : axis = 'wght';
  const FontVariation.width(this.value) : axis = 'wdth';
  const FontVariation.slant(this.value) : axis = 'slnt';
  const FontVariation.italic(this.value) : axis = 'ital';
  const FontVariation.opticalSize(this.value) : axis = 'opsz';
  final String axis;
  final double value;
  @override
  bool operator ==(Object other) =>
      other is FontVariation && other.axis == axis && other.value == value;
  @override
  int get hashCode => Object.hash(axis, value);
}

/// A language/script/country identifier, as in `dart:ui`.
class Locale {
  const Locale(this.languageCode, [this.countryCode]) : scriptCode = null;
  const Locale.fromSubtags({
    this.languageCode = 'und',
    this.scriptCode,
    this.countryCode,
  });
  final String languageCode;
  final String? scriptCode, countryCode;

  /// Parses BCP 47 tags such as `de-DE` or `zh-Hant-TW`.
  factory Locale.parse(String tag) {
    final parts = tag.replaceAll('_', '-').split('-');
    String? script, country;
    for (final part in parts.skip(1)) {
      if (part.length == 4) {
        script = part[0].toUpperCase() + part.substring(1).toLowerCase();
      } else if (part.length == 2 || part.length == 3) {
        country = part.toUpperCase();
      }
    }
    return Locale.fromSubtags(
      languageCode: parts.first.toLowerCase(),
      scriptCode: script,
      countryCode: country,
    );
  }

  String toLanguageTag() => [
    languageCode,
    ?scriptCode,
    if (countryCode != null && countryCode!.isNotEmpty) countryCode!,
  ].join('-');

  @override
  bool operator ==(Object other) =>
      other is Locale &&
      other.languageCode == languageCode &&
      other.scriptCode == scriptCode &&
      other.countryCode == countryCode;
  @override
  int get hashCode => Object.hash(languageCode, scriptCode, countryCode);
  @override
  String toString() => [
    languageCode,
    ?scriptCode,
    if (countryCode != null && countryCode!.isNotEmpty) countryCode!,
  ].join('_');
}

enum BoxShape { rectangle, circle }

enum BorderStyle { none, solid }

enum Clip { none, hardEdge, antiAlias, antiAliasWithSaveLayer }

enum DynamicSchemeVariant {
  tonalSpot,
  fidelity,
  monochrome,
  neutral,
  vibrant,
  expressive,
  content,
  rainbow,
  fruitSalad,
}

/// OpenType feature settings; only CSS-expressible features are emitted.
class FontFeature {
  const FontFeature(this.feature, [this.value = 1]);
  const FontFeature.enable(this.feature) : value = 1;
  const FontFeature.disable(this.feature) : value = 0;
  const FontFeature.tabularFigures() : feature = 'tnum', value = 1;
  const FontFeature.proportionalFigures() : feature = 'pnum', value = 1;
  final String feature;
  final int value;
}

class TextDecoration {
  const TextDecoration._(this._mask);
  factory TextDecoration.combine(List<TextDecoration> decorations) =>
      TextDecoration._(decorations.fold(0, (mask, item) => mask | item._mask));
  final int _mask;
  static const none = TextDecoration._(0);
  static const underline = TextDecoration._(1);
  static const overline = TextDecoration._(2);
  static const lineThrough = TextDecoration._(4);
  bool contains(TextDecoration other) => (_mask | other._mask) == _mask;
  @override
  bool operator ==(Object other) =>
      other is TextDecoration && other._mask == _mask;
  @override
  int get hashCode => _mask.hashCode;
}

class Offset {
  const Offset(this.dx, this.dy);
  factory Offset.fromDirection(double direction, [double distance = 1]) =>
      Offset(distance * math.cos(direction), distance * math.sin(direction));
  final double dx, dy;
  static const zero = Offset(0, 0);
  static const infinite = Offset(double.infinity, double.infinity);
  double get distance => math.sqrt(dx * dx + dy * dy);
  double get distanceSquared => dx * dx + dy * dy;
  double get direction => math.atan2(dy, dx);
  bool get isFinite => dx.isFinite && dy.isFinite;
  Offset scale(double scaleX, double scaleY) =>
      Offset(dx * scaleX, dy * scaleY);
  Offset translate(double translateX, double translateY) =>
      Offset(dx + translateX, dy + translateY);
  Offset operator -() => Offset(-dx, -dy);
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);
  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);
  Offset operator *(double operand) => Offset(dx * operand, dy * operand);
  Offset operator /(double operand) => Offset(dx / operand, dy / operand);
  Offset operator %(double operand) => Offset(dx % operand, dy % operand);
  Rect operator &(Size other) =>
      Rect.fromLTWH(dx, dy, other.width, other.height);
  static Offset? lerp(Offset? a, Offset? b, double t) {
    if (a == null || b == null) return a ?? b;
    return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  }

  @override
  bool operator ==(Object other) =>
      other is Offset && other.dx == dx && other.dy == dy;
  @override
  int get hashCode => Object.hash(dx, dy);
  @override
  String toString() => 'Offset($dx, $dy)';
}

/// Width and height, as in `dart:ui`.
class Size {
  const Size(this.width, this.height);
  static Size? lerp(Size? a, Size? b, double t) => lerpSize(a, b, t);
  const Size.square(double dimension) : width = dimension, height = dimension;
  const Size.fromWidth(this.width) : height = double.infinity;
  const Size.fromHeight(this.height) : width = double.infinity;
  const Size.fromRadius(double radius)
    : width = radius * 2,
      height = radius * 2;
  final double width, height;
  static const zero = Size(0, 0);
  static const infinite = Size(double.infinity, double.infinity);
  double get shortestSide => math.min(width, height);
  double get longestSide => math.max(width, height);
  double get aspectRatio => height == 0 ? 0 : width / height;
  bool get isEmpty => width <= 0 || height <= 0;
  bool get isFinite => width.isFinite && height.isFinite;
  Offset center(Offset origin) =>
      Offset(origin.dx + width / 2, origin.dy + height / 2);
  Size operator *(double operand) => Size(width * operand, height * operand);
  Size operator /(double operand) => Size(width / operand, height / operand);
  Size operator +(Offset other) => Size(width + other.dx, height + other.dy);
  Offset operator -(Size other) =>
      Offset(width - other.width, height - other.height);
  bool contains(Offset offset) =>
      offset.dx >= 0 &&
      offset.dx < width &&
      offset.dy >= 0 &&
      offset.dy < height;
  @override
  bool operator ==(Object other) =>
      other is Size && other.width == width && other.height == height;
  @override
  int get hashCode => Object.hash(width, height);
  @override
  String toString() => 'Size($width, $height)';
}

class Rect {
  const Rect.fromLTRB(this.left, this.top, this.right, this.bottom);
  const Rect.fromLTWH(double left, double top, double width, double height)
    : this.fromLTRB(left, top, left + width, top + height);
  Rect.fromCircle({required Offset center, required double radius})
    : this.fromCenter(center: center, width: radius * 2, height: radius * 2);
  Rect.fromCenter({
    required Offset center,
    required double width,
    required double height,
  }) : this.fromLTRB(
         center.dx - width / 2,
         center.dy - height / 2,
         center.dx + width / 2,
         center.dy + height / 2,
       );
  Rect.fromPoints(Offset a, Offset b)
    : this.fromLTRB(
        math.min(a.dx, b.dx),
        math.min(a.dy, b.dy),
        math.max(a.dx, b.dx),
        math.max(a.dy, b.dy),
      );
  final double left, top, right, bottom;
  static const zero = Rect.fromLTRB(0, 0, 0, 0);
  static const largest = Rect.fromLTRB(-1e9, -1e9, 1e9, 1e9);
  double get width => right - left;
  double get height => bottom - top;
  Size get size => Size(width, height);
  bool get isEmpty => left >= right || top >= bottom;
  bool get isFinite =>
      left.isFinite && top.isFinite && right.isFinite && bottom.isFinite;
  double get shortestSide => math.min(width.abs(), height.abs());
  double get longestSide => math.max(width.abs(), height.abs());
  Offset get topLeft => Offset(left, top);
  Offset get topCenter => Offset(left + width / 2, top);
  Offset get topRight => Offset(right, top);
  Offset get centerLeft => Offset(left, top + height / 2);
  Offset get center => Offset(left + width / 2, top + height / 2);
  Offset get centerRight => Offset(right, top + height / 2);
  Offset get bottomLeft => Offset(left, bottom);
  Offset get bottomCenter => Offset(left + width / 2, bottom);
  Offset get bottomRight => Offset(right, bottom);
  Rect shift(Offset offset) => Rect.fromLTRB(
    left + offset.dx,
    top + offset.dy,
    right + offset.dx,
    bottom + offset.dy,
  );
  Rect translate(double translateX, double translateY) =>
      shift(Offset(translateX, translateY));
  Rect inflate(double delta) =>
      Rect.fromLTRB(left - delta, top - delta, right + delta, bottom + delta);
  Rect deflate(double delta) => inflate(-delta);
  Rect intersect(Rect other) => Rect.fromLTRB(
    math.max(left, other.left),
    math.max(top, other.top),
    math.min(right, other.right),
    math.min(bottom, other.bottom),
  );
  Rect expandToInclude(Rect other) => Rect.fromLTRB(
    math.min(left, other.left),
    math.min(top, other.top),
    math.max(right, other.right),
    math.max(bottom, other.bottom),
  );
  bool overlaps(Rect other) =>
      right > other.left &&
      other.right > left &&
      bottom > other.top &&
      other.bottom > top;
  bool contains(Offset offset) =>
      offset.dx >= left &&
      offset.dx < right &&
      offset.dy >= top &&
      offset.dy < bottom;
  static Rect? lerp(Rect? a, Rect? b, double t) {
    if (a == null || b == null) return a ?? b;
    double mix(double x, double y) => x + (y - x) * t;
    return Rect.fromLTRB(
      mix(a.left, b.left),
      mix(a.top, b.top),
      mix(a.right, b.right),
      mix(a.bottom, b.bottom),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Rect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;
  @override
  int get hashCode => Object.hash(left, top, right, bottom);
  @override
  String toString() => 'Rect.fromLTRB($left, $top, $right, $bottom)';
}

class RRect {
  const RRect.fromLTRBAndCorners(
    this.left,
    this.top,
    this.right,
    this.bottom, {
    this.topLeft = Radius.zero,
    this.topRight = Radius.zero,
    this.bottomRight = Radius.zero,
    this.bottomLeft = Radius.zero,
  });
  RRect.fromLTRBR(
    double left,
    double top,
    double right,
    double bottom,
    Radius radius,
  ) : this.fromLTRBAndCorners(
        left,
        top,
        right,
        bottom,
        topLeft: radius,
        topRight: radius,
        bottomRight: radius,
        bottomLeft: radius,
      );
  RRect.fromLTRBXY(
    double left,
    double top,
    double right,
    double bottom,
    double radiusX,
    double radiusY,
  ) : this.fromLTRBR(
        left,
        top,
        right,
        bottom,
        Radius.elliptical(radiusX, radiusY),
      );
  RRect.fromRectAndRadius(Rect rect, Radius radius)
    : this.fromLTRBR(rect.left, rect.top, rect.right, rect.bottom, radius);
  RRect.fromRectXY(Rect rect, double radiusX, double radiusY)
    : this.fromRectAndRadius(rect, Radius.elliptical(radiusX, radiusY));
  RRect.fromRectAndCorners(
    Rect rect, {
    Radius topLeft = Radius.zero,
    Radius topRight = Radius.zero,
    Radius bottomRight = Radius.zero,
    Radius bottomLeft = Radius.zero,
  }) : this.fromLTRBAndCorners(
         rect.left,
         rect.top,
         rect.right,
         rect.bottom,
         topLeft: topLeft,
         topRight: topRight,
         bottomRight: bottomRight,
         bottomLeft: bottomLeft,
       );
  final double left, top, right, bottom;
  final Radius topLeft, topRight, bottomRight, bottomLeft;
  double get width => right - left;
  double get height => bottom - top;
  Rect get outerRect => Rect.fromLTRB(left, top, right, bottom);
  Offset get center => Offset(left + width / 2, top + height / 2);
  RRect shift(Offset offset) => RRect.fromLTRBAndCorners(
    left + offset.dx,
    top + offset.dy,
    right + offset.dx,
    bottom + offset.dy,
    topLeft: topLeft,
    topRight: topRight,
    bottomRight: bottomRight,
    bottomLeft: bottomLeft,
  );
  RRect inflate(double delta) => RRect.fromLTRBAndCorners(
    left - delta,
    top - delta,
    right + delta,
    bottom + delta,
    topLeft: Radius.elliptical(topLeft.x + delta, topLeft.y + delta),
    topRight: Radius.elliptical(topRight.x + delta, topRight.y + delta),
    bottomRight: Radius.elliptical(
      bottomRight.x + delta,
      bottomRight.y + delta,
    ),
    bottomLeft: Radius.elliptical(bottomLeft.x + delta, bottomLeft.y + delta),
  );
  RRect deflate(double delta) => inflate(-delta);
}

class TextStyle {
  static TextStyle? lerp(TextStyle? a, TextStyle? b, double t) =>
      lerpTextStyle(a, b, t);
  const TextStyle({
    this.inherit = true,
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontFeatures,
    this.overflow,
    this.decorationStyle,
    this.decorationThickness,
    this.shadows,
    this.textBaseline,
    this.leadingDistribution,
    this.locale,
    this.foreground,
    this.background,
    this.fontVariations,
    this.debugLabel,
    String? package,
  });
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final List<Shadow>? shadows;
  final TextBaseline? textBaseline;
  final TextLeadingDistribution? leadingDistribution;
  final Object? locale;
  final Paint? foreground, background;
  final List<FontVariation>? fontVariations;
  final String? debugLabel;
  final bool inherit;
  final Color? color, backgroundColor, decorationColor;
  final double? fontSize, letterSpacing, wordSpacing, height;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final List<FontFeature>? fontFeatures;
  final TextOverflow? overflow;

  TextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    List<FontFeature>? fontFeatures,
    TextOverflow? overflow,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
    TextLeadingDistribution? leadingDistribution,
    Object? locale,
    Paint? foreground,
    Paint? background,
    List<FontVariation>? fontVariations,
    String? debugLabel,
    String? package,
  }) => TextStyle(
    decorationStyle: decorationStyle ?? this.decorationStyle,
    decorationThickness: decorationThickness ?? this.decorationThickness,
    shadows: shadows ?? this.shadows,
    textBaseline: textBaseline ?? this.textBaseline,
    leadingDistribution: leadingDistribution ?? this.leadingDistribution,
    locale: locale ?? this.locale,
    foreground: foreground ?? this.foreground,
    background: background ?? this.background,
    fontVariations: fontVariations ?? this.fontVariations,
    debugLabel: debugLabel ?? this.debugLabel,
    inherit: inherit ?? this.inherit,
    color: color ?? this.color,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    fontStyle: fontStyle ?? this.fontStyle,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    wordSpacing: wordSpacing ?? this.wordSpacing,
    height: height ?? this.height,
    decoration: decoration ?? this.decoration,
    decorationColor: decorationColor ?? this.decorationColor,
    fontFamily: fontFamily ?? this.fontFamily,
    fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
    fontFeatures: fontFeatures ?? this.fontFeatures,
    overflow: overflow ?? this.overflow,
  );

  /// Non-null fields of [other] take precedence, as in Flutter.
  TextStyle merge(TextStyle? other) {
    if (other == null) return this;
    if (!other.inherit) return other;
    return copyWith(
      color: other.color,
      backgroundColor: other.backgroundColor,
      fontSize: other.fontSize,
      fontWeight: other.fontWeight,
      fontStyle: other.fontStyle,
      letterSpacing: other.letterSpacing,
      wordSpacing: other.wordSpacing,
      height: other.height,
      decoration: other.decoration,
      decorationColor: other.decorationColor,
      fontFamily: other.fontFamily,
      fontFamilyFallback: other.fontFamilyFallback,
      fontFeatures: other.fontFeatures,
      overflow: other.overflow,
      decorationStyle: other.decorationStyle,
      decorationThickness: other.decorationThickness,
      shadows: other.shadows,
      textBaseline: other.textBaseline,
      leadingDistribution: other.leadingDistribution,
      locale: other.locale,
      foreground: other.foreground,
      background: other.background,
      fontVariations: other.fontVariations,
    );
  }

  TextStyle apply({
    Color? color,
    Color? backgroundColor,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double decorationThicknessFactor = 1,
    double decorationThicknessDelta = 0,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double fontSizeFactor = 1,
    double fontSizeDelta = 0,
    int fontWeightDelta = 0,
    FontStyle? fontStyle,
    double letterSpacingFactor = 1,
    double letterSpacingDelta = 0,
    double wordSpacingFactor = 1,
    double wordSpacingDelta = 0,
    double heightFactor = 1,
    double heightDelta = 0,
    TextBaseline? textBaseline,
    TextLeadingDistribution? leadingDistribution,
    Object? locale,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    String? package,
    TextOverflow? overflow,
  }) => copyWith(
    color: color,
    backgroundColor: backgroundColor,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness == null
        ? null
        : decorationThickness! * decorationThicknessFactor +
              decorationThicknessDelta,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize == null
        ? null
        : fontSize! * fontSizeFactor + fontSizeDelta,
    fontWeight: fontWeight == null
        ? null
        : FontWeight.values[(fontWeight!.index + fontWeightDelta).clamp(
            0,
            FontWeight.values.length - 1,
          )],
    fontStyle: fontStyle,
    letterSpacing: letterSpacing == null
        ? null
        : letterSpacing! * letterSpacingFactor + letterSpacingDelta,
    wordSpacing: wordSpacing == null
        ? null
        : wordSpacing! * wordSpacingFactor + wordSpacingDelta,
    height: height == null ? null : height! * heightFactor + heightDelta,
    textBaseline: textBaseline,
    leadingDistribution: leadingDistribution,
    locale: locale,
    shadows: shadows,
    fontFeatures: fontFeatures,
    fontVariations: fontVariations,
    overflow: overflow,
  );
}

TextStyle _m3(double size, double lineHeight, FontWeight weight, double ls) =>
    TextStyle(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: ls,
    );

/// Material 3 (2021) type scale without colors; colors come from the scheme.
class TextTheme {
  const TextTheme({
    this.displayLarge,
    this.displayMedium,
    this.displaySmall,
    this.headlineLarge,
    this.headlineMedium,
    this.headlineSmall,
    this.titleLarge,
    this.titleMedium,
    this.titleSmall,
    this.bodyLarge,
    this.bodyMedium,
    this.bodySmall,
    this.labelLarge,
    this.labelMedium,
    this.labelSmall,
  });
  final TextStyle? displayLarge, displayMedium, displaySmall;
  final TextStyle? headlineLarge, headlineMedium, headlineSmall;
  final TextStyle? titleLarge, titleMedium, titleSmall;
  final TextStyle? bodyLarge, bodyMedium, bodySmall;
  final TextStyle? labelLarge, labelMedium, labelSmall;

  static final material3 = TextTheme(
    displayLarge: _m3(57, 64, FontWeight.w400, -0.25),
    displayMedium: _m3(45, 52, FontWeight.w400, 0),
    displaySmall: _m3(36, 44, FontWeight.w400, 0),
    headlineLarge: _m3(32, 40, FontWeight.w400, 0),
    headlineMedium: _m3(28, 36, FontWeight.w400, 0),
    headlineSmall: _m3(24, 32, FontWeight.w400, 0),
    titleLarge: _m3(22, 28, FontWeight.w400, 0),
    titleMedium: _m3(16, 24, FontWeight.w500, 0.15),
    titleSmall: _m3(14, 20, FontWeight.w500, 0.1),
    bodyLarge: _m3(16, 24, FontWeight.w400, 0.5),
    bodyMedium: _m3(14, 20, FontWeight.w400, 0.25),
    bodySmall: _m3(12, 16, FontWeight.w400, 0.4),
    labelLarge: _m3(14, 20, FontWeight.w500, 0.1),
    labelMedium: _m3(12, 16, FontWeight.w500, 0.5),
    labelSmall: _m3(11, 16, FontWeight.w500, 0.5),
  );

  TextTheme copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
  }) => TextTheme(
    displayLarge: displayLarge ?? this.displayLarge,
    displayMedium: displayMedium ?? this.displayMedium,
    displaySmall: displaySmall ?? this.displaySmall,
    headlineLarge: headlineLarge ?? this.headlineLarge,
    headlineMedium: headlineMedium ?? this.headlineMedium,
    headlineSmall: headlineSmall ?? this.headlineSmall,
    titleLarge: titleLarge ?? this.titleLarge,
    titleMedium: titleMedium ?? this.titleMedium,
    titleSmall: titleSmall ?? this.titleSmall,
    bodyLarge: bodyLarge ?? this.bodyLarge,
    bodyMedium: bodyMedium ?? this.bodyMedium,
    bodySmall: bodySmall ?? this.bodySmall,
    labelLarge: labelLarge ?? this.labelLarge,
    labelMedium: labelMedium ?? this.labelMedium,
    labelSmall: labelSmall ?? this.labelSmall,
  );

  TextTheme merge(TextTheme? other) {
    if (other == null) return this;
    TextStyle? pick(TextStyle? mine, TextStyle? theirs) =>
        mine == null ? theirs : mine.merge(theirs);
    return TextTheme(
      displayLarge: pick(displayLarge, other.displayLarge),
      displayMedium: pick(displayMedium, other.displayMedium),
      displaySmall: pick(displaySmall, other.displaySmall),
      headlineLarge: pick(headlineLarge, other.headlineLarge),
      headlineMedium: pick(headlineMedium, other.headlineMedium),
      headlineSmall: pick(headlineSmall, other.headlineSmall),
      titleLarge: pick(titleLarge, other.titleLarge),
      titleMedium: pick(titleMedium, other.titleMedium),
      titleSmall: pick(titleSmall, other.titleSmall),
      bodyLarge: pick(bodyLarge, other.bodyLarge),
      bodyMedium: pick(bodyMedium, other.bodyMedium),
      bodySmall: pick(bodySmall, other.bodySmall),
      labelLarge: pick(labelLarge, other.labelLarge),
      labelMedium: pick(labelMedium, other.labelMedium),
      labelSmall: pick(labelSmall, other.labelSmall),
    );
  }

  /// As in Flutter, [displayColor] applies to the display and headline
  /// styles and `bodySmall`; [bodyColor] applies to the rest.
  TextTheme apply({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    double fontSizeFactor = 1.0,
    double fontSizeDelta = 0.0,
    Color? displayColor,
    Color? bodyColor,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    TextStyle? Function(TextStyle?) with_(Color? color) =>
        (style) => style
            ?.apply(
              color: color,
              decorationColor: decorationColor,
              fontFamily: fontFamily,
              fontSizeFactor: fontSizeFactor,
              fontSizeDelta: fontSizeDelta,
            )
            .copyWith(
              fontFamilyFallback: fontFamilyFallback,
              decoration: decoration,
            );
    final display = with_(displayColor);
    final body = with_(bodyColor);
    return TextTheme(
      displayLarge: display(displayLarge),
      displayMedium: display(displayMedium),
      displaySmall: display(displaySmall),
      headlineLarge: display(headlineLarge),
      headlineMedium: display(headlineMedium),
      headlineSmall: display(headlineSmall),
      titleLarge: body(titleLarge),
      titleMedium: body(titleMedium),
      titleSmall: body(titleSmall),
      bodyLarge: body(bodyLarge),
      bodyMedium: body(bodyMedium),
      bodySmall: display(bodySmall),
      labelLarge: body(labelLarge),
      labelMedium: body(labelMedium),
      labelSmall: body(labelSmall),
    );
  }

  static TextTheme lerp(TextTheme? a, TextTheme? b, double t) =>
      (t < 0.5 ? a : b) ?? const TextTheme();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextTheme &&
          other.displayLarge == displayLarge &&
          other.displayMedium == displayMedium &&
          other.displaySmall == displaySmall &&
          other.headlineLarge == headlineLarge &&
          other.headlineMedium == headlineMedium &&
          other.headlineSmall == headlineSmall &&
          other.titleLarge == titleLarge &&
          other.titleMedium == titleMedium &&
          other.titleSmall == titleSmall &&
          other.bodyLarge == bodyLarge &&
          other.bodyMedium == bodyMedium &&
          other.bodySmall == bodySmall &&
          other.labelLarge == labelLarge &&
          other.labelMedium == labelMedium &&
          other.labelSmall == labelSmall;

  @override
  int get hashCode => Object.hash(
    displayLarge,
    displayMedium,
    displaySmall,
    headlineLarge,
    headlineMedium,
    headlineSmall,
    titleLarge,
    titleMedium,
    titleSmall,
    bodyLarge,
    bodyMedium,
    bodySmall,
    labelLarge,
    labelMedium,
    labelSmall,
  );
}

/// Material 3 baseline roles. Unspecified roles use the baseline light scheme.
class ColorScheme {
  const ColorScheme({
    this.brightness = Brightness.light,
    this.primary = const Color(0xff6750a4),
    this.onPrimary = const Color(0xffffffff),
    this.primaryContainer = const Color(0xffeaddff),
    this.onPrimaryContainer = const Color(0xff21005d),
    this.secondary = const Color(0xff625b71),
    this.onSecondary = const Color(0xffffffff),
    this.secondaryContainer = const Color(0xffe8def8),
    this.onSecondaryContainer = const Color(0xff1d192b),
    this.tertiary = const Color(0xff7d5260),
    this.onTertiary = const Color(0xffffffff),
    this.tertiaryContainer = const Color(0xffffd8e4),
    this.onTertiaryContainer = const Color(0xff31111d),
    this.error = const Color(0xffb3261e),
    this.onError = const Color(0xffffffff),
    this.errorContainer = const Color(0xfff9dedc),
    this.onErrorContainer = const Color(0xff410e0b),
    this.surface = const Color(0xfffffbfe),
    this.onSurface = const Color(0xff1c1b1f),
    this.surfaceDim = const Color(0xffded8e1),
    this.surfaceBright = const Color(0xfffef7ff),
    this.surfaceContainerLowest = const Color(0xffffffff),
    this.surfaceContainerLow = const Color(0xfff7f2fa),
    this.surfaceContainer = const Color(0xfff3edf7),
    this.surfaceContainerHigh = const Color(0xffece6f0),
    this.surfaceContainerHighest = const Color(0xffe6e0e9),
    this.onSurfaceVariant = const Color(0xff49454f),
    this.outline = const Color(0xff79747e),
    this.outlineVariant = const Color(0xffcac4d0),
    this.shadow = const Color(0xff000000),
    this.scrim = const Color(0xff000000),
    this.inverseSurface = const Color(0xff322f35),
    this.onInverseSurface = const Color(0xfff5eff7),
    this.inversePrimary = const Color(0xffd0bcff),
    this.primaryFixed = const Color(0xffeaddff),
    this.primaryFixedDim = const Color(0xffd0bcff),
    this.onPrimaryFixed = const Color(0xff21005d),
    this.onPrimaryFixedVariant = const Color(0xff4f378b),
    this.secondaryFixed = const Color(0xffe8def8),
    this.secondaryFixedDim = const Color(0xffccc2dc),
    this.onSecondaryFixed = const Color(0xff1d192b),
    this.onSecondaryFixedVariant = const Color(0xff4a4458),
    this.tertiaryFixed = const Color(0xffffd8e4),
    this.tertiaryFixedDim = const Color(0xffefb8c8),
    this.onTertiaryFixed = const Color(0xff31111d),
    this.onTertiaryFixedVariant = const Color(0xff633b48),
    Color? surfaceTint,
    @Deprecated('Use surface instead.') Color? background,
    @Deprecated('Use onSurface instead.') Color? onBackground,
    @Deprecated('Use surfaceContainerHighest instead.') Color? surfaceVariant,
  }) : _surfaceTint = surfaceTint,
       _background = background,
       _onBackground = onBackground,
       _surfaceVariant = surfaceVariant;

  /// Material 3 dynamic color, computed with the same
  /// material_color_utilities schemes Flutter uses.
  factory ColorScheme.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
    DynamicSchemeVariant dynamicSchemeVariant = DynamicSchemeVariant.tonalSpot,
    double contrastLevel = 0.0,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? surface,
    Color? onSurface,
    Color? surfaceContainerHighest,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? onPrimaryFixed,
    Color? onPrimaryFixedVariant,
    Color? secondaryFixed,
    Color? secondaryFixedDim,
    Color? onSecondaryFixed,
    Color? onSecondaryFixedVariant,
    Color? tertiaryFixed,
    Color? tertiaryFixedDim,
    Color? onTertiaryFixed,
    Color? onTertiaryFixedVariant,
    Color? surfaceDim,
    Color? surfaceBright,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? shadow,
    Color? scrim,
    Color? surfaceTint,
    @Deprecated('Use surface instead.') Color? background,
    @Deprecated('Use onSurface instead.') Color? onBackground,
    @Deprecated('Use surfaceContainerHighest instead.') Color? surfaceVariant,
  }) {
    if (contrastLevel < -1 || contrastLevel > 1)
      throw ArgumentError('contrastLevel must be between -1.0 and 1.0.');
    final source = Hct.fromInt(seedColor.value);
    final dark = brightness == Brightness.dark;
    final scheme = switch (dynamicSchemeVariant) {
      DynamicSchemeVariant.tonalSpot => SchemeTonalSpot(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.fidelity => SchemeFidelity(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.content => SchemeContent(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.monochrome => SchemeMonochrome(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.neutral => SchemeNeutral(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.vibrant => SchemeVibrant(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.expressive => SchemeExpressive(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.rainbow => SchemeRainbow(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.fruitSalad => SchemeFruitSalad(
        sourceColorHct: source,
        isDark: dark,
        contrastLevel: contrastLevel,
      ),
    };
    Color role(DynamicColor color) => Color(color.getArgb(scheme));
    final base = ColorScheme(
      brightness: brightness,
      primary: primary ?? role(MaterialDynamicColors.primary),
      onPrimary: onPrimary ?? role(MaterialDynamicColors.onPrimary),
      primaryContainer:
          primaryContainer ?? role(MaterialDynamicColors.primaryContainer),
      onPrimaryContainer:
          onPrimaryContainer ?? role(MaterialDynamicColors.onPrimaryContainer),
      primaryFixed: role(MaterialDynamicColors.primaryFixed),
      primaryFixedDim: role(MaterialDynamicColors.primaryFixedDim),
      onPrimaryFixed: role(MaterialDynamicColors.onPrimaryFixed),
      onPrimaryFixedVariant: role(MaterialDynamicColors.onPrimaryFixedVariant),
      secondary: secondary ?? role(MaterialDynamicColors.secondary),
      onSecondary: onSecondary ?? role(MaterialDynamicColors.onSecondary),
      secondaryContainer:
          secondaryContainer ?? role(MaterialDynamicColors.secondaryContainer),
      onSecondaryContainer:
          onSecondaryContainer ??
          role(MaterialDynamicColors.onSecondaryContainer),
      secondaryFixed: role(MaterialDynamicColors.secondaryFixed),
      secondaryFixedDim: role(MaterialDynamicColors.secondaryFixedDim),
      onSecondaryFixed: role(MaterialDynamicColors.onSecondaryFixed),
      onSecondaryFixedVariant: role(
        MaterialDynamicColors.onSecondaryFixedVariant,
      ),
      tertiary: tertiary ?? role(MaterialDynamicColors.tertiary),
      onTertiary: onTertiary ?? role(MaterialDynamicColors.onTertiary),
      tertiaryContainer:
          tertiaryContainer ?? role(MaterialDynamicColors.tertiaryContainer),
      onTertiaryContainer:
          onTertiaryContainer ??
          role(MaterialDynamicColors.onTertiaryContainer),
      tertiaryFixed: role(MaterialDynamicColors.tertiaryFixed),
      tertiaryFixedDim: role(MaterialDynamicColors.tertiaryFixedDim),
      onTertiaryFixed: role(MaterialDynamicColors.onTertiaryFixed),
      onTertiaryFixedVariant: role(
        MaterialDynamicColors.onTertiaryFixedVariant,
      ),
      error: error ?? role(MaterialDynamicColors.error),
      onError: onError ?? role(MaterialDynamicColors.onError),
      errorContainer:
          errorContainer ?? role(MaterialDynamicColors.errorContainer),
      onErrorContainer:
          onErrorContainer ?? role(MaterialDynamicColors.onErrorContainer),
      outline: outline ?? role(MaterialDynamicColors.outline),
      outlineVariant:
          outlineVariant ?? role(MaterialDynamicColors.outlineVariant),
      surface: surface ?? role(MaterialDynamicColors.surface),
      surfaceDim: role(MaterialDynamicColors.surfaceDim),
      surfaceBright: role(MaterialDynamicColors.surfaceBright),
      surfaceContainerLowest: role(
        MaterialDynamicColors.surfaceContainerLowest,
      ),
      surfaceContainerLow: role(MaterialDynamicColors.surfaceContainerLow),
      surfaceContainer: role(MaterialDynamicColors.surfaceContainer),
      surfaceContainerHigh: role(MaterialDynamicColors.surfaceContainerHigh),
      surfaceContainerHighest:
          surfaceContainerHighest ??
          role(MaterialDynamicColors.surfaceContainerHighest),
      onSurface: onSurface ?? role(MaterialDynamicColors.onSurface),
      onSurfaceVariant:
          onSurfaceVariant ?? role(MaterialDynamicColors.onSurfaceVariant),
      inverseSurface: role(MaterialDynamicColors.inverseSurface),
      onInverseSurface: role(MaterialDynamicColors.inverseOnSurface),
      inversePrimary: role(MaterialDynamicColors.inversePrimary),
      shadow: role(MaterialDynamicColors.shadow),
      scrim: role(MaterialDynamicColors.scrim),
      surfaceTint: role(MaterialDynamicColors.primary),
    );
    return base.copyWith(
      primaryFixed: primaryFixed,
      primaryFixedDim: primaryFixedDim,
      onPrimaryFixed: onPrimaryFixed,
      onPrimaryFixedVariant: onPrimaryFixedVariant,
      secondaryFixed: secondaryFixed,
      secondaryFixedDim: secondaryFixedDim,
      onSecondaryFixed: onSecondaryFixed,
      onSecondaryFixedVariant: onSecondaryFixedVariant,
      tertiaryFixed: tertiaryFixed,
      tertiaryFixedDim: tertiaryFixedDim,
      onTertiaryFixed: onTertiaryFixed,
      onTertiaryFixedVariant: onTertiaryFixedVariant,
      surfaceDim: surfaceDim,
      surfaceBright: surfaceBright,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      inversePrimary: inversePrimary,
      shadow: shadow,
      scrim: scrim,
      surfaceTint: surfaceTint,
      // ignore: deprecated_member_use_from_same_package
      background: background,
      // ignore: deprecated_member_use_from_same_package
      onBackground: onBackground,
      // ignore: deprecated_member_use_from_same_package
      surfaceVariant: surfaceVariant,
    );
  }

  /// Material 2 scheme derived from a swatch, as in Flutter.
  factory ColorScheme.fromSwatch({
    MaterialColor primarySwatch = Colors.blue,
    Color? primaryColorDark,
    Color? accentColor,
    Color? cardColor,
    Color? backgroundColor,
    Color? errorColor,
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;
    final primaryIsDark = _isDarkColor(primarySwatch);
    final secondary =
        accentColor ?? (isDark ? Colors.tealAccent[200]! : primarySwatch);
    final secondaryIsDark = _isDarkColor(secondary);
    return ColorScheme(
      brightness: brightness,
      primary: primarySwatch,
      onPrimary: primaryIsDark ? Colors.white : Colors.black,
      primaryContainer:
          primaryColorDark ?? (isDark ? Colors.black : primarySwatch[700]!),
      secondary: secondary,
      onSecondary: secondaryIsDark ? Colors.white : Colors.black,
      secondaryContainer: isDark
          ? Colors.tealAccent[700]!
          : primarySwatch[700]!,
      surface: cardColor ?? (isDark ? Colors.grey[800]! : Colors.white),
      onSurface: isDark ? Colors.white : Colors.black,
      error: errorColor ?? Colors.red[700]!,
      onError: isDark ? Colors.black : Colors.white,
      // ignore: deprecated_member_use_from_same_package
      background:
          backgroundColor ?? (isDark ? Colors.grey[700]! : primarySwatch[200]!),
      // ignore: deprecated_member_use_from_same_package
      onBackground: primaryIsDark ? Colors.white : Colors.black,
    );
  }

  const ColorScheme.light({
    Color primary = const Color(0xff6750a4),
    Color onPrimary = const Color(0xffffffff),
    Color secondary = const Color(0xff625b71),
    Color onSecondary = const Color(0xffffffff),
    Color error = const Color(0xffb3261e),
    Color onError = const Color(0xffffffff),
    Color surface = const Color(0xfffffbfe),
    Color onSurface = const Color(0xff1c1b1f),
  }) : this(
         primary: primary,
         onPrimary: onPrimary,
         secondary: secondary,
         onSecondary: onSecondary,
         error: error,
         onError: onError,
         surface: surface,
         onSurface: onSurface,
       );

  const ColorScheme.dark({
    Color primary = const Color(0xffd0bcff),
    Color onPrimary = const Color(0xff381e72),
    Color secondary = const Color(0xffccc2dc),
    Color onSecondary = const Color(0xff332d41),
    Color error = const Color(0xfff2b8b5),
    Color onError = const Color(0xff601410),
    Color surface = const Color(0xff141218),
    Color onSurface = const Color(0xffe6e0e9),
  }) : this(
         brightness: Brightness.dark,
         primary: primary,
         onPrimary: onPrimary,
         primaryContainer: const Color(0xff4f378b),
         onPrimaryContainer: const Color(0xffeaddff),
         secondary: secondary,
         onSecondary: onSecondary,
         secondaryContainer: const Color(0xff4a4458),
         onSecondaryContainer: const Color(0xffe8def8),
         tertiary: const Color(0xffefb8c8),
         onTertiary: const Color(0xff492532),
         tertiaryContainer: const Color(0xff633b48),
         onTertiaryContainer: const Color(0xffffd8e4),
         error: error,
         onError: onError,
         errorContainer: const Color(0xff8c1d18),
         onErrorContainer: const Color(0xfff9dedc),
         surface: surface,
         onSurface: onSurface,
         surfaceDim: const Color(0xff141218),
         surfaceBright: const Color(0xff3b383e),
         surfaceContainerLowest: const Color(0xff0f0d13),
         surfaceContainerLow: const Color(0xff1d1b20),
         surfaceContainer: const Color(0xff211f26),
         surfaceContainerHigh: const Color(0xff2b2930),
         surfaceContainerHighest: const Color(0xff36343b),
         onSurfaceVariant: const Color(0xffcac4d0),
         outline: const Color(0xff938f99),
         outlineVariant: const Color(0xff49454f),
         inverseSurface: const Color(0xffe6e0e9),
         onInverseSurface: const Color(0xff322f35),
         inversePrimary: const Color(0xff6750a4),
       );

  final Brightness brightness;
  final Color primary, onPrimary, primaryContainer, onPrimaryContainer;
  final Color secondary, onSecondary, secondaryContainer, onSecondaryContainer;
  final Color tertiary, onTertiary, tertiaryContainer, onTertiaryContainer;
  final Color error, onError, errorContainer, onErrorContainer;
  final Color surface, onSurface, surfaceDim, surfaceBright;
  final Color surfaceContainerLowest, surfaceContainerLow, surfaceContainer;
  final Color surfaceContainerHigh, surfaceContainerHighest;
  final Color onSurfaceVariant, outline, outlineVariant, shadow, scrim;
  final Color inverseSurface, onInverseSurface, inversePrimary;
  final Color primaryFixed, primaryFixedDim, onPrimaryFixed;
  final Color onPrimaryFixedVariant, secondaryFixed, secondaryFixedDim;
  final Color onSecondaryFixed, onSecondaryFixedVariant, tertiaryFixed;
  final Color tertiaryFixedDim, onTertiaryFixed, onTertiaryFixedVariant;
  final Color? _surfaceTint, _background, _onBackground, _surfaceVariant;
  Color get surfaceTint => _surfaceTint ?? primary;
  @Deprecated('Use surface instead.')
  Color get background => _background ?? surface;
  @Deprecated('Use onSurface instead.')
  Color get onBackground => _onBackground ?? onSurface;
  @Deprecated('Use surfaceContainerHighest instead.')
  Color get surfaceVariant => _surfaceVariant ?? surfaceContainerHighest;

  ColorScheme copyWith({
    Brightness? brightness,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? surface,
    Color? onSurface,
    Color? surfaceDim,
    Color? surfaceBright,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? shadow,
    Color? scrim,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? onPrimaryFixed,
    Color? onPrimaryFixedVariant,
    Color? secondaryFixed,
    Color? secondaryFixedDim,
    Color? onSecondaryFixed,
    Color? onSecondaryFixedVariant,
    Color? tertiaryFixed,
    Color? tertiaryFixedDim,
    Color? onTertiaryFixed,
    Color? onTertiaryFixedVariant,
    Color? surfaceTint,
    @Deprecated('Use surface instead.') Color? background,
    @Deprecated('Use onSurface instead.') Color? onBackground,
    @Deprecated('Use surfaceContainerHighest instead.') Color? surfaceVariant,
  }) => ColorScheme(
    brightness: brightness ?? this.brightness,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
    secondary: secondary ?? this.secondary,
    onSecondary: onSecondary ?? this.onSecondary,
    secondaryContainer: secondaryContainer ?? this.secondaryContainer,
    onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
    tertiary: tertiary ?? this.tertiary,
    onTertiary: onTertiary ?? this.onTertiary,
    tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    errorContainer: errorContainer ?? this.errorContainer,
    onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    surface: surface ?? this.surface,
    onSurface: onSurface ?? this.onSurface,
    surfaceDim: surfaceDim ?? this.surfaceDim,
    surfaceBright: surfaceBright ?? this.surfaceBright,
    surfaceContainerLowest:
        surfaceContainerLowest ?? this.surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
    surfaceContainer: surfaceContainer ?? this.surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
    surfaceContainerHighest:
        surfaceContainerHighest ?? this.surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
    outline: outline ?? this.outline,
    outlineVariant: outlineVariant ?? this.outlineVariant,
    shadow: shadow ?? this.shadow,
    scrim: scrim ?? this.scrim,
    inverseSurface: inverseSurface ?? this.inverseSurface,
    onInverseSurface: onInverseSurface ?? this.onInverseSurface,
    inversePrimary: inversePrimary ?? this.inversePrimary,
    primaryFixed: primaryFixed ?? this.primaryFixed,
    primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant ?? this.onPrimaryFixedVariant,
    secondaryFixed: secondaryFixed ?? this.secondaryFixed,
    secondaryFixedDim: secondaryFixedDim ?? this.secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
    onSecondaryFixedVariant:
        onSecondaryFixedVariant ?? this.onSecondaryFixedVariant,
    tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed ?? this.onTertiaryFixed,
    onTertiaryFixedVariant:
        onTertiaryFixedVariant ?? this.onTertiaryFixedVariant,
    surfaceTint: surfaceTint ?? _surfaceTint,
    background: background ?? _background,
    onBackground: onBackground ?? _onBackground,
    surfaceVariant: surfaceVariant ?? _surfaceVariant,
  );

  static ColorScheme lerp(ColorScheme a, ColorScheme b, double t) =>
      t < 0.5 ? a : b;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorScheme &&
          other.brightness == brightness &&
          other.primary == primary &&
          other.onPrimary == onPrimary &&
          other.primaryContainer == primaryContainer &&
          other.onPrimaryContainer == onPrimaryContainer &&
          other.secondary == secondary &&
          other.onSecondary == onSecondary &&
          other.secondaryContainer == secondaryContainer &&
          other.onSecondaryContainer == onSecondaryContainer &&
          other.tertiary == tertiary &&
          other.onTertiary == onTertiary &&
          other.tertiaryContainer == tertiaryContainer &&
          other.onTertiaryContainer == onTertiaryContainer &&
          other.error == error &&
          other.onError == onError &&
          other.errorContainer == errorContainer &&
          other.onErrorContainer == onErrorContainer &&
          other.surface == surface &&
          other.onSurface == onSurface &&
          other.surfaceDim == surfaceDim &&
          other.surfaceBright == surfaceBright &&
          other.surfaceContainerLowest == surfaceContainerLowest &&
          other.surfaceContainerLow == surfaceContainerLow &&
          other.surfaceContainer == surfaceContainer &&
          other.surfaceContainerHigh == surfaceContainerHigh &&
          other.surfaceContainerHighest == surfaceContainerHighest &&
          other.onSurfaceVariant == onSurfaceVariant &&
          other.outline == outline &&
          other.outlineVariant == outlineVariant &&
          other.shadow == shadow &&
          other.scrim == scrim &&
          other.inverseSurface == inverseSurface &&
          other.onInverseSurface == onInverseSurface &&
          other.inversePrimary == inversePrimary &&
          other.surfaceTint == surfaceTint;

  @override
  int get hashCode => Object.hash(
    brightness,
    primary,
    secondary,
    tertiary,
    error,
    surface,
    onSurface,
    surfaceContainerHighest,
    outline,
    surfaceTint,
  );
}

bool _isDarkColor(Color color) {
  final luminance = color.computeLuminance();
  return (luminance + 0.05) * (luminance + 0.05) <= 0.15;
}

class IconThemeData {
  const IconThemeData({
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.opacity,
    this.shadows,
    this.applyTextScaling,
  });
  const IconThemeData.fallback()
    : size = 24,
      fill = 0,
      weight = 400,
      grade = 0,
      opticalSize = 48,
      color = const Color(0xff000000),
      opacity = 1,
      shadows = null,
      applyTextScaling = false;
  final Color? color;
  final double? size, fill, weight, grade, opticalSize;
  final double? opacity;
  final List<Shadow>? shadows;
  final bool? applyTextScaling;
  bool get isConcrete =>
      size != null &&
      fill != null &&
      weight != null &&
      grade != null &&
      opticalSize != null &&
      color != null &&
      opacity != null &&
      applyTextScaling != null;
  IconThemeData copyWith({
    double? size,
    double? fill,
    double? weight,
    double? grade,
    double? opticalSize,
    Color? color,
    double? opacity,
    List<Shadow>? shadows,
    bool? applyTextScaling,
  }) => IconThemeData(
    size: size ?? this.size,
    fill: fill ?? this.fill,
    weight: weight ?? this.weight,
    grade: grade ?? this.grade,
    opticalSize: opticalSize ?? this.opticalSize,
    color: color ?? this.color,
    opacity: opacity ?? this.opacity,
    shadows: shadows ?? this.shadows,
    applyTextScaling: applyTextScaling ?? this.applyTextScaling,
  );
  IconThemeData merge(IconThemeData? other) => other == null
      ? this
      : copyWith(
          size: other.size,
          fill: other.fill,
          weight: other.weight,
          grade: other.grade,
          opticalSize: other.opticalSize,
          color: other.color,
          opacity: other.opacity,
          shadows: other.shadows,
          applyTextScaling: other.applyTextScaling,
        );
  static IconThemeData lerp(IconThemeData? a, IconThemeData? b, double t) =>
      (t < 0.5 ? a : b) ?? const IconThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconThemeData &&
          other.size == size &&
          other.fill == fill &&
          other.weight == weight &&
          other.grade == grade &&
          other.opticalSize == opticalSize &&
          other.color == color &&
          other.opacity == opacity &&
          other.shadows == shadows &&
          other.applyTextScaling == applyTextScaling;
  @override
  int get hashCode => Object.hash(
    size,
    fill,
    weight,
    grade,
    opticalSize,
    color,
    opacity,
    shadows,
    applyTextScaling,
  );
}

abstract class EdgeInsetsGeometry {
  static EdgeInsetsGeometry? lerp(
    EdgeInsetsGeometry? a,
    EdgeInsetsGeometry? b,
    double t,
  ) => lerpEdgeInsets(a, b, t);
  const EdgeInsetsGeometry();
  EdgeInsets resolve(TextDirection? direction);
}

class EdgeInsets extends EdgeInsetsGeometry {
  static EdgeInsets? lerp(EdgeInsets? a, EdgeInsets? b, double t) =>
      _lerpInsets(a, b, t);
  const EdgeInsets.all(double value)
    : left = value,
      top = value,
      right = value,
      bottom = value;
  const EdgeInsets.symmetric({double horizontal = 0, double vertical = 0})
    : left = horizontal,
      right = horizontal,
      top = vertical,
      bottom = vertical;
  const EdgeInsets.only({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);
  static const zero = EdgeInsets.all(0);
  final double left, top, right, bottom;
  double get horizontal => left + right;
  double get vertical => top + bottom;
  @override
  EdgeInsets resolve(TextDirection? direction) => this;
  EdgeInsets operator +(EdgeInsets other) => EdgeInsets.fromLTRB(
    left + other.left,
    top + other.top,
    right + other.right,
    bottom + other.bottom,
  );
  EdgeInsets copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => EdgeInsets.fromLTRB(
    left ?? this.left,
    top ?? this.top,
    right ?? this.right,
    bottom ?? this.bottom,
  );
  @override
  bool operator ==(Object other) =>
      other is EdgeInsets &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;
  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

/// Left-to-right documents only: start maps to left and end to right.
class EdgeInsetsDirectional extends EdgeInsetsGeometry {
  const EdgeInsetsDirectional.only({
    this.start = 0,
    this.top = 0,
    this.end = 0,
    this.bottom = 0,
  });
  const EdgeInsetsDirectional.all(double value)
    : start = value,
      top = value,
      end = value,
      bottom = value;
  const EdgeInsetsDirectional.symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) : start = horizontal,
       end = horizontal,
       top = vertical,
       bottom = vertical;
  const EdgeInsetsDirectional.fromSTEB(
    this.start,
    this.top,
    this.end,
    this.bottom,
  );
  final double start, top, end, bottom;
  @override
  EdgeInsets resolve(TextDirection? direction) => direction == TextDirection.rtl
      ? EdgeInsets.fromLTRB(end, top, start, bottom)
      : EdgeInsets.fromLTRB(start, top, end, bottom);
}

class Radius {
  static Radius? lerp(Radius? a, Radius? b, double t) {
    if (a == null && b == null) return null;
    return _lerpRadius(a ?? Radius.zero, b ?? Radius.zero, t);
  }

  const Radius.circular(double radius) : x = radius, y = radius;
  const Radius.elliptical(this.x, this.y);
  static const zero = Radius.circular(0);
  final double x, y;
}

abstract class BorderRadiusGeometry {
  static BorderRadiusGeometry? lerp(
    BorderRadiusGeometry? a,
    BorderRadiusGeometry? b,
    double t,
  ) => lerpBorderRadius(a, b, t);
  const BorderRadiusGeometry();
  BorderRadius resolve(TextDirection? direction);
}

class BorderRadius extends BorderRadiusGeometry {
  static BorderRadius? lerp(BorderRadius? a, BorderRadius? b, double t) =>
      lerpBorderRadius(a, b, t) as BorderRadius?;
  const BorderRadius.all(Radius radius)
    : topLeft = radius,
      topRight = radius,
      bottomLeft = radius,
      bottomRight = radius;
  BorderRadius.circular(double radius) : this.all(Radius.circular(radius));
  const BorderRadius.only({
    this.topLeft = Radius.zero,
    this.topRight = Radius.zero,
    this.bottomLeft = Radius.zero,
    this.bottomRight = Radius.zero,
  });
  const BorderRadius.vertical({
    Radius top = Radius.zero,
    Radius bottom = Radius.zero,
  }) : topLeft = top,
       topRight = top,
       bottomLeft = bottom,
       bottomRight = bottom;
  const BorderRadius.horizontal({
    Radius left = Radius.zero,
    Radius right = Radius.zero,
  }) : topLeft = left,
       bottomLeft = left,
       topRight = right,
       bottomRight = right;
  static const zero = BorderRadius.all(Radius.zero);
  final Radius topLeft, topRight, bottomLeft, bottomRight;
  @override
  BorderRadius resolve(TextDirection? direction) => this;
  RRect toRRect(Rect rect) => RRect.fromRectAndCorners(
    rect,
    topLeft: topLeft,
    topRight: topRight,
    bottomRight: bottomRight,
    bottomLeft: bottomLeft,
  );
}

/// Left-to-right documents only.
class BorderRadiusDirectional extends BorderRadiusGeometry {
  const BorderRadiusDirectional.only({
    this.topStart = Radius.zero,
    this.topEnd = Radius.zero,
    this.bottomStart = Radius.zero,
    this.bottomEnd = Radius.zero,
  });
  const BorderRadiusDirectional.all(Radius radius)
    : topStart = radius,
      topEnd = radius,
      bottomStart = radius,
      bottomEnd = radius;
  BorderRadiusDirectional.circular(double radius)
    : this.all(Radius.circular(radius));
  final Radius topStart, topEnd, bottomStart, bottomEnd;
  @override
  BorderRadius resolve(TextDirection? direction) =>
      direction == TextDirection.rtl
      ? BorderRadius.only(
          topLeft: topEnd,
          topRight: topStart,
          bottomLeft: bottomEnd,
          bottomRight: bottomStart,
        )
      : BorderRadius.only(
          topLeft: topStart,
          topRight: topEnd,
          bottomLeft: bottomStart,
          bottomRight: bottomEnd,
        );
}

class BorderSide {
  static BorderSide lerp(BorderSide a, BorderSide b, double t) =>
      _lerpSide(a, b, t);
  const BorderSide({
    this.color = const Color(0xff000000),
    this.width = 1,
    this.style = BorderStyle.solid,
  });
  static const none = BorderSide(width: 0, style: BorderStyle.none);
  final Color color;
  final double width;
  final BorderStyle style;
  BorderSide copyWith({Color? color, double? width, BorderStyle? style}) =>
      BorderSide(
        color: color ?? this.color,
        width: width ?? this.width,
        style: style ?? this.style,
      );
}

abstract class BoxBorder {
  const BoxBorder();
  BorderSide get top;
  BorderSide get right;
  BorderSide get bottom;
  BorderSide get left;
}

class Border extends BoxBorder {
  const Border({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
  });
  const Border.fromBorderSide(BorderSide side)
    : top = side,
      right = side,
      bottom = side,
      left = side;
  const Border.symmetric({
    BorderSide vertical = BorderSide.none,
    BorderSide horizontal = BorderSide.none,
  }) : left = vertical,
       right = vertical,
       top = horizontal,
       bottom = horizontal;
  Border.all({
    Color color = const Color(0xff000000),
    double width = 1,
    BorderStyle style = BorderStyle.solid,
  }) : this.fromBorderSide(
         BorderSide(color: color, width: width, style: style),
       );
  @override
  final BorderSide top, right, bottom, left;
  // Uniform-border accessors retained for earlier metadata fixtures.
  Color get color => top.color;
  double get width => top.width;
}

abstract class ShapeBorder {
  const ShapeBorder();
}

abstract class OutlinedBorder extends ShapeBorder {
  const OutlinedBorder({this.side = BorderSide.none});
  final BorderSide side;
  OutlinedBorder copyWith({BorderSide? side});
}

class RoundedRectangleBorder extends OutlinedBorder {
  const RoundedRectangleBorder({
    this.borderRadius = BorderRadius.zero,
    super.side,
  });
  final BorderRadiusGeometry borderRadius;
  @override
  RoundedRectangleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => RoundedRectangleBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );
}

/// Corners cut diagonally; approximated with rounded corners of the same
/// size (CSS borders cannot bevel).
class BeveledRectangleBorder extends RoundedRectangleBorder {
  const BeveledRectangleBorder({super.borderRadius, super.side});
}

/// An ellipse inscribed in the box.
class OvalBorder extends OutlinedBorder {
  const OvalBorder({super.side, this.eccentricity = 1});
  final double eccentricity;
  @override
  OvalBorder copyWith({BorderSide? side, double? eccentricity}) => OvalBorder(
    side: side ?? this.side,
    eccentricity: eccentricity ?? this.eccentricity,
  );
}

/// Drawn as its bounding circle; star points are not cut.
class StarBorder extends OutlinedBorder {
  const StarBorder({
    super.side,
    this.points = 5,
    this.innerRadiusRatio = 0.4,
    this.pointRounding = 0,
    this.valleyRounding = 0,
    this.rotation = 0,
    this.squash = 0,
  });
  const StarBorder.polygon({
    super.side,
    double sides = 5,
    this.pointRounding = 0,
    this.rotation = 0,
    this.squash = 0,
  }) : points = sides,
       innerRadiusRatio = null,
       valleyRounding = 0;
  final double points, pointRounding, valleyRounding, rotation, squash;
  final double? innerRadiusRatio;
  @override
  StarBorder copyWith({BorderSide? side}) => StarBorder(
    side: side ?? this.side,
    points: points,
    innerRadiusRatio: innerRadiusRatio ?? 0.4,
    pointRounding: pointRounding,
    valleyRounding: valleyRounding,
    rotation: rotation,
    squash: squash,
  );
}

/// Borders on chosen edges of the box.
class LinearBorder extends OutlinedBorder {
  const LinearBorder({super.side, this.start, this.end, this.top, this.bottom});
  final LinearBorderEdge? start, end, top, bottom;
  static const none = LinearBorder();
  @override
  LinearBorder copyWith({
    BorderSide? side,
    LinearBorderEdge? start,
    LinearBorderEdge? end,
    LinearBorderEdge? top,
    LinearBorderEdge? bottom,
  }) => LinearBorder(
    side: side ?? this.side,
    start: start ?? this.start,
    end: end ?? this.end,
    top: top ?? this.top,
    bottom: bottom ?? this.bottom,
  );
  LinearBorder.start({super.side, double alignment = 0, double size = 1})
    : start = LinearBorderEdge(alignment: alignment, size: size),
      end = null,
      top = null,
      bottom = null;
  LinearBorder.end({super.side, double alignment = 0, double size = 1})
    : end = LinearBorderEdge(alignment: alignment, size: size),
      start = null,
      top = null,
      bottom = null;
  LinearBorder.top({super.side, double alignment = 0, double size = 1})
    : top = LinearBorderEdge(alignment: alignment, size: size),
      start = null,
      end = null,
      bottom = null;
  LinearBorder.bottom({super.side, double alignment = 0, double size = 1})
    : bottom = LinearBorderEdge(alignment: alignment, size: size),
      start = null,
      end = null,
      top = null;
}

class LinearBorderEdge {
  const LinearBorderEdge({this.size = 1, this.alignment = 0});
  final double size, alignment;
}

/// Approximated as a rounded rectangle; CSS has no superellipse corners.
class ContinuousRectangleBorder extends RoundedRectangleBorder {
  const ContinuousRectangleBorder({super.borderRadius, super.side});
  @override
  ContinuousRectangleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => ContinuousRectangleBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );
}

class StadiumBorder extends OutlinedBorder {
  const StadiumBorder({super.side});
  @override
  StadiumBorder copyWith({BorderSide? side}) =>
      StadiumBorder(side: side ?? this.side);
}

class CircleBorder extends OutlinedBorder {
  const CircleBorder({super.side, this.eccentricity = 0.0});
  final double eccentricity;
  @override
  CircleBorder copyWith({BorderSide? side, double? eccentricity}) =>
      CircleBorder(
        side: side ?? this.side,
        eccentricity: eccentricity ?? this.eccentricity,
      );
}

class Shadow {
  const Shadow({
    this.color = const Color(0xff000000),
    this.offset = Offset.zero,
    this.blurRadius = 0,
  });
  final Color color;
  final Offset offset;
  final double blurRadius;
}

class BoxShadow {
  static List<BoxShadow>? lerpList(
    List<BoxShadow>? a,
    List<BoxShadow>? b,
    double t,
  ) => _lerpShadows(a, b, t);
  const BoxShadow({
    this.color = const Color(0xff000000),
    this.offset = Offset.zero,
    this.blurRadius = 0,
    this.spreadRadius = 0,
    this.blurStyle = BlurStyle.normal,
  });
  final Color color;
  final Offset offset;
  final double blurRadius, spreadRadius;
  final BlurStyle blurStyle;
  BoxShadow scale(double factor) => BoxShadow(
    color: color,
    offset: offset * factor,
    blurRadius: blurRadius * factor,
    spreadRadius: spreadRadius * factor,
    blurStyle: blurStyle,
  );
  BoxShadow copyWith({
    Color? color,
    Offset? offset,
    double? blurRadius,
    double? spreadRadius,
    BlurStyle? blurStyle,
  }) => BoxShadow(
    color: color ?? this.color,
    offset: offset ?? this.offset,
    blurRadius: blurRadius ?? this.blurRadius,
    spreadRadius: spreadRadius ?? this.spreadRadius,
    blurStyle: blurStyle ?? this.blurStyle,
  );
  double get blurSigma => blurRadius * 0.57735 + 0.5;
}

abstract class AlignmentGeometry {
  static AlignmentGeometry? lerp(
    AlignmentGeometry? a,
    AlignmentGeometry? b,
    double t,
  ) => lerpAlignment(a, b, t);
  const AlignmentGeometry();
  Alignment resolve(TextDirection? direction);
}

class Alignment extends AlignmentGeometry {
  static Alignment? lerp(Alignment? a, Alignment? b, double t) =>
      lerpAlignment(a, b, t) as Alignment?;
  const Alignment(this.x, this.y);
  final double x, y;
  static const topLeft = Alignment(-1, -1);
  static const topCenter = Alignment(0, -1);
  static const topRight = Alignment(1, -1);
  static const centerLeft = Alignment(-1, 0);
  static const center = Alignment(0, 0);
  static const centerRight = Alignment(1, 0);
  static const bottomLeft = Alignment(-1, 1);
  static const bottomCenter = Alignment(0, 1);
  static const bottomRight = Alignment(1, 1);
  @override
  Alignment resolve(TextDirection? direction) => this;
  @override
  bool operator ==(Object other) =>
      other is Alignment && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

/// Left-to-right documents only: start maps to left.
class AlignmentDirectional extends AlignmentGeometry {
  const AlignmentDirectional(this.start, this.y);
  final double start, y;
  static const topStart = AlignmentDirectional(-1, -1);
  static const topCenter = AlignmentDirectional(0, -1);
  static const topEnd = AlignmentDirectional(1, -1);
  static const centerStart = AlignmentDirectional(-1, 0);
  static const center = AlignmentDirectional(0, 0);
  static const centerEnd = AlignmentDirectional(1, 0);
  static const bottomStart = AlignmentDirectional(-1, 1);
  static const bottomCenter = AlignmentDirectional(0, 1);
  static const bottomEnd = AlignmentDirectional(1, 1);
  @override
  Alignment resolve(TextDirection? direction) =>
      Alignment(direction == TextDirection.rtl ? -start : start, y);
}

abstract class Gradient {
  const Gradient({required this.colors, this.stops, this.transform});
  final List<Color> colors;
  final List<double>? stops;
  final GradientTransform? transform;
  Shader createShader(Rect rect, {TextDirection? textDirection});
}

abstract class GradientTransform {
  const GradientTransform();
}

/// Rotates a gradient by [radians] about its box's center.
class GradientRotation extends GradientTransform {
  const GradientRotation(this.radians);
  final double radians;
}

/// A conic gradient around [center], from [startAngle] to [endAngle].
class SweepGradient extends Gradient {
  const SweepGradient({
    this.center = Alignment.center,
    this.startAngle = 0,
    this.endAngle = math.pi * 2,
    required super.colors,
    super.stops,
    this.tileMode = TileMode.clamp,
    super.transform,
  });
  final AlignmentGeometry center;
  final double startAngle, endAngle;
  final TileMode tileMode;
  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final c = center.resolve(textDirection);
    return Shader.radial(
      Offset(
        rect.center.dx + c.x * rect.width / 2,
        rect.center.dy + c.y * rect.height / 2,
      ),
      rect.shortestSide / 2,
      colors,
      stops,
    );
  }
}

class LinearGradient extends Gradient {
  const LinearGradient({
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    required super.colors,
    super.stops,
    this.tileMode = TileMode.clamp,
    super.transform,
  });
  final AlignmentGeometry begin, end;
  final TileMode tileMode;
  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    Offset point(AlignmentGeometry a) {
      final r = a.resolve(textDirection);
      return Offset(
        rect.center.dx + r.x * rect.width / 2,
        rect.center.dy + r.y * rect.height / 2,
      );
    }

    return Shader.linear(point(begin), point(end), colors, stops);
  }
}

class RadialGradient extends Gradient {
  const RadialGradient({
    this.center = Alignment.center,
    this.radius = 0.5,
    required super.colors,
    super.stops,
    this.tileMode = TileMode.clamp,
    this.focal,
    this.focalRadius = 0,
    super.transform,
  });
  final AlignmentGeometry center;
  final double radius;
  final TileMode tileMode;
  final AlignmentGeometry? focal;
  final double focalRadius;
  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final c = center.resolve(textDirection);
    return Shader.radial(
      Offset(
        rect.center.dx + c.x * rect.width / 2,
        rect.center.dy + c.y * rect.height / 2,
      ),
      radius * rect.shortestSide,
      colors,
      stops,
    );
  }
}

enum BoxFit { fill, contain, cover, fitWidth, fitHeight, none, scaleDown }

enum ImageRepeat { repeat, repeatX, repeatY, noRepeat }

/// Image sources resolve to URLs; bytes are fetched by the browser.
abstract class ImageProvider<T extends Object> {
  const ImageProvider();
  String get url;
}

/// Flutter web serves bundled assets at `assets/<key>`.
class AssetImage extends ImageProvider<AssetImage> {
  const AssetImage(this.assetName, {this.package});
  final String assetName;
  final String? package;
  @override
  String get url {
    if (assetName.isEmpty ||
        assetName.startsWith('/') ||
        assetName.split('/').contains('..'))
      throw ArgumentError('Invalid asset name.');
    final key = package == null ? assetName : 'packages/$package/$assetName';
    return 'assets/${Uri.encodeFull(key)}';
  }
}

/// Accepts http(s) and same-origin relative URLs only.
class NetworkImage extends ImageProvider<NetworkImage> {
  const NetworkImage(this.src, {this.scale = 1, this.headers});
  final String src;
  final double scale;
  final Map<String, String>? headers;
  @override
  String get url {
    final parsed = Uri.tryParse(src);
    if (parsed == null ||
        (parsed.hasScheme &&
            parsed.scheme != 'https' &&
            parsed.scheme != 'http'))
      throw ArgumentError('Unsupported image URL.');
    if (headers != null && headers!.isNotEmpty)
      throw UnsupportedError('Image request headers are unsupported.');
    return src;
  }
}

/// Encoded image bytes, served to the browser as a data URL.
class MemoryImage extends ImageProvider<MemoryImage> {
  const MemoryImage(this.bytes, {this.scale = 1});
  final Uint8List bytes;
  final double scale;

  static String _mime(Uint8List bytes) {
    bool starts(List<int> magic) =>
        bytes.length >= magic.length &&
        Iterable.generate(magic.length).every((i) => bytes[i] == magic[i]);
    if (starts([0x89, 0x50, 0x4e, 0x47])) return 'image/png';
    if (starts([0xff, 0xd8, 0xff])) return 'image/jpeg';
    if (starts([0x47, 0x49, 0x46])) return 'image/gif';
    if (starts([0x52, 0x49, 0x46, 0x46]) &&
        bytes.length > 11 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    if (starts([0x42, 0x4d])) return 'image/bmp';
    final head = String.fromCharCodes(bytes.take(256)).trimLeft();
    if (head.startsWith('<svg') || head.startsWith('<?xml')) {
      return 'image/svg+xml';
    }
    return 'application/octet-stream';
  }

  @override
  String get url => 'data:${_mime(bytes)};base64,${base64Encode(bytes)}';

  @override
  bool operator ==(Object other) =>
      other is MemoryImage && identical(other.bytes, bytes);
  @override
  int get hashCode => identityHashCode(bytes);
}

/// Decoding sizes are a hint for native engines; browsers decode the
/// source image, so the inner provider's URL is used as is.
class ResizeImage extends ImageProvider<ResizeImage> {
  const ResizeImage(
    this.imageProvider, {
    this.width,
    this.height,
    this.allowUpscaling = false,
  });
  final ImageProvider imageProvider;
  final int? width, height;
  final bool allowUpscaling;
  @override
  String get url => imageProvider.url;

  static ImageProvider<Object> resizeIfNeeded(
    int? cacheWidth,
    int? cacheHeight,
    ImageProvider<Object> provider,
  ) => provider;
}

class ImageChunkEvent {
  const ImageChunkEvent({
    required this.cumulativeBytesLoaded,
    required this.expectedTotalBytes,
  });
  final int cumulativeBytesLoaded;
  final int? expectedTotalBytes;
}

String cssUrl(String url) =>
    'url("${url.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '')}")';

String objectFitCss(BoxFit? fit) => switch (fit) {
  null => '',
  BoxFit.fill => 'object-fit:fill;',
  BoxFit.contain => 'object-fit:contain;',
  BoxFit.cover => 'object-fit:cover;',
  BoxFit.fitWidth => 'object-fit:cover;',
  BoxFit.fitHeight => 'object-fit:cover;',
  BoxFit.none => 'object-fit:none;',
  BoxFit.scaleDown => 'object-fit:scale-down;',
};

class DecorationImage {
  const DecorationImage({
    required this.image,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.opacity = 1,
    this.onError,
    this.colorFilter,
    this.centerSlice,
    this.matchTextDirection = false,
    this.scale = 1,
    this.filterQuality = FilterQuality.medium,
    this.invertColors = false,
    this.isAntiAlias = false,
  });
  final void Function(Object exception, StackTrace? stackTrace)? onError;
  final ColorFilter? colorFilter;
  final Rect? centerSlice;
  final bool matchTextDirection, invertColors, isAntiAlias;
  final double scale;
  final FilterQuality filterQuality;
  final ImageProvider image;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final double opacity;
}

String decorationImageCss(DecorationImage? image) {
  if (image == null) return '';
  final a = image.alignment.resolve(TextDirection.ltr);
  final size = switch (image.fit) {
    BoxFit.cover => 'cover',
    BoxFit.contain || BoxFit.scaleDown => 'contain',
    BoxFit.fill => '100% 100%',
    BoxFit.fitWidth => '100% auto',
    BoxFit.fitHeight => 'auto 100%',
    BoxFit.none || null => 'auto',
  };
  final repeat = switch (image.repeat) {
    ImageRepeat.repeat => 'repeat',
    ImageRepeat.repeatX => 'repeat-x',
    ImageRepeat.repeatY => 'repeat-y',
    ImageRepeat.noRepeat => 'no-repeat',
  };
  // Opacity below one cross-fades the image with a transparent one.
  final url = cssUrl(image.image.url);
  final source = image.opacity >= 1
      ? url
      : 'cross-fade(${cssNumber(image.opacity * 100)}% $url,linear-gradient(transparent,transparent))';
  return 'background-image:$source;background-size:$size;background-repeat:$repeat;background-position:${cssNumber((a.x + 1) * 50)}% ${cssNumber((a.y + 1) * 50)}%;';
}

abstract class Decoration {
  static Decoration? lerp(Decoration? a, Decoration? b, double t) =>
      lerpDecoration(a, b, t);
  const Decoration();
}

class BoxDecoration extends Decoration {
  static BoxDecoration? lerp(BoxDecoration? a, BoxDecoration? b, double t) =>
      lerpDecoration(a, b, t) as BoxDecoration?;
  const BoxDecoration({
    this.color,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.image,
    this.shape = BoxShape.rectangle,
    this.backgroundBlendMode,
  });
  final BlendMode? backgroundBlendMode;
  final DecorationImage? image;
  final Color? color;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final BoxShape shape;
  BoxDecoration copyWith({
    Color? color,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    DecorationImage? image,
    BoxShape? shape,
  }) => BoxDecoration(
    image: image ?? this.image,
    color: color ?? this.color,
    border: border ?? this.border,
    borderRadius: borderRadius ?? this.borderRadius,
    boxShadow: boxShadow ?? this.boxShadow,
    gradient: gradient ?? this.gradient,
    shape: shape ?? this.shape,
  );
}

class ShapeDecoration extends Decoration {
  const ShapeDecoration({
    this.color,
    required this.shape,
    this.shadows,
    this.gradient,
  });
  final Color? color;
  final ShapeBorder shape;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
}

// ---------------------------------------------------------------------------
// CSS serialization. Every numeric value passes a finite/nonnegative check.

String colorCss(Color color) =>
    'rgba(${color.red},${color.green},${color.blue},${cssNumber(color.alpha / 255)})';

String cssNumber(num value) {
  final rounded = (value * 1000).round() / 1000;
  return rounded == rounded.roundToDouble() ? '${rounded.round()}' : '$rounded';
}

/// Formats a checked CSS pixel length without a trailing `.0`.
String px(double value) => '${cssNumber(checkedDimension(value))}px';

double checkedDimension(double value) {
  if (!value.isFinite || value < 0)
    throw ArgumentError('CSS dimensions must be finite and nonnegative.');
  return value;
}

final _unsafeFamily = RegExp('["\'\\\\<>;{}]');

String fontFamilyCss(TextStyle style) {
  final families = [
    if (style.fontFamily != null) style.fontFamily!,
    ...?style.fontFamilyFallback,
  ];
  if (families.isEmpty) return '';
  for (final family in families) {
    if (_unsafeFamily.hasMatch(family))
      throw ArgumentError('Unsupported font family name.');
  }
  return 'font-family:${families.map((f) => '"$f"').join(',')},system-ui,sans-serif;';
}

String textStyleCss(TextStyle? style) {
  if (style == null) return '';
  final out = StringBuffer();
  if (style.color != null) out.write('color:${colorCss(style.color!)};');
  if (style.backgroundColor != null)
    out.write('background-color:${colorCss(style.backgroundColor!)};');
  if (style.fontSize != null) out.write('font-size:${px(style.fontSize!)};');
  if (style.fontWeight != null)
    out.write('font-weight:${style.fontWeight!.value};');
  if (style.fontStyle != null)
    out.write('font-style:${style.fontStyle!.name};');
  if (style.letterSpacing != null) {
    final value = style.letterSpacing!;
    if (!value.isFinite) throw ArgumentError('Invalid letter spacing.');
    out.write('letter-spacing:${cssNumber(value)}px;');
  }
  if (style.wordSpacing != null) {
    final value = style.wordSpacing!;
    if (!value.isFinite) throw ArgumentError('Invalid word spacing.');
    out.write('word-spacing:${cssNumber(value)}px;');
  }
  if (style.height != null)
    out.write('line-height:${cssNumber(checkedDimension(style.height!))};');
  final decoration = style.decoration;
  if (decoration != null) {
    final lines = [
      if (decoration.contains(TextDecoration.underline)) 'underline',
      if (decoration.contains(TextDecoration.overline)) 'overline',
      if (decoration.contains(TextDecoration.lineThrough)) 'line-through',
    ];
    out.write('text-decoration:${lines.isEmpty ? 'none' : lines.join(' ')};');
    if (style.decorationColor != null)
      out.write('text-decoration-color:${colorCss(style.decorationColor!)};');
    if (style.decorationStyle != null)
      out.write('text-decoration-style:${style.decorationStyle!.name};');
    if (style.decorationThickness != null)
      out.write(
        'text-decoration-thickness:${cssNumber(style.decorationThickness!)}px;',
      );
  }
  final shadows = style.shadows;
  if (shadows != null) {
    out.write(
      shadows.isEmpty
          ? 'text-shadow:none;'
          : 'text-shadow:${shadows.map((s) => '${cssNumber(s.offset.dx)}px ${cssNumber(s.offset.dy)}px ${cssNumber(s.blurRadius)}px ${colorCss(s.color)}').join(',')};',
    );
  }
  final variations = style.fontVariations;
  if (variations != null && variations.isNotEmpty) {
    out.write(
      'font-variation-settings:${variations.where((v) => RegExp(r'^[a-zA-Z0-9]{4}$').hasMatch(v.axis)).map((v) => '"${v.axis}" ${cssNumber(v.value)}').join(',')};',
    );
  }
  if (style.foreground?.color case final paint? when style.color == null) {
    out.write('color:${colorCss(paint)};');
  }
  out.write(fontFamilyCss(style));
  final features = style.fontFeatures;
  if (features != null && features.isNotEmpty) {
    for (final feature in features) {
      if (!RegExp(r'^[a-zA-Z0-9]{4}$').hasMatch(feature.feature))
        throw ArgumentError('Invalid OpenType feature tag.');
    }
    out.write(
      'font-feature-settings:${features.map((f) => '"${f.feature}" ${f.value}').join(',')};',
    );
  }
  return out.toString();
}

String borderRadiusCss(BorderRadiusGeometry? radius) {
  if (radius == null) return '';
  final r = radius.resolve(TextDirection.ltr);
  String corner(Radius c) => c.x == c.y ? px(c.x) : '${px(c.x)} ${px(c.y)}';
  final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
  if (corners.every((c) => c.x == 0 && c.y == 0)) return '';
  if (corners.every((c) => c.x == c.y && c.x == corners.first.x))
    return 'border-radius:${px(corners.first.x)};';
  return 'border-top-left-radius:${corner(r.topLeft)};border-top-right-radius:${corner(r.topRight)};border-bottom-right-radius:${corner(r.bottomRight)};border-bottom-left-radius:${corner(r.bottomLeft)};';
}

String _side(BorderSide side) =>
    side.style == BorderStyle.none || side.width == 0
    ? ''
    : '${px(side.width)} solid ${colorCss(side.color)}';

String borderSideCss(String property, BorderSide side) {
  final value = _side(side);
  return value.isEmpty ? '' : '$property:$value;';
}

String boxBorderCss(BoxBorder? border) {
  if (border == null) return '';
  final sides = [border.top, border.right, border.bottom, border.left];
  final first = sides.first;
  if (sides.every(
    (s) =>
        s.width == first.width &&
        s.color == first.color &&
        s.style == first.style,
  )) {
    return borderSideCss('border', first);
  }
  return borderSideCss('border-top', border.top) +
      borderSideCss('border-right', border.right) +
      borderSideCss('border-bottom', border.bottom) +
      borderSideCss('border-left', border.left);
}

String boxShadowCss(List<BoxShadow>? shadows) {
  if (shadows == null || shadows.isEmpty) return '';
  String one(BoxShadow s) {
    if (!s.offset.dx.isFinite || !s.offset.dy.isFinite)
      throw ArgumentError('Invalid shadow offset.');
    if (!s.spreadRadius.isFinite) throw ArgumentError('Invalid shadow spread.');
    // Inner blur draws inside the box, as CSS inset shadows do.
    return '${s.blurStyle == BlurStyle.inner ? 'inset ' : ''}${cssNumber(s.offset.dx)}px ${cssNumber(s.offset.dy)}px ${px(s.blurRadius)} ${cssNumber(s.spreadRadius)}px ${colorCss(s.color)}';
  }

  return 'box-shadow:${shadows.map(one).join(',')};';
}

String gradientCss(Gradient? gradient) {
  if (gradient == null) return '';
  final stops = gradient.stops;
  if (gradient.colors.length < 2)
    throw ArgumentError('Gradients require at least two colors.');
  if (stops != null && stops.length != gradient.colors.length)
    throw ArgumentError('Gradient stops must match colors.');
  final colors = [
    for (var i = 0; i < gradient.colors.length; i++)
      stops == null
          ? colorCss(gradient.colors[i])
          : '${colorCss(gradient.colors[i])} ${cssNumber(checkedDimension(stops[i]) * 100)}%',
  ].join(',');
  final transform = gradient.transform;
  final rotation = transform is GradientRotation
      ? transform.radians * 180 / math.pi
      : 0.0;
  if (gradient is LinearGradient) {
    final begin = gradient.begin.resolve(TextDirection.ltr);
    final end = gradient.end.resolve(TextDirection.ltr);
    final degrees =
        math.atan2(end.x - begin.x, -(end.y - begin.y)) * 180 / math.pi +
        rotation;
    final kind = gradient.tileMode == TileMode.repeated
        ? 'repeating-linear-gradient'
        : 'linear-gradient';
    return 'background-image:$kind(${cssNumber(degrees)}deg,$colors);';
  }
  if (gradient is RadialGradient) {
    final center = gradient.center.resolve(TextDirection.ltr);
    final kind = gradient.tileMode == TileMode.repeated
        ? 'repeating-radial-gradient'
        : 'radial-gradient';
    return 'background-image:$kind(circle at ${cssNumber((center.x + 1) * 50)}% ${cssNumber((center.y + 1) * 50)}%,$colors);';
  }
  if (gradient is SweepGradient) {
    final center = gradient.center.resolve(TextDirection.ltr);
    final from = gradient.startAngle * 180 / math.pi + 90 + rotation;
    final span = (gradient.endAngle - gradient.startAngle) / (2 * math.pi);
    // Stops map onto the swept span of the full turn.
    final swept = [
      for (var i = 0; i < gradient.colors.length; i++)
        '${colorCss(gradient.colors[i])} ${cssNumber((gradient.stops?[i] ?? i / (gradient.colors.length - 1)) * span * 100)}%',
    ].join(',');
    return 'background-image:conic-gradient(from ${cssNumber(from)}deg at ${cssNumber((center.x + 1) * 50)}% ${cssNumber((center.y + 1) * 50)}%,$swept);';
  }
  return '';
}

String shapeCss(ShapeBorder? shape) {
  if (shape == null) return '';
  final side = shape is OutlinedBorder ? shape.side : BorderSide.none;
  final border = borderSideCss('border', side);
  if (shape is StadiumBorder) return '${border}border-radius:9999px;';
  if (shape is CircleBorder) return '${border}border-radius:50%;';
  if (shape is RoundedRectangleBorder)
    return border + borderRadiusCss(shape.borderRadius);
  if (shape is OvalBorder || shape is StarBorder) {
    return '${border}border-radius:50%;';
  }
  if (shape is LinearBorder) {
    final side = shape.side;
    return [
      if (shape.start != null) borderSideCss('border-left', side),
      if (shape.end != null) borderSideCss('border-right', side),
      if (shape.top != null) borderSideCss('border-top', side),
      if (shape.bottom != null) borderSideCss('border-bottom', side),
    ].join();
  }
  // Other shapes draw as the plain box.
  return border;
}

String _blendCss(BlendMode? mode) {
  const css = {
    BlendMode.multiply: 'multiply',
    BlendMode.screen: 'screen',
    BlendMode.overlay: 'overlay',
    BlendMode.darken: 'darken',
    BlendMode.lighten: 'lighten',
    BlendMode.colorDodge: 'color-dodge',
    BlendMode.colorBurn: 'color-burn',
    BlendMode.hardLight: 'hard-light',
    BlendMode.softLight: 'soft-light',
    BlendMode.difference: 'difference',
    BlendMode.exclusion: 'exclusion',
    BlendMode.hue: 'hue',
    BlendMode.saturation: 'saturation',
    BlendMode.color: 'color',
    BlendMode.luminosity: 'luminosity',
  };
  final value = css[mode];
  return value == null ? '' : 'background-blend-mode:$value;';
}

String decorationCss(Decoration? decoration) {
  if (decoration == null) return '';
  if (decoration is BoxDecoration) {
    return (decoration.color == null
            ? ''
            : 'background-color:${colorCss(decoration.color!)};') +
        gradientCss(decoration.gradient) +
        decorationImageCss(decoration.image) +
        boxBorderCss(decoration.border) +
        (decoration.shape == BoxShape.circle
            ? 'border-radius:50%;'
            : borderRadiusCss(decoration.borderRadius)) +
        boxShadowCss(decoration.boxShadow) +
        _blendCss(decoration.backgroundBlendMode);
  }
  if (decoration is ShapeDecoration) {
    return (decoration.color == null
            ? ''
            : 'background-color:${colorCss(decoration.color!)};') +
        gradientCss(decoration.gradient) +
        shapeCss(decoration.shape) +
        boxShadowCss(decoration.shadows);
  }
  // Custom decorations paint nothing in this runtime.
  return '';
}

String edgeInsetsCss(String property, EdgeInsetsGeometry? insets) {
  if (insets == null) return '';
  final e = insets.resolve(TextDirection.ltr);
  if (e.left == 0 && e.top == 0 && e.right == 0 && e.bottom == 0) {
    checkedDimension(0);
    return '';
  }
  return '$property:${px(e.top)} ${px(e.right)} ${px(e.bottom)} ${px(e.left)};';
}

/// Material 3 elevation as approximate key and ambient shadows.
String elevationCss(double elevation, Color shadow) {
  checkedDimension(elevation);
  if (elevation == 0) return '';
  final level = elevation <= 1
      ? 1
      : elevation <= 3
      ? 2
      : elevation <= 6
      ? 3
      : elevation <= 8
      ? 4
      : 5;
  final key = colorCss(shadow.withValues(alpha: 0.3));
  final ambient = colorCss(shadow.withValues(alpha: 0.15));
  return 'box-shadow:0 ${level}px ${level + 1}px $key,0 ${level * 2 - 1}px ${level * 3}px ${level}px $ambient;';
}

// ---------------------------------------------------------------------------
// Interpolation used by implicit animations. Shapes that cannot be blended
// (different border types, gradients) switch at the midpoint, as Flutter
// does for non-interpolable properties.

double _mix(double a, double b, double t) => a + (b - a) * t;

T? _switch<T>(T? a, T? b, double t) => t < 0.5 ? a : b;

EdgeInsets? _lerpInsets(EdgeInsets? a, EdgeInsets? b, double t) {
  {
    if (a == null && b == null) return null;
    a ??= EdgeInsets.zero;
    b ??= EdgeInsets.zero;
    return EdgeInsets.fromLTRB(
      _mix(a.left, b.left, t),
      _mix(a.top, b.top, t),
      _mix(a.right, b.right, t),
      _mix(a.bottom, b.bottom, t),
    );
  }
}

EdgeInsetsGeometry? lerpEdgeInsets(
  EdgeInsetsGeometry? a,
  EdgeInsetsGeometry? b,
  double t,
) => _lerpInsets(
  a?.resolve(TextDirection.ltr),
  b?.resolve(TextDirection.ltr),
  t,
);

Radius _lerpRadius(Radius a, Radius b, double t) =>
    Radius.elliptical(_mix(a.x, b.x, t), _mix(a.y, b.y, t));

BorderRadiusGeometry? lerpBorderRadius(
  BorderRadiusGeometry? x,
  BorderRadiusGeometry? y,
  double t,
) {
  if (x == null && y == null) return null;
  final a = x?.resolve(TextDirection.ltr) ?? BorderRadius.zero;
  final b = y?.resolve(TextDirection.ltr) ?? BorderRadius.zero;
  return BorderRadius.only(
    topLeft: _lerpRadius(a.topLeft, b.topLeft, t),
    topRight: _lerpRadius(a.topRight, b.topRight, t),
    bottomLeft: _lerpRadius(a.bottomLeft, b.bottomLeft, t),
    bottomRight: _lerpRadius(a.bottomRight, b.bottomRight, t),
  );
}

AlignmentGeometry? lerpAlignment(
  AlignmentGeometry? x,
  AlignmentGeometry? y,
  double t,
) {
  if (x == null && y == null) return null;
  final a = x?.resolve(TextDirection.ltr) ?? Alignment.center;
  final b = y?.resolve(TextDirection.ltr) ?? Alignment.center;
  return Alignment(_mix(a.x, b.x, t), _mix(a.y, b.y, t));
}

BorderSide _lerpSide(BorderSide a, BorderSide b, double t) => BorderSide(
  color: Color.lerp(a.color, b.color, t)!,
  width: _mix(a.width, b.width, t),
  style: _switch(a.style, b.style, t)!,
);

BoxBorder? _lerpBorder(BoxBorder? a, BoxBorder? b, double t) {
  if (a == null && b == null) return null;
  final none = const Border();
  final x = a ?? none, y = b ?? none;
  return Border(
    top: _lerpSide(x.top, y.top, t),
    right: _lerpSide(x.right, y.right, t),
    bottom: _lerpSide(x.bottom, y.bottom, t),
    left: _lerpSide(x.left, y.left, t),
  );
}

List<BoxShadow>? _lerpShadows(
  List<BoxShadow>? a,
  List<BoxShadow>? b,
  double t,
) {
  if (a == null && b == null) return null;
  final x = a ?? const [], y = b ?? const [];
  final length = x.length > y.length ? x.length : y.length;
  return [
    for (var i = 0; i < length; i++)
      BoxShadow(
        color: Color.lerp(
          i < x.length ? x[i].color : null,
          i < y.length ? y[i].color : null,
          t,
        )!,
        offset: Offset.lerp(
          i < x.length ? x[i].offset : Offset.zero,
          i < y.length ? y[i].offset : Offset.zero,
          t,
        )!,
        blurRadius: _mix(
          i < x.length ? x[i].blurRadius : 0,
          i < y.length ? y[i].blurRadius : 0,
          t,
        ),
        spreadRadius: _mix(
          i < x.length ? x[i].spreadRadius : 0,
          i < y.length ? y[i].spreadRadius : 0,
          t,
        ),
      ),
  ];
}

Decoration? lerpDecoration(Decoration? a, Decoration? b, double t) {
  if (a == null && b == null) return null;
  if ((a == null || a is BoxDecoration) && (b == null || b is BoxDecoration)) {
    final x = a as BoxDecoration?, y = b as BoxDecoration?;
    if (x?.shape != y?.shape && x != null && y != null) return _switch(a, b, t);
    return BoxDecoration(
      color: Color.lerp(x?.color, y?.color, t),
      border: _lerpBorder(x?.border, y?.border, t),
      borderRadius: lerpBorderRadius(x?.borderRadius, y?.borderRadius, t),
      boxShadow: _lerpShadows(x?.boxShadow, y?.boxShadow, t),
      gradient: _switch(x?.gradient, y?.gradient, t),
      image: _switch(x?.image, y?.image, t),
      shape: (y ?? x)!.shape,
    );
  }
  return _switch(a, b, t);
}

TextStyle? lerpTextStyle(TextStyle? a, TextStyle? b, double t) {
  if (a == null && b == null) return null;
  final x = a ?? const TextStyle(), y = b ?? const TextStyle();
  double? number(double? p, double? q) =>
      p == null || q == null ? _switch(p, q, t) : _mix(p, q, t);
  FontWeight? weight;
  if (x.fontWeight != null && y.fontWeight != null) {
    weight =
        FontWeight.values[_mix(
          x.fontWeight!.index.toDouble(),
          y.fontWeight!.index.toDouble(),
          t,
        ).round()];
  } else {
    weight = _switch(x.fontWeight, y.fontWeight, t);
  }
  return TextStyle(
    inherit: _switch(x.inherit, y.inherit, t)!,
    color: Color.lerp(x.color, y.color, t),
    backgroundColor: Color.lerp(x.backgroundColor, y.backgroundColor, t),
    fontSize: number(x.fontSize, y.fontSize),
    fontWeight: weight,
    fontStyle: _switch(x.fontStyle, y.fontStyle, t),
    letterSpacing: number(x.letterSpacing, y.letterSpacing),
    wordSpacing: number(x.wordSpacing, y.wordSpacing),
    height: number(x.height, y.height),
    decoration: _switch(x.decoration, y.decoration, t),
    decorationColor: Color.lerp(x.decorationColor, y.decorationColor, t),
    fontFamily: _switch(x.fontFamily, y.fontFamily, t),
    fontFamilyFallback: _switch(x.fontFamilyFallback, y.fontFamilyFallback, t),
    fontFeatures: _switch(x.fontFeatures, y.fontFeatures, t),
    overflow: _switch(x.overflow, y.overflow, t),
  );
}

Size? lerpSize(Size? a, Size? b, double t) {
  if (a == null && b == null) return null;
  final x = a ?? Size.zero, y = b ?? Size.zero;
  return Size(_mix(x.width, y.width, t), _mix(x.height, y.height, t));
}

/// Line-box settings for a paragraph. The runtime applies `height` and
/// `fontSize` when [forceStrutHeight] is set.
class StrutStyle {
  const StrutStyle({
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize,
    this.height,
    this.leadingDistribution,
    this.leading,
    this.fontWeight,
    this.fontStyle,
    this.forceStrutHeight,
    this.debugLabel,
    String? package,
  });
  StrutStyle.fromTextStyle(
    TextStyle textStyle, {
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    this.leading,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    this.forceStrutHeight,
    String? debugLabel,
    String? package,
  }) : fontFamily = fontFamily ?? textStyle.fontFamily,
       fontFamilyFallback = fontFamilyFallback ?? textStyle.fontFamilyFallback,
       fontSize = fontSize ?? textStyle.fontSize,
       height = height ?? textStyle.height,
       leadingDistribution =
           leadingDistribution ?? textStyle.leadingDistribution,
       fontWeight = fontWeight ?? textStyle.fontWeight,
       fontStyle = fontStyle ?? textStyle.fontStyle,
       debugLabel = debugLabel ?? textStyle.debugLabel;
  final String? fontFamily, debugLabel;
  final List<String>? fontFamilyFallback;
  final double? fontSize, height, leading;
  final TextLeadingDistribution? leadingDistribution;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final bool? forceStrutHeight;
  static const disabled = StrutStyle(height: 0, leading: 0);
}

/// A color in hue, saturation and lightness, as in Flutter.
class HSLColor {
  const HSLColor.fromAHSL(
    this.alpha,
    this.hue,
    this.saturation,
    this.lightness,
  );

  factory HSLColor.fromColor(Color color) {
    final red = color.r, green = color.g, blue = color.b;
    final max = math.max(red, math.max(green, blue));
    final min = math.min(red, math.min(green, blue));
    final delta = max - min;
    final hue = _hue(red, green, blue, max, delta);
    final lightness = (max + min) / 2;
    final saturation = lightness == 1
        ? 0.0
        : (delta / (1 - (2 * lightness - 1).abs())).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(color.a, hue, saturation, lightness);
  }

  final double alpha, hue, saturation, lightness;

  HSLColor withAlpha(double alpha) =>
      HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  HSLColor withHue(double hue) =>
      HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  HSLColor withSaturation(double saturation) =>
      HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  HSLColor withLightness(double lightness) =>
      HSLColor.fromAHSL(alpha, hue, saturation, lightness);

  Color toColor() {
    final chroma = (1 - (2 * lightness - 1).abs()) * saturation;
    final secondary = chroma * (1 - (((hue / 60) % 2) - 1).abs());
    final match = lightness - chroma / 2;
    return _colorFromHue(alpha, hue, chroma, secondary, match);
  }

  static HSLColor? lerp(HSLColor? a, HSLColor? b, double t) {
    if (a == null || b == null) return a ?? b;
    return HSLColor.fromAHSL(
      a.alpha + (b.alpha - a.alpha) * t,
      (a.hue + (b.hue - a.hue) * t) % 360,
      a.saturation + (b.saturation - a.saturation) * t,
      a.lightness + (b.lightness - a.lightness) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HSLColor &&
      other.alpha == alpha &&
      other.hue == hue &&
      other.saturation == saturation &&
      other.lightness == lightness;
  @override
  int get hashCode => Object.hash(alpha, hue, saturation, lightness);
}

class HSVColor {
  const HSVColor.fromAHSV(this.alpha, this.hue, this.saturation, this.value);

  factory HSVColor.fromColor(Color color) {
    final red = color.r, green = color.g, blue = color.b;
    final max = math.max(red, math.max(green, blue));
    final min = math.min(red, math.min(green, blue));
    final delta = max - min;
    return HSVColor.fromAHSV(
      color.a,
      _hue(red, green, blue, max, delta),
      max == 0 ? 0 : delta / max,
      max,
    );
  }

  final double alpha, hue, saturation, value;

  HSVColor withAlpha(double alpha) =>
      HSVColor.fromAHSV(alpha, hue, saturation, value);
  HSVColor withHue(double hue) =>
      HSVColor.fromAHSV(alpha, hue, saturation, value);
  HSVColor withSaturation(double saturation) =>
      HSVColor.fromAHSV(alpha, hue, saturation, value);
  HSVColor withValue(double value) =>
      HSVColor.fromAHSV(alpha, hue, saturation, value);

  Color toColor() {
    final chroma = saturation * value;
    final secondary = chroma * (1 - (((hue / 60) % 2) - 1).abs());
    return _colorFromHue(alpha, hue, chroma, secondary, value - chroma);
  }

  @override
  bool operator ==(Object other) =>
      other is HSVColor &&
      other.alpha == alpha &&
      other.hue == hue &&
      other.saturation == saturation &&
      other.value == value;
  @override
  int get hashCode => Object.hash(alpha, hue, saturation, value);
}

double _hue(double red, double green, double blue, double max, double delta) {
  if (max == 0 || delta == 0) return 0;
  final double hue;
  if (max == red) {
    hue = 60 * (((green - blue) / delta) % 6);
  } else if (max == green) {
    hue = 60 * (((blue - red) / delta) + 2);
  } else {
    hue = 60 * (((red - green) / delta) + 4);
  }
  return hue.isNaN ? 0 : hue;
}

Color _colorFromHue(
  double alpha,
  double hue,
  double chroma,
  double secondary,
  double match,
) {
  final (r, g, b) = hue < 60
      ? (chroma, secondary, 0.0)
      : hue < 120
      ? (secondary, chroma, 0.0)
      : hue < 180
      ? (0.0, chroma, secondary)
      : hue < 240
      ? (0.0, secondary, chroma)
      : hue < 300
      ? (secondary, 0.0, chroma)
      : (chroma, 0.0, secondary);
  return Color.from(
    alpha: alpha,
    red: r + match,
    green: g + match,
    blue: b + match,
  );
}
