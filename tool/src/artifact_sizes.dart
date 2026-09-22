import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

List<String> flutterArtifacts(
  String root, {
  String bootstrap = 'flutter_bootstrap.js',
  bool includeHtml = true,
}) {
  final files = [
    if (includeHtml) 'index.html',
    bootstrap,
    'main.dart.js',
    'canvaskit/chromium/canvaskit.js',
    'canvaskit/chromium/canvaskit.wasm',
    'assets/FontManifest.json',
  ];
  final fonts =
      jsonDecode(
            File(p.join(root, 'assets/FontManifest.json')).readAsStringSync(),
          )
          as List;
  for (final family in fonts) {
    for (final font in family['fonts'] as List) {
      files.add('assets/${font['asset']}');
    }
  }
  return files.toSet().toList()..sort();
}

Map<String, Object?> measureArtifacts(String root, List<String> paths) {
  final files = <Map<String, Object?>>[];
  var bytes = 0, compressed = 0;
  for (final path in paths.toSet().toList()..sort()) {
    final content = File(p.join(root, path)).readAsBytesSync();
    final gzipSize = GZipCodec(level: 9).encode(content).length;
    bytes += content.length;
    compressed += gzipSize;
    files.add({
      'path': path,
      'bytes': content.length,
      'gzipBytes': gzipSize,
      'sha256': sha256.convert(content).toString(),
    });
  }
  return {'bytes': bytes, 'gzipBytes': compressed, 'files': files};
}
