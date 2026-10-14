part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Cupertino widgets: iOS-styled counterparts on the same DOM primitives as
// the Material widgets (native buttons, inputs and selects), with iOS
// colors, radii and type sizes. `package:flutter/cupertino.dart` maps to
// the same runtime library as Material.

/// A color with light and dark variants, resolved against the ambient
/// brightness.
class CupertinoDynamicColor extends Color {
  const CupertinoDynamicColor({
    required this.color,
    required this.darkColor,
    Color? highContrastColor,
    Color? darkHighContrastColor,
    Color? elevatedColor,
    Color? darkElevatedColor,
    Color? highContrastElevatedColor,
    Color? darkHighContrastElevatedColor,
  }) : super(0);
  const CupertinoDynamicColor.withBrightness({
    required this.color,
    required this.darkColor,
  }) : super(0);
  const CupertinoDynamicColor.withBrightnessAndContrast({
    required this.color,
    required this.darkColor,
    required Color highContrastColor,
    required Color darkHighContrastColor,
  }) : super(0);
  final Color color, darkColor;

  @override
  int get value => color.value;

  CupertinoDynamicColor resolveFrom(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final chosen = dark ? darkColor : color;
    return CupertinoDynamicColor.withBrightness(
      color: chosen,
      darkColor: chosen,
    );
  }

  static Color resolve(Color resolvable, BuildContext context) =>
      resolvable is CupertinoDynamicColor
      ? resolvable.resolveFrom(context).color
      : resolvable;

  static Color? maybeResolve(Color? resolvable, BuildContext context) =>
      resolvable == null ? null : resolve(resolvable, context);
}

abstract final class CupertinoColors {
  static const activeBlue = systemBlue;
  static const activeGreen = systemGreen;
  static const activeOrange = systemOrange;
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const lightBackgroundGray = Color(0xFFE5E5EA);
  static const extraLightBackgroundGray = Color(0xFFEFEFF4);
  static const darkBackgroundGray = Color(0xFF171717);
  static const inactiveGray = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF999999),
    darkColor: Color(0xFF757575),
  );
  static const destructiveRed = systemRed;
  static const transparent = Color(0x00000000);
  static const systemBlue = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF007AFF),
    darkColor: Color(0xFF0A84FF),
  );
  static const systemGreen = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF34C759),
    darkColor: Color(0xFF30D158),
  );
  static const systemMint = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF00C7BE),
    darkColor: Color(0xFF63E6E2),
  );
  static const systemIndigo = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF5856D6),
    darkColor: Color(0xFF5E5CE6),
  );
  static const systemOrange = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF9500),
    darkColor: Color(0xFFFF9F0A),
  );
  static const systemPink = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF2D55),
    darkColor: Color(0xFFFF375F),
  );
  static const systemBrown = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFA2845E),
    darkColor: Color(0xFFAC8E68),
  );
  static const systemPurple = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFAF52DE),
    darkColor: Color(0xFFBF5AF2),
  );
  static const systemRed = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF3B30),
    darkColor: Color(0xFFFF453A),
  );
  static const systemTeal = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF5AC8FA),
    darkColor: Color(0xFF64D2FF),
  );
  static const systemCyan = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF32ADE6),
    darkColor: Color(0xFF64D2FF),
  );
  static const systemYellow = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFCC00),
    darkColor: Color(0xFFFFD60A),
  );
  static const systemGrey = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF8E8E93),
    darkColor: Color(0xFF8E8E93),
  );
  static const systemGrey2 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFAEAEB2),
    darkColor: Color(0xFF636366),
  );
  static const systemGrey3 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFC7C7CC),
    darkColor: Color(0xFF48484A),
  );
  static const systemGrey4 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFD1D1D6),
    darkColor: Color(0xFF3A3A3C),
  );
  static const systemGrey5 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFE5E5EA),
    darkColor: Color(0xFF2C2C2E),
  );
  static const systemGrey6 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF1C1C1E),
  );
  static const label = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF000000),
    darkColor: Color(0xFFFFFFFF),
  );
  static const secondaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0x993C3C43),
    darkColor: Color(0x99EBEBF5),
  );
  static const tertiaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0x4C3C3C43),
    darkColor: Color(0x4CEBEBF5),
  );
  static const quaternaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0x2D3C3C43),
    darkColor: Color(0x29EBEBF5),
  );
  static const placeholderText = tertiaryLabel;
  static const link = systemBlue;
  static const separator = CupertinoDynamicColor.withBrightness(
    color: Color(0x493C3C43),
    darkColor: Color(0x99545458),
  );
  static const opaqueSeparator = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFC6C6C8),
    darkColor: Color(0xFF38383A),
  );
  static const systemFill = CupertinoDynamicColor.withBrightness(
    color: Color(0x33787880),
    darkColor: Color(0x5C787880),
  );
  static const secondarySystemFill = CupertinoDynamicColor.withBrightness(
    color: Color(0x28787880),
    darkColor: Color(0x51787880),
  );
  static const tertiarySystemFill = CupertinoDynamicColor.withBrightness(
    color: Color(0x1E767680),
    darkColor: Color(0x3D767680),
  );
  static const quaternarySystemFill = CupertinoDynamicColor.withBrightness(
    color: Color(0x14747480),
    darkColor: Color(0x2D767680),
  );
  static const systemBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF000000),
  );
  static const secondarySystemBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF1C1C1E),
  );
  static const tertiarySystemBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF2C2C2E),
  );
  static const systemGroupedBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF000000),
  );
  static const secondarySystemGroupedBackground =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFFFFFFFF),
        darkColor: Color(0xFF1C1C1E),
      );
  static const tertiarySystemGroupedBackground =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFFF2F2F7),
        darkColor: Color(0xFF2C2C2E),
      );
}

Color _cupertinoResolve(Color color, BuildContext context) =>
    CupertinoDynamicColor.resolve(color, context);

class CupertinoTextThemeData {
  const CupertinoTextThemeData({
    this.primaryColor = CupertinoColors.systemBlue,
    TextStyle? textStyle,
    TextStyle? actionTextStyle,
    TextStyle? actionSmallTextStyle,
    TextStyle? tabLabelTextStyle,
    TextStyle? navTitleTextStyle,
    TextStyle? navLargeTitleTextStyle,
    TextStyle? navActionTextStyle,
    TextStyle? pickerTextStyle,
    TextStyle? dateTimePickerTextStyle,
  }) : _textStyle = textStyle,
       _actionTextStyle = actionTextStyle,
       _tabLabelTextStyle = tabLabelTextStyle,
       _navTitleTextStyle = navTitleTextStyle,
       _navLargeTitleTextStyle = navLargeTitleTextStyle,
       _navActionTextStyle = navActionTextStyle,
       _pickerTextStyle = pickerTextStyle,
       _dateTimePickerTextStyle = dateTimePickerTextStyle;
  final Color primaryColor;
  final TextStyle? _textStyle, _actionTextStyle, _tabLabelTextStyle;
  final TextStyle? _navTitleTextStyle, _navLargeTitleTextStyle;
  final TextStyle? _navActionTextStyle, _pickerTextStyle;
  final TextStyle? _dateTimePickerTextStyle;

  static const _base = TextStyle(
    fontFamily: 'CupertinoSystemText',
    fontFamilyFallback: ['-apple-system', 'BlinkMacSystemFont', 'system-ui'],
    fontSize: 17,
    letterSpacing: -0.41,
    color: CupertinoColors.label,
  );
  TextStyle get textStyle => _textStyle ?? _base;
  TextStyle get actionTextStyle =>
      _actionTextStyle ?? _base.copyWith(color: primaryColor);
  TextStyle get actionSmallTextStyle => actionTextStyle.copyWith(fontSize: 15);
  TextStyle get tabLabelTextStyle =>
      _tabLabelTextStyle ??
      _base.copyWith(
        fontSize: 10,
        letterSpacing: -0.24,
        color: CupertinoColors.inactiveGray,
      );
  TextStyle get navTitleTextStyle =>
      _navTitleTextStyle ?? _base.copyWith(fontWeight: FontWeight.w600);
  TextStyle get navLargeTitleTextStyle =>
      _navLargeTitleTextStyle ??
      _base.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.41,
      );
  TextStyle get navActionTextStyle =>
      _navActionTextStyle ?? _base.copyWith(color: primaryColor);
  TextStyle get pickerTextStyle =>
      _pickerTextStyle ?? _base.copyWith(fontSize: 21, letterSpacing: -0.6);
  TextStyle get dateTimePickerTextStyle =>
      _dateTimePickerTextStyle ?? _base.copyWith(fontSize: 21);

  CupertinoTextThemeData copyWith({
    Color? primaryColor,
    TextStyle? textStyle,
    TextStyle? actionTextStyle,
    TextStyle? actionSmallTextStyle,
    TextStyle? tabLabelTextStyle,
    TextStyle? navTitleTextStyle,
    TextStyle? navLargeTitleTextStyle,
    TextStyle? navActionTextStyle,
    TextStyle? pickerTextStyle,
    TextStyle? dateTimePickerTextStyle,
  }) => CupertinoTextThemeData(
    primaryColor: primaryColor ?? this.primaryColor,
    textStyle: textStyle ?? _textStyle,
    actionTextStyle: actionTextStyle ?? _actionTextStyle,
    tabLabelTextStyle: tabLabelTextStyle ?? _tabLabelTextStyle,
    navTitleTextStyle: navTitleTextStyle ?? _navTitleTextStyle,
    navLargeTitleTextStyle: navLargeTitleTextStyle ?? _navLargeTitleTextStyle,
    navActionTextStyle: navActionTextStyle ?? _navActionTextStyle,
    pickerTextStyle: pickerTextStyle ?? _pickerTextStyle,
    dateTimePickerTextStyle:
        dateTimePickerTextStyle ?? _dateTimePickerTextStyle,
  );
}

