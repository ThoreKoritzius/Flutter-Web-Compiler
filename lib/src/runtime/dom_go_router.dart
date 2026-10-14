part of 'flutter_dom.dart';

// An independent implementation of the go_router public API (v14+ shape),
// mapped from `package:go_router/go_router.dart`. Locations use Flutter
// web's default hash URLs; page transitions are not animated.

typedef GoRouterWidgetBuilder =
    Widget Function(BuildContext context, GoRouterState state);
typedef GoRouterPageBuilder =
    Page<dynamic> Function(BuildContext context, GoRouterState state);
typedef GoRouterRedirect =
    FutureOr<String?> Function(BuildContext context, GoRouterState state);
typedef ShellRouteBuilder =
    Widget Function(BuildContext context, GoRouterState state, Widget child);
typedef ShellRoutePageBuilder =
    Page<dynamic> Function(
      BuildContext context,
      GoRouterState state,
      Widget child,
    );
typedef StatefulShellRouteBuilder =
    Widget Function(
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    );
typedef StatefulShellRoutePageBuilder =
    Page<dynamic> Function(
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    );
typedef ShellNavigationContainerBuilder =
    Widget Function(
      BuildContext context,
      StatefulNavigationShell navigationShell,
      List<Widget> children,
    );
typedef ExitCallback =
    FutureOr<bool> Function(BuildContext context, GoRouterState state);
typedef GoExceptionHandler =
    void Function(BuildContext context, GoRouterState state, GoRouter router);

class GoException implements Exception {
  GoException(this.message);
  final String message;
  @override
  String toString() => 'GoException: $message';
}

class GoError extends Error {
  GoError(this.message);
  final String message;
  @override
  String toString() => 'GoError: $message';
}

abstract class RouteBase {
  const RouteBase._({
    this.redirect,
    this.metadata,
    required this.routes,
    required this.parentNavigatorKey,
  });
  final GoRouterRedirect? redirect;
  final Map<String, dynamic>? metadata;
  final List<RouteBase> routes;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
}

class GoRoute extends RouteBase {
  GoRoute({
    required this.path,
    this.name,
    this.builder,
    this.pageBuilder,
    super.parentNavigatorKey,
    super.redirect,
    super.metadata,
    this.onExit,
    this.caseSensitive = true,
    super.routes = const <RouteBase>[],
  }) : super._() {
    if (path.isEmpty) throw GoError('GoRoute path cannot be empty.');
    if (builder == null && pageBuilder == null && redirect == null)
      throw GoError('GoRoute needs builder, pageBuilder or redirect.');
  }
  final String path;
  final String? name;
  final GoRouterWidgetBuilder? builder;
  final GoRouterPageBuilder? pageBuilder;
  final ExitCallback? onExit;
  final bool caseSensitive;
}

