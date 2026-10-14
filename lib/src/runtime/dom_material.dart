part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Generic private box used to compose Material widgets from DOM elements.

class _Box extends _DomWidget {
  const _Box({
    super.key,
    this.tag = 'div',
    this.css = '',
    this.attributes = const {},
    this.handlers = const {},
    this.children = const [],
    this.layout = _DomLayout.block,
    this.fill = _Fill.child,
    this.gestures,
  });
  final _GestureCallbacks? gestures;
  final String tag;
  final String css;
  final Map<String, String> attributes;
  final Map<String, _DomHandler> handlers;
  final List<Widget> children;
  final _DomLayout layout;
  final _Fill fill;
  @override
  String get _tag => tag;
  @override
  _DomLayout get _layout => layout;
  @override
  _Fill get _fill => fill;
  @override
  void _render(_DomBuilder out) {
    out.css(css);
    out.attributes.addAll(attributes);
    if (gestures case final gestures?) _installGestures(out, gestures);
    out.handlers.addAll(handlers);
    final click = handlers['click'];
    if (gestures != null && click != null) {
      out.handlers['click'] = (event) {
        if (!_clickSuppressed(event)) click(event);
      };
    }
    out.children = children;
  }
}

/// Keyboard activation for non-button elements with button semantics.
Map<String, _DomHandler> _activationHandlers(VoidCallback? onActivate) =>
    onActivate == null
    ? const {}
    : {
        'click': (_) => onActivate(),
        'keydown': (event) {
          final key = event?.key;
          if (key == 'Enter' || key == ' ') {
            event?.preventDefault();
            onActivate();
          }
        },
      };

String _stateLayerCss(Color foreground) =>
    '--fd-hover:${colorCss(foreground.withValues(alpha: 0.08))};--fd-press:${colorCss(foreground.withValues(alpha: 0.1))};--fd-focus:${colorCss(foreground)};';

// ---------------------------------------------------------------------------
// Theme and application.

final _defaultTheme = ThemeData();

class Theme extends StatelessWidget {
  const Theme({super.key, required this.data, required this.child});
  final ThemeData data;
  final Widget child;
  static ThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedTheme>()?.data ??
      _defaultTheme;
  static Brightness brightnessOf(BuildContext context) =>
      maybeBrightnessOf(context) ?? Brightness.light;
  static Brightness? maybeBrightnessOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_InheritedTheme>()
          ?.data
          .brightness ??
      MediaQuery.platformBrightnessOf(context);
  @override
  Widget build(BuildContext context) => _InheritedTheme(data, child);
}

class _InheritedTheme extends InheritedWidget {
  const _InheritedTheme(this.data, Widget child) : super(child: child);
  final ThemeData data;
  @override
  bool updateShouldNotify(_InheritedTheme oldWidget) =>
      !identical(oldWidget.data, data);
}

enum ThemeMode { system, light, dark }

/// Router configurations accepted by `MaterialApp.router`.
abstract interface class RouterConfig<T> {}

abstract interface class _DomRouterConfig {
  Widget _buildRouterView();
}

enum MaterialTapTargetSize { padded, shrinkWrap }

class VisualDensity {
  const VisualDensity({this.horizontal = 0, this.vertical = 0});
  final double horizontal, vertical;
  static const double minimumDensity = -4.0;
  static const double maximumDensity = 4.0;
  static const standard = VisualDensity();
  static const comfortable = VisualDensity(horizontal: -1, vertical: -1);
  static const compact = VisualDensity(horizontal: -2, vertical: -2);
  static VisualDensity get adaptivePlatformDensity =>
      defaultDensityForPlatform(defaultTargetPlatform);
  static VisualDensity defaultDensityForPlatform(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android ||
        TargetPlatform.fuchsia ||
        TargetPlatform.iOS => standard,
        _ => compact,
      };
  VisualDensity copyWith({double? horizontal, double? vertical}) =>
      VisualDensity(
        horizontal: horizontal ?? this.horizontal,
        vertical: vertical ?? this.vertical,
      );
  Offset get baseSizeAdjustment => Offset(horizontal * 4, vertical * 4);
  static VisualDensity lerp(VisualDensity a, VisualDensity b, double t) =>
      VisualDensity(
        horizontal: a.horizontal + (b.horizontal - a.horizontal) * t,
        vertical: a.vertical + (b.vertical - a.vertical) * t,
      );
  @override
  bool operator ==(Object other) =>
      other is VisualDensity &&
      other.horizontal == horizontal &&
      other.vertical == vertical;
  @override
  int get hashCode => Object.hash(horizontal, vertical);
}

class Title extends StatefulWidget {
  const Title({
    super.key,
    required this.title,
    required this.color,
    required this.child,
  });
  final String title;
  final Color color;
  final Widget child;
  @override
  State<Title> createState() => _TitleState();
}

