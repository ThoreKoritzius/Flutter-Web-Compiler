part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// ThemeData and supporting Material theme types.

enum ListTileStyle { list, drawer }

enum ListTileTitleAlignment { threeLine, titleHeight, top, center, bottom }

enum TabBarIndicatorSize { tab, label }

enum TabAlignment { start, startOffset, fill, center }

enum TabIndicatorAnimation { linear, elastic }

enum BottomNavigationBarLandscapeLayout { spread, centered, linear }

enum ShowValueIndicator {
  onlyForDiscrete,
  onlyForContinuous,
  always,
  onDrag,
  alwaysVisible,
  never,
}

enum SliderInteraction { tapAndSlide, tapOnly, slideOnly, slideThumb }

enum TooltipTriggerMode { manual, longPress, tap }

enum ButtonTextTheme { normal, accent, primary }

enum ButtonBarLayoutBehavior { constrained, padded }

enum IconAlignment { start, end }

/// Where a floating label sits horizontally.
class FloatingLabelAlignment {
  const FloatingLabelAlignment._(this._x);
  final double _x;
  static const start = FloatingLabelAlignment._(-1);
  static const center = FloatingLabelAlignment._(0);
  @override
  bool operator ==(Object other) =>
      other is FloatingLabelAlignment && other._x == _x;
  @override
  int get hashCode => _x.hashCode;
}

// Slider shapes. The native range input paints the slider, so shapes are
// carried as values only.

abstract class SliderComponentShape {
  const SliderComponentShape();
  static const SliderComponentShape noThumb = _EmptySliderComponentShape();
  static const SliderComponentShape noOverlay = _EmptySliderComponentShape();
}

class _EmptySliderComponentShape extends SliderComponentShape {
  const _EmptySliderComponentShape();
}

abstract class SliderTickMarkShape {
  const SliderTickMarkShape();
  static const SliderTickMarkShape noTickMark = RoundSliderTickMarkShape(
    tickMarkRadius: 0,
  );
}

abstract class SliderTrackShape {
  const SliderTrackShape();
}

abstract class RangeSliderTickMarkShape {
  const RangeSliderTickMarkShape();
}

abstract class RangeSliderThumbShape {
  const RangeSliderThumbShape();
}

abstract class RangeSliderTrackShape {
  const RangeSliderTrackShape();
}

abstract class RangeSliderValueIndicatorShape {
  const RangeSliderValueIndicatorShape();
}

class RoundSliderThumbShape extends SliderComponentShape {
  const RoundSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
  });
  final double enabledThumbRadius;
  final double? disabledThumbRadius;
  final double elevation, pressedElevation;
}

class RoundSliderOverlayShape extends SliderComponentShape {
  const RoundSliderOverlayShape({this.overlayRadius = 24.0});
  final double overlayRadius;
}

class HandleThumbShape extends SliderComponentShape {
  const HandleThumbShape();
}

class RoundSliderTickMarkShape extends SliderTickMarkShape {
  const RoundSliderTickMarkShape({this.tickMarkRadius});
  final double? tickMarkRadius;
}

class RoundedRectSliderTrackShape extends SliderTrackShape {
  const RoundedRectSliderTrackShape();
}

class RectangularSliderTrackShape extends SliderTrackShape {
  const RectangularSliderTrackShape();
}

class GappedSliderTrackShape extends SliderTrackShape {
  const GappedSliderTrackShape();
}

class PaddleSliderValueIndicatorShape extends SliderComponentShape {
  const PaddleSliderValueIndicatorShape();
}

class RectangularSliderValueIndicatorShape extends SliderComponentShape {
  const RectangularSliderValueIndicatorShape();
}

class DropSliderValueIndicatorShape extends SliderComponentShape {
  const DropSliderValueIndicatorShape();
}

class RoundRangeSliderThumbShape extends RangeSliderThumbShape {
  const RoundRangeSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
  });
  final double enabledThumbRadius;
  final double? disabledThumbRadius;
  final double elevation, pressedElevation;
}

class RoundedRectRangeSliderTrackShape extends RangeSliderTrackShape {
  const RoundedRectRangeSliderTrackShape();
}

class RoundRangeSliderTickMarkShape extends RangeSliderTickMarkShape {
  const RoundRangeSliderTickMarkShape({this.tickMarkRadius});
  final double? tickMarkRadius;
}

class PaddleRangeSliderValueIndicatorShape
    extends RangeSliderValueIndicatorShape {
  const PaddleRangeSliderValueIndicatorShape();
}

class RectangularRangeSliderValueIndicatorShape
    extends RangeSliderValueIndicatorShape {
  const RectangularRangeSliderValueIndicatorShape();
}

// Ink splash factories. Ink effects are CSS state layers here, so the
// factories only select whether a widget shows a splash at all.

abstract class InteractiveInkFeatureFactory {
  const InteractiveInkFeatureFactory();
}

class _InkFactory extends InteractiveInkFeatureFactory {
  const _InkFactory(this.name);
  final String name;
}

abstract final class InkSplash {
  static const InteractiveInkFeatureFactory splashFactory = _InkFactory(
    'splash',
  );
}

abstract final class InkRipple {
  static const InteractiveInkFeatureFactory splashFactory = _InkFactory(
    'ripple',
  );
}

abstract final class InkSparkle {
  static const InteractiveInkFeatureFactory splashFactory = _InkFactory(
    'sparkle',
  );
  static const InteractiveInkFeatureFactory
  constantTurbulenceSeedSplashFactory = _InkFactory('sparkle');
}

abstract final class NoSplash {
  static const InteractiveInkFeatureFactory splashFactory = _InkFactory('none');
}

bool _noSplash(InteractiveInkFeatureFactory? factory) =>
    identical(factory, NoSplash.splashFactory);

// Page transitions. Routes switch without animation in the DOM runtime;
// builders are accepted so themes compile.

abstract class PageTransitionsBuilder {
  const PageTransitionsBuilder();
}

class FadeUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeUpwardsPageTransitionsBuilder();
}

class OpenUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const OpenUpwardsPageTransitionsBuilder();
}

class ZoomPageTransitionsBuilder extends PageTransitionsBuilder {
  const ZoomPageTransitionsBuilder({
    this.allowSnapshotting = true,
    this.allowEnterRouteSnapshotting = true,
    this.backgroundColor,
  });
  final bool allowSnapshotting, allowEnterRouteSnapshotting;
  final Color? backgroundColor;
}

class FadeForwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeForwardsPageTransitionsBuilder({this.backgroundColor});
  final Color? backgroundColor;
}

class CupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const CupertinoPageTransitionsBuilder();
}

class PredictiveBackPageTransitionsBuilder extends PageTransitionsBuilder {
  const PredictiveBackPageTransitionsBuilder();
}

class PageTransitionsTheme {
  const PageTransitionsTheme({
    Map<TargetPlatform, PageTransitionsBuilder> builders = _defaultBuilders,
  }) : _builders = builders;
  static const Map<TargetPlatform, PageTransitionsBuilder> _defaultBuilders = {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: ZoomPageTransitionsBuilder(),
  };
  final Map<TargetPlatform, PageTransitionsBuilder> _builders;
  Map<TargetPlatform, PageTransitionsBuilder> get builders => _builders;
  @override
  bool operator ==(Object other) =>
      other is PageTransitionsTheme &&
      other._builders.length == _builders.length &&
      _builders.entries.every(
        (entry) => other._builders[entry.key] == entry.value,
      );
  @override
  int get hashCode => Object.hashAllUnordered(_builders.values);
}

/// Overrides for a widget's default animation curves and durations.
class AnimationStyle {
  const AnimationStyle({
    this.curve,
    this.duration,
    this.reverseCurve,
    this.reverseDuration,
  });
  static const AnimationStyle noAnimation = AnimationStyle(
    duration: Duration.zero,
    reverseDuration: Duration.zero,
  );
  final Curve? curve, reverseCurve;
  final Duration? duration, reverseDuration;
  AnimationStyle copyWith({
    Curve? curve,
    Duration? duration,
    Curve? reverseCurve,
    Duration? reverseDuration,
  }) => AnimationStyle(
    curve: curve ?? this.curve,
    duration: duration ?? this.duration,
    reverseCurve: reverseCurve ?? this.reverseCurve,
    reverseDuration: reverseDuration ?? this.reverseDuration,
  );
}

