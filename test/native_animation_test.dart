import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('controllers, implicit animations and post-frame callbacks', () async {
    final directory = Directory.systemTemp.createTempSync('native-anim-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  print('curve ${Curves.easeInOut.transform(0.5).toStringAsFixed(2)} ${Curves.easeIn.transform(0.25).toStringAsFixed(3)}');
  print('tween ${ColorTween(begin: const Color(0xff000000), end: const Color(0xffffffff)).transform(0.5)} ${Tween<double>(begin: 10, end: 20).chain(CurveTween(curve: Curves.linear)).transform(0.25)}');
  runApp(const MaterialApp(home: Demo()));
}

class Demo extends StatefulWidget {
  const Demo({super.key});
  @override
  State<Demo> createState() => DemoState();
}

class DemoState extends State<Demo> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  bool wide = false, alternate = false, shown = true;
  @override
  void initState() {
    super.initState();
    controller.addStatusListener((status) => print('status ${status.name}'));
    WidgetsBinding.instance.addPostFrameCallback((_) => print('post frame ${context.mounted}'));
  }
  @override
  void dispose() {
    controller.dispose();
    print('demo disposed');
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    ElevatedButton(onPressed: () => controller.forward(), child: const Text('Forward')),
    ElevatedButton(onPressed: () => controller.repeat(reverse: true), child: const Text('Repeat')),
    ElevatedButton(onPressed: () => controller.stop(), child: const Text('Stop')),
    ElevatedButton(onPressed: () => setState(() => wide = !wide), child: const Text('Resize')),
    ElevatedButton(onPressed: () => setState(() => alternate = !alternate), child: const Text('Switch')),
    ElevatedButton(onPressed: () => runApp(const Text('Replaced')), child: const Text('Replace')),
    FadeTransition(opacity: controller, child: const Text('Fading')),
    AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: wide ? 200 : 100,
      height: 20,
      color: wide ? const Color(0xffff0000) : const Color(0xff0000ff),
      onEnd: () => print('container end'),
      child: const Text('Box'),
    ),
    AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(alternate ? 'Second' : 'First', key: ValueKey(alternate)),
    ),
    TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, _) => Text('tween ${value == 1 ? 'done' : 'running'}'),
    ),
    Transform.rotate(angle: 0, child: const Text('Rotated')),
  ]);
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      'tool/browser/native_animation_test.cjs',
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Animations passed'));
  });
}