class ShellRoute extends RouteBase {
  ShellRoute({
    super.redirect,
    this.builder,
    this.pageBuilder,
    this.notifyRootObserver = true,
    this.observers,
    super.metadata,
    required super.routes,
    super.parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
    this.restorationScopeId,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
       super._();
  final ShellRouteBuilder? builder;
  final ShellRoutePageBuilder? pageBuilder;
  final bool notifyRootObserver;
  final List<NavigatorObserver>? observers;
  final GlobalKey<NavigatorState> navigatorKey;
  final String? restorationScopeId;
}

class StatefulShellBranch {
  StatefulShellBranch({
    required this.routes,
    GlobalKey<NavigatorState>? navigatorKey,
    this.initialLocation,
    this.restorationScopeId,
    this.observers,
    this.preload = false,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
  final List<RouteBase> routes;
  final GlobalKey<NavigatorState> navigatorKey;
  final String? initialLocation, restorationScopeId;
  final List<NavigatorObserver>? observers;
  final bool preload;
}

class StatefulShellRoute extends RouteBase {
  StatefulShellRoute({
    required this.branches,
    super.redirect,
    this.builder,
    this.pageBuilder,
    this.notifyRootObserver = true,
    required this.navigatorContainerBuilder,
    super.parentNavigatorKey,
    super.metadata,
    this.restorationScopeId,
    GlobalKey<StatefulNavigationShellState>? key,
  }) : super._(routes: [for (final branch in branches) ...branch.routes]);
  StatefulShellRoute.indexedStack({
    required List<StatefulShellBranch> branches,
    bool notifyRootObserver = true,
    GoRouterRedirect? redirect,
    StatefulShellRouteBuilder? builder,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    StatefulShellRoutePageBuilder? pageBuilder,
    String? restorationScopeId,
    GlobalKey<StatefulNavigationShellState>? key,
  }) : this(
         branches: branches,
         notifyRootObserver: notifyRootObserver,
         redirect: redirect,
         builder: builder,
         pageBuilder: pageBuilder,
         parentNavigatorKey: parentNavigatorKey,
         restorationScopeId: restorationScopeId,
         navigatorContainerBuilder: _indexedStackContainer,
         key: key,
       );
  final List<StatefulShellBranch> branches;
  final StatefulShellRouteBuilder? builder;
  final StatefulShellRoutePageBuilder? pageBuilder;
  final bool notifyRootObserver;
  final ShellNavigationContainerBuilder navigatorContainerBuilder;
  final String? restorationScopeId;
}

Widget _indexedStackContainer(
  BuildContext context,
  StatefulNavigationShell shell,
  List<Widget> children,
) => IndexedStack(index: shell.currentIndex, children: children);

// ---------------------------------------------------------------------------
// Pages without transitions (transitions are not animated in this runtime).

class NoTransitionPage<T> extends Page<T> implements _ChildPage {
  const NoTransitionPage({
    required this.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  });
  final Widget child;
  @override
  Widget get pageChild => child;
  @override
  Route<T> createRoute(BuildContext context) => _PageBasedRoute<T>(this);
}

class CustomTransitionPage<T> extends Page<T>
    implements _ChildPage, _OpaquePage {
  const CustomTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });
  final Widget child;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )
  transitionsBuilder;
  final Duration transitionDuration, reverseTransitionDuration;
  final bool maintainState, fullscreenDialog, opaque, barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  @override
  bool get isOpaque => opaque;
  @override
  Widget get pageChild => Builder(
    builder: (context) => transitionsBuilder(
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
      child,
    ),
  );
  @override
  Route<T> createRoute(BuildContext context) => _PageBasedRoute<T>(this);
}

// ---------------------------------------------------------------------------
// State and matching.

class GoRouterState {
  GoRouterState._({
    required this.uri,
    required this.matchedLocation,
    this.name,
    this.path,
    required this.fullPath,
    required this.pathParameters,
    this.extra,
    this.error,
    required this.pageKey,
    this.topRoute,
  });
  final Uri uri;
  final String matchedLocation;
  final String? name, path, fullPath;
  final Map<String, String> pathParameters;
  final Object? extra;
  final GoException? error;
  final ValueKey<String> pageKey;
  final GoRoute? topRoute;
  Map<String, dynamic> get metadata => const {};

  static GoRouterState of(BuildContext context) =>
      maybeOf(context) ?? (throw GoError('There is no GoRouterState above.'));
  static GoRouterState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GoRouterStateScope>()?.state;

  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
  }) => _currentRouter!.namedLocation(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );
}

class _GoRouterStateScope extends InheritedWidget {
  const _GoRouterStateScope({required this.state, required super.child});
  final GoRouterState state;
  @override
  bool updateShouldNotify(_GoRouterStateScope oldWidget) =>
      !identical(oldWidget.state, state);
}

/// One matched route: GoRoutes consume path segments; shells do not.
class RouteMatch {
  RouteMatch._(this.route, this.matchedLocation, this.fullPath, this.branch);
  final RouteBase route;
  final String matchedLocation;
  final String fullPath;
  final int branch;
  ValueKey<String> get pageKey => ValueKey(
    route is GoRoute
        ? matchedLocation
        : '$fullPath#shell${identityHashCode(route)}',
  );
}

class RouteMatchList {
  RouteMatchList._(
    this.uri,
    this.matches,
    this.pathParameters,
    this.extra, {
    this.error,
  });
  final Uri uri;
  final List<RouteMatch> matches;
  final Map<String, String> pathParameters;
  final Object? extra;
  final GoException? error;
  bool get isEmpty => matches.isEmpty;
  bool get isNotEmpty => matches.isNotEmpty;
  RouteMatch get last => matches.last;
  String get fullPath => matches.isEmpty ? '' : matches.last.fullPath;
}

String _joinPaths(String parent, String child) {
  if (child.startsWith('/')) return child;
  if (parent.isEmpty || parent == '/') return '/$child';
  return '$parent/$child';
}

List<String> _segments(String path) =>
    path.split('/').where((s) => s.isNotEmpty).toList();

