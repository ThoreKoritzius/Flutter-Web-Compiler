/// Framework-independent request state. Executed by Dart, not AST emulation.
enum ResourcePhase { idle, loading, data, error }

class ResourceState<T> {
  const ResourceState(this.phase, {this.value, this.error});
  final ResourcePhase phase;
  final T? value;
  final Object? error;
}

/// A single resource with latest-request-wins semantics and explicit disposal.
/// Superseded requests continue running; their results cannot publish state.
class AsyncResource<T> {
  AsyncResource(this.load);
  final Future<T> Function() load;
  ResourceState<T> _state = const ResourceState(ResourcePhase.idle);
  ResourceState<T> get state => _state;
  final _listeners = <void Function(ResourceState<T>)>{};
  var _generation = 0;
  var _disposed = false;

  void Function() listen(void Function(ResourceState<T>) listener) {
    if (_disposed) throw StateError('Resource is disposed.');
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _publish(ResourceState<T> next) {
    _state = next;
    for (final listener in List.of(_listeners)) {
      if (!_disposed &&
          identical(_state, next) &&
          _listeners.contains(listener)) {
        listener(next);
      }
    }
  }

  Future<void> refresh() async {
    if (_disposed) throw StateError('Resource is disposed.');
    final generation = ++_generation;
    _publish(ResourceState(ResourcePhase.loading, value: _state.value));
    // A loading listener can dispose or supersede this request synchronously.
    if (_disposed || generation != _generation) return;
    T result;
    try {
      result = await load();
    } catch (error) {
      if (!_disposed && generation == _generation) {
        _publish(
          ResourceState(ResourcePhase.error, value: _state.value, error: error),
        );
      }
      return;
    }
    if (!_disposed && generation == _generation) {
      _publish(ResourceState(ResourcePhase.data, value: result));
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _listeners.clear();
  }
}
