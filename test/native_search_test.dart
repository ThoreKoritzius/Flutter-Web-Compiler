import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('Autocomplete and SearchAnchor run natively', () async {
    final directory = Directory.systemTemp.createTempSync('native-search-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';

const fruits = ['apple', 'apricot', 'banana'];

void main() => runApp(const MaterialApp(home: Scaffold(body: Finder())));

class Finder extends StatefulWidget {
  const Finder({super.key});
  @override
  State<Finder> createState() => _FinderState();
}

class _FinderState extends State<Finder> {
  String picked = '';
  final search = SearchController();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('picked $picked search ${search.text}'),
      Autocomplete<String>(
        optionsBuilder: (value) => fruits.where((f) => value.text.isNotEmpty && f.startsWith(value.text)),
        onSelected: (value) => setState(() => picked = value),
      ),
      SearchAnchor.bar(
        searchController: search,
        barHintText: 'Search fruit',
        suggestionsBuilder: (context, controller) => [
          for (final fruit in fruits.where((f) => f.contains(controller.text)))
            ListTile(
              title: Text('suggest $fruit'),
              onTap: () {
                controller.closeView(fruit);
                setState(() {});
              },
            ),
        ],
      ),
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
const {install,until,label,find,findAll}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
(async()=>{require(process.argv[1]);
 const text=()=>label(host);
 await until(()=>text().includes('picked'),'rendered');
 const inputs=()=>findAll(host,n=>n.tag==='input');
 const field=inputs()[0];
 field.events.focus?.({});
 field.value='ap';field.events.input({});
 await until(()=>findAll(host,n=>n.attributes.role==='option').length===2,'options: '+text());
 const combo=find(host,n=>n.attributes.role==='combobox');
 const key=(name)=>{let node=field;const ev={key:name,timeStamp:1,target:field,preventDefault(){},stopPropagation(){ev.stopped=true;}};while(node&&!ev.stopped){ev.currentTarget=node;node.events.keydown?.(ev);node=node.parent;}};
 key('ArrowDown');
 await until(()=>find(host,n=>n.attributes.role==='option'&&n.attributes['aria-selected']==='true'&&label(n)==='apricot'),'highlight');
 key('Enter');
 await until(()=>text().includes('picked apricot'),'selected: '+text());
 if(field.value!=='apricot')throw Error('field text '+field.value);
 const bar=inputs()[1];
 bar.events.click?.({});
 bar.events.focus?.({});
 const tap=find(host,n=>n.attributes.role==='search');
 bar.value='nan';bar.events.input({});
 await until(()=>text().includes('suggest banana'),'search view: '+text());
 find(host,n=>label(n)==='suggest banana'&&n.events.click).events.click({});
 await until(()=>text().includes('search banana')&&!text().includes('suggest banana'),'closed with value: '+text());
 console.log('Search passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Search passed'));
  });
}
