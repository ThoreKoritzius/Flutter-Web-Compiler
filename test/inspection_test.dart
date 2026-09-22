import 'dart:io';
import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'inventories source sites without claiming conversion coverage or reading generated files',
    () {
      final directory = Directory.systemTemp.createTempSync('dom-inspect-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory(p.join(directory.path, 'lib')).createSync();
      final input = File(p.join(directory.path, 'lib', 'main.dart'));
      const source = '''
class App extends ConsumerStatefulWidget {}
class Painter extends CustomPainter {}
void build() { ref.watch(data); Theme.of(context); const Text('literal');
  TextField(); LayoutBuilder(); const GlobalKey<String>(); CustomPaint(); }
''';
      input.writeAsStringSync(source);
      File(
        p.join(directory.path, 'lib', 'generated.g.dart'),
      ).writeAsStringSync('invalid {');
      File(
        p.join(directory.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: test\ndependencies:\n  flutter: any\n');
      final inspector = ProjectInspector();
      final result = inspector.inspect(directory.path);
      expect(result['dartFiles'], 1);
      expect(result['parserDiagnostics'], 0);
      expect(result['kind'], 'syntax-inventory-not-conversion-coverage');
      expect(result['dependencies'], ['flutter']);
      expect(result['signals'], containsPair('riverpod-access', 1));
      expect(result['signals'], containsPair('global-key', 1));
      expect(result['constructorLikeCalls'], containsPair('Text', 1));
      expect(
        inspector.markdown(result),
        contains('not a DOM-conversion estimate'),
      );
      expect(input.readAsStringSync(), source);
    },
  );

  test('scores actual compiler acceptance with located blockers', () {
    final directory = Directory.systemTemp.createTempSync('dom-score-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory(p.join(directory.path, 'lib')).createSync();
    File(p.join(directory.path, 'lib', 'main.dart')).writeAsStringSync('''
class Good extends StatelessWidget { Widget build(BuildContext c) => Text('OK'); }
class Bad extends StatefulWidget {}
class Imported extends StatelessWidget { Widget build(BuildContext c) => Unknown(); }
''');
    final result = ProjectInspector().inspect(directory.path);
    final score = result['compatibility'] as Map;
    expect(score['native'], 1);
    expect(score['total'], 3);
    expect(score['percent'], closeTo(100 / 3, .001));
    final entries = score['entries'] as List;
    expect(entries[1]['blocker'], contains('StatelessWidget'));
    expect(entries[2]['file'], 'lib/main.dart');
    expect(entries[2]['line'], 3);
  });

  test('reports parse failures and rejects directories without lib', () {
    final directory = Directory.systemTemp.createTempSync('dom-inspect-');
    addTearDown(() => directory.deleteSync(recursive: true));
    expect(
      () => ProjectInspector().inspect(directory.path),
      throwsArgumentError,
    );
    Directory(p.join(directory.path, 'lib')).createSync();
    File(
      p.join(directory.path, 'lib', 'broken.dart'),
    ).writeAsStringSync('class {');
    expect(
      ProjectInspector().inspect(directory.path)['parserDiagnostics'],
      greaterThan(0),
    );
  });
}
