/// Glyph subsetting for CFF-flavoured OpenType icon fonts.
///
/// Keeps `.notdef` plus the glyphs mapped from the requested code points,
/// rebuilds `CFF `, `cmap`, `hmtx`, `hhea`, `maxp` and `post`, copies `head`,
/// `OS/2` and `name`, and drops layout tables such as `GSUB` (icon ligatures
/// are not used when rendering by code point). Fonts with CID-keyed CFF or
/// TrueType outlines are rejected; callers then ship the original font.
library;

import 'dart:typed_data';

class FontSubsetException implements Exception {
  FontSubsetException(this.message);
  final String message;
  @override
  String toString() => 'FontSubsetException: $message';
}

Never _fail(String message) => throw FontSubsetException(message);

class _Reader {
  _Reader(this.bytes) : data = ByteData.sublistView(bytes);
  final Uint8List bytes;
  final ByteData data;
  void _check(int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > bytes.length)
      _fail('Truncated font data.');
  }

  int u8(int o) {
    _check(o, 1);
    return bytes[o];
  }

  int u16(int o) {
    _check(o, 2);
    return data.getUint16(o);
  }

  int i16(int o) {
    _check(o, 2);
    return data.getInt16(o);
  }

  int u32(int o) {
    _check(o, 4);
    return data.getUint32(o);
  }

  int offset(int o, int size) {
    _check(o, size);
    var value = 0;
    for (var i = 0; i < size; i++) {
      value = (value << 8) | bytes[o + i];
    }
    return value;
  }

  Uint8List slice(int o, int length) {
    _check(o, length);
    return Uint8List.sublistView(bytes, o, o + length);
  }
}

class _Builder {
  final _out = BytesBuilder(copy: false);
  int get length => _out.length;
  void u8(int v) => _out.addByte(v & 0xff);
  void u16(int v) {
    u8(v >> 8);
    u8(v);
  }

  void i16(int v) => u16(v & 0xffff);
  void u32(int v) {
    u16(v >> 16);
    u16(v);
  }

  void bytes(List<int> b) => _out.add(b);
  void pad4() {
    while (_out.length % 4 != 0) {
      u8(0);
    }
  }

  Uint8List take() => _out.takeBytes();
}

/// Parsed CFF INDEX: item byte ranges relative to the CFF table.
class _Index {
  _Index(this.items, this.end);
  final List<(int, int)> items;
  final int end;
}

_Index _readIndex(_Reader cff, int pos) {
  final count = cff.u16(pos);
  if (count == 0) return _Index(const [], pos + 2);
  final offSize = cff.u8(pos + 2);
  if (offSize < 1 || offSize > 4) _fail('Invalid CFF INDEX offset size.');
  final offsets = [
    for (var i = 0; i <= count; i++) cff.offset(pos + 3 + i * offSize, offSize),
  ];
  final dataStart = pos + 3 + (count + 1) * offSize - 1;
  final items = <(int, int)>[];
  for (var i = 0; i < count; i++) {
    if (offsets[i + 1] < offsets[i]) _fail('Invalid CFF INDEX offsets.');
    items.add((dataStart + offsets[i], offsets[i + 1] - offsets[i]));
  }
  return _Index(items, dataStart + offsets.last);
}

void _writeIndex(_Builder out, List<Uint8List> items) {
  out.u16(items.length);
  if (items.isEmpty) return;
  final total = items.fold<int>(0, (sum, item) => sum + item.length) + 1;
  final offSize = total < 0x100
      ? 1
      : total < 0x10000
      ? 2
      : total < 0x1000000
      ? 3
      : 4;
  out.u8(offSize);
  void writeOffset(int value) {
    for (var i = offSize - 1; i >= 0; i--) {
      out.u8(value >> (8 * i));
    }
  }

  var offset = 1;
  writeOffset(offset);
  for (final item in items) {
    offset += item.length;
    writeOffset(offset);
  }
  for (final item in items) {
    out.bytes(item);
  }
}

int _indexSize(List<Uint8List> items) {
  final out = _Builder();
  _writeIndex(out, items);
  return out.length;
}

/// A Top DICT entry: operator plus raw operand bytes and decoded integers.
class _DictEntry {
  _DictEntry(this.op, this.raw, this.ints);
  final int op;
  final Uint8List raw;
  final List<int?> ints;
}

