/// Explicit in-process Dart adapters, not Flutter binary platform channels.
library;

import 'dart:async';

export 'dart:typed_data';

class MissingPluginException implements Exception {
  MissingPluginException([this.message]);
  final String? message;
  @override
  String toString() => 'MissingPluginException($message)';
}

class PlatformException implements Exception {
  PlatformException({
    required this.code,
    this.message,
    this.details,
    this.stacktrace,
  });
  final String code;
  final String? message;
  final dynamic details;
  final String? stacktrace;
  @override
  String toString() =>
      'PlatformException($code, $message, $details, $stacktrace)';
}

class MethodCall {
  const MethodCall(this.method, [this.arguments]);
  final String method;
  final dynamic arguments;
}

typedef DomMethodHandler = FutureOr<Object?> Function(MethodCall call);
final _handlers = <String, DomMethodHandler>{};

/// No plugin is registered automatically. Duplicate registrations fail.
/// The returned idempotent disposer unregisters this exact handler.
void Function() registerDomMethodChannel(
  String name,
  DomMethodHandler handler,
) {
  if (_handlers.containsKey(name))
    throw StateError('Channel already registered: $name');
  _handlers[name] = handler;
  var active = true;
  return () {
    if (!active) return;
    active = false;
    if (identical(_handlers[name], handler)) _handlers.remove(name);
  };
}

class MethodChannel {
  const MethodChannel(this.name);
  final String name;

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    final handler = _handlers[name];
    if (handler == null)
      throw MissingPluginException(
        'No DOM adapter for method $method on channel $name',
      );
    return (await handler(MethodCall(method, arguments))) as T?;
  }

  Future<List<T>?> invokeListMethod<T>(
    String method, [
    dynamic arguments,
  ]) async => (await invokeMethod<List<dynamic>>(method, arguments))?.cast<T>();

  Future<Map<K, V>?> invokeMapMethod<K, V>(
    String method, [
    dynamic arguments,
  ]) async => (await invokeMethod<Map<dynamic, dynamic>>(
    method,
    arguments,
  ))?.cast<K, V>();
}
