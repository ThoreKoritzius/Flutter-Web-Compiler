part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Generic private box used to compose Material widgets from DOM elements.

class _Box extends _DomWidget {
  const _Box({
    this.tag = 'div',
    this.css = '',
    this.attributes = const {},
    this.handlers = const {},
    this.children = const [],
    this.layout = _DomLayout.block,
    this.fill = _Fill.child,
  });
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
    out.handlers.addAll(handlers);
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

enum MaterialTapTargetSize { padded, shrinkWrap }

class VisualDensity {
  const VisualDensity({this.horizontal = 0, this.vertical = 0});
  final double horizontal, vertical;
  static const standard = VisualDensity();
  static const comfortable = VisualDensity(horizontal: -1, vertical: -1);
  static const compact = VisualDensity(horizontal: -2, vertical: -2);
  static const adaptivePlatformDensity = standard;
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
  });
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
    final usesNavigator =
        routes.isNotEmpty ||
        onGenerateRoute != null ||
        initialRoute != null ||
        navigatorKey != null;
    Widget content = usesNavigator
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
    return Title(
      title: title,
      color: color ?? data.colorScheme.primary,
      child: Theme(
        data: data,
        child: ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: _AppSurface(child: content),
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
    this.clipBehavior = Clip.none,
    this.child,
  });
  final MaterialType type;
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
    final background =
        color ??
        switch (_variant) {
          _CardVariant.elevated => Theme.of(context).cardColor,
          _CardVariant.filled => scheme.surfaceContainerHighest,
          _CardVariant.outlined => scheme.surface,
        };
    final cardShape =
        shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _variant == _CardVariant.outlined
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        );
    final depth = elevation ?? (_variant == _CardVariant.elevated ? 1.0 : 0.0);
    return _Box(
      css:
          'box-sizing:border-box;min-width:0;${edgeInsetsCss('margin', margin ?? const EdgeInsets.all(4))}background-color:${colorCss(background)};${shapeCss(cardShape)}${elevationCss(depth, shadowColor ?? scheme.shadow)}${(clipBehavior ?? Clip.none) == Clip.none ? '' : 'overflow:hidden;'}',
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
}

typedef MaterialStateProperty<T> = WidgetStateProperty<T>;
typedef MaterialStatePropertyAll<T> = WidgetStatePropertyAll<T>;

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
    this.side,
    this.shape,
    this.alignment,
    this.visualDensity,
    this.tapTargetSize,
  });
  final WidgetStateProperty<TextStyle?>? textStyle;
  final WidgetStateProperty<Color?>? backgroundColor, foregroundColor;
  final WidgetStateProperty<Color?>? overlayColor, shadowColor;
  final WidgetStateProperty<Color?>? surfaceTintColor, iconColor;
  final WidgetStateProperty<double?>? elevation, iconSize;
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;
  final WidgetStateProperty<Size?>? minimumSize, fixedSize, maximumSize;
  final WidgetStateProperty<BorderSide?>? side;
  final WidgetStateProperty<OutlinedBorder?>? shape;
  final AlignmentGeometry? alignment;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? tapTargetSize;

  ButtonStyle merge(ButtonStyle? other) => other == null
      ? this
      : ButtonStyle(
          textStyle: textStyle ?? other.textStyle,
          backgroundColor: backgroundColor ?? other.backgroundColor,
          foregroundColor: foregroundColor ?? other.foregroundColor,
          overlayColor: overlayColor ?? other.overlayColor,
          shadowColor: shadowColor ?? other.shadowColor,
          surfaceTintColor: surfaceTintColor ?? other.surfaceTintColor,
          elevation: elevation ?? other.elevation,
          padding: padding ?? other.padding,
          minimumSize: minimumSize ?? other.minimumSize,
          fixedSize: fixedSize ?? other.fixedSize,
          maximumSize: maximumSize ?? other.maximumSize,
          iconColor: iconColor ?? other.iconColor,
          iconSize: iconSize ?? other.iconSize,
          side: side ?? other.side,
          shape: shape ?? other.shape,
          alignment: alignment ?? other.alignment,
          visualDensity: visualDensity ?? other.visualDensity,
          tapTargetSize: tapTargetSize ?? other.tapTargetSize,
        );

  ButtonStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<double?>? elevation,
    WidgetStateProperty<Size?>? minimumSize,
  }) => ButtonStyle(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    padding: padding,
    shape: shape,
    side: side,
    textStyle: textStyle,
    elevation: elevation,
    minimumSize: minimumSize,
  ).merge(this);
}