List<_DictEntry> _readDict(_Reader cff, int start, int length) {
  final entries = <_DictEntry>[];
  var i = start;
  var operandStart = start;
  final ints = <int?>[];
  final end = start + length;
  while (i < end) {
    final b = cff.u8(i);
    if (b <= 21) {
      var op = b;
      final rawEnd = i;
      i++;
      if (b == 12) {
        op = 1200 + cff.u8(i);
        i++;
      }
      entries.add(
        _DictEntry(op, cff.slice(operandStart, rawEnd - operandStart), [
          ...ints,
        ]),
      );
      ints.clear();
      operandStart = i;
    } else if (b == 28) {
      ints.add(cff.i16(i + 1));
      i += 3;
    } else if (b == 29) {
      ints.add(cff.data.getInt32(i + 1));
      i += 5;
    } else if (b == 30) {
      i++;
      while (true) {
        final nibbles = cff.u8(i++);
        if ((nibbles & 0xf) == 0xf || (nibbles >> 4) == 0xf) break;
      }
      ints.add(null);
    } else if (b >= 32 && b <= 246) {
      ints.add(b - 139);
      i++;
    } else if (b >= 247 && b <= 250) {
      ints.add((b - 247) * 256 + cff.u8(i + 1) + 108);
      i += 2;
    } else if (b >= 251 && b <= 254) {
      ints.add(-(b - 251) * 256 - cff.u8(i + 1) - 108);
      i += 2;
    } else {
      _fail('Invalid CFF DICT data.');
    }
  }
  return entries;
}

List<int> _int32Operand(int value) => [
  29,
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];

/// Code point to glyph mapping from a format 4 or 12 cmap subtable.
Map<int, int> _readCmap(_Reader font, int cmap) {
  final count = font.u16(cmap + 2);
  int? best;
  var bestFormat = 0;
  for (var i = 0; i < count; i++) {
    final record = cmap + 4 + i * 8;
    final platform = font.u16(record);
    final encoding = font.u16(record + 2);
    final sub = cmap + font.u32(record + 4);
    final format = font.u16(sub);
    final unicode =
        platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10));
    if (!unicode) continue;
    if (format == 12 && bestFormat != 12) {
      best = sub;
      bestFormat = 12;
    } else if (format == 4 && bestFormat == 0) {
      best = sub;
      bestFormat = 4;
    }
  }
  if (best == null) _fail('No Unicode cmap subtable.');
  final map = <int, int>{};
  if (bestFormat == 12) {
    final groups = font.u32(best + 12);
    for (var g = 0; g < groups; g++) {
      final p = best + 16 + g * 12;
      final start = font.u32(p), end = font.u32(p + 4), glyph = font.u32(p + 8);
      if (end < start || end - start > 0x110000) _fail('Invalid cmap group.');
      for (var c = start; c <= end; c++) {
        map[c] = glyph + c - start;
      }
    }
  } else {
    final segments = font.u16(best + 6) ~/ 2;
    final ends = best + 14, starts = ends + segments * 2 + 2;
    final deltas = starts + segments * 2, ranges = deltas + segments * 2;
    for (var s = 0; s < segments; s++) {
      final end = font.u16(ends + s * 2), start = font.u16(starts + s * 2);
      final delta = font.i16(deltas + s * 2);
      final rangeOffset = font.u16(ranges + s * 2);
      for (var c = start; c <= end && c != 0xffff; c++) {
        int glyph;
        if (rangeOffset == 0) {
          glyph = (c + delta) & 0xffff;
        } else {
          final address = ranges + s * 2 + rangeOffset + (c - start) * 2;
          glyph = font.u16(address);
          if (glyph != 0) glyph = (glyph + delta) & 0xffff;
        }
        if (glyph != 0) map[c] = glyph;
      }
    }
  }
  return map;
}

