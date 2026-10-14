/// Bounded painting and material values translated to CSS by the native
/// runtime. Defaults follow the Material 3 baseline; this is not Flutter's
/// painting library and does not claim pixel parity.
library;

import 'dart:math' as math;

import 'package:material_color_utilities/material_color_utilities.dart';

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

enum BoxShape { rectangle, circle }

enum BorderStyle { none, solid }

enum Clip { none, hardEdge, antiAlias, antiAliasWithSaveLayer }

enum Brightness { light, dark }

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
  final double dx, dy;
  static const zero = Offset(0, 0);
  @override
  bool operator ==(Object other) =>
      other is Offset && other.dx == dx && other.dy == dy;
  @override
  int get hashCode => Object.hash(dx, dy);
}

class TextStyle {
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
  });
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
  }) => TextStyle(
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
    );
  }

  TextStyle apply({
    Color? color,
    Color? decorationColor,
    String? fontFamily,
    double fontSizeFactor = 1,
    double fontSizeDelta = 0,
  }) => copyWith(
    color: color,
    decorationColor: decorationColor,
    fontFamily: fontFamily,
    fontSize: fontSize == null
        ? null
        : fontSize! * fontSizeFactor + fontSizeDelta,
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

  TextTheme _map(TextStyle? Function(TextStyle?) f) => TextTheme(
    displayLarge: f(displayLarge),
    displayMedium: f(displayMedium),
    displaySmall: f(displaySmall),
    headlineLarge: f(headlineLarge),
    headlineMedium: f(headlineMedium),
    headlineSmall: f(headlineSmall),
    titleLarge: f(titleLarge),
    titleMedium: f(titleMedium),
    titleSmall: f(titleSmall),
    bodyLarge: f(bodyLarge),
    bodyMedium: f(bodyMedium),
    bodySmall: f(bodySmall),
    labelLarge: f(labelLarge),
    labelMedium: f(labelMedium),
    labelSmall: f(labelSmall),
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

  TextTheme apply({
    String? fontFamily,
    Color? bodyColor,
    Color? displayColor,
  }) => _map(
    (style) => style?.copyWith(
      fontFamily: fontFamily,
      color: bodyColor ?? displayColor,
    ),
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
  }) : _surfaceTint = surfaceTint;

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
    return ColorScheme(
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
  final Color? _surfaceTint;
  Color get surfaceTint => _surfaceTint ?? primary;
  @Deprecated('Use surface instead.')
  Color get background => surface;
  @Deprecated('Use onSurface instead.')
  Color get onBackground => onSurface;
  @Deprecated('Use surfaceContainerHighest instead.')
  Color get surfaceVariant => surfaceContainerHighest;

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
    Color? surfaceTint,
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
    surfaceTint: surfaceTint ?? _surfaceTint,
  );
}

class IconThemeData {
  const IconThemeData({this.color, this.size, this.opacity});
  final Color? color;
  final double? size;
  final double? opacity;
  IconThemeData copyWith({Color? color, double? size, double? opacity}) =>
      IconThemeData(
        color: color ?? this.color,
        size: size ?? this.size,
        opacity: opacity ?? this.opacity,
      );
  IconThemeData merge(IconThemeData? other) => other == null
      ? this
      : copyWith(color: other.color, size: other.size, opacity: other.opacity);
}

