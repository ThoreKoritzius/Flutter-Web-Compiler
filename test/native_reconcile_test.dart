import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'keys move state, inherited notifiers rebuild dependents and async builders resolve',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-keys-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'dart:async';
import 'package:flutter/material.dart';

final counter = ValueNotifier<int>(0);
final stream = StreamController<String>();
void main() => runApp(MaterialApp(home: const Root()));

class Counter extends InheritedNotifier<ValueNotifier<int>> {
  const Counter({super.key, required super.notifier, required super.child});
  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Counter>()!.notifier!.value;
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => RootState();
}

class RootState extends State<Root> {
  List<String> items = ['a', 'b', 'c'];
  final itemKey = GlobalKey<ItemState>();
  late final Future<String> future = Future.delayed(
    const Duration(milliseconds: 10),
    () => 'future done',
  );
  int builds = 0;
  @override
  Widget build(BuildContext context) {
    builds++;
    return Counter(
      notifier: counter,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => setState(() => items = items.reversed.toList()),
            child: const Text('Reverse'),
          ),
          ElevatedButton(
            onPressed: () => setState(() => items = [...items.skip(1)]),
            child: const Text('Drop first'),
          ),
          ElevatedButton(
            onPressed: () => counter.value++,
            child: const Text('Notify'),
          ),
          ElevatedButton(
            onPressed: () => print('global:${itemKey.currentState?.taps}'),
            child: const Text('Read global'),
          ),
          Text('root builds $builds'),
          const ShowCounter(),
          ValueListenableBuilder<int>(
            valueListenable: counter,
            builder: (context, value, child) => Text('listenable $value'),
          ),
          FutureBuilder<String>(
            future: future,
            builder: (context, snapshot) =>
                Text(snapshot.hasData ? snapshot.data! : 'future waiting'),
          ),
          StreamBuilder<String>(
            stream: stream.stream,
            initialData: 'stream initial',
            builder: (context, snapshot) => Text(snapshot.data ?? 'none'),
          ),
          for (final item in items)
            Item(
              key: item == 'b' ? itemKey : ValueKey(item),
              name: item,
            ),
        ],
      ),
    );
  }
}

class ShowCounter extends StatelessWidget {
  const ShowCounter({super.key});
  @override
  Widget build(BuildContext context) => Text('inherited ${Counter.of(context)}');
}

class Item extends StatefulWidget {
  const Item({super.key, required this.name});
  final String name;
  @override
  State<Item> createState() => ItemState();
}

class ItemState extends State<Item> {
  int taps = 0;
  @override
  void dispose() {
    print('dispose ${widget.name} $taps');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () => setState(() => taps++),
    child: Text('${widget.name}:$taps'),
  );
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/native_reconcile_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Keyed reconciliation passed'));
    },
  );
}