Uint8List _buildCmap(Map<int, int> mapping) {
  final codes = mapping.keys.toList()..sort();
  final bmp = codes.where((c) => c <= 0xfffe).toList();
  // Format 4: one segment per BMP code point plus the terminator.
  final f4 = _Builder();
  final segCount = bmp.length + 1;
  var searchRange = 1, entrySelector = 0;
  while (searchRange * 2 <= segCount) {
    searchRange *= 2;
    entrySelector++;
  }
  searchRange *= 2;
  f4
    ..u16(4)
    ..u16(16 + segCount * 8)
    ..u16(0)
    ..u16(segCount * 2)
    ..u16(searchRange)
    ..u16(entrySelector)
    ..u16(segCount * 2 - searchRange);
  for (final c in bmp) {
    f4.u16(c);
  }
  f4
    ..u16(0xffff)
    ..u16(0);
  for (final c in bmp) {
    f4.u16(c);
  }
  f4.u16(0xffff);
  for (final c in bmp) {
    f4.i16((mapping[c]! - c) & 0xffff);
  }
  f4.u16(1);
  for (var i = 0; i < segCount; i++) {
    f4.u16(0);
  }
  final format4 = f4.take();
  // Format 12: one group per contiguous run.
  final groups = <(int, int, int)>[];
  for (final c in codes) {
    final glyph = mapping[c]!;
    if (groups.isNotEmpty &&
        groups.last.$2 + 1 == c &&
        groups.last.$3 + (c - groups.last.$1) == glyph) {
      final last = groups.removeLast();
      groups.add((last.$1, c, last.$3));
    } else {
      groups.add((c, c, glyph));
    }
  }
  final f12 = _Builder()
    ..u16(12)
    ..u16(0)
    ..u32(16 + groups.length * 12)
    ..u32(0)
    ..u32(groups.length);
  for (final group in groups) {
    f12
      ..u32(group.$1)
      ..u32(group.$2)
      ..u32(group.$3);
  }
  final format12 = f12.take();
  final out = _Builder()
    ..u16(0)
    ..u16(2)
    ..u16(3)
    ..u16(1)
    ..u32(4 + 16)
    ..u16(3)
    ..u16(10)
    ..u32(4 + 16 + format4.length)
    ..bytes(format4)
    ..bytes(format12);
  return out.take();
}

int _checksum(Uint8List table) {
  final padded = Uint8List((table.length + 3) & ~3)..setAll(0, table);
  final data = ByteData.sublistView(padded);
  var sum = 0;
  for (var i = 0; i < padded.length; i += 4) {
    sum = (sum + data.getUint32(i)) & 0xffffffff;
  }
  return sum;
}

