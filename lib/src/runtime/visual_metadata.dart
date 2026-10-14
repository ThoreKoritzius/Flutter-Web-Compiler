/// Color and icon values. This library does not paint or load icon fonts.
library;

import 'dart:math' as math;

enum ColorSpace { sRGB, extendedSRGB, displayP3 }

/// 32-bit sRGB colors. Components are stored as 8-bit channels.
class Color {
  const Color(int value) : _value = value;
  const Color.fromARGB(int a, int r, int g, int b)
    : _value =
          ((a & 0xff) << 24) |
          ((r & 0xff) << 16) |
          ((g & 0xff) << 8) |
          (b & 0xff);
  Color.fromRGBO(int r, int g, int b, double opacity)
    : this.fromARGB((opacity.clamp(0.0, 1.0) * 255).round(), r, g, b);
  Color.from({
    required double alpha,
    required double red,
    required double green,
    required double blue,
    ColorSpace colorSpace = ColorSpace.sRGB,
  }) : this.fromARGB(
         (alpha.clamp(0.0, 1.0) * 255).round(),
         (red.clamp(0.0, 1.0) * 255).round(),
         (green.clamp(0.0, 1.0) * 255).round(),
         (blue.clamp(0.0, 1.0) * 255).round(),
       );
  ColorSpace get colorSpace => ColorSpace.sRGB;
  final int _value;
  int get value => _value & 0xffffffff;
  int get alpha => (value >> 24) & 0xff;
  int get red => (value >> 16) & 0xff;
  int get green => (value >> 8) & 0xff;
  int get blue => value & 0xff;
  double get opacity => alpha / 255;
  double get a => alpha / 255;
  double get r => red / 255;
  double get g => green / 255;
  double get b => blue / 255;
  int toARGB32() => value;

  static int _channel(double? component, int fallback) {
    if (component == null) return fallback;
    if (!component.isFinite || component < 0 || component > 1)
      throw ArgumentError('Color components must be between zero and one.');
    return (component * 255).round();
  }

  Color withValues({double? alpha, double? red, double? green, double? blue}) =>
      Color.fromARGB(
        _channel(alpha, this.alpha),
        _channel(red, this.red),
        _channel(green, this.green),
        _channel(blue, this.blue),
      );
  Color withAlpha(int a) => Color.fromARGB(a, red, green, blue);
  Color withOpacity(double opacity) => withValues(alpha: opacity);
  Color withRed(int r) => Color.fromARGB(alpha, r, green, blue);
  Color withGreen(int g) => Color.fromARGB(alpha, red, g, blue);
  Color withBlue(int b) => Color.fromARGB(alpha, red, green, b);

  /// Relative luminance per WCAG, as Flutter computes it.
  double computeLuminance() {
    double linear(int channel) {
      final c = channel / 255;
      return c <= 0.03928 ? c / 12.92 : _pow((c + 0.055) / 1.055, 2.4);
    }

    return 0.2126 * linear(red) +
        0.7152 * linear(green) +
        0.0722 * linear(blue);
  }

  static double _pow(double x, double y) => math.pow(x, y).toDouble();

  /// Per-channel interpolation in sRGB, matching Flutter's legacy lerp.
  static Color? lerp(Color? x, Color? y, double t) {
    if (x == y) return x;
    if (x == null) return y!.withAlpha((y.alpha * t).round().clamp(0, 255));
    if (y == null)
      return x.withAlpha((x.alpha * (1 - t)).round().clamp(0, 255));
    int mix(int p, int q) => (p + (q - p) * t).round().clamp(0, 255);
    return Color.fromARGB(
      mix(x.alpha, y.alpha),
      mix(x.red, y.red),
      mix(x.green, y.green),
      mix(x.blue, y.blue),
    );
  }

  static Color alphaBlend(Color foreground, Color background) {
    final alpha = foreground.alpha;
    if (alpha == 0) return background;
    final invAlpha = 0xff - alpha;
    var backAlpha = background.alpha;
    if (backAlpha == 0xff) {
      return Color.fromARGB(
        0xff,
        (alpha * foreground.red + invAlpha * background.red) ~/ 0xff,
        (alpha * foreground.green + invAlpha * background.green) ~/ 0xff,
        (alpha * foreground.blue + invAlpha * background.blue) ~/ 0xff,
      );
    }
    backAlpha = (backAlpha * invAlpha) ~/ 0xff;
    final outAlpha = alpha + backAlpha;
    return Color.fromARGB(
      outAlpha,
      (foreground.red * alpha + background.red * backAlpha) ~/ outAlpha,
      (foreground.green * alpha + background.green * backAlpha) ~/ outAlpha,
      (foreground.blue * alpha + background.blue * backAlpha) ~/ outAlpha,
    );
  }

  @override
  bool operator ==(Object other) => other is Color && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'Color(0x${value.toRadixString(16).padLeft(8, '0')})';
}

class IconData {
  const IconData(
    this.codePoint, {
    this.fontFamily,
    this.fontPackage,
    this.matchTextDirection = false,
    this.fontFamilyFallback,
  });
  final int codePoint;
  final String? fontFamily;
  final String? fontPackage;
  final bool matchTextDirection;
  final List<String>? fontFamilyFallback;
}

abstract class ThemeExtension<T extends ThemeExtension<T>> {
  const ThemeExtension();
  Object get type => T;
  ThemeExtension<T> copyWith();
  ThemeExtension<T> lerp(covariant ThemeExtension<T>? other, double t);
}
