/// Bounded material values translated to CSS by the native runtime.
library;

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
}

class TextStyle {
  const TextStyle({this.color, this.fontSize, this.fontWeight, this.height});
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? height;
  TextStyle copyWith({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) => TextStyle(
    color: color ?? this.color,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    height: height ?? this.height,
  );
}

class TextTheme {
  const TextTheme({
    this.bodyMedium = const TextStyle(fontSize: 14),
    this.bodySmall = const TextStyle(fontSize: 12),
    this.labelSmall = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    this.titleSmall = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    this.titleMedium = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  });
  final TextStyle? bodyMedium, bodySmall, labelSmall, titleSmall, titleMedium;
}

class ColorScheme {
  const ColorScheme({
    this.primary = const Color(0xff6750a4),
    this.surface = const Color(0xfffffbfe),
    this.onSurface = const Color(0xff1c1b1f),
    this.onSurfaceVariant = const Color(0xff49454f),
    this.outlineVariant = const Color(0xffcac4d0),
    this.surfaceContainerLow = const Color(0xfff7f2fa),
  });
  final Color primary,
      surface,
      onSurface,
      onSurfaceVariant,
      outlineVariant,
      surfaceContainerLow;
}

class ThemeData {
  const ThemeData({
    this.colorScheme = const ColorScheme(),
    this.textTheme = const TextTheme(),
    this.extensions = const [],
  });
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Iterable<ThemeExtension<dynamic>> extensions;
  T? extension<T>() {
    for (final extension in extensions) {
      if (extension is T) return extension as T;
    }
    return null;
  }
}

class EdgeInsets {
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
  static const zero = EdgeInsets.all(0);
  final double left, top, right, bottom;
}

class BorderRadius {
  const BorderRadius.circular(this.radius);
  final double radius;
}

class BorderSide {
  const BorderSide({this.color = const Color(0xff000000), this.width = 1});
  final Color color;
  final double width;
}

class RoundedRectangleBorder {
  const RoundedRectangleBorder({
    this.borderRadius = const BorderRadius.circular(0),
    this.side = const BorderSide(width: 0),
  });
  final BorderRadius borderRadius;
  final BorderSide side;
}

String colorCss(Color color) =>
    'rgba(${color.red},${color.green},${color.blue},${color.alpha / 255})';

double checkedDimension(double value) {
  if (!value.isFinite || value < 0)
    throw ArgumentError('CSS dimensions must be finite and nonnegative.');
  return value;
}

String textStyleCss(TextStyle? style) => style == null
    ? ''
    : '${style.color == null ? '' : 'color:${colorCss(style.color!)};'}'
          '${style.fontSize == null ? '' : 'font-size:${checkedDimension(style.fontSize!)}px;'}'
          '${style.fontWeight == null ? '' : 'font-weight:${(style.fontWeight!.index + 1) * 100};'}'
          '${style.height == null ? '' : 'line-height:${checkedDimension(style.height!)};'}';