WidgetStateProperty<T?>? _allOrNull<T>(T? value) =>
    value == null ? null : WidgetStatePropertyAll<T?>(value);

WidgetStateProperty<Color?>? _disabledAware(Color? enabled, Color? disabled) =>
    enabled == null && disabled == null
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
  Color? overlayColor,
  double? elevation,
  TextStyle? textStyle,
  EdgeInsetsGeometry? padding,
  Size? minimumSize,
  Size? fixedSize,
  Size? maximumSize,
  BorderSide? side,
  OutlinedBorder? shape,
  AlignmentGeometry? alignment,
  VisualDensity? visualDensity,
  MaterialTapTargetSize? tapTargetSize,
}) => ButtonStyle(
  foregroundColor: _disabledAware(foregroundColor, disabledForegroundColor),
  backgroundColor: _disabledAware(backgroundColor, disabledBackgroundColor),
  shadowColor: _allOrNull(shadowColor),
  surfaceTintColor: _allOrNull(surfaceTintColor),
  iconColor: _allOrNull(iconColor),
  iconSize: _allOrNull(iconSize),
  overlayColor: _allOrNull(overlayColor),
  elevation: _allOrNull(elevation),
  textStyle: _allOrNull(textStyle),
  padding: _allOrNull(padding),
  minimumSize: _allOrNull(minimumSize),
  fixedSize: _allOrNull(fixedSize),
  maximumSize: _allOrNull(maximumSize),
  side: _allOrNull(side),
  shape: _allOrNull(shape),
  alignment: alignment,
  visualDensity: visualDensity,
  tapTargetSize: tapTargetSize,
);

/// Shared native implementation of Material buttons: a real `<button>` with
/// disabled semantics, keyboard activation and focus from the browser.
abstract class ButtonStyleButton extends StatelessWidget {
  const ButtonStyleButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.style,
    this.autofocus = false,
    this.clipBehavior,
    this.tooltip,
    required this.child,
  });
  final VoidCallback? onPressed, onLongPress;
  final ButtonStyle? style;
  final bool autofocus;
  final Clip? clipBehavior;
  final String? tooltip;
  final Widget? child;
  bool get enabled => onPressed != null;
  ButtonStyle defaultStyleOf(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final states = <WidgetState>{if (!enabled) WidgetState.disabled};
    final resolvedStyle = (style ?? const ButtonStyle()).merge(
      defaultStyleOf(context),
    );
    T? resolve<T>(WidgetStateProperty<T?>? property) =>
        property?.resolve(states);
    final foreground =
        resolve(resolvedStyle.foregroundColor) ??
        Theme.of(context).colorScheme.primary;
    final background = resolve(resolvedStyle.backgroundColor);
    final text = Theme.of(
      context,
    ).textTheme.labelLarge!.merge(resolve(resolvedStyle.textStyle));
    final padding =
        resolve(resolvedStyle.padding) ??
        const EdgeInsets.symmetric(horizontal: 24);
    final minimum = resolve(resolvedStyle.minimumSize) ?? const Size(64, 40);
    final fixed = resolve(resolvedStyle.fixedSize);
    final maximum = resolve(resolvedStyle.maximumSize);
    final side = resolve(resolvedStyle.side);
    final shape = resolve(resolvedStyle.shape) ?? const StadiumBorder();
    final elevation = resolve(resolvedStyle.elevation) ?? 0;
    final iconColor = resolve(resolvedStyle.iconColor) ?? foreground;
    final iconSize = resolve(resolvedStyle.iconSize) ?? 18;
    final shadow =
        resolve(resolvedStyle.shadowColor) ??
        Theme.of(context).colorScheme.shadow;
    final alignment = resolvedStyle.alignment;
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
    if (clipBehavior != null && clipBehavior != Clip.none)
      css.write('overflow:hidden;');
    return _Box(
      tag: 'button',
      css: css.toString(),
      fill: _Fill.none,
      layout: _DomLayout.row,
      attributes: {
        'type': 'button',
        'class': 'fd-ink fd-button',
        if (!enabled) 'disabled': '',
        if (tooltip != null) 'title': tooltip!,
        if (tooltip != null && child is Icon) 'aria-label': tooltip!,
      },
      handlers: {if (enabled) 'click': (_) => onPressed!()},
      children: [
        if (child != null)
          IconTheme.merge(
            data: IconThemeData(color: iconColor, size: iconSize),
            child: DefaultTextStyle(
              style: text.copyWith(color: foreground),
              child: child!,
            ),
          ),
      ],
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel(this.icon, this.label);
  final Widget? icon;
  final Widget label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: [
      ?icon,
      Flexible(child: label),
    ],
  );
}

