import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'tabs, navigation bars, drawers, expansion tiles and seed colors',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-material-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
void main() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xff6750a4));
  print('seed ${scheme.primary.value.toRadixString(16)} ${scheme.surfaceContainerHighest.value.toRadixString(16)}');
  runApp(MaterialApp(theme: ThemeData(colorSchemeSeed: Colors.teal), home: const Shell()));
}
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => ShellState();
}
class ShellState extends State<Shell> {
  int page = 0;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(title: const Text('Shell'), bottom: const TabBar(tabs: [Tab(text: 'One'), Tab(text: 'Two')])),
      drawer: Drawer(child: ListTile(title: const Text('Menu item'), onTap: () => print('menu'))),
      body: Column(children: [
        Text('page $page'),
        const SizedBox(height: 200, child: TabBarView(children: [Text('first tab'), Text('second tab')])),
        const ExpansionTile(title: Text('More'), children: [Text('hidden detail')]),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    ),
  );
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/native_material_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Material structure passed'));
    },
  );
}