class _TitleState extends State<Title> {
  void _apply() {
    if (widget.title.isNotEmpty) {
      (_document as JSObject).setProperty('title'.toJS, widget.title.toJS);
    }
  }

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(Title oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) _apply();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MaterialApp extends StatelessWidget {
  const MaterialApp({
    super.key,
    this.navigatorKey,
    this.scaffoldMessengerKey,
    this.home,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.builder,
    this.title = '',
    this.color,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.debugShowCheckedModeBanner = true,
    this.locale,
    this.localizationsDelegates,
    this.localeResolutionCallback,
    this.localeListResolutionCallback,
    this.supportedLocales = const [Locale('en', 'US')],
  }) : routerConfig = null;
  const MaterialApp.router({
    super.key,
    this.scaffoldMessengerKey,
    required RouterConfig<Object> this.routerConfig,
    this.builder,
    this.title = '',
    this.color,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.debugShowCheckedModeBanner = true,
    this.locale,
    this.localizationsDelegates,
    this.localeResolutionCallback,
    this.localeListResolutionCallback,
    this.supportedLocales = const [Locale('en', 'US')],
  }) : navigatorKey = null,
       home = null,
       routes = const {},
       initialRoute = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorObservers = const [];
  final RouterConfig<Object>? routerConfig;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleResolutionCallback? localeResolutionCallback;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final Iterable<Locale> supportedLocales;

  Locale _resolveLocale() {
    if (locale != null) return locale!;
    final preferred = _browserLocales();
    final listResolved = localeListResolutionCallback?.call(
      preferred,
      supportedLocales,
    );
    if (listResolved != null) return listResolved;
    final resolved = localeResolutionCallback?.call(
      preferred.firstOrNull,
      supportedLocales,
    );
    return resolved ?? basicLocaleListResolution(preferred, supportedLocales);
  }

  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final Widget? home;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute, onUnknownRoute;
  final List<NavigatorObserver> navigatorObservers;
  final TransitionBuilder? builder;
  final String title;
  final Color? color;
  final ThemeData? theme, darkTheme;
  final ThemeMode themeMode;
  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    final dark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platform == Brightness.dark);
    final data = (dark ? darkTheme : null) ?? theme ?? _defaultTheme;
    final router = routerConfig;
    if (router != null && router is! _DomRouterConfig)
      throw UnsupportedError(
        'Only GoRouter router configurations are supported.',
      );
    // As in Flutter, any home page runs inside a Navigator so dialogs and
    // menus can be pushed from it.
    final usesNavigator =
        home != null ||
        routes.isNotEmpty ||
        onGenerateRoute != null ||
        initialRoute != null ||
        navigatorKey != null;
    Widget content = router != null
        ? (router as _DomRouterConfig)._buildRouterView()
        : usesNavigator
        ? Navigator(
            key: navigatorKey,
            home: home,
            routes: routes,
            initialRoute: initialRoute,
            onGenerateRoute: onGenerateRoute,
            onUnknownRoute: onUnknownRoute,
            observers: navigatorObservers,
          )
        : (home ??
              (throw ArgumentError(
                'MaterialApp requires home, routes or onGenerateRoute.',
              )));
    if (builder != null) {
      final inner = content;
      content = Builder(builder: (context) => builder!(context, inner));
    }
    final appLocale = _resolveLocale();
    return Title(
      title: title,
      color: color ?? data.colorScheme.primary,
      child: _DocumentLanguage(
        locale: appLocale,
        child: Localizations(
          locale: appLocale,
          isApplicationLevel: true,
          delegates: [
            ...?localizationsDelegates,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Theme(
            data: data,
            child: ScaffoldMessenger(
              key: scaffoldMessengerKey,
              child: _AppSurface(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSurface extends _DomWidget {
  const _AppSurface({required this.child});
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) {
    final scheme = Theme.of(out.context).colorScheme;
    out.css(
      'min-height:100vh;display:grid;grid-template-columns:minmax(0,1fr);background-color:${colorCss(scheme.surface)};color:${colorCss(scheme.onSurface)};',
    );
    out.child(child);
  }
}

// ---------------------------------------------------------------------------
// Surfaces.

enum MaterialType { canvas, card, circle, button, transparency }

const Duration kThemeChangeDuration = Duration(milliseconds: 200);

class Material extends StatelessWidget {
  const Material({
    super.key,
    this.type = MaterialType.canvas,
    this.elevation = 0,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.textStyle,
    this.borderRadius,
    this.shape,
    this.borderOnForeground = true,
    this.clipBehavior = Clip.none,
    this.animationDuration = kThemeChangeDuration,
    this.child,
  });
  final MaterialType type;
  final bool borderOnForeground;
  final Duration animationDuration;
  final double elevation;
  final Color? color, shadowColor, surfaceTintColor;
  final TextStyle? textStyle;
  final BorderRadiusGeometry? borderRadius;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = type == MaterialType.transparency
        ? null
        : color ??
              (type == MaterialType.card
                  ? Theme.of(context).cardColor
                  : scheme.surface);
    final shapeStyle = type == MaterialType.circle
        ? 'border-radius:50%;'
        : shape != null
        ? shapeCss(shape)
        : borderRadiusCss(borderRadius);
    Widget? content = child;
    if (content != null && textStyle != null)
      content = DefaultTextStyle.merge(style: textStyle, child: content);
    return _Box(
      css:
          'box-sizing:border-box;min-width:0;${background == null ? '' : 'background-color:${colorCss(background)};'}$shapeStyle${elevationCss(elevation, shadowColor ?? scheme.shadow)}${clipBehavior == Clip.none ? '' : 'overflow:hidden;'}',
      layout: _DomLayout.grid,
      children: [?content],
    );
  }
}

enum _CardVariant { elevated, filled, outlined }

class Card extends StatelessWidget {
  const Card({
    super.key,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.semanticContainer = true,
    this.child,
  }) : _variant = _CardVariant.elevated;
  const Card.filled({
    super.key,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.semanticContainer = true,
    this.child,
  }) : _variant = _CardVariant.filled;
  const Card.outlined({
    super.key,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.semanticContainer = true,
    this.child,
  }) : _variant = _CardVariant.outlined;
  final Color? color, shadowColor, surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground, semanticContainer;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final Widget? child;
  final _CardVariant _variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardTheme = CardTheme.of(context);
    final background =
        color ??
        cardTheme.color ??
        switch (_variant) {
          _CardVariant.elevated => Theme.of(context).cardColor,
          _CardVariant.filled => scheme.surfaceContainerHighest,
          _CardVariant.outlined => scheme.surface,
        };
    final cardShape =
        shape ??
        cardTheme.shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _variant == _CardVariant.outlined
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        );
    final depth =
        elevation ??
        cardTheme.elevation ??
        (_variant == _CardVariant.elevated ? 1.0 : 0.0);
    final clip = clipBehavior ?? cardTheme.clipBehavior ?? Clip.none;
    final cardMargin = margin ?? cardTheme.margin ?? const EdgeInsets.all(4);
    final shadow = shadowColor ?? cardTheme.shadowColor ?? scheme.shadow;
    return _Box(
      css:
          'box-sizing:border-box;min-width:0;${edgeInsetsCss('margin', cardMargin)}background-color:${colorCss(background)};${shapeCss(cardShape)}${elevationCss(depth, shadow)}${clip == Clip.none ? '' : 'overflow:hidden;'}',
      children: [?child],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget states and button styles.

enum WidgetState {
  hovered,
  focused,
  pressed,
  dragged,
  selected,
  scrolledUnder,
  disabled,
  error,
}

typedef MaterialState = WidgetState;

abstract class WidgetStateProperty<T> {
  const WidgetStateProperty();
  T resolve(Set<WidgetState> states);
  static WidgetStateProperty<T> resolveWith<T>(
    T Function(Set<WidgetState> states) callback,
  ) => _WidgetStatePropertyWith<T>(callback);
  static WidgetStateProperty<T> all<T>(T value) =>
      WidgetStatePropertyAll<T>(value);
  static T resolveAs<T>(T value, Set<WidgetState> states) =>
      value is WidgetStateProperty<T> ? value.resolve(states) : value;
}

class _WidgetStatePropertyWith<T> extends WidgetStateProperty<T> {
  const _WidgetStatePropertyWith(this._resolve);
  final T Function(Set<WidgetState>) _resolve;
  @override
  T resolve(Set<WidgetState> states) => _resolve(states);
}

class WidgetStatePropertyAll<T> extends WidgetStateProperty<T> {
  const WidgetStatePropertyAll(this.value);
  final T value;
  @override
  T resolve(Set<WidgetState> states) => value;
  @override
  bool operator ==(Object other) =>
      other is WidgetStatePropertyAll<T> && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

typedef MaterialStateProperty<T> = WidgetStateProperty<T>;
typedef MaterialStatePropertyAll<T> = WidgetStatePropertyAll<T>;

/// The interactive states of a widget, as a listenable set.
class WidgetStatesController extends ValueNotifier<Set<WidgetState>> {
  WidgetStatesController([Set<WidgetState>? value])
    : super(<WidgetState>{...?value});
  void update(WidgetState state, bool add) {
    final changed = add ? value.add(state) : value.remove(state);
    if (changed) notifyListeners();
  }
}

typedef MaterialStatesController = WidgetStatesController;

typedef ButtonLayerBuilder =
    Widget Function(
      BuildContext context,
      Set<WidgetState> states,
      Widget? child,
    );

class ButtonStyle {
  const ButtonStyle({
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.padding,
    this.minimumSize,
    this.fixedSize,
    this.maximumSize,
    this.iconColor,
    this.iconSize,
    this.iconAlignment,
    this.side,
    this.shape,
    this.mouseCursor,
    this.visualDensity,
    this.tapTargetSize,
    this.animationDuration,
    this.enableFeedback,
    this.alignment,
    this.splashFactory,
    this.backgroundBuilder,
    this.foregroundBuilder,
  });
  final WidgetStateProperty<TextStyle?>? textStyle;
  final WidgetStateProperty<Color?>? backgroundColor, foregroundColor;
  final WidgetStateProperty<Color?>? overlayColor, shadowColor;
  final WidgetStateProperty<Color?>? surfaceTintColor, iconColor;
  final WidgetStateProperty<double?>? elevation, iconSize;
  final IconAlignment? iconAlignment;
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;
  final WidgetStateProperty<Size?>? minimumSize, fixedSize, maximumSize;
  final WidgetStateProperty<BorderSide?>? side;
  final WidgetStateProperty<OutlinedBorder?>? shape;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? tapTargetSize;
  final Duration? animationDuration;
  final bool? enableFeedback;
  final AlignmentGeometry? alignment;
  final InteractiveInkFeatureFactory? splashFactory;
  final ButtonLayerBuilder? backgroundBuilder, foregroundBuilder;

  /// Fills this style's null properties from [style].
  ButtonStyle merge(ButtonStyle? style) => style == null
      ? this
      : copyWith(
          textStyle: textStyle ?? style.textStyle,
          backgroundColor: backgroundColor ?? style.backgroundColor,
          foregroundColor: foregroundColor ?? style.foregroundColor,
          overlayColor: overlayColor ?? style.overlayColor,
          shadowColor: shadowColor ?? style.shadowColor,
          surfaceTintColor: surfaceTintColor ?? style.surfaceTintColor,
          elevation: elevation ?? style.elevation,
          padding: padding ?? style.padding,
          minimumSize: minimumSize ?? style.minimumSize,
          fixedSize: fixedSize ?? style.fixedSize,
          maximumSize: maximumSize ?? style.maximumSize,
          iconColor: iconColor ?? style.iconColor,
          iconSize: iconSize ?? style.iconSize,
          iconAlignment: iconAlignment ?? style.iconAlignment,
          side: side ?? style.side,
          shape: shape ?? style.shape,
          mouseCursor: mouseCursor ?? style.mouseCursor,
          visualDensity: visualDensity ?? style.visualDensity,
          tapTargetSize: tapTargetSize ?? style.tapTargetSize,
          animationDuration: animationDuration ?? style.animationDuration,
          enableFeedback: enableFeedback ?? style.enableFeedback,
          alignment: alignment ?? style.alignment,
          splashFactory: splashFactory ?? style.splashFactory,
          backgroundBuilder: backgroundBuilder ?? style.backgroundBuilder,
          foregroundBuilder: foregroundBuilder ?? style.foregroundBuilder,
        );

  ButtonStyle copyWith({
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<Color?>? shadowColor,
    WidgetStateProperty<Color?>? surfaceTintColor,
    WidgetStateProperty<double?>? elevation,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<Size?>? fixedSize,
    WidgetStateProperty<Size?>? maximumSize,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<double?>? iconSize,
    IconAlignment? iconAlignment,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
    ButtonLayerBuilder? backgroundBuilder,
    ButtonLayerBuilder? foregroundBuilder,
  }) => ButtonStyle(
    textStyle: textStyle ?? this.textStyle,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    overlayColor: overlayColor ?? this.overlayColor,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    elevation: elevation ?? this.elevation,
    padding: padding ?? this.padding,
    minimumSize: minimumSize ?? this.minimumSize,
    fixedSize: fixedSize ?? this.fixedSize,
    maximumSize: maximumSize ?? this.maximumSize,
    iconColor: iconColor ?? this.iconColor,
    iconSize: iconSize ?? this.iconSize,
    iconAlignment: iconAlignment ?? this.iconAlignment,
    side: side ?? this.side,
    shape: shape ?? this.shape,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    visualDensity: visualDensity ?? this.visualDensity,
    tapTargetSize: tapTargetSize ?? this.tapTargetSize,
    animationDuration: animationDuration ?? this.animationDuration,
    enableFeedback: enableFeedback ?? this.enableFeedback,
    alignment: alignment ?? this.alignment,
    splashFactory: splashFactory ?? this.splashFactory,
    backgroundBuilder: backgroundBuilder ?? this.backgroundBuilder,
    foregroundBuilder: foregroundBuilder ?? this.foregroundBuilder,
  );

  static ButtonStyle? lerp(ButtonStyle? a, ButtonStyle? b, double t) =>
      t < 0.5 ? a : b;
}

WidgetStateProperty<T?>? _allOrNull<T>(T? value) =>
    value == null ? null : WidgetStatePropertyAll<T?>(value);

WidgetStateProperty<Color?>? _disabledAware(Color? enabled, Color? disabled) =>
    enabled == null && disabled == null
    ? null
    : WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? disabled : enabled,
      );

WidgetStateProperty<MouseCursor?>? _cursorFor(
  MouseCursor? enabled,
  MouseCursor? disabled,
) => enabled == null && disabled == null
    ? null
    : WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? disabled : enabled,
      );

ButtonStyle _styleFrom({
  Color? foregroundColor,
  Color? backgroundColor,
  Color? disabledForegroundColor,
  Color? disabledBackgroundColor,
  Color? shadowColor,
  Color? surfaceTintColor,
  Color? iconColor,
  double? iconSize,
  IconAlignment? iconAlignment,
  Color? disabledIconColor,
  Color? overlayColor,
  double? elevation,
  TextStyle? textStyle,
  EdgeInsetsGeometry? padding,
  Size? minimumSize,
  Size? fixedSize,
  Size? maximumSize,
  BorderSide? side,
  OutlinedBorder? shape,
  MouseCursor? enabledMouseCursor,
  MouseCursor? disabledMouseCursor,
  VisualDensity? visualDensity,
  MaterialTapTargetSize? tapTargetSize,
  Duration? animationDuration,
  bool? enableFeedback,
  AlignmentGeometry? alignment,
  InteractiveInkFeatureFactory? splashFactory,
  ButtonLayerBuilder? backgroundBuilder,
  ButtonLayerBuilder? foregroundBuilder,
}) => ButtonStyle(
  foregroundColor: _disabledAware(foregroundColor, disabledForegroundColor),
  backgroundColor: _disabledAware(backgroundColor, disabledBackgroundColor),
  shadowColor: _allOrNull(shadowColor),
  surfaceTintColor: _allOrNull(surfaceTintColor),
  iconColor: _disabledAware(iconColor, disabledIconColor),
  iconSize: _allOrNull(iconSize),
  iconAlignment: iconAlignment,
  overlayColor: overlayColor == null
      ? null
      : WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? overlayColor.withValues(alpha: 0.1)
              : states.contains(WidgetState.hovered)
              ? overlayColor.withValues(alpha: 0.08)
              : states.contains(WidgetState.focused)
              ? overlayColor.withValues(alpha: 0.1)
              : null,
        ),
  elevation: _allOrNull(elevation),
  textStyle: _allOrNull(textStyle),
  padding: _allOrNull(padding),
  minimumSize: _allOrNull(minimumSize),
  fixedSize: _allOrNull(fixedSize),
  maximumSize: _allOrNull(maximumSize),
  side: _allOrNull(side),
  shape: _allOrNull(shape),
  mouseCursor: _cursorFor(enabledMouseCursor, disabledMouseCursor),
  visualDensity: visualDensity,
  tapTargetSize: tapTargetSize,
  animationDuration: animationDuration,
  enableFeedback: enableFeedback,
  alignment: alignment,
  splashFactory: splashFactory,
  backgroundBuilder: backgroundBuilder,
  foregroundBuilder: foregroundBuilder,
);

/// Shared native implementation of Material buttons: a real `<button>` with
/// disabled semantics, keyboard activation and focus from the browser.
///
/// As in Flutter, each property resolves from the widget's [style], then
/// the component theme's style ([themeStyleOf]), then [defaultStyleOf].
abstract class ButtonStyleButton extends StatelessWidget {
  const ButtonStyleButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior,
    this.statesController,
    this.isSemanticButton = true,
    this.iconAlignment,
    this.tooltip,
    required this.child,
  });
  final VoidCallback? onPressed, onLongPress;
  final ValueChanged<bool>? onHover, onFocusChange;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip? clipBehavior;
  final WidgetStatesController? statesController;
  final bool? isSemanticButton;
  final IconAlignment? iconAlignment;
  final String? tooltip;
  final Widget? child;
  bool get enabled => onPressed != null || onLongPress != null;
  ButtonStyle defaultStyleOf(BuildContext context);
  ButtonStyle? themeStyleOf(BuildContext context) => null;
  Set<WidgetState> get _extraStates => const {};

  static WidgetStateProperty<T>? allOrNull<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T>(value);

  static EdgeInsetsGeometry scaledPadding(
    EdgeInsetsGeometry geometry1x,
    EdgeInsetsGeometry geometry2x,
    EdgeInsetsGeometry geometry3x,
    double fontSizeMultiplier,
  ) => fontSizeMultiplier <= 1
      ? geometry1x
      : fontSizeMultiplier < 2
      ? geometry2x
      : geometry3x;

  @override
  Widget build(BuildContext context) {
    final states = <WidgetState>{
      ...?statesController?.value,
      ..._extraStates,
      if (!enabled) WidgetState.disabled,
    };
    final widgetStyle = style;
    final themeStyle = themeStyleOf(context);
    final defaults = defaultStyleOf(context);
    T? pick<T>(T? Function(ButtonStyle? style) get) =>
        get(widgetStyle) ?? get(themeStyle) ?? get(defaults);
    T? resolveIn<T>(
      WidgetStateProperty<T?>? Function(ButtonStyle? style) get,
      Set<WidgetState> states,
    ) =>
        get(widgetStyle)?.resolve(states) ??
        get(themeStyle)?.resolve(states) ??
        get(defaults)?.resolve(states);
    T? resolve<T>(WidgetStateProperty<T?>? Function(ButtonStyle? style) get) =>
        resolveIn(get, states);
    final scheme = Theme.of(context).colorScheme;
    final foreground = resolve((s) => s?.foregroundColor) ?? scheme.primary;
    final background = resolve((s) => s?.backgroundColor);
    final text = Theme.of(
      context,
    ).textTheme.labelLarge!.merge(resolve((s) => s?.textStyle));
    final padding =
        resolve((s) => s?.padding) ??
        const EdgeInsets.symmetric(horizontal: 24);
    final minimum = resolve((s) => s?.minimumSize) ?? const Size(64, 40);
    final fixed = resolve((s) => s?.fixedSize);
    final maximum = resolve((s) => s?.maximumSize);
    final side = resolve((s) => s?.side);
    final shape = resolve((s) => s?.shape) ?? const StadiumBorder();
    final elevation = resolve((s) => s?.elevation) ?? 0;
    final iconColor = resolve((s) => s?.iconColor) ?? foreground;
    final iconSize = resolve((s) => s?.iconSize) ?? 18;
    final shadow = resolve((s) => s?.shadowColor) ?? scheme.shadow;
    final cursor = resolve((s) => s?.mouseCursor);
    final alignment = pick((s) => s?.alignment);
    final splash =
        pick((s) => s?.splashFactory) ?? Theme.of(context).splashFactory;
    final hoverOverlay = resolveIn((s) => s?.overlayColor, {
      ...states,
      WidgetState.hovered,
    });
    final pressOverlay = resolveIn((s) => s?.overlayColor, {
      ...states,
      WidgetState.pressed,
    });
    final css = StringBuffer(
      'display:inline-flex;align-items:center;justify-content:center;gap:8px;box-sizing:border-box;flex-shrink:0;margin:0;border:0;font:inherit;text-align:center;',
    )..write(textStyleCss(text.copyWith(color: foreground)));
    css.write(
      'background-color:${background == null ? 'transparent' : colorCss(background)};',
    );
    css.write(edgeInsetsCss('padding', padding));
    if (minimum.width.isFinite && minimum.width > 0)
      css.write('min-width:${px(minimum.width)};');
    if (minimum.height.isFinite && minimum.height > 0)
      css.write('min-height:${px(minimum.height)};');
    if (fixed != null) {
      if (fixed.width.isFinite) css.write('width:${px(fixed.width)};');
      if (fixed.height.isFinite) css.write('height:${px(fixed.height)};');
    }
    if (maximum != null && maximum.width.isFinite)
      css.write('max-width:${px(maximum.width)};');
    css.write(shapeCss(shape));
    if (side != null) css.write(borderSideCss('border', side));
    css.write(elevationCss(elevation, shadow));
    if (alignment != null) {
      final a = alignment.resolve(TextDirection.ltr);
      css.write(
        'justify-content:${a.x < 0
            ? 'flex-start'
            : a.x > 0
            ? 'flex-end'
            : 'center'};',
      );
    }
    css.write(_stateLayerCss(foreground));
    if (hoverOverlay != null)
      css.write('--fd-hover:${colorCss(hoverOverlay)};');
    if (_noSplash(splash)) {
      css.write('--fd-press:transparent;');
    } else if (pressOverlay != null) {
      css.write('--fd-press:${colorCss(pressOverlay)};');
    }
    if (cursor != null) css.write('cursor:${cursor._css};');
    if (clipBehavior != null && clipBehavior != Clip.none)
      css.write('overflow:hidden;');
    final semantic = isSemanticButton ?? true;
    Widget? content = child;
    final iconSide = iconAlignment ?? pick((s) => s?.iconAlignment);
    if (content is _IconLabel && content.alignment == null && iconSide != null)
      content = _IconLabel(content.icon, content.label, iconSide);
    return _Box(
      tag: semantic ? 'button' : 'div',
      css: css.toString(),
      fill: _Fill.none,
      layout: _DomLayout.row,
      attributes: {
        if (semantic) 'type': 'button',
        if (!semantic && enabled) 'tabindex': '0',
        'class': 'fd-ink fd-button',
        if (!enabled) 'disabled': '',
        if (!enabled && !semantic) 'aria-disabled': 'true',
        if (autofocus) 'autofocus': '',
        if (tooltip != null) 'title': tooltip!,
        if (tooltip != null && child is Icon) 'aria-label': tooltip!,
      },
      handlers: {
        if (onPressed != null) 'click': (_) => onPressed!(),
        if (onHover != null) 'mouseenter': (_) => onHover!(true),
        if (onHover != null) 'mouseleave': (_) => onHover!(false),
        if (onFocusChange != null || statesController != null)
          'focus': (_) {
            statesController?.update(WidgetState.focused, true);
            onFocusChange?.call(true);
          },
        if (onFocusChange != null || statesController != null)
          'blur': (_) {
            statesController?.update(WidgetState.focused, false);
            onFocusChange?.call(false);
          },
      },
      gestures: enabled && onLongPress != null
          ? _GestureCallbacks(onLongPress: onLongPress)
          : null,
      children: [
        if (content != null)
          IconTheme.merge(
            data: IconThemeData(color: iconColor, size: iconSize),
            child: DefaultTextStyle(
              style: text.copyWith(color: foreground),
              child: content,
            ),
          ),
      ],
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel(this.icon, this.label, [this.alignment]);
  final Widget? icon;
  final Widget label;
  final IconAlignment? alignment;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: alignment == IconAlignment.end
        ? [Flexible(child: label), ?icon]
        : [?icon, Flexible(child: label)],
  );
}

class ElevatedButton extends ButtonStyleButton {
  const ElevatedButton({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus,
    super.clipBehavior,
    super.statesController,
    required super.child,
    super.iconAlignment,
  });
  ElevatedButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    ValueChanged<bool>? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    WidgetStatesController? statesController,
    Widget? icon,
    required Widget label,
    IconAlignment? iconAlignment,
  }) : this(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         onHover: onHover,
         onFocusChange: onFocusChange,
         style: style,
         focusNode: focusNode,
         autofocus: autofocus ?? false,
         clipBehavior: clipBehavior,
         statesController: statesController,
         iconAlignment: iconAlignment,
         child: _IconLabel(icon, label),
       );
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? iconColor,
    double? iconSize,
    IconAlignment? iconAlignment,
    Color? disabledIconColor,
    Color? overlayColor,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
    ButtonLayerBuilder? backgroundBuilder,
    ButtonLayerBuilder? foregroundBuilder,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    iconColor: iconColor,
    iconSize: iconSize,
    iconAlignment: iconAlignment,
    disabledIconColor: disabledIconColor,
    overlayColor: overlayColor,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    enabledMouseCursor: enabledMouseCursor,
    disabledMouseCursor: disabledMouseCursor,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
    animationDuration: animationDuration,
    enableFeedback: enableFeedback,
    alignment: alignment,
    splashFactory: splashFactory,
    backgroundBuilder: backgroundBuilder,
    foregroundBuilder: foregroundBuilder,
  );
  @override
  ButtonStyle? themeStyleOf(BuildContext context) =>
      ElevatedButtonTheme.of(context).style;
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ButtonStyle(
      foregroundColor: _disabledAware(
        scheme.primary,
        scheme.onSurface.withValues(alpha: 0.38),
      ),
      backgroundColor: _disabledAware(
        scheme.surfaceContainerLow,
        scheme.onSurface.withValues(alpha: 0.12),
      ),
      elevation: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? 0.0 : 1.0,
      ),
    );
  }
}

