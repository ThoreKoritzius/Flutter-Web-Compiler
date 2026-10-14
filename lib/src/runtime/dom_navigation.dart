part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Routes.

class RouteSettings {
  const RouteSettings({this.name, this.arguments});
  final String? name;
  final Object? arguments;
  RouteSettings copyWith({String? name, Object? arguments}) => RouteSettings(
    name: name ?? this.name,
    arguments: arguments ?? this.arguments,
  );
}

typedef RouteFactory = Route<dynamic>? Function(RouteSettings settings);
typedef RoutePredicate = bool Function(Route<dynamic> route);
typedef RoutePageBuilder = Widget Function(BuildContext context);

abstract class Route<T> {
  Route({RouteSettings? settings})
    : _settings = settings ?? const RouteSettings();
  RouteSettings _settings;
  RouteSettings get settings => _settings;
  NavigatorState? _navigator;
  NavigatorState? get navigator => _navigator;
  final _popCompleter = Completer<T?>();
  Future<T?> get popped => _popCompleter.future;
  bool get isActive => _navigator != null;
  bool get isCurrent => _navigator?._entries.last.route == this;
  bool get isFirst => _navigator?._entries.first.route == this;

  /// Opaque routes hide the routes below them; their state is retained.
  bool get opaque => true;
  bool get barrierDismissible => false;
  Color? get barrierColor => null;
  Widget _buildPage(BuildContext context);
}

abstract class ModalRoute<T> extends Route<T> {
  ModalRoute({super.settings});
  static ModalRoute<dynamic>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ModalScope>()?.entry.route
          as ModalRoute<dynamic>?;
}

abstract class PageRoute<T> extends ModalRoute<T> {
  PageRoute({super.settings, this.fullscreenDialog = false});
  final bool fullscreenDialog;
}

class MaterialPageRoute<T> extends PageRoute<T> {
  MaterialPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog,
  });
  final WidgetBuilder builder;
  final bool maintainState;
  @override
  Widget _buildPage(BuildContext context) => builder(context);
}

typedef PageBuilder =
    Widget Function(
      BuildContext context,
      Object? animation,
      Object? secondaryAnimation,
    );

/// Transitions are not animated; the page builder receives null animations.
class PageRouteBuilder<T> extends PageRoute<T> {
  PageRouteBuilder({
    required this.pageBuilder,
    super.settings,
    this.opaqueRoute = true,
    super.fullscreenDialog,
  });
  final PageBuilder pageBuilder;
  final bool opaqueRoute;
  @override
  bool get opaque => opaqueRoute;
  @override
  Widget _buildPage(BuildContext context) => pageBuilder(context, null, null);
}

class _OverlayRoute<T> extends ModalRoute<T> {
  _OverlayRoute({
    required this.builder,
    required this.dismissible,
    required this.color,
    required this.sheet,
    this.anchor,
    super.settings,
  });
  final WidgetBuilder builder;
  final bool dismissible, sheet;

  /// Viewport rectangle to open beside (menus); centered when null.
  final Rect? anchor;
  final Color color;
  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => dismissible;
  @override
  Color? get barrierColor => color;
  @override
  Widget _buildPage(BuildContext context) => builder(context);
}

class NavigatorObserver {
  NavigatorState? get navigator => _navigator;
  NavigatorState? _navigator;
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {}
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {}
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {}
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {}
}

// ---------------------------------------------------------------------------
// Declarative pages.

abstract class Page<T> extends RouteSettings {
  const Page({this.key, super.name, super.arguments, this.restorationId});
  final LocalKey? key;
  final String? restorationId;
  bool canUpdate(Page<dynamic> other) =>
      other.runtimeType == runtimeType && other.key == key;
  Route<T> createRoute(BuildContext context);
}

class MaterialPage<T> extends Page<T> {
  const MaterialPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });
  final Widget child;
  final bool maintainState, fullscreenDialog, allowSnapshotting;
  @override
  Route<T> createRoute(BuildContext context) => _PageBasedRoute<T>(this);
}

/// A route whose content comes from its (replaceable) page.
class _PageBasedRoute<T> extends PageRoute<T> {
  _PageBasedRoute(Page<T> page) : super(settings: page);
  Page<T> get page => settings as Page<T>;
  @override
  bool get opaque {
    final page = this.page;
    return page is _OpaquePage ? (page as _OpaquePage).isOpaque : true;
  }

