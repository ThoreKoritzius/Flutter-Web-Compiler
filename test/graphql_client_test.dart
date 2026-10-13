import 'dart:convert';
import 'package:flutter_dom_compiler/runtime.dart';
import 'package:test/test.dart';

class Transport implements GraphqlTransport {
  Transport(this.response);
  GraphqlHttpResponse response;
  String? body;
  @override
  Future<GraphqlHttpResponse> post(String body) async {
    this.body = body;
    return response;
  }
}

void main() {
  test('encodes original document and variables, unwraps data', () async {
    final transport = Transport(
      const GraphqlHttpResponse(200, '{"data":{"items":[1,2]}}'),
    );
    final data = await GraphqlClient(transport).query(
      'query Items { items }',
      variables: {'limit': 2},
      operationName: 'Items',
    );
    expect(data['items'], [1, 2]);
    expect(jsonDecode(transport.body!), {
      'query': 'query Items { items }',
      'variables': {'limit': 2},
      'operationName': 'Items',
    });
  });
  for (final item in [
    (503, '{"secret":"hidden"}', 'http'),
    (200, 'invalid', 'invalid-json'),
    (200, '[]', 'invalid-envelope'),
    (200, '{"errors":{}}', 'invalid-envelope'),
    (200, '{"data":{"items":[]},"errors":[{"message":"secret"}]}', 'graphql'),
    (200, '{"data":null}', 'missing-data'),
  ]) {
    test('rejects ${item.$3} without exposing response', () async {
      await expectLater(
        GraphqlClient(
          Transport(GraphqlHttpResponse(item.$1, item.$2)),
        ).query('query { items }'),
        throwsA(
          isA<GraphqlRequestException>()
              .having((e) => e.kind, 'kind', item.$3)
              .having(
                (e) => e.toString(),
                'safe message',
                isNot(contains('secret')),
              ),
        ),
      );
    });
  }
}
