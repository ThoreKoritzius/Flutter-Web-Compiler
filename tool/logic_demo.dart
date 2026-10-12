import 'dart:convert';
import 'dart:io';

/// Reproducible experiment: official compiler, pure-Dart logic, explicit DOM host.
Future<void> main(List<String> args) async {
  if (args.any((a) => a != '--no-serve')) {
    stderr.writeln('Usage: dart run tool/logic_demo.dart [--no-serve]');
    exitCode = 64;
    return;
  }
  final output = Directory('build/logic-demo')..createSync(recursive: true);
  final process = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'js',
    '-O2',
    '--no-source-maps',
    '-o',
    '${output.path}/logic.js',
    'examples/logic/lib/browser.dart',
  ]);
  if (process.exitCode != 0) {
    stderr.write('${process.stdout}${process.stderr}');
    exitCode = process.exitCode;
    return;
  }
  File('examples/logic/index.html').copySync('${output.path}/index.html');
  stdout.writeln(
    'Built official Dart JavaScript + explicit DOM host (${File('${output.path}/logic.js').lengthSync()} bytes JS).',
  );
  if (args.contains('--no-serve')) return;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8121);
  stdout.writeln('http://127.0.0.1:8121/ · synthetic live API');
  await for (final request in server) {
    if (request.uri.path == '/api/summary') {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      request.response.headers.contentType = ContentType.json;
      request.response.headers.set('Cache-Control', 'no-store');
      if (request.uri.queryParameters['fail'] == '1') {
        request.response.statusCode = 503;
        request.response.write(
          jsonEncode({
            'errors': ['Synthetic failure'],
          }),
        );
      } else {
        request.response.write(
          jsonEncode({
            'data': {
              'activities': [
                {'name': 'Walking', 'minutes': 42},
                {'name': 'Cycling', 'minutes': 65},
                {'name': 'Swimming', 'minutes': 30},
              ],
            },
          }),
        );
      }
    } else if (request.uri.path == '/' || request.uri.path == '/logic.js') {
      final name = request.uri.path == '/' ? 'index.html' : 'logic.js';
      request.response.headers.contentType = name.endsWith('.js')
          ? ContentType('application', 'javascript')
          : ContentType.html;
      request.response.add(File('${output.path}/$name').readAsBytesSync());
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  }
}