class NoDefaultCupertinoThemeData {
  const NoDefaultCupertinoThemeData({
    this.brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
    this.applyThemeToAll,
  });
  final Brightness? brightness;
  final Color? primaryColor, primaryContrastingColor;
  final CupertinoTextThemeData? textTheme;
  final Color? barBackgroundColor, scaffoldBackgroundColor;
  final bool? applyThemeToAll;
}

class CupertinoThemeData extends NoDefaultCupertinoThemeData {
  const CupertinoThemeData({
    super.brightness,
    super.primaryColor,
    super.primaryContrastingColor,
    super.textTheme,
    super.barBackgroundColor,
    super.scaffoldBackgroundColor,
    super.applyThemeToAll,
  });
  const CupertinoThemeData.raw(
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
  ) : super(
        brightness: brightness,
        primaryColor: primaryColor,
        primaryContrastingColor: primaryContrastingColor,
        textTheme: textTheme,
        barBackgroundColor: barBackgroundColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        applyThemeToAll: applyThemeToAll,
      );

  CupertinoThemeData resolveFrom(BuildContext context) => this;

  CupertinoThemeData copyWith({
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
  }) => CupertinoThemeData(
    brightness: brightness ?? this.brightness,
    primaryColor: primaryColor ?? this.primaryColor,
    primaryContrastingColor:
        primaryContrastingColor ?? this.primaryContrastingColor,
    textTheme: textTheme ?? this.textTheme,
    barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
    scaffoldBackgroundColor:
        scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
    applyThemeToAll: applyThemeToAll ?? this.applyThemeToAll,
  );
}

/// Resolved Cupertino theme values, falling back to the Material theme.
class _CupertinoValues {
  _CupertinoValues(
    this.brightness,
    this.primary,
    this.text,
    this.bar,
    this.scaffold,
  );
  final Brightness brightness;
  final Color primary, bar, scaffold;
  final CupertinoTextThemeData text;
}

class CupertinoTheme extends StatelessWidget {
  const CupertinoTheme({super.key, required this.data, required this.child});
  final CupertinoThemeData data;
  final Widget child;

  static CupertinoThemeData of(BuildContext context) {
    final explicit = context
        .dependOnInheritedWidgetOfExactType<_CupertinoThemeScope>()
        ?.data;
    final values = _values(context);
    return CupertinoThemeData(
      brightness: explicit?.brightness ?? values.brightness,
      primaryColor: values.primary,
      primaryContrastingColor:
          explicit?.primaryContrastingColor ?? CupertinoColors.white,
      textTheme: values.text,
      barBackgroundColor: values.bar,
      scaffoldBackgroundColor: values.scaffold,
    );
  }

  static Brightness brightnessOf(BuildContext context) =>
      maybeBrightnessOf(context) ?? Brightness.light;

  static Brightness? maybeBrightnessOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_CupertinoThemeScope>()
          ?.data
          .brightness ??
      Theme.of(context).brightness;

  static _CupertinoValues _values(BuildContext context) {
    final explicit = context
        .dependOnInheritedWidgetOfExactType<_CupertinoThemeScope>()
        ?.data;
    final material = Theme.of(context);
    final brightness = explicit?.brightness ?? material.brightness;
    final dark = brightness == Brightness.dark;
    Color pick(Color? value, Color fallback) {
      final color = value ?? fallback;
      return color is CupertinoDynamicColor
          ? (dark ? color.darkColor : color.color)
          : color;
    }

    final primary = pick(explicit?.primaryColor, CupertinoColors.systemBlue);
    return _CupertinoValues(
      brightness,
      primary,
      (explicit?.textTheme ?? const CupertinoTextThemeData()).copyWith(
        primaryColor: primary,
      ),
      pick(
        explicit?.barBackgroundColor,
        const CupertinoDynamicColor.withBrightness(
          color: Color(0xF0F9F9F9),
          darkColor: Color(0xF01D1D1D),
        ),
      ),
      pick(explicit?.scaffoldBackgroundColor, CupertinoColors.systemBackground),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _CupertinoThemeScope(data: data, child: child);
}

class _CupertinoThemeScope extends InheritedWidget {
  const _CupertinoThemeScope({required this.data, required super.child});
  final CupertinoThemeData data;
  @override
  bool updateShouldNotify(_CupertinoThemeScope oldWidget) =>
      oldWidget.data != data;
}

TextStyle _cupertinoText(BuildContext context, {Color? color}) {
  final values = CupertinoTheme._values(context);
  final style = values.text.textStyle;
  final dark = values.brightness == Brightness.dark;
  return style.copyWith(
    color:
        color ??
        (style.color is CupertinoDynamicColor
            ? (dark
                  ? (style.color! as CupertinoDynamicColor).darkColor
                  : (style.color! as CupertinoDynamicColor).color)
            : style.color),
  );
}

// ---------------------------------------------------------------------------
// App and page structure.

/// Runs on the same app shell as [MaterialApp] with iOS defaults.
class CupertinoApp extends StatelessWidget {
  const CupertinoApp({
    super.key,
    this.navigatorKey,
    this.home,
    this.theme,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const [Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  }) : routerConfig = null;
  const CupertinoApp.router({
    super.key,
    this.routerConfig,
    this.theme,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const [Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  }) : navigatorKey = null,
       home = null,
       routes = const {},
       initialRoute = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorObservers = const [];
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? home;
  final CupertinoThemeData? theme;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute, onUnknownRoute;
  final List<NavigatorObserver> navigatorObservers;
  final TransitionBuilder? builder;
  final String title;
  final String Function(BuildContext context)? onGenerateTitle;
  final Color? color;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay, debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final ScrollBehavior? scrollBehavior;
  final Object? routerConfig;

  @override
  Widget build(BuildContext context) {
    final dark = theme?.brightness == Brightness.dark;
    final material = ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      colorSchemeSeed: null,
      scaffoldBackgroundColor: dark
          ? CupertinoColors.systemBackground.darkColor
          : CupertinoColors.systemBackground.color,
    );
    Widget wrap(BuildContext context, Widget? child) {
      final content = CupertinoTheme(
        data: theme ?? const CupertinoThemeData(),
        child: child ?? const SizedBox.shrink(),
      );
      return builder == null ? content : builder!(context, content);
    }

    final config = routerConfig;
    if (config != null) {
      return MaterialApp.router(
        routerConfig: config as RouterConfig<Object>,
        title: title,
        color: color,
        theme: material,
        builder: wrap,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        localeListResolutionCallback: localeListResolutionCallback,
        localeResolutionCallback: localeResolutionCallback,
        supportedLocales: supportedLocales,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      );
    }
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: home,
      routes: routes,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onUnknownRoute: onUnknownRoute,
      navigatorObservers: navigatorObservers,
      title: title,
      color: color,
      theme: material,
      builder: wrap,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    );
  }
}

abstract class ObstructingPreferredSizeWidget implements PreferredSizeWidget {
  bool shouldFullyObstruct(BuildContext context);
}

class CupertinoPageScaffold extends StatelessWidget {
  const CupertinoPageScaffold({
    super.key,
    this.navigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    required this.child,
  });
  final ObstructingPreferredSizeWidget? navigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: navigationBar,
    backgroundColor: _cupertinoResolve(
      backgroundColor ?? CupertinoTheme._values(context).scaffold,
      context,
    ),
    body: DefaultTextStyle(style: _cupertinoText(context), child: child),
  );
}

/// The iOS navigation bar: centered title, leading and trailing slots,
/// translucent background with a hairline border.
class CupertinoNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const CupertinoNavigationBar({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyMiddle = true,
    this.previousPageTitle,
    this.middle,
    this.trailing,
    this.border,
    this.backgroundColor,
    this.automaticBackgroundVisibility = true,
    this.enableBackgroundFilterBlur = true,
    this.brightness,
    this.padding,
    this.transitionBetweenRoutes = true,
    this.heroTag,
    this.bottom,
  });
  const CupertinoNavigationBar.large({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyMiddle = true,
    this.previousPageTitle,
    Widget? largeTitle,
    this.trailing,
    this.border,
    this.backgroundColor,
    this.automaticBackgroundVisibility = true,
    this.enableBackgroundFilterBlur = true,
    this.brightness,
    this.padding,
    this.transitionBetweenRoutes = true,
    this.heroTag,
    this.bottom,
  }) : middle = largeTitle;
  final Widget? leading, middle, trailing;
  final bool automaticallyImplyLeading, automaticallyImplyMiddle;
  final String? previousPageTitle;
  final Border? border;
  final Color? backgroundColor;
  final bool automaticBackgroundVisibility, enableBackgroundFilterBlur;
  final Brightness? brightness;
  final EdgeInsetsDirectional? padding;
  final bool transitionBetweenRoutes;
  final Object? heroTag;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(44 + (bottom?.preferredSize.height ?? 0));
  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    final values = CupertinoTheme._values(context);
    var leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        leadingWidget = CupertinoNavigationBarBackButton(
          previousPageTitle: previousPageTitle,
        );
      }
    }
    final background = _cupertinoResolve(
      backgroundColor ?? values.bar,
      context,
    );
    return _Box(
      tag: 'header',
      css:
          'position:sticky;top:0;z-index:2;box-sizing:border-box;display:flex;flex-direction:column;background-color:${colorCss(background)};${enableBackgroundFilterBlur ? 'backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);' : ''}border-bottom:${border == null ? '0.5px solid ${colorCss(_cupertinoResolve(CupertinoColors.separator, context))}' : '${px(border!.bottom.width)} solid ${colorCss(border!.bottom.color)}'};',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        _Box(
          css:
              'display:grid;grid-template-columns:1fr auto 1fr;align-items:center;min-height:44px;padding:0 ${px(padding?.start ?? 16)};gap:8px;',
          layout: _DomLayout.grid,
          fill: _Fill.expand,
          children: [
            _Box(
              css: 'justify-self:start;display:flex;align-items:center;',
              fill: _Fill.none,
              children: [
                DefaultTextStyle(
                  style: values.text.navActionTextStyle,
                  child: IconTheme.merge(
                    data: IconThemeData(color: values.primary),
                    child: leadingWidget ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            _Box(
              css: 'min-width:0;text-align:center;',
              attributes: const {'role': 'heading', 'aria-level': '1'},
              fill: _Fill.none,
              children: [
                DefaultTextStyle(
                  style: _cupertinoText(context)
                      .merge(values.text.navTitleTextStyle)
                      .copyWith(color: _cupertinoText(context).color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: middle ?? const SizedBox.shrink(),
                ),
              ],
            ),
            _Box(
              css: 'justify-self:end;display:flex;align-items:center;gap:8px;',
              fill: _Fill.none,
              children: [
                DefaultTextStyle(
                  style: values.text.navActionTextStyle,
                  child: IconTheme.merge(
                    data: IconThemeData(color: values.primary),
                    child: trailing ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ],
        ),
        ?bottom,
      ],
    );
  }
}

class CupertinoNavigationBarBackButton extends StatelessWidget {
  const CupertinoNavigationBarBackButton({
    super.key,
    this.color,
    this.previousPageTitle,
    this.onPressed,
  });
  final Color? color;
  final String? previousPageTitle;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed ?? () => Navigator.maybePop(context),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.back,
          color: color ?? CupertinoTheme._values(context).primary,
          semanticLabel: 'Back',
        ),
        if (previousPageTitle != null) Text(previousPageTitle!),
      ],
    ),
  );
}

/// The large-title navigation bar: a pinned bar over a large title that
/// scrolls away.
class CupertinoSliverNavigationBar extends StatelessWidget {
  const CupertinoSliverNavigationBar({
    super.key,
    this.largeTitle,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyTitle = true,
    this.alwaysShowMiddle = true,
    this.previousPageTitle,
    this.middle,
    this.trailing,
    this.border,
    this.backgroundColor,
    this.automaticBackgroundVisibility = true,
    this.enableBackgroundFilterBlur = true,
    this.brightness,
    this.padding,
    this.transitionBetweenRoutes = true,
    this.heroTag,
    this.stretch = false,
    this.bottom,
    this.bottomMode,
  });
  final Widget? largeTitle, leading, middle, trailing;
  final bool automaticallyImplyLeading, automaticallyImplyTitle;
  final bool alwaysShowMiddle, transitionBetweenRoutes, stretch;
  final bool automaticBackgroundVisibility, enableBackgroundFilterBlur;
  final String? previousPageTitle;
  final Border? border;
  final Color? backgroundColor;
  final Brightness? brightness;
  final EdgeInsetsDirectional? padding;
  final Object? heroTag, bottomMode;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverPersistentHeader(
        pinned: true,
        delegate: _CupertinoBarDelegate(
          CupertinoNavigationBar(
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            previousPageTitle: previousPageTitle,
            middle: alwaysShowMiddle ? (middle ?? largeTitle) : middle,
            trailing: trailing,
            border: border,
            backgroundColor: backgroundColor,
            enableBackgroundFilterBlur: enableBackgroundFilterBlur,
            padding: padding,
            bottom: bottom,
          ),
        ),
      ),
      if (largeTitle != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Builder(
            builder: (context) => DefaultTextStyle(
              style: CupertinoTheme._values(context).text.navLargeTitleTextStyle
                  .copyWith(color: _cupertinoText(context).color),
              child: largeTitle!,
            ),
          ),
        ),
    ],
  );
}