class FilledButton extends ButtonStyleButton {
  const FilledButton({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus,
    super.clipBehavior,
    super.statesController,
    required super.child,
  }) : _tonal = false;
  const FilledButton.tonal({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus,
    super.clipBehavior,
    super.statesController,
    required super.child,
  }) : _tonal = true;
  FilledButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    ValueChanged<bool>? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    WidgetStatesController? statesController,
    Widget? icon,
    required Widget label,
    IconAlignment? iconAlignment,
  }) : this(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         onHover: onHover,
         onFocusChange: onFocusChange,
         style: style,
         focusNode: focusNode,
         autofocus: autofocus ?? false,
         clipBehavior: clipBehavior,
         statesController: statesController,
         child: _IconLabel(icon, label, iconAlignment),
       );
  FilledButton.tonalIcon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    ValueChanged<bool>? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    WidgetStatesController? statesController,
    Widget? icon,
    required Widget label,
    IconAlignment? iconAlignment,
  }) : this.tonal(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         onHover: onHover,
         onFocusChange: onFocusChange,
         style: style,
         focusNode: focusNode,
         autofocus: autofocus ?? false,
         clipBehavior: clipBehavior,
         statesController: statesController,
         child: _IconLabel(icon, label, iconAlignment),
       );
  final bool _tonal;
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? iconColor,
    double? iconSize,
    IconAlignment? iconAlignment,
    Color? disabledIconColor,
    Color? overlayColor,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
    ButtonLayerBuilder? backgroundBuilder,
    ButtonLayerBuilder? foregroundBuilder,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    iconColor: iconColor,
    iconSize: iconSize,
    iconAlignment: iconAlignment,
    disabledIconColor: disabledIconColor,
    overlayColor: overlayColor,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    enabledMouseCursor: enabledMouseCursor,
    disabledMouseCursor: disabledMouseCursor,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
    animationDuration: animationDuration,
    enableFeedback: enableFeedback,
    alignment: alignment,
    splashFactory: splashFactory,
    backgroundBuilder: backgroundBuilder,
    foregroundBuilder: foregroundBuilder,
  );
  @override
  ButtonStyle? themeStyleOf(BuildContext context) =>
      FilledButtonTheme.of(context).style;
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ButtonStyle(
      foregroundColor: _disabledAware(
        _tonal ? scheme.onSecondaryContainer : scheme.onPrimary,
        scheme.onSurface.withValues(alpha: 0.38),
      ),
      backgroundColor: _disabledAware(
        _tonal ? scheme.secondaryContainer : scheme.primary,
        scheme.onSurface.withValues(alpha: 0.12),
      ),
    );
  }
}

class OutlinedButton extends ButtonStyleButton {
  const OutlinedButton({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus,
    super.clipBehavior,
    super.statesController,
    required super.child,
    super.iconAlignment,
  });
  OutlinedButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    ValueChanged<bool>? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    WidgetStatesController? statesController,
    Widget? icon,
    required Widget label,
    IconAlignment? iconAlignment,
  }) : this(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         onHover: onHover,
         onFocusChange: onFocusChange,
         style: style,
         focusNode: focusNode,
         autofocus: autofocus ?? false,
         clipBehavior: clipBehavior,
         statesController: statesController,
         iconAlignment: iconAlignment,
         child: _IconLabel(icon, label),
       );
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? iconColor,
    double? iconSize,
    IconAlignment? iconAlignment,
    Color? disabledIconColor,
    Color? overlayColor,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
    ButtonLayerBuilder? backgroundBuilder,
    ButtonLayerBuilder? foregroundBuilder,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    iconColor: iconColor,
    iconSize: iconSize,
    iconAlignment: iconAlignment,
    disabledIconColor: disabledIconColor,
    overlayColor: overlayColor,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    enabledMouseCursor: enabledMouseCursor,
    disabledMouseCursor: disabledMouseCursor,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
    animationDuration: animationDuration,
    enableFeedback: enableFeedback,
    alignment: alignment,
    splashFactory: splashFactory,
    backgroundBuilder: backgroundBuilder,
    foregroundBuilder: foregroundBuilder,
  );
  @override
  ButtonStyle? themeStyleOf(BuildContext context) =>
      OutlinedButtonTheme.of(context).style;
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ButtonStyle(
      foregroundColor: _disabledAware(
        scheme.primary,
        scheme.onSurface.withValues(alpha: 0.38),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.12)
              : scheme.outline,
        ),
      ),
    );
  }
}

