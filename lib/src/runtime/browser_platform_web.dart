import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The browser's user agent and platform, for target-platform detection.
String? browserUserAgent() {
  final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
  if (navigator == null) return null;
  final agent = navigator.getProperty<JSAny?>('userAgent'.toJS);
  final platform = navigator.getProperty<JSAny?>('platform'.toJS);
  return [
    if (agent.isA<JSString>()) (agent as JSString).toDart,
    if (platform.isA<JSString>()) (platform as JSString).toDart,
  ].join(' ');
}
