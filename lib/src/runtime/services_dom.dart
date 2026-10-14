/// Explicit in-process Dart adapters, not Flutter binary platform channels.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'ui_enums.dart';
import 'browser_services.dart'
    if (dart.library.js_interop) 'browser_services_web.dart';

import 'visual_metadata.dart' show Color;

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

// ---------------------------------------------------------------------------
// Text editing values and formatters (pure Dart, as in Flutter's services).

class TextRange {
  const TextRange({required this.start, required this.end});
  const TextRange.collapsed(int offset) : start = offset, end = offset;
  static const empty = TextRange(start: -1, end: -1);
  final int start, end;
  bool get isValid => start >= 0 && end >= 0;
  bool get isCollapsed => start == end;
  @override
  bool operator ==(Object other) =>
      other is TextRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

class TextSelection extends TextRange {
  const TextSelection({required this.baseOffset, required this.extentOffset})
    : super(
        start: baseOffset < extentOffset ? baseOffset : extentOffset,
        end: baseOffset < extentOffset ? extentOffset : baseOffset,
      );
  const TextSelection.collapsed({required int offset})
    : baseOffset = offset,
      extentOffset = offset,
      super.collapsed(offset);
  final int baseOffset, extentOffset;
  @override
  bool operator ==(Object other) =>
      other is TextSelection &&
      other.baseOffset == baseOffset &&
      other.extentOffset == extentOffset;
  @override
  int get hashCode => Object.hash(baseOffset, extentOffset);
}

class TextEditingValue {
  const TextEditingValue({
    this.text = '',
    this.selection = const TextSelection.collapsed(offset: -1),
    this.composing = TextRange.empty,
  });
  static const empty = TextEditingValue();
  final String text;
  final TextSelection selection;
  final TextRange composing;
  TextEditingValue copyWith({
    String? text,
    TextSelection? selection,
    TextRange? composing,
  }) => TextEditingValue(
    text: text ?? this.text,
    selection: selection ?? this.selection,
    composing: composing ?? this.composing,
  );
  @override
  bool operator ==(Object other) =>
      other is TextEditingValue &&
      other.text == text &&
      other.selection == selection &&
      other.composing == composing;
  @override
  int get hashCode => Object.hash(text, selection, composing);
}

abstract class TextInputFormatter {
  const TextInputFormatter();
  factory TextInputFormatter.withFunction(
    TextEditingValue Function(
      TextEditingValue oldValue,
      TextEditingValue newValue,
    )
    formatFunction,
  ) = _FunctionTextInputFormatter;
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  );
}

class _FunctionTextInputFormatter extends TextInputFormatter {
  _FunctionTextInputFormatter(this._format);
  final TextEditingValue Function(TextEditingValue, TextEditingValue) _format;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _format(oldValue, newValue);
}

