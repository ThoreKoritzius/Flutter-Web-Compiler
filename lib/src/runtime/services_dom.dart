/// Explicit in-process Dart adapters, not Flutter binary platform channels.
library;

import 'dart:async';

import 'visual_metadata.dart' show Brightness, Color;

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