  @override
  Widget _buildPage(BuildContext context) => switch (page) {
    final MaterialPage<T> page => page.child,
    final _ChildPage page => page.pageChild,
    _ => throw UnsupportedError('Unsupported page type: ${page.runtimeType}'),
  };
}

/// Pages from other libraries (such as router pages) expose their child.
abstract interface class _ChildPage {
  Widget get pageChild;
}

abstract interface class _OpaquePage {
  bool get isOpaque;
}

typedef PopPageCallback = bool Function(Route<dynamic> route, dynamic result);
typedef DidRemovePageCallback = void Function(Page<Object?> page);

class _RouteEntry {
  _RouteEntry(this.route, {this.page}) : key = UniqueKey();
  final Route<dynamic> route;
  Page<dynamic>? page;
  final Key key;
  final popScopes = <_PopScopeState>[];
  int historyIndex = 0;
}

// ---------------------------------------------------------------------------
// Browser history (root navigator only). Route names map to `#/name`, the
// same URL shape as Flutter web's default hash strategy.

extension type _History(JSObject _) implements JSObject {
  external void pushState(JSAny? data, String title, String? url);
  external void replaceState(JSAny? data, String title, String? url);
  external void back();
  external JSAny? get state;
}

_History? get _history {
  final window = _window as JSObject;
  return window.has('history')
      ? _History(window.getProperty<JSObject>('history'.toJS))
      : null;
}

String? _locationHash() {
  final window = _window as JSObject;
  if (!window.has('location')) return null;
  final hash = window
      .getProperty<JSObject>('location'.toJS)
      .getProperty<JSString?>('hash'.toJS)
      ?.toDart;
  return hash == null || hash.length < 2 ? null : hash.substring(1);
}

String? _hashFor(String? name) {
  if (name == null || !name.startsWith('/')) return null;
  return '#${Uri.encodeFull(name)}';
}

// ---------------------------------------------------------------------------
// Navigator.

class Navigator extends StatefulWidget {
  const Navigator({
    super.key,
    this.home,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.observers = const [],
    this.pages = const [],
    @Deprecated('Use onDidRemovePage instead.') this.onPopPage,
    this.onDidRemovePage,
  });
  final List<Page<dynamic>> pages;
  final PopPageCallback? onPopPage;
  final DidRemovePageCallback? onDidRemovePage;
  final Widget? home;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute, onUnknownRoute;
  final List<NavigatorObserver> observers;
  static const defaultRouteName = '/';

  static NavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
  }) =>
      maybeOf(context, rootNavigator: rootNavigator) ??
      (throw StateError('No Navigator ancestor in this context.'));

  static NavigatorState? maybeOf(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    if (context is StatefulElement && context.state is NavigatorState) {
      if (!rootNavigator) return context.state as NavigatorState;
    }
    return rootNavigator
        ? context.findRootAncestorStateOfType<NavigatorState>()
        : context.findAncestorStateOfType<NavigatorState>();
  }

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) => of(context).push(route);
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) => of(context).pushNamed<T>(routeName, arguments: arguments);
  static Future<T?> pushReplacement<T extends Object?, R extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    R? result,
  }) => of(context).pushReplacement<T, R>(newRoute, result: result);
  static Future<T?> pushReplacementNamed<T extends Object?, R extends Object?>(
    BuildContext context,
    String routeName, {
    R? result,
    Object? arguments,
  }) => of(
    context,
  ).pushReplacementNamed<T, R>(routeName, result: result, arguments: arguments);
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Route<T> newRoute,
    RoutePredicate predicate,
  ) => of(context).pushAndRemoveUntil<T>(newRoute, predicate);
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) => of(
    context,
  ).pushNamedAndRemoveUntil<T>(newRouteName, predicate, arguments: arguments);
  static void pop<T extends Object?>(BuildContext context, [T? result]) =>
      of(context).pop<T>(result);
  static Future<bool> maybePop<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) => of(context).maybePop<T>(result);
  static bool canPop(BuildContext context) =>
      maybeOf(context)?.canPop() ?? false;
  static void popUntil(BuildContext context, RoutePredicate predicate) =>
      of(context).popUntil(predicate);

  @override
  State<Navigator> createState() => NavigatorState();
}

class NavigatorState extends State<Navigator> {
  final _entries = <_RouteEntry>[];
  bool _isRoot = false;
  JSFunction? _popListener;
  int _ignoredPops = 0;
  int _historyDepth = 0;