/// An inherited widget that can re-wrap a subtree with its theme.
abstract class InheritedTheme extends InheritedWidget {
  const InheritedTheme({super.key, required super.child});
  Widget wrap(BuildContext context, Widget child);
}

/// The Material type sets. Colors are left to the color scheme, as in the
/// Material 3 2021 typography; the scale is [TextTheme.material3].
class Typography {
  const Typography._(
    this.black,
    this.white,
    this.englishLike,
    this.dense,
    this.tall,
  );
  factory Typography({
    TargetPlatform? platform,
    TextTheme? black,
    TextTheme? white,
    TextTheme? englishLike,
    TextTheme? dense,
    TextTheme? tall,
  }) => Typography.material2021(
    platform: platform,
    black: black,
    white: white,
    englishLike: englishLike,
    dense: dense,
    tall: tall,
  );
  factory Typography.material2014({
    TargetPlatform? platform = TargetPlatform.android,
    TextTheme? black,
    TextTheme? white,
    TextTheme? englishLike,
    TextTheme? dense,
    TextTheme? tall,
  }) => Typography.material2021(
    platform: platform,
    black: black,
    white: white,
    englishLike: englishLike,
    dense: dense,
    tall: tall,
  );
  factory Typography.material2018({
    TargetPlatform? platform = TargetPlatform.android,
    TextTheme? black,
    TextTheme? white,
    TextTheme? englishLike,
    TextTheme? dense,
    TextTheme? tall,
  }) => Typography.material2021(
    platform: platform,
    black: black,
    white: white,
    englishLike: englishLike,
    dense: dense,
    tall: tall,
  );
  factory Typography.material2021({
    TargetPlatform? platform = TargetPlatform.android,
    ColorScheme colorScheme = const ColorScheme.light(),
    TextTheme? black,
    TextTheme? white,
    TextTheme? englishLike,
    TextTheme? dense,
    TextTheme? tall,
  }) {
    final base = TextTheme.material3;
    return Typography._(
      black ??
          base.apply(
            bodyColor: const Color(0xdd000000),
            displayColor: const Color(0x8a000000),
          ),
      white ??
          base.apply(
            bodyColor: const Color(0xffffffff),
            displayColor: const Color(0xb3ffffff),
          ),
      englishLike ?? base,
      dense ?? base,
      tall ?? base,
    );
  }
  final TextTheme black, white, englishLike, dense, tall;
  TextTheme geometryThemeFor(ScriptCategory category) => switch (category) {
    ScriptCategory.englishLike => englishLike,
    ScriptCategory.dense => dense,
    ScriptCategory.tall => tall,
  };
  Typography copyWith({
    TextTheme? black,
    TextTheme? white,
    TextTheme? englishLike,
    TextTheme? dense,
    TextTheme? tall,
  }) => Typography._(
    black ?? this.black,
    white ?? this.white,
    englishLike ?? this.englishLike,
    dense ?? this.dense,
    tall ?? this.tall,
  );
  static Typography lerp(Typography a, Typography b, double t) =>
      t < 0.5 ? a : b;
}

enum ScriptCategory { englishLike, dense, tall }

class AppBarTheme {
  const AppBarTheme({
    @Deprecated('Use backgroundColor instead.') Color? color,
    Color? backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.iconTheme,
    this.actionsIconTheme,
    this.centerTitle,
    this.titleSpacing,
    this.leadingWidth,
    this.toolbarHeight,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.actionsPadding,
  }) : backgroundColor = backgroundColor ?? color;
  final Color? backgroundColor, foregroundColor;
  final double? elevation, scrolledUnderElevation;
  final Color? shadowColor, surfaceTintColor;
  final ShapeBorder? shape;
  final IconThemeData? iconTheme, actionsIconTheme;
  final bool? centerTitle;
  final double? titleSpacing, leadingWidth, toolbarHeight;
  final TextStyle? toolbarTextStyle, titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final EdgeInsetsGeometry? actionsPadding;
  @Deprecated('Use backgroundColor instead.')
  Color? get color => backgroundColor;

  AppBarTheme copyWith({
    IconThemeData? actionsIconTheme,
    @Deprecated('Use backgroundColor instead.') Color? color,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    double? scrolledUnderElevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    IconThemeData? iconTheme,
    bool? centerTitle,
    double? titleSpacing,
    double? leadingWidth,
    double? toolbarHeight,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
    EdgeInsetsGeometry? actionsPadding,
  }) => AppBarTheme(
    backgroundColor: backgroundColor ?? color ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    elevation: elevation ?? this.elevation,
    scrolledUnderElevation:
        scrolledUnderElevation ?? this.scrolledUnderElevation,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    shape: shape ?? this.shape,
    iconTheme: iconTheme ?? this.iconTheme,
    actionsIconTheme: actionsIconTheme ?? this.actionsIconTheme,
    centerTitle: centerTitle ?? this.centerTitle,
    titleSpacing: titleSpacing ?? this.titleSpacing,
    leadingWidth: leadingWidth ?? this.leadingWidth,
    toolbarHeight: toolbarHeight ?? this.toolbarHeight,
    toolbarTextStyle: toolbarTextStyle ?? this.toolbarTextStyle,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    systemOverlayStyle: systemOverlayStyle ?? this.systemOverlayStyle,
    actionsPadding: actionsPadding ?? this.actionsPadding,
  );

  static AppBarTheme of(BuildContext context) => Theme.of(context).appBarTheme;

  static AppBarTheme lerp(AppBarTheme? a, AppBarTheme? b, double t) =>
      (t < 0.5 ? a : b) ?? const AppBarTheme();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBarTheme &&
          other.backgroundColor == backgroundColor &&
          other.foregroundColor == foregroundColor &&
          other.elevation == elevation &&
          other.scrolledUnderElevation == scrolledUnderElevation &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.shape == shape &&
          other.iconTheme == iconTheme &&
          other.actionsIconTheme == actionsIconTheme &&
          other.centerTitle == centerTitle &&
          other.titleSpacing == titleSpacing &&
          other.leadingWidth == leadingWidth &&
          other.toolbarHeight == toolbarHeight &&
          other.toolbarTextStyle == toolbarTextStyle &&
          other.titleTextStyle == titleTextStyle &&
          other.systemOverlayStyle == systemOverlayStyle &&
          other.actionsPadding == actionsPadding;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    elevation,
    scrolledUnderElevation,
    shadowColor,
    surfaceTintColor,
    shape,
    iconTheme,
    actionsIconTheme,
    centerTitle,
    titleSpacing,
    leadingWidth,
    toolbarHeight,
    toolbarTextStyle,
    titleTextStyle,
    systemOverlayStyle,
    actionsPadding,
  );
}