/// Depth-first match of [segments] from [index], returning the route chain.
List<RouteMatch>? _matchRoutes(
  List<RouteBase> routes,
  List<String> segments,
  int index,
  String parentFullPath,
  Map<String, String> params, {
  int branch = -1,
}) {
  for (var r = 0; r < routes.length; r++) {
    final route = routes[r];
    if (route is GoRoute) {
      final fullPath = _joinPaths(parentFullPath, route.path);
      final pattern = _segments(route.path);
      if (index + pattern.length > segments.length) continue;
      final captured = <String, String>{};
      var ok = true;
      for (var i = 0; i < pattern.length; i++) {
        final p = pattern[i], s = segments[index + i];
        if (p.startsWith(':')) {
          captured[p.substring(1)] = Uri.decodeComponent(s);
        } else if (route.caseSensitive
            ? p != s
            : p.toLowerCase() != s.toLowerCase()) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      final next = index + pattern.length;
      final location = '/${segments.take(next).join('/')}';
      final match = RouteMatch._(route, location, fullPath, branch);
      if (next == segments.length) {
        params.addAll(captured);
        return [match];
      }
      final rest = _matchRoutes(
        route.routes,
        segments,
        next,
        fullPath,
        params,
        branch: branch,
      );
      if (rest != null) {
        params.addAll(captured);
        return [match, ...rest];
      }
    } else if (route is StatefulShellRoute) {
      for (var b = 0; b < route.branches.length; b++) {
        final rest = _matchRoutes(
          route.branches[b].routes,
          segments,
          index,
          parentFullPath,
          params,
          branch: b,
        );
        if (rest != null) {
          return [
            RouteMatch._(
              route,
              '/${segments.take(index).join('/')}',
              parentFullPath,
              b,
            ),
            ...rest,
          ];
        }
      }
    } else if (route is ShellRoute) {
      final rest = _matchRoutes(
        route.routes,
        segments,
        index,
        parentFullPath,
        params,
        branch: branch,
      );
      if (rest != null) {
        return [
          RouteMatch._(
            route,
            '/${segments.take(index).join('/')}',
            parentFullPath,
            branch,
          ),
          ...rest,
        ];
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// GoRouter.

GoRouter? _currentRouter;

class _Pushed {
  _Pushed(this.list, this.completer, this.serial, {required this.history});
  RouteMatchList list;
  final Completer<Object?> completer;
  final int serial;
  final bool history;
}

class GoRouterDelegate {
  GoRouterDelegate._(this._router);
  final GoRouter _router;
  RouteMatchList get currentConfiguration => _router._currentList;
  GoRouterState get state => _router.state;
  bool canPop() => _router.canPop();
}

class GoRouter extends ChangeNotifier
    implements RouterConfig<RouteMatchList>, _DomRouterConfig {
  GoRouter({
    required List<RouteBase> routes,
    Codec<Object?, Object?>? extraCodec,
    GoExceptionHandler? onException,
    GoRouterPageBuilder? errorPageBuilder,
    GoRouterWidgetBuilder? errorBuilder,
    GoRouterRedirect? redirect,
    int redirectLimit = 5,
    Listenable? refreshListenable,
    bool routerNeglect = false,
    String? initialLocation,
    bool overridePlatformDefaultLocation = false,
    Object? initialExtra,
    List<NavigatorObserver>? observers,
    bool debugLogDiagnostics = false,
    GlobalKey<NavigatorState>? navigatorKey,
    String? restorationScopeId,
    bool requestFocus = true,
  }) : _routes = routes,
       _onException = onException,
       _errorPageBuilder = errorPageBuilder,
       _errorBuilder = errorBuilder,
       _redirect = redirect,
       _redirectLimit = redirectLimit,
       _refreshListenable = refreshListenable,
       _routerNeglect = routerNeglect,
       _initialLocation = initialLocation ?? '/',
       _overrideLocation = overridePlatformDefaultLocation,
       _initialExtra = initialExtra,
       observers = observers ?? const [],
       navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    _validate(routes, '');
    _refreshListenable?.addListener(refresh);
    _currentRouter = this;
  }

  final List<RouteBase> _routes;
  final GoExceptionHandler? _onException;
  final GoRouterPageBuilder? _errorPageBuilder;
  final GoRouterWidgetBuilder? _errorBuilder;
  final GoRouterRedirect? _redirect;
  final int _redirectLimit;
  final Listenable? _refreshListenable;
  final bool _routerNeglect, _overrideLocation;
  final String _initialLocation;
  final Object? _initialExtra;
  final List<NavigatorObserver> observers;
  final GlobalKey<NavigatorState> navigatorKey;
  final _names = <String, String>{};
  static bool optionURLReflectsImperativeAPIs = false;

  RouteMatchList _currentList = RouteMatchList._(
    Uri.parse('/'),
    const [],
    const {},
    null,
  );
  final _pushed = <_Pushed>[];
  var _serial = 0;
  BuildContext? _context;
  // Remembered location per stateful shell branch.
  final _branchLocations = <StatefulShellRoute, Map<int, String>>{};
  JSFunction? _popListener;
  int _ignoredPops = 0;
  int _navigation = 0;

  late final routerDelegate = GoRouterDelegate._(this);

  void _validate(List<RouteBase> routes, String parent) {
    for (final route in routes) {
      if (route is GoRoute) {
        final full = _joinPaths(parent, route.path);
        if (parent.isEmpty && !route.path.startsWith('/'))
          throw GoError('Top-level route paths must start with "/".');
        if (parent.isNotEmpty && route.path.startsWith('/') && parent != '/')
          throw GoError('Sub-route paths must not start with "/".');
        final name = route.name;
        if (name != null) {
          if (_names.containsKey(name))
            throw GoError('Duplicate route name "$name".');
          _names[name] = full;
        }
        _validate(route.routes, full);
      } else {
        _validate(route.routes, parent);
      }
    }
  }

  static GoRouter of(BuildContext context) =>
      maybeOf(context) ?? (throw GoError('No GoRouter found in context.'));
  static GoRouter? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedGoRouter>()
      ?.goRouter;

  GoRouterState get state => _stateFor(
    _currentList,
    _currentList.matches.isEmpty ? null : _currentList.matches.last,
  );

  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    String? fragment,
  }) {
    final pattern =
        _names[name] ?? (throw GoError('Unknown route name "$name".'));
    final path = _segments(pattern)
        .map((segment) {
          if (!segment.startsWith(':')) return segment;
          final key = segment.substring(1);
          final value =
              pathParameters[key] ??
              (throw GoError('Missing path parameter "$key" for "$name".'));
          return Uri.encodeComponent(value);
        })
        .join('/');
    final query = queryParameters.isEmpty
        ? null
        : {
            for (final entry in queryParameters.entries)
              entry.key: entry.value is Iterable
                  ? (entry.value as Iterable).map((v) => '$v').toList()
                  : '${entry.value}',
          };
    return Uri(
      path: '/$path',
      queryParameters: query,
      fragment: fragment,
    ).toString();
  }

  GoRouterState _stateFor(RouteMatchList list, RouteMatch? match) {
    final top = list.matches.lastWhere(
      (m) => m.route is GoRoute,
      orElse: () => RouteMatch._(_routes.first, '/', '/', -1),
    );
    final route = match?.route;
    return GoRouterState._(
      uri: list.uri,
      matchedLocation: match?.matchedLocation ?? list.uri.path,
      name: route is GoRoute ? route.name : null,
      path: route is GoRoute ? route.path : null,
      fullPath: match?.fullPath ?? list.fullPath,
      pathParameters: list.pathParameters,
      extra: list.extra,
      error: list.error,
      pageKey: match?.pageKey ?? ValueKey(list.uri.path),
      topRoute: top.route is GoRoute ? top.route as GoRoute : null,
    );
  }

  RouteMatchList _match(Uri uri, Object? extra) {
    final params = <String, String>{};
    final matches = _matchRoutes(_routes, _segments(uri.path), 0, '', params);
    if (matches == null || matches.isEmpty || matches.last.route is! GoRoute) {
      return RouteMatchList._(
        uri,
        const [],
        const {},
        extra,
        error: GoException('no routes for location: $uri'),
      );
    }
    return RouteMatchList._(uri, matches, params, extra);
  }

  /// Resolves redirects; null when a newer navigation superseded this one.
  Future<RouteMatchList?> _resolve(String location, Object? extra) async {
    final id = ++_navigation;
    var uri = Uri.parse(location.isEmpty ? '/' : location);
    final seen = <String>[];
    for (var hop = 0; ; hop++) {
      var list = _match(uri, extra);
      final context = _context;
      String? target;
      if (context != null) {
        final top = _redirect;
        if (top != null) {
          final result = top(context, _stateFor(list, null));
          target = result is Future<String?> ? await result : result;
        }
        if (target == null) {
          for (final match in list.matches) {
            final redirect = match.route.redirect;
            if (redirect == null) continue;
            final result = redirect(context, _stateFor(list, match));
            target = result is Future<String?> ? await result : result;
            if (target != null) break;
          }
        }
      }
      if (id != _navigation) return null;
      if (target == null || target == uri.toString()) return list;
      seen.add(uri.toString());
      if (hop >= _redirectLimit || seen.contains(target)) {
        return RouteMatchList._(
          uri,
          const [],
          const {},
          extra,
          error: GoException(
            hop >= _redirectLimit
                ? 'too many redirects ${[...seen, target].join(' => ')}'
                : 'redirect loop detected ${[...seen, target].join(' => ')}',
          ),
        );
      }
      uri = Uri.parse(target);
      list = _match(uri, extra);
    }
  }

  void _rememberBranches(RouteMatchList list) {
    for (final match in list.matches) {
      final route = match.route;
      if (route is StatefulShellRoute && match.branch >= 0) {
        (_branchLocations[route] ??= {})[match.branch] = list.uri.toString();
      }
    }
  }

  Future<bool> _allowExit(RouteMatchList from, RouteMatchList to) async {
    final context = _context;
    if (context == null) return true;
    for (final match in from.matches.reversed) {
      final route = match.route;
      if (route is! GoRoute || route.onExit == null) continue;
      if (to.matches.any((m) => identical(m.route, route))) continue;
      final result = route.onExit!(context, _stateFor(from, match));
      if (!(result is Future<bool> ? await result : result)) return false;
    }
    return true;
  }

  Future<void> _apply(
    String location,
    Object? extra, {
    required bool history,
    bool replaceHistory = false,
  }) async {
    final list = await _resolve(location, extra);
    if (list == null) return;
    if (!await _allowExit(_currentList, list)) return;
    _currentList = list;
    for (final pushed in _pushed) {
      if (!pushed.completer.isCompleted) pushed.completer.complete(null);
    }
    _pushed.clear();
    _rememberBranches(list);
    if (history) _writeHistory(list.uri.toString(), replace: replaceHistory);
    if (list.error != null) _reportError(list);
    notifyListeners();
  }

  void _reportError(RouteMatchList list) {
    final handler = _onException;
    final context = _context;
    if (handler != null && context != null) {
      handler(context, _stateFor(list, null), this);
    }
  }

  void go(String location, {Object? extra}) =>
      unawaited(_apply(location, extra, history: !_routerNeglect));

  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
    String? fragment,
  }) => go(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      fragment: fragment,
    ),
    extra: extra,
  );

  Future<T?> push<T extends Object?>(String location, {Object? extra}) async {
    final list = await _resolve(location, extra);
    if (list == null) return null;
    final writeUrl = optionURLReflectsImperativeAPIs && !_routerNeglect;
    final entry = _Pushed(
      list,
      Completer<Object?>(),
      _serial++,
      history: writeUrl,
    );
    _pushed.add(entry);
    if (writeUrl) _writeHistory(list.uri.toString());
    notifyListeners();
    return await entry.completer.future as T?;
  }

  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => push<T>(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    ),
    extra: extra,
  );

  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) async {
    if (_pushed.isEmpty) {
      await _apply(
        location,
        extra,
        history: !_routerNeglect,
        replaceHistory: true,
      );
      return null;
    }
    final old = _pushed.removeLast();
    if (!old.completer.isCompleted) old.completer.complete(null);
    return push<T>(location, extra: extra);
  }

  Future<T?> pushReplacementNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => pushReplacement<T>(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    ),
    extra: extra,
  );

  Future<T?> replace<T>(String location, {Object? extra}) async =>
      await pushReplacement<Object?>(location, extra: extra) as T?;

  Future<T?> replaceNamed<T>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => replace<T>(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    ),
    extra: extra,
  );

  /// The location of the closest enclosing page in the declarative chain.
  String? _parentLocation() {
    final pages = _currentList.matches.whereType<RouteMatch>().where(
      (m) => m.route is GoRoute,
    );
    if (pages.length < 2) return null;
    final parent = pages.elementAt(pages.length - 2);
    return parent.matchedLocation;
  }

  bool canPop() => _pushed.isNotEmpty || _parentLocation() != null;

  void pop<T extends Object?>([T? result]) {
    if (_pushed.isNotEmpty) {
      final entry = _pushed.removeLast();
      if (!entry.completer.isCompleted) entry.completer.complete(result);
      if (entry.history) {
        _ignoredPops++;
        _history?.back();
      }
      notifyListeners();
      return;
    }
    final parent = _parentLocation();
    if (parent == null) throw GoError('There is nothing to pop.');
    go(parent);
  }

  void refresh() {
    if (_context == null) return;
    // Redirects reported by a refresh replace the current URL entry.
    unawaited(
      _apply(
        _currentList.uri.toString(),
        _currentList.extra,
        history: !_routerNeglect,
        replaceHistory: true,
      ),
    );
  }

  void _writeHistory(String location, {bool replace = false}) {
    final history = _history;
    if (history == null) return;
    final url = '#${Uri.encodeFull(location)}'.replaceAll('%25', '%');
    if (replace) {
      history.replaceState(null, '', url);
    } else {
      history.pushState(null, '', url);
    }
  }

  void _onBrowserPop() {
    if (_ignoredPops > 0) {
      _ignoredPops--;
      return;
    }
    final hash = _locationHash();
    final location = hash == null || hash.isEmpty ? '/' : Uri.decodeFull(hash);
    if (_pushed.isNotEmpty) {
      final entry = _pushed.removeLast();
      if (!entry.completer.isCompleted) entry.completer.complete(null);
      notifyListeners();
      return;
    }
    unawaited(_apply(location, null, history: false));
  }

  void _attach(BuildContext context) {
    _context = context;
    _currentRouter = this;
    final hash = _routerNeglect || _overrideLocation ? null : _locationHash();
    final initial = hash == null || hash.isEmpty
        ? _initialLocation
        : Uri.decodeFull(hash);
    unawaited(
      _apply(
        initial,
        _initialExtra,
        history: !_routerNeglect,
        replaceHistory: true,
      ),
    );
    if (!_routerNeglect && _history != null) {
      _popListener = ((JSAny? _) => _onBrowserPop()).toJS;
      _window.addEventListener('popstate', _popListener!);
    }
  }

  void _detach() {
    _context = null;
    if (_popListener != null) {
      _window.removeEventListener('popstate', _popListener!);
      _popListener = null;
    }
  }

  @override
  void dispose() {
    _detach();
    _refreshListenable?.removeListener(refresh);
    for (final entry in _pushed) {
      if (!entry.completer.isCompleted) entry.completer.complete(null);
    }
    super.dispose();
  }

  @override
  Widget _buildRouterView() => _GoRouterView(router: this);
}

