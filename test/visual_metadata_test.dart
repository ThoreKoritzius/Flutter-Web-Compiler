import 'package:flutter_dom_compiler/src/runtime/visual_metadata.dart';
import 'package:test/test.dart';

void main() {
  test('ARGB metadata preserves channels, low 32 bits and equality', () {
    const color = Color(0x80123456);
    expect(
      [color.alpha, color.red, color.green, color.blue],
      [128, 18, 52, 86],
    );
    expect(const Color(0x180123456), color);
    expect(const Color(0x180123456).hashCode, color.hashCode);
    expect(const Color(-1).value, 0xffffffff);
  });
  test('unsupported color interpolation fails explicitly', () {
    expect(
      () => Color.lerp(const Color(0), const Color(0xffffffff), .5),
      throwsUnsupportedError,
    );
  });
}