class _CupertinoBarDelegate extends SliverPersistentHeaderDelegate {
  _CupertinoBarDelegate(this.bar);
  final CupertinoNavigationBar bar;
  @override
  double get minExtent => bar.preferredSize.height;
  @override
  double get maxExtent => bar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) => bar;
  @override
  bool shouldRebuild(_CupertinoBarDelegate oldDelegate) =>
      oldDelegate.bar != bar;
}

// ---------------------------------------------------------------------------
// Buttons and indicators.

enum CupertinoButtonSize { small, medium, large }

class CupertinoButton extends StatelessWidget {
  const CupertinoButton({
    super.key,
    required this.child,
    this.sizeStyle = CupertinoButtonSize.large,
    this.padding,
    this.color,
    this.foregroundColor,
    this.disabledColor = CupertinoColors.quaternarySystemFill,
    this.minSize,
    this.minimumSize,
    this.pressedOpacity = 0.4,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.focusColor,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.mouseCursor,
    this.onLongPress,
    required this.onPressed,
  }) : _filled = false,
       _tinted = false;
  const CupertinoButton.filled({
    super.key,
    required this.child,
    this.sizeStyle = CupertinoButtonSize.large,
    this.padding,
    this.color,
    this.foregroundColor,
    this.disabledColor = CupertinoColors.quaternarySystemFill,
    this.minSize,
    this.minimumSize,
    this.pressedOpacity = 0.4,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.focusColor,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.mouseCursor,
    this.onLongPress,
    required this.onPressed,
  }) : _filled = true,
       _tinted = false;
  const CupertinoButton.tinted({
    super.key,
    required this.child,
    this.sizeStyle = CupertinoButtonSize.large,
    this.padding,
    this.color,
    this.foregroundColor,
    this.disabledColor = CupertinoColors.quaternarySystemFill,
    this.minSize,
    this.minimumSize,
    this.pressedOpacity = 0.4,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.focusColor,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.mouseCursor,
    this.onLongPress,
    required this.onPressed,
  }) : _filled = false,
       _tinted = true;
  final Widget child;
  final CupertinoButtonSize sizeStyle;
  final EdgeInsetsGeometry? padding;
  final Color? color, foregroundColor, focusColor;
  final Color disabledColor;
  final double? minSize;
  final Size? minimumSize;
  final double? pressedOpacity;
  final BorderRadius? borderRadius;
  final AlignmentGeometry alignment;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final VoidCallback? onLongPress, onPressed;
  final bool _filled, _tinted;

