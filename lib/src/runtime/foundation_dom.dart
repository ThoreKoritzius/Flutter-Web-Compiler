/// Bounded foundation APIs for the official Dart web runtime target.
library;

export 'dart:typed_data';

import 'dart:async';

import 'browser_platform.dart'
    if (dart.library.js_interop) 'browser_platform_web.dart';

const bool kIsWeb = bool.fromEnvironment('dart.library.js_interop');
const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');
const bool kProfileMode = bool.fromEnvironment('dart.vm.profile');
const bool kDebugMode = !kReleaseMode && !kProfileMode;

typedef ComputeCallback<M, R> = FutureOr<R> Function(M message);

/// Web behavior: yield before invoking the callback on the current event loop.
/// This does not create a worker or provide Flutter profiling events.
Future<R> compute<M, R>(
  ComputeCallback<M, R> callback,
  M message, {
  String? debugLabel,
}) async {
  await Future<void>.value();
  return callback(message);
}

typedef DebugPrintCallback = void Function(String? message, {int? wrapWidth});

/// Explicit synchronous console logging; Flutter throttling is not implemented.
DebugPrintCallback debugPrint = debugPrintSynchronously;

void debugPrintSynchronously(String? message, {int? wrapWidth}) {
  if (wrapWidth != null)
    throw UnsupportedError('Debug log wrapping is unsupported.');
  print(message);
}

/// Prints [stackTrace] (or the current one) with an optional [label].
void debugPrintStack({StackTrace? stackTrace, String? label, int? maxFrames}) {
  if (label != null) debugPrint(label);
  var lines = (stackTrace ?? StackTrace.current).toString().trimRight().split(
    '\n',
  );
  if (maxFrames != null) lines = lines.take(maxFrames).toList();
  debugPrint(lines.join('\n'));
}

enum TargetPlatform { android, fuchsia, iOS, linux, macOS, windows }

/// Overrides [defaultTargetPlatform] in debug code, as in Flutter.
TargetPlatform? debugDefaultTargetPlatformOverride;

/// The operating system the browser runs on, detected from the user agent
/// the way Flutter web does; Android when unknown.
TargetPlatform get defaultTargetPlatform =>
    debugDefaultTargetPlatformOverride ?? _browserPlatform;

final TargetPlatform _browserPlatform = () {
  final agent = (browserUserAgent() ?? '').toLowerCase();
  if (agent.contains('iphone') ||
      agent.contains('ipad') ||
      agent.contains('ipod')) {
    return TargetPlatform.iOS;
  }
  if (agent.contains('android')) return TargetPlatform.android;
  if (agent.contains('mac')) return TargetPlatform.macOS;
  if (agent.contains('win')) return TargetPlatform.windows;
  if (agent.contains('linux') || agent.contains('cros')) {
    return TargetPlatform.linux;
  }
  return TargetPlatform.android;
}();

typedef VoidCallback = void Function();
typedef ValueChanged<T> = void Function(T value);
typedef ValueSetter<T> = void Function(T value);
typedef ValueGetter<T> = T Function();
typedef AsyncCallback = Future<void> Function();

/// Pure-Dart listener contracts matching Flutter's foundation semantics:
/// listeners added during notification are not called until the next one,
/// and removal during notification takes effect immediately.
abstract class Listenable {
  const Listenable();
  factory Listenable.merge(Iterable<Listenable?> listenables) =
      _MergingListenable;
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

abstract class ValueListenable<T> extends Listenable {
  const ValueListenable();
  T get value;
}

class _MergingListenable extends Listenable {
  _MergingListenable(this._children);
  final Iterable<Listenable?> _children;
  @override
  void addListener(VoidCallback listener) {
    for (final child in _children) child?.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final child in _children) child?.removeListener(listener);
  }
}

mixin class ChangeNotifier implements Listenable {
  List<VoidCallback?> _listeners = [];
  int _notificationDepth = 0;
  bool _disposed = false;
  int _removed = 0;

  bool get hasListeners => _listeners.any((l) => l != null);

  void _checkNotDisposed() {
    if (_disposed) throw StateError('A $runtimeType was used after dispose.');
  }

  @override
  void addListener(VoidCallback listener) {
    _checkNotDisposed();
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    for (var i = 0; i < _listeners.length; i++) {
      if (_listeners[i] == listener) {
        if (_notificationDepth > 0) {
          _listeners[i] = null;
          _removed++;
        } else {
          _listeners.removeAt(i);
        }
        return;
      }
    }
  }

  void dispose() {
    _checkNotDisposed();
    _disposed = true;
    _listeners = [];
  }

  void notifyListeners() {
    _checkNotDisposed();
    final end = _listeners.length;
    _notificationDepth++;
    try {
      for (var i = 0; i < end; i++) {
        final listener = i < _listeners.length ? _listeners[i] : null;
        listener?.call();
      }
    } finally {
      _notificationDepth--;
      if (_notificationDepth == 0 && _removed > 0) {
        _listeners = _listeners.whereType<VoidCallback>().toList();
        _removed = 0;
      }
    }
  }
}

class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  ValueNotifier(this._value);
  T _value;
  @override
  T get value => _value;
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => 'ValueNotifier<$T>($value)';
}

/// Equality helpers commonly imported from foundation.
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool setEquals<T>(Set<T>? a, Set<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  return a.containsAll(b);
}

bool mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

String describeEnum(Enum value) => value.name;

/// A future whose value is available synchronously: [then] runs its callback
/// immediately, as in Flutter. Localization delegates rely on this to
/// build without an empty first frame.
class SynchronousFuture<T> implements Future<T> {
  SynchronousFuture(this._value);
  final T _value;