/// The legacy Material 2 button theme; Material 3 buttons do not read it.
class ButtonThemeData {
  const ButtonThemeData({
    this.textTheme = ButtonTextTheme.normal,
    this.minWidth = 88.0,
    this.height = 36.0,
    EdgeInsetsGeometry? padding,
    ShapeBorder? shape,
    this.layoutBehavior = ButtonBarLayoutBehavior.padded,
    this.alignedDropdown = false,
    Color? buttonColor,
    Color? disabledColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    this.colorScheme,
    MaterialTapTargetSize? materialTapTargetSize,
  }) : _padding = padding,
       _shape = shape,
       _buttonColor = buttonColor,
       _disabledColor = disabledColor,
       _focusColor = focusColor,
       _hoverColor = hoverColor,
       _highlightColor = highlightColor,
       _splashColor = splashColor,
       _materialTapTargetSize = materialTapTargetSize;
  final ButtonTextTheme textTheme;
  final double minWidth, height;
  final ButtonBarLayoutBehavior layoutBehavior;
  final bool alignedDropdown;
  final ColorScheme? colorScheme;
  final EdgeInsetsGeometry? _padding;
  final ShapeBorder? _shape;
  final Color? _buttonColor, _disabledColor, _focusColor, _hoverColor;
  final Color? _highlightColor, _splashColor;
  final MaterialTapTargetSize? _materialTapTargetSize;
  EdgeInsetsGeometry get padding =>
      _padding ?? const EdgeInsets.symmetric(horizontal: 16);
  ShapeBorder get shape =>
      _shape ??
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      );
  BoxConstraints get constraints =>
      BoxConstraints(minWidth: minWidth, minHeight: height);
  ButtonThemeData copyWith({
    ButtonTextTheme? textTheme,
    ButtonBarLayoutBehavior? layoutBehavior,
    double? minWidth,
    double? height,
    EdgeInsetsGeometry? padding,
    ShapeBorder? shape,
    bool? alignedDropdown,
    Color? buttonColor,
    Color? disabledColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    ColorScheme? colorScheme,
    MaterialTapTargetSize? materialTapTargetSize,
  }) => ButtonThemeData(
    textTheme: textTheme ?? this.textTheme,
    layoutBehavior: layoutBehavior ?? this.layoutBehavior,
    minWidth: minWidth ?? this.minWidth,
    height: height ?? this.height,
    padding: padding ?? _padding,
    shape: shape ?? _shape,
    alignedDropdown: alignedDropdown ?? this.alignedDropdown,
    buttonColor: buttonColor ?? _buttonColor,
    disabledColor: disabledColor ?? _disabledColor,
    focusColor: focusColor ?? _focusColor,
    hoverColor: hoverColor ?? _hoverColor,
    highlightColor: highlightColor ?? _highlightColor,
    splashColor: splashColor ?? _splashColor,
    colorScheme: colorScheme ?? this.colorScheme,
    materialTapTargetSize: materialTapTargetSize ?? _materialTapTargetSize,
  );
}

class ButtonTheme extends InheritedTheme {
  const ButtonTheme({
    super.key,
    ButtonTextTheme textTheme = ButtonTextTheme.normal,
    ButtonBarLayoutBehavior layoutBehavior = ButtonBarLayoutBehavior.padded,
    double minWidth = 88.0,
    double height = 36.0,
    EdgeInsetsGeometry? padding,
    ShapeBorder? shape,
    bool alignedDropdown = false,
    Color? buttonColor,
    Color? disabledColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    ColorScheme? colorScheme,
    MaterialTapTargetSize? materialTapTargetSize,
    required super.child,
  }) : data = const ButtonThemeData(),
       _overrides = (
         textTheme,
         layoutBehavior,
         minWidth,
         height,
         padding,
         shape,
         alignedDropdown,
         buttonColor,
       );
  const ButtonTheme.fromButtonThemeData({
    super.key,
    required this.data,
    required super.child,
  }) : _overrides = null;
  final ButtonThemeData data;
  final (
    ButtonTextTheme,
    ButtonBarLayoutBehavior,
    double,
    double,
    EdgeInsetsGeometry?,
    ShapeBorder?,
    bool,
    Color?,
  )?
  _overrides;
  ButtonThemeData get _data {
    final o = _overrides;
    if (o == null) return data;
    return ButtonThemeData(
      textTheme: o.$1,
      layoutBehavior: o.$2,
      minWidth: o.$3,
      height: o.$4,
      padding: o.$5,
      shape: o.$6,
      alignedDropdown: o.$7,
      buttonColor: o.$8,
    );
  }

  static ButtonThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ButtonTheme>()?._data ??
      Theme.of(context).buttonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ButtonTheme.fromButtonThemeData(data: _data, child: child);
  @override
  bool updateShouldNotify(ButtonTheme oldWidget) =>
      !identical(_data, oldWidget._data);
}

// Flutter 3.27 moved card, dialog and tab bar themes to `*ThemeData`
// classes and turned `CardTheme`, `DialogTheme` and `TabBarTheme` into
// inherited widgets whose constructors still take the theme values. Both
// spellings are accepted by ThemeData.

class CardTheme extends InheritedTheme {
  const CardTheme({
    super.key,
    Clip? clipBehavior,
    Color? color,
    Color? surfaceTintColor,
    Color? shadowColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    ShapeBorder? shape,
    CardThemeData? data,
    Widget? child,
  }) : _data = data,
       _clipBehavior = clipBehavior,
       _color = color,
       _surfaceTintColor = surfaceTintColor,
       _shadowColor = shadowColor,
       _elevation = elevation,
       _margin = margin,
       _shape = shape,
       super(child: child ?? const SizedBox());
  final CardThemeData? _data;
  final Clip? _clipBehavior;
  final Color? _color, _surfaceTintColor, _shadowColor;
  final double? _elevation;
  final EdgeInsetsGeometry? _margin;
  final ShapeBorder? _shape;
  CardThemeData get data =>
      _data ??
      CardThemeData(
        clipBehavior: _clipBehavior,
        color: _color,
        surfaceTintColor: _surfaceTintColor,
        shadowColor: _shadowColor,
        elevation: _elevation,
        margin: _margin,
        shape: _shape,
      );
  Clip? get clipBehavior => data.clipBehavior;
  Color? get color => data.color;
  Color? get surfaceTintColor => data.surfaceTintColor;
  Color? get shadowColor => data.shadowColor;
  double? get elevation => data.elevation;
  EdgeInsetsGeometry? get margin => data.margin;
  ShapeBorder? get shape => data.shape;
  CardTheme copyWith({
    Clip? clipBehavior,
    Color? color,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    ShapeBorder? shape,
  }) => CardTheme(
    data: data.copyWith(
      clipBehavior: clipBehavior,
      color: color,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation,
      margin: margin,
      shape: shape,
    ),
    child: child,
  );
  static CardThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardTheme>()?.data ??
      Theme.of(context).cardTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      CardTheme(data: data, child: child);
  @override
  bool updateShouldNotify(CardTheme oldWidget) => data != oldWidget.data;
}

class DialogTheme extends InheritedTheme {
  const DialogTheme({
    super.key,
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    AlignmentGeometry? alignment,
    Color? iconColor,
    TextStyle? titleTextStyle,
    TextStyle? contentTextStyle,
    EdgeInsetsGeometry? actionsPadding,
    Color? barrierColor,
    EdgeInsets? insetPadding,
    Clip? clipBehavior,
    DialogThemeData? data,
    Widget? child,
  }) : _data = data,
       _values = (
         backgroundColor,
         elevation,
         shadowColor,
         surfaceTintColor,
         shape,
         alignment,
         iconColor,
         titleTextStyle,
         contentTextStyle,
         actionsPadding,
         barrierColor,
         insetPadding,
         clipBehavior,
       ),
       super(child: child ?? const SizedBox());
  final DialogThemeData? _data;
  final (
    Color?,
    double?,
    Color?,
    Color?,
    ShapeBorder?,
    AlignmentGeometry?,
    Color?,
    TextStyle?,
    TextStyle?,
    EdgeInsetsGeometry?,
    Color?,
    EdgeInsets?,
    Clip?,
  )
  _values;
  DialogThemeData get data =>
      _data ??
      DialogThemeData(
        backgroundColor: _values.$1,
        elevation: _values.$2,
        shadowColor: _values.$3,
        surfaceTintColor: _values.$4,
        shape: _values.$5,
        alignment: _values.$6,
        iconColor: _values.$7,
        titleTextStyle: _values.$8,
        contentTextStyle: _values.$9,
        actionsPadding: _values.$10,
        barrierColor: _values.$11,
        insetPadding: _values.$12,
        clipBehavior: _values.$13,
      );
  Color? get backgroundColor => data.backgroundColor;
  double? get elevation => data.elevation;
  ShapeBorder? get shape => data.shape;
  TextStyle? get titleTextStyle => data.titleTextStyle;
  TextStyle? get contentTextStyle => data.contentTextStyle;
  static DialogThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DialogTheme>()?.data ??
      Theme.of(context).dialogTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      DialogTheme(data: data, child: child);
  @override
  bool updateShouldNotify(DialogTheme oldWidget) => data != oldWidget.data;
}

