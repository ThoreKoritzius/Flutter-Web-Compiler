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
    expect(entries[1]['blocker'], contains('createState'));
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

  test('labels the static score and separates failure categories', () {
    final directory = Directory.systemTemp.createTempSync('dom-categories-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory(p.join(directory.path, 'lib')).createSync();
    File(p.join(directory.path, 'lib', 'card.dart')).writeAsStringSync('''
class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.title});
  final String title;
  Widget build(BuildContext c) => Text(title);
}
''');
    File(p.join(directory.path, 'lib', 'main.dart')).writeAsStringSync('''
class Plain extends StatelessWidget { Widget build(BuildContext c) => Text('OK'); }
class Counter extends StatefulWidget {
  State<Counter> createState() => _CounterState();
  void reset() {}
}
class Uses extends StatelessWidget { Widget build(BuildContext c) => ProfileCard(title: 'x'); }
class Exotic extends StatelessWidget { Widget build(BuildContext c) => Stepper(); }
''');
    final inspector = ProjectInspector();
    final report = inspector.inspect(directory.path);
    final score = report['compatibility'] as Map;
    expect(score['target'], 'static-html');
    expect(score['label'], staticCompatibilityLabel);
    expect(score['scope'], contains('Not whole-app coverage'));
    final byWidget = {
      for (final entry in score['entries'] as List) entry['widget']: entry,
    };
    expect(byWidget['Plain']['category'], 'native');
    expect(byWidget['ProfileCard']['category'], 'needs-inputs');
    expect(byWidget['ProfileCard']['reason'], 'required-parameters');
    expect(byWidget['Counter']['category'], 'needs-inputs');
    expect(byWidget['Counter']['reason'], 'stateful-only');
    expect(byWidget['Uses']['category'], 'dependency');
    expect(byWidget['Exotic']['category'], 'unsupported-api');
    expect(score['categories'], {
      'needs-inputs': 2,
      'unsupported-api': 1,
      'dependency': 1,
      'untested': 0,
    });
    expect(score['statefulOnly'], 1);
    expect((report['domRuntime'] as Map)['measured'], false);
    final markdown = inspector.markdown(report);
    expect(markdown, contains('## $staticCompatibilityLabel'));
    expect(markdown, contains('## DOM runtime (--dart-runtime)'));
    expect(markdown, contains('Not measured.'));
  });

  test('classifies inconclusive and context blockers', () {
    expect(
      classifyStaticBlocker(
        'Native State supports build and pure expression helpers; lifecycle and mixins require an island.',
        'unsupported',
      ),
      ('needs-inputs', 'stateful-only'),
    );
    expect(
      classifyStaticBlocker(
        'Static evaluation budget exceeded.',
        'unsupported',
      ),
      ('untested', 'inconclusive'),
    );
    expect(classifyStaticBlocker('x', 'requires-context'), (
      'needs-inputs',
      'runtime-context',
    ));
    expect(
      classifyStaticBlocker(
        'Theme.of requires an explicit staticTheme snapshot; inherited themes are not inferred.',
        'unsupported',
      ),
      ('needs-inputs', 'inherited-context'),
    );
  });
}