  @override
  Stream<T> asStream() => Stream<T>.value(_value);
  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      this;
  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    final result = onValue(_value);
    if (result is Future<R>) return result;
    return SynchronousFuture<R>(result);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      Future<T>.value(_value).timeout(timeLimit, onTimeout: onTimeout);
  @override
  Future<T> whenComplete(FutureOr<dynamic> Function() action) {
    try {
      final result = action();
      if (result is Future) return result.then((_) => _value);
      return this;
    } catch (error, stack) {
      return Future<T>.error(error, stack);
    }
  }
}

class FlutterError extends Error {
  FlutterError(this.message);
  factory FlutterError.fromParts(List<Object> parts) =>
      FlutterError(parts.join('\n'));
  final String message;
  @override
  String toString() => message;
  static void Function(FlutterErrorDetails details)? onError;
  static void reportError(FlutterErrorDetails details) =>
      onError?.call(details);
}

class FlutterErrorDetails {
  const FlutterErrorDetails({
    required this.exception,
    this.stack,
    this.library,
    this.context,
  });
  final Object exception;
  final StackTrace? stack;
  final String? library;
  final Object? context;
}

// ---------------------------------------------------------------------------
// Diagnostics. Properties are collected for `toString` output only; there is
// no inspector.

enum DiagnosticLevel {
  hidden,
  fine,
  debug,
  info,
  warning,
  hint,
  summary,
  error,
  off,
}

enum DiagnosticsTreeStyle {
  none,
  sparse,
  offstage,
  dense,
  transition,
  error,
  whitespace,
  flat,
  singleLine,
  errorProperty,
  shallow,
  truncateChildren,
}

class DiagnosticsNode {
  DiagnosticsNode({required this.name, this.value});
  final String? name;
  final Object? value;
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      name == null ? '$value' : '$name: $value';
}

class DiagnosticsProperty<T> extends DiagnosticsNode {
  DiagnosticsProperty(
    String? name,
    T? value, {
    String? description,
    String? ifNull,
    bool showName = true,
    Object? defaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
  }) : super(name: name, value: value);
}

class StringProperty extends DiagnosticsProperty<String> {
  StringProperty(
    super.name,
    super.value, {
    super.description,
    super.ifNull,
    bool quoted = true,
    super.showName,
    super.defaultValue,
    super.level,
  });
}

class IntProperty extends DiagnosticsProperty<int> {
  IntProperty(
    super.name,
    super.value, {
    super.ifNull,
    super.showName,
    String? unit,
    super.defaultValue,
    super.level,
  });
}

class DoubleProperty extends DiagnosticsProperty<double> {
  DoubleProperty(
    super.name,
    super.value, {
    super.ifNull,
    String? unit,
    String? tooltip,
    super.defaultValue,
    super.showName,
    super.level,
  });
}

class FlagProperty extends DiagnosticsProperty<bool> {
  FlagProperty(
    String name, {
    required bool? value,
    String? ifTrue,
    String? ifFalse,
    bool showName = false,
    Object? defaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : super(name, value, showName: showName, defaultValue: defaultValue);
}

class EnumProperty<T> extends DiagnosticsProperty<T> {
  EnumProperty(super.name, super.value, {super.defaultValue, super.level});
}

class IterableProperty<T> extends DiagnosticsProperty<Iterable<T>> {
  IterableProperty(
    super.name,
    super.value, {
    super.defaultValue,
    super.ifNull,
    String? ifEmpty = '[]',
    super.style,
    super.showName,
    super.level,
  });
}

class ObjectFlagProperty<T> extends DiagnosticsProperty<T> {
  ObjectFlagProperty(
    String super.name,
    super.value, {
    String? ifPresent,
    super.ifNull,
    super.showName = false,
    super.level,
  });
  ObjectFlagProperty.has(
    String name,
    T? value, {
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : super(name, value, level: level);
}

class DiagnosticPropertiesBuilder {
  DiagnosticPropertiesBuilder();
  final List<DiagnosticsNode> properties = [];
  DiagnosticsTreeStyle defaultDiagnosticsTreeStyle =
      DiagnosticsTreeStyle.sparse;
  String? emptyBodyDescription;
  void add(DiagnosticsNode property) => properties.add(property);
}

mixin Diagnosticable {
  String toStringShort() => '$runtimeType';

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  DiagnosticsNode toDiagnosticsNode({
    String? name,
    DiagnosticsTreeStyle? style,
  }) => DiagnosticsNode(name: name, value: toStringShort());

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final builder = DiagnosticPropertiesBuilder();
    debugFillProperties(builder);
    if (builder.properties.isEmpty) return toStringShort();
    return '${toStringShort()}(${builder.properties.join(', ')})';
  }
}

mixin DiagnosticableTreeMixin implements Diagnosticable {
  @override
  String toStringShort() => '$runtimeType';
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
  @override
  DiagnosticsNode toDiagnosticsNode({
    String? name,
    DiagnosticsTreeStyle? style,
  }) => DiagnosticsNode(name: name, value: toStringShort());
  List<DiagnosticsNode> debugDescribeChildren() => const [];
  String toStringDeep({
    String prefixLineOne = '',
    String? prefixOtherLines,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) => toString();
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final builder = DiagnosticPropertiesBuilder();
    debugFillProperties(builder);
    if (builder.properties.isEmpty) return toStringShort();
    return '${toStringShort()}(${builder.properties.join(', ')})';
  }
}

abstract class DiagnosticableTree with Diagnosticable {
  const DiagnosticableTree();
  List<DiagnosticsNode> debugDescribeChildren() => const [];
}

String describeIdentity(Object? object) =>
    '${object.runtimeType}#${shortHash(object)}';

String shortHash(Object? object) =>
    object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
