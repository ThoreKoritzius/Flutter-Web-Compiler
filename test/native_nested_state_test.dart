import 'dart:io';
import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'compiled descendant state survives updates and disposes on structural removal',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-nested-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
void main() => runApp(const Parent());
class Parent extends StatefulWidget { const Parent(); State<Parent> createState()=>ParentState(); }
class ParentState extends State<Parent> {
 bool visible=true, alternate=false; int version=0;
 Widget build(BuildContext context) => Column(children:[
  ElevatedButton(onPressed:()=>setState(()=>version++), child:const Text('Parent update')),
  ElevatedButton(onPressed:()=>setState(()=>visible=!visible), child:const Text('Visibility')),
  ElevatedButton(onPressed:()=>setState(()=>alternate=!alternate), child:const Text('Change ancestor')),
  visible ? (alternate ? Card(child:Counter('A',version)) : Padding(padding:EdgeInsets.zero,child:Counter('A',version))) : const SizedBox(),
  const Counter('B',0),
  ElevatedButton(onPressed:(){
    runApp(const Text('End'));
    try { runApp(const Column(children:[Counter('C',0), Broken()])); }
    on StateError { print('failure cleaned'); }
    runApp(const Text('End'));
  }, child:const Text('End app')),
 ]);
 void dispose(){print('parent disposed');super.dispose();}
}
class Broken extends StatefulWidget { const Broken(); State<Broken> createState()=>BrokenState(); }
class BrokenState extends State<Broken> {
 Widget build(BuildContext context)=>throw StateError('broken build');
 void dispose(){print('broken disposed');super.dispose();}
}
class Counter extends StatefulWidget {
 const Counter(this.name,this.version); final String name; final int version;
 State<Counter> createState()=>CounterState();
}
class CounterState extends State<Counter> {
 int count=0;
 void initState(){super.initState();print('init ${widget.name}');}
 void didUpdateWidget(Counter old){super.didUpdateWidget(old);print('update ${widget.name} ${old.version}->${widget.version}');}
 void dispose(){print('dispose ${widget.name} $count');super.dispose();}
 Widget build(BuildContext context)=>ElevatedButton(onPressed:()=>setState(()=>count++),child:Text('${widget.name} ${widget.version}:$count'));
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final result = await Process.run('node', [
        'tool/browser/native_nested_state_test.cjs',
        file.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    },
  );
}