/// Filters by pattern. Selection is placed at the end of the result, a
/// simplification of Flutter's per-region selection mapping.
class FilteringTextInputFormatter extends TextInputFormatter {
  FilteringTextInputFormatter(
    this.filterPattern, {
    required this.allow,
    this.replacementString = '',
  });
  FilteringTextInputFormatter.allow(
    this.filterPattern, {
    this.replacementString = '',
  }) : allow = true;
  FilteringTextInputFormatter.deny(
    this.filterPattern, {
    this.replacementString = '',
  }) : allow = false;
  static final digitsOnly = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
  static final singleLineFormatter = FilteringTextInputFormatter.deny('\n');
  final Pattern filterPattern;
  final bool allow;
  final String replacementString;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final out = StringBuffer();
    var index = 0;
    for (final match in filterPattern.allMatches(text)) {
      if (allow) {
        if (match.start > index) out.write(replacementString);
        out.write(match.group(0));
      } else {
        out.write(text.substring(index, match.start));
        out.write(replacementString);
      }
      index = match.end;
    }
    if (allow) {
      if (index < text.length) out.write(replacementString);
    } else {
      out.write(text.substring(index));
    }
    final result = out.toString();
    if (result == text) return newValue;
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class LengthLimitingTextInputFormatter extends TextInputFormatter {
  LengthLimitingTextInputFormatter(this.maxLength);
  final int? maxLength;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final limit = maxLength;
    if (limit == null || limit < 0 || newValue.text.runes.length <= limit)
      return newValue;
    if (oldValue.text.runes.length == limit) return oldValue;
    final text = String.fromCharCodes(newValue.text.runes.take(limit));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class TextInputType {
  const TextInputType._(this._name, {this.signed, this.decimal});
  const TextInputType.numberWithOptions({
    bool signed = false,
    bool decimal = false,
  }) : this._('number', signed: signed, decimal: decimal);
  final String _name;
  final bool? signed, decimal;
  static const text = TextInputType._('text');
  static const multiline = TextInputType._('multiline');
  static const number = TextInputType._('number');
  static const phone = TextInputType._('phone');
  static const datetime = TextInputType._('datetime');
  static const emailAddress = TextInputType._('emailAddress');
  static const url = TextInputType._('url');
  static const visiblePassword = TextInputType._('visiblePassword');
  static const name = TextInputType._('name');
  static const streetAddress = TextInputType._('streetAddress');
  static const none = TextInputType._('none');

  /// The matching HTML `type` and `inputmode` attributes.
  (String type, String? inputMode) get htmlInput => switch (_name) {
    'number' => ('text', decimal == true ? 'decimal' : 'numeric'),
    'phone' => ('tel', null),
    'emailAddress' => ('email', null),
    'url' => ('url', null),
    'none' => ('text', 'none'),
    _ => ('text', null),
  };

  String? get autocomplete => switch (_name) {
    'emailAddress' => 'email',
    'phone' => 'tel',
    'name' => 'name',
    'streetAddress' => 'street-address',
    'url' => 'url',
    _ => null,
  };
}

enum TextInputAction {
  none,
  unspecified,
  done,
  go,
  search,
  send,
  next,
  previous,
  continueAction,
  join,
  route,
  emergencyCall,
  newline,
}

enum TextCapitalization { words, sentences, characters, none }

enum MaxLengthEnforcement { none, enforced, truncateAfterCompositionEnds }

// ---------------------------------------------------------------------------
// Clipboard, haptics and system chrome.

class ClipboardData {
  const ClipboardData({required String this.text});
  final String? text;
}

abstract final class Clipboard {
  static const kTextPlain = 'text/plain';

  /// Uses the browser's async Clipboard API; failures (no permission or
  /// insecure context) are ignored, as Flutter web does.
  static Future<void> setData(ClipboardData data) async {
    await browserClipboardWrite(data.text ?? '');
  }

  static Future<ClipboardData?> getData(String format) async {
    final text = await browserClipboardRead();
    return text == null ? null : ClipboardData(text: text);
  }

  static Future<bool> hasStrings() async =>
      (await browserClipboardRead())?.isNotEmpty ?? false;
}

/// Haptics map to `navigator.vibrate` where the browser supports it.
abstract final class HapticFeedback {
  static Future<void> vibrate() async => browserVibrate(50);
  static Future<void> lightImpact() async => browserVibrate(10);
  static Future<void> mediumImpact() async => browserVibrate(20);
  static Future<void> heavyImpact() async => browserVibrate(30);
  static Future<void> selectionClick() async => browserVibrate(5);
}

enum SystemSoundType { click, alert, tick }

abstract final class SystemSound {
  static Future<void> play(SystemSoundType type) async {}
}

enum DeviceOrientation {
  portraitUp,
  landscapeLeft,
  portraitDown,
  landscapeRight,
}

enum SystemUiMode { leanBack, immersive, immersiveSticky, edgeToEdge, manual }

enum SystemUiOverlay { top, bottom }

/// System chrome colors an app requests. Browsers have no status or
/// navigation bars to style, so the values are carried but not applied.
class SystemUiOverlayStyle {
  const SystemUiOverlayStyle({
    this.systemNavigationBarColor,
    this.systemNavigationBarDividerColor,
    this.systemNavigationBarIconBrightness,
    this.systemNavigationBarContrastEnforced,
    this.statusBarColor,
    this.statusBarBrightness,
    this.statusBarIconBrightness,
    this.systemStatusBarContrastEnforced,
  });
  final Color? systemNavigationBarColor, systemNavigationBarDividerColor;
  final Brightness? systemNavigationBarIconBrightness;
  final bool? systemNavigationBarContrastEnforced;
  final Color? statusBarColor;
  final Brightness? statusBarBrightness, statusBarIconBrightness;
  final bool? systemStatusBarContrastEnforced;

  /// Light icons, for dark backgrounds.
  static const light = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xff000000),
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  /// Dark icons, for light backgrounds.
  static const dark = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xff000000),
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  SystemUiOverlayStyle copyWith({
    Color? systemNavigationBarColor,
    Color? systemNavigationBarDividerColor,
    bool? systemNavigationBarContrastEnforced,
    Color? statusBarColor,
    Brightness? statusBarBrightness,
    Brightness? statusBarIconBrightness,
    bool? systemStatusBarContrastEnforced,
    Brightness? systemNavigationBarIconBrightness,
  }) => SystemUiOverlayStyle(
    systemNavigationBarColor:
        systemNavigationBarColor ?? this.systemNavigationBarColor,
    systemNavigationBarDividerColor:
        systemNavigationBarDividerColor ?? this.systemNavigationBarDividerColor,
    systemNavigationBarContrastEnforced:
        systemNavigationBarContrastEnforced ??
        this.systemNavigationBarContrastEnforced,
    statusBarColor: statusBarColor ?? this.statusBarColor,
    statusBarBrightness: statusBarBrightness ?? this.statusBarBrightness,
    statusBarIconBrightness:
        statusBarIconBrightness ?? this.statusBarIconBrightness,
    systemStatusBarContrastEnforced:
        systemStatusBarContrastEnforced ?? this.systemStatusBarContrastEnforced,
    systemNavigationBarIconBrightness:
        systemNavigationBarIconBrightness ??
        this.systemNavigationBarIconBrightness,
  );

