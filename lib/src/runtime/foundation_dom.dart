/// Bounded foundation APIs for the official Dart web runtime target.
library;

export 'dart:typed_data';

import 'dart:async';

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