  @override
  void initState() {
    super.initState();
    _isRoot = context.findAncestorStateOfType<NavigatorState>() == null;
    for (final observer in widget.observers) {
      observer._navigator = this;
    }
    if (widget.pages.isNotEmpty) {
      // Declarative navigators leave the URL to their router.
      _isRoot = false;
      _reconcilePages();
      return;
    }
    final history = _isRoot ? _history : null;
    final initialName =
        (history == null ? null : _locationHash()) ??
        widget.initialRoute ??
        Navigator.defaultRouteName;
    for (final route in _initialRoutes(initialName)) {
      _entries.add(_RouteEntry(route).._attach(this));
    }
    if (history != null) {
      history.replaceState(
        _historyState(0),
        '',
        _hashFor(_entries.last.route.settings.name),
      );
      _popListener = ((JSAny? _) => _onBrowserPop()).toJS;
      _window.addEventListener('popstate', _popListener!);
    }
  }

  @override
  void didUpdateWidget(Navigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pages, widget.pages)) _reconcilePages();
  }

  /// Matches pages to existing routes by [Page.canUpdate], keeping their
  /// state; imperative routes stay above the page-based ones.
  void _reconcilePages() {
    final old = _entries.where((e) => e.page != null).toList();
    final imperative = _entries.where((e) => e.page == null).toList();
    final next = <_RouteEntry>[];
    for (final page in widget.pages) {
      final index = old.indexWhere((e) => e.page!.canUpdate(page));
      if (index >= 0) {
        final entry = old.removeAt(index);
        entry.page = page;
        entry.route._settings = page;
        next.add(entry);
      } else {
        next.add(
          _RouteEntry(page.createRoute(context), page: page).._attach(this),
        );
      }
    }
    for (final removed in old) {
      removed._detach(null);
    }
    _entries
      ..clear()
      ..addAll(next)
      ..addAll(imperative);
  }

  JSAny _historyState(int depth) => {'flutterDomDepth': depth}.jsify()!;

  List<Route<dynamic>> _initialRoutes(String name) {
    final routes = <Route<dynamic>>[];
    if (name == Navigator.defaultRouteName || !name.startsWith('/')) {
      final route = _routeNamed(name, null, allowNull: true);
      if (route != null) return [route];
    } else {
      final root = _routeNamed('/', null, allowNull: true);
      if (root != null) routes.add(root);
      final parts = name.substring(1).split('/');
      var path = '';
      for (final part in parts) {
        path += '/$part';
        final route = _routeNamed(path, null, allowNull: true);
        if (route != null) routes.add(route);
      }
      if (routes.isNotEmpty && routes.last.settings.name == name) return routes;
    }
    final fallback = _routeNamed(Navigator.defaultRouteName, null);
    return [fallback!];
  }

  Route<T?>? _routeNamed<T>(
    String name,
    Object? arguments, {
    bool allowNull = false,
  }) {
    final settings = RouteSettings(name: name, arguments: arguments);
    if (name == Navigator.defaultRouteName && widget.home != null) {
      final home = widget.home!;
      return MaterialPageRoute<T?>(builder: (_) => home, settings: settings);
    }
    final builder = widget.routes[name];
    if (builder != null)
      return MaterialPageRoute<T?>(builder: builder, settings: settings);
    final generated = widget.onGenerateRoute?.call(settings);
    if (generated != null) return generated as Route<T?>;
    if (allowNull) return null;
    final unknown = widget.onUnknownRoute?.call(settings);
    if (unknown != null) return unknown as Route<T?>;
    throw StateError('Could not find a generator for route "$name".');
  }

  bool canPop() => _entries.length > 1;

  void _notify() {
    if (mounted) setState(() {});
  }

  Future<T?> push<T extends Object?>(Route<T> route) {
    final previous = _entries.isEmpty ? null : _entries.last.route;
    final entry = _RouteEntry(route).._attach(this);
    _entries.add(entry);
    _pushHistory(entry);
    for (final observer in widget.observers) {
      observer.didPush(route, previous);
    }
    _notify();
    return route.popped;
  }

  void _pushHistory(_RouteEntry entry) {
    if (!_isRoot) return;
    final history = _history;
    if (history == null) return;
    entry.historyIndex = ++_historyDepth;
    history.pushState(
      _historyState(_historyDepth),
      '',
      _hashFor(entry.route.settings.name),
    );
  }

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) => push<T?>(_routeNamed<T>(routeName, arguments)!);

  Future<T?> pushReplacement<T extends Object?, R extends Object?>(
    Route<T> newRoute, {
    R? result,
  }) {
    final old = _entries.removeLast();
    old._detach(result);
    final entry = _RouteEntry(newRoute).._attach(this);
    _entries.add(entry);
    if (_isRoot) {
      entry.historyIndex = old.historyIndex;
      _history?.replaceState(
        _historyState(old.historyIndex),
        '',
        _hashFor(newRoute.settings.name),
      );
    }
    for (final observer in widget.observers) {
      observer.didReplace(newRoute: newRoute, oldRoute: old.route);
    }
    _notify();
    return newRoute.popped;
  }

  Future<T?> pushReplacementNamed<T extends Object?, R extends Object?>(
    String routeName, {
    R? result,
    Object? arguments,
  }) => pushReplacement<T?, R>(
    _routeNamed<T>(routeName, arguments)!,
    result: result,
  );

  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Route<T> newRoute,
    RoutePredicate predicate,
  ) {
    while (_entries.isNotEmpty && !predicate(_entries.last.route)) {
      final removed = _entries.removeLast();
      removed._detach(null);
      for (final observer in widget.observers) {
        observer.didRemove(
          removed.route,
          _entries.isEmpty ? null : _entries.last.route,
        );
      }
    }
    return push<T>(newRoute);
  }

  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) => pushAndRemoveUntil<T?>(
    _routeNamed<T>(newRouteName, arguments)!,
    predicate,
  );

  void pop<T extends Object?>([T? result]) {
    if (!canPop()) throw StateError('Cannot pop the initial route.');
    _popEntry(result, fromBrowser: false);
  }

  void _popEntry(Object? result, {required bool fromBrowser}) {
    final entry = _entries.last;
    final page = entry.page;
    if (page != null) {
      // Page-based routes are removed by their owner updating `pages`.
      final onPopPage = widget.onPopPage;
      if (widget.onDidRemovePage == null &&
          onPopPage != null &&
          !onPopPage(entry.route, result)) {
        return;
      }
      _entries.removeLast();
      entry._detach(result);
      widget.onDidRemovePage?.call(page);
      _notify();
      return;
    }
    _entries.removeLast();
    entry._detach(result);
    for (final observer in widget.observers) {
      observer.didPop(entry.route, _entries.last.route);
    }
    if (_isRoot && !fromBrowser && entry.historyIndex > 0) {
      final history = _history;
      if (history != null) {
        _ignoredPops++;
        _historyDepth--;
        history.back();
      }
    }
    _notify();
  }

  Future<bool> maybePop<T extends Object?>([T? result]) async {
    if (!canPop()) return false;
    final entry = _entries.last;
    for (final scope in entry.popScopes.reversed) {
      if (!scope.widget.canPop) {
        scope._invoked(false, result);
        return true;
      }
    }
    _popEntry(result, fromBrowser: false);
    for (final scope in entry.popScopes) {
      scope._invoked(true, result);
    }
    return true;
  }

  void popUntil(RoutePredicate predicate) {
    while (canPop() && !predicate(_entries.last.route)) {
      _popEntry(null, fromBrowser: false);
    }
  }

  void _onBrowserPop() {
    if (!mounted) return;
    if (_ignoredPops > 0) {
      _ignoredPops--;
      return;
    }
    if (!canPop()) return;
    final entry = _entries.last;
    final blocked = entry.popScopes.any((scope) => !scope.widget.canPop);
    if (blocked) {
      // Restore the entry the browser just left; the page stays.
      _history?.pushState(
        _historyState(entry.historyIndex),
        '',
        _hashFor(entry.route.settings.name),
      );
      for (final scope in entry.popScopes) {
        if (!scope.widget.canPop) scope._invoked(false, null);
      }
      return;
    }
    _historyDepth = _historyDepth > 0 ? _historyDepth - 1 : 0;
    _popEntry(null, fromBrowser: true);
    for (final scope in entry.popScopes) {
      scope._invoked(true, null);
    }
  }

  @override
  void dispose() {
    if (_popListener != null) {
      _window.removeEventListener('popstate', _popListener!);
      _popListener = null;
    }
    for (final entry in _entries) {
      entry._detach(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var topOpaque = 0;
    for (var i = _entries.length - 1; i >= 0; i--) {
      if (_entries[i].route.opaque) {
        topOpaque = i;
        break;
      }
    }
    return _Box(
      css: 'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [
        for (var i = 0; i < _entries.length; i++)
          _RouteHost(
            key: _entries[i].key,
            entry: _entries[i],
            hidden: i < topOpaque,
            current: i == _entries.length - 1,
          ),
      ],
    );
  }
}

