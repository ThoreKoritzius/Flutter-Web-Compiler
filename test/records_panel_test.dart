import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'records panel fixture keeps state, updates inputs and stays accessible',
    () async {
      final source = File(
        'examples/records_panel/lib/expandable_records_panel.dart',
      ).readAsStringSync();
      final app = await buildNativeApp(
        'examples/records_panel',
        'lib/main.dart',
      );
      expect(app.libraries, 4);
      final directory = Directory.systemTemp.createTempSync('records-panel-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/records_panel_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Records panel:'));
      expect(
        File(
          'examples/records_panel/lib/expandable_records_panel.dart',
        ).readAsStringSync(),
        source,
      );
    },
  );
}