class _InheritedGoRouter extends InheritedWidget {
  const _InheritedGoRouter({required this.goRouter, required super.child});
  final GoRouter goRouter;
  @override
  bool updateShouldNotify(_InheritedGoRouter oldWidget) =>
      !identical(oldWidget.goRouter, goRouter);
}

// ---------------------------------------------------------------------------
// View: declarative navigators for the current match chain.

class _GoRouterView extends StatefulWidget {
  const _GoRouterView({required this.router});
  final GoRouter router;
  @override
  State<_GoRouterView> createState() => _GoRouterViewState();
}

class _GoRouterViewState extends State<_GoRouterView> {
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.router.addListener(_changed);
    widget.router._attach(context);
  }

  @override
  void dispose() {
    widget.router.removeListener(_changed);
    widget.router._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = widget.router;
    final list = router._currentList;
    if (list.isEmpty && list.error == null) return const SizedBox.shrink();
    return _InheritedGoRouter(
      goRouter: router,
      child: _GoNavigatorBuilder(router: router).buildRoot(context),
    );
  }
}

/// Builds pages for one navigator; shells nest their own navigators.
class _GoNavigatorBuilder {
  _GoNavigatorBuilder({required this.router});
  final GoRouter router;
  final _pageMatches = HashMap<Page<dynamic>, Object>.identity();