extension on _RouteEntry {
  void _attach(NavigatorState navigator) {
    route._navigator = navigator;
  }

  void _detach(Object? result) {
    route._navigator = null;
    if (!route._popCompleter.isCompleted) route._popCompleter.complete(result);
  }
}

class _ModalScope extends InheritedWidget {
  const _ModalScope({required this.entry, required super.child});
  final _RouteEntry entry;
  @override
  bool updateShouldNotify(_ModalScope oldWidget) =>
      !identical(oldWidget.entry, entry);
}

/// Hosts one route. Covered routes stay mounted (state is retained) but are
/// removed from rendering and the accessibility tree.
class _RouteHost extends StatelessWidget {
  const _RouteHost({
    super.key,
    required this.entry,
    required this.hidden,
    required this.current,
  });
  final _RouteEntry entry;
  final bool hidden, current;
  @override
  Widget build(BuildContext context) {
    final route = entry.route;
    final page = _ModalScope(
      entry: entry,
      child: Builder(builder: route._buildPage),
    );
    if (route is _OverlayRoute) {
      return _Box(
        css:
            'position:fixed;inset:0;z-index:10;display:flex;${route.sheet ? 'align-items:flex-end;justify-content:center;' : 'align-items:center;justify-content:center;'}background-color:${colorCss(route.color)};${hidden ? 'display:none;' : ''}',
        key: const ValueKey('overlay'),
        attributes: {
          if (!current) 'inert': '',
          if (hidden) 'aria-hidden': 'true',
        },
        handlers: {
          if (route.dismissible)
            'keydown': (event) {
              if (event?.key == 'Escape') route.navigator?.maybePop();
            },
        },
        fill: _Fill.none,
        children: [
          if (route.dismissible)
            _Box(
              css: 'position:absolute;inset:0;',
              attributes: const {'aria-hidden': 'true'},
              handlers: {'click': (_) => route.navigator?.maybePop()},
              fill: _Fill.none,
            ),
          _Box(
            css: route.anchor == null
                ? 'position:relative;max-width:100%;'
                : 'position:absolute;left:${px(math.max(0, route.anchor!.left))};top:${px(math.max(0, route.anchor!.top))};max-height:calc(100vh - ${px(math.max(0, route.anchor!.top))} - 8px);overflow:auto;',
            fill: _Fill.none,
            children: [page],
          ),
        ],
      );
    }
    return _Box(
      css:
          'grid-area:1/1;display:grid;grid-template-columns:minmax(0,1fr);min-width:0;${hidden ? 'display:none;' : ''}',
      attributes: {
        if (hidden) 'aria-hidden': 'true',
        if (!current) 'inert': '',
      },
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [page],
    );
  }
}