class ElevatedButton extends ButtonStyleButton {
  const ElevatedButton({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.style,
    super.autofocus,
    super.clipBehavior,
    required super.child,
  });
  ElevatedButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    Widget? icon,
    required Widget label,
  }) : this(
         key: key,
         onPressed: onPressed,
         style: style,
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
    Color? overlayColor,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    AlignmentGeometry? alignment,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    iconColor: iconColor,
    iconSize: iconSize,
    overlayColor: overlayColor,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    alignment: alignment,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
  );
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
    super.style,
    super.autofocus,
    super.clipBehavior,
    required super.child,
  }) : _tonal = false;
  const FilledButton.tonal({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.style,
    super.autofocus,
    super.clipBehavior,
    required super.child,
  }) : _tonal = true;
  FilledButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    Widget? icon,
    required Widget label,
  }) : this(
         key: key,
         onPressed: onPressed,
         style: style,
         child: _IconLabel(icon, label),
       );
  FilledButton.tonalIcon({
    Key? key,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    Widget? icon,
    required Widget label,
  }) : this.tonal(
         key: key,
         onPressed: onPressed,
         style: style,
         child: _IconLabel(icon, label),
       );
  final bool _tonal;
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? iconColor,
    double? iconSize,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    AlignmentGeometry? alignment,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    iconColor: iconColor,
    iconSize: iconSize,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    alignment: alignment,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
  );
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
    super.style,
    super.autofocus,
    super.clipBehavior,
    required super.child,
  });
  OutlinedButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    Widget? icon,
    required Widget label,
  }) : this(
         key: key,
         onPressed: onPressed,
         style: style,
         child: _IconLabel(icon, label),
       );
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? iconColor,
    double? iconSize,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    AlignmentGeometry? alignment,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    iconColor: iconColor,
    iconSize: iconSize,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    alignment: alignment,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
  );
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
    super.style,
    super.autofocus,
    super.clipBehavior,
    required super.child,
  });
  TextButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    Widget? icon,
    required Widget label,
  }) : this(
         key: key,
         onPressed: onPressed,
         style: style,
         child: _IconLabel(icon, label),
       );
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? iconColor,
    double? iconSize,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    AlignmentGeometry? alignment,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
  }) => _styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    iconColor: iconColor,
    iconSize: iconSize,
    elevation: elevation,
    textStyle: textStyle,
    padding: padding,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    maximumSize: maximumSize,
    side: side,
    shape: shape,
    alignment: alignment,
    visualDensity: visualDensity,
    tapTargetSize: tapTargetSize,
  );
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

class IconButton extends StatelessWidget {
  const IconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.padding,
    this.color,
    this.disabledColor,
    this.tooltip,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.constraints,
  });
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget? selectedIcon;
  final bool? isSelected;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final Color? color, disabledColor;
  final String? tooltip;
  final ButtonStyle? style;
  final BoxConstraints? constraints;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = isSelected == true;
    final foreground = onPressed == null
        ? disabledColor ?? scheme.onSurface.withValues(alpha: 0.38)
        : color ?? (selected ? scheme.primary : scheme.onSurfaceVariant);
    return _IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(foreground),
        iconColor: WidgetStatePropertyAll(foreground),
        iconSize: WidgetStatePropertyAll(iconSize ?? 24),
        padding: WidgetStatePropertyAll(padding ?? const EdgeInsets.all(8)),
        minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
        shape: const WidgetStatePropertyAll(CircleBorder()),
      ).merge(style),
      child: selected && selectedIcon != null ? selectedIcon! : icon,
    );
  }
}

class _IconButton extends ButtonStyleButton {
  const _IconButton({
    required super.onPressed,
    super.style,
    super.tooltip,
    required super.child,
  });
  @override
  ButtonStyle defaultStyleOf(BuildContext context) => const ButtonStyle();
}

