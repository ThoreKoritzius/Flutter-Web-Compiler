/// Riverpod widget bindings for the native runtime, backed by the official
/// pure-Dart Riverpod 2.6.1 engine. Provider evaluation is never replaced.
library;

import 'package:riverpod/riverpod.dart';
import 'flutter_dom.dart';
export 'package:riverpod/riverpod.dart';

/// Owns a [ProviderContainer] for its subtree. Nested scopes create child
/// containers, so overrides apply only below them.
class ProviderScope extends StatefulWidget {
  const ProviderScope({
    super.key,
    this.overrides = const [],
    this.observers,
    this.parent,
    required this.child,
  });
  final List<Override> overrides;
  final List<ProviderObserver>? observers;
  final ProviderContainer? parent;
  final Widget child;

  static ProviderContainer containerOf(
    BuildContext context, {
    bool listen = true,
  }) {
    final scope = listen
        ? context
              .dependOnInheritedWidgetOfExactType<UncontrolledProviderScope>()
        : context.getInheritedWidgetOfExactType<UncontrolledProviderScope>();
    if (scope == null) throw StateError('Missing ProviderScope ancestor.');
    return scope.container;
  }

  @override
  State<ProviderScope> createState() => _ProviderScopeState();
}

class _ProviderScopeState extends State<ProviderScope> {
  late final ProviderContainer container;

  @override
  void initState() {
    super.initState();
    final parent =
        widget.parent ??
        context
            .getInheritedWidgetOfExactType<UncontrolledProviderScope>()
            ?.container;
    container = ProviderContainer(
      parent: parent,
      overrides: widget.overrides,
      observers: widget.observers,
    );
  }

  @override
  void didUpdateWidget(ProviderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.overrides, widget.overrides))
      container.updateOverrides(widget.overrides);
  }

  @override
  void dispose() {
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: container, child: widget.child);
}

/// Exposes an externally owned container; the caller disposes it.
class UncontrolledProviderScope extends InheritedWidget {
  const UncontrolledProviderScope({
    super.key,
    required this.container,
    required super.child,
  });
  final ProviderContainer container;
  @override
  bool updateShouldNotify(UncontrolledProviderScope oldWidget) =>
      !identical(oldWidget.container, container);
}

abstract class ConsumerStatefulWidget extends StatefulWidget {
  const ConsumerStatefulWidget({super.key});
  @override
  ConsumerState createState();
}

abstract class ConsumerState<T extends ConsumerStatefulWidget> extends State<T>
    implements DomBuildLifecycle {
  WidgetRef? _ref;
  WidgetRef get ref => _ref ??= WidgetRef._(this);

  @override
  void beginDomBuild() => ref._begin();
  @override
  void endDomBuild() => ref._end();
  @override
  void disposeDomBuild() => _ref?._dispose();
}

abstract class ConsumerWidget extends ConsumerStatefulWidget {
  const ConsumerWidget({super.key});
  Widget build(BuildContext context, WidgetRef ref);
  @override
  ConsumerState<ConsumerWidget> createState() => _ConsumerWidgetState();
}

class _ConsumerWidgetState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) => widget.build(context, ref);
}

typedef ConsumerBuilder =
    Widget Function(BuildContext context, WidgetRef ref, Widget? child);

class Consumer extends ConsumerWidget {
  const Consumer({super.key, required this.builder, this.child});
  final ConsumerBuilder builder;
  final Widget? child;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      builder(context, ref, child);
}

class _BuildListener {
  _BuildListener(this.subscription, this.callback);
  final ProviderSubscription<Object?> subscription;
  void Function(Object? previous, Object? next) callback;
}

/// Widget-side provider access. `watch` and `listen` are build-scoped:
/// subscriptions not renewed during a build are closed afterwards.
class WidgetRef {
  WidgetRef._(this._state)
    : _container = ProviderScope.containerOf(_state.context, listen: false);
  final ConsumerState<ConsumerStatefulWidget> _state;
  final ProviderContainer _container;
  final _watched =
      <ProviderListenable<Object?>, ProviderSubscription<Object?>>{};
  final _listeners = <ProviderListenable<Object?>, _BuildListener>{};
  final _manual = <ProviderSubscription<Object?>>[];
  final _usedWatches = <ProviderListenable<Object?>>{};
  final _usedListeners = <ProviderListenable<Object?>>{};
  bool _building = false;
  bool _disposed = false;

  BuildContext get context => _state.context;

  void _check() {
    if (_disposed || !_state.mounted)
      throw StateError('Provider ref after disposal.');
  }

  T read<T>(ProviderListenable<T> provider) {
    _check();
    return _container.read(provider);
  }

  bool exists(ProviderBase<Object?> provider) {
    _check();
    return _container.exists(provider);
  }

  T watch<T>(ProviderListenable<T> provider) {
    _check();
    if (!_building)
      throw StateError('ref.watch is only supported during build.');
    _usedWatches.add(provider);
    final subscription = _watched.putIfAbsent(
      provider,
      () => _container.listen<T>(provider, (_, _) {
        if (!_disposed && _state.mounted) _state.setState(() {});
      }),
    );
    return subscription.read() as T;
  }

  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _check();
    if (!_building)
      throw StateError('ref.listen is only supported during build.');
    _usedListeners.add(provider);
    void callback(Object? previous, Object? next) =>
        listener(previous as T?, next as T);
    final existing = _listeners[provider];
    if (existing != null) {
      existing.callback = callback;
      return;
    }
    late final _BuildListener entry;
    final subscription = _container.listen<T>(provider, (previous, next) {
      if (!_disposed && _state.mounted) entry.callback(previous, next);
    }, onError: onError);
    entry = _BuildListener(subscription, callback);
    _listeners[provider] = entry;
  }

  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    _check();
    final subscription = _container.listen<T>(
      provider,
      listener,
      onError: onError,
      fireImmediately: fireImmediately,
    );
    _manual.add(subscription);
    return subscription;
  }

  void invalidate(ProviderOrFamily provider) {
    _check();
    _container.invalidate(provider);
  }

  T refresh<T>(Refreshable<T> provider) {
    _check();
    return _container.refresh(provider);
  }

  void _begin() {
    _check();
    _building = true;
    _usedWatches.clear();
    _usedListeners.clear();
  }

  void _end() {
    _building = false;
    for (final provider in _watched.keys.toList()) {
      if (!_usedWatches.contains(provider)) _watched.remove(provider)!.close();
    }
    for (final provider in _listeners.keys.toList()) {
      if (!_usedListeners.contains(provider))
        _listeners.remove(provider)!.subscription.close();
    }
  }

  void _dispose() {
    _disposed = true;
    for (final subscription in [
      ..._watched.values,
      for (final entry in _listeners.values) entry.subscription,
      ..._manual,
    ]) {
      subscription.close();
    }
    _watched.clear();
    _listeners.clear();
    _manual.clear();
  }
}