  @override
  bool operator ==(Object other) =>
      other is SystemUiOverlayStyle &&
      other.systemNavigationBarColor == systemNavigationBarColor &&
      other.systemNavigationBarDividerColor ==
          systemNavigationBarDividerColor &&
      other.systemNavigationBarIconBrightness ==
          systemNavigationBarIconBrightness &&
      other.systemNavigationBarContrastEnforced ==
          systemNavigationBarContrastEnforced &&
      other.statusBarColor == statusBarColor &&
      other.statusBarBrightness == statusBarBrightness &&
      other.statusBarIconBrightness == statusBarIconBrightness &&
      other.systemStatusBarContrastEnforced == systemStatusBarContrastEnforced;

  @override
  int get hashCode => Object.hash(
    systemNavigationBarColor,
    systemNavigationBarDividerColor,
    systemNavigationBarIconBrightness,
    systemNavigationBarContrastEnforced,
    statusBarColor,
    statusBarBrightness,
    statusBarIconBrightness,
    systemStatusBarContrastEnforced,
  );
}

class ApplicationSwitcherDescription {
  const ApplicationSwitcherDescription({this.label, this.primaryColor});
  final String? label;
  final int? primaryColor;
}

/// Browsers have no system bars or orientation lock to control; these
/// calls complete without effect, except that the switcher description
/// sets the document title as Flutter web does.
abstract final class SystemChrome {
  static void setSystemUIOverlayStyle(SystemUiOverlayStyle style) {}
  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {}
  static Future<void> setEnabledSystemUIMode(
    SystemUiMode mode, {
    List<SystemUiOverlay>? overlays,
  }) async {}
  static Future<void> setEnabledSystemUIOverlays(
    List<SystemUiOverlay> overlays,
  ) async {}
  static Future<void> restoreSystemUIOverlays() async {}
  static Future<void> setSystemUIChangeCallback(
    Future<void> Function(bool systemOverlaysAreVisible)? callback,
  ) async {}
  static Future<void> setApplicationSwitcherDescription(
    ApplicationSwitcherDescription description,
  ) async {
    if (description.label != null) browserSetTitle(description.label!);
  }
}

abstract final class SystemNavigator {
  /// Goes back in browser history, the closest web equivalent of leaving.
  static Future<void> pop({bool? animated}) async => browserHistoryBack();
  static Future<void> routeInformationUpdated({
    String? location,
    Uri? uri,
    Object? state,
    bool replace = false,
  }) async {}
}

// ---------------------------------------------------------------------------
// Keyboard keys and events.

class LogicalKeyboardKey {
  const LogicalKeyboardKey(this.keyId);
  final int keyId;

  String get keyLabel => _labels[keyId] ?? String.fromCharCode(keyId);
  String? get debugName => keyLabel;

  /// The key for a DOM `KeyboardEvent.key` value.
  static LogicalKeyboardKey fromDomKey(String key) {
    for (final entry in _labels.entries) {
      if (entry.value == key) return LogicalKeyboardKey(entry.key);
    }
    final runes = key.toLowerCase().runes.toList();
    return LogicalKeyboardKey(runes.length == 1 ? runes.single : key.hashCode);
  }