  Widget buildRoot(BuildContext context) {
    final list = router._currentList;
    final pages = <Page<dynamic>>[];
    if (list.error != null) {
      pages.add(_errorPage(context, list));
    } else {
      pages.addAll(_pagesFor(context, list, list.matches, router.navigatorKey));
    }
    for (final pushed in router._pushed) {
      final match = pushed.list.matches.isEmpty
          ? null
          : pushed.list.matches.last;
      if (match == null) continue;
      final page = _goPage(
        context,
        pushed.list,
        match,
        key: ValueKey('push-${pushed.serial}'),
      );
      _pageMatches[page] = pushed;
      pages.add(page);
    }
    return _navigator(router.navigatorKey, pages, router.observers);
  }

  Widget _navigator(
    GlobalKey<NavigatorState> key,
    List<Page<dynamic>> pages,
    List<NavigatorObserver> observers,
  ) => Navigator(
    key: key,
    pages: pages,
    observers: observers,
    onDidRemovePage: (page) {
      final owner = _pageMatches[page];
      if (owner is _Pushed) {
        router._pushed.remove(owner);
        if (!owner.completer.isCompleted) owner.completer.complete(null);
        router.notifyListeners();
      } else if (owner is RouteMatch) {
        final parent = router._parentLocation();
        if (parent != null) router.go(parent);
      }
    },
  );

