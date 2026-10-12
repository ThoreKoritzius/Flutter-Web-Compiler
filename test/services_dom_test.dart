import 'package:flutter_dom_compiler/src/runtime/services_dom.dart';
import 'package:test/test.dart';

void main() {
  test(
    'unregistered platform calls fail asynchronously with a missing plugin',
    () async {
      const channel = MethodChannel('missing');
      final future = channel.invokeMethod<int>('read');
      await expectLater(future, throwsA(isA<MissingPluginException>()));
      await expectLater(
        channel.invokeListMethod<String>('read'),
        throwsA(isA<MissingPluginException>()),
      );
      await expectLater(
        channel.invokeMapMethod<String, int>('read'),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );

  test(
    'explicit adapters preserve methods, arguments, typed results and disposal',
    () async {
      const channel = MethodChannel('example');
      final calls = <MethodCall>[];
      final dispose = registerDomMethodChannel(channel.name, (call) async {
        calls.add(call);
        return switch (call.method) {
          'number' => 42,
          'list' => <dynamic>['value'],
          'map' => <dynamic, dynamic>{'value': 42},
          _ => null,
        };
      });
      addTearDown(dispose);
      expect(await channel.invokeMethod<int>('number', {'input': 1}), 42);
      expect(calls.first.arguments, {'input': 1});
      expect(await channel.invokeListMethod<String>('list'), ['value']);
      expect(await channel.invokeMapMethod<String, int>('map'), {'value': 42});
      expect(await channel.invokeMethod<String>('null'), isNull);
      expect(
        () => registerDomMethodChannel(channel.name, (_) => 0),
        throwsStateError,
      );
      dispose();
      dispose();
      await expectLater(
        channel.invokeMethod<int>('number'),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );

  test(
    'adapter failures and result type errors propagate to original callers',
    () async {
      final dispose = registerDomMethodChannel('errors', (call) {
        if (call.method == 'throw')
          throw PlatformException(
            code: 'denied',
            details: {'reason': 'example'},
          );
        if (call.method == 'async')
          return Future<Object?>.error(StateError('async failure'));
        return 'wrong type';
      });
      addTearDown(dispose);
      const channel = MethodChannel('errors');
      await expectLater(
        channel.invokeMethod<void>('throw'),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'denied'),
        ),
      );
      await expectLater(channel.invokeMethod<int>('async'), throwsStateError);
      await expectLater(
        channel.invokeMethod<int>('type'),
        throwsA(isA<TypeError>()),
      );
    },
  );
  test(
    'a retired disposer cannot unregister a later registration of the same callback',
    () async {
      int handler(MethodCall call) => 42;
      final old = registerDomMethodChannel('reuse', handler);
      old();
      final current = registerDomMethodChannel('reuse', handler);
      addTearDown(current);
      old();
      expect(await const MethodChannel('reuse').invokeMethod<int>('read'), 42);
    },
  );
}