  static const _plane = 0x00100000000;
  static const backspace = LogicalKeyboardKey(_plane + 0x08);
  static const tab = LogicalKeyboardKey(_plane + 0x09);
  static const enter = LogicalKeyboardKey(_plane + 0x0d);
  static const escape = LogicalKeyboardKey(_plane + 0x1b);
  static const delete = LogicalKeyboardKey(_plane + 0x7f);
  static const arrowDown = LogicalKeyboardKey(_plane + 0x301);
  static const arrowLeft = LogicalKeyboardKey(_plane + 0x302);
  static const arrowRight = LogicalKeyboardKey(_plane + 0x303);
  static const arrowUp = LogicalKeyboardKey(_plane + 0x304);
  static const end = LogicalKeyboardKey(_plane + 0x305);
  static const home = LogicalKeyboardKey(_plane + 0x306);
  static const pageDown = LogicalKeyboardKey(_plane + 0x307);
  static const pageUp = LogicalKeyboardKey(_plane + 0x308);
  static const f1 = LogicalKeyboardKey(_plane + 0x801);
  static const f5 = LogicalKeyboardKey(_plane + 0x805);
  static const controlLeft = LogicalKeyboardKey(0x00200000100);
  static const controlRight = LogicalKeyboardKey(0x00200000101);
  static const shiftLeft = LogicalKeyboardKey(0x00200000102);
  static const shiftRight = LogicalKeyboardKey(0x00200000103);
  static const altLeft = LogicalKeyboardKey(0x00200000104);
  static const altRight = LogicalKeyboardKey(0x00200000105);
  static const metaLeft = LogicalKeyboardKey(0x00200000106);
  static const metaRight = LogicalKeyboardKey(0x00200000107);
  static const control = LogicalKeyboardKey(0x001f0000100);
  static const shift = LogicalKeyboardKey(0x001f0000102);
  static const alt = LogicalKeyboardKey(0x001f0000104);
  static const meta = LogicalKeyboardKey(0x001f0000106);
  static const space = LogicalKeyboardKey(0x20);
  static const comma = LogicalKeyboardKey(0x2c);
  static const period = LogicalKeyboardKey(0x2e);
  static const slash = LogicalKeyboardKey(0x2f);
  static const digit0 = LogicalKeyboardKey(0x30);
  static const digit1 = LogicalKeyboardKey(0x31);
  static const digit2 = LogicalKeyboardKey(0x32);
  static const digit3 = LogicalKeyboardKey(0x33);
  static const digit4 = LogicalKeyboardKey(0x34);
  static const digit5 = LogicalKeyboardKey(0x35);
  static const digit6 = LogicalKeyboardKey(0x36);
  static const digit7 = LogicalKeyboardKey(0x37);
  static const digit8 = LogicalKeyboardKey(0x38);
  static const digit9 = LogicalKeyboardKey(0x39);
  static const keyA = LogicalKeyboardKey(0x61);
  static const keyB = LogicalKeyboardKey(0x62);
  static const keyC = LogicalKeyboardKey(0x63);
  static const keyD = LogicalKeyboardKey(0x64);
  static const keyE = LogicalKeyboardKey(0x65);
  static const keyF = LogicalKeyboardKey(0x66);
  static const keyG = LogicalKeyboardKey(0x67);
  static const keyH = LogicalKeyboardKey(0x68);
  static const keyI = LogicalKeyboardKey(0x69);
  static const keyJ = LogicalKeyboardKey(0x6a);
  static const keyK = LogicalKeyboardKey(0x6b);
  static const keyL = LogicalKeyboardKey(0x6c);
  static const keyM = LogicalKeyboardKey(0x6d);
  static const keyN = LogicalKeyboardKey(0x6e);
  static const keyO = LogicalKeyboardKey(0x6f);
  static const keyP = LogicalKeyboardKey(0x70);
  static const keyQ = LogicalKeyboardKey(0x71);
  static const keyR = LogicalKeyboardKey(0x72);
  static const keyS = LogicalKeyboardKey(0x73);
  static const keyT = LogicalKeyboardKey(0x74);
  static const keyU = LogicalKeyboardKey(0x75);
  static const keyV = LogicalKeyboardKey(0x76);
  static const keyW = LogicalKeyboardKey(0x77);
  static const keyX = LogicalKeyboardKey(0x78);
  static const keyY = LogicalKeyboardKey(0x79);
  static const keyZ = LogicalKeyboardKey(0x7a);