class TabBarTheme extends InheritedTheme {
  const TabBarTheme({
    super.key,
    Decoration? indicator,
    Color? indicatorColor,
    TabBarIndicatorSize? indicatorSize,
    Color? dividerColor,
    double? dividerHeight,
    Color? labelColor,
    EdgeInsetsGeometry? labelPadding,
    TextStyle? labelStyle,
    Color? unselectedLabelColor,
    TextStyle? unselectedLabelStyle,
    WidgetStateProperty<Color?>? overlayColor,
    InteractiveInkFeatureFactory? splashFactory,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    TabAlignment? tabAlignment,
    TextScaler? textScaler,
    TabIndicatorAnimation? indicatorAnimation,
    TabBarThemeData? data,
    Widget? child,
  }) : _data = data,
       _values = (
         indicator,
         indicatorColor,
         indicatorSize,
         dividerColor,
         dividerHeight,
         labelColor,
         labelPadding,
         labelStyle,
         unselectedLabelColor,
         unselectedLabelStyle,
         overlayColor,
         splashFactory,
         mouseCursor,
         tabAlignment,
         textScaler,
         indicatorAnimation,
       ),
       super(child: child ?? const SizedBox());
  final TabBarThemeData? _data;
  final (
    Decoration?,
    Color?,
    TabBarIndicatorSize?,
    Color?,
    double?,
    Color?,
    EdgeInsetsGeometry?,
    TextStyle?,
    Color?,
    TextStyle?,
    WidgetStateProperty<Color?>?,
    InteractiveInkFeatureFactory?,
    WidgetStateProperty<MouseCursor?>?,
    TabAlignment?,
    TextScaler?,
    TabIndicatorAnimation?,
  )
  _values;
  TabBarThemeData get data =>
      _data ??
      TabBarThemeData(
        indicator: _values.$1,
        indicatorColor: _values.$2,
        indicatorSize: _values.$3,
        dividerColor: _values.$4,
        dividerHeight: _values.$5,
        labelColor: _values.$6,
        labelPadding: _values.$7,
        labelStyle: _values.$8,
        unselectedLabelColor: _values.$9,
        unselectedLabelStyle: _values.$10,
        overlayColor: _values.$11,
        splashFactory: _values.$12,
        mouseCursor: _values.$13,
        tabAlignment: _values.$14,
        textScaler: _values.$15,
        indicatorAnimation: _values.$16,
      );
  Color? get labelColor => data.labelColor;
  Color? get unselectedLabelColor => data.unselectedLabelColor;
  Color? get indicatorColor => data.indicatorColor;
  static TabBarThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabBarTheme>()?.data ??
      Theme.of(context).tabBarTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      TabBarTheme(data: data, child: child);
  @override
  bool updateShouldNotify(TabBarTheme oldWidget) => data != oldWidget.data;
}

CardThemeData _cardThemeData(Object? value) => switch (value) {
  null => const CardThemeData(),
  CardThemeData data => data,
  CardTheme theme => theme.data,
  _ => throw ArgumentError.value(
    value,
    'cardTheme',
    'Expected a CardThemeData or CardTheme.',
  ),
};

DialogThemeData _dialogThemeData(Object? value) => switch (value) {
  null => const DialogThemeData(),
  DialogThemeData data => data,
  DialogTheme theme => theme.data,
  _ => throw ArgumentError.value(
    value,
    'dialogTheme',
    'Expected a DialogThemeData or DialogTheme.',
  ),
};

TabBarThemeData _tabBarThemeData(Object? value) => switch (value) {
  null => const TabBarThemeData(),
  TabBarThemeData data => data,
  TabBarTheme theme => theme.data,
  _ => throw ArgumentError.value(
    value,
    'tabBarTheme',
    'Expected a TabBarThemeData or TabBarTheme.',
  ),
};

class ListTileTheme extends InheritedTheme {
  const ListTileTheme({
    super.key,
    ListTileThemeData? data,
    bool? dense,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    double? horizontalTitleGap,
    double? minVerticalPadding,
    double? minLeadingWidth,
    ListTileControlAffinity? controlAffinity,
    required super.child,
  }) : _data = data,
       _values = (
         dense,
         shape,
         style,
         selectedColor,
         iconColor,
         textColor,
         contentPadding,
         tileColor,
         selectedTileColor,
         enableFeedback,
         mouseCursor,
         horizontalTitleGap,
         minVerticalPadding,
         minLeadingWidth,
         controlAffinity,
       );
  final ListTileThemeData? _data;
  final (
    bool?,
    ShapeBorder?,
    ListTileStyle?,
    Color?,
    Color?,
    Color?,
    EdgeInsetsGeometry?,
    Color?,
    Color?,
    bool?,
    WidgetStateProperty<MouseCursor?>?,
    double?,
    double?,
    double?,
    ListTileControlAffinity?,
  )
  _values;
  ListTileThemeData get data =>
      _data ??
      ListTileThemeData(
        dense: _values.$1,
        shape: _values.$2,
        style: _values.$3,
        selectedColor: _values.$4,
        iconColor: _values.$5,
        textColor: _values.$6,
        contentPadding: _values.$7,
        tileColor: _values.$8,
        selectedTileColor: _values.$9,
        enableFeedback: _values.$10,
        mouseCursor: _values.$11,
        horizontalTitleGap: _values.$12,
        minVerticalPadding: _values.$13,
        minLeadingWidth: _values.$14,
        controlAffinity: _values.$15,
      );
  bool? get dense => data.dense;
  ShapeBorder? get shape => data.shape;
  Color? get selectedColor => data.selectedColor;
  Color? get iconColor => data.iconColor;
  Color? get textColor => data.textColor;
  EdgeInsetsGeometry? get contentPadding => data.contentPadding;
  Color? get tileColor => data.tileColor;

  static ListTileThemeData of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<ListTileTheme>()
        ?.data;
    final theme = Theme.of(context).listTileTheme;
    if (inherited == null) return theme;
    return _mergeListTile(inherited, theme);
  }

  /// Merges the given properties over the nearest list tile theme.
  static Widget merge({
    Key? key,
    bool? dense,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? leadingAndTrailingTextStyle,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    double? horizontalTitleGap,
    double? minVerticalPadding,
    double? minLeadingWidth,
    double? minTileHeight,
    ListTileTitleAlignment? titleAlignment,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    VisualDensity? visualDensity,
    ListTileControlAffinity? controlAffinity,
    required Widget child,
  }) => Builder(
    key: key,
    builder: (context) => ListTileTheme(
      data: _mergeListTile(
        ListTileThemeData(
          dense: dense,
          shape: shape,
          style: style,
          selectedColor: selectedColor,
          iconColor: iconColor,
          textColor: textColor,
          titleTextStyle: titleTextStyle,
          subtitleTextStyle: subtitleTextStyle,
          leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
          contentPadding: contentPadding,
          tileColor: tileColor,
          selectedTileColor: selectedTileColor,
          enableFeedback: enableFeedback,
          horizontalTitleGap: horizontalTitleGap,
          minVerticalPadding: minVerticalPadding,
          minLeadingWidth: minLeadingWidth,
          minTileHeight: minTileHeight,
          titleAlignment: titleAlignment,
          mouseCursor: mouseCursor,
          visualDensity: visualDensity,
          controlAffinity: controlAffinity,
        ),
        ListTileTheme.of(context),
      ),
      child: child,
    ),
  );

  @override
  Widget wrap(BuildContext context, Widget child) =>
      ListTileTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ListTileTheme oldWidget) => data != oldWidget.data;
}