  bool get enabled => onPressed != null || onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final values = CupertinoTheme._values(context);
    final primary = _cupertinoResolve(color ?? values.primary, context);
    final Color? background = !enabled
        ? (_filled || _tinted || color != null
              ? _cupertinoResolve(disabledColor, context)
              : null)
        : _filled
        ? primary
        : _tinted
        ? primary.withValues(alpha: 0.15)
        : (color == null ? null : primary);
    final foreground = !enabled
        ? _cupertinoResolve(CupertinoColors.tertiaryLabel, context)
        : foregroundColor ??
              (_filled || (color != null && !_tinted)
                  ? CupertinoColors.white
                  : values.primary);
    final minHeight = minimumSize?.height ?? minSize ?? 44;
    final style = values.text.actionTextStyle.copyWith(
      color: foreground,
      fontSize: sizeStyle == CupertinoButtonSize.small ? 15 : 17,
    );
    return _Box(
      tag: 'button',
      css:
          'display:inline-flex;align-items:center;justify-content:center;box-sizing:border-box;margin:0;border:0;font:inherit;cursor:${enabled ? 'pointer' : 'default'};min-height:${px(minHeight)};min-width:${px(minimumSize?.width ?? minSize ?? 44)};${edgeInsetsCss('padding', padding ?? (background == null ? const EdgeInsets.symmetric(vertical: 14, horizontal: 16) : const EdgeInsets.symmetric(vertical: 14, horizontal: 64)))}background-color:${background == null ? 'transparent' : colorCss(background)};border-radius:${px(borderRadius?.topLeft.x ?? 8)};-webkit-tap-highlight-color:transparent;--fd-press-opacity:${cssNumber(pressedOpacity ?? 1)};',
      attributes: {
        'type': 'button',
        'class': 'fd-cupertino-button',
        if (!enabled) 'disabled': '',
      },
      handlers: {if (onPressed != null) 'click': (_) => onPressed!()},
      gestures: onLongPress == null
          ? null
          : _GestureCallbacks(onLongPress: onLongPress),
      layout: _DomLayout.row,
      fill: _Fill.none,
      children: [
        DefaultTextStyle(
          style: style,
          child: IconTheme.merge(
            data: IconThemeData(color: foreground, size: 28),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// The iOS spinner: twelve fading ticks drawn with a conic gradient mask.
class CupertinoActivityIndicator extends StatelessWidget {
  const CupertinoActivityIndicator({
    super.key,
    this.color,
    this.animating = true,
    this.radius = 10,
  }) : progress = 1;
  const CupertinoActivityIndicator.partiallyRevealed({
    super.key,
    this.color,
    this.radius = 10,
    this.progress = 1,
  }) : animating = false;
  final Color? color;
  final bool animating;
  final double radius, progress;
  @override
  Widget build(BuildContext context) {
    final tick = colorCss(
      _cupertinoResolve(
        color ??
            const CupertinoDynamicColor.withBrightness(
              color: Color(0xFF3C3C44),
              darkColor: Color(0xFFEBEBF5),
            ),
        context,
      ),
    );
    final size = radius * 2;
    final ticks =
        'repeating-conic-gradient(from 0deg,$tick 0deg 12deg,transparent 12deg 30deg)';
    const ring =
        'radial-gradient(circle,transparent 45%,#000 46%,#000 100%,transparent 100%)';
    return _Box(
      css:
          'display:inline-block;flex-shrink:0;width:${px(size)};height:${px(size)};border-radius:50%;background:$ticks;-webkit-mask:$ring;mask:$ring;${animating ? 'animation:fd-spin 1s steps(12) infinite;' : ''}${progress < 1 ? 'opacity:${cssNumber(progress)};' : ''}',
      attributes: const {'role': 'progressbar', 'aria-label': 'Loading'},
      fill: _Fill.none,
    );
  }
}

class CupertinoSwitch extends StatelessWidget {
  const CupertinoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor,
    this.activeColor,
    this.inactiveTrackColor,
    this.trackColor,
    this.thumbColor,
    this.inactiveThumbColor,
    this.applyTheme,
    this.focusColor,
    this.onLabelColor,
    this.offLabelColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.thumbIcon,
    this.trackOutlineColor,
    this.trackOutlineWidth,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.mouseCursor,
    this.dragStartBehavior,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeTrackColor, activeColor, inactiveTrackColor, trackColor;
  final Color? thumbColor, inactiveThumbColor, focusColor;
  final Color? onLabelColor, offLabelColor;
  final bool? applyTheme;
  final ImageProvider? activeThumbImage, inactiveThumbImage;
  final Object? thumbIcon, trackOutlineColor, trackOutlineWidth;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final Object? dragStartBehavior;
  @override
  Widget build(BuildContext context) => Switch(
    value: value,
    onChanged: onChanged,
    activeColor: thumbColor ?? CupertinoColors.white,
    activeTrackColor: _cupertinoResolve(
      activeTrackColor ?? activeColor ?? CupertinoColors.systemGreen,
      context,
    ),
    inactiveThumbColor:
        inactiveThumbColor ?? thumbColor ?? CupertinoColors.white,
    inactiveTrackColor: _cupertinoResolve(
      inactiveTrackColor ?? trackColor ?? CupertinoColors.secondarySystemFill,
      context,
    ),
    focusNode: focusNode,
    autofocus: autofocus,
  );
}

class CupertinoSlider extends StatelessWidget {
  const CupertinoSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.activeColor,
    this.thumbColor = CupertinoColors.white,
  });
  final double value, min, max;
  final ValueChanged<double>? onChanged, onChangeStart, onChangeEnd;
  final int? divisions;
  final Color? activeColor;
  final Color thumbColor;
  @override
  Widget build(BuildContext context) => Slider(
    value: value,
    onChanged: onChanged,
    onChangeStart: onChangeStart,
    onChangeEnd: onChangeEnd,
    min: min,
    max: max,
    divisions: divisions,
    activeColor: _cupertinoResolve(
      activeColor ?? CupertinoTheme._values(context).primary,
      context,
    ),
  );
}

class CupertinoCheckbox extends StatelessWidget {
  const CupertinoCheckbox({
    super.key,
    required this.value,
    this.tristate = false,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.fillColor,
    this.checkColor,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.side,
    this.shape,
    this.semanticLabel,
    this.mouseCursor,
  });
  final bool? value;
  final bool tristate, autofocus;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor, inactiveColor, checkColor, focusColor;
  final WidgetStateProperty<Color?>? fillColor;
  final FocusNode? focusNode;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final String? semanticLabel;
  final MouseCursor? mouseCursor;
  @override
  Widget build(BuildContext context) => Checkbox(
    value: value,
    tristate: tristate,
    onChanged: onChanged,
    activeColor: _cupertinoResolve(
      activeColor ?? CupertinoTheme._values(context).primary,
      context,
    ),
  );
}

class CupertinoRadio<T> extends StatelessWidget {
  const CupertinoRadio({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.toggleable = false,
    this.activeColor,
    this.inactiveColor,
    this.fillColor,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.useCheckmarkStyle = false,
    this.mouseCursor,
  });
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final bool toggleable, autofocus, useCheckmarkStyle;
  final Color? activeColor, inactiveColor, fillColor, focusColor;
  final FocusNode? focusNode;
  final MouseCursor? mouseCursor;
  @override
  Widget build(BuildContext context) => Radio<T>(
    value: value,
    groupValue: groupValue,
    onChanged: onChanged,
    activeColor: _cupertinoResolve(
      activeColor ?? CupertinoTheme._values(context).primary,
      context,
    ),
  );
}

// ---------------------------------------------------------------------------
// Segmented controls.

Widget _cupertinoSegments<T>({
  required BuildContext context,
  required Map<T, Widget> children,
  required T? groupValue,
  required ValueChanged<T>? onValueChanged,
  required Color selectedBackground,
  required Color unselectedBackground,
  required Color selectedForeground,
  required Color unselectedForeground,
  required Color border,
  required bool sliding,
  required EdgeInsetsGeometry? padding,
  Set<T> disabled = const {},
}) {
  final text = _cupertinoText(context).copyWith(fontSize: 13);
  return _Box(
    css:
        'display:inline-grid;grid-auto-flow:column;grid-auto-columns:1fr;box-sizing:border-box;${edgeInsetsCss('padding', padding ?? (sliding ? const EdgeInsets.all(2) : EdgeInsets.zero))}border-radius:${sliding ? '9px' : '6px'};background-color:${colorCss(unselectedBackground)};${sliding ? '' : 'border:1px solid ${colorCss(border)};'}overflow:hidden;',
    attributes: const {'role': 'group'},
    layout: _DomLayout.grid,
    fill: _Fill.none,
    children: [
      for (final (index, MapEntry(:key, :value)) in children.entries.indexed)
        () {
          final selected = key == groupValue;
          final enabled = onValueChanged != null && !disabled.contains(key);
          return _Box(
            key: ValueKey(index),
            tag: 'button',
            css:
                'box-sizing:border-box;margin:0;border:0;font:inherit;padding:4px 12px;min-height:${sliding ? 28 : 29}px;cursor:${enabled ? 'pointer' : 'default'};background-color:${selected ? colorCss(selectedBackground) : 'transparent'};${sliding && selected ? 'border-radius:7px;box-shadow:0 3px 8px rgba(0,0,0,0.12),0 3px 1px rgba(0,0,0,0.04);' : ''}${!sliding && index > 0 ? 'border-left:1px solid ${colorCss(border)};' : ''}',
            attributes: {
              'type': 'button',
              'aria-pressed': '$selected',
              if (!enabled) 'disabled': '',
            },
            handlers: {if (enabled) 'click': (_) => onValueChanged(key)},
            layout: _DomLayout.align,
            fill: _Fill.none,
            children: [
              DefaultTextStyle(
                style: text.copyWith(
                  color: selected ? selectedForeground : unselectedForeground,
                  fontWeight: selected && sliding ? FontWeight.w600 : null,
                ),
                child: value,
              ),
            ],
          );
        }(),
    ],
  );
}

class CupertinoSlidingSegmentedControl<T extends Object>
    extends StatelessWidget {
  const CupertinoSlidingSegmentedControl({
    super.key,
    required this.children,
    required this.onValueChanged,
    this.disabledChildren = const {},
    this.groupValue,
    this.thumbColor = const CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFFFFFF),
      darkColor: Color(0xFF636366),
    ),
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
    this.backgroundColor = CupertinoColors.tertiarySystemFill,
    this.proportionalWidth = false,
    this.isMomentary = false,
  });
  final Map<T, Widget> children;
  final ValueChanged<T?> onValueChanged;
  final Set<T> disabledChildren;
  final T? groupValue;
  final Color thumbColor, backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool proportionalWidth, isMomentary;
  @override
  Widget build(BuildContext context) => _cupertinoSegments<T>(
    context: context,
    children: children,
    groupValue: groupValue,
    onValueChanged: onValueChanged,
    selectedBackground: _cupertinoResolve(thumbColor, context),
    unselectedBackground: _cupertinoResolve(backgroundColor, context),
    selectedForeground: _cupertinoText(context).color ?? CupertinoColors.black,
    unselectedForeground:
        _cupertinoText(context).color ?? CupertinoColors.black,
    border: CupertinoColors.transparent,
    sliding: true,
    padding: padding,
    disabled: disabledChildren,
  );
}

class CupertinoSegmentedControl<T extends Object> extends StatelessWidget {
  const CupertinoSegmentedControl({
    super.key,
    required this.children,
    required this.onValueChanged,
    this.groupValue,
    this.unselectedColor,
    this.selectedColor,
    this.borderColor,
    this.pressedColor,
    this.disabledColor,
    this.disabledTextColor,
    this.padding,
    this.disabledChildren = const {},
  });
  final Map<T, Widget> children;
  final ValueChanged<T> onValueChanged;
  final T? groupValue;
  final Color? unselectedColor, selectedColor, borderColor, pressedColor;
  final Color? disabledColor, disabledTextColor;
  final EdgeInsetsGeometry? padding;
  final Set<T> disabledChildren;
  @override
  Widget build(BuildContext context) {
    final primary = _cupertinoResolve(
      selectedColor ?? CupertinoTheme._values(context).primary,
      context,
    );
    final unselected = _cupertinoResolve(
      unselectedColor ?? CupertinoColors.systemBackground,
      context,
    );
    return _cupertinoSegments<T>(
      context: context,
      children: children,
      groupValue: groupValue,
      onValueChanged: onValueChanged,
      selectedBackground: primary,
      unselectedBackground: unselected,
      selectedForeground: unselected,
      unselectedForeground: primary,
      border: borderColor ?? primary,
      sliding: false,
      padding: padding,
      disabled: disabledChildren,
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs, action sheets and popups.

Future<T?> showCupertinoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? barrierLabel,
  bool useRootNavigator = true,
  bool barrierDismissible = false,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool? requestFocus,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
  _OverlayRoute<T>(
    builder: builder,
    dismissible: barrierDismissible,
    color: const Color(0x33000000),
    sheet: false,
    settings: routeSettings,
  ),
);

Future<T?> showCupertinoModalPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  ImageFilter? filter,
  Color barrierColor = const Color(0x33000000),
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  bool semanticsDismissible = false,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool? requestFocus,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
  _OverlayRoute<T>(
    builder: (context) =>
        Padding(padding: const EdgeInsets.all(8), child: builder(context)),
    dismissible: barrierDismissible,
    color: barrierColor,
    sheet: true,
    settings: routeSettings,
  ),
);

Future<T?> showCupertinoSheet<T>({
  required BuildContext context,
  required WidgetBuilder pageBuilder,
  bool useNestedNavigation = false,
  bool enableDrag = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: pageBuilder,
);

class CupertinoPopupSurface extends StatelessWidget {
  const CupertinoPopupSurface({
    super.key,
    this.isSurfacePainted = true,
    this.blurSigma = 30,
    this.isVibrancePainted = true,
    this.child,
  });
  final bool isSurfacePainted, isVibrancePainted;
  final double blurSigma;
  final Widget? child;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'box-sizing:border-box;border-radius:14px;overflow:hidden;${isSurfacePainted ? 'background-color:${colorCss(_cupertinoResolve(const CupertinoDynamicColor.withBrightness(color: Color(0xCCF2F2F2), darkColor: Color(0xBF1E1E1E)), context))};' : ''}backdrop-filter:blur(${cssNumber(blurSigma / 2)}px);-webkit-backdrop-filter:blur(${cssNumber(blurSigma / 2)}px);',
    fill: _Fill.child,
    children: [?child],
  );
}

class CupertinoAlertDialog extends StatelessWidget {
  const CupertinoAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.scrollController,
    this.actionScrollController,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
  });
  final Widget? title, content;
  final List<Widget> actions;
  final ScrollController? scrollController, actionScrollController;
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;
  @override
  Widget build(BuildContext context) {
    final separator = colorCss(
      _cupertinoResolve(CupertinoColors.separator, context),
    );
    final text = _cupertinoText(context);
    return _Box(
      css: 'width:270px;max-width:calc(100vw - 32px);',
      attributes: const {'role': 'alertdialog', 'aria-modal': 'true'},
      fill: _Fill.none,
      children: [
        CupertinoPopupSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 19, 16, 19),
                child: Column(
                  children: [
                    if (title != null)
                      DefaultTextStyle(
                        style: text.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        child: title!,
                      ),
                    if (title != null && content != null)
                      const SizedBox(height: 4),
                    if (content != null)
                      DefaultTextStyle(
                        style: text.copyWith(fontSize: 13),
                        textAlign: TextAlign.center,
                        child: content!,
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                _Box(
                  css:
                      'display:grid;${actions.length == 2 ? 'grid-template-columns:1fr 1fr;' : 'grid-template-columns:minmax(0,1fr);'}border-top:0.5px solid $separator;',
                  layout: _DomLayout.grid,
                  fill: _Fill.expand,
                  children: [
                    for (final (index, action) in actions.indexed)
                      _Box(
                        key: ValueKey(index),
                        css: index == 0
                            ? 'display:grid;'
                            : (actions.length == 2
                                  ? 'display:grid;border-left:0.5px solid $separator;'
                                  : 'display:grid;border-top:0.5px solid $separator;'),
                        layout: _DomLayout.grid,
                        fill: _Fill.expand,
                        children: [action],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class CupertinoDialogAction extends StatelessWidget {
  const CupertinoDialogAction({
    super.key,
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.textStyle,
    required this.child,
  });
  final VoidCallback? onPressed;
  final bool isDefaultAction, isDestructiveAction;
  final TextStyle? textStyle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final values = CupertinoTheme._values(context);
    final color = onPressed == null
        ? _cupertinoResolve(CupertinoColors.tertiaryLabel, context)
        : isDestructiveAction
        ? _cupertinoResolve(CupertinoColors.systemRed, context)
        : values.primary;
    return _Box(
      tag: 'button',
      css:
          'box-sizing:border-box;margin:0;border:0;background:transparent;font:inherit;min-height:44px;padding:0 8px;cursor:${onPressed == null ? 'default' : 'pointer'};',
      attributes: {'type': 'button', if (onPressed == null) 'disabled': ''},
      handlers: {if (onPressed != null) 'click': (_) => onPressed!()},
      layout: _DomLayout.align,
      fill: _Fill.expand,
      children: [
        DefaultTextStyle(
          style: _cupertinoText(context)
              .copyWith(
                color: color,
                fontWeight: isDefaultAction ? FontWeight.w600 : null,
              )
              .merge(textStyle),
          textAlign: TextAlign.center,
          child: child,
        ),
      ],
    );
  }
}

class CupertinoActionSheet extends StatelessWidget {
  const CupertinoActionSheet({
    super.key,
    this.title,
    this.message,
    this.actions,
    this.messageScrollController,
    this.actionScrollController,
    this.cancelButton,
  });
  final Widget? title, message, cancelButton;
  final List<Widget>? actions;
  final ScrollController? messageScrollController, actionScrollController;
  @override
  Widget build(BuildContext context) {
    final separator = colorCss(
      _cupertinoResolve(CupertinoColors.separator, context),
    );
    final text = _cupertinoText(
      context,
      color: _cupertinoResolve(CupertinoColors.secondaryLabel, context),
    ).copyWith(fontSize: 13);
    return _Box(
      css:
          'width:min(100vw - 16px,400px);display:flex;flex-direction:column;gap:8px;',
      attributes: const {'role': 'dialog', 'aria-modal': 'true'},
      layout: _DomLayout.column,
      fill: _Fill.none,
      children: [
        CupertinoPopupSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null || message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      if (title != null)
                        DefaultTextStyle(
                          style: text.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          child: title!,
                        ),
                      if (message != null)
                        DefaultTextStyle(
                          style: text,
                          textAlign: TextAlign.center,
                          child: message!,
                        ),
                    ],
                  ),
                ),
              for (final (index, action)
                  in (actions ?? const <Widget>[]).indexed)
                _Box(
                  key: ValueKey(index),
                  css: index == 0 && title == null && message == null
                      ? 'display:grid;'
                      : 'display:grid;border-top:0.5px solid $separator;',
                  layout: _DomLayout.grid,
                  fill: _Fill.expand,
                  children: [action],
                ),
            ],
          ),
        ),
        if (cancelButton != null) CupertinoPopupSurface(child: cancelButton),
      ],
    );
  }
}

class CupertinoActionSheetAction extends StatelessWidget {
  const CupertinoActionSheetAction({
    super.key,
    required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.mouseCursor,
    required this.child,
  });
  final VoidCallback onPressed;
  final bool isDefaultAction, isDestructiveAction;
  final MouseCursor? mouseCursor;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final values = CupertinoTheme._values(context);
    return _Box(
      tag: 'button',
      css:
          'box-sizing:border-box;margin:0;border:0;background:transparent;font:inherit;min-height:57px;padding:0 16px;cursor:pointer;',
      attributes: const {'type': 'button'},
      handlers: {'click': (_) => onPressed()},
      layout: _DomLayout.align,
      fill: _Fill.expand,
      children: [
        DefaultTextStyle(
          style: _cupertinoText(context).copyWith(
            fontSize: 20,
            color: isDestructiveAction
                ? _cupertinoResolve(CupertinoColors.systemRed, context)
                : values.primary,
            fontWeight: isDefaultAction ? FontWeight.w600 : null,
          ),
          textAlign: TextAlign.center,
          child: child,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Text fields.

enum OverlayVisibilityMode { never, editing, notEditing, always }

class CupertinoTextField extends StatelessWidget {
  const CupertinoTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.padding = const EdgeInsets.all(7),
    this.placeholder,
    this.placeholderStyle,
    this.prefix,
    this.prefixMode = OverlayVisibilityMode.always,
    this.suffix,
    this.suffixMode = OverlayVisibilityMode.always,
    this.clearButtonMode = OverlayVisibilityMode.never,
    this.clearButtonSemanticLabel,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTapOutside,
    this.inputFormatters,
    this.enabled = true,
    this.cursorWidth = 2,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2),
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20),
    this.enableInteractiveSelection = true,
    this.onTap,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.restorationId,
    this.contextMenuBuilder,
  }) : _borderless = false;
  const CupertinoTextField.borderless({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.padding = const EdgeInsets.all(7),
    this.placeholder,
    this.placeholderStyle,
    this.prefix,
    this.prefixMode = OverlayVisibilityMode.always,
    this.suffix,
    this.suffixMode = OverlayVisibilityMode.always,
    this.clearButtonMode = OverlayVisibilityMode.never,
    this.clearButtonSemanticLabel,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTapOutside,
    this.inputFormatters,
    this.enabled = true,
    this.cursorWidth = 2,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2),
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20),
    this.enableInteractiveSelection = true,
    this.onTap,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.restorationId,
    this.contextMenuBuilder,
  }) : _borderless = true;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry padding;
  final String? placeholder, clearButtonSemanticLabel, obscuringCharacter;
  final TextStyle? placeholderStyle, style;
  final Widget? prefix, suffix;
  final OverlayVisibilityMode prefixMode, suffixMode, clearButtonMode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final Object? textAlignVertical, keyboardAppearance, contextMenuBuilder;
  final bool readOnly, autofocus, obscureText, autocorrect, enableSuggestions;
  final bool? showCursor;
  final int? maxLines, minLines, maxLength;
  final bool expands, enabled, enableInteractiveSelection;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onEditingComplete, onTap;
  final Object? onTapOutside;
  final List<TextInputFormatter>? inputFormatters;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius cursorRadius;
  final Color? cursorColor;
  final EdgeInsets scrollPadding;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final String? restorationId;
  final bool _borderless;

