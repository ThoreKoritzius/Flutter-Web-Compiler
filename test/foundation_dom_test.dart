import 'dart:async';

import 'package:flutter_dom_compiler/src/runtime/foundation_dom.dart';
import 'package:test/test.dart';

void main() {
  test(
    'compute yields, flattens futures and propagates callback failures',
    () async {
      var called = false;
      final result = compute((int value) {
        called = true;
        return value * 2;
      }, 21);
      expect(called, isFalse);
      expect(await result, 42);
      expect(await compute((int value) async => value + 1, 41), 42);
      await expectLater(
        compute((int _) => throw StateError('failure'), 0),
        throwsStateError,
      );
      await expectLater(
        compute((int _) => Future<int>.error(StateError('async')), 0),
        throwsStateError,
      );
    },
  );

  test('console logging is explicit and rejects unsupported wrapping', () {
    final logs = <String>[];
    runZoned(
      () {
        debugPrint('message');
        debugPrint(null);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, parent, zone, message) {
          logs.add(message);
        },
      ),
    );
    expect(logs, ['message', 'null']);
    expect(() => debugPrint('text', wrapWidth: 20), throwsUnsupportedError);
  });
}
