library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

class NativeAppBuild {
  NativeAppBuild(this.javascript, this.libraries);
  final String javascript;
  final int libraries;
}

/// Copies a local source graph and substitutes only Flutter's material import.
/// Original widget, lifecycle, repository and model bodies remain unchanged.
/// All unsupported APIs are left to the official compiler to reject.
Future<NativeAppBuild> buildNativeApp(String project, String source) async {
  final root = Directory(project).resolveSymbolicLinksSync();
  final entry = File(p.join(root, source));
  if (!entry.existsSync()) throw ArgumentError('Native app entry is missing.');
  final temporary = Directory.systemTemp.createTempSync('flutter-dom-runtime-');
  final seen = <String, String>{};
  // Resolve the package library rather than depending on the caller's cwd.
  final runtimeUri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_dom_compiler/src/runtime/flutter_dom.dart'),
  );
  if (runtimeUri == null)
    throw StateError('DOM runtime package could not be resolved.');
  try {
    String copy(File input) {
      final path = input.resolveSymbolicLinksSync();
      if (!p.isWithin(root, path))
        throw ArgumentError('Local dependency is outside project.');
      if (seen.containsKey(path)) return seen[path]!;
      if (seen.length >= 500)
        throw ArgumentError(
          'Native runtime source graph exceeds 500 libraries.',
        );
      final destination = p.join(
        temporary.path,
        'source',
        p.relative(path, from: root),
      );
      seen[path] = destination;
      final text = input.readAsStringSync();
      final parsed = parseString(content: text, throwIfDiagnostics: false);
      if (parsed.errors.isNotEmpty)
        throw ArgumentError('Native source contains parser errors.');
      final edits = <(int, int, String)>[];
      for (final directive in parsed.unit.directives) {
        if (directive is! UriBasedDirective) continue;
        final uri = directive.uri.stringValue;
        if (uri == null) throw ArgumentError('Invalid library URI.');
        if (directive is ImportDirective &&
                directive.configurations.isNotEmpty ||
            directive is ExportDirective &&
                directive.configurations.isNotEmpty) {
          throw UnsupportedError(
            'Conditional library directives are not supported in the experimental runtime target.',
          );
        }
        String? replacement;
        if (uri == 'package:flutter/material.dart') {
          replacement = runtimeUri.toString();
        } else if (uri.startsWith('package:flutter/') || uri == 'dart:ui') {
          throw UnsupportedError('Unsupported Flutter/engine import: $uri');
        } else if (!Uri.parse(uri).hasScheme) {
          replacement = Uri.file(
            copy(File(p.join(p.dirname(path), uri))),
          ).toString();
        }
        if (replacement != null)
          edits.add((
            directive.uri.offset,
            directive.uri.length,
            jsonEncode(replacement),
          ));
      }
      var rewritten = text;
      for (final edit in edits.reversed) {
        rewritten = rewritten.replaceRange(edit.$1, edit.$1 + edit.$2, edit.$3);
      }
      final file = File(destination)..parent.createSync(recursive: true);
      file.writeAsStringSync(rewritten);
      return destination;
    }

    final generated = copy(entry);
    final output = p.join(temporary.path, 'app.js');
    final packages = File(p.join(root, '.dart_tool/package_config.json'));
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--no-source-maps',
      if (packages.existsSync()) '--packages=${packages.path}',
      '-o',
      output,
      generated,
    ]);
    if (result.exitCode != 0)
      throw StateError(
        'Official Dart compilation failed:\n${result.stdout}${result.stderr}',
      );
    return NativeAppBuild(File(output).readAsStringSync(), seen.length);
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

const nativeAppHost = '''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Native Dart app</title>
<style>:root{color-scheme:dark;background:#101217;color:#eef1fa;font-family:system-ui,sans-serif}body{margin:0;padding:clamp(24px,6vw,72px)}main{max-width:720px;margin:auto}h1{font-size:clamp(32px,6vw,48px);letter-spacing:-.04em}#app{border:1px solid #303644;border-radius:20px;background:#1d212a;padding:28px}p{margin:4px 0;line-height:1.6}button{font:inherit;background:#a6b8ff;color:#101217;border:0;border-radius:10px;padding:12px 16px;cursor:pointer}button p{margin:0}button:hover{filter:brightness(1.1)}button:focus-visible{outline:3px solid white;outline-offset:3px}footer{color:#aab1c3;font-size:13px;margin-top:24px}</style>
<main><h1>Flutter source. Native DOM.</h1><div id="app">Starting…</div><footer>Experimental runtime · bounded Flutter API · official Dart compiler</footer></main>
<script defer src="app.js"></script></html>''';
