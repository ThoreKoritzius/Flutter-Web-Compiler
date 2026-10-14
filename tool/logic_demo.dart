import 'dart:convert';
import 'dart:io';

/// Reproducible experiment: official compiler, pure-Dart logic, explicit DOM host.
Future<void> main(List<String> args) async {
  if (args.any((a) => a != '--no-serve' && a != '--native-app')) {
    stderr.writeln(
      'Usage: dart run tool/logic_demo.dart [--no-serve] [--native-app]',
    );
    exitCode = 64;
    return;
  }
  final native = args.contains('--native-app');
  final output = Directory(native ? 'build/native-app' : 'build/logic-demo')
    ..createSync(recursive: true);
  final script = native ? 'app.js' : 'logic.js';
  final process = await Process.run(
    Platform.resolvedExecutable,
    native
        ? [
            'run',
            'bin/flutter_dom.dart',
            'build',
            'web',
            '--project',
            'examples/logic',
            '--dart-runtime',
            '--output',
            output.path,
          ]
        : [
            'compile',
            'js',
            '-O2',
            '--no-source-maps',
            '-o',
            '${output.path}/logic.js',
            'examples/logic/lib/browser.dart',
          ],
  );
  if (process.exitCode != 0) {
    stderr.write('${process.stdout}${process.stderr}');
    exitCode = process.exitCode;
    return;
  }
  if (!native)
    File('examples/logic/index.html').copySync('${output.path}/index.html');
  stdout.writeln(
    'Built official Dart JavaScript + ${native ? 'bounded Flutter DOM runtime' : 'explicit DOM host'} (${File('${output.path}/$script').lengthSync()} bytes JS).',
  );
  if (args.contains('--no-serve')) return;
  final port = native ? 8122 : 8121;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('http://127.0.0.1:$port/ · synthetic live API');
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
    } else if (const {
      '/',
      '/app.js',
      '/logic.js',
      '/app.css',
    }.contains(request.uri.path)) {
      final name = request.uri.path == '/'
          ? 'index.html'
          : request.uri.path.substring(1);
      final file = File('${output.path}/$name');
      if (!file.existsSync()) {
        request.response.statusCode = 404;
      } else {
        request.response.headers.contentType = name.endsWith('.js')
            ? ContentType('application', 'javascript')
            : name.endsWith('.css')
            ? ContentType('text', 'css', charset: 'utf-8')
            : ContentType.html;
        request.response.add(file.readAsBytesSync());
      }
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  }
}