/// Returns a subset font containing glyphs for [codePoints] (missing code
/// points are ignored) plus `.notdef`.
Uint8List subsetCffFont(Uint8List input, Iterable<int> codePoints) {
  final font = _Reader(input);
  if (font.u32(0) != 0x4f54544f) _fail('Only CFF (OTTO) fonts are supported.');
  final numTables = font.u16(4);
  final tables = <String, (int, int)>{};
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    final tag = String.fromCharCodes(font.slice(record, 4));
    tables[tag] = (font.u32(record + 8), font.u32(record + 12));
  }
  for (final required in ['CFF ', 'cmap', 'head', 'hhea', 'hmtx', 'maxp']) {
    if (!tables.containsKey(required)) _fail('Missing $required table.');
  }
  final (cffStart, cffLength) = tables['CFF ']!;
  final cff = _Reader(font.slice(cffStart, cffLength));

  // Glyph selection.
  final cmap = _readCmap(font, tables['cmap']!.$1);
  final mapping = <int, int>{};
  for (final code in codePoints) {
    final glyph = cmap[code];
    if (glyph != null) mapping[code] = glyph;
  }
  final oldGlyphs = <int>{0, ...mapping.values}.toList()..sort();
  final newGlyphOf = {
    for (var i = 0; i < oldGlyphs.length; i++) oldGlyphs[i]: i,
  };

  // CFF structure.
  final headerSize = cff.u8(2);
  final names = _readIndex(cff, headerSize);
  final topDicts = _readIndex(cff, names.end);
  if (topDicts.items.length != 1) _fail('Font sets are not supported.');
  final strings = _readIndex(cff, topDicts.end);
  final globalSubrs = _readIndex(cff, strings.end);
  final (topStart, topLength) = topDicts.items.single;
  final top = _readDict(cff, topStart, topLength);
  int? operand(int op) {
    for (final entry in top) {
      if (entry.op == op) return entry.ints.isEmpty ? null : entry.ints.last;
    }
    return null;
  }

  if (top.any((e) => e.op == 1230)) _fail('CID-keyed CFF is not supported.');
  final charStringsOffset = operand(17) ?? _fail('Missing CharStrings.');
  final charStrings = _readIndex(cff, charStringsOffset);
  final glyphCount = charStrings.items.length;
  if (oldGlyphs.last >= glyphCount) _fail('cmap references a missing glyph.');
  final privateEntry = top.where((e) => e.op == 18).firstOrNull;
  if (privateEntry != null &&
      (privateEntry.ints.length != 2 || privateEntry.ints.contains(null)))
    _fail('Invalid Private DICT operands.');
  final privateSize = privateEntry?.ints.first ?? 0;
  final privateOffset = privateEntry?.ints.last ?? 0;
  var privateBlockEnd = privateOffset + privateSize;
  if (privateSize > 0) {
    final private = _readDict(cff, privateOffset, privateSize);
    final subrs = private.where((e) => e.op == 19).firstOrNull?.ints.last;
    if (subrs != null) {
      final local = _readIndex(cff, privateOffset + subrs);
      if (local.end > privateBlockEnd) privateBlockEnd = local.end;
    }
  }

  // Original charset: glyph id → SID.
  final charsetOffset = operand(15) ?? 0;
  final sids = List<int>.generate(glyphCount, (gid) => gid);
  if (charsetOffset > 2) {
    final format = cff.u8(charsetOffset);
    var p = charsetOffset + 1;
    var gid = 1;
    if (format == 0) {
      for (; gid < glyphCount; gid++, p += 2) {
        sids[gid] = cff.u16(p);
      }
    } else if (format == 1 || format == 2) {
      while (gid < glyphCount) {
        final first = cff.u16(p);
        final left = format == 1 ? cff.u8(p + 2) : cff.u16(p + 2);
        p += format == 1 ? 3 : 4;
        for (var k = 0; k <= left && gid < glyphCount; k++) {
          sids[gid++] = first + k;
        }
      }
    } else {
      _fail('Unknown charset format.');
    }
  } else if (charsetOffset != 0) {
    _fail('Predefined expert charsets are not supported.');
  }

  // Keep only custom strings that kept glyphs or the Top DICT reference.
  const standardStrings = 391;
  const sidOperators = {0, 1, 2, 3, 4, 1200, 1221, 1222};
  final usedSids = <int>{
    for (final gid in oldGlyphs.skip(1))
      if (sids[gid] >= standardStrings) sids[gid],
    for (final entry in top)
      if (sidOperators.contains(entry.op))
        for (final value in entry.ints)
          if (value != null && value >= standardStrings) value,
  }.toList()..sort();
  for (final sid in usedSids) {
    if (sid - standardStrings >= strings.items.length)
      _fail('String index out of range.');
  }
  final newSid = {
    for (var i = 0; i < usedSids.length; i++) usedSids[i]: standardStrings + i,
  };
  int remap(int sid) => sid < standardStrings ? sid : newSid[sid]!;

  // New CFF layout with fixed-width offset operands in the Top DICT.
  final topBuilder = _Builder();
  void addOffsets(int charset, int glyphs, int privateAt) {
    for (final entry in top) {
      if (entry.op == 15) {
        topBuilder.bytes(_int32Operand(charset));
      } else if (entry.op == 17) {
        topBuilder.bytes(_int32Operand(glyphs));
      } else if (entry.op == 18) {
        topBuilder
          ..bytes(_int32Operand(privateSize))
          ..bytes(_int32Operand(privateAt));
      } else if (sidOperators.contains(entry.op) &&
          entry.ints.isNotEmpty &&
          entry.ints.every((value) => value != null)) {
        for (final value in entry.ints) {
          topBuilder.bytes(_int32Operand(remap(value!)));
        }
      } else if (entry.op == 16) {
        // Encodings are irrelevant for cmap-based rendering; use standard.
        topBuilder.bytes(_int32Operand(0));
      } else {
        topBuilder.bytes(entry.raw);
      }
      if (entry.op >= 1200) {
        topBuilder
          ..u8(12)
          ..u8(entry.op - 1200);
      } else {
        topBuilder.u8(entry.op);
      }
    }
    if (!top.any((e) => e.op == 15) && charsetOffset == 0) {
      topBuilder
        ..bytes(_int32Operand(charset))
        ..u8(15);
    }
  }

  final newCharStrings = [
    for (final gid in oldGlyphs)
      cff.slice(charStrings.items[gid].$1, charStrings.items[gid].$2),
  ];
  final charset = _Builder()..u8(0);
  for (final gid in oldGlyphs.skip(1)) {
    charset.u16(remap(sids[gid]));
  }
  final charsetBytes = charset.take();
  final headerBytes = cff.slice(0, headerSize);
  final nameBytes = cff.slice(headerSize, names.end - headerSize);
  final stringOut = _Builder();
  _writeIndex(stringOut, [
    for (final sid in usedSids)
      cff.slice(
        strings.items[sid - standardStrings].$1,
        strings.items[sid - standardStrings].$2,
      ),
  ]);
  final stringBytes = stringOut.take();
  final gsubrBytes = cff.slice(strings.end, globalSubrs.end - strings.end);

  addOffsets(0, 0, 0);
  final topSize = _indexSize([topBuilder.take()]);
  final charsetAt =
      headerBytes.length +
      nameBytes.length +
      topSize +
      stringBytes.length +
      gsubrBytes.length;
  final charStringsAt = charsetAt + charsetBytes.length;
  final privateAt = charStringsAt + _indexSize(newCharStrings);
  addOffsets(charsetAt, charStringsAt, privateAt);
  final newCff = _Builder()
    ..bytes(headerBytes)
    ..bytes(nameBytes);
  _writeIndex(newCff, [topBuilder.take()]);
  newCff
    ..bytes(stringBytes)
    ..bytes(gsubrBytes)
    ..bytes(charsetBytes);
  _writeIndex(newCff, newCharStrings);
  if (privateBlockEnd > privateOffset) {
    newCff.bytes(cff.slice(privateOffset, privateBlockEnd - privateOffset));
  }

  // Metrics.
  final (hheaStart, hheaLength) = tables['hhea']!;
  final oldMetrics = font.u16(hheaStart + 34);
  final hmtxStart = tables['hmtx']!.$1;
  (int, int) metric(int gid) {
    if (gid < oldMetrics) {
      return (font.u16(hmtxStart + gid * 4), font.i16(hmtxStart + gid * 4 + 2));
    }
    final advance = font.u16(hmtxStart + (oldMetrics - 1) * 4);
    final lsb = font.i16(hmtxStart + oldMetrics * 4 + (gid - oldMetrics) * 2);
    return (advance, lsb);
  }

  final hmtx = _Builder();
  for (final gid in oldGlyphs) {
    final (advance, lsb) = metric(gid);
    hmtx
      ..u16(advance)
      ..i16(lsb);
  }
  final hhea = Uint8List.fromList(font.slice(hheaStart, hheaLength));
  ByteData.sublistView(hhea).setUint16(34, oldGlyphs.length);
  final (maxpStart, maxpLength) = tables['maxp']!;
  final maxp = Uint8List.fromList(font.slice(maxpStart, maxpLength));
  ByteData.sublistView(maxp).setUint16(4, oldGlyphs.length);
  final post = _Builder()..u32(0x00030000);
  if (tables.containsKey('post')) {
    post.bytes(font.slice(tables['post']!.$1 + 4, 28));
  } else {
    post.bytes(Uint8List(28));
  }
  final head = Uint8List.fromList(
    font.slice(tables['head']!.$1, tables['head']!.$2),
  );
  ByteData.sublistView(head).setUint32(8, 0);

  final output = <String, Uint8List>{
    'CFF ': newCff.take(),
    'cmap': _buildCmap({
      for (final entry in mapping.entries) entry.key: newGlyphOf[entry.value]!,
    }),
    'head': head,
    'hhea': hhea,
    'hmtx': hmtx.take(),
    'maxp': maxp,
    'post': post.take(),
    for (final tag in ['OS/2', 'name'])
      if (tables.containsKey(tag))
        tag: font.slice(tables[tag]!.$1, tables[tag]!.$2),
  };

  // sfnt container.
  final tags = output.keys.toList()..sort();
  var searchRange = 1, entrySelector = 0;
  while (searchRange * 2 <= tags.length) {
    searchRange *= 2;
    entrySelector++;
  }
  searchRange *= 16;
  final file = _Builder()
    ..u32(0x4f54544f)
    ..u16(tags.length)
    ..u16(searchRange)
    ..u16(entrySelector)
    ..u16(tags.length * 16 - searchRange);
  var offset = 12 + tags.length * 16;
  final offsets = <String, int>{};
  for (final tag in tags) {
    offsets[tag] = offset;
    offset += (output[tag]!.length + 3) & ~3;
  }
  for (final tag in tags) {
    file
      ..bytes(tag.codeUnits)
      ..u32(_checksum(output[tag]!))
      ..u32(offsets[tag]!)
      ..u32(output[tag]!.length);
  }
  for (final tag in tags) {
    file
      ..bytes(output[tag]!)
      ..pad4();
  }
  final bytes = file.take();
  final adjustment = (0xb1b0afba - _checksum(bytes)) & 0xffffffff;
  ByteData.sublistView(bytes).setUint32(offsets['head']! + 8, adjustment);
  return bytes;
}

/// Code point to glyph id, for verification of subset output.
Map<int, int> readFontCmap(Uint8List input) {
  final font = _Reader(input);
  final numTables = font.u16(4);
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    if (String.fromCharCodes(font.slice(record, 4)) == 'cmap')
      return _readCmap(font, font.u32(record + 8));
  }
  _fail('Missing cmap table.');
}