  @override
  Widget build(BuildContext context) {
    final border = colorCss(
      _cupertinoResolve(
        const CupertinoDynamicColor.withBrightness(
          color: Color(0x33000000),
          darkColor: Color(0x33FFFFFF),
        ),
        context,
      ),
    );
    final background =
        decoration?.color ??
        _cupertinoResolve(CupertinoColors.systemBackground, context);
    return _Box(
      css:
          'display:flex;align-items:center;box-sizing:border-box;min-width:0;${_borderless ? '' : 'border:0.5px solid $border;border-radius:5px;'}${decoration == null ? (_borderless ? '' : 'background-color:${colorCss(background)};') : decorationCss(decoration!)}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        ?prefix,
        _FlexFill(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            style: _cupertinoText(context).merge(style),
            textAlign: textAlign,
            autofocus: autofocus,
            obscureText: obscureText,
            autocorrect: autocorrect,
            enableSuggestions: enableSuggestions,
            maxLines: maxLines,
            minLines: minLines,
            expands: expands,
            maxLength: maxLength,
            maxLengthEnforcement: maxLengthEnforcement,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            onSubmitted: onSubmitted,
            onTap: onTap,
            inputFormatters: inputFormatters,
            enabled: enabled,
            readOnly: readOnly,
            autofillHints: autofillHints,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: _cupertinoText(
                context,
                color: _cupertinoResolve(
                  CupertinoColors.placeholderText,
                  context,
                ),
              ).merge(placeholderStyle),
              border: InputBorder.none,
              isDense: true,
              contentPadding: padding,
              counterText: '',
            ),
          ),
        ),
        ?suffix,
      ],
    );
  }
}