  Page<dynamic> _errorPage(BuildContext context, RouteMatchList list) {
    final state = router._stateFor(list, null);
    final custom = router._errorPageBuilder;
    if (custom != null) return custom(context, state);
    final builder = router._errorBuilder;
    return MaterialPage<void>(
      key: const ValueKey('go-error'),
      child: _GoRouterStateScope(
        state: state,
        child: builder != null
            ? Builder(builder: (context) => builder(context, state))
            : _DefaultErrorScreen(error: list.error),
      ),
    );
  }

  Page<dynamic> _goPage(
    BuildContext context,
    RouteMatchList list,
    RouteMatch match, {
    LocalKey? key,
  }) {
    final route = match.route as GoRoute;
    final state = router._stateFor(list, match);
    final pageBuilder = route.pageBuilder;
    if (pageBuilder != null) {
      final page = pageBuilder(context, state);
      return _ScopedPage(page, state, key ?? page.key ?? state.pageKey);
    }
    return MaterialPage<void>(
      key: key ?? state.pageKey,
      name: route.name ?? route.path,
      child: _GoRouterStateScope(
        state: state,
        child: Builder(builder: (context) => route.builder!(context, state)),
      ),
    );
  }

  /// Pages for [matches] in the navigator identified by [navigatorKey].
  List<Page<dynamic>> _pagesFor(
    BuildContext context,
    RouteMatchList list,
    List<RouteMatch> matches,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final pages = <Page<dynamic>>[];
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final route = match.route;
      if (route is GoRoute) {
        final page = _goPage(context, list, match);
        _pageMatches[page] = match;
        pages.add(page);
      } else if (route is ShellRoute || route is StatefulShellRoute) {
        final rest = matches.sublist(i + 1);
        // Routes that target an outer navigator escape the shell.
        final inner = [
          for (final m in rest)
            if (m.route.parentNavigatorKey == null ||
                !identical(m.route.parentNavigatorKey, navigatorKey))
              m,
        ];
        final escaped = [
          for (final m in rest)
            if (identical(m.route.parentNavigatorKey, navigatorKey)) m,
        ];
        pages.add(_shellPage(context, list, match, inner));
        for (final m in escaped) {
          if (m.route is GoRoute) {
            final page = _goPage(context, list, m);
            _pageMatches[page] = m;
            pages.add(page);
          }
        }
        break;
      }
    }
    return pages;
  }

  Page<dynamic> _shellPage(
    BuildContext context,
    RouteMatchList list,
    RouteMatch match,
    List<RouteMatch> inner,
  ) {
    final state = router._stateFor(list, match);
    final route = match.route;
    Widget child;
    Page<dynamic>? custom;
    if (route is ShellRoute) {
      final navigator = _navigator(
        route.navigatorKey,
        _pagesFor(context, list, inner, route.navigatorKey),
        route.observers ?? const [],
      );
      if (route.pageBuilder != null) {
        custom = route.pageBuilder!(context, state, navigator);
      }
      child = route.builder == null
          ? navigator
          : Builder(
              builder: (context) => route.builder!(context, state, navigator),
            );
    } else {
      final shell = route as StatefulShellRoute;
      final navigationShell = StatefulNavigationShell._(
        router: router,
        route: shell,
        currentIndex: match.branch,
        branchChildren: (context) => [
          for (var b = 0; b < shell.branches.length; b++)
            _branchNavigator(
              context,
              shell,
              b,
              b == match.branch ? inner : null,
            ),
        ],
      );
      if (shell.pageBuilder != null) {
        custom = shell.pageBuilder!(context, state, navigationShell);
      }
      child = shell.builder == null
          ? navigationShell
          : Builder(
              builder: (context) =>
                  shell.builder!(context, state, navigationShell),
            );
    }
    if (custom != null)
      return _ScopedPage(custom, state, custom.key ?? match.pageKey);
    return MaterialPage<void>(
      key: match.pageKey,
      child: _GoRouterStateScope(state: state, child: child),
    );
  }

  Widget _branchNavigator(
    BuildContext context,
    StatefulShellRoute shell,
    int index,
    List<RouteMatch>? active,
  ) {
    final branch = shell.branches[index];
    var matches = active;
    RouteMatchList list = router._currentList;
    if (matches == null) {
      final remembered = router._branchLocations[shell]?[index];
      if (remembered == null) {
        return SizedBox.shrink(key: ValueKey('branch-$index'));
      }
      list = router._match(Uri.parse(remembered), null);
      final at = list.matches.indexWhere((m) => identical(m.route, shell));
      if (at < 0) return SizedBox.shrink(key: ValueKey('branch-$index'));
      matches = list.matches.sublist(at + 1);
    }
    return KeyedSubtree(
      key: ValueKey('branch-$index'),
      child: _navigator(
        branch.navigatorKey,
        _pagesFor(context, list, matches, branch.navigatorKey),
        branch.observers ?? const [],
      ),
    );
  }
}

