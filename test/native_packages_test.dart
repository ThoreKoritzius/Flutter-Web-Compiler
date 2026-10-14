import 'dart:convert';
import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('Flutter-dependent packages compile against the runtime', () async {
    final directory = Directory.systemTemp.createTempSync('native-packages-');
    addTearDown(() => directory.deleteSync(recursive: true));
    void write(String path, String content) => (File(
      p.join(directory.path, path),
    )..createSync(recursive: true)).writeAsStringSync(content);

    // A pure Dart package and a widget package that uses it, Flutter and a
    // bridged plugin, laid out as pub would.
    write('deps/plain_text/lib/plain_text.dart', '''
String shout(String value) => '\${value.toUpperCase()}!';
''');
    write('deps/card_kit/lib/card_kit.dart', '''
export 'src/labelled.dart';
export 'src/model.dart';
''');
    write('deps/card_kit/lib/src/model.dart', '''
class CardModel {
  const CardModel(this.title);
  final String title;
}
''');
    write('deps/card_kit/lib/src/labelled.dart', '''
import 'package:flutter/material.dart';
import 'package:plain_text/plain_text.dart';
import 'package:url_launcher/link.dart';
import 'model.dart';

class LabelledCard extends StatelessWidget {
  const LabelledCard({super.key, required this.model, required this.url});
  final CardModel model;
  final Uri url;
  @override
  Widget build(BuildContext context) => Link(
    uri: url,
    target: LinkTarget.blank,
    builder: (context, follow) =>
        TextButton(onPressed: follow, child: Text(shout(model.title))),
  );
}
''');
    final compilerConfig =
        jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
            as Map<String, Object?>;
    final packages = [
      for (final entry
          in (compilerConfig['packages'] as List).cast<Map<String, Object?>>())
        {
          ...entry,
          'rootUri': Directory.current.uri
              .resolve('.dart_tool/')
              .resolve(entry['rootUri'] as String)
              .toString(),
        },
      for (final name in ['plain_text', 'card_kit'])
        {
          'name': name,
          'rootUri': '../deps/$name',
          'packageUri': 'lib/',
          'languageVersion': '3.6',
        },
      {
        'name': 'app',
        'rootUri': '../',
        'packageUri': 'lib/',
        'languageVersion': '3.6',
      },
    ];
    write(
      '.dart_tool/package_config.json',
      jsonEncode({...compilerConfig, 'packages': packages}),
    );
    write('lib/main.dart', r"""
import 'package:card_kit/card_kit.dart';
import 'package:card_kit/src/model.dart' as model;
import 'package:flutter/material.dart';

void main() {
  // The same CardModel type through both imports.
  const model.CardModel card = CardModel('docs');
  runApp(MaterialApp(
    home: LabelledCard(model: card, url: Uri.parse('https://example.com/docs')),
  ));
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    expect(app.rewrittenPackages, ['card_kit']);
    expect(app.builtInBridges, ['url_launcher']);
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      '-e',
      r"""
const {install,until,label,find}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
const opened=[];global.window.open=(url,target)=>{opened.push([url,target]);return {};};
(async()=>{require(process.argv[1]);
 await until(()=>label(host).includes('DOCS!'),'card rendered');
 find(host,n=>n.tag==='button').events.click({});
 await until(()=>opened.length===1,'link followed');
 if(JSON.stringify(opened[0])!=='["https://example.com/docs","_blank"]')throw Error(JSON.stringify(opened));
 console.log('Packages passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Packages passed'));
  });
}
