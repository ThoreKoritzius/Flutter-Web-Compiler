import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('keyboard, services, pages, lists, drag and search run natively', () async {
    final directory = Directory.systemTemp.createTempSync('native-widgets-more-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: Lab())));

class SaveIntent extends Intent {
  const SaveIntent();
}

class Lab extends StatefulWidget {
  const Lab({super.key});
  @override
  State<Lab> createState() => _LabState();
}

class _LabState extends State<Lab> {
  final log = <String>[];
  final pages = PageController();
  final listKey = GlobalKey<AnimatedListState>();
  final items = <String>['x'];
  bool dismissed = false;
  String dropped = '';

  void add(String entry) => setState(() => log.add(entry));

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        Text('log ${log.join('|')}'),
        Shortcuts(
          shortcuts: const {SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveIntent()},
          child: Actions(
            actions: {SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) { add('save'); return null; })},
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  add('enter');
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: const Text('focus box'),
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: 'copied'));
            final text = await rootBundle.loadString('assets/data.json');
            add('asset $text');
            add('hsl ${HSLColor.fromColor(const Color(0xFF3366CC)).toColor().toARGB32().toRadixString(16)}');
          },
          child: const Text('services'),
        ),
        SizedBox(
          height: 100,
          child: PageView(
            controller: pages,
            onPageChanged: (page) => add('page $page'),
            children: const [Text('p0'), Text('p1'), Text('p2')],
          ),
        ),
        TextButton(onPressed: () => pages.jumpToPage(2), child: const Text('jump page')),
        SizedBox(
          height: 120,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) add('scroll start');
              return false;
            },
            child: AnimatedList(
              key: listKey,
              initialItemCount: items.length,
              itemBuilder: (context, i, animation) => SizeTransition(sizeFactor: animation, child: Text('item ${items[i]}')),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            items.insert(0, 'y');
            listKey.currentState!.insertItem(0, duration: const Duration(milliseconds: 50));
          },
          child: const Text('insert'),
        ),
        if (!dismissed)
          Dismissible(
            key: const ValueKey('d'),
            movementDuration: const Duration(milliseconds: 10),
            resizeDuration: const Duration(milliseconds: 10),
            onDismissed: (direction) => setState(() {
              dismissed = true;
              log.add('dismissed ${direction.name}');
            }),
            background: const ColoredBox(color: Colors.red),
            child: const Text('swipe me'),
          ),
        Draggable<String>(data: 'payload', feedback: const Text('flying'), child: const Text('drag me')),
        DragTarget<String>(
          onAcceptWithDetails: (details) => setState(() => dropped = details.data),
          builder: (context, candidates, rejected) => Text('target ${candidates.length} $dropped'),
        ),
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showSearch<String>(context: context, delegate: Finder());
              add('search $result');
            },
            child: const Text('search'),
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => const LinearGradient(colors: [Colors.red, Colors.blue]).createShader(rect),
          child: const Text('gradient'),
        ),
        BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: const Text('frosted')),
        Image.memory(Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1, 2]), width: 10),
        ClipPath(clipper: const ShapeBorderClipper(shape: CircleBorder()), child: const SizedBox(width: 20, height: 20)),
        FittedBox(child: const Text('fit')),
        WillPopScope(onWillPop: () async => false, child: const Text('guarded')),
      ],
    ),
  );
}

class Finder extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => BackButton(onPressed: () => close(context, 'none'));
  @override
  Widget buildResults(BuildContext context) => TextButton(onPressed: () => close(context, query), child: Text('result $query'));
  @override
  Widget buildSuggestions(BuildContext context) => Text('suggest $query');
}
""");
    Directory('${directory.path}/assets').createSync();
    File('${directory.path}/pubspec.yaml').writeAsStringSync('name: lab\nflutter:\n  assets:\n    - assets/data.json\n');
    File('${directory.path}/assets/data.json').writeAsStringSync('{"ok":true}');
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      '-e',
      r"""
