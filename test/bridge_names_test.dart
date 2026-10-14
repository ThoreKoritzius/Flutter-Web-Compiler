import 'dart:io';

import 'package:flutter_dom_compiler/src/runtime/bridge_names.dart';
import 'package:test/test.dart';

Set<String> _declared(String path) {
  final source = File(path).readAsStringSync();
  return {
    for (final match in RegExp(
      r'^(?:abstract |sealed |final |base |interface )*(?:class|enum|typedef|mixin|extension) ([A-Z]\w*)',
      multiLine: true,
    ).allMatches(source))
      match.group(1)!,
    for (final match in RegExp(
      r'^[A-Za-z][\w<>?, ]*? ([a-z]\w*)\(',
      multiLine: true,
    ).allMatches(source))
      if (!match.group(1)!.startsWith('_')) match.group(1)!,
    for (final match in RegExp(
      r'^const ([a-zA-Z]\w*) =',
      multiLine: true,
    ).allMatches(source))
      if (!match.group(1)!.startsWith('_')) match.group(1)!,
  };
}

void main() {
  test('bridge name lists match public declarations', () {
    expect(
      flChartBridgeNames.toSet(),
      _declared('lib/src/runtime/dom_fl_chart.dart'),
    );
    expect(
      goRouterBridgeNames.toSet(),
      _declared('lib/src/runtime/dom_go_router.dart'),
    );
    expect(
      flutterLocalizationsBridgeNames.toSet(),
      _declared('lib/src/runtime/dom_flutter_localizations.dart'),
    );
  });
}
