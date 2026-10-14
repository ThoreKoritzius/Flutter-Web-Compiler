import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('menus, pickers, chips and segmented buttons run natively', () async {
    final directory = Directory.systemTemp.createTempSync('native-more-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: Panel())));

enum Sort { name, date, size }

class Panel extends StatefulWidget {
  const Panel({super.key});
  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  Sort sort = Sort.name;
  DateTime? day;
  TimeOfDay? time;
  final tags = <String>{};
  String size = 's';
  Set<String> views = {'list'};
  String log = '';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PopupMenuButton<Sort>(
        onSelected: (value) => setState(() => sort = value),
        onCanceled: () => setState(() => log += 'canceled;'),
        itemBuilder: (context) => [
          for (final value in Sort.values)
            PopupMenuItem(value: value, child: Text('by ${value.name}')),
          const PopupMenuDivider(),
          const PopupMenuItem(enabled: false, child: Text('disabled')),
        ],
        child: Text('sort ${sort.name}'),
      ),
      TextButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2026, 3, 1),
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
          );
          setState(() => day = picked);
        },
        child: const Text('pick day'),
      ),
      TextButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 9, minute: 30),
          );
          setState(() => time = picked);
        },
        child: const Text('pick time'),
      ),
      for (final tag in ['red', 'blue'])
        FilterChip(
          label: Text(tag),
          selected: tags.contains(tag),
          onSelected: (on) => setState(() => on ? tags.add(tag) : tags.remove(tag)),
        ),
      ChoiceChip(
        label: const Text('large'),
        selected: size == 'l',
        onSelected: (_) => setState(() => size = 'l'),
      ),
      SegmentedButton<String>(
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: 'list', label: Text('List')),
          ButtonSegment(value: 'grid', label: Text('Grid')),
        ],
        selected: views,
        onSelectionChanged: (next) => setState(() => views = next),
      ),
      Text('state ${sort.name} ${day?.toIso8601String().substring(0, 10)} ${time?.hour}:${time?.minute} ${(tags.toList()..sort()).join(',')} $size ${views.join(',')} $log'),
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
const {install,until,label,find,findAll,key}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
(async()=>{require(process.argv[1]);
 const state=()=>label(host).split('state ')[1];
 await until(()=>state()!==undefined,'app ran');
 const byText=(tag,text)=>find(host,n=>n.tag===tag&&label(n)===text);
 const menuButton=find(host,n=>n.attributes['aria-haspopup']==='menu');
 menuButton.events.click({});
 await until(()=>find(host,n=>n.attributes.role==='menu'),'menu opened');
 const menu=find(host,n=>n.attributes.role==='menu');
 const items=findAll(menu,n=>n.attributes.role==='menuitem');
 if(items.length!==4||items[3].attributes.disabled===undefined)throw Error('menu items');
 key(menu,'ArrowDown');
 if(document.activeElement!==items[0])throw Error('arrow focus');
 key(menu,'ArrowUp');
 if(document.activeElement!==items[2])throw Error('wrapped focus skips disabled');
 items[1].events.click({});
 await until(()=>state().startsWith('date ')&&!find(host,n=>n.attributes.role==='menu'),'menu selection');
 byText('button','pick day').events.click({});
 await until(()=>find(host,n=>n.tag==='input'&&n.attributes.type==='date'),'date dialog');
 const date=find(host,n=>n.tag==='input'&&n.attributes.type==='date');
 if(date.value!=='2026-03-01'||date.attributes.min!=='2026-01-01'||date.attributes.max!=='2026-12-31')throw Error('date input '+date.value+JSON.stringify(date.attributes));
 date.value='2026-04-15';date.events.input({});
 await new Promise(r=>setTimeout(r,10));
 byText('button','OK').events.click({});
 await until(()=>state().startsWith('date 2026-04-15'),'date picked: '+state());
 byText('button','pick time').events.click({});
 await until(()=>find(host,n=>n.tag==='input'&&n.attributes.type==='time'),'time dialog');
 const time=find(host,n=>n.tag==='input'&&n.attributes.type==='time');
 if(time.value!=='09:30')throw Error('time input '+time.value);
 time.value='18:05';time.events.input({});
 await new Promise(r=>setTimeout(r,10));
 byText('button','OK').events.click({});
 await until(()=>state().includes(' 18:5 '),'time picked: '+state());
 const chip=t=>find(host,n=>n.tag==='button'&&label(n).includes(t)&&n.attributes['aria-pressed']!==undefined);
 chip('blue').events.click({});
 await until(()=>chip('blue').attributes['aria-pressed']==='true','filter chip');
 chip('red').events.click({});chip('large').events.click({});
 const segment=t=>find(host,n=>n.tag==='button'&&label(n).endsWith(t)&&n.parent.attributes.role==='group');
 if(!segment('List').attributes.style.includes('min-height:32px;'))throw Error('compact segment minimum height');

 segment('Grid').events.click({});
 await until(()=>state()==='date 2026-04-15 18:5 blue,red l grid ','final: '+state());
 if(segment('Grid').attributes['aria-pressed']!=='true')throw Error('segment pressed');
 menuButton.events.click({});
 await until(()=>find(host,n=>n.attributes.role==='menu'),'menu reopened');
 console.log('More passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('More passed'));
  });
}
