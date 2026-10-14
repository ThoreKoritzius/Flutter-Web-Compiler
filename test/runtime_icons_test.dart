import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('every icon the runtime draws stays in subset fonts', () {
    final used = <String>{};
    for (final file in Directory('lib/src/runtime').listSync()) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('icons_metadata.dart')) continue;
      for (final match in RegExp(
        r'\bIcons\.((?:adaptive\.)?[a-z]\w*)',
      ).allMatches(file.readAsStringSync())) {
        used.add(match.group(1)!);
      }
    }
    expect(used.difference(nativeRuntimeIcons.toSet()), isEmpty);
  });
}
