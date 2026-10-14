/// Browser user-agent classification used by `defaultTargetPlatform`,
/// following Flutter web's rules in a reduced form.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

String browserPlatformName() {
  final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
  if (navigator == null) return 'android';
  String read(String name) =>
      navigator.getProperty<JSAny?>(name.toJS).dartify()?.toString() ?? '';
  final agent = read('userAgent').toLowerCase();
  final platform = read('platform').toLowerCase();
  if (agent.contains('iphone') ||
      agent.contains('ipad') ||
      agent.contains('ipod')) {
    return 'ios';
  }
  if (platform.startsWith('mac')) {
    // iPadOS reports a Mac platform with touch support.
    final points = navigator.getProperty<JSAny?>('maxTouchPoints'.toJS);
    final count = points.dartify();
    return count is num && count > 2 ? 'ios' : 'macos';
  }
  if (agent.contains('android')) return 'android';
  if (platform.startsWith('win')) return 'windows';
  if (platform.contains('linux') || agent.contains('linux')) return 'linux';
  return 'android';
}
