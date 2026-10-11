import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source = '''
enum Slot { primary, secondary }
const palette = Palette(slots: {Slot.primary: Color(0xff3987e5)}, fallback: Color(0xffaabbcc));
class Palette extends ThemeExtension<Palette> {
 const Palette({required this.slots, required this.fallback});
 final Map<Slot, Color> slots; final Color fallback;
 Color operator [](Slot slot) => slots[slot] ?? fallback;
 static Palette of(BuildContext context) => Theme.of(context).extension<Palette>()!;
 Palette copyWith() { throw Exception('Unused'); }
}
abstract final class Styles {
 static TextStyle? text(BuildContext ctx) => Theme.of(ctx).textTheme.titleSmall;
}
class Page extends StatelessWidget {
 Widget build(BuildContext context) => Text('Snapshot', style: Styles.text(context)?.copyWith(color: Palette.of(context)[Slot.primary]));
}
''';
  final config = {
    'root': 'Page',
    'staticTheme': {
      'textTheme': {
        'titleSmall': {'fontSize': 20},
      },
      'extensions': {'Palette': 'palette'},
    },
  };
  test(
    'original extension constants, enum map indexing and operator helpers compile',
    () {
      final result = compiler.compile(source, config);
      expect(result.html, contains('rgba(57,135,229,1.0)'));
      expect(result.html, contains('font-size:20px'));
      expect(result.report['nativeAdapterInstances'], 0);
      final alpha = compiler.compile(
        source.replaceFirst(
          '[Slot.primary]',
          '[Slot.primary].withValues(alpha: .5)',
        ),
        config,
      );
      expect(alpha.html, contains('rgba(57,135,229,0.5)'));
      final fallback = compiler.compile(
        source.replaceFirst('[Slot.primary]', '[Slot.secondary]'),
        config,
      );
      expect(fallback.html, contains('rgba(170,187,204,1.0)'));
    },
  );
  test(
    'missing snapshots, wrong key types and unsupported map operations fail',
    () {
      for (final input in [
        source.replaceFirst('[Slot.primary]', "['primary']"),
        source.replaceFirst('Styles.text(context)', 'Styles.text(null)'),
        source.replaceFirst('slots[slot] ?? fallback', 'slots.remove(slot)'),
        source.replaceFirst(
          'Slot.primary: Color(0xff3987e5)',
          'Slot.primary: Color(0xff3987e5), Slot.primary: Color(0xff000000)',
        ),
      ]) {
        expect(
          () => compiler.compile(input, config),
          throwsA(isA<CompileException>()),
        );
      }
      expect(
        () => compiler.compile(source, {
          'root': 'Page',
          'staticTheme': {'textTheme': {}},
        }),
        throwsA(isA<CompileException>()),
      );
    },
  );
  test('read-only Material surfaces retain bounds and text line height', () {
    const input = '''
class Page extends StatelessWidget {
 Widget build(BuildContext context) => Material(color: Color(0xff3987e5), borderRadius: BorderRadius.circular(15), child: Container(constraints: BoxConstraints(minHeight: 76), child: Text('Tile', style: TextStyle(height: 1.15))));
}
''';
    final result = compiler.compile(input, {'root': 'Page'});
    expect(result.html, contains('min-height:76px'));
    expect(result.html, contains('border-radius:15px'));
    expect(result.html, contains('line-height:1.15'));
    for (final value in ['-1', 'double.infinity']) {
      expect(
        () => compiler.compile(
          input.replaceFirst('minHeight: 76', 'minHeight: $value'),
          {'root': 'Page'},
        ),
        throwsA(isA<CompileException>()),
      );
    }
    expect(
      () => compiler.compile(input.replaceFirst('height: 1.15', 'height: 0'), {
        'root': 'Page',
      }),
      throwsA(isA<CompileException>()),
    );
  });
}
