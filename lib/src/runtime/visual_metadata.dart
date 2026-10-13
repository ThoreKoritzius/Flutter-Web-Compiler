/// Value metadata only. This library does not paint or load icon fonts.
library;

class Color {
  const Color(int value) : _value = value;
  final int _value;
  int get value => _value & 0xffffffff;
  int get alpha => (value >> 24) & 0xff;
  int get red => (value >> 16) & 0xff;
  int get green => (value >> 8) & 0xff;
  int get blue => value & 0xff;

  /// Color-space interpolation is not part of this metadata bridge.
  static Color? lerp(Color? a, Color? b, double t) =>
      throw UnsupportedError('Color interpolation is not supported.');

  @override
  bool operator ==(Object other) => other is Color && other.value == value;
  @override
  int get hashCode => value.hashCode;
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
