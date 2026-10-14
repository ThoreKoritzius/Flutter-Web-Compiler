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
  test('colors interpolate per channel and handle null endpoints', () {
    expect(
      Color.lerp(const Color(0xff000000), const Color(0xffffffff), .5),
      const Color(0xff808080),
    );
    expect(
      Color.lerp(null, const Color(0xff112233), .5),
      const Color(0x80112233),
    );
    expect(
      Color.lerp(const Color(0xff112233), null, 1),
      const Color(0x00112233),
    );
    expect(
      Color.alphaBlend(const Color(0x80ffffff), const Color(0xff000000)),
      const Color(0xff808080),
    );
    expect(const Color(0xffffffff).computeLuminance(), closeTo(1, 1e-9));
    expect(const Color(0xff000000).computeLuminance(), 0);
    expect(Color.fromRGBO(255, 0, 0, .5), const Color(0x80ff0000));
    expect(const Color(0xff336699).withValues(alpha: .5).alpha, 128);
  });
}