  static const _labels = {
    _plane + 0x08: 'Backspace',
    _plane + 0x09: 'Tab',
    _plane + 0x0d: 'Enter',
    _plane + 0x1b: 'Escape',
    _plane + 0x7f: 'Delete',
    _plane + 0x301: 'ArrowDown',
    _plane + 0x302: 'ArrowLeft',
    _plane + 0x303: 'ArrowRight',
    _plane + 0x304: 'ArrowUp',
    _plane + 0x305: 'End',
    _plane + 0x306: 'Home',
    _plane + 0x307: 'PageDown',
    _plane + 0x308: 'PageUp',
    _plane + 0x801: 'F1',
    _plane + 0x805: 'F5',
    0x001f0000100: 'Control',
    0x001f0000102: 'Shift',
    0x001f0000104: 'Alt',
    0x001f0000106: 'Meta',
    0x20: ' ',
  };

  /// Collapses left/right modifier variants, as Flutter's synonyms do.
  static const _synonyms = {
    0x00200000100: 0x001f0000100,
    0x00200000101: 0x001f0000100,
    0x00200000102: 0x001f0000102,
    0x00200000103: 0x001f0000102,
    0x00200000104: 0x001f0000104,
    0x00200000105: 0x001f0000104,
    0x00200000106: 0x001f0000106,
    0x00200000107: 0x001f0000106,
  };

  Set<LogicalKeyboardKey> get synonyms => {
    if (_synonyms[keyId] case final id?) LogicalKeyboardKey(id),
  };

  @override
  bool operator ==(Object other) =>
      other is LogicalKeyboardKey && other.keyId == keyId;
  @override
  int get hashCode => keyId.hashCode;
  @override
  String toString() => 'LogicalKeyboardKey($keyLabel)';
}

class PhysicalKeyboardKey {
  const PhysicalKeyboardKey(this.usbHidUsage);
  final int usbHidUsage;
  @override
  bool operator ==(Object other) =>
      other is PhysicalKeyboardKey && other.usbHidUsage == usbHidUsage;
  @override
  int get hashCode => usbHidUsage.hashCode;
}

enum KeyEventDeviceType { keyboard, directionalPad, gamepad, joystick, hdmi }

abstract class KeyEvent {
  const KeyEvent({
    required this.physicalKey,
    required this.logicalKey,
    this.character,
    required this.timeStamp,
    this.deviceType = KeyEventDeviceType.keyboard,
    this.synthesized = false,
  });
  final PhysicalKeyboardKey physicalKey;
  final LogicalKeyboardKey logicalKey;
  final String? character;
  final Duration timeStamp;
  final KeyEventDeviceType deviceType;
  final bool synthesized;
}

class KeyDownEvent extends KeyEvent {
  const KeyDownEvent({
    required super.physicalKey,
    required super.logicalKey,
    super.character,
    required super.timeStamp,
    super.deviceType,
    super.synthesized,
  });
}

class KeyUpEvent extends KeyEvent {
  const KeyUpEvent({
    required super.physicalKey,
    required super.logicalKey,
    required super.timeStamp,
    super.deviceType,
    super.synthesized,
  });
}

class KeyRepeatEvent extends KeyEvent {
  const KeyRepeatEvent({
    required super.physicalKey,
    required super.logicalKey,
    super.character,
    required super.timeStamp,
    super.deviceType,
  });
}

/// Modifier state from the most recent DOM keyboard event.
class HardwareKeyboard {
  HardwareKeyboard._();
  static final instance = HardwareKeyboard._();
  final Set<LogicalKeyboardKey> _pressed = {};
  bool isControlPressed = false,
      isShiftPressed = false,
      isAltPressed = false,
      isMetaPressed = false;
  Set<LogicalKeyboardKey> get logicalKeysPressed => Set.unmodifiable(_pressed);
  bool isLogicalKeyPressed(LogicalKeyboardKey key) => _pressed.contains(key);

  void _record(
    KeyEvent event, {
    required bool control,
    required bool shift,
    required bool alt,
    required bool meta,
  }) {
    isControlPressed = control;
    isShiftPressed = shift;
    isAltPressed = alt;
    isMetaPressed = meta;
    if (event is KeyUpEvent) {
      _pressed.remove(event.logicalKey);
    } else {
      _pressed.add(event.logicalKey);
    }
  }
}