const {install,until,label,find,findAll,pointer,Element,style}=require('./tool/browser/dom_shim.cjs');
Element.measure=()=>400;Element.measureHeight=()=>100;
const {host,windowListeners}=install();
let copied=null;
Object.defineProperty(globalThis.navigator,'clipboard',{value:{writeText:async t=>{copied=t;},readText:async()=>copied},configurable:true});
const fetched=[];
globalThis.fetch=async url=>{fetched.push(url);return {ok:true,arrayBuffer:async()=>new TextEncoder().encode('{"ok":true}').buffer};};
(async()=>{require(process.argv[1]);
 const text=()=>label(host);
 const log=()=>text().split('log ')[1]?.split('focus box')[0]??'';
 await until(()=>text().includes('focus box'),'rendered');
 const button=t=>find(host,n=>n.tag==='button'&&label(n)===t);
 // Key events bubble from the focused element through Focus and Shortcuts.
 const focusText=find(host,n=>n.tag==='p'&&label(n)==='focus box');
 const fire=(type,init)=>{let node=focusText;let stopped=false;const ev={type,...init,timeStamp:1,target:focusText,preventDefault(){ev.prevented=true;},stopPropagation(){stopped=true;}};while(node&&!stopped){ev.currentTarget=node;node.events[type]?.(ev);node=node.parent;}return ev;};
 if(!fire('keydown',{key:'Enter'}).prevented)throw Error('enter not handled');
 fire('keydown',{key:'s',ctrlKey:true});
 await until(()=>log().includes('enter|save'),'keys: '+log());
 button('services').events.click({});
 await until(()=>log().includes('asset {"ok":true}'),'services: '+log());
 if(copied!=='copied')throw Error('clipboard '+copied);
 if(fetched[0]!=='assets/assets/data.json')throw Error('asset url '+fetched);
 if(!log().includes('hsl ff3366cc'))throw Error('hsl '+log());
 // Page views snap and report page changes.
 button('jump page').events.click({});
 await until(()=>log().includes('page 2'),'page: '+log());
 const pageView=find(host,n=>style(n).includes('scroll-snap-type:x mandatory'));
 if(!pageView)throw Error('page snapping');
 // Animated list inserts and scroll notifications.
 button('insert').events.click({});
 await until(()=>text().includes('item yitem x'),'insert: '+text());
 const list=find(host,n=>n.events.scroll&&label(n).startsWith('item'));
 list.events.scroll({});
 await until(()=>log().includes('scroll start'),'notification: '+log());
 // Dismissible: a long horizontal drag dismisses.
 const swipe=find(host,n=>n.events.pointerdown&&label(n)==='swipe me');
 pointer(swipe,'pointerdown',{x:10,y:5,time:0});
 pointer(swipe,'pointermove',{x:200,y:5,time:50});
 pointer(swipe,'pointermove',{x:300,y:5,time:100});
 pointer(swipe,'pointerup',{x:300,y:5,time:100});
 await until(()=>log().includes('dismissed startToEnd'),'dismiss: '+log());
 // Drag and drop through elementFromPoint.
 const target=find(host,n=>label(n).startsWith('target ')&&n.tag!=='p');
 document.elementFromPoint=()=>target;
 const drag=find(host,n=>n.events.pointerdown&&label(n)==='drag me');
 pointer(drag,'pointerdown',{x:5,y:5});
 for(const fn of windowListeners.pointermove)fn({clientX:60,clientY:60,timeStamp:10,preventDefault(){}});
 await until(()=>text().includes('flying')&&text().includes('target 1'),'dragging: '+text());
 for(const fn of [...windowListeners.pointerup])fn({});
 await until(()=>text().includes('target 0 payload')&&!text().includes('flying'),'dropped: '+text());
 // Search delegate: suggestions, results, close with a value.
 button('search').events.click({});
 await until(()=>text().includes('suggest '),'search page');
 const input=find(host,n=>n.tag==='input');
 input.value='kiwi';input.events.input?.({});
 await until(()=>text().includes('suggest kiwi'),'query: '+text());
 input.events.keydown?.({key:'Enter',preventDefault(){}});
 input.events.change?.({});
 await new Promise(r=>setTimeout(r,20));
 if(!text().includes('result kiwi')){const submit=input.events.keydown;}
 await until(()=>text().includes('result kiwi'),'results: '+text());
 button('result kiwi').events.click({});
 await until(()=>log().includes('search kiwi'),'closed: '+log());
 // CSS-mapped widgets.
 if(!find(host,n=>style(n).includes('background-clip:text')))throw Error('shader mask');
 if(!find(host,n=>style(n).includes('backdrop-filter:blur(6.00px)')))throw Error('backdrop filter');
 const img=find(host,n=>n.tag==='img');
 if(!img.attributes.src.startsWith('data:image/png;base64,iVBORw'))throw Error('memory image '+img.attributes.src);
 await until(()=>find(host,n=>style(n).includes('clip-path:path(')),'clip path');
 console.log('Widgets more passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Widgets more passed'));
  });
}