class TextButton extends ButtonStyleButton {
  const TextButton({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus,
    super.clipBehavior,
    super.statesController,
    super.isSemanticButton,
    required Widget super.child,
    super.iconAlignment,
  });
  TextButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    ValueChanged<bool>? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    WidgetStatesController? statesController,
    Widget? icon,
    required Widget label,
    IconAlignment? iconAlignment,
  }) : this(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         onHover: onHover,
         onFocusChange: onFocusChange,
         style: style,
         focusNode: focusNode,
         autofocus: autofocus ?? false,
         clipBehavior: clipBehavior,
         statesController: statesController,
         iconAlignment: iconAlignment,
         child: _IconLabel(icon, label),
       );
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? iconColor,
    double? iconSize,
    IconAlignment? iconAlignment,
    Color? disabledIconColor,
    Color? overlayColor,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
    ButtonLayerBuilder? backgroundBuilder,
    ButtonLayerBuilder? foregroundBuilder,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    iconColor: iconColor,
    iconSize: iconSize,
    iconAlignment: iconAlignment,
    disabledIconColor: disabledIconColor,
    overlayColor: overlayColor,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    enabledMouseCursor: enabledMouseCursor,
    disabledMouseCursor: disabledMouseCursor,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
    animationDuration: animationDuration,
    enableFeedback: enableFeedback,
    alignment: alignment,
    splashFactory: splashFactory,
    backgroundBuilder: backgroundBuilder,
    foregroundBuilder: foregroundBuilder,
  );
  @override
  ButtonStyle? themeStyleOf(BuildContext context) =>
      TextButtonTheme.of(context).style;
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ButtonStyle(
      foregroundColor: _disabledAware(
        scheme.primary,
        scheme.onSurface.withValues(alpha: 0.38),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

enum _IconButtonVariant { standard, filled, filledTonal, outlined }

class IconButton extends StatelessWidget {
  const IconButton({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.onHover,
    this.onLongPress,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    required this.icon,
  }) : _variant = _IconButtonVariant.standard;
  const IconButton.filled({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.onHover,
    this.onLongPress,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    required this.icon,
  }) : _variant = _IconButtonVariant.filled;
  const IconButton.filledTonal({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.onHover,
    this.onLongPress,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    required this.icon,
  }) : _variant = _IconButtonVariant.filledTonal;
  const IconButton.outlined({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.onHover,
    this.onLongPress,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    required this.icon,
  }) : _variant = _IconButtonVariant.outlined;
  final double? iconSize, splashRadius;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final Color? color, focusColor, hoverColor, highlightColor, splashColor;
  final Color? disabledColor;
  final VoidCallback? onPressed, onLongPress;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  final bool? enableFeedback;
  final BoxConstraints? constraints;
  final ButtonStyle? style;
  final bool? isSelected;
  final Widget? selectedIcon;
  final Widget icon;
  final _IconButtonVariant _variant;

  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? overlayColor,
    double? elevation,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    double? iconSize,
    BorderSide? side,
    OutlinedBorder? shape,
    EdgeInsetsGeometry? padding,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
    ButtonLayerBuilder? backgroundBuilder,
    ButtonLayerBuilder? foregroundBuilder,
  }) {
    final base = _styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      iconColor: foregroundColor,
      disabledIconColor: disabledForegroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      overlayColor: overlayColor,
      elevation: elevation,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      iconSize: iconSize,
      side: side,
      shape: shape,
      padding: padding,
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
      backgroundBuilder: backgroundBuilder,
      foregroundBuilder: foregroundBuilder,
    );
    if (overlayColor != null || (hoverColor == null && highlightColor == null))
      return base;
    return base.copyWith(
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? highlightColor
            : states.contains(WidgetState.hovered)
            ? hoverColor
            : states.contains(WidgetState.focused)
            ? focusColor
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = isSelected == true;
    // Widget parameters form a style that the explicit [style] overrides.
    var adjusted = styleFrom(
      foregroundColor: color,
      disabledForegroundColor: disabledColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      iconSize: iconSize,
      padding: padding,
      minimumSize: constraints == null
          ? null
          : Size(constraints!.minWidth, constraints!.minHeight),
      maximumSize: constraints == null
          ? null
          : Size(constraints!.maxWidth, constraints!.maxHeight),
      visualDensity: visualDensity,
      enabledMouseCursor: mouseCursor,
      enableFeedback: enableFeedback,
      alignment: alignment,
    );
    if (style != null) adjusted = style!.merge(adjusted);
    return _IconButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      onHover: onHover,
      focusNode: focusNode,
      autofocus: autofocus,
      tooltip: tooltip,
      style: adjusted,
      selected: selected,
      variant: _variant,
      child: selected && selectedIcon != null ? selectedIcon! : icon,
    );
  }
}

class _IconButton extends ButtonStyleButton {
  const _IconButton({
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.focusNode,
    super.autofocus,
    super.style,
    super.tooltip,
    this.selected = false,
    this.variant = _IconButtonVariant.standard,
    this.useTheme = true,
    required super.child,
  });
  final bool selected, useTheme;
  final _IconButtonVariant variant;
  @override
  Set<WidgetState> get _extraStates =>
      selected ? const {WidgetState.selected} : const {};
  @override
  ButtonStyle? themeStyleOf(BuildContext context) =>
      useTheme ? IconButtonTheme.of(context).style : null;
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    if (!useTheme) return const ButtonStyle();
    final scheme = Theme.of(context).colorScheme;
    final disabled = scheme.onSurface.withValues(alpha: 0.38);
    Color foreground(Set<WidgetState> states) => switch (variant) {
      _ when states.contains(WidgetState.disabled) => disabled,
      _IconButtonVariant.filled => scheme.onPrimary,
      _IconButtonVariant.filledTonal => scheme.onSecondaryContainer,
      _ when states.contains(WidgetState.selected) =>
        variant == _IconButtonVariant.outlined
            ? scheme.onInverseSurface
            : scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith(foreground),
      iconColor: WidgetStateProperty.resolveWith(foreground),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => switch (variant) {
          _IconButtonVariant.standard => null,
          _ when states.contains(WidgetState.disabled) =>
            variant == _IconButtonVariant.outlined
                ? null
                : scheme.onSurface.withValues(alpha: 0.12),
          _IconButtonVariant.filled => scheme.primary,
          _IconButtonVariant.filledTonal => scheme.secondaryContainer,
          _IconButtonVariant.outlined =>
            states.contains(WidgetState.selected)
                ? scheme.inverseSurface
                : null,
        },
      ),
      side: variant == _IconButtonVariant.outlined
          ? WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? null
                  : BorderSide(
                      color: states.contains(WidgetState.disabled)
                          ? scheme.onSurface.withValues(alpha: 0.12)
                          : scheme.outline,
                    ),
            )
          : null,
      iconSize: const WidgetStatePropertyAll(24),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      shape: const WidgetStatePropertyAll(CircleBorder()),
    );
  }
}

enum _FabSize { regular, small, large, extended }

class FloatingActionButton extends StatelessWidget {
  const FloatingActionButton({
    super.key,
    this.child,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.heroTag,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.highlightElevation,
    this.disabledElevation,
    required this.onPressed,
    this.mouseCursor,
    this.mini = false,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.materialTapTargetSize,
    this.isExtended = false,
    this.enableFeedback,
  }) : _label = null,
       _size = mini ? _FabSize.small : _FabSize.regular,
       extendedIconLabelSpacing = null,
       extendedPadding = null,
       extendedTextStyle = null;
  const FloatingActionButton.small({
    super.key,
    this.child,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.heroTag,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.highlightElevation,
    this.disabledElevation,
    required this.onPressed,
    this.mouseCursor,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.materialTapTargetSize,
    this.enableFeedback,
  }) : _label = null,
       _size = _FabSize.small,
       mini = true,
       isExtended = false,
       extendedIconLabelSpacing = null,
       extendedPadding = null,
       extendedTextStyle = null;
  const FloatingActionButton.large({
    super.key,
    this.child,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.heroTag,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.highlightElevation,
    this.disabledElevation,
    required this.onPressed,
    this.mouseCursor,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.materialTapTargetSize,
    this.enableFeedback,
  }) : _label = null,
       _size = _FabSize.large,
       mini = false,
       isExtended = false,
       extendedIconLabelSpacing = null,
       extendedPadding = null,
       extendedTextStyle = null;
  const FloatingActionButton.extended({
    super.key,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.heroTag,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.splashColor,
    this.highlightElevation,
    this.disabledElevation,
    required this.onPressed,
    this.mouseCursor,
    this.shape,
    this.isExtended = true,
    this.materialTapTargetSize,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.extendedIconLabelSpacing,
    this.extendedPadding,
    this.extendedTextStyle,
    Widget? icon,
    required Widget label,
    this.enableFeedback,
  }) : _label = label,
       child = icon,
       _size = _FabSize.extended,
       mini = false;
  final Widget? child;
  final Widget? _label;
  final _FabSize _size;
  final String? tooltip;
  final Color? foregroundColor, backgroundColor;
  final Color? focusColor, hoverColor, splashColor;
  final Object? heroTag;
  final double? elevation, focusElevation, hoverElevation;
  final double? highlightElevation, disabledElevation;
  final VoidCallback? onPressed;
  final MouseCursor? mouseCursor;
  final bool mini;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool autofocus;
  final MaterialTapTargetSize? materialTapTargetSize;
  final bool isExtended;
  final bool? enableFeedback;
  final double? extendedIconLabelSpacing;
  final EdgeInsetsGeometry? extendedPadding;
  final TextStyle? extendedTextStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fabTheme = Theme.of(context).floatingActionButtonTheme;
    final extended = _size == _FabSize.extended;
    final constraints = switch (_size) {
      _FabSize.small => fabTheme.smallSizeConstraints,
      _FabSize.large => fabTheme.largeSizeConstraints,
      _FabSize.extended => fabTheme.extendedSizeConstraints,
      _FabSize.regular => fabTheme.sizeConstraints,
    };
    final size = switch (_size) {
      _FabSize.small => 40.0,
      _FabSize.large => 96.0,
      _ => 56.0,
    };
    final radius = switch (_size) {
      _FabSize.small => 12.0,
      _FabSize.large => 28.0,
      _ => 16.0,
    };
    final resolvedShape = shape ?? fabTheme.shape;
    final iconSize =
        fabTheme.iconSize ?? (_size == _FabSize.large ? 36.0 : 24.0);
    final textStyle = extendedTextStyle ?? fabTheme.extendedTextStyle;
    return _IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      autofocus: autofocus,
      focusNode: focusNode,
      useTheme: false,
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          foregroundColor ??
              fabTheme.foregroundColor ??
              scheme.onPrimaryContainer,
        ),
        backgroundColor: WidgetStatePropertyAll(
          backgroundColor ??
              fabTheme.backgroundColor ??
              scheme.primaryContainer,
        ),
        iconSize: WidgetStatePropertyAll(iconSize),
        textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
        elevation: WidgetStatePropertyAll(
          onPressed == null
              ? disabledElevation ??
                    fabTheme.disabledElevation ??
                    elevation ??
                    fabTheme.elevation ??
                    6
              : elevation ?? fabTheme.elevation ?? 6,
        ),
        padding: WidgetStatePropertyAll(
          extended
              ? extendedPadding ??
                    fabTheme.extendedPadding ??
                    const EdgeInsets.symmetric(horizontal: 16)
              : EdgeInsets.zero,
        ),
        minimumSize: WidgetStatePropertyAll(
          constraints != null
              ? Size(constraints.minWidth, constraints.minHeight)
              : Size(extended ? 80 : size, size),
        ),
        fixedSize: extended || constraints == null
            ? null
            : WidgetStatePropertyAll(
                Size(constraints.maxWidth, constraints.maxHeight),
              ),
        mouseCursor: mouseCursor == null
            ? null
            : WidgetStatePropertyAll(mouseCursor),
        shape: WidgetStatePropertyAll(
          resolvedShape is OutlinedBorder
              ? resolvedShape
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
        ),
      ),
      child: extended
          ? (isExtended ? _IconLabel(child, _label!) : child ?? _label)
          : child,
    );
  }
}