class CupertinoSearchTextField extends StatelessWidget {
  const CupertinoSearchTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.placeholder,
    this.placeholderStyle,
    this.decoration,
    this.backgroundColor,
    this.borderRadius,
    this.keyboardType = TextInputType.text,
    this.padding = const EdgeInsetsDirectional.fromSTEB(5.5, 8, 5.5, 8),
    this.itemColor = CupertinoColors.secondaryLabel,
    this.itemSize = 20,
    this.prefixInsets = const EdgeInsetsDirectional.fromSTEB(6, 0, 0, 3),
    this.prefixIcon = const Icon(CupertinoIcons.search),
    this.suffixInsets = const EdgeInsetsDirectional.fromSTEB(0, 0, 5, 2),
    this.suffixIcon = const Icon(CupertinoIcons.xmark_circle_fill),
    this.suffixMode = OverlayVisibilityMode.editing,
    this.onSuffixTap,
    this.restorationId,
    this.focusNode,
    this.smartQuotesType,
    this.smartDashesType,
    this.enableIMEPersonalizedLearning = true,
    this.autofocus = false,
    this.onTap,
    this.autocorrect = true,
    this.enabled,
    this.cursorWidth = 2,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2),
    this.cursorOpacityAnimates = true,
    this.cursorColor,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final TextStyle? style, placeholderStyle;
  final String? placeholder, restorationId;
  final BoxDecoration? decoration;
  final Color? backgroundColor, cursorColor;
  final BorderRadius? borderRadius;
  final TextInputType? keyboardType;
  final EdgeInsetsGeometry padding, prefixInsets, suffixInsets;
  final Color itemColor;
  final double itemSize, cursorWidth;
  final double? cursorHeight;
  final Radius cursorRadius;
  final Widget prefixIcon, suffixIcon;
  final OverlayVisibilityMode suffixMode;
  final VoidCallback? onSuffixTap, onTap;
  final FocusNode? focusNode;
  final Object? smartQuotesType, smartDashesType;
  final bool enableIMEPersonalizedLearning, autofocus, autocorrect;
  final bool? enabled;
  final bool cursorOpacityAnimates;

  @override
  Widget build(BuildContext context) {
    final icons = IconThemeData(
      color: _cupertinoResolve(itemColor, context),
      size: itemSize,
    );
    return CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      style: style,
      placeholder: placeholder ?? 'Search',
      placeholderStyle: placeholderStyle,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.search,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enabled: enabled ?? true,
      padding: padding,
      decoration:
          decoration ??
          BoxDecoration(
            color: _cupertinoResolve(
              backgroundColor ?? CupertinoColors.tertiarySystemFill,
              context,
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(9),
          ),
      prefix: Padding(
        padding: prefixInsets,
        child: IconTheme.merge(data: icons, child: prefixIcon),
      ),
      suffix: CupertinoButton(
        padding: suffixInsets,
        minimumSize: Size.zero,
        onPressed: () {
          controller?.clear();
          onChanged?.call('');
          onSuffixTap?.call();
        },
        child: IconTheme.merge(data: icons, child: suffixIcon),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lists.

class CupertinoListSection extends StatelessWidget {
  const CupertinoListSection({
    super.key,
    this.children,
    this.header,
    this.footer,
    this.margin = EdgeInsets.zero,
    this.backgroundColor = CupertinoColors.systemGroupedBackground,
    this.decoration,
    this.clipBehavior = Clip.none,
    this.dividerMargin = 14,
    this.additionalDividerMargin,
    this.topMargin = 22,
    this.hasLeading = true,
    this.separatorColor,
  }) : _inset = false;
  const CupertinoListSection.insetGrouped({
    super.key,
    this.children,
    this.header,
    this.footer,
    EdgeInsetsGeometry? margin,
    this.backgroundColor = CupertinoColors.systemGroupedBackground,
    this.decoration,
    this.clipBehavior = Clip.hardEdge,
    this.dividerMargin = 14,
    this.additionalDividerMargin,
    this.topMargin,
    this.hasLeading = true,
    this.separatorColor,
  }) : margin = margin ?? const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
       _inset = true;
  final List<Widget>? children;
  final Widget? header, footer;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final BoxDecoration? decoration;
  final Clip clipBehavior;
  final double dividerMargin;
  final double? additionalDividerMargin, topMargin;
  final bool hasLeading;
  final Color? separatorColor;
  final bool _inset;

  @override
  Widget build(BuildContext context) {
    final separator = colorCss(
      _cupertinoResolve(separatorColor ?? CupertinoColors.separator, context),
    );
    final secondary = _cupertinoText(
      context,
      color: _cupertinoResolve(CupertinoColors.secondaryLabel, context),
    ).copyWith(fontSize: 13);
    final rowBackground = _cupertinoResolve(
      CupertinoColors.secondarySystemGroupedBackground,
      context,
    );
    final rows = children ?? const <Widget>[];
    return _Box(
      tag: 'section',
      css:
          'box-sizing:border-box;padding-top:${px(topMargin ?? (_inset ? 0 : 22))};background-color:${colorCss(_cupertinoResolve(backgroundColor, context))};',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: DefaultTextStyle(style: secondary, child: header!),
          ),
        Padding(
          padding: margin,
          child: _Box(
            css:
                'display:flex;flex-direction:column;background-color:${colorCss(rowBackground)};${_inset ? 'border-radius:10px;overflow:hidden;' : 'border-top:0.5px solid $separator;border-bottom:0.5px solid $separator;'}${decoration == null ? '' : decorationCss(decoration!)}',
            layout: _DomLayout.column,
            fill: _Fill.expand,
            children: [
              for (final (index, row) in rows.indexed)
                _Box(
                  key: row.key ?? ValueKey(index),
                  css: index == 0
                      ? 'display:grid;'
                      : 'display:grid;border-top:0.5px solid $separator;margin-left:${px(hasLeading ? dividerMargin + 44 + (additionalDividerMargin ?? 0) : dividerMargin + (additionalDividerMargin ?? 0))};',
                  layout: _DomLayout.grid,
                  fill: _Fill.expand,
                  children: [row],
                ),
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: DefaultTextStyle(style: secondary, child: footer!),
          ),
      ],
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  const CupertinoListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.additionalInfo,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.backgroundColorActivated,
    this.padding,
    this.leadingSize = 28,
    this.leadingToTitle = 16,
  }) : _notched = false;
  const CupertinoListTile.notched({
    super.key,
    required this.title,
    this.subtitle,
    this.additionalInfo,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.backgroundColorActivated,
    this.padding,
    this.leadingSize = 30,
    this.leadingToTitle = 12,
  }) : _notched = true;
  final Widget title;
  final Widget? subtitle, additionalInfo, leading, trailing;
  final FutureOr<void> Function()? onTap;
  final Color? backgroundColor, backgroundColorActivated;
  final EdgeInsetsGeometry? padding;
  final double leadingSize, leadingToTitle;
  final bool _notched;

  @override
  Widget build(BuildContext context) {
    final text = _cupertinoText(context);
    final secondary = text.copyWith(
      color: _cupertinoResolve(CupertinoColors.secondaryLabel, context),
      fontSize: 15,
    );
    final row = _Box(
      css:
          'display:flex;align-items:center;box-sizing:border-box;min-height:${subtitle == null ? 44 : 58}px;gap:${px(leadingToTitle)};${edgeInsetsCss('padding', padding ?? (_notched ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10) : const EdgeInsets.symmetric(horizontal: 20, vertical: 10)))}${backgroundColor == null ? '' : 'background-color:${colorCss(_cupertinoResolve(backgroundColor!, context))};'}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        if (leading != null)
          SizedBox(
            width: leadingSize,
            height: leadingSize,
            child: Center(child: leading),
          ),
        _FlexFill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: title,
              ),
              if (subtitle != null)
                DefaultTextStyle(style: secondary, child: subtitle!),
            ],
          ),
        ),
        if (additionalInfo != null)
          DefaultTextStyle(
            style: secondary.copyWith(fontSize: 17),
            child: additionalInfo!,
          ),
        if (trailing != null)
          IconTheme.merge(
            data: IconThemeData(
              color: _cupertinoResolve(CupertinoColors.systemGrey2, context),
            ),
            child: trailing!,
          ),
      ],
    );
    final tap = onTap;
    if (tap == null) return row;
    return _Box(
      tag: 'button',
      css:
          'display:grid;box-sizing:border-box;margin:0;border:0;padding:0;background:transparent;font:inherit;text-align:left;cursor:pointer;',
      attributes: const {'type': 'button', 'class': 'fd-ink'},
      handlers: {'click': (_) => tap()},
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [row],
    );
  }
}

