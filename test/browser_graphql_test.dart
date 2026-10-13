import 'dart:io';
import 'package:test/test.dart';

void main() {
  test(
    'compiled browser GraphQL POST validates responses and aborts slow bodies',
    () async {
      final directory = Directory.systemTemp.createTempSync('graphql-browser-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final runtime = File('lib/browser_runtime.dart').absolute.uri;
      final entry = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import '$runtime';
import 'dart:js_interop';
@JS('finishGraphqlTest')
external void finishGraphqlTest();
Future<void> main() async {
  for (final path in ['https://example.com/graphql', '//example.com/graphql', '/api#fragment', r'/\\evil', '/\\n/evil', '/api endpoint']) {
    try { BrowserGraphqlTransport(path); throw StateError('Accepted invalid endpoint'); }
    on ArgumentError { }
  }
  final client = GraphqlClient(BrowserGraphqlTransport('/graphql'));
  final data = await client.query(r'query Items(\u0024limit: Int!) { items }', variables: {'limit': 2}, operationName: 'Items');
  if (data['items'].length != 2) throw StateError('Wrong data');
  for (final item in [('http', 'http'), ('errors', 'graphql'), ('invalid', 'invalid-json'), ('redirect', 'network'), ('slow', 'timeout')]) {
    try {
      await GraphqlClient(BrowserGraphqlTransport('/' + item.\u00241, timeout: const Duration(milliseconds: 150))).query('query { items }');
      throw StateError('Unexpected request success');
    } on GraphqlRequestException catch(e) {
      if(e.kind != item.\u00242) throw StateError('Wrong error: ' + e.kind);
    }
  }
  print('GraphQL POST, error handling and body abort passed');
  finishGraphqlTest();
}
''');
      final output = '${directory.path}/app.js';
      final compile = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '--no-source-maps',
        '-o',
        output,
        entry.path,
      ]);
      expect(compile.exitCode, 0, reason: '${compile.stdout}${compile.stderr}');
      final run = await Process.run('node', [
        'tool/browser/graphql_transport_test.cjs',
        output,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('body abort passed'));
    },
  );
}
