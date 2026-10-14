import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('overlays, render boxes, semantics and restoration run natively', () async {
    final directory = Directory.systemTemp.createTempSync('native-framework-more-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  routes: {'/': (_) => const Lab(), '/next': (_) => const Text('next page'), '/other': (_) => const Text('other page')},
));

class Lab extends StatefulWidget {
  const Lab({super.key});
  @override
  State<Lab> createState() => _LabState();
}

class _LabState extends State<Lab> with RestorationMixin {
  final counter = RestorableInt(3);
  final boxKey = GlobalKey();
  OverlayEntry? entry;
  String log = '';
  @override
  String? get restorationId => 'lab';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) =>
      registerForRestoration(counter, 'counter');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('log $log count ${counter.value}'),
        Container(
          key: boxKey,
          width: 50,
          height: 20,
          transform: Matrix4.rotationZ(math.pi / 2),
          transformAlignment: Alignment.center,
          foregroundDecoration: const BoxDecoration(color: Color(0x80FF0000)),
          decoration: const BoxDecoration(
            gradient: SweepGradient(colors: [Colors.red, Colors.blue]),
            backgroundBlendMode: BlendMode.multiply,
          ),
        ),
        const DecoratedBox(decoration: ShapeDecoration(shape: StarBorder(), color: Colors.green), child: SizedBox(width: 4, height: 4)),
        MouseRegion(
          onEnter: (event) => setState(() => log += 'enter;'),
          onHover: (event) => setState(() => log += 'hover ${event.localPosition.dx.round()};'),
          child: const Text('hover zone'),
        ),
        Semantics(label: 'Profile', button: true, selected: true, onTap: () => setState(() => log += 'semantic tap;'), child: const Text('semantic')),
        TextButton(
          onPressed: () {
            final box = boxKey.currentContext!.findRenderObject() as RenderBox;
            final origin = box.localToGlobal(const Offset(5, 5));
            setState(() => log += 'box ${box.size.width.round()}x${box.size.height.round()} at ${origin.dx.round()},${origin.dy.round()};');
          },
          child: const Text('measure'),
        ),
        TextButton(
          onPressed: () {
            entry = OverlayEntry(builder: (context) => Positioned(top: 10, left: 10, child: Material(child: TextButton(onPressed: () { entry?.remove(); setState(() => log += 'closed;'); }, child: const Text('overlay card')))));
            Overlay.of(context).insert(entry!);
          },
          child: const Text('show overlay'),
        ),
        TextButton(onPressed: () => setState(() => counter.value++), child: const Text('increment')),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pushNamed('/next');
            await Future<void>.delayed(const Duration(milliseconds: 10));
            if (context.mounted) Navigator.popAndPushNamed(context, '/other');
          },
          child: const Text('navigate'),
        ),
      ],
    ),
  );
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      '-e',
      r"""
const {install,until,label,find,findAll,style,Element}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
(async()=>{require(process.argv[1]);
 const text=()=>label(host);
 const log=()=>text().split('log ')[1]?.split(' count')[0]??'';
 await until(()=>text().includes('count 3'),'rendered with restored default');
 const button=t=>find(host,n=>n.tag==='button'&&label(n)===t);
 const box=find(host,n=>style(n).includes('conic-gradient'));
 if(!style(box).includes('transform-origin:50% 50%')||!style(box).includes('matrix3d('))throw Error('transform '+style(box));
 if(!style(box).includes('background-blend-mode:multiply'))throw Error('blend');
 if(!box.children.some(c=>style(c).includes('position:absolute;inset:0')))throw Error('foreground decoration');
 if(!find(host,n=>style(n).includes('border-radius:50%')&&style(n).includes('background-color')))throw Error('star border');
 Element.rect=n=>n===box?{left:30,top:40,width:50,height:20}:{};
 button('measure').events.click({});
 await until(()=>log().includes('box 50x20 at 35,45;'),'render box: '+log());
 const zone=find(host,n=>n.events.mouseenter);
 zone.events.mouseenter({clientX:0,clientY:0,currentTarget:zone});
 Element.rect=n=>n===zone?{left:10,top:0}:{};
 zone.events.mousemove({clientX:17,clientY:0,currentTarget:zone});
 await until(()=>log().includes('enter;hover 7;'),'mouse: '+log());
 const semantic=find(host,n=>n.attributes['aria-label']==='Profile');
 if(semantic.attributes.role!=='button'||semantic.attributes['aria-selected']!=='true'||semantic.attributes.tabindex!=='0')throw Error('semantics '+JSON.stringify(semantic.attributes));
 semantic.events.click({});
 await until(()=>log().includes('semantic tap;'),'semantic tap');
 button('show overlay').events.click({});
 await until(()=>text().includes('overlay card'),'overlay');
 const layer=find(host,n=>style(n).includes('position:fixed;inset:0;z-index:30'));
 if(!layer||!label(layer).includes('overlay card'))throw Error('overlay layer');
 button('overlay card').events.click({});
 await until(()=>!text().includes('overlay card')&&log().includes('closed;'),'overlay removed');
 button('increment').events.click({});
 await until(()=>text().includes('count 4'),'restorable value');
 button('navigate').events.click({});
 await until(()=>text().includes('other page')&&!text().includes('next page'),'popAndPushNamed: '+text());
 console.log('Framework more passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Framework more passed'));
  });
}
