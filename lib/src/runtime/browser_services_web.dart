import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

JSObject? _navigator() =>
    globalContext.getProperty<JSObject?>('navigator'.toJS);

JSObject? _clipboard() =>
    _navigator()?.getProperty<JSObject?>('clipboard'.toJS);

/// Writes through the async Clipboard API (needs a user gesture and a
/// secure context, as in Flutter web).
Future<bool> browserClipboardWrite(String text) async {
  final clipboard = _clipboard();
  if (clipboard == null || !clipboard.has('writeText')) return false;
  try {
    await clipboard
        .callMethod<JSPromise<JSAny?>>('writeText'.toJS, text.toJS)
        .toDart;
    return true;
  } catch (_) {
    return false;
  }
}

Future<String?> browserClipboardRead() async {
  final clipboard = _clipboard();
  if (clipboard == null || !clipboard.has('readText')) return null;
  try {
    final value = await clipboard
        .callMethod<JSPromise<JSString>>('readText'.toJS)
        .toDart;
    return value.toDart;
  } catch (_) {
    return null;
  }
}

bool browserVibrate(int milliseconds) {
  final navigator = _navigator();
  if (navigator == null || !navigator.has('vibrate')) return false;
  try {
    navigator.callMethod<JSAny?>('vibrate'.toJS, milliseconds.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

void browserSetTitle(String title) {
  final document = globalContext.getProperty<JSObject?>('document'.toJS);
  document?.setProperty('title'.toJS, title.toJS);
}

void browserHistoryBack() {
  final history = globalContext.getProperty<JSObject?>('history'.toJS);
  if (history != null && history.has('back')) {
    history.callMethod<JSAny?>('back'.toJS);
  }
}

/// Fetches [url] relative to the page; null when the request fails.
Future<List<int>?> browserFetchBytes(String url) async {
  if (!globalContext.has('fetch')) return null;
  try {
    final response = await globalContext
        .callMethod<JSPromise<JSObject>>('fetch'.toJS, url.toJS)
        .toDart;
    if (response.getProperty<JSBoolean?>('ok'.toJS)?.toDart != true) {
      return null;
    }
    final buffer = await response
        .callMethod<JSPromise<JSArrayBuffer>>('arrayBuffer'.toJS)
        .toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Registers [bytes] as a font face named [family] (CSS Font Loading API).
Future<void> browserLoadFont(String family, List<int> bytes) async {
  final document = globalContext.getProperty<JSObject?>('document'.toJS);
  final fonts = document?.getProperty<JSObject?>('fonts'.toJS);
  if (fonts == null || !globalContext.has('FontFace')) return;
  final buffer = Uint8List.fromList(bytes).buffer.toJS;
  final face = globalContext
      .getProperty<JSFunction>('FontFace'.toJS)
      .callAsConstructor<JSObject>(family.toJS, buffer);
  await face.callMethod<JSPromise<JSAny?>>('load'.toJS).toDart;
  fonts.callMethod<JSAny?>('add'.toJS, face);
}
