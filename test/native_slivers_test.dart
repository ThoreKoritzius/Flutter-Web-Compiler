import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'slivers, scroll controllers, notifier providers and reordering',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-slivers-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Counter extends ChangeNotifier {
  int value = 0;
  void increment() {
    value++;
    notifyListeners();
  }
}

final counterProvider = ChangeNotifierProvider((ref) => Counter());

void main() {
  debugPrintStack(label: 'stack label', maxFrames: 1);
  PaintingBinding.instance.imageCache.clear();
  print('platform ${defaultTargetPlatform.name}');
  runApp(const ProviderScope(child: MaterialApp(home: Scaffold(body: Page()))));
}

class Header extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 40;
  @override
  double get maxExtent => 120;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      Text('header ${shrinkOffset.round()} $overlaps');
  @override
  bool shouldRebuild(Header old) => true;
}

class Page extends ConsumerStatefulWidget {
  const Page({super.key});
  @override
  ConsumerState<Page> createState() => _PageState();
}

class _PageState extends ConsumerState<Page> {
  final controller = ScrollController();
  final order = ['a', 'b', 'c'];
  String status = '';

  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(counterProvider);
    return Column(
      children: [
        Text('count ${counter.value} status $status'),
        TextButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: const Text('increment'),
        ),
        TextButton(
          onPressed: () {
            controller.jumpTo(120);
            setState(() => status =
                '${controller.hasClients} ${controller.offset} ${controller.position.pixels}');
          },
          child: const Text('jump'),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: 1,
            items: const [DropdownMenuItem(value: 1, child: Text('one'))],
            onChanged: (_) {},
          ),
        ),
        SizedBox(
          height: 400,
          child: RefreshIndicator(
            onRefresh: () async {},
            child: CustomScrollView(
              controller: controller,
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  expandedHeight: 160,
                  flexibleSpace: FlexibleSpaceBar(title: Text('Health')),
                ),
                SliverPersistentHeader(pinned: true, delegate: Header()),
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverList.builder(
                    itemCount: 3,
                    itemBuilder: (context, i) => Text('row $i'),
                  ),
                ),
                SliverGrid.count(
                  crossAxisCount: 2,
                  children: const [Text('cell 0'), Text('cell 1')],
                ),
                SliverLayoutBuilder(
                  builder: (context, constraints) =>
                      SliverToBoxAdapter(child: Text('cross ${constraints.crossAxisExtent.round()}')),
                ),
                const SliverFillRemaining(child: Text('rest')),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ReorderableListView(
            onReorder: (from, to) => setState(() {
              final item = order.removeAt(from);
              order.insert(to > from ? to - 1 : to, item);
            }),
            children: [
              for (final item in order)
                ListTile(key: ValueKey(item), title: Text('item $item')),
            ],
          ),
        ),
        Text('order ${order.join()}'),
      ],
    );
  }
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        '-e',
        r"""
const {install,until,label,find,findAll,pointer,Element,style}=require('./tool/browser/dom_shim.cjs');
Element.measure=()=>400;Element.measureHeight=()=>400;
const {host,windowListeners}=install();
const logs=[];const log=console.log;console.log=(...a)=>logs.push(a.join(' '));
(async()=>{require(process.argv[1]);
 await until(()=>label(host).includes('row 2'),'slivers rendered');
 const text=()=>label(host);
 if(!logs.includes('stack label'))throw Error('debugPrintStack '+logs);
 if(!logs.some(l=>/^platform (android|linux|macOS|windows|iOS)$/.test(l)))throw Error('platform '+logs);
 for(const s of ['Health','header 0 false','row 0','cell 1','rest','item c'])if(!text().includes(s))throw Error('missing '+s+': '+text());
 const header=find(host,n=>label(n)==='header 0 false'&&style(n).includes('position:sticky'));
 if(!header||!style(header).includes('height:120px'))throw Error('header box '+(header&&style(header)));
 const bar=find(host,n=>style(n).includes('position:sticky')&&label(n).includes('Health'));
 if(!style(bar).includes('height:160px'))throw Error('app bar extent '+style(bar));
 const select=find(host,n=>n.tag==='select');
 if(style(select).includes('border-bottom'))throw Error('underline hidden');
 // ChangeNotifierProvider rebuilds on notifyListeners.
 find(host,n=>n.tag==='button'&&label(n)==='increment').events.click({});
 await until(()=>text().includes('count 1'),'notifier rebuild');
 // The controller scrolls its view.
 find(host,n=>n.tag==='button'&&label(n)==='jump').events.click({});
 await until(()=>text().includes('status true 120 120'),'controller '+text());
 // Pinned headers shrink once content scrolls under them.
 const prev=header.parent.children[header.parent.children.indexOf(header)-1];
 Element.rect=n=>n===prev?{top:-200,bottom:-30,height:170}:{};
 const scroller=find(host,n=>n.events.scroll);
 scroller.events.scroll({});
 await until(()=>text().includes('header 30 true'),'header shrink '+text());
 if(!style(header).includes('height:90px')||!style(header).includes('margin-bottom:30px'))throw Error('shrunk box '+style(header));
 // Dragging the first handle below the second item reorders the list.
 Element.rect=n=>{const l=label(n);return l.startsWith('item a')?{top:0,bottom:50,height:50}:l.startsWith('item b')?{top:50,bottom:100,height:50}:l.startsWith('item c')?{top:100,bottom:150,height:50}:{};};
 const handles=findAll(host,n=>n.events.pointerdown&&n.children[0]&&style(n.children[0]).includes('cursor:grab'));
 if(handles.length!==3)throw Error('handles '+handles.length);
 pointer(handles[0],'pointerdown',{x:5,y:25});
 await until(()=>(windowListeners.pointermove?.size??0)>0,'drag started');
 for(const fn of windowListeners.pointermove)fn({clientY:105,preventDefault(){}});
 for(const fn of [...windowListeners.pointerup])fn({});
 await until(()=>text().includes('order bac'),'reordered '+text());
 console.log=log;console.log('Slivers passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Slivers passed'));
    },
  );
}