class ThemeData {
  factory ThemeData({
    ColorScheme? colorScheme,
    Color? colorSchemeSeed,
    Brightness? brightness,
    bool? useMaterial3,
    TextTheme? textTheme,
    String? fontFamily,
    Color? scaffoldBackgroundColor,
    Color? dividerColor,
    Color? cardColor,
    IconThemeData? iconTheme,
    Iterable<ThemeExtension<dynamic>> extensions = const [],
  }) {
    if (colorScheme != null && colorSchemeSeed != null)
      throw ArgumentError('Use either colorScheme or colorSchemeSeed.');
    final scheme =
        colorScheme ??
        (colorSchemeSeed != null
            ? ColorScheme.fromSeed(
                seedColor: colorSchemeSeed,
                brightness: brightness ?? Brightness.light,
              )
            : brightness == Brightness.dark
            ? const ColorScheme.dark()
            : const ColorScheme());
    var text = TextTheme.material3.merge(textTheme);
    if (fontFamily != null) text = text.apply(fontFamily: fontFamily);
    return ThemeData.raw(
      colorScheme: scheme,
      textTheme: text,
      useMaterial3: useMaterial3 ?? true,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? scheme.surface,
      dividerColor: dividerColor ?? scheme.outlineVariant,
      cardColor: cardColor ?? scheme.surfaceContainerLow,
      iconTheme: iconTheme ?? IconThemeData(color: scheme.onSurface, size: 24),
      extensions: extensions,
    );
  }
  factory ThemeData.light({bool? useMaterial3}) =>
      ThemeData(useMaterial3: useMaterial3);
  factory ThemeData.dark({bool? useMaterial3}) =>
      ThemeData(brightness: Brightness.dark, useMaterial3: useMaterial3);
  const ThemeData.raw({
    required this.colorScheme,
    required this.textTheme,
    required this.useMaterial3,
    required this.scaffoldBackgroundColor,
    required this.dividerColor,
    required this.cardColor,
    required this.iconTheme,
    required this.extensions,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool useMaterial3;
  final Color scaffoldBackgroundColor, dividerColor, cardColor;
  final IconThemeData iconTheme;
  final Iterable<ThemeExtension<dynamic>> extensions;
  Brightness get brightness => colorScheme.brightness;
  Color get primaryColor => colorScheme.primary;
  Color get canvasColor => colorScheme.surface;
  Color get disabledColor => colorScheme.onSurface.withValues(alpha: 0.38);
  Color get hintColor => colorScheme.onSurfaceVariant;

  T? extension<T>() {
    for (final extension in extensions) {
      if (extension is T) return extension as T;
    }
    return null;
  }

  ThemeData copyWith({
    ColorScheme? colorScheme,
    TextTheme? textTheme,
    bool? useMaterial3,
    Color? scaffoldBackgroundColor,
    Color? dividerColor,
    Color? cardColor,
    IconThemeData? iconTheme,
    Iterable<ThemeExtension<dynamic>>? extensions,
  }) => ThemeData.raw(
    colorScheme: colorScheme ?? this.colorScheme,
    textTheme: textTheme ?? this.textTheme,
    useMaterial3: useMaterial3 ?? this.useMaterial3,
    scaffoldBackgroundColor:
        scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
    dividerColor: dividerColor ?? this.dividerColor,
    cardColor: cardColor ?? this.cardColor,
    iconTheme: iconTheme ?? this.iconTheme,
    extensions: extensions ?? this.extensions,
  );
}

abstract class EdgeInsetsGeometry {
  const EdgeInsetsGeometry();
  EdgeInsets resolve(TextDirection? direction);
}

class EdgeInsets extends EdgeInsetsGeometry {
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
  const Radius.circular(double radius) : x = radius, y = radius;
  const Radius.elliptical(this.x, this.y);
  static const zero = Radius.circular(0);
  final double x, y;
}

abstract class BorderRadiusGeometry {
  const BorderRadiusGeometry();
  BorderRadius resolve(TextDirection? direction);
}

class BorderRadius extends BorderRadiusGeometry {
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
}

class RoundedRectangleBorder extends OutlinedBorder {
  const RoundedRectangleBorder({
    this.borderRadius = BorderRadius.zero,
    super.side,
  });
  final BorderRadiusGeometry borderRadius;
}

/// Approximated as a rounded rectangle; CSS has no superellipse corners.
class ContinuousRectangleBorder extends RoundedRectangleBorder {
  const ContinuousRectangleBorder({super.borderRadius, super.side});
}

class StadiumBorder extends OutlinedBorder {
  const StadiumBorder({super.side});
}

class CircleBorder extends OutlinedBorder {
  const CircleBorder({super.side});
}

class BoxShadow {
  const BoxShadow({
    this.color = const Color(0xff000000),
    this.offset = Offset.zero,
    this.blurRadius = 0,
    this.spreadRadius = 0,
  });
  final Color color;
  final Offset offset;
  final double blurRadius, spreadRadius;
}

abstract class AlignmentGeometry {
  const AlignmentGeometry();
  Alignment resolve(TextDirection? direction);
}

class Alignment extends AlignmentGeometry {
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
  const Gradient({required this.colors, this.stops});
  final List<Color> colors;
  final List<double>? stops;
}

class LinearGradient extends Gradient {
  const LinearGradient({
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    required super.colors,
    super.stops,
  });
  final AlignmentGeometry begin, end;
}

class RadialGradient extends Gradient {
  const RadialGradient({
    this.center = Alignment.center,
    this.radius = 0.5,
    required super.colors,
    super.stops,
  });
  final AlignmentGeometry center;
  final double radius;
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
  });
  final ImageProvider image;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final double opacity;
}

String decorationImageCss(DecorationImage? image) {
  if (image == null) return '';
  if (image.opacity != 1)
    throw UnsupportedError('Decoration image opacity is unsupported.');
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
  return 'background-image:${cssUrl(image.image.url)};background-size:$size;background-repeat:$repeat;background-position:${cssNumber((a.x + 1) * 50)}% ${cssNumber((a.y + 1) * 50)}%;';
}

abstract class Decoration {
  const Decoration();
}

class BoxDecoration extends Decoration {
  const BoxDecoration({
    this.color,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.image,
    this.shape = BoxShape.rectangle,
  });
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
    return '${cssNumber(s.offset.dx)}px ${cssNumber(s.offset.dy)}px ${px(s.blurRadius)} ${cssNumber(s.spreadRadius)}px ${colorCss(s.color)}';
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
  if (gradient is LinearGradient) {
    final begin = gradient.begin.resolve(TextDirection.ltr);
    final end = gradient.end.resolve(TextDirection.ltr);
    final degrees =
        math.atan2(end.x - begin.x, -(end.y - begin.y)) * 180 / math.pi;
    return 'background-image:linear-gradient(${cssNumber(degrees)}deg,$colors);';
  }
  if (gradient is RadialGradient) {
    final center = gradient.center.resolve(TextDirection.ltr);
    return 'background-image:radial-gradient(circle at ${cssNumber((center.x + 1) * 50)}% ${cssNumber((center.y + 1) * 50)}%,$colors);';
  }
  throw UnsupportedError('Unsupported gradient type.');
}

String shapeCss(ShapeBorder? shape) {
  if (shape == null) return '';
  final side = shape is OutlinedBorder ? shape.side : BorderSide.none;
  final border = borderSideCss('border', side);
  if (shape is StadiumBorder) return '${border}border-radius:9999px;';
  if (shape is CircleBorder) return '${border}border-radius:50%;';
  if (shape is RoundedRectangleBorder)
    return border + borderRadiusCss(shape.borderRadius);
  throw UnsupportedError('Unsupported shape border.');
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
        boxShadowCss(decoration.boxShadow);
  }
  if (decoration is ShapeDecoration) {
    return (decoration.color == null
            ? ''
            : 'background-color:${colorCss(decoration.color!)};') +
        gradientCss(decoration.gradient) +
        shapeCss(decoration.shape) +
        boxShadowCss(decoration.shadows);
  }
  throw UnsupportedError('Unsupported decoration type.');
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
