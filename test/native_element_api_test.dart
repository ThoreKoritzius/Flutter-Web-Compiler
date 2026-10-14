import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('provider-style element APIs and image package bridges', () async {
    final directory = Directory.systemTemp.createTempSync('native-element-api-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A selector-style inherited model, written the way provider does it:
/// a custom InheritedElement that stores per-dependent aspects and only
/// notifies dependents whose aspect changed.
class Model extends InheritedWidget {
  const Model({super.key, required this.values, required super.child});
  final Map<String, int> values;
  static int of(BuildContext context, String aspect) {
    final element = context.getElementForInheritedWidgetOfExactType<Model>()!;
    final model = context.dependOnInheritedElement(element, aspect: aspect) as Model;
    return model.values[aspect]!;
  }
  @override
  bool updateShouldNotify(Model oldWidget) => true;
  @override
  ModelElement createElement() => ModelElement(this);
}

class ModelElement extends InheritedElement {
  ModelElement(Model super.widget);
  final log = <String>[];

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    log.add('mounted');
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final aspects = (getDependencies(dependent) as Set<String>?) ?? <String>{};
    setDependencies(dependent, aspects..add(aspect! as String));
  }

  @override
  void notifyDependent(Model oldWidget, Element dependent) {
    final aspects = getDependencies(dependent) as Set<String>;
    final current = widget as Model;
    if (aspects.any((a) => oldWidget.values[a] != current.values[a])) {
      dependent.didChangeDependencies();
    }
  }

  @override
  void updated(Model oldWidget) {
    log.add('updated');
    super.updated(oldWidget);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', (widget as Model).values.length));
  }
}

int aBuilds = 0, bBuilds = 0;

class ShowA extends StatelessWidget {
  const ShowA({super.key});
  @override
  Widget build(BuildContext context) {
    aBuilds++;
    return Text('a=${Model.of(context, 'a')} builds $aBuilds');
  }
}

class ShowB extends StatelessWidget {
  const ShowB({super.key});
  @override
  Widget build(BuildContext context) {
    bBuilds++;
    return Text('b=${Model.of(context, 'b')} builds $bBuilds');
  }
}

void main() => runApp(const MaterialApp(home: Scaffold(body: Root())));

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  var values = {'a': 1, 'b': 1};
  @override
  Widget build(BuildContext context) => Model(
    values: values,
    child: Column(
      children: [
        const ShowA(),
        const ShowB(),
        TextButton(onPressed: () => setState(() => values = {...values, 'a': values['a']! + 1}), child: const Text('bump a')),
        SvgPicture.asset('assets/logo.svg', width: 24, colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn)),
        SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg"/>', width: 10),
        CachedNetworkImage(imageUrl: 'https://example.com/a.png', width: 30, placeholder: (context, url) => const Text('loading image')),
        Builder(builder: (context) => Text('render ${context.findRenderObject() is RenderBox} ${context.owner != null}')),
      ],
    ),
  );
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    expect(app.builtInBridges, containsAll(['cached_network_image', 'flutter_svg']));
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      '-e',
      r"""
const {install,until,label,find,style}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
(async()=>{require(process.argv[1]);
 const text=()=>label(host);
 await until(()=>text().includes('a=1 builds 1'),'rendered: '+text());
 if(!text().includes('b=1 builds 1'))throw Error('b '+text());
 if(!text().includes('render true true'))throw Error('render object '+text());
 find(host,n=>n.tag==='button'&&label(n)==='bump a').events.click({});
 await until(()=>text().includes('a=2 builds 2'),'aspect a: '+text());
 await new Promise(r=>setTimeout(r,30));
 if(!text().includes('b=1 builds 1'))throw Error('b rebuilt though its aspect is unchanged: '+text());
 const masked=find(host,n=>style(n).includes('mask:url("assets/assets/logo.svg")'));
 if(!masked||!style(masked).includes('background-color:'))throw Error('tinted svg');
 const svg=find(host,n=>n.tag==='img'&&(n.attributes.src||'').startsWith('data:image/svg+xml;base64,'));
 if(!svg)throw Error('svg string');
 const img=find(host,n=>n.tag==='img'&&n.attributes.src==='https://example.com/a.png');
 if(!img||!text().includes('loading image'))throw Error('cached image placeholder');
 img.events.load?.({});
 await until(()=>!text().includes('loading image'),'image loaded');
 console.log('Element API passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Element API passed'));
  });
}
