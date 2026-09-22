import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

const card = '''
class CardText extends StatelessWidget {
  const CardText({super.key, required this.title, this.size = 18});
  final String title;
  final double size;
  Widget build(BuildContext context) => Text(title, style: TextStyle(fontSize: size));
}
''';
String source(String child) =>
    '''
class App extends StatelessWidget {
  Widget build(BuildContext context) => $child;
}
$card
''';

void main() {
  test(
    'binds named final fields and defaults without leaking between instances',
    () {
      final result = FlutterDomCompiler().compile(
        source(
          'const Column(children: [CardText(title: "First"), CardText(title: "Second", size: 24)])',
        ),
        {},
      );
      expect(result.html, contains('font-size:18px">First'));
      expect(result.html, contains('font-size:24px">Second'));
    },
  );
  test('rejects missing and unknown constructor data', () {
    for (final call in [
      'const CardText()',
      'const CardText(title: "X", unknown: true)',
    ]) {
      expect(
        () => FlutterDomCompiler().compile(source(call), {}),
        throwsA(isA<CompileException>()),
      );
    }
  });
  test('does not execute constructor bodies or mutable fields', () {
    for (final code in [
      source('CardText(title: "X")')
          .replaceFirst('const CardText', 'CardText')
          .replaceFirst(
            'this.size = 18});',
            'this.size = 18}) { print(title); }',
          ),
      source(
        'const CardText(title: "X")',
      ).replaceFirst('final String title', 'String title'),
    ]) {
      expect(
        () => FlutterDomCompiler().compile(code, {}),
        throwsA(isA<CompileException>()),
      );
    }
  });
}
