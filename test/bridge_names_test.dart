import 'dart:io';

import 'package:flutter_dom_compiler/src/runtime/bridge_names.dart';
import 'package:test/test.dart';

void main() {
  test('fl_chart bridge names match public declarations', () {
    final source = File('lib/src/runtime/dom_fl_chart.dart').readAsStringSync();
    final declared = <String>{
      for (final match in RegExp(
        r'^(?:abstract |sealed |final )*(?:class|enum|typedef|mixin) ([A-Z]\w*)',
        multiLine: true,
      ).allMatches(source))
        match.group(1)!,
      for (final match in RegExp(
        r'^[A-Za-z][\w<>?, ]*? ([a-z]\w*)\(',
        multiLine: true,
      ).allMatches(source))
        if (!match.group(1)!.startsWith('_')) match.group(1)!,
    };
    expect(flChartBridgeNames.toSet(), declared);
  });
}