// ---------------------------------------------------------------------------
// Ink and list tiles.

/// Clickable region with button semantics. Enter and Space activate it when
/// enabled; without callbacks it is neither focusable nor interactive.
class InkWell extends StatelessWidget {
  const InkWell({
    super.key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.onHighlightChanged,
    this.onHover,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.overlayColor,
    this.splashColor,
    this.splashFactory,
    this.radius,
    this.borderRadius,
    this.customBorder,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
    this.statesController,
    this.hoverDuration,
  });
  final Widget? child;
  final VoidCallback? onTap, onDoubleTap, onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTapCancel, onSecondaryTap;
  final ValueChanged<bool>? onHighlightChanged, onHover, onFocusChange;
  final MouseCursor? mouseCursor;
  final Color? focusColor, hoverColor, highlightColor, splashColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final InteractiveInkFeatureFactory? splashFactory;
  final double? radius;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final bool enableFeedback, excludeFromSemantics, canRequestFocus, autofocus;
  final FocusNode? focusNode;
  final WidgetStatesController? statesController;
  final Duration? hoverDuration;

  @override
  Widget build(BuildContext context) {
    final enabled =
        onTap != null ||
        onDoubleTap != null ||
        onLongPress != null ||
        onTapDown != null ||
        onTapUp != null ||
        onSecondaryTap != null;
    final theme = Theme.of(context);
    final overlay =
        overlayColor?.resolve(const {WidgetState.hovered}) ??
        hoverColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final press = _noSplash(splashFactory ?? theme.splashFactory)
        ? null
        : overlayColor?.resolve(const {WidgetState.pressed}) ??
              highlightColor ??
              overlay;
    final handlers = <String, _DomHandler>{
      ..._activationHandlers(onTap),
      if (onDoubleTap != null) 'dblclick': (_) => onDoubleTap!(),
      if (onSecondaryTap != null)
        'contextmenu': (event) {
          event?.preventDefault();
          onSecondaryTap!();
        },
      if (onHover != null) 'mouseenter': (_) => onHover!(true),
      if (onHover != null) 'mouseleave': (_) => onHover!(false),
      if (onFocusChange != null) 'focus': (_) => onFocusChange!(true),
      if (onFocusChange != null) 'blur': (_) => onFocusChange!(false),
    };
    return _Box(
      css:
          'box-sizing:border-box;min-width:0;${borderRadiusCss(borderRadius)}${customBorder == null ? '' : shapeCss(customBorder)}'
          '${enabled ? '--fd-hover:${colorCss(overlay)};--fd-press:${press == null ? 'transparent' : colorCss(press)};--fd-focus:${colorCss(theme.colorScheme.primary)};' : ''}'
          '${mouseCursor == null ? '' : 'cursor:${mouseCursor!._css};'}',
      attributes: {
        if (enabled && !excludeFromSemantics) 'role': 'button',
        if (enabled && canRequestFocus) 'tabindex': '0',
        if (enabled) 'class': 'fd-ink',
      },
      handlers: handlers,
      gestures:
          onLongPress == null &&
              onTapDown == null &&
              onTapUp == null &&
              onTapCancel == null
          ? null
          : _GestureCallbacks(
              onLongPress: onLongPress,
              onTapDown: onTapDown,
              onTapUp: onTapUp,
              onTapCancel: onTapCancel,
            ),
      layout: _DomLayout.grid,
      children: [?child],
    );
  }
}

class InkResponse extends InkWell {
  const InkResponse({
    super.key,
    super.child,
    super.onTap,
    super.onTapDown,
    super.onTapUp,
    super.onTapCancel,
    super.onDoubleTap,
    super.onLongPress,
    super.onSecondaryTap,
    super.onHighlightChanged,
    super.onHover,
    super.mouseCursor,
    this.containedInkWell = false,
    this.highlightShape = BoxShape.circle,
    super.radius,
    super.borderRadius,
    super.customBorder,
    super.focusColor,
    super.hoverColor,
    super.highlightColor,
    super.overlayColor,
    super.splashColor,
    super.splashFactory,
    super.enableFeedback,
    super.excludeFromSemantics,
    super.focusNode,
    super.canRequestFocus,
    super.onFocusChange,
    super.autofocus,
    super.statesController,
    super.hoverDuration,
  });
  final bool containedInkWell;
  final BoxShape highlightShape;
}

class ListTile extends StatelessWidget {
  const ListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.visualDensity,
    this.shape,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.tileColor,
    this.selectedTileColor,
    this.iconColor,
    this.textColor,
    this.selectedColor,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.style,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.focusNode,
    this.autofocus = false,
    this.enableFeedback,
    this.onFocusChange,
    this.titleAlignment,
    this.internalAddSemanticForOnTap = false,
    this.statesController,
  });
  final Widget? leading, title, subtitle, trailing;
  final bool isThreeLine, enabled, selected, autofocus;
  final bool internalAddSemanticForOnTap;
  final TextStyle? leadingAndTrailingTextStyle;
  final ListTileStyle? style;
  final Color? focusColor, hoverColor, splashColor;
  final FocusNode? focusNode;
  final bool? enableFeedback;
  final ValueChanged<bool>? onFocusChange;
  final ListTileTitleAlignment? titleAlignment;
  final WidgetStatesController? statesController;
  final bool? dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onTap, onLongPress;
  final Color? tileColor, selectedTileColor, iconColor, textColor;
  final Color? selectedColor;
  final double? horizontalTitleGap, minVerticalPadding, minLeadingWidth;
  final double? minTileHeight;
  final TextStyle? titleTextStyle, subtitleTextStyle;
  final MouseCursor? mouseCursor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tileTheme = ListTileTheme.of(context);
    final compact = dense ?? tileTheme.dense ?? false;
    final disabled = scheme.onSurface.withValues(alpha: 0.38);
    final selectedForeground =
        selectedColor ?? tileTheme.selectedColor ?? scheme.primary;
    final titleColor = !enabled
        ? disabled
        : selected
        ? selectedForeground
        : textColor ?? tileTheme.textColor ?? scheme.onSurface;
    final leadingColor = !enabled
        ? disabled
        : selected
        ? selectedForeground
        : iconColor ?? tileTheme.iconColor ?? scheme.onSurfaceVariant;
    final explicitTitle = titleTextStyle ?? tileTheme.titleTextStyle;
    final titleStyle =
        (compact ? theme.textTheme.bodyMedium! : theme.textTheme.bodyLarge!)
            .merge(explicitTitle)
            .copyWith(
              color: !enabled || selected
                  ? titleColor
                  : textColor ??
                        tileTheme.textColor ??
                        explicitTitle?.color ??
                        titleColor,
            );
    final explicitSubtitle = subtitleTextStyle ?? tileTheme.subtitleTextStyle;
    final subtitleStyle = theme.textTheme.bodyMedium!
        .merge(explicitSubtitle)
        .copyWith(
          color: !enabled
              ? disabled
              : selected
              ? selectedForeground
              : textColor ??
                    tileTheme.textColor ??
                    explicitSubtitle?.color ??
                    scheme.onSurfaceVariant,
        );
    final trailingStyle = theme.textTheme.labelSmall!
        .merge(
          leadingAndTrailingTextStyle ?? tileTheme.leadingAndTrailingTextStyle,
        )
        .copyWith(color: enabled ? null : disabled);
    final threeLine = isThreeLine || (tileTheme.isThreeLine ?? false);
    final height =
        minTileHeight ??
        tileTheme.minTileHeight ??
        (subtitle == null
            ? (compact ? 48.0 : 56.0)
            : threeLine
            ? 88.0
            : (compact ? 64.0 : 72.0));
    final padding =
        contentPadding ??
        tileTheme.contentPadding ??
        const EdgeInsetsDirectional.only(start: 16, end: 24);
    final background = selected
        ? selectedTileColor ??
              tileTheme.selectedTileColor ??
              tileColor ??
              tileTheme.tileColor
        : tileColor ?? tileTheme.tileColor;
    final tileShape = shape ?? tileTheme.shape;
    final gap = horizontalTitleGap ?? tileTheme.horizontalTitleGap ?? 16;
    final verticalPadding =
        minVerticalPadding ?? tileTheme.minVerticalPadding ?? 8;
    final leadingWidth = minLeadingWidth ?? tileTheme.minLeadingWidth;
    final align = switch (titleAlignment ?? tileTheme.titleAlignment) {
      ListTileTitleAlignment.top ||
      ListTileTitleAlignment.titleHeight => 'flex-start',
      ListTileTitleAlignment.bottom => 'flex-end',
      ListTileTitleAlignment.threeLine when threeLine => 'flex-start',
      _ => 'center',
    };
    final row = _Box(
      css:
          'display:flex;flex-direction:row;align-items:$align;gap:${px(gap)};box-sizing:border-box;min-height:${px(height)};${edgeInsetsCss('padding', padding)}'
          'padding-top:${px(verticalPadding)};padding-bottom:${px(verticalPadding)};'
          '${background == null ? '' : 'background-color:${colorCss(background)};'}${tileShape == null ? '' : shapeCss(tileShape)}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        if (leading != null)
          _Box(
            css:
                'display:flex;align-items:center;flex-shrink:0;${leadingWidth == null ? '' : 'min-width:${px(leadingWidth)};'}',
            layout: _DomLayout.row,
            fill: _Fill.none,
            children: [
              IconTheme.merge(
                data: IconThemeData(color: leadingColor),
                child: DefaultTextStyle(
                  style: titleStyle.copyWith(color: leadingColor),
                  child: leading!,
                ),
              ),
            ],
          ),
        _Box(
          css:
              'flex:1 1 0;min-width:0;display:flex;flex-direction:column;align-items:stretch;',
          layout: _DomLayout.column,
          children: [
            if (title != null)
              DefaultTextStyle(style: titleStyle, child: title!),
            if (subtitle != null)
              DefaultTextStyle(style: subtitleStyle, child: subtitle!),
          ],
        ),
        if (trailing != null)
          _Box(
            css: 'display:flex;align-items:center;flex-shrink:0;',
            layout: _DomLayout.row,
            fill: _Fill.none,
            children: [
              IconTheme.merge(
                data: IconThemeData(color: leadingColor),
                child: DefaultTextStyle(
                  style: trailingStyle.copyWith(
                    color: trailingStyle.color ?? scheme.onSurfaceVariant,
                  ),
                  child: trailing!,
                ),
              ),
            ],
          ),
      ],
    );
    if (!enabled || (onTap == null && onLongPress == null)) return row;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
      hoverColor: hoverColor,
      focusColor: focusColor,
      splashColor: splashColor,
      customBorder: tileShape,
      mouseCursor:
          mouseCursor ??
          tileTheme.mouseCursor?.resolve({if (selected) WidgetState.selected}),
      child: row,
    );
  }
}

