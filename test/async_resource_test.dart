import 'dart:async';

import 'package:flutter_dom_compiler/runtime.dart';
import 'package:test/test.dart';

import '../examples/logic/lib/repository.dart';

class _Transport implements SummaryTransport {
  _Transport(this.body);
  final String body;
  @override
  Future<String> read() async => body;
}

void main() {
  test(
    'original repository and factories decode and validate response data',
    () async {
      final result = await SummaryRepository(
        _Transport('{"data":{"activities":[{"name":"Walk","minutes":42}]}}'),
      ).fetch();
      expect(result.totalMinutes, 42.0);
      for (final body in [
        '{"errors":["failure"]}',
        '{"data":{"activities":[{"name":"Walk","minutes":-1}]}}',
        '{"data":{"activities":[{"name":"Walk","minutes":"42"}]}}',
        'invalid',
      ]) {
        await expectLater(
          SummaryRepository(_Transport(body)).fetch(),
          throwsA(anything),
        );
      }
    },
  );

  test(
    'loading, error, retry and retained prior data have explicit states',
    () async {
      var fail = false;
      final resource = AsyncResource<int>(() async {
        if (fail) throw StateError('failed');
        return 42;
      });
      final states = <ResourceState<int>>[];
      resource.listen(states.add);
      await resource.refresh();
      fail = true;
      await resource.refresh();
      expect(resource.state.phase, ResourcePhase.error);
      expect(resource.state.value, 42);
      expect(resource.state.error, isA<StateError>());
      fail = false;
      await resource.refresh();
      expect(states.map((s) => s.phase), [
        ResourcePhase.loading,
        ResourcePhase.data,
        ResourcePhase.loading,
        ResourcePhase.error,
        ResourcePhase.loading,
        ResourcePhase.data,
      ]);
      expect(resource.state.error, isNull);
    },
  );

  test(
    'late success and late failure cannot overwrite a newer request',
    () async {
      for (final lateFailure in [false, true]) {
        final requests = <Completer<int>>[];
        final resource = AsyncResource<int>(() {
          final request = Completer<int>();
          requests.add(request);
          return request.future;
        });
        final old = resource.refresh();
        final current = resource.refresh();
        requests[1].complete(2);
        await current;
        if (lateFailure) {
          requests[0].completeError(StateError('stale'));
        } else {
          requests[0].complete(1);
        }
        await old;
        expect(resource.state.phase, ResourcePhase.data);
        expect(resource.state.value, 2);
      }
    },
  );

  test('disposal and unsubscribe prevent later DOM notifications', () async {
    final request = Completer<int>();
    final resource = AsyncResource<int>(() => request.future);
    var notifications = 0;
    final unsubscribe = resource.listen((_) => notifications++);
    final pending = resource.refresh();
    unsubscribe();
    resource.dispose();
    request.complete(1);
    await pending;
    expect(notifications, 1);
    await expectLater(resource.refresh(), throwsStateError);
    expect(() => resource.listen((_) {}), throwsStateError);
  });

  test('synchronous load errors become resource errors', () async {
    final resource = AsyncResource<int>(() => throw StateError('sync'));
    await resource.refresh();
    expect(resource.state.phase, ResourcePhase.error);
  });

  test(
    'reentrant refresh does not dispatch superseded data to later listeners',
    () async {
      var calls = 0;
      final resource = AsyncResource<int>(() async => ++calls);
      Future<void>? newer;
      resource.listen((state) {
        if (state.phase == ResourcePhase.data && state.value == 1) {
          newer = resource.refresh();
        }
      });
      final values = <int?>[];
      resource.listen((state) {
        if (state.phase == ResourcePhase.data) values.add(state.value);
      });
      await resource.refresh();
      await newer;
      expect(values, [2]);
    },
  );

  test('disposal during loading avoids starting the request', () async {
    var requests = 0;
    final resource = AsyncResource<int>(() async => ++requests);
    resource.listen((_) => resource.dispose());
    await resource.refresh();
    expect(requests, 0);
  });
}