// ---------------------------------------------------------------------------
// Pop scopes.

typedef PopInvokedWithResultCallback<T> = void Function(bool didPop, T? result);

class PopScope<T> extends StatefulWidget {
  const PopScope({
    super.key,
    required this.child,
    this.canPop = true,
    this.onPopInvokedWithResult,
    @Deprecated('Use onPopInvokedWithResult.') this.onPopInvoked,
  });
  final Widget child;
  final bool canPop;
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;
  final void Function(bool didPop)? onPopInvoked;
  @override
  State<PopScope<T>> createState() => _PopScopeState<T>();
}

class _PopScopeState<T> extends State<PopScope<T>> {
  _RouteEntry? _entry;

  void _invoked(bool didPop, Object? result) {
    widget.onPopInvokedWithResult?.call(didPop, result as T?);
    widget.onPopInvoked?.call(didPop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entry = context
        .dependOnInheritedWidgetOfExactType<_ModalScope>()
        ?.entry;
    if (identical(entry, _entry)) return;
    _entry?.popScopes.remove(this);
    _entry = entry;
    entry?.popScopes.add(this);
  }

  @override
  void dispose() {
    _entry?.popScopes.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ---------------------------------------------------------------------------
// Dialogs and sheets.

Future<T?> showDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
  _OverlayRoute<T>(
    builder: builder,
    dismissible: barrierDismissible,
    color: barrierColor ?? const Color(0x8a000000),
    sheet: false,
    settings: routeSettings,
  ),
);

Future<T?> showModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  Color? barrierColor,
  bool isDismissible = true,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool showDragHandle = false,
  RouteSettings? routeSettings,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
  _OverlayRoute<T>(
    builder: (context) =>
        _BottomSheetSurface(color: backgroundColor, child: builder(context)),
    dismissible: isDismissible,
    color: barrierColor ?? const Color(0x52000000),
    sheet: true,
    settings: routeSettings,
  ),
);

class _BottomSheetSurface extends StatelessWidget {
  const _BottomSheetSurface({required this.color, required this.child});
  final Color? color;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Box(
      css:
          'box-sizing:border-box;width:min(640px,100vw);max-height:90vh;overflow-y:auto;border-radius:28px 28px 0 0;background-color:${colorCss(color ?? scheme.surfaceContainerLow)};',
      attributes: const {'role': 'dialog', 'aria-modal': 'true'},
      fill: _Fill.none,
      children: [child],
    );
  }
}