class FloatingActionButton extends StatelessWidget {
  const FloatingActionButton({
    super.key,
    required this.onPressed,
    this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.shape,
    this.mini = false,
    this.heroTag,
  }) : _label = null;
  const FloatingActionButton.extended({
    super.key,
    required this.onPressed,
    required Widget label,
    Widget? icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.shape,
    this.heroTag,
  }) : _label = label,
       child = icon,
       mini = false;
  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? _label;
  final String? tooltip;
  final Color? backgroundColor, foregroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool mini;
  final Object? heroTag;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extended = _label != null;
    final size = mini ? 40.0 : 56.0;
    return _IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          foregroundColor ?? scheme.onPrimaryContainer,
        ),
        backgroundColor: WidgetStatePropertyAll(
          backgroundColor ?? scheme.primaryContainer,
        ),
        iconSize: const WidgetStatePropertyAll(24),
        elevation: WidgetStatePropertyAll(elevation ?? 6),
        padding: WidgetStatePropertyAll(
          extended
              ? const EdgeInsets.symmetric(horizontal: 16)
              : EdgeInsets.zero,
        ),
        minimumSize: WidgetStatePropertyAll(Size(extended ? 80 : size, size)),
        shape: WidgetStatePropertyAll(
          shape is OutlinedBorder
              ? shape as OutlinedBorder
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(mini ? 12 : 16),
                ),
        ),
      ),
      child: extended ? _IconLabel(child, _label) : child,
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
    this.onHover,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.borderRadius,
    this.customBorder,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.canRequestFocus = true,
    this.autofocus = false,
  });
  final Widget? child;
  final VoidCallback? onTap, onDoubleTap, onLongPress;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final Color? focusColor, hoverColor, highlightColor, splashColor;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final bool enableFeedback, excludeFromSemantics, canRequestFocus, autofocus;

  @override
  Widget build(BuildContext context) {
    if (onLongPress != null)
      throw UnsupportedError('Long-press gestures are unsupported.');
    final enabled = onTap != null || onDoubleTap != null;
    final overlay =
        hoverColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final handlers = <String, _DomHandler>{
      ..._activationHandlers(onTap),
      if (onDoubleTap != null) 'dblclick': (_) => onDoubleTap!(),
      if (onHover != null) 'mouseenter': (_) => onHover!(true),
      if (onHover != null) 'mouseleave': (_) => onHover!(false),
    };
    return _Box(
      css:
          'box-sizing:border-box;min-width:0;${borderRadiusCss(borderRadius)}${customBorder == null ? '' : shapeCss(customBorder)}'
          '${enabled ? '--fd-hover:${colorCss(overlay)};--fd-press:${colorCss(overlay)};--fd-focus:${colorCss(Theme.of(context).colorScheme.primary)};' : ''}'
          '${mouseCursor == null ? '' : 'cursor:${mouseCursor!._css};'}',
      attributes: {
        if (enabled && !excludeFromSemantics) 'role': 'button',
        if (enabled && canRequestFocus) 'tabindex': '0',
        if (enabled) 'class': 'fd-ink',
      },
      handlers: handlers,
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
    super.onDoubleTap,
    super.onHover,
    super.borderRadius,
    super.hoverColor,
  });
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
    this.mouseCursor,
  });
  final Widget? leading, title, subtitle, trailing;
  final bool isThreeLine, enabled, selected;
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
    final compact = dense == true;
    final disabled = scheme.onSurface.withValues(alpha: 0.38);
    final titleColor = !enabled
        ? disabled
        : selected
        ? selectedColor ?? scheme.primary
        : textColor ?? scheme.onSurface;
    final leadingColor = !enabled
        ? disabled
        : selected
        ? selectedColor ?? scheme.primary
        : iconColor ?? scheme.onSurfaceVariant;
    final titleStyle =
        (compact ? theme.textTheme.bodyMedium! : theme.textTheme.bodyLarge!)
            .merge(titleTextStyle)
            .copyWith(color: titleTextStyle?.color ?? titleColor);
    final subtitleStyle = theme.textTheme.bodyMedium!
        .merge(subtitleTextStyle)
        .copyWith(
          color:
              subtitleTextStyle?.color ??
              (enabled ? scheme.onSurfaceVariant : disabled),
        );
    final height =
        minTileHeight ??
        (subtitle == null
            ? (compact ? 48.0 : 56.0)
            : isThreeLine
            ? 88.0
            : (compact ? 64.0 : 72.0));
    final padding =
        contentPadding ?? const EdgeInsetsDirectional.only(start: 16, end: 24);
    final background = selected && selectedTileColor != null
        ? selectedTileColor
        : tileColor;
    final row = _Box(
      css:
          'display:flex;flex-direction:row;align-items:center;gap:${px(horizontalTitleGap ?? 16)};box-sizing:border-box;min-height:${px(height)};${edgeInsetsCss('padding', padding)}'
          'padding-top:${px(minVerticalPadding ?? 8)};padding-bottom:${px(minVerticalPadding ?? 8)};'
          '${background == null ? '' : 'background-color:${colorCss(background)};'}${shape == null ? '' : shapeCss(shape)}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        if (leading != null)
          _Box(
            css:
                'display:flex;align-items:center;flex-shrink:0;${minLeadingWidth == null ? '' : 'min-width:${px(minLeadingWidth!)};'}',
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
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: enabled ? scheme.onSurfaceVariant : disabled,
                  ),
                  child: trailing!,
                ),
              ),
            ],
          ),
      ],
    );
    if (!enabled || onTap == null) return row;
    return InkWell(onTap: onTap, mouseCursor: mouseCursor, child: row);
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
  });
  final double? height, thickness, indent, endIndent;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final extent = checkedDimension(height ?? 16);
    final line = checkedDimension(thickness ?? 1);
    final margin = (extent - line) / 2;
    return _Box(
      css:
          'box-sizing:content-box;height:0;flex-shrink:0;border-top:${px(line)} solid ${colorCss(color ?? Theme.of(context).dividerColor)};margin:${px(margin < 0 ? 0 : margin)} ${px(endIndent ?? 0)} ${px(margin < 0 ? 0 : margin)} ${px(indent ?? 0)};',
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
  });
  final double? width, thickness, indent, endIndent;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final extent = checkedDimension(width ?? 16);
    final line = checkedDimension(thickness ?? 1);
    final margin = (extent - line) / 2;
    return _Box(
      css:
          'box-sizing:content-box;width:0;flex-shrink:0;align-self:stretch;border-left:${px(line)} solid ${colorCss(color ?? Theme.of(context).dividerColor)};margin:${px(indent ?? 0)} ${px(margin < 0 ? 0 : margin)} ${px(endIndent ?? 0)} ${px(margin < 0 ? 0 : margin)};',
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
    required this.label,
    this.avatar,
    this.labelStyle,
    this.backgroundColor,
    this.side,
    this.shape,
    this.padding,
    this.onDeleted,
    this.deleteIcon,
    this.deleteButtonTooltipMessage,
  });
  final Widget label;
  final Widget? avatar, deleteIcon;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onDeleted;
  final String? deleteButtonTooltipMessage;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chipShape =
        shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: side ?? BorderSide(color: scheme.outlineVariant),
        );
    return _Box(
      css:
          'display:inline-flex;align-items:center;gap:8px;box-sizing:border-box;flex-shrink:0;min-height:32px;${edgeInsetsCss('padding', padding ?? const EdgeInsets.symmetric(horizontal: 8))}background-color:${colorCss(backgroundColor ?? scheme.surface)};${shapeCss(chipShape)}',
      layout: _DomLayout.row,
      fill: _Fill.none,
      children: [
        if (avatar != null)
          IconTheme.merge(
            data: IconThemeData(color: scheme.primary, size: 18),
            child: avatar!,
          ),
        DefaultTextStyle(
          style: theme.textTheme.labelLarge!
              .copyWith(color: scheme.onSurfaceVariant)
              .merge(labelStyle),
          child: label,
        ),
        if (onDeleted != null)
          IconButton(
            onPressed: onDeleted,
            tooltip: deleteButtonTooltipMessage ?? 'Delete',
            iconSize: 18,
            padding: EdgeInsets.zero,
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
    this.label,
    this.backgroundColor,
    this.textColor,
    this.isLabelVisible = true,
    this.child,
  });
  Badge.count({
    super.key,
    required int count,
    this.backgroundColor,
    this.textColor,
    this.isLabelVisible = true,
    this.child,
  }) : label = Text(count > 999 ? '999+' : '$count');
  final Widget? label, child;
  final Color? backgroundColor, textColor;
  final bool isLabelVisible;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badge = _Box(
      tag: 'span',
      css:
          '${child == null ? '' : 'position:absolute;top:-4px;right:-4px;'}display:inline-flex;align-items:center;justify-content:center;box-sizing:border-box;border-radius:9999px;background-color:${colorCss(backgroundColor ?? scheme.error)};${label == null ? 'width:6px;height:6px;' : 'min-width:16px;height:16px;padding:0 4px;'}',
      fill: _Fill.none,
      children: [
        if (label != null)
          DefaultTextStyle(
            style: theme.textTheme.labelSmall!.copyWith(
              color: textColor ?? scheme.onError,
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
  const Tooltip({super.key, this.message, this.child});
  final String? message;
  final Widget? child;
  @override
  Widget build(BuildContext context) => _Box(
    css: 'display:contents;',
    attributes: {if (message != null) 'title': message!},
    children: [?child],
  );
}

// ---------------------------------------------------------------------------
// Progress.

class LinearProgressIndicator extends StatelessWidget {
  const LinearProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.minHeight,
    this.borderRadius,
    this.semanticsLabel,
    this.semanticsValue,
  });
  final double? value;
  final Color? backgroundColor, color;
  final double? minHeight;
  final BorderRadiusGeometry? borderRadius;
  final String? semanticsLabel, semanticsValue;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value;
    if (v != null && !v.isFinite)
      throw ArgumentError('Progress values must be finite.');
    final clamped = v?.clamp(0.0, 1.0);
    final indicator = colorCss(color ?? scheme.primary);
    return _Box(
      css:
          'position:relative;overflow:hidden;box-sizing:border-box;height:${px(minHeight ?? 4)};background-color:${colorCss(backgroundColor ?? scheme.secondaryContainer)};${borderRadiusCss(borderRadius)}--fd-indicator:$indicator;',
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
                'height:100%;width:${cssNumber(clamped * 100)}%;background-color:$indicator;${borderRadiusCss(borderRadius)}',
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
    this.strokeWidth = 4,
    this.semanticsLabel,
  });
  const CircularProgressIndicator.adaptive({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.strokeWidth = 4,
    this.semanticsLabel,
  });
  final double? value;
  final Color? backgroundColor, color;
  final double strokeWidth;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value;
    if (v != null && !v.isFinite)
      throw ArgumentError('Progress values must be finite.');
    final clamped = v?.clamp(0.0, 1.0);
    final indicator = colorCss(color ?? scheme.primary);
    final track = backgroundColor == null
        ? 'transparent'
        : colorCss(backgroundColor!);
    final stroke = px(strokeWidth);
    final ring =
        'radial-gradient(farthest-side,transparent calc(100% - $stroke),#000 calc(100% - $stroke))';
    return _Box(
      css: clamped == null
          ? 'box-sizing:border-box;flex-shrink:0;width:36px;height:36px;border-radius:50%;border:$stroke solid $track;border-top-color:$indicator;'
          : 'box-sizing:border-box;flex-shrink:0;width:36px;height:36px;border-radius:50%;background:conic-gradient($indicator ${cssNumber(clamped * 360)}deg,$track 0);-webkit-mask:$ring;mask:$ring;',
      attributes: {
        'role': 'progressbar',
        'aria-valuemin': '0',
        'aria-valuemax': '100',
        if (clamped != null) 'aria-valuenow': '${(clamped * 100).round()}',
        if (semanticsLabel != null) 'aria-label': semanticsLabel!,
        if (clamped == null) 'class': 'fd-spin',
      },
      fill: _Fill.none,
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
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle,
    this.titleSpacing,
    this.toolbarHeight,
    this.titleTextStyle,
    this.bottom,
  });
  final Widget? leading, title;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final Color? backgroundColor, foregroundColor;
  final double? elevation, titleSpacing, toolbarHeight;
  final bool? centerTitle;
  final TextStyle? titleTextStyle;
  final PreferredSizeWidget? bottom;
  @override
  Size get preferredSize => Size(double.infinity, toolbarHeight ?? 64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = foregroundColor ?? scheme.onSurface;
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
    final toolbar = _toolbar(context, theme, scheme, foreground, leadingWidget);
    if (bottom == null) return toolbar;
    return _Box(
      tag: 'header',
      css:
          'position:sticky;top:0;z-index:2;display:flex;flex-direction:column;background-color:${colorCss(backgroundColor ?? scheme.surface)};',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [toolbar, bottom!],
    );
  }

  Widget _toolbar(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    Color foreground,
    Widget? leadingWidget,
  ) {
    return _Box(
      tag: bottom == null ? 'header' : 'div',
      css:
          '${bottom == null ? 'position:sticky;top:0;z-index:2;' : ''}display:flex;flex-direction:row;align-items:center;box-sizing:border-box;min-height:${px(toolbarHeight ?? 64)};padding:0 4px;gap:${px(titleSpacing ?? 16)};background-color:${colorCss(backgroundColor ?? scheme.surface)};color:${colorCss(foreground)};${elevationCss(elevation ?? 0, scheme.shadow)}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: foreground, size: 24),
          child: leadingWidget ?? const SizedBox(width: 12),
        ),
        _Box(
          css:
              'flex:1 1 0;min-width:0;${centerTitle == true ? 'text-align:center;display:flex;justify-content:center;' : ''}',
          attributes: const {'role': 'heading', 'aria-level': '1'},
          children: [
            if (title != null)
              DefaultTextStyle(
                style: theme.textTheme.titleLarge!
                    .copyWith(color: foreground)
                    .merge(titleTextStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: title!,
              ),
          ],
        ),
        if (actions != null)
          IconTheme.merge(
            data: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
            child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
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

class FloatingActionButtonLocation {
  const FloatingActionButtonLocation._(this._css);
  final String _css;
  static const endFloat = FloatingActionButtonLocation._('right:16px;');
  static const centerFloat = FloatingActionButtonLocation._(
    'left:50%;transform:translateX(-50%);',
  );
  static const startFloat = FloatingActionButtonLocation._('left:16px;');
}

class Scaffold extends StatefulWidget {
  const Scaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });
  final PreferredSizeWidget? appBar;
  final Widget? body, floatingActionButton, bottomNavigationBar, bottomSheet;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final Widget? drawer, endDrawer;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody, extendBodyBehindAppBar;

  static ScaffoldState of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No Scaffold ancestor in this context.'));
  static ScaffoldState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ScaffoldState>();

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
        if (scaffold.bottomNavigationBar != null)
          _Box(
            css: 'position:sticky;bottom:0;z-index:2;',
            fill: _Fill.expand,
            children: [scaffold.bottomNavigationBar!],
          ),
        if (scaffold.floatingActionButton != null)
          _Box(
            css:
                'position:fixed;bottom:16px;z-index:3;${(scaffold.floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat)._css}',
            fill: _Fill.none,
            children: [scaffold.floatingActionButton!],
          ),
        if (state._drawerOpen && scaffold.drawer != null)
          _DrawerOverlay(
            drawer: scaffold.drawer!,
            end: false,
            onClose: state.closeDrawer,
          ),
        if (state._endDrawerOpen && scaffold.endDrawer != null)
          _DrawerOverlay(
            drawer: scaffold.endDrawer!,
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
    required this.label,
    required this.onPressed,
    this.textColor,
  });
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () {
      ScaffoldMessenger.maybeOf(
        context,
      )?.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
      onPressed();
    },
    style: TextButton.styleFrom(
      foregroundColor:
          textColor ?? Theme.of(context).colorScheme.inversePrimary,
    ),
    child: Text(label),
  );
}

