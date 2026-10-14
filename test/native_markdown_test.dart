import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('flutter_markdown imports render native markdown', () async {
    final directory = Directory.systemTemp.createTempSync('native-md-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r'''
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

const doc = """
# Weekly summary

Some **bold**, *italic*, ~~old~~ and `inline code` with a [guide link](https://example.com/guide "Guide").

- First item
- Second item with **emphasis**
  1. Nested one
  2. Nested two

- [x] Done task
- [ ] Open task

> Quoted note

```
let total = 42;
```

| Metric | Value |
| :----- | ----: |
| Steps  | 8,000 |

![Chart](https://example.com/chart.png)
""";

void main() => runApp(const MaterialApp(home: Scaffold(body: Notes())));

class Notes extends StatefulWidget {
  const Notes({super.key});
  @override
  State<Notes> createState() => NotesState();
}

class NotesState extends State<Notes> {
  String tapped = '-';
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('tapped $tapped'),
    MarkdownBody(
      data: doc,
      onTapLink: (text, href, title) => setState(() => tapped = '$text|$href|$title'),
      styleSheet: MarkdownStyleSheet(h1: const TextStyle(fontSize: 30, color: Color(0xff123456))),
    ),
  ]);
}
''');
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    expect(app.builtInBridges, ['flutter_markdown_plus']);
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      'tool/browser/native_markdown_test.cjs',
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Markdown passed'));
  });
}
