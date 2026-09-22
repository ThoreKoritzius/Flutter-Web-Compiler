import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

void main() {
  test('bound static interpolation and boolean branches emit escaped HTML', () {
    const source = r'''
class App extends StatelessWidget {
  Widget build(BuildContext context) => Tile(title: '<hello>', enabled: true);
}
class Tile extends StatelessWidget {
  const Tile({required this.title, required this.enabled});
  final String title;
  final bool enabled;
  Widget build(BuildContext context) => enabled
      ? Text('Result: $title (${true})') : UnsupportedWidget();
}
''';
    final result = FlutterDomCompiler().compile(source, {}, domOnly: true);
    expect(result.html, contains('Result: &lt;hello&gt; (true)'));
    expect(result.html, isNot(contains('UnsupportedWidget')));
  });
  test('runtime conditions remain explicit blockers', () {
    expect(
      () => FlutterDomCompiler().compile('''
class App extends StatelessWidget {
 Widget build(BuildContext context) => runtimeFlag ? Text('A') : Text('B');
}
''', {}),
      throwsA(isA<CompileException>()),
    );
  });
}
