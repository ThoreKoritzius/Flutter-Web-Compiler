import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('navigator routes, browser history, dialogs and snack bars', () async {
    final directory = Directory.systemTemp.createTempSync('native-nav-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  routes: {
    '/': (context) => const Home(),
    '/details': (context) => const Details(),
  },
));

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  int count = 0;
  String result = '-';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: Column(children: [
      Text('home count $count result $result'),
      ElevatedButton(onPressed: () => setState(() => count++), child: const Text('Increment')),
      ElevatedButton(
        onPressed: () async {
          final value = await Navigator.pushNamed<String>(context, '/details', arguments: 'from home');
          setState(() => result = value ?? 'none');
        },
        child: const Text('Open details'),
      ),
      ElevatedButton(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Proceed?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
              ],
            ),
          );
          setState(() => result = 'dialog $ok');
        },
        child: const Text('Ask'),
      ),
      ElevatedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Saved'), action: SnackBarAction(label: 'Undo', onPressed: () => print('undo'))),
        ),
        child: const Text('Notify'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Guarded())),
        child: const Text('Open guarded'),
      ),
    ]),
  );
}

class Details extends StatelessWidget {
  const Details({super.key});
  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Column(children: [
        Text('details $argument'),
        ElevatedButton(onPressed: () => Navigator.pop(context, 'picked'), child: const Text('Pick')),
      ]),
    );
  }
}

class Guarded extends StatefulWidget {
  const Guarded({super.key});
  @override
  State<Guarded> createState() => GuardedState();
}

class GuardedState extends State<Guarded> {
  bool allow = false;
  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: allow,
    onPopInvokedWithResult: (didPop, result) => print('pop invoked $didPop'),
    child: Scaffold(
      appBar: AppBar(title: const Text('Guarded')),
      body: ElevatedButton(onPressed: () => setState(() => allow = true), child: const Text('Allow')),
    ),
  );
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      'tool/browser/native_navigation_test.cjs',
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Navigation passed'));
  });
}
