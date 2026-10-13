import 'dart:io';
import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'scoped themes and card layout survive root updates in compiled JavaScript',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-style-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
void main() => runApp(const MaterialApp(theme: ThemeData(colorScheme: ColorScheme(onSurface: Color(0xff123456), surfaceContainerLow: Color(0xff20242c))), home: Panel()));
class Panel extends StatefulWidget {
 const Panel();
 @override State<Panel> createState() => PanelState();
}
class PanelState extends State<Panel> {
 int count=0;
 @override void initState() { super.initState(); print('init:${Theme.of(context).colorScheme.onSurface.red}'); }
 @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
  Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xff123456).withValues(alpha: .5))), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text('Ready $count', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))), ElevatedButton(onPressed: () => setState(() => count++), child: const Text('Update'))]))),
  const Theme(data: ThemeData(colorScheme: ColorScheme(onSurface: Color(0xffabcdef))), child: Label()),
  const Text('Sibling'),
  ElevatedButton(onPressed: () {
   try { runApp(const Expanded(child: Text('Invalid'))); } on UnsupportedError { print('invalid flex rejected'); }
   try { runApp(const Padding(padding: EdgeInsets.all(-1), child: Text('Invalid'))); } on ArgumentError { print('invalid padding rejected'); }
   try { runApp(const Icon(Icons.favorite_rounded)); } on UnsupportedError { print('icon painting rejected'); }
   runApp(const Text('Done'));
  }, child: const Text('Check errors')),
 ]);
}
class Label extends StatelessWidget {
 const Label();
 @override Widget build(BuildContext context) => Text('Scoped', style: TextStyle(color: Theme.of(context).colorScheme.onSurface));
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/native_style_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(
        run.stdout,
        contains(
          'Scoped theme, card layout, updates and rejection checks passed',
        ),
      );
    },
  );
}