class CupertinoListTileChevron extends StatelessWidget {
  const CupertinoListTileChevron({super.key});
  @override
  Widget build(BuildContext context) => Icon(
    CupertinoIcons.right_chevron,
    size: 18,
    color: _cupertinoResolve(CupertinoColors.systemGrey2, context),
  );
}

class CupertinoFormSection extends CupertinoListSection {
  const CupertinoFormSection({
    super.key,
    required List<Widget> super.children,
    super.header,
    super.footer,
    super.margin,
    super.backgroundColor,
    super.decoration,
    super.clipBehavior,
  }) : super(hasLeading: false);
  const CupertinoFormSection.insetGrouped({
    super.key,
    required List<Widget> super.children,
    super.header,
    super.footer,
    super.margin,
    super.backgroundColor,
    super.decoration,
    super.clipBehavior,
  }) : super.insetGrouped(hasLeading: false);
}

class CupertinoFormRow extends StatelessWidget {
  const CupertinoFormRow({
    super.key,
    required this.child,
    this.prefix,
    this.padding,
    this.helper,
    this.error,
  });
  final Widget child;
  final Widget? prefix, helper, error;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    final text = _cupertinoText(context);
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (prefix != null) DefaultTextStyle(style: text, child: prefix!),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: child),
              ),
            ],
          ),
          if (helper != null)
            DefaultTextStyle(
              style: text.copyWith(fontSize: 13),
              child: helper!,
            ),
          if (error != null)
            DefaultTextStyle(
              style: text.copyWith(
                fontSize: 13,
                color: _cupertinoResolve(
                  CupertinoColors.destructiveRed,
                  context,
                ),
              ),
              child: error!,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabs.

class CupertinoTabController extends ChangeNotifier {
  CupertinoTabController({int initialIndex = 0}) : _index = initialIndex;
  int _index;
  int get index => _index;
  set index(int value) {
    if (value == _index) return;
    _index = value;
    notifyListeners();
  }
}

class CupertinoTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CupertinoTabBar({
    super.key,
    required this.items,
    this.onTap,
    this.currentIndex = 0,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor = CupertinoColors.inactiveGray,
    this.iconSize = 30,
    this.height = 50,
    this.border,
  });
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int>? onTap;
  final int currentIndex;
  final Color? backgroundColor, activeColor;
  final Color inactiveColor;
  final double iconSize, height;
  final Border? border;
  @override
  Size get preferredSize => Size.fromHeight(height);

  CupertinoTabBar copyWith({
    Key? key,
    List<BottomNavigationBarItem>? items,
    Color? backgroundColor,
    Color? activeColor,
    Color? inactiveColor,
    double? iconSize,
    double? height,
    Border? border,
    int? currentIndex,
    ValueChanged<int>? onTap,
  }) => CupertinoTabBar(
    key: key ?? this.key,
    items: items ?? this.items,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    iconSize: iconSize ?? this.iconSize,
    height: height ?? this.height,
    border: border ?? this.border,
    currentIndex: currentIndex ?? this.currentIndex,
    onTap: onTap ?? this.onTap,
  );

  @override
  Widget build(BuildContext context) {
    final values = CupertinoTheme._values(context);
    final active = _cupertinoResolve(activeColor ?? values.primary, context);
    final inactive = _cupertinoResolve(inactiveColor, context);
    return _Box(
      tag: 'nav',
      css:
          'display:grid;grid-auto-flow:column;grid-auto-columns:1fr;box-sizing:border-box;min-height:${px(height)};background-color:${colorCss(_cupertinoResolve(backgroundColor ?? values.bar, context))};border-top:0.5px solid ${colorCss(_cupertinoResolve(CupertinoColors.separator, context))};backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);',
      attributes: const {'role': 'tablist'},
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [
        for (final (index, item) in items.indexed)
          () {
            final selected = index == currentIndex;
            final color = selected ? active : inactive;
            return _Box(
              key: ValueKey(index),
              tag: 'button',
              css:
                  'display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;box-sizing:border-box;margin:0;border:0;background:transparent;font:inherit;cursor:pointer;padding:4px 0;',
              attributes: {
                'type': 'button',
                'role': 'tab',
                'aria-selected': '$selected',
              },
              handlers: {'click': (_) => onTap?.call(index)},
              layout: _DomLayout.column,
              fill: _Fill.expand,
              children: [
                IconTheme.merge(
                  data: IconThemeData(color: color, size: iconSize),
                  child: selected ? (item.activeIcon ?? item.icon) : item.icon,
                ),
                if (item.label != null)
                  Text(
                    item.label!,
                    style: values.text.tabLabelTextStyle.copyWith(color: color),
                  ),
              ],
            );
          }(),
      ],
    );
  }
}

class CupertinoTabScaffold extends StatefulWidget {
  CupertinoTabScaffold({
    super.key,
    required this.tabBar,
    required this.tabBuilder,
    this.controller,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.restorationId,
  });
  final CupertinoTabBar tabBar;
  final IndexedWidgetBuilder tabBuilder;
  final CupertinoTabController? controller;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final String? restorationId;
  @override
  State<CupertinoTabScaffold> createState() => _CupertinoTabScaffoldState();
}

