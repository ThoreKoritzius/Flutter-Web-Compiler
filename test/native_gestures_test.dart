import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'gesture detectors report tap details, long presses and drags',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-gestures-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: Board())));

class Board extends StatefulWidget {
  const Board({super.key});
  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  final events = <String>[];
  double slider = 0;
  Offset pan = Offset.zero;

  void log(String event) => setState(() => events.add(event));

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        key: const ValueKey('cells'),
        onTapDown: (d) => log('down ${d.localPosition.dx},${d.localPosition.dy} ${d.kind?.name}'),
        onTapUp: (d) => log('up ${(d.localPosition.dx ~/ 10)},${(d.localPosition.dy ~/ 10)}'),
        onTap: () => log('tap'),
        onTapCancel: () => log('cancel'),
        onLongPress: () => log('long'),
        child: const SizedBox(width: 100, height: 70),
      ),
      GestureDetector(
        key: const ValueKey('slider'),
        onHorizontalDragStart: (d) => log('hstart ${d.localPosition.dx}'),
        onHorizontalDragUpdate: (d) => setState(() => slider += d.primaryDelta!),
        onHorizontalDragEnd: (d) => log('hend $slider ${d.primaryVelocity}'),
        child: Text('slider $slider'),
      ),
      GestureDetector(
        key: const ValueKey('pad'),
        onPanUpdate: (d) => setState(() => pan += d.delta),
        onPanEnd: (_) => log('pan $pan'),
        onTap: () => log('pad tap'),
        child: Text('pad ${pan.dx},${pan.dy}'),
      ),
      InkWell(
        key: const ValueKey('ink'),
        onTap: () => log('ink tap'),
        onLongPress: () => log('ink long'),
        child: const Text('ink'),
      ),
      Text('events ${events.join('|')}'),
    ],
  );
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        '-e',
        r"""
const {install,until,label,find,pointer,Element}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{require(process.argv[1]);
 await until(()=>label(host).includes('events'),'app ran');
 const text=()=>label(host);
 const byLabel=s=>{let hit;const walk=n=>{if(n.events.pointerdown&&label(n).includes(s))hit=n;n.children.forEach(walk);};walk(host);return hit;};
 const expect=(a,b)=>{if(JSON.stringify(a)!==JSON.stringify(b))throw Error(JSON.stringify(a)+' != '+JSON.stringify(b));};
 const events=()=>text().split('events ')[1];
 const cells=find(host,n=>n.events.pointerdown&&n.events.click&&label(n)==='');
 Element.rect=n=>n===cells?{left:200,top:100,width:100,height:70}:{};
 pointer(cells,'pointerdown',{x:234,y:157,kind:'mouse'});
 pointer(cells,'pointerup',{x:234,y:157,kind:'mouse'});
 cells.events.click({currentTarget:cells});
 await until(()=>events()==='down 34,57 mouse|up 3,5|tap','tap details: '+events());
 pointer(cells,'pointerdown',{x:210,y:110});
 await sleep(650);
 pointer(cells,'pointerup',{x:210,y:110});
 cells.events.click({currentTarget:cells});
 await until(()=>events().endsWith('down 10,10 touch|cancel|long'),'long press: '+events());
 pointer(cells,'pointerdown',{x:210,y:110});
 pointer(cells,'pointermove',{x:260,y:110});
 pointer(cells,'pointerup',{x:260,y:110});
 cells.events.click({currentTarget:cells});
 await until(()=>events().endsWith('long|down 10,10 touch|cancel'),'slop cancels: '+events());
 const slider=byLabel('slider');
 pointer(slider,'pointerdown',{x:10,y:5,time:0});
 if(!slider.attributes.style.includes('touch-action:pan-y'))throw Error('touch action');
 pointer(slider,'pointermove',{x:40,y:7,time:10});
 if(!pointer(slider,'pointermove',{x:60,y:9,time:20}))throw Error('drag must prevent scrolling');
 await until(()=>text().includes('slider 50'),'drag: '+text());
 pointer(slider,'pointerup',{x:60,y:9,time:20});
 await until(()=>events().endsWith('hstart 10|hend 50 2000'),'drag end: '+events());
 const pad=byLabel('pad');
 pointer(pad,'pointerdown',{x:0,y:0,kind:'mouse'});
 pointer(pad,'pointermove',{x:3,y:4,kind:'mouse'});
 pointer(pad,'pointermove',{x:6,y:-4,kind:'mouse'});
 pointer(pad,'pointerup',{x:6,y:-4,kind:'mouse'});
 pad.events.click({currentTarget:pad});
 await until(()=>events().endsWith('pan Offset(6, -4)'),'pan');
 pointer(pad,'pointerdown',{x:0,y:0,kind:'mouse'});
 pointer(pad,'pointerup',{x:0,y:0,kind:'mouse'});
 pad.events.click({currentTarget:pad});
 await until(()=>events().endsWith('pan Offset(6, -4)|pad tap'),'pad tap: '+events());
 const ink=byLabel('ink');
 ink.events.click({currentTarget:ink});
 await until(()=>events().endsWith('|ink tap'),'ink tap');
 pointer(ink,'pointerdown',{});
 await sleep(650);
 pointer(ink,'pointerup',{});
 ink.events.click({currentTarget:ink});
 await until(()=>events().endsWith('|ink tap|ink long'),'ink long: '+events());
 await sleep(20);
 if(events().endsWith('ink tap|ink long|ink tap'))throw Error('click after long press');
 console.log('Gestures passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Gestures passed'));
    },
  );
}