/// Wraps a user page so its child sees the right GoRouterState.
class _ScopedPage extends Page<dynamic> implements _ChildPage, _OpaquePage {
  _ScopedPage(this.inner, this.state, LocalKey key)
    : super(key: key, name: inner.name, arguments: inner.arguments);
  final Page<dynamic> inner;
  final GoRouterState state;
  @override
  bool canUpdate(Page<dynamic> other) =>
      other is _ScopedPage &&
      other.key == key &&
      other.inner.runtimeType == inner.runtimeType;
  @override
  bool get isOpaque {
    final inner = this.inner;
    return inner is _OpaquePage ? (inner as _OpaquePage).isOpaque : true;
  }

  @override
  Widget get pageChild {
    final inner = this.inner;
    final child = switch (inner) {
      final MaterialPage<dynamic> page => page.child,
      final _ChildPage page => page.pageChild,
      _ => throw UnsupportedError(
        'Unsupported page type: ${inner.runtimeType}',
      ),
    };
    return _GoRouterStateScope(state: state, child: child);
  }

  @override
  Route<dynamic> createRoute(BuildContext context) => _PageBasedRoute(this);
}

class _DefaultErrorScreen extends StatelessWidget {
  const _DefaultErrorScreen({required this.error});
  final GoException? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(child: Text(error?.toString() ?? 'page not found')),
  );
}

