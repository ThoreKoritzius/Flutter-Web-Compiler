import 'dart:convert';
import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('Cupertino apps run natively and bundle package icon fonts', () async {
    final directory = Directory.systemTemp.createTempSync('native-cupertino-');
    addTearDown(() => directory.deleteSync(recursive: true));
    void write(String path, String content) =>
        (File(p.join(directory.path, path))..createSync(recursive: true))
            .writeAsStringSync(content);
    // A stand-in for the cupertino_icons package: a pubspec font family.
    write('deps/cupertino_icons/pubspec.yaml', '''
name: cupertino_icons
flutter:
  fonts:
    - family: CupertinoIcons
      fonts:
        - asset: assets/CupertinoIcons.ttf
''');
    write('deps/cupertino_icons/assets/CupertinoIcons.ttf', 'font bytes');
    write('deps/cupertino_icons/lib/cupertino_icons.dart', '');
    final compilerConfig =
        jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
            as Map<String, Object?>;
    write(
      '.dart_tool/package_config.json',
      jsonEncode({
        ...compilerConfig,
        'packages': [
          for (final entry in (compilerConfig['packages'] as List)
              .cast<Map<String, Object?>>())
            {
              ...entry,
              'rootUri': Directory.current.uri
                  .resolve('.dart_tool/')
                  .resolve(entry['rootUri'] as String)
                  .toString(),
            },
          {
            'name': 'cupertino_icons',
            'rootUri': '../deps/cupertino_icons',
            'packageUri': 'lib/',
            'languageVersion': '3.0',
          },
          {
            'name': 'app',
            'rootUri': '../',
            'packageUri': 'lib/',
            'languageVersion': '3.6',
          },
        ],
      }),
    );
    write('lib/main.dart', r"""
import 'package:flutter/cupertino.dart';

void main() => runApp(const CupertinoApp(home: Home()));

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool on = false;
  int segment = 0;
  String log = '';
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
    child: ListView(
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('GENERAL'),
          children: [
            CupertinoListTile(
              leading: const Icon(CupertinoIcons.wifi),
              title: const Text('Wi-Fi'),
              trailing: CupertinoSwitch(value: on, onChanged: (v) => setState(() => on = v)),
            ),
            CupertinoListTile(
              title: const Text('About'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => setState(() => log += 'about;'),
            ),
          ],
        ),
        CupertinoSlidingSegmentedControl<int>(
          groupValue: segment,
          onValueChanged: (v) => setState(() => segment = v ?? 0),
          children: const {0: Text('Day'), 1: Text('Week')},
        ),
        CupertinoButton.filled(
          onPressed: () => showCupertinoDialog<void>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Delete?'),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => log += 'deleted;');
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
          child: const Text('Ask'),
        ),
        const CupertinoTextField(placeholder: 'Name'),
        const CupertinoActivityIndicator(),
        Text('state $on $segment $log'),
      ],
    ),
  );
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    expect(
      app.fontFaces.map((face) => '${face.family}=${face.path}'),
      contains(
        'packages/cupertino_icons/CupertinoIcons=assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
      ),
    );
    expect(
      app.assets['assets/packages/cupertino_icons/assets/CupertinoIcons.ttf'],
      endsWith('CupertinoIcons.ttf'),
    );
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      '-e',
      r"""
const {install,until,label,find,findAll,style}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
(async()=>{require(process.argv[1]);
 const text=()=>label(host);
 await until(()=>text().includes('Settings'),'rendered');
 const state=()=>text().split('state ')[1];
 const icon=find(host,n=>style(n).includes('packages/cupertino_icons/CupertinoIcons'));
 if(!icon)throw Error('cupertino icon font');
 const toggle=find(host,n=>n.attributes.role==='switch');
 toggle.events.click?.({});toggle.events.change?.({});
 await until(()=>state().startsWith('true'),'switch: '+state());
 find(host,n=>n.tag==='button'&&label(n)==='Week').events.click({});
 await until(()=>state().startsWith('true 1'),'segment: '+state());
 find(host,n=>n.tag==='button'&&label(n).startsWith('About')).events.click({});
 await until(()=>state().includes('about;'),'tile: '+state());
 find(host,n=>n.tag==='button'&&label(n)==='Ask').events.click({});
 await until(()=>find(host,n=>n.attributes.role==='alertdialog'),'dialog');
 find(host,n=>n.tag==='button'&&label(n)==='Delete').events.click({});
 await until(()=>state().includes('deleted;')&&!find(host,n=>n.attributes.role==='alertdialog'),'dialog action: '+state());
 if(!find(host,n=>n.tag==='input'&&n.attributes.placeholder==='Name'))throw Error('text field');
 console.log('Cupertino passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Cupertino passed'));
  });
}
