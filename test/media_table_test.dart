import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

String app(String body) => '''void main() => runApp(const MyPage());
class MyPage extends StatelessWidget { Widget build(BuildContext c) => $body; }''';
void main() {
  test(
    'root inference rejects startup statements and conditional initialization',
    () {
      expect(
        () => discoverRoot("void main() { initialize(); runApp(MyApp()); }"),
        throwsA(isA<CompileException>()),
      );
      expect(
        () => discoverRoot("void main() { if (flag) runApp(MyApp()); }"),
        throwsA(isA<CompileException>()),
      );
    },
  );
  test('discovers root and records safe local images with escaped alt text', () {
    final result = FlutterDomCompiler().compile(
      app(
        "Image.asset('assets/test.jpg', semanticLabel: '<layers>', fit: BoxFit.cover)",
      ),
      {},
    );
    expect(result.report['root'], 'MyPage');
    expect(result.report['assets'], ['assets/test.jpg']);
    expect(result.html, contains('alt="&lt;layers&gt;"'));
    expect(
      () => FlutterDomCompiler().compile(
        app("Image.asset('../private.jpg')"),
        {},
      ),
      throwsA(isA<CompileException>()),
    );
  });
  test('emits semantic tables and rejects mismatched rows and callbacks', () {
    const table =
        "DataTable(columns: [DataColumn(label: Text('Name'))], rows: [DataRow(cells: [DataCell(Text('DOM'))])])";
    expect(
      FlutterDomCompiler().compile(app(table), {}).html,
      contains('<th scope="col">'),
    );
    expect(
      () => FlutterDomCompiler().compile(
        app(table.replaceFirst("DataCell(Text('DOM'))", '')),
        {},
      ),
      throwsA(isA<CompileException>()),
    );
  });
}