/// Builds a [KeyEvent] from DOM keyboard event fields and records modifier
/// state. Runtime widgets call this for `keydown`/`keyup`.
KeyEvent domKeyEvent({
  required String type,
  required String key,
  required bool repeat,
  required double timeStamp,
  required bool control,
  required bool shift,
  required bool alt,
  required bool meta,
}) {
  final logical = LogicalKeyboardKey.fromDomKey(key);
  const physical = PhysicalKeyboardKey(0);
  final stamp = Duration(microseconds: (timeStamp * 1000).round());
  final character = key.runes.length == 1 ? key : null;
  final KeyEvent event = type == 'keyup'
      ? KeyUpEvent(physicalKey: physical, logicalKey: logical, timeStamp: stamp)
      : repeat
      ? KeyRepeatEvent(
          physicalKey: physical,
          logicalKey: logical,
          character: character,
          timeStamp: stamp,
        )
      : KeyDownEvent(
          physicalKey: physical,
          logicalKey: logical,
          character: character,
          timeStamp: stamp,
        );
  HardwareKeyboard.instance._record(
    event,
    control: control,
    shift: shift,
    alt: alt,
    meta: meta,
  );
  return event;
}

// ---------------------------------------------------------------------------
// Asset bundles. Flutter web serves bundled assets under `assets/<key>`;
// the runtime build copies pubspec assets to the same place.

abstract class AssetBundle {
  const AssetBundle();
  Future<ByteData> load(String key);

  Future<Uint8List> loadBuffer(String key) async =>
      (await load(key)).buffer.asUint8List();

  Future<String> loadString(String key, {bool cache = true}) async {
    final data = await load(key);
    return utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));

  void evict(String key) {}
  void clear() {}
}

class NetworkAssetBundle extends AssetBundle {
  NetworkAssetBundle(this.baseUrl);
  final Uri baseUrl;
  @override
  Future<ByteData> load(String key) async {
    final bytes = await browserFetchBytes(baseUrl.resolve(key).toString());
    if (bytes == null) throw FlutterAssetError('Unable to load asset: "$key".');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

class PlatformAssetBundle extends AssetBundle {
  PlatformAssetBundle();
  final _cache = <String, Future<String>>{};

  @override
  Future<ByteData> load(String key) async {
    final bytes = await browserFetchBytes('assets/${Uri.encodeFull(key)}');
    if (bytes == null) throw FlutterAssetError('Unable to load asset: "$key".');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) => cache
      ? _cache.putIfAbsent(key, () => super.loadString(key))
      : super.loadString(key);

  @override
  void evict(String key) => _cache.remove(key);
  @override
  void clear() => _cache.clear();
}

/// Thrown when an asset cannot be loaded, like Flutter's `FlutterError`.
class FlutterAssetError extends Error {
  FlutterAssetError(this.message);
  final String message;
  @override
  String toString() => message;
}

final AssetBundle rootBundle = PlatformAssetBundle();

/// Registers fonts at runtime, as `dart:ui`'s FontLoader does.
class FontLoader {
  FontLoader(this.family);
  final String family;
  final _fonts = <Future<ByteData>>[];
  void addFont(Future<ByteData> bytes) => _fonts.add(bytes);
  Future<void> load() async {
    for (final font in _fonts) {
      final data = await font;
      await browserLoadFont(
        family,
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
  }
}

/// Bundled asset keys, read from the build's `AssetManifest.json`.
class AssetManifest {
  AssetManifest._(this._assets);
  final Map<String, List<String>> _assets;

  static Future<AssetManifest> loadFromAssetBundle(AssetBundle bundle) async {
    try {
      final json = jsonDecode(await bundle.loadString('AssetManifest.json'));
      return AssetManifest._({
        for (final entry in (json as Map).entries)
          entry.key as String: [
            for (final variant in entry.value as List) '$variant',
          ],
      });
    } catch (_) {
      return AssetManifest._(const {});
    }
  }

  List<String> listAssets() => _assets.keys.toList();

  List<AssetMetadata>? getAssetVariants(String key) => _assets[key] == null
      ? null
      : [
          for (final variant in _assets[key]!)
            AssetMetadata(
              key: variant,
              targetDevicePixelRatio: null,
              main: variant == key,
            ),
        ];
}

class AssetMetadata {
  const AssetMetadata({
    required this.key,
    required this.targetDevicePixelRatio,
    required this.main,
  });
  final String key;
  final double? targetDevicePixelRatio;
  final bool main;
}