class Divider extends StatelessWidget {
  const Divider({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
    this.radius,
  });
  final double? height, thickness, indent, endIndent;
  final Color? color;
  final BorderRadiusGeometry? radius;
  @override
  Widget build(BuildContext context) {
    final dividerTheme = DividerTheme.of(context);
    final extent = checkedDimension(height ?? dividerTheme.space ?? 16);
    final line = checkedDimension(thickness ?? dividerTheme.thickness ?? 1);
    final start = indent ?? dividerTheme.indent ?? 0;
    final end = endIndent ?? dividerTheme.endIndent ?? 0;
    final lineColor =
        color ?? dividerTheme.color ?? Theme.of(context).dividerColor;
    final margin = (extent - line) / 2;
    return _Box(
      css:
          'box-sizing:content-box;height:0;flex-shrink:0;border-top:${px(line)} solid ${colorCss(lineColor)};margin:${px(margin < 0 ? 0 : margin)} ${px(end)} ${px(margin < 0 ? 0 : margin)} ${px(start)};',
      attributes: const {'role': 'separator'},
      fill: _Fill.expand,
    );
  }
}

class VerticalDivider extends StatelessWidget {
  const VerticalDivider({
    super.key,
    this.width,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
    this.radius,
  });
  final double? width, thickness, indent, endIndent;
  final Color? color;
  final BorderRadiusGeometry? radius;
  @override
  Widget build(BuildContext context) {
    final dividerTheme = DividerTheme.of(context);
    final extent = checkedDimension(width ?? dividerTheme.space ?? 16);
    final line = checkedDimension(thickness ?? dividerTheme.thickness ?? 1);
    final start = indent ?? dividerTheme.indent ?? 0;
    final end = endIndent ?? dividerTheme.endIndent ?? 0;
    final lineColor =
        color ?? dividerTheme.color ?? Theme.of(context).dividerColor;
    final margin = (extent - line) / 2;
    return _Box(
      css:
          'box-sizing:content-box;width:0;flex-shrink:0;align-self:stretch;border-left:${px(line)} solid ${colorCss(lineColor)};margin:${px(start)} ${px(margin < 0 ? 0 : margin)} ${px(end)} ${px(margin < 0 ? 0 : margin)};',
      attributes: const {'role': 'separator', 'aria-orientation': 'vertical'},
      fill: _Fill.none,
    );
  }
}

class CircleAvatar extends StatelessWidget {
  const CircleAvatar({
    super.key,
    this.child,
    this.backgroundImage,
    this.backgroundColor,
    this.foregroundColor,
    this.radius,
    this.minRadius,
    this.maxRadius,
  });
  final Widget? child;
  final ImageProvider? backgroundImage;
  final Color? backgroundColor, foregroundColor;
  final double? radius, minRadius, maxRadius;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = checkedDimension(radius ?? minRadius ?? maxRadius ?? 20) * 2;
    final foreground = foregroundColor ?? scheme.onPrimaryContainer;
    return _Box(
      css:
          'display:inline-flex;align-items:center;justify-content:center;flex-shrink:0;box-sizing:border-box;overflow:hidden;border-radius:50%;width:${px(size)};height:${px(size)};background-color:${colorCss(backgroundColor ?? scheme.primaryContainer)};${backgroundImage == null ? '' : decorationImageCss(DecorationImage(image: backgroundImage!, fit: BoxFit.cover))}',
      layout: _DomLayout.align,
      fill: _Fill.none,
      children: [
        if (child != null)
          IconTheme.merge(
            data: IconThemeData(color: foreground),
            child: DefaultTextStyle(
              style: theme.textTheme.titleMedium!.copyWith(color: foreground),
              child: child!,
            ),
          ),
      ],
    );
  }
}

class Chip extends StatelessWidget {
  const Chip({
    super.key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.side,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.color,
    this.backgroundColor,
    this.padding,
    this.visualDensity,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.iconTheme,
    this.avatarBoxConstraints,
    this.deleteIconBoxConstraints,
  });
  final Widget label;
  final Widget? avatar, deleteIcon;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? labelPadding, padding;
  final Color? deleteIconColor, backgroundColor, shadowColor;
  final Color? surfaceTintColor;
  final WidgetStateProperty<Color?>? color;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onDeleted;
  final String? deleteButtonTooltipMessage;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? materialTapTargetSize;
  final double? elevation;
  final IconThemeData? iconTheme;
  final BoxConstraints? avatarBoxConstraints, deleteIconBoxConstraints;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chipTheme = ChipTheme.of(context);
    final chipSide =
        side ?? chipTheme.side ?? BorderSide(color: scheme.outlineVariant);
    final explicitShape = shape ?? chipTheme.shape;
    final OutlinedBorder chipShape =
        explicitShape?.copyWith(
          side: side ?? chipTheme.side ?? explicitShape.side,
        ) ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: chipSide,
        );
    final background =
        color?.resolve(const {}) ??
        backgroundColor ??
        chipTheme.color?.resolve(const {}) ??
        chipTheme.backgroundColor ??
        scheme.surface;
    final depth = elevation ?? chipTheme.elevation ?? 0;
    final icons = IconThemeData(
      color: scheme.primary,
      size: 18,
    ).merge(chipTheme.iconTheme).merge(iconTheme);
    final text = theme.textTheme.labelLarge!
        .copyWith(color: scheme.onSurfaceVariant)
        .merge(chipTheme.labelStyle)
        .merge(labelStyle);
    final contentPadding = labelPadding ?? chipTheme.labelPadding;
    return _Box(
      css:
          'display:inline-flex;align-items:center;gap:8px;box-sizing:border-box;flex-shrink:0;min-height:32px;${edgeInsetsCss('padding', padding ?? chipTheme.padding ?? const EdgeInsets.symmetric(horizontal: 8))}background-color:${colorCss(background)};${shapeCss(chipShape)}${depth > 0 ? elevationCss(depth, shadowColor ?? chipTheme.shadowColor ?? scheme.shadow) : ''}${clipBehavior == Clip.none ? '' : 'overflow:hidden;'}',
      layout: _DomLayout.row,
      fill: _Fill.none,
      children: [
        if (avatar != null) IconTheme.merge(data: icons, child: avatar!),
        DefaultTextStyle(
          style: text,
          child: contentPadding == null
              ? label
              : Padding(padding: contentPadding, child: label),
        ),
        if (onDeleted != null)
          IconButton(
            onPressed: onDeleted,
            tooltip: deleteButtonTooltipMessage ?? 'Delete',
            iconSize: 18,
            padding: EdgeInsets.zero,
            color:
                deleteIconColor ??
                chipTheme.deleteIconColor ??
                scheme.onSurfaceVariant,
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(24, 24)),
            ),
            icon: deleteIcon ?? const Icon(Icons.cancel_rounded),
          ),
      ],
    );
  }
}

class Badge extends StatelessWidget {
  const Badge({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.smallSize,
    this.largeSize,
    this.textStyle,
    this.padding,
    this.alignment,
    this.offset,
    this.label,
    this.isLabelVisible = true,
    this.child,
  });
  Badge.count({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.smallSize,
    this.largeSize,
    this.textStyle,
    this.padding,
    this.alignment,
    this.offset,
    required int count,
    int maxCount = 999,
    this.isLabelVisible = true,
    this.child,
  }) : label = Text(count > maxCount ? '$maxCount+' : '$count');
  final Widget? label, child;
  final Color? backgroundColor, textColor;
  final double? smallSize, largeSize;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final Offset? offset;
  final bool isLabelVisible;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badgeTheme = BadgeTheme.of(context);
    final small = smallSize ?? badgeTheme.smallSize ?? 6;
    final large = largeSize ?? badgeTheme.largeSize ?? 16;
    final inset =
        padding ??
        badgeTheme.padding ??
        const EdgeInsets.symmetric(horizontal: 4);
    final shift = offset ?? badgeTheme.offset;
    final badge = _Box(
      tag: 'span',
      css:
          '${child == null ? '' : 'position:absolute;top:${px(-4 + (shift?.dy ?? 0))};right:${px(-4 - (shift?.dx ?? 0))};'}display:inline-flex;align-items:center;justify-content:center;box-sizing:border-box;border-radius:9999px;background-color:${colorCss(backgroundColor ?? badgeTheme.backgroundColor ?? scheme.error)};${label == null ? 'width:${px(small)};height:${px(small)};' : 'min-width:${px(large)};height:${px(large)};${edgeInsetsCss('padding', inset)}'}',
      fill: _Fill.none,
      children: [
        if (label != null)
          DefaultTextStyle(
            style: theme.textTheme.labelSmall!
                .merge(badgeTheme.textStyle)
                .merge(textStyle)
                .copyWith(
                  color: textColor ?? badgeTheme.textColor ?? scheme.onError,
                ),
            child: label!,
          ),
      ],
    );
    if (child == null) return isLabelVisible ? badge : const SizedBox.shrink();
    return _Box(
      css: 'position:relative;display:inline-flex;flex-shrink:0;',
      fill: _Fill.none,
      children: [child!, if (isLabelVisible) badge],
    );
  }
}

class Tooltip extends StatelessWidget {
  const Tooltip({
    super.key,
    this.message,
    this.richMessage,
    @Deprecated('Use constraints instead.') this.height,
    this.constraints,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.textAlign,
    this.waitDuration,
    this.showDuration,
    this.exitDuration,
    this.enableTapToDismiss = true,
    this.triggerMode,
    this.enableFeedback,
    this.onTriggered,
    this.mouseCursor,
    this.ignorePointer,
    this.child,
  });
  final String? message;
  final InlineSpan? richMessage;
  final double? height, verticalOffset;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding, margin;
  final bool? preferBelow, excludeFromSemantics, enableFeedback;
  final bool? ignorePointer;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final Duration? waitDuration, showDuration, exitDuration;
  final bool enableTapToDismiss;
  final TooltipTriggerMode? triggerMode;
  final VoidCallback? onTriggered;
  final MouseCursor? mouseCursor;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final text = message ?? richMessage?.toPlainText();
    return _Box(
      css: 'display:contents;',
      attributes: {if (text != null) 'title': text},
      children: [?child],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress.

class LinearProgressIndicator extends StatelessWidget {
  const LinearProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.minHeight,
    this.semanticsLabel,
    this.semanticsValue,
    this.borderRadius,
    this.stopIndicatorColor,
    this.stopIndicatorRadius,
    this.trackGap,
    this.year2023,
  });
  final double? value;
  final Color? backgroundColor, color, stopIndicatorColor;
  final Animation<Color?>? valueColor;
  final double? minHeight, stopIndicatorRadius, trackGap;
  final BorderRadiusGeometry? borderRadius;
  final String? semanticsLabel, semanticsValue;
  final bool? year2023;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressTheme = ProgressIndicatorTheme.of(context);
    final v = value;
    if (v != null && !v.isFinite)
      throw ArgumentError('Progress values must be finite.');
    final clamped = v?.clamp(0.0, 1.0);
    final indicator = colorCss(
      valueColor?.value ?? color ?? progressTheme.color ?? scheme.primary,
    );
    final radius = borderRadius ?? progressTheme.borderRadius;
    return _Box(
      css:
          'position:relative;overflow:hidden;box-sizing:border-box;height:${px(minHeight ?? progressTheme.linearMinHeight ?? 4)};background-color:${colorCss(backgroundColor ?? progressTheme.linearTrackColor ?? scheme.secondaryContainer)};${borderRadiusCss(radius)}--fd-indicator:$indicator;',
      attributes: {
        'role': 'progressbar',
        'aria-valuemin': '0',
        'aria-valuemax': '100',
        if (clamped != null) 'aria-valuenow': '${(clamped * 100).round()}',
        if (semanticsLabel != null) 'aria-label': semanticsLabel!,
        if (semanticsValue != null) 'aria-valuetext': semanticsValue!,
        if (clamped == null) 'class': 'fd-linear-indeterminate',
      },
      fill: _Fill.expand,
      children: [
        if (clamped != null)
          _Box(
            css:
                'height:100%;width:${cssNumber(clamped * 100)}%;background-color:$indicator;${borderRadiusCss(radius)}',
            fill: _Fill.none,
          ),
      ],
    );
  }
}

