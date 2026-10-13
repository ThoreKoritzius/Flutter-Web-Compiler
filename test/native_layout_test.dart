import 'dart:io';
import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'compiled layout measures attached containers and rebuilds on viewport resize',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-layout-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
void main() => runApp(const LayoutBuilder(builder: buildGrid));
Widget buildGrid(BuildContext context, BoxConstraints constraints) => Wrap(spacing: 10, runSpacing: 12, children: [
 SizedBox(width: (constraints.maxWidth - 10) / 2, child: Text('Measured ${constraints.maxWidth} / ${MediaQuery.sizeOf(context).width}')),
 ElevatedButton(onPressed: () => runApp(const Text('Disposed')), child: const Text('Replace')),
]);
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/native_layout_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    },
  );
}
