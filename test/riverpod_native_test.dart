import 'dart:io';
import 'dart:convert';
import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  for (final version in [null, '3.0.0']) {
    test('consumer import rejects incompatible engine $version', () async {
      final directory = Directory.systemTemp.createTempSync(
        'consumer-version-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      Directory('${directory.path}/.dart_tool').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(
        "import 'package:flutter_riverpod/flutter_riverpod.dart'; void main() {} ",
      );
      final packages = <Map<String, dynamic>>[];
      if (version != null) {
        final root = Directory('${directory.path}/engine')..createSync();
        File(
          '${root.path}/pubspec.yaml',
        ).writeAsStringSync('name: riverpod\nversion: $version\n');
        packages.add({
          'name': 'riverpod',
          'rootUri': root.uri.toString(),
          'packageUri': 'lib/',
          'languageVersion': '3.0',
        });
      }
      File(
        '${directory.path}/.dart_tool/package_config.json',
      ).writeAsStringSync(
        jsonEncode({'configVersion': 2, 'packages': packages}),
      );
      await expectLater(
        buildNativeApp(directory.path, 'lib/main.dart'),
        throwsUnsupportedError,
      );
    });
  }

  test(
    'official providers drive root native consumers and release subscriptions',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-consumer-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final count = StateProvider<int>((ref) => 0);
final doubled = Provider<int>((ref) => ref.watch(count) * 2);
final result = FutureProvider<int>((ref) async {
  ref.onDispose(() => print('async provider disposed'));
  return Future.delayed(const Duration(milliseconds: 20), () => 42);
});
void main() => runApp(ProviderScope(overrides: [count.overrideWith((ref) => 4)], child: const MaterialApp(home: Counter())));
class Counter extends ConsumerStatefulWidget {
  const Counter();
  @override ConsumerState<Counter> createState() => CounterState();
}
class CounterState extends ConsumerState<Counter> {
  bool watching = true;
  @override void initState() {
    super.initState();
    print('initial:${ref.read(count)}');
    try { ref.watch(count); } on StateError { print('watch outside build rejected'); }
  }
  @override Widget build(BuildContext context) {
    print('consumer build');
    final value = watching ? ref.watch(doubled) : ref.read(doubled);
    final async = ref.watch(result);
    return Column(children: [
      Text('Count: $value'),
      Text(async.when(data: (value) => 'Result: $value', loading: () => 'Pending', error: (e,s) => 'Error')),
      ElevatedButton(onPressed: () => ref.read(count.notifier).state++, child: const Text('Increment')),
      ElevatedButton(onPressed: () => setState(() => watching = false), child: const Text('Stop watching')),
      ElevatedButton(onPressed: () {
        runApp(const Text('Unmounted'));
        try { ref.read(count); } on StateError { print('disposed ref rejected'); }
      }, child: const Text('Unmount')),
    ]);
  }
}
''');
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      expect(app.riverpodConsumers, isTrue);
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        'tool/browser/riverpod_native_test.cjs',
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(
        run.stdout,
        contains('providers, async, overrides and disposal passed'),
      );
    },
  );
}