class _CupertinoTabScaffoldState extends State<CupertinoTabScaffold> {
  late CupertinoTabController _controller =
      widget.controller ??
      CupertinoTabController(initialIndex: widget.tabBar.currentIndex);
  final _visited = <int>{};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(CupertinoTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller.removeListener(_changed);
      _controller = widget.controller!..addListener(_changed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final index = _controller.index;
    _visited.add(index);
    return Scaffold(
      backgroundColor: _cupertinoResolve(
        widget.backgroundColor ?? CupertinoTheme._values(context).scaffold,
        context,
      ),
      // Visited tabs stay mounted (hidden), keeping their state as Flutter does.
      body: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < widget.tabBar.items.length; i++)
            _visited.contains(i)
                ? Builder(builder: (context) => widget.tabBuilder(context, i))
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: widget.tabBar.copyWith(
        currentIndex: index,
        onTap: (i) {
          _controller.index = i;
          widget.tabBar.onTap?.call(i);
        },
      ),
    );
  }
}

/// A tab's own navigation stack.
class CupertinoTabView extends StatelessWidget {
  const CupertinoTabView({
    super.key,
    this.builder,
    this.navigatorKey,
    this.defaultTitle,
    this.routes,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.restorationScopeId,
  });
  final WidgetBuilder? builder;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? defaultTitle, restorationScopeId;
  final Map<String, WidgetBuilder>? routes;
  final RouteFactory? onGenerateRoute, onUnknownRoute;
  final List<NavigatorObserver> navigatorObservers;
  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    home: builder == null ? null : Builder(builder: builder!),
    routes: routes ?? const {},
    onGenerateRoute: onGenerateRoute,
    onUnknownRoute: onUnknownRoute,
    observers: navigatorObservers,
  );
}

// ---------------------------------------------------------------------------
// Pickers.

class CupertinoPicker extends StatelessWidget {
  CupertinoPicker({
    super.key,
    this.diameterRatio = 1.07,
    this.backgroundColor,
    this.offAxisFraction = 0,
    this.useMagnifier = false,
    this.magnification = 1,
    this.scrollController,
    this.squeeze = 1.45,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required List<Widget> children,
    this.selectionOverlay = const CupertinoPickerDefaultSelectionOverlay(),
    bool looping = false,
    this.changeReportingBehavior,
  }) : childDelegate = ListWheelChildListDelegate(children: children);
  CupertinoPicker.builder({
    super.key,
    this.diameterRatio = 1.07,
    this.backgroundColor,
    this.offAxisFraction = 0,
    this.useMagnifier = false,
    this.magnification = 1,
    this.scrollController,
    this.squeeze = 1.45,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? childCount,
    this.selectionOverlay = const CupertinoPickerDefaultSelectionOverlay(),
    this.changeReportingBehavior,
  }) : childDelegate = ListWheelChildBuilderDelegate(
         builder: itemBuilder,
         childCount: childCount,
       );
  final double diameterRatio, offAxisFraction, magnification, squeeze;
  final double itemExtent;
  final Color? backgroundColor;
  final bool useMagnifier;
  final FixedExtentScrollController? scrollController;
  final ValueChanged<int>? onSelectedItemChanged;
  final ListWheelChildDelegate childDelegate;
  final Widget? selectionOverlay;
  final Object? changeReportingBehavior;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'position:relative;display:grid;min-height:${px(itemExtent * 5)};${backgroundColor == null ? '' : 'background-color:${colorCss(_cupertinoResolve(backgroundColor!, context))};'}',
    layout: _DomLayout.grid,
    fill: _Fill.expand,
    children: [
      DefaultTextStyle(
        style: CupertinoTheme._values(
          context,
        ).text.pickerTextStyle.copyWith(color: _cupertinoText(context).color),
        child: ListWheelScrollView.useDelegate(
          controller: scrollController,
          itemExtent: itemExtent,
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: childDelegate,
        ),
      ),
    ],
  );
}

class CupertinoPickerDefaultSelectionOverlay extends StatelessWidget {
  const CupertinoPickerDefaultSelectionOverlay({
    super.key,
    this.background = CupertinoColors.tertiarySystemFill,
    this.capStartEdge = true,
    this.capEndEdge = true,
  });
  final Color background;
  final bool capStartEdge, capEndEdge;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

enum CupertinoDatePickerMode { time, date, dateAndTime, monthYear }

enum DatePickerDateOrder { dmy, mdy, ymd, ydm }

/// Picks dates and times with the browser's native inputs.
class CupertinoDatePicker extends StatelessWidget {
  CupertinoDatePicker({
    super.key,
    this.mode = CupertinoDatePickerMode.dateAndTime,
    required this.onDateTimeChanged,
    DateTime? initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.minimumYear = 1,
    this.maximumYear,
    this.minuteInterval = 1,
    this.use24hFormat = false,
    this.dateOrder,
    this.backgroundColor,
    this.showDayOfWeek = false,
    this.itemExtent = 32,
    this.selectionOverlayBuilder,
    this.showTimeSeparator = false,
    this.changeReportingBehavior,
  }) : initialDateTime = initialDateTime ?? DateTime.now();
  final CupertinoDatePickerMode mode;
  final ValueChanged<DateTime> onDateTimeChanged;
  final DateTime initialDateTime;
  final DateTime? minimumDate, maximumDate;
  final int minimumYear, minuteInterval;
  final int? maximumYear;
  final bool use24hFormat, showDayOfWeek, showTimeSeparator;
  final DatePickerDateOrder? dateOrder;
  final Color? backgroundColor;
  final double itemExtent;
  final Object? selectionOverlayBuilder, changeReportingBehavior;

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
  static String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  @override
  Widget build(BuildContext context) {
    final (type, value, min, max) = switch (mode) {
      CupertinoDatePickerMode.date => (
        'date',
        _date(initialDateTime),
        minimumDate == null ? null : _date(minimumDate!),
        maximumDate == null ? null : _date(maximumDate!),
      ),
      CupertinoDatePickerMode.monthYear => (
        'month',
        _date(initialDateTime).substring(0, 7),
        minimumDate == null ? null : _date(minimumDate!).substring(0, 7),
        maximumDate == null ? null : _date(maximumDate!).substring(0, 7),
      ),
      CupertinoDatePickerMode.time => (
        'time',
        _time(initialDateTime),
        null,
        null,
      ),
      CupertinoDatePickerMode.dateAndTime => (
        'datetime-local',
        '${_date(initialDateTime)}T${_time(initialDateTime)}',
        minimumDate == null
            ? null
            : '${_date(minimumDate!)}T${_time(minimumDate!)}',
        maximumDate == null
            ? null
            : '${_date(maximumDate!)}T${_time(maximumDate!)}',
      ),
    };
    return _Box(
      css:
          'display:grid;padding:8px;${backgroundColor == null ? '' : 'background-color:${colorCss(_cupertinoResolve(backgroundColor!, context))};'}',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [
        _NativeValueInput(
          type: type,
          value: value,
          label: 'Date and time',
          min: min,
          max: max,
          onChanged: (raw) {
            final parsed = _parse(raw);
            if (parsed != null) onDateTimeChanged(parsed);
          },
        ),
      ],
    );
  }

  DateTime? _parse(String raw) {
    switch (mode) {
      case CupertinoDatePickerMode.time:
        final parts = raw.split(':');
        if (parts.length < 2) return null;
        return DateTime(
          initialDateTime.year,
          initialDateTime.month,
          initialDateTime.day,
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
        );
      case CupertinoDatePickerMode.monthYear:
        return DateTime.tryParse('$raw-01');
      case CupertinoDatePickerMode.date:
      case CupertinoDatePickerMode.dateAndTime:
        return DateTime.tryParse(raw);
    }
  }
}

class CupertinoScrollbar extends StatelessWidget {
  const CupertinoScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbVisibility,
    this.thickness = 3,
    this.thicknessWhileDragging = 8,
    this.radius = const Radius.circular(1.5),
    this.radiusWhileDragging = const Radius.circular(4),
    this.notificationPredicate,
    this.scrollbarOrientation,
  });
  final Widget child;
  final ScrollController? controller;
  final bool? thumbVisibility;
  final double thickness, thicknessWhileDragging;
  final Radius radius, radiusWhileDragging;
  final Object? notificationPredicate, scrollbarOrientation;
  @override
  Widget build(BuildContext context) => child;
}

/// A centered context surface; previews and the long-press menu are
/// approximated by the action list shown on long press.
class CupertinoContextMenu extends StatelessWidget {
  const CupertinoContextMenu({
    super.key,
    required this.actions,
    required this.child,
    this.enableHapticFeedback = false,
  });
  final List<Widget> actions;
  final Widget child;
  final bool enableHapticFeedback;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () => showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(actions: actions),
    ),
    child: child,
  );
}

class CupertinoContextMenuAction extends StatelessWidget {
  const CupertinoContextMenuAction({
    super.key,
    required this.child,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.onPressed,
    this.trailingIcon,
  });
  final Widget child;
  final bool isDefaultAction, isDestructiveAction;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  @override
  Widget build(BuildContext context) => CupertinoActionSheetAction(
    onPressed: onPressed ?? () {},
    isDefaultAction: isDefaultAction,
    isDestructiveAction: isDestructiveAction,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [child, if (trailingIcon != null) Icon(trailingIcon)],
    ),
  );
}

/// A flex item that takes the remaining space in a raw flex box.
class _FlexFill extends StatelessWidget {
  const _FlexFill({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'flex:1 1 0;min-width:0;display:grid;grid-template-columns:minmax(0,1fr);',
    layout: _DomLayout.grid,
    fill: _Fill.expand,
    children: [child],
  );
}
