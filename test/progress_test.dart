import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  final compiler = FlutterDomCompiler();
  const source =
      "class Page extends StatelessWidget { Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:0.5,minHeight:9,color:Color(0xff3a8fe8),semanticsLabel:'Volume',semanticsValue:'Half')); }";
  test('determinate native bars expose source-provided accessible values', () {
    final result = compiler.compile(source, {'root': 'Page'});
    final bar = parse(result.html).querySelector('[role=progressbar]')!;
    expect(bar.attributes['aria-valuenow'], '50.0');
    expect(bar.attributes['aria-label'], 'Volume');
    expect(bar.attributes['aria-valuetext'], 'Half');
    expect(result.report['nativeAdapterInstances'], 0);
    expect(result.island, isNull);
  });
  test(
    'indeterminate, invalid or unsupported progress/clip behavior fails closed',
    () {
      for (final input in [
        source.replaceFirst('value:0.5', 'value:null'),
        source.replaceFirst('value:0.5', 'value:1.5'),
        source.replaceFirst('minHeight:9', 'minHeight:0'),
        source.replaceFirst('value:0.5', 'value:0.5,strokeAlign:1'),
        source.replaceFirst(
          'BorderRadius.circular(20)',
          'BorderRadius.only(topLeft:Radius.circular(20))',
        ),
      ]) {
        expect(
          () => compiler.compile(input, {'root': 'Page'}),
          throwsA(isA<CompileException>()),
        );
      }
    },
  );
}