ListTileThemeData _mergeListTile(ListTileThemeData a, ListTileThemeData b) =>
    ListTileThemeData(
      dense: a.dense ?? b.dense,
      shape: a.shape ?? b.shape,
      style: a.style ?? b.style,
      selectedColor: a.selectedColor ?? b.selectedColor,
      iconColor: a.iconColor ?? b.iconColor,
      textColor: a.textColor ?? b.textColor,
      titleTextStyle: a.titleTextStyle ?? b.titleTextStyle,
      subtitleTextStyle: a.subtitleTextStyle ?? b.subtitleTextStyle,
      leadingAndTrailingTextStyle:
          a.leadingAndTrailingTextStyle ?? b.leadingAndTrailingTextStyle,
      contentPadding: a.contentPadding ?? b.contentPadding,
      tileColor: a.tileColor ?? b.tileColor,
      selectedTileColor: a.selectedTileColor ?? b.selectedTileColor,
      horizontalTitleGap: a.horizontalTitleGap ?? b.horizontalTitleGap,
      minVerticalPadding: a.minVerticalPadding ?? b.minVerticalPadding,
      minLeadingWidth: a.minLeadingWidth ?? b.minLeadingWidth,
      minTileHeight: a.minTileHeight ?? b.minTileHeight,
      enableFeedback: a.enableFeedback ?? b.enableFeedback,
      mouseCursor: a.mouseCursor ?? b.mouseCursor,
      visualDensity: a.visualDensity ?? b.visualDensity,
      titleAlignment: a.titleAlignment ?? b.titleAlignment,
      controlAffinity: a.controlAffinity ?? b.controlAffinity,
      isThreeLine: a.isThreeLine ?? b.isThreeLine,
    );

bool _isMobile(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.fuchsia ||
  TargetPlatform.iOS => true,
  _ => false,
};

Brightness _estimateBrightness(Color color) {
  final luminance = color.computeLuminance();
  return (luminance + 0.05) * (luminance + 0.05) > 0.15
      ? Brightness.light
      : Brightness.dark;
}

Map<Object, ThemeExtension<dynamic>> _extensionMap(
  Iterable<ThemeExtension<dynamic>> extensions,
) => {for (final extension in extensions) extension.type: extension};