class CircularProgressIndicator extends StatelessWidget {
  const CircularProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.strokeWidth,
    this.strokeAlign,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeCap,
    this.constraints,
    this.trackGap,
    this.year2023,
    this.padding,
  }) : _size = 36;
  const CircularProgressIndicator.adaptive({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeCap,
    this.strokeAlign,
    this.constraints,
    this.trackGap,
    this.year2023,
    this.padding,
  }) : color = null,
       _size = 36;
  const CircularProgressIndicator._sized(
    this._size, {
    this.value,
    this.color,
    this.valueColor,
    this.strokeWidth,
    this.semanticsLabel,
    this.semanticsValue,
  }) : backgroundColor = null,
       strokeAlign = null,
       strokeCap = null,
       constraints = null,
       trackGap = null,
       year2023 = null,
       padding = null;
  final double? value;
  final Color? backgroundColor, color;
  final Animation<Color?>? valueColor;
  final double? strokeWidth, strokeAlign, trackGap;
  final String? semanticsLabel, semanticsValue;
  final StrokeCap? strokeCap;
  final BoxConstraints? constraints;
  final bool? year2023;
  final EdgeInsetsGeometry? padding;
  final double _size;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressTheme = ProgressIndicatorTheme.of(context);
    final v = value;
    if (v != null && !v.isFinite)
      throw ArgumentError('Progress values must be finite.');
    final clamped = v?.clamp(0.0, 1.0);
    final indicator = colorCss(
      valueColor?.value ?? color ?? progressTheme.color ?? scheme.primary,
    );
    final trackColor = backgroundColor ?? progressTheme.circularTrackColor;
    final track = trackColor == null ? 'transparent' : colorCss(trackColor);
    final stroke = px(strokeWidth ?? progressTheme.strokeWidth ?? 4);
    final box = constraints ?? progressTheme.constraints;
    final size = px(box == null ? _size : box.minWidth);
    final ring =
        'radial-gradient(farthest-side,transparent calc(100% - $stroke),#000 calc(100% - $stroke))';
    return _Box(
      css: clamped == null
          ? 'box-sizing:border-box;flex-shrink:0;width:$size;height:$size;border-radius:50%;border:$stroke solid $track;border-top-color:$indicator;'
          : 'box-sizing:border-box;flex-shrink:0;width:$size;height:$size;border-radius:50%;background:conic-gradient($indicator ${cssNumber(clamped * 360)}deg,$track 0);-webkit-mask:$ring;mask:$ring;',
      attributes: {
        'role': 'progressbar',
        'aria-valuemin': '0',
        'aria-valuemax': '100',
        if (clamped != null) 'aria-valuenow': '${(clamped * 100).round()}',
        if (semanticsLabel != null) 'aria-label': semanticsLabel!,
        if (semanticsValue != null) 'aria-valuetext': semanticsValue!,
        if (clamped == null) 'class': 'fd-spin',
      },
      fill: _Fill.none,
    );
  }
}

/// A circular indicator on a raised disc, as used by pull-to-refresh.
class RefreshProgressIndicator extends StatelessWidget {
  const RefreshProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.strokeWidth = 2.5,
    this.indicatorMargin = const EdgeInsets.all(4.0),
    this.indicatorPadding = const EdgeInsets.all(12.0),
    this.elevation = 2.0,
    this.semanticsLabel,
    this.semanticsValue,
  });
  final double? value;
  final Color? backgroundColor, color;
  final Animation<Color?>? valueColor;
  final double strokeWidth, elevation;
  final EdgeInsetsGeometry indicatorMargin, indicatorPadding;
  final String? semanticsLabel, semanticsValue;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressTheme = ProgressIndicatorTheme.of(context);
    return _Box(
      css:
          'display:inline-flex;flex-shrink:0;box-sizing:border-box;border-radius:50%;${edgeInsetsCss('margin', indicatorMargin)}${edgeInsetsCss('padding', indicatorPadding)}background-color:${colorCss(backgroundColor ?? progressTheme.refreshBackgroundColor ?? scheme.surfaceContainerHighest)};${elevationCss(elevation, scheme.shadow)}',
      fill: _Fill.none,
      children: [
        CircularProgressIndicator._sized(
          16,
          value: value,
          color: color,
          valueColor: valueColor,
          strokeWidth: strokeWidth,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold, app bar and snack bars.

abstract class PreferredSizeWidget implements Widget {
  Size get preferredSize;
}

class PreferredSize extends StatelessWidget implements PreferredSizeWidget {
  const PreferredSize({
    super.key,
    required this.preferredSize,
    required this.child,
  });
  @override
  final Size preferredSize;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class AppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppBar({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
    this.toolbarHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
    this.actionsPadding,
  });
  final Widget? leading, title, flexibleSpace;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? elevation, scrolledUnderElevation;
  final Color? shadowColor, surfaceTintColor;
  final ShapeBorder? shape;
  final Color? backgroundColor, foregroundColor;
  final IconThemeData? iconTheme, actionsIconTheme;
  final bool primary;
  final bool? centerTitle;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double toolbarOpacity, bottomOpacity;
  final double? toolbarHeight, leadingWidth;
  final TextStyle? toolbarTextStyle, titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool forceMaterialTransparency;
  final Clip? clipBehavior;
  final EdgeInsetsGeometry? actionsPadding;
  @override
  Size get preferredSize => Size(
    double.infinity,
    (toolbarHeight ?? 64) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final barTheme = theme.appBarTheme;
    final foreground =
        foregroundColor ?? barTheme.foregroundColor ?? scheme.onSurface;
    final background = forceMaterialTransparency
        ? null
        : backgroundColor ?? barTheme.backgroundColor ?? scheme.surface;
    var leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      final scaffold = Scaffold.maybeOf(context);
      final navigator = Navigator.maybeOf(context);
      if (scaffold != null && scaffold.hasDrawer) {
        leadingWidget = IconButton(
          onPressed: scaffold.openDrawer,
          tooltip: 'Open navigation menu',
          icon: const Icon(Icons.menu),
        );
      } else if (navigator != null && navigator.canPop()) {
        leadingWidget = BackButton(onPressed: navigator.maybePop);
      }
    }
    final barShape = shape ?? barTheme.shape;
    final depth = elevation ?? barTheme.elevation ?? 0;
    final shadow = shadowColor ?? barTheme.shadowColor ?? scheme.shadow;
    final clip = clipBehavior ?? Clip.none;
    final surfaceCss =
        '${background == null ? 'background-color:transparent;' : 'background-color:${colorCss(background)};'}'
        '${barShape == null ? '' : shapeCss(barShape)}${elevationCss(depth, shadow)}'
        '${clip == Clip.none ? '' : 'overflow:hidden;'}';
    final opacity = toolbarOpacity < 1
        ? 'opacity:${cssNumber(toolbarOpacity)};'
        : '';
    if (bottom == null && flexibleSpace == null)
      return _toolbar(
        context,
        theme,
        scheme,
        foreground,
        leadingWidget,
        'header',
        'position:sticky;top:0;z-index:2;$surfaceCss$opacity',
      );
    return _Box(
      tag: 'header',
      css:
          'position:sticky;top:0;z-index:2;display:flex;flex-direction:column;$surfaceCss',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        if (flexibleSpace != null)
          _Box(
            css: 'position:absolute;inset:0;z-index:0;overflow:hidden;',
            attributes: const {'aria-hidden': 'true'},
            fill: _Fill.none,
            children: [flexibleSpace!],
          ),
        _toolbar(
          context,
          theme,
          scheme,
          foreground,
          leadingWidget,
          'div',
          'position:relative;$opacity',
        ),
        if (bottom != null)
          _Box(
            css:
                'position:relative;${bottomOpacity < 1 ? 'opacity:${cssNumber(bottomOpacity)};' : ''}',
            fill: _Fill.expand,
            children: [bottom!],
          ),
      ],
    );
  }

  Widget _toolbar(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    Color foreground,
    Widget? leadingWidget,
    String tag,
    String outerCss,
  ) {
    final barTheme = theme.appBarTheme;
    final height = toolbarHeight ?? barTheme.toolbarHeight ?? 64;
    final spacing = titleSpacing ?? barTheme.titleSpacing ?? 16;
    final center = centerTitle ?? barTheme.centerTitle ?? false;
    final icons = IconThemeData(
      color: foreground,
      size: 24,
    ).merge(barTheme.iconTheme).merge(iconTheme);
    final actionIcons =
        IconThemeData(
          color:
              foregroundColor ??
              barTheme.foregroundColor ??
              scheme.onSurfaceVariant,
          size: 24,
        ).merge(
          actionsIconTheme ??
              barTheme.actionsIconTheme ??
              iconTheme ??
              barTheme.iconTheme,
        );
    final toolbarStyle = theme.textTheme.bodyMedium!
        .copyWith(color: foreground)
        .merge(toolbarTextStyle ?? barTheme.toolbarTextStyle);
    final width = leadingWidth ?? barTheme.leadingWidth;
    final padding = actionsPadding ?? barTheme.actionsPadding;
    return _Box(
      tag: tag,
      css:
          '${outerCss}display:flex;flex-direction:row;align-items:center;box-sizing:border-box;min-height:${px(height)};padding:0 4px;gap:${px(spacing)};color:${colorCss(foreground)};',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        IconTheme.merge(
          data: icons,
          child: width == null || leadingWidget == null
              ? leadingWidget ?? const SizedBox(width: 12)
              : SizedBox(width: width, child: leadingWidget),
        ),
        _Box(
          css:
              'flex:1 1 0;min-width:0;${center ? 'text-align:center;display:flex;justify-content:center;' : ''}',
          attributes: {
            if (!excludeHeaderSemantics) 'role': 'heading',
            if (!excludeHeaderSemantics) 'aria-level': '1',
          },
          children: [
            if (title != null)
              DefaultTextStyle(
                style: theme.textTheme.titleLarge!
                    .copyWith(color: foreground)
                    .merge(titleTextStyle ?? barTheme.titleTextStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: title!,
              ),
          ],
        ),
        if (actions != null)
          IconTheme.merge(
            data: actionIcons,
            child: DefaultTextStyle(
              style: toolbarStyle,
              child: padding == null
                  ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                  : Padding(
                      padding: padding,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class BackButton extends StatelessWidget {
  const BackButton({super.key, this.onPressed, this.color});
  final VoidCallback? onPressed;
  final Color? color;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed ?? () => Navigator.maybePop(context),
    tooltip: 'Back',
    color: color,
    icon: const Icon(Icons.arrow_back),
  );
}

class CloseButton extends StatelessWidget {
  const CloseButton({super.key, this.onPressed, this.color});
  final VoidCallback? onPressed;
  final Color? color;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed ?? () => Navigator.maybePop(context),
    tooltip: 'Close',
    color: color,
    icon: const Icon(Icons.close),
  );
}

/// Where the scaffold places its floating action button. The DOM runtime
/// positions it with fixed CSS offsets; docked locations sit over the
/// bottom bar's top edge.
class FloatingActionButtonLocation {
  const FloatingActionButtonLocation._(
    this._css, [
    this._vertical = 'bottom:16px;',
  ]);
  final String _css;
  final String _vertical;
  static const _start = 'left:16px;';
  static const _center = 'left:50%;transform:translateX(-50%);';
  static const _end = 'right:16px;';
  static const _top = 'top:36px;';
  static const _docked = 'bottom:52px;';
  static const startTop = FloatingActionButtonLocation._(_start, _top);
  static const miniStartTop = FloatingActionButtonLocation._(_start, _top);
  static const centerTop = FloatingActionButtonLocation._(_center, _top);
  static const miniCenterTop = FloatingActionButtonLocation._(_center, _top);
  static const endTop = FloatingActionButtonLocation._(_end, _top);
  static const miniEndTop = FloatingActionButtonLocation._(_end, _top);
  static const startFloat = FloatingActionButtonLocation._(_start);
  static const miniStartFloat = FloatingActionButtonLocation._(_start);
  static const centerFloat = FloatingActionButtonLocation._(_center);
  static const miniCenterFloat = FloatingActionButtonLocation._(_center);
  static const endFloat = FloatingActionButtonLocation._(_end);
  static const miniEndFloat = FloatingActionButtonLocation._(_end);
  static const startDocked = FloatingActionButtonLocation._(_start, _docked);
  static const miniStartDocked = FloatingActionButtonLocation._(
    _start,
    _docked,
  );
  static const centerDocked = FloatingActionButtonLocation._(_center, _docked);
  static const miniCenterDocked = FloatingActionButtonLocation._(
    _center,
    _docked,
  );
  static const endDocked = FloatingActionButtonLocation._(_end, _docked);
  static const miniEndDocked = FloatingActionButtonLocation._(_end, _docked);
  static const endContained = FloatingActionButtonLocation._(_end, _docked);
}

/// Accepted for API compatibility; the FAB does not animate between
/// locations.
abstract class FloatingActionButtonAnimator {
  const FloatingActionButtonAnimator();
  static const FloatingActionButtonAnimator scaling = _NoFabAnimator();
  static const FloatingActionButtonAnimator noAnimation = _NoFabAnimator();
}

class _NoFabAnimator extends FloatingActionButtonAnimator {
  const _NoFabAnimator();
}

typedef DrawerCallback = void Function(bool isOpened);

class Scaffold extends StatefulWidget {
  const Scaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.persistentFooterDecoration,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  });
  final PreferredSizeWidget? appBar;
  final Widget? body, floatingActionButton, bottomNavigationBar, bottomSheet;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final AlignmentDirectional persistentFooterAlignment;
  final BoxDecoration? persistentFooterDecoration;
  final Color? backgroundColor;
  final Widget? drawer, endDrawer;
  final DrawerCallback? onDrawerChanged, onEndDrawerChanged;
  final bool? resizeToAvoidBottomInset;
  final bool primary, extendBody, extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture, endDrawerEnableOpenDragGesture;
  final String? restorationId;

  static ScaffoldState of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No Scaffold ancestor in this context.'));
  static ScaffoldState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ScaffoldState>();
  static bool hasDrawer(
    BuildContext context, {
    bool registerForUpdates = true,
  }) => maybeOf(context)?.hasDrawer ?? false;

  @override
  State<Scaffold> createState() => ScaffoldState();
}

class _ScaffoldBody extends StatelessWidget {
  const _ScaffoldBody({required this.scaffold, required this.state});
  final Scaffold scaffold;
  final ScaffoldState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Box(
      css:
          'display:flex;flex-direction:column;box-sizing:border-box;min-height:100vh;min-width:0;background-color:${colorCss(scaffold.backgroundColor ?? theme.scaffoldBackgroundColor)};',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        ?scaffold.appBar,
        _Box(
          tag: 'main',
          css:
              'flex:1 1 auto;display:grid;grid-template-columns:minmax(0,1fr);min-width:0;min-height:0;',
          layout: _DomLayout.grid,
          fill: _Fill.expand,
          children: [?scaffold.body],
        ),
        ?scaffold.bottomSheet,
        if (state._persistentSheet case final sheet?) sheet,
        if (scaffold.persistentFooterButtons case final buttons?
            when buttons.isNotEmpty)
          _Box(
            css:
                'display:flex;flex-direction:row;flex-wrap:wrap;gap:8px;box-sizing:border-box;padding:8px;justify-content:${switch (scaffold.persistentFooterAlignment.start) {
                  < 0 => 'flex-start',
                  > 0 => 'flex-end',
                  _ => 'center',
                }};${scaffold.persistentFooterDecoration == null ? 'border-top:1px solid ${colorCss(theme.dividerColor)};' : decorationCss(scaffold.persistentFooterDecoration)}',
            layout: _DomLayout.row,
            fill: _Fill.expand,
            children: buttons,
          ),
        if (scaffold.bottomNavigationBar != null)
          _Box(
            css: 'position:sticky;bottom:0;z-index:2;',
            fill: _Fill.expand,
            children: [scaffold.bottomNavigationBar!],
          ),
        if (scaffold.floatingActionButton != null)
          _Box(
            css:
                'position:fixed;z-index:3;${(scaffold.floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat)._vertical}${(scaffold.floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat)._css}',
            fill: _Fill.none,
            children: [scaffold.floatingActionButton!],
          ),
        if (state._drawerOpen && scaffold.drawer != null)
          _DrawerOverlay(
            drawer: scaffold.drawer!,
            scrim: scaffold.drawerScrimColor,
            end: false,
            onClose: state.closeDrawer,
          ),
        if (state._endDrawerOpen && scaffold.endDrawer != null)
          _DrawerOverlay(
            drawer: scaffold.endDrawer!,
            scrim: scaffold.drawerScrimColor,
            end: true,
            onClose: state.closeEndDrawer,
          ),
      ],
    );
  }
}

