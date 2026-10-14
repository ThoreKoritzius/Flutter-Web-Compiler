/// shared_preferences on `window.localStorage`, using the official web
/// plugin's layout (JSON values; `flutter.` key prefix for the legacy API) so
/// values written by a Flutter web build on the same origin remain readable.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

extension type _Storage(JSObject _) implements JSObject {
  external int get length;
  external String? key(int index);
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

_Storage? get _storage {
  final global = globalContext;
  if (!global.has('localStorage')) return null;
  try {
    return _Storage(global.getProperty<JSObject>('localStorage'.toJS));
  } catch (_) {
    return null;
  }
}

Object? _decode(String? encoded) {
  if (encoded == null) return null;
  try {
    final value = jsonDecode(encoded);
    return value is List ? value.cast<String>() : value;
  } on FormatException {
    return null;
  }
}

Map<String, Object?> _read(String prefix, Set<String>? allowList) {
  final storage = _storage;
  final values = <String, Object?>{};
  if (storage == null) return values;
  for (var i = 0; i < storage.length; i++) {
    final key = storage.key(i);
    if (key == null || !key.startsWith(prefix)) continue;
    final name = key.substring(prefix.length);
    if (allowList != null && !allowList.contains(name)) continue;
    final value = _decode(storage.getItem(key));
    if (value != null) values[name] = value;
  }
  return values;
}

bool _write(String key, Object? value) {
  final storage = _storage;
  if (storage == null) return false;
  try {
    if (value == null) {
      storage.removeItem(key);
    } else {
      storage.setItem(key, jsonEncode(value));
    }
    return true;
  } catch (_) {
    // Quota exceeded or storage blocked.
    return false;
  }
}

Map<String, Object>? _mockValues;

class SharedPreferences {
  SharedPreferences._(this._cache);
  static String _prefix = 'flutter.';
  static Set<String>? _allowList;
  static Completer<SharedPreferences>? _instance;
  final Map<String, Object?> _cache;

  static void setPrefix(String prefix, {Set<String>? allowList}) {
    if (_instance != null)
      throw StateError('setPrefix cannot be called after getInstance.');
    _prefix = prefix;
    _allowList = allowList;
  }

  static Future<SharedPreferences> getInstance() async {
    final existing = _instance;
    if (existing != null) return existing.future;
    final completer = _instance = Completer<SharedPreferences>();
    final mock = _mockValues;
    completer.complete(
      SharedPreferences._(
        mock != null ? Map.of(mock) : _read(_prefix, _allowList),
      ),
    );
    return completer.future;
  }

  static void resetStatic() => _instance = null;

  static void setMockInitialValues(Map<String, Object> values) {
    _mockValues = {
      for (final entry in values.entries)
        entry.key.startsWith(_prefix)
                ? entry.key.substring(_prefix.length)
                : entry.key:
            entry.value,
    };
    _instance = null;
  }

  Set<String> getKeys() => Set.of(_cache.keys);
  Object? get(String key) => _cache[key];
  bool? getBool(String key) => _cache[key] as bool?;
  int? getInt(String key) => _cache[key] as int?;
  double? getDouble(String key) => (_cache[key] as num?)?.toDouble();
  String? getString(String key) => _cache[key] as String?;
  List<String>? getStringList(String key) =>
      (_cache[key] as List<Object?>?)?.cast<String>().toList();
  bool containsKey(String key) => _cache.containsKey(key);

  Future<bool> _set(String key, Object? value) {
    if (_allowList != null && !_allowList!.contains(key))
      throw ArgumentError('$key is not included in the allow list.');
    if (value == null) {
      _cache.remove(key);
    } else {
      _cache[key] = value is List<String> ? List.of(value) : value;
    }
    return Future.value(_mockValues != null || _write('$_prefix$key', value));
  }

