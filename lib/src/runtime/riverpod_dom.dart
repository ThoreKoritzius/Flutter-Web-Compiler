/// Bounded root consumer integration using the official Riverpod 2.6.1 engine.
library;

import 'package:riverpod/riverpod.dart';
import 'flutter_dom.dart';
export 'package:riverpod/riverpod.dart';

class ProviderScope extends DomRootScope {
  const ProviderScope({
    required this.child,
    this.overrides = const [],
    super.key,
  });
  @override
  final Widget child;
  final List<Override> overrides;
  @override
  void Function() openDomScope(State state) {
    if (state is! ConsumerState) {
      throw UnsupportedError('ProviderScope requires a root ConsumerState.');
    }
    final container = ProviderContainer(overrides: overrides);
    state._attach(container);
    return container.dispose;
  }
}

abstract class ConsumerStatefulWidget extends StatefulWidget {
  const ConsumerStatefulWidget({super.key});
  @override
  ConsumerState createState();
}

abstract class ConsumerState<T extends ConsumerStatefulWidget> extends State<T>
    implements DomBuildLifecycle {
  WidgetRef? _ref;
  WidgetRef get ref =>
      _ref ?? (throw StateError('Missing root ProviderScope.'));
  void _attach(ProviderContainer container) {
    _ref = WidgetRef._(container, () => mounted, () => setState(() {}));
  }

  @override
  void beginDomBuild() => ref._begin();
  @override
  void endDomBuild() => ref._end();
  @override
  void disposeDomBuild() => _ref?._dispose();
}

/// Only read/watch are supported. Provider internals remain official Riverpod.
class WidgetRef {
  WidgetRef._(this._container, this._mounted, this._invalidate);
  final ProviderContainer _container;
  final bool Function() _mounted;
  final void Function() _invalidate;
  final _subscriptions =
      <ProviderListenable<Object?>, ProviderSubscription<Object?>>{};
  final _used = <ProviderListenable<Object?>>{};
  bool _building = false;
  bool _disposed = false;

  void _check() {
    if (_disposed || !_mounted())
      throw StateError('Provider ref after disposal.');
  }

  T read<T>(ProviderListenable<T> provider) {
    _check();
    return _container.read(provider);
  }

  T watch<T>(ProviderListenable<T> provider) {
    _check();
    if (!_building)
      throw StateError('ref.watch is only supported during build.');
    _used.add(provider);
    final subscription = _subscriptions.putIfAbsent(
      provider,
      () => _container.listen<T>(provider, (_, __) {
        if (!_disposed && _mounted()) _invalidate();
      }),
    );
    return subscription.read() as T;
  }

  void _begin() {
    _check();
    _building = true;
    _used.clear();
  }

  void _end() {
    _building = false;
    for (final provider in _subscriptions.keys.toList()) {
      if (!_used.contains(provider)) _subscriptions.remove(provider)!.close();
    }
  }

  void _dispose() {
    _disposed = true;
    for (final subscription in _subscriptions.values) {
      subscription.close();
    }
    _subscriptions.clear();
  }
}