enum SnackBarBehavior { fixed, floating }

enum SnackBarClosedReason { action, dismiss, swipe, hide, remove, timeout }

class SnackBarAction extends StatelessWidget {
  const SnackBarAction({
    super.key,
    this.textColor,
    this.disabledTextColor,
    this.backgroundColor,
    this.disabledBackgroundColor,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;
  final Color? textColor, disabledTextColor;
  final Color? backgroundColor, disabledBackgroundColor;
  @override
  Widget build(BuildContext context) {
    final snackTheme = Theme.of(context).snackBarTheme;
    final background = backgroundColor ?? snackTheme.actionBackgroundColor;
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.maybeOf(
          context,
        )?.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
        onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor:
            textColor ??
            snackTheme.actionTextColor ??
            Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: background,
      ),
      child: Text(label),
    );
  }
}

class SnackBar extends StatelessWidget {
  const SnackBar({
    super.key,
    required this.content,
    this.backgroundColor,
    this.elevation,
    this.margin,
    this.padding,
    this.width,
    this.shape,
    this.hitTestBehavior,
    this.behavior,
    this.action,
    this.actionOverflowThreshold,
    this.showCloseIcon,
    this.closeIconColor,
    this.duration = const Duration(milliseconds: 4000),
    this.persist,
    this.animation,
    this.onVisible,
    this.dismissDirection,
    this.clipBehavior = Clip.hardEdge,
  });
  final Widget content;
  final Color? backgroundColor, closeIconColor;
  final double? elevation, width, actionOverflowThreshold;
  final EdgeInsetsGeometry? margin, padding;
  final ShapeBorder? shape;
  final HitTestBehavior? hitTestBehavior;
  final SnackBarBehavior? behavior;
  final SnackBarAction? action;
  final bool? showCloseIcon, persist;
  final Duration duration;
  final Animation<double>? animation;
  final VoidCallback? onVisible;
  final DismissDirection? dismissDirection;
  final Clip clipBehavior;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final snackTheme = theme.snackBarTheme;
    final snackShape = shape ?? snackTheme.shape;
    final snackWidth = width ?? snackTheme.width;
    final closeIcon = showCloseIcon ?? snackTheme.showCloseIcon ?? false;
    final floating =
        (behavior ?? snackTheme.behavior) == SnackBarBehavior.floating;
    return _Box(
      css:
          'display:flex;align-items:center;gap:8px;box-sizing:border-box;min-height:48px;${edgeInsetsCss('padding', padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4))}${floating && margin != null ? edgeInsetsCss('margin', margin) : ''}${snackShape == null ? 'border-radius:4px;' : shapeCss(snackShape)}background-color:${colorCss(backgroundColor ?? snackTheme.backgroundColor ?? scheme.inverseSurface)};${elevationCss(elevation ?? snackTheme.elevation ?? 6, scheme.shadow)}${snackWidth == null ? '' : 'width:${px(snackWidth)};'}${clipBehavior == Clip.none ? '' : 'overflow:hidden;'}',
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        _Box(
          css: 'flex:1 1 0;min-width:0;',
          children: [
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: scheme.onInverseSurface)
                  .merge(snackTheme.contentTextStyle),
              child: content,
            ),
          ],
        ),
        ?action,
        if (closeIcon)
          IconButton(
            onPressed: () => ScaffoldMessenger.maybeOf(
              context,
            )?.hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss),
            tooltip: 'Close',
            color:
                closeIconColor ??
                snackTheme.closeIconColor ??
                scheme.onInverseSurface,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}

class ScaffoldFeatureController<T, U> {
  ScaffoldFeatureController._(this._close, this.closed);
  final void Function() _close;
  final Future<U> closed;
  void close() => _close();
}

class ScaffoldMessenger extends StatefulWidget {
  const ScaffoldMessenger({super.key, required this.child});
  final Widget child;
  static ScaffoldMessengerState of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No ScaffoldMessenger ancestor in this context.'));
  static ScaffoldMessengerState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ScaffoldMessengerState>();
  @override
  State<ScaffoldMessenger> createState() => ScaffoldMessengerState();
}

class ScaffoldMessengerState extends State<ScaffoldMessenger> {
  final _queue = <(SnackBar, Completer<SnackBarClosedReason>)>[];
  Timer? _timer;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackBar, {
    AnimationStyle? snackBarAnimationStyle,
  }) {
    final completer = Completer<SnackBarClosedReason>();
    final entry = (snackBar, completer);
    setState(() => _queue.add(entry));
    if (_queue.length == 1) _startTimer();
    return ScaffoldFeatureController._(
      () => _close(entry, SnackBarClosedReason.hide),
      completer.future,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    if (_queue.isEmpty) return;
    final current = _queue.first;
    final onVisible = current.$1.onVisible;
    if (onVisible != null) scheduleMicrotask(onVisible);
    if (current.$1.persist == true) return;
    _timer = Timer(
      current.$1.duration,
      () => _close(current, SnackBarClosedReason.timeout),
    );
  }

  void _close(
    (SnackBar, Completer<SnackBarClosedReason>) entry,
    SnackBarClosedReason reason,
  ) {
    if (!mounted || !_queue.contains(entry)) return;
    final wasCurrent = identical(_queue.first, entry);
    setState(() => _queue.remove(entry));
    if (!entry.$2.isCompleted) entry.$2.complete(reason);
    if (wasCurrent) _startTimer();
  }

  void hideCurrentSnackBar({
    SnackBarClosedReason reason = SnackBarClosedReason.hide,
  }) {
    if (_queue.isNotEmpty) _close(_queue.first, reason);
  }

  void removeCurrentSnackBar({
    SnackBarClosedReason reason = SnackBarClosedReason.remove,
  }) => hideCurrentSnackBar(reason: reason);

  void clearSnackBars() {
    while (_queue.isNotEmpty) {
      _close(_queue.first, SnackBarClosedReason.remove);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Box(
    css: 'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
    layout: _DomLayout.grid,
    fill: _Fill.expand,
    children: [
      widget.child,
      if (_queue.isNotEmpty)
        _Box(
          css:
              'position:fixed;left:50%;bottom:16px;transform:translateX(-50%);z-index:4;width:min(600px,calc(100vw - 32px));',
          fill: _Fill.none,
          children: [_queue.first.$1],
        ),
    ],
  );
}