  Future<bool> setBool(String key, bool value) => _set(key, value);
  Future<bool> setInt(String key, int value) => _set(key, value);
  Future<bool> setDouble(String key, double value) => _set(key, value);
  Future<bool> setString(String key, String value) => _set(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _set(key, value);
  Future<bool> remove(String key) => _set(key, null);

  Future<bool> clear() async {
    var ok = true;
    for (final key in _cache.keys.toList()) {
      ok = await remove(key) && ok;
    }
    return ok;
  }

  Future<bool> commit() async => true;

  Future<void> reload() async {
    if (_mockValues != null) return;
    _cache
      ..clear()
      ..addAll(_read(_prefix, _allowList));
  }
}

class SharedPreferencesOptions {
  const SharedPreferencesOptions();
}

/// Asynchronous API without a key prefix, matching the web plugin.
class SharedPreferencesAsync {
  SharedPreferencesAsync({
    SharedPreferencesOptions options = const SharedPreferencesOptions(),
  });

  Future<Set<String>> getKeys({Set<String>? allowList}) async =>
      _read('', allowList).keys.toSet();
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async =>
      _read('', allowList);
  Object? _get(String key) => _decode(_storage?.getItem(key));
  Future<bool?> getBool(String key) async => _get(key) as bool?;
  Future<int?> getInt(String key) async => _get(key) as int?;
  Future<double?> getDouble(String key) async =>
      (_get(key) as num?)?.toDouble();
  Future<String?> getString(String key) async => _get(key) as String?;
  Future<List<String>?> getStringList(String key) async =>
      (_get(key) as List<Object?>?)?.cast<String>().toList();
  Future<bool> containsKey(String key) async => _get(key) != null;
  Future<void> setBool(String key, bool value) async => _write(key, value);
  Future<void> setInt(String key, int value) async => _write(key, value);
  Future<void> setDouble(String key, double value) async => _write(key, value);
  Future<void> setString(String key, String value) async => _write(key, value);
  Future<void> setStringList(String key, List<String> value) async =>
      _write(key, value);
  Future<void> remove(String key) async => _write(key, null);
  Future<void> clear({Set<String>? allowList}) async {
    for (final key in _read('', allowList).keys) {
      _write(key, null);
    }
  }
}

class SharedPreferencesWithCacheOptions {
  const SharedPreferencesWithCacheOptions({this.allowList});
  final Set<String>? allowList;
}

class SharedPreferencesWithCache {
  SharedPreferencesWithCache._(this._options, this._cache);
  final SharedPreferencesWithCacheOptions _options;
  final Map<String, Object?> _cache;

  static Future<SharedPreferencesWithCache> create({
    SharedPreferencesOptions sharedPreferencesOptions =
        const SharedPreferencesOptions(),
    required SharedPreferencesWithCacheOptions cacheOptions,
  }) async => SharedPreferencesWithCache._(
    cacheOptions,
    _read('', cacheOptions.allowList),
  );

  void _check(String key) {
    final allowList = _options.allowList;
    if (allowList != null && !allowList.contains(key))
      throw ArgumentError('$key is not included in the allow list.');
  }

  Set<String> get keys => Set.of(_cache.keys);
  Object? get(String key) {
    _check(key);
    return _cache[key];
  }

  bool? getBool(String key) => get(key) as bool?;
  int? getInt(String key) => get(key) as int?;
  double? getDouble(String key) => (get(key) as num?)?.toDouble();
  String? getString(String key) => get(key) as String?;
  List<String>? getStringList(String key) =>
      (get(key) as List<Object?>?)?.cast<String>().toList();
  bool containsKey(String key) => _cache.containsKey(key);
  Future<void> _set(String key, Object? value) async {
    _check(key);
    if (value == null) {
      _cache.remove(key);
    } else {
      _cache[key] = value;
    }
    _write(key, value);
  }

  Future<void> setBool(String key, bool value) => _set(key, value);
  Future<void> setInt(String key, int value) => _set(key, value);
  Future<void> setDouble(String key, double value) => _set(key, value);
  Future<void> setString(String key, String value) => _set(key, value);
  Future<void> setStringList(String key, List<String> value) =>
      _set(key, value);
  Future<void> remove(String key) => _set(key, null);
  Future<void> clear() async {
    for (final key in _cache.keys.toList()) {
      await remove(key);
    }
  }

  Future<void> reloadCache() async {
    _cache
      ..clear()
      ..addAll(_read('', _options.allowList));
  }
}