class StatefulNavigationShell extends StatefulWidget {
  StatefulNavigationShell._({
    required GoRouter router,
    required this.route,
    required this.currentIndex,
    required this.branchChildren,
  }) : _router = router,
       super(key: ValueKey(route));
  final GoRouter _router;
  final StatefulShellRoute route;
  final int currentIndex;
  final List<Widget> Function(BuildContext context) branchChildren;

  /// Navigates to the last location of the branch at [index], or its
  /// initial location when [initialLocation] is true or it was never shown.
  void goBranch(int index, {bool initialLocation = false}) {
    if (index < 0 || index >= route.branches.length)
      throw RangeError.index(index, route.branches);
    final remembered = _router._branchLocations[route]?[index];
    final location = !initialLocation && remembered != null
        ? remembered
        : route.branches[index].initialLocation ??
              _defaultBranchLocation(route.branches[index].routes, '');
    if (location == null)
      throw GoError('Branch $index has no initial location.');
    _router.go(location);
  }

  static String? _defaultBranchLocation(List<RouteBase> routes, String parent) {
    for (final route in routes) {
      if (route is GoRoute) {
        final full = _joinPaths(parent, route.path);
        if (!full.contains(':')) return full;
      } else if (route is ShellRoute) {
        final nested = _defaultBranchLocation(route.routes, parent);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  @override
  State<StatefulNavigationShell> createState() =>
      StatefulNavigationShellState();
}

class StatefulNavigationShellState extends State<StatefulNavigationShell> {
  int get currentIndex => widget.currentIndex;
  void goBranch(int index, {bool initialLocation = false}) =>
      widget.goBranch(index, initialLocation: initialLocation);
  @override
  Widget build(BuildContext context) => widget.route.navigatorContainerBuilder(
    context,
    widget,
    widget.branchChildren(context),
  );
}

extension GoRouterHelper on BuildContext {
  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    String? fragment,
  }) => GoRouter.of(this).namedLocation(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    fragment: fragment,
  );
  void go(String location, {Object? extra}) =>
      GoRouter.of(this).go(location, extra: extra);
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
    String? fragment,
  }) => GoRouter.of(this).goNamed(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    extra: extra,
    fragment: fragment,
  );
  Future<T?> push<T extends Object?>(String location, {Object? extra}) =>
      GoRouter.of(this).push<T>(location, extra: extra);
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => GoRouter.of(this).pushNamed<T>(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    extra: extra,
  );
  bool canPop() => GoRouter.of(this).canPop();

  /// Pops dialogs and imperative routes of the nearest navigator first,
  /// then the router's own stack, as go_router does.
  void pop<T extends Object?>([T? result]) {
    final navigator = Navigator.maybeOf(this);
    if (navigator != null &&
        navigator._entries.isNotEmpty &&
        navigator._entries.last.page == null &&
        navigator.canPop()) {
      navigator.pop<T>(result);
      return;
    }
    GoRouter.of(this).pop<T>(result);
  }

  void pushReplacement(String location, {Object? extra}) =>
      GoRouter.of(this).pushReplacement(location, extra: extra);
  void pushReplacementNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => GoRouter.of(this).pushReplacementNamed(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    extra: extra,
  );
  void replace(String location, {Object? extra}) =>
      GoRouter.of(this).replace<Object?>(location, extra: extra);
  void replaceNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => GoRouter.of(this).replaceNamed<Object?>(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    extra: extra,
  );
}