class SnackBar extends StatelessWidget {
  const SnackBar({
    super.key,
    required this.content,
    this.action,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 4000),
    this.behavior,
    this.showCloseIcon,
    this.width,
    this.margin,
    this.padding,
  });
  final Widget content;
  final SnackBarAction? action;
  final Color? backgroundColor;
  final Duration duration;
  final SnackBarBehavior? behavior;
  final bool? showCloseIcon;
  final double? width;
  final EdgeInsetsGeometry? margin, padding;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _Box(
      css:
          'display:flex;align-items:center;gap:8px;box-sizing:border-box;min-height:48px;${edgeInsetsCss('padding', padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4))}border-radius:4px;background-color:${colorCss(backgroundColor ?? scheme.inverseSurface)};${elevationCss(6, scheme.shadow)}${width == null ? '' : 'width:${px(width!)};'}',
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        _Box(
          css: 'flex:1 1 0;min-width:0;',
          children: [
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onInverseSurface,
              ),
              child: content,
            ),
          ],
        ),
        ?action,
        if (showCloseIcon == true)
          IconButton(
            onPressed: () => ScaffoldMessenger.maybeOf(
              context,
            )?.hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss),
            tooltip: 'Close',
            color: scheme.onInverseSurface,
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
    SnackBar snackBar,
  ) {
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
