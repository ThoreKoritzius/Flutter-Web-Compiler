import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:flutter_dom_compiler/src/font_subset.dart';
import 'package:test/test.dart';

// A synthetic 5-glyph CFF font generated for these tests (no third-party
// outlines): square U+E001, triangle U+E002, bar U+F0003, wide U+E004.
final _font = base64Decode(
  'T1RUTwAJAIAAAwAQQ0ZGIOkMkMEAAAJwAAAAqE9TLzIg+FfrAAABAAAAAGBjbWFw4EphDQAAAdgAAAB4aGVhZDCEOAIAAACcAAAANmhoZWEGpgOKAAAA1AAAACRobXR4DUgAAAAAAxgAAAAUbWF4cAAFUAAAAAD4AAAABm5hbWVtqpBsAAABYAAAAHVwb3N0AAMAAAAAAlAAAAAgAAEAAAABAACt8xMwXw889QADA+gAAAAA5vT6MwAAAADm9PozAAAAAAOEArwAAAADAAIAAAAAAAAAAQAAAyD/OAAAA+gAAABkA4QAAQAAAAAAAAAAAAAAAAAAAAUAAFAAAAUAAAADAqgBkAAFAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAASAAAABAAAAAAAAAA/Pz8/AADgAf//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAQANgABAAAAAAABAA4AAAABAAAAAAACAAcADgADAAEECQABABwAFQADAAEECQACAA4AMVN5bnRoZXRpY0ljb25zUmVndWxhcgBTAHkAbgB0AGgAZQB0AGkAYwBJAGMAbwBuAHMAUgBlAGcAdQBsAGEAcgAAAAAAAAMAAAADAAAAHAADAAEAAAAcAAMACgAAAEQABAAoAAAABgAEAAEAAuAC4AT//wAA4AHgBP//IAAgAAABAAAAAAAAAAwAAAAAADQAAAAAAAAAAwAA4AEAAOACAAAAAQAA4AQAAOAEAAAABAAPAAMADwADAAAAAwADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAEAQABAQEPU3ludGhldGljSWNvbnMAAQEBE/geAouL+hj5UAXjD4v3PBLsEQAEAQEHDxMhc3F1YXJldHJpYW5nbGV3aWRlU3ludGhldGljSWNvbnMAAAABhwGIAF0BiQAFAQENGigzP/jsixb4iPlQ/IgGDvjs7+8V+CT4JPwkBg747O/vFfgkBvtc+CQFDvjs7+8V7/iIJwYO+Oz3XAT6GO/+GAYOAlgAAAJYAAACWAAAAlgAAAPoAAA=',
);

int _u16(Uint8List b, int o) => (b[o] << 8) | b[o + 1];
int _u32(Uint8List b, int o) =>
    (b[o] << 24 | b[o + 1] << 16 | b[o + 2] << 8 | b[o + 3]) & 0xffffffff;

Map<String, (int, int)> _tables(Uint8List font) => {
  for (var i = 0; i < _u16(font, 4); i++)
    String.fromCharCodes(font.sublist(12 + i * 16, 16 + i * 16)): (
      _u32(font, 20 + i * 16),
      _u32(font, 24 + i * 16),
    ),
};

int _checksum(Uint8List bytes, int offset, int length) {
  var sum = 0;
  for (var i = 0; i < length; i += 4) {
    var word = 0;
    for (var k = 0; k < 4; k++) {
      word = (word << 8) | (i + k < length ? bytes[offset + i + k] : 0);
    }
    sum = (sum + word) & 0xffffffff;
  }
  return sum;
}

void main() {
  test('keeps requested glyphs and notdef, renumbered in order', () {
    final subset = subsetCffFont(_font, [0xf0003, 0xe001, 0x41]);
    expect(readFontCmap(subset), {0xe001: 1, 0xf0003: 2});
    final tables = _tables(subset);
    expect(tables.keys, containsAll(['CFF ', 'cmap', 'head', 'hmtx', 'maxp']));
    final maxp = tables['maxp']!.$1;
    expect(_u16(subset, maxp + 4), 3, reason: 'numGlyphs');
    final hhea = tables['hhea']!.$1;
    expect(_u16(subset, hhea + 34), 3, reason: 'numberOfHMetrics');
    expect(subset.length, lessThan(_font.length));
  });

  test('preserves advance widths and writes valid checksums', () {
    final subset = subsetCffFont(_font, [0xe004]);
    final tables = _tables(subset);
    final hmtx = tables['hmtx']!.$1;
    expect(_u16(subset, hmtx + 4), 1000, reason: 'wide glyph advance');
    for (var i = 0; i < _u16(subset, 4); i++) {
      final tag = String.fromCharCodes(
        subset.sublist(12 + i * 16, 16 + i * 16),
      );
      if (tag == 'head') continue;
      final (offset, length) = tables[tag]!;
      expect(_checksum(subset, offset, length), _u32(subset, 16 + i * 16));
    }
    expect(_checksum(subset, 0, subset.length), 0xb1b0afba);
  });

  test('ignores unmapped code points and rejects non-CFF fonts', () {
    expect(readFontCmap(subsetCffFont(_font, [0x41])), isEmpty);
    final trueType = Uint8List.fromList(_font)..setAll(0, [0, 1, 0, 0]);
    expect(
      () => subsetCffFont(trueType, [0xe001]),
      throwsA(isA<FontSubsetException>()),
    );
  });

  test('icon usage comes from sources and the matching JS constructor', () {
    const names = {'home': 0xe318, 'close': 0xe16a, 'star': 0xe5f9};
    const js =
        'B.a=new A.Q(58136,!1);B.b=new A.Q(59897,!1);B.c=new A.Dur(1000,0)';
    final codes = materialIconCodePoints(js, ['Icon(Icons.home)'], names);
    // The constructor used for Icons.home also built 59897 (from a package).
    expect(codes, containsAll({0xe318, 59897, 0xe16a}));
    expect(codes, isNot(contains(1000)));
    expect(materialIconCodePoints(js, ['no icons'], names), isNull);
    expect(
      materialIconCodePoints(';new A.Q(x,!1)', ['Icons.home'], names),
      isNull,
      reason: 'computed code points require the full font',
    );
  });
}