class Dialog extends StatelessWidget {
  const Dialog({
    super.key,
    this.backgroundColor,
    this.elevation,
    this.insetPadding,
    this.shape,
    this.child,
  });
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsets? insetPadding;
  final ShapeBorder? shape;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inset =
        insetPadding ??
        const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
    return _Box(
      css:
          'box-sizing:border-box;min-width:280px;max-width:min(560px,calc(100vw - ${px(inset.horizontal)}));max-height:calc(100vh - ${px(inset.vertical)});overflow:auto;background-color:${colorCss(backgroundColor ?? scheme.surfaceContainerHigh)};${shape == null ? 'border-radius:28px;' : shapeCss(shape)}${elevationCss(elevation ?? 6, scheme.shadow)}',
      attributes: const {'role': 'dialog', 'aria-modal': 'true'},
      fill: _Fill.none,
      children: [?child],
    );
  }
}

class AlertDialog extends StatelessWidget {
  const AlertDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor,
    this.shape,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.actionsAlignment,
    this.insetPadding,
  });
  final Widget? icon, title, content;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? titlePadding, contentPadding, actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final EdgeInsets? insetPadding;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      backgroundColor: backgroundColor,
      shape: shape,
      insetPadding: insetPadding,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: icon == null
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IconTheme.merge(
                  data: IconThemeData(color: scheme.secondary, size: 24),
                  child: icon!,
                ),
              ),
            if (title != null)
              Padding(
                padding: titlePadding ?? const EdgeInsets.only(bottom: 16),
                child: Semantics(
                  header: true,
                  child: DefaultTextStyle(
                    style: theme.textTheme.headlineSmall!.copyWith(
                      color: scheme.onSurface,
                    ),
                    child: title!,
                  ),
                ),
              ),
            if (content != null)
              Padding(
                padding: contentPadding ?? EdgeInsets.zero,
                child: DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  child: content!,
                ),
              ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: actionsPadding ?? const EdgeInsets.only(top: 24),
                child: Wrap(
                  alignment: switch (actionsAlignment) {
                    MainAxisAlignment.start => WrapAlignment.start,
                    MainAxisAlignment.center => WrapAlignment.center,
                    MainAxisAlignment.spaceBetween =>
                      WrapAlignment.spaceBetween,
                    _ => WrapAlignment.end,
                  },
                  spacing: 8,
                  runSpacing: 8,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SimpleDialog extends StatelessWidget {
  const SimpleDialog({
    super.key,
    this.title,
    this.children,
    this.backgroundColor,
  });
  final Widget? title;
  final List<Widget>? children;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: DefaultTextStyle(
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  child: title!,
                ),
              ),
            ...?children,
          ],
        ),
      ),
    );
  }
}

class SimpleDialogOption extends StatelessWidget {
  const SimpleDialogOption({super.key, this.onPressed, this.child});
  final VoidCallback? onPressed;
  final Widget? child;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: child,
    ),
  );
}

/// The viewport rectangle of [context]'s DOM box, for anchoring overlays.
Rect? _viewportRect(BuildContext context) {
  if (context is! Element || !context.mounted) return null;
  final node = context._domNode as JSObject;
  if (!node.has('getBoundingClientRect')) return null;
  final box = node.callMethod<JSObject>('getBoundingClientRect'.toJS);
  double read(String name) =>
      box.getProperty<JSNumber?>(name.toJS)?.toDartDouble ?? 0;
  return Rect.fromLTWH(
    read('left'),
    read('top'),
    read('width'),
    read('height'),
  );
}