class ThemeData {
  factory ThemeData({
    // General configuration.
    Object? adaptations,
    bool? applyElevationOverlayColor,
    NoDefaultCupertinoThemeData? cupertinoOverrideTheme,
    Iterable<ThemeExtension<dynamic>>? extensions,
    InputDecorationTheme? inputDecorationTheme,
    MaterialTapTargetSize? materialTapTargetSize,
    PageTransitionsTheme? pageTransitionsTheme,
    TargetPlatform? platform,
    ScrollbarThemeData? scrollbarTheme,
    InteractiveInkFeatureFactory? splashFactory,
    bool? useMaterial3,
    VisualDensity? visualDensity,
    // Color.
    ColorScheme? colorScheme,
    Brightness? brightness,
    Color? colorSchemeSeed,
    Color? canvasColor,
    Color? cardColor,
    Color? disabledColor,
    Color? dividerColor,
    Color? focusColor,
    Color? highlightColor,
    Color? hintColor,
    Color? hoverColor,
    Color? primaryColor,
    Color? primaryColorDark,
    Color? primaryColorLight,
    MaterialColor? primarySwatch,
    Color? scaffoldBackgroundColor,
    Color? secondaryHeaderColor,
    Color? shadowColor,
    Color? splashColor,
    Color? unselectedWidgetColor,
    // Typography and iconography.
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    IconThemeData? iconTheme,
    IconThemeData? primaryIconTheme,
    TextTheme? primaryTextTheme,
    TextTheme? textTheme,
    Typography? typography,
    // Component themes.
    ActionIconThemeData? actionIconTheme,
    AppBarTheme? appBarTheme,
    BadgeThemeData? badgeTheme,
    MaterialBannerThemeData? bannerTheme,
    BottomAppBarTheme? bottomAppBarTheme,
    BottomNavigationBarThemeData? bottomNavigationBarTheme,
    BottomSheetThemeData? bottomSheetTheme,
    ButtonThemeData? buttonTheme,
    Object? cardTheme,
    CheckboxThemeData? checkboxTheme,
    ChipThemeData? chipTheme,
    DataTableThemeData? dataTableTheme,
    DatePickerThemeData? datePickerTheme,
    Object? dialogTheme,
    DividerThemeData? dividerTheme,
    DrawerThemeData? drawerTheme,
    DropdownMenuThemeData? dropdownMenuTheme,
    ElevatedButtonThemeData? elevatedButtonTheme,
    ExpansionTileThemeData? expansionTileTheme,
    FilledButtonThemeData? filledButtonTheme,
    FloatingActionButtonThemeData? floatingActionButtonTheme,
    IconButtonThemeData? iconButtonTheme,
    ListTileThemeData? listTileTheme,
    MenuBarThemeData? menuBarTheme,
    MenuButtonThemeData? menuButtonTheme,
    MenuThemeData? menuTheme,
    NavigationBarThemeData? navigationBarTheme,
    NavigationDrawerThemeData? navigationDrawerTheme,
    NavigationRailThemeData? navigationRailTheme,
    OutlinedButtonThemeData? outlinedButtonTheme,
    PopupMenuThemeData? popupMenuTheme,
    ProgressIndicatorThemeData? progressIndicatorTheme,
    RadioThemeData? radioTheme,
    SearchBarThemeData? searchBarTheme,
    SearchViewThemeData? searchViewTheme,
    SegmentedButtonThemeData? segmentedButtonTheme,
    SliderThemeData? sliderTheme,
    SnackBarThemeData? snackBarTheme,
    SwitchThemeData? switchTheme,
    Object? tabBarTheme,
    TextButtonThemeData? textButtonTheme,
    TextSelectionThemeData? textSelectionTheme,
    TimePickerThemeData? timePickerTheme,
    ToggleButtonsThemeData? toggleButtonsTheme,
    TooltipThemeData? tooltipTheme,
    // Deprecated colors.
    @Deprecated('Use DialogThemeData.backgroundColor instead.')
    Color? dialogBackgroundColor,
    @Deprecated('Use TabBarThemeData.indicatorColor instead.')
    Color? indicatorColor,
  }) {
    if (colorScheme != null && colorSchemeSeed != null)
      throw ArgumentError('Use either colorScheme or colorSchemeSeed.');
    final effectiveBrightness =
        brightness ?? colorScheme?.brightness ?? Brightness.light;
    final dark = effectiveBrightness == Brightness.dark;
    final m3 = useMaterial3 ?? true;
    final targetPlatform = platform ?? defaultTargetPlatform;
    final swatch = primarySwatch ?? Colors.blue;
    final ColorScheme scheme =
        colorScheme ??
        (colorSchemeSeed != null
            ? ColorScheme.fromSeed(
                seedColor: colorSchemeSeed,
                brightness: effectiveBrightness,
              )
            : m3
            ? (dark ? const ColorScheme.dark() : const ColorScheme())
            : ColorScheme.fromSwatch(
                primarySwatch: swatch,
                brightness: effectiveBrightness,
              ));
    final primary =
        primaryColor ??
        (m3
            ? (dark ? scheme.surface : scheme.primary)
            : (dark ? Colors.grey[900]! : swatch));
    final primaryIsDark = _estimateBrightness(primary) == Brightness.dark;
    final types =
        typography ??
        Typography.material2021(platform: targetPlatform, colorScheme: scheme);
    var text = TextTheme.material3.merge(textTheme);
    var primaryText = (primaryIsDark ? types.white : types.black).merge(
      primaryTextTheme,
    );
    if (fontFamily != null || fontFamilyFallback != null) {
      text = text.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      );
      primaryText = primaryText.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      );
    }
    return ThemeData.raw(
      adaptationMap: const {},
      applyElevationOverlayColor: applyElevationOverlayColor ?? false,
      cupertinoOverrideTheme: cupertinoOverrideTheme,
      extensions: _extensionMap(extensions ?? const []),
      inputDecorationTheme:
          inputDecorationTheme ?? const InputDecorationTheme(),
      materialTapTargetSize:
          materialTapTargetSize ??
          (_isMobile(targetPlatform)
              ? MaterialTapTargetSize.padded
              : MaterialTapTargetSize.shrinkWrap),
      pageTransitionsTheme:
          pageTransitionsTheme ?? const PageTransitionsTheme(),
      platform: targetPlatform,
      scrollbarTheme: scrollbarTheme ?? const ScrollbarThemeData(),
      splashFactory:
          splashFactory ??
          (m3 ? InkRipple.splashFactory : InkSplash.splashFactory),
      useMaterial3: m3,
      visualDensity:
          visualDensity ??
          VisualDensity.defaultDensityForPlatform(targetPlatform),
      colorScheme: scheme,
      brightness: effectiveBrightness,
      canvasColor: canvasColor ?? scheme.surface,
      cardColor: cardColor ?? scheme.surfaceContainerLow,
      disabledColor: disabledColor ?? scheme.onSurface.withValues(alpha: 0.38),
      dividerColor: dividerColor ?? scheme.outlineVariant,
      focusColor: focusColor ?? (dark ? Colors.white12 : Colors.black12),
      highlightColor:
          highlightColor ??
          (dark ? const Color(0x40cccccc) : const Color(0x66bcbcbc)),
      hintColor: hintColor ?? scheme.onSurfaceVariant,
      hoverColor:
          hoverColor ??
          (dark ? const Color(0x0affffff) : const Color(0x0a000000)),
      primaryColor: primary,
      primaryColorDark:
          primaryColorDark ?? (dark ? Colors.black : swatch[700]!),
      primaryColorLight:
          primaryColorLight ?? (dark ? Colors.grey[500]! : swatch[100]!),
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? scheme.surface,
      secondaryHeaderColor:
          secondaryHeaderColor ?? (dark ? Colors.grey[700]! : swatch[50]!),
      shadowColor: shadowColor ?? Colors.black,
      splashColor:
          splashColor ??
          (dark ? const Color(0x40cccccc) : const Color(0x66c8c8c8)),
      unselectedWidgetColor:
          unselectedWidgetColor ?? (dark ? Colors.white70 : Colors.black54),
      iconTheme: iconTheme ?? IconThemeData(color: scheme.onSurface, size: 24),
      primaryIconTheme:
          primaryIconTheme ??
          IconThemeData(
            color: primaryIsDark ? Colors.white : Colors.black,
            size: 24,
          ),
      primaryTextTheme: primaryText,
      textTheme: text,
      typography: types,
      actionIconTheme: actionIconTheme,
      appBarTheme: appBarTheme ?? const AppBarTheme(),
      badgeTheme: badgeTheme ?? const BadgeThemeData(),
      bannerTheme: bannerTheme ?? const MaterialBannerThemeData(),
      bottomAppBarTheme: bottomAppBarTheme ?? const BottomAppBarTheme(),
      bottomNavigationBarTheme:
          bottomNavigationBarTheme ?? const BottomNavigationBarThemeData(),
      bottomSheetTheme: bottomSheetTheme ?? const BottomSheetThemeData(),
      buttonTheme: buttonTheme ?? const ButtonThemeData(),
      cardTheme: _cardThemeData(cardTheme),
      checkboxTheme: checkboxTheme ?? const CheckboxThemeData(),
      chipTheme: chipTheme ?? const ChipThemeData(),
      dataTableTheme: dataTableTheme ?? const DataTableThemeData(),
      datePickerTheme: datePickerTheme ?? const DatePickerThemeData(),
      dialogTheme: _dialogThemeData(dialogTheme),
      dividerTheme: dividerTheme ?? const DividerThemeData(),
      drawerTheme: drawerTheme ?? const DrawerThemeData(),
      dropdownMenuTheme: dropdownMenuTheme ?? const DropdownMenuThemeData(),
      elevatedButtonTheme:
          elevatedButtonTheme ?? const ElevatedButtonThemeData(),
      expansionTileTheme: expansionTileTheme ?? const ExpansionTileThemeData(),
      filledButtonTheme: filledButtonTheme ?? const FilledButtonThemeData(),
      floatingActionButtonTheme:
          floatingActionButtonTheme ?? const FloatingActionButtonThemeData(),
      iconButtonTheme: iconButtonTheme ?? const IconButtonThemeData(),
      listTileTheme: listTileTheme ?? const ListTileThemeData(),
      menuBarTheme: menuBarTheme ?? const MenuBarThemeData(),
      menuButtonTheme: menuButtonTheme ?? const MenuButtonThemeData(),
      menuTheme: menuTheme ?? const MenuThemeData(),
      navigationBarTheme: navigationBarTheme ?? const NavigationBarThemeData(),
      navigationDrawerTheme:
          navigationDrawerTheme ?? const NavigationDrawerThemeData(),
      navigationRailTheme:
          navigationRailTheme ?? const NavigationRailThemeData(),
      outlinedButtonTheme:
          outlinedButtonTheme ?? const OutlinedButtonThemeData(),
      popupMenuTheme: popupMenuTheme ?? const PopupMenuThemeData(),
      progressIndicatorTheme:
          progressIndicatorTheme ?? const ProgressIndicatorThemeData(),
      radioTheme: radioTheme ?? const RadioThemeData(),
      searchBarTheme: searchBarTheme ?? const SearchBarThemeData(),
      searchViewTheme: searchViewTheme ?? const SearchViewThemeData(),
      segmentedButtonTheme:
          segmentedButtonTheme ?? const SegmentedButtonThemeData(),
      sliderTheme: sliderTheme ?? const SliderThemeData(),
      snackBarTheme: snackBarTheme ?? const SnackBarThemeData(),
      switchTheme: switchTheme ?? const SwitchThemeData(),
      tabBarTheme: _tabBarThemeData(tabBarTheme),
      textButtonTheme: textButtonTheme ?? const TextButtonThemeData(),
      textSelectionTheme: textSelectionTheme ?? const TextSelectionThemeData(),
      timePickerTheme: timePickerTheme ?? const TimePickerThemeData(),
      toggleButtonsTheme: toggleButtonsTheme ?? const ToggleButtonsThemeData(),
      tooltipTheme: tooltipTheme ?? const TooltipThemeData(),
      dialogBackgroundColor: dialogBackgroundColor,
      indicatorColor: indicatorColor,
    );
  }

  /// A theme built from [colorScheme], as Flutter's `ThemeData.from`.
  factory ThemeData.from({
    required ColorScheme colorScheme,
    TextTheme? textTheme,
    bool? useMaterial3,
  }) => ThemeData(
    colorScheme: colorScheme,
    brightness: colorScheme.brightness,
    textTheme: textTheme,
    useMaterial3: useMaterial3,
  );
  factory ThemeData.light({bool? useMaterial3}) =>
      ThemeData(brightness: Brightness.light, useMaterial3: useMaterial3);
  factory ThemeData.dark({bool? useMaterial3}) =>
      ThemeData(brightness: Brightness.dark, useMaterial3: useMaterial3);
  factory ThemeData.fallback({bool? useMaterial3}) =>
      ThemeData.light(useMaterial3: useMaterial3);

  /// Every value explicit, as Flutter's `ThemeData.raw`. The deprecated
  /// dialog and indicator colors default from the color scheme.
  ThemeData.raw({
    Map<Type, Object>? adaptationMap,
    required this.applyElevationOverlayColor,
    this.cupertinoOverrideTheme,
    required this.extensions,
    required this.inputDecorationTheme,
    required this.materialTapTargetSize,
    required this.pageTransitionsTheme,
    required this.platform,
    required this.scrollbarTheme,
    required this.splashFactory,
    required this.useMaterial3,
    required this.visualDensity,
    required this.colorScheme,
    Brightness? brightness,
    required this.canvasColor,
    required this.cardColor,
    required this.disabledColor,
    required this.dividerColor,
    required this.focusColor,
    required this.highlightColor,
    required this.hintColor,
    required this.hoverColor,
    required this.primaryColor,
    required this.primaryColorDark,
    required this.primaryColorLight,
    required this.scaffoldBackgroundColor,
    required this.secondaryHeaderColor,
    required this.shadowColor,
    required this.splashColor,
    required this.unselectedWidgetColor,
    required this.iconTheme,
    required this.primaryIconTheme,
    required this.primaryTextTheme,
    required this.textTheme,
    required this.typography,
    this.actionIconTheme,
    required this.appBarTheme,
    required this.badgeTheme,
    required this.bannerTheme,
    required this.bottomAppBarTheme,
    required this.bottomNavigationBarTheme,
    required this.bottomSheetTheme,
    required this.buttonTheme,
    required this.cardTheme,
    required this.checkboxTheme,
    required this.chipTheme,
    required this.dataTableTheme,
    required this.datePickerTheme,
    required this.dialogTheme,
    required this.dividerTheme,
    required this.drawerTheme,
    required this.dropdownMenuTheme,
    required this.elevatedButtonTheme,
    required this.expansionTileTheme,
    required this.filledButtonTheme,
    required this.floatingActionButtonTheme,
    required this.iconButtonTheme,
    required this.listTileTheme,
    required this.menuBarTheme,
    required this.menuButtonTheme,
    required this.menuTheme,
    required this.navigationBarTheme,
    required this.navigationDrawerTheme,
    required this.navigationRailTheme,
    required this.outlinedButtonTheme,
    required this.popupMenuTheme,
    required this.progressIndicatorTheme,
    required this.radioTheme,
    required this.searchBarTheme,
    required this.searchViewTheme,
    required this.segmentedButtonTheme,
    required this.sliderTheme,
    required this.snackBarTheme,
    required this.switchTheme,
    required this.tabBarTheme,
    required this.textButtonTheme,
    required this.textSelectionTheme,
    required this.timePickerTheme,
    required this.toggleButtonsTheme,
    required this.tooltipTheme,
    Color? dialogBackgroundColor,
    Color? indicatorColor,
  }) : adaptationMap = adaptationMap ?? const {},
       _dialogBackgroundColor =
           dialogBackgroundColor ?? colorScheme.surfaceContainerHigh,
       _indicatorColor =
           indicatorColor ??
           (colorScheme.brightness == Brightness.dark
               ? colorScheme.onSurface
               : colorScheme.onPrimary);

  final Map<Type, Object> adaptationMap;
  final bool applyElevationOverlayColor;
  final NoDefaultCupertinoThemeData? cupertinoOverrideTheme;
  final Map<Object, ThemeExtension<dynamic>> extensions;
  final InputDecorationTheme inputDecorationTheme;
  final MaterialTapTargetSize materialTapTargetSize;
  final PageTransitionsTheme pageTransitionsTheme;
  final TargetPlatform platform;
  final ScrollbarThemeData scrollbarTheme;
  final InteractiveInkFeatureFactory splashFactory;
  final bool useMaterial3;
  final VisualDensity visualDensity;
  final ColorScheme colorScheme;
  final Color canvasColor, cardColor, disabledColor, dividerColor;
  final Color focusColor, highlightColor, hintColor, hoverColor;
  final Color primaryColor, primaryColorDark, primaryColorLight;
  final Color scaffoldBackgroundColor, secondaryHeaderColor, shadowColor;
  final Color splashColor, unselectedWidgetColor;
  final IconThemeData iconTheme, primaryIconTheme;
  final TextTheme primaryTextTheme, textTheme;
  final Typography typography;
  final ActionIconThemeData? actionIconTheme;
  final AppBarTheme appBarTheme;
  final BadgeThemeData badgeTheme;
  final MaterialBannerThemeData bannerTheme;
  final BottomAppBarTheme bottomAppBarTheme;
  final BottomNavigationBarThemeData bottomNavigationBarTheme;
  final BottomSheetThemeData bottomSheetTheme;
  final ButtonThemeData buttonTheme;
  final CardThemeData cardTheme;
  final CheckboxThemeData checkboxTheme;
  final ChipThemeData chipTheme;
  final DataTableThemeData dataTableTheme;
  final DatePickerThemeData datePickerTheme;
  final DialogThemeData dialogTheme;
  final DividerThemeData dividerTheme;
  final DrawerThemeData drawerTheme;
  final DropdownMenuThemeData dropdownMenuTheme;
  final ElevatedButtonThemeData elevatedButtonTheme;
  final ExpansionTileThemeData expansionTileTheme;
  final FilledButtonThemeData filledButtonTheme;
  final FloatingActionButtonThemeData floatingActionButtonTheme;
  final IconButtonThemeData iconButtonTheme;
  final ListTileThemeData listTileTheme;
  final MenuBarThemeData menuBarTheme;
  final MenuButtonThemeData menuButtonTheme;
  final MenuThemeData menuTheme;
  final NavigationBarThemeData navigationBarTheme;
  final NavigationDrawerThemeData navigationDrawerTheme;
  final NavigationRailThemeData navigationRailTheme;
  final OutlinedButtonThemeData outlinedButtonTheme;
  final PopupMenuThemeData popupMenuTheme;
  final ProgressIndicatorThemeData progressIndicatorTheme;
  final RadioThemeData radioTheme;
  final SearchBarThemeData searchBarTheme;
  final SearchViewThemeData searchViewTheme;
  final SegmentedButtonThemeData segmentedButtonTheme;
  final SliderThemeData sliderTheme;
  final SnackBarThemeData snackBarTheme;
  final SwitchThemeData switchTheme;
  final TabBarThemeData tabBarTheme;
  final TextButtonThemeData textButtonTheme;
  final TextSelectionThemeData textSelectionTheme;
  final TimePickerThemeData timePickerTheme;
  final ToggleButtonsThemeData toggleButtonsTheme;
  final TooltipThemeData tooltipTheme;
  final Color _dialogBackgroundColor, _indicatorColor;

  Brightness get brightness => colorScheme.brightness;
  @Deprecated('Use DialogThemeData.backgroundColor instead.')
  Color get dialogBackgroundColor => _dialogBackgroundColor;
  @Deprecated('Use TabBarThemeData.indicatorColor instead.')
  Color get indicatorColor => _indicatorColor;

  T? extension<T>() => extensions[T] as T?;

  /// Flutter's adaptation lookup; the DOM runtime registers none.
  T? getAdaptation<T>() => adaptationMap[T] as T?;

  static Brightness estimateBrightnessForColor(Color color) =>
      _estimateBrightness(color);

  /// Snaps at the midpoint instead of interpolating every property.
  static ThemeData lerp(ThemeData a, ThemeData b, double t) => t < 0.5 ? a : b;

  /// As Flutter's `ThemeData.localize`; text geometry is not localized.
  static ThemeData localize(ThemeData baseTheme, TextTheme localTextGeometry) =>
      baseTheme.copyWith(
        textTheme: localTextGeometry.merge(baseTheme.textTheme),
        primaryTextTheme: localTextGeometry.merge(baseTheme.primaryTextTheme),
      );

  ThemeData copyWith({
    Object? adaptations,
    bool? applyElevationOverlayColor,
    NoDefaultCupertinoThemeData? cupertinoOverrideTheme,
    Iterable<ThemeExtension<dynamic>>? extensions,
    InputDecorationTheme? inputDecorationTheme,
    MaterialTapTargetSize? materialTapTargetSize,
    PageTransitionsTheme? pageTransitionsTheme,
    TargetPlatform? platform,
    ScrollbarThemeData? scrollbarTheme,
    InteractiveInkFeatureFactory? splashFactory,
    bool? useMaterial3,
    VisualDensity? visualDensity,
    ColorScheme? colorScheme,
    Brightness? brightness,
    Color? canvasColor,
    Color? cardColor,
    Color? disabledColor,
    Color? dividerColor,
    Color? focusColor,
    Color? highlightColor,
    Color? hintColor,
    Color? hoverColor,
    Color? primaryColor,
    Color? primaryColorDark,
    Color? primaryColorLight,
    Color? scaffoldBackgroundColor,
    Color? secondaryHeaderColor,
    Color? shadowColor,
    Color? splashColor,
    Color? unselectedWidgetColor,
    IconThemeData? iconTheme,
    IconThemeData? primaryIconTheme,
    TextTheme? primaryTextTheme,
    TextTheme? textTheme,
    Typography? typography,
    ActionIconThemeData? actionIconTheme,
    AppBarTheme? appBarTheme,
    BadgeThemeData? badgeTheme,
    MaterialBannerThemeData? bannerTheme,
    BottomAppBarTheme? bottomAppBarTheme,
    BottomNavigationBarThemeData? bottomNavigationBarTheme,
    BottomSheetThemeData? bottomSheetTheme,
    ButtonThemeData? buttonTheme,
    Object? cardTheme,
    CheckboxThemeData? checkboxTheme,
    ChipThemeData? chipTheme,
    DataTableThemeData? dataTableTheme,
    DatePickerThemeData? datePickerTheme,
    Object? dialogTheme,
    DividerThemeData? dividerTheme,
    DrawerThemeData? drawerTheme,
    DropdownMenuThemeData? dropdownMenuTheme,
    ElevatedButtonThemeData? elevatedButtonTheme,
    ExpansionTileThemeData? expansionTileTheme,
    FilledButtonThemeData? filledButtonTheme,
    FloatingActionButtonThemeData? floatingActionButtonTheme,
    IconButtonThemeData? iconButtonTheme,
    ListTileThemeData? listTileTheme,
    MenuBarThemeData? menuBarTheme,
    MenuButtonThemeData? menuButtonTheme,
    MenuThemeData? menuTheme,
    NavigationBarThemeData? navigationBarTheme,
    NavigationDrawerThemeData? navigationDrawerTheme,
    NavigationRailThemeData? navigationRailTheme,
    OutlinedButtonThemeData? outlinedButtonTheme,
    PopupMenuThemeData? popupMenuTheme,
    ProgressIndicatorThemeData? progressIndicatorTheme,
    RadioThemeData? radioTheme,
    SearchBarThemeData? searchBarTheme,
    SearchViewThemeData? searchViewTheme,
    SegmentedButtonThemeData? segmentedButtonTheme,
    SliderThemeData? sliderTheme,
    SnackBarThemeData? snackBarTheme,
    SwitchThemeData? switchTheme,
    Object? tabBarTheme,
    TextButtonThemeData? textButtonTheme,
    TextSelectionThemeData? textSelectionTheme,
    TimePickerThemeData? timePickerTheme,
    ToggleButtonsThemeData? toggleButtonsTheme,
    TooltipThemeData? tooltipTheme,
    @Deprecated('Use DialogThemeData.backgroundColor instead.')
    Color? dialogBackgroundColor,
    @Deprecated('Use TabBarThemeData.indicatorColor instead.')
    Color? indicatorColor,
  }) {
    final scheme = (colorScheme ?? this.colorScheme).copyWith(
      brightness: brightness,
    );
    return ThemeData.raw(
      adaptationMap: adaptationMap,
      applyElevationOverlayColor:
          applyElevationOverlayColor ?? this.applyElevationOverlayColor,
      cupertinoOverrideTheme:
          cupertinoOverrideTheme ?? this.cupertinoOverrideTheme,
      extensions: extensions == null
          ? this.extensions
          : _extensionMap(extensions),
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      materialTapTargetSize:
          materialTapTargetSize ?? this.materialTapTargetSize,
      pageTransitionsTheme: pageTransitionsTheme ?? this.pageTransitionsTheme,
      platform: platform ?? this.platform,
      scrollbarTheme: scrollbarTheme ?? this.scrollbarTheme,
      splashFactory: splashFactory ?? this.splashFactory,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      visualDensity: visualDensity ?? this.visualDensity,
      colorScheme: scheme,
      canvasColor: canvasColor ?? this.canvasColor,
      cardColor: cardColor ?? this.cardColor,
      disabledColor: disabledColor ?? this.disabledColor,
      dividerColor: dividerColor ?? this.dividerColor,
      focusColor: focusColor ?? this.focusColor,
      highlightColor: highlightColor ?? this.highlightColor,
      hintColor: hintColor ?? this.hintColor,
      hoverColor: hoverColor ?? this.hoverColor,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryColorDark: primaryColorDark ?? this.primaryColorDark,
      primaryColorLight: primaryColorLight ?? this.primaryColorLight,
      scaffoldBackgroundColor:
          scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      secondaryHeaderColor: secondaryHeaderColor ?? this.secondaryHeaderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      splashColor: splashColor ?? this.splashColor,
      unselectedWidgetColor:
          unselectedWidgetColor ?? this.unselectedWidgetColor,
      iconTheme: iconTheme ?? this.iconTheme,
      primaryIconTheme: primaryIconTheme ?? this.primaryIconTheme,
      primaryTextTheme: primaryTextTheme ?? this.primaryTextTheme,
      textTheme: textTheme ?? this.textTheme,
      typography: typography ?? this.typography,
      actionIconTheme: actionIconTheme ?? this.actionIconTheme,
      appBarTheme: appBarTheme ?? this.appBarTheme,
      badgeTheme: badgeTheme ?? this.badgeTheme,
      bannerTheme: bannerTheme ?? this.bannerTheme,
      bottomAppBarTheme: bottomAppBarTheme ?? this.bottomAppBarTheme,
      bottomNavigationBarTheme:
          bottomNavigationBarTheme ?? this.bottomNavigationBarTheme,
      bottomSheetTheme: bottomSheetTheme ?? this.bottomSheetTheme,
      buttonTheme: buttonTheme ?? this.buttonTheme,
      cardTheme: cardTheme == null ? this.cardTheme : _cardThemeData(cardTheme),
      checkboxTheme: checkboxTheme ?? this.checkboxTheme,
      chipTheme: chipTheme ?? this.chipTheme,
      dataTableTheme: dataTableTheme ?? this.dataTableTheme,
      datePickerTheme: datePickerTheme ?? this.datePickerTheme,
      dialogTheme: dialogTheme == null
          ? this.dialogTheme
          : _dialogThemeData(dialogTheme),
      dividerTheme: dividerTheme ?? this.dividerTheme,
      drawerTheme: drawerTheme ?? this.drawerTheme,
      dropdownMenuTheme: dropdownMenuTheme ?? this.dropdownMenuTheme,
      elevatedButtonTheme: elevatedButtonTheme ?? this.elevatedButtonTheme,
      expansionTileTheme: expansionTileTheme ?? this.expansionTileTheme,
      filledButtonTheme: filledButtonTheme ?? this.filledButtonTheme,
      floatingActionButtonTheme:
          floatingActionButtonTheme ?? this.floatingActionButtonTheme,
      iconButtonTheme: iconButtonTheme ?? this.iconButtonTheme,
      listTileTheme: listTileTheme ?? this.listTileTheme,
      menuBarTheme: menuBarTheme ?? this.menuBarTheme,
      menuButtonTheme: menuButtonTheme ?? this.menuButtonTheme,
      menuTheme: menuTheme ?? this.menuTheme,
      navigationBarTheme: navigationBarTheme ?? this.navigationBarTheme,
      navigationDrawerTheme:
          navigationDrawerTheme ?? this.navigationDrawerTheme,
      navigationRailTheme: navigationRailTheme ?? this.navigationRailTheme,
      outlinedButtonTheme: outlinedButtonTheme ?? this.outlinedButtonTheme,
      popupMenuTheme: popupMenuTheme ?? this.popupMenuTheme,
      progressIndicatorTheme:
          progressIndicatorTheme ?? this.progressIndicatorTheme,
      radioTheme: radioTheme ?? this.radioTheme,
      searchBarTheme: searchBarTheme ?? this.searchBarTheme,
      searchViewTheme: searchViewTheme ?? this.searchViewTheme,
      segmentedButtonTheme: segmentedButtonTheme ?? this.segmentedButtonTheme,
      sliderTheme: sliderTheme ?? this.sliderTheme,
      snackBarTheme: snackBarTheme ?? this.snackBarTheme,
      switchTheme: switchTheme ?? this.switchTheme,
      tabBarTheme: tabBarTheme == null
          ? this.tabBarTheme
          : _tabBarThemeData(tabBarTheme),
      textButtonTheme: textButtonTheme ?? this.textButtonTheme,
      textSelectionTheme: textSelectionTheme ?? this.textSelectionTheme,
      timePickerTheme: timePickerTheme ?? this.timePickerTheme,
      toggleButtonsTheme: toggleButtonsTheme ?? this.toggleButtonsTheme,
      tooltipTheme: tooltipTheme ?? this.tooltipTheme,
      dialogBackgroundColor: dialogBackgroundColor ?? _dialogBackgroundColor,
      indicatorColor: indicatorColor ?? _indicatorColor,
    );
  }
}
