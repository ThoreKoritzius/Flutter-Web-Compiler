library;

export 'src/runtime/source_selection.dart' show NativeSourceSelection;
import 'src/runtime/source_selection.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class NativeAppBuild {
  NativeAppBuild(
    this.javascript,
    this.libraries,
    this.libraryAdapters, {
    this.riverpodConsumers = false,
    this.packageAdapters = const [],
    this.sourceSelections = const {},
  });
  final Map<String, NativeSourceSelection> sourceSelections;
  final List<String> packageAdapters;
  final bool riverpodConsumers;
  final String javascript;
  final int libraries;
  final List<String> libraryAdapters;
}

/// Copies a local source graph and substitutes bounded Flutter API imports.
/// Unadapted widget, lifecycle, repository and model bodies remain unchanged.
/// Selected library bridges are explicit replacements, reported separately.
/// All unsupported APIs are left to the official compiler to reject.
Future<NativeAppBuild> buildNativeApp(
  String project,
  String source, {
  Map<String, String> libraryBridges = const {},
  Map<String, String> packageBridges = const {},
  Map<String, String> dartDefines = const {},
  Map<String, NativeSourceSelection> sourceSelections = const {},
}) async {
  final root = Directory(project).resolveSymbolicLinksSync();
  final entry = File(p.join(root, source));
  if (!entry.existsSync()) throw ArgumentError('Native app entry is missing.');
  if (libraryBridges.length > 50)
    throw ArgumentError('At most 50 library bridges are supported.');
  final bridges = <String, File>{};
  for (final item in libraryBridges.entries) {
    if (p.isAbsolute(item.key) ||
        p.normalize(item.key) != item.key ||
        item.key.split(p.separator).contains('..')) {
      throw ArgumentError(
        'Bridge keys must be normalized project-relative library paths.',
      );
    }
    final original = File(p.join(root, item.key));
    if (!original.existsSync() ||
        !p.isWithin(root, original.resolveSymbolicLinksSync())) {
      throw ArgumentError(
        'Bridge source must be an existing project-local library.',
      );
    }
    final bridge = File(item.value);
    if (!bridge.existsSync())
      throw ArgumentError('Bridge implementation does not exist.');
    final identity = original.resolveSymbolicLinksSync();
    if (bridges.containsKey(identity))
      throw ArgumentError('Duplicate bridge source identity.');
    bridges[identity] = bridge;
  }
  if (packageBridges.length > 50 || dartDefines.length > 50)
    throw ArgumentError(
      'At most 50 package bridges and definitions are supported.',
    );
  final packageAdapters = <String, String>{};
  for (final item in packageBridges.entries) {
    final uri = Uri.parse(item.key);
    if (uri.scheme != 'package' ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.hasAuthority ||
        uri.path.startsWith('/') ||
        uri.pathSegments.length < 2 ||
        uri.pathSegments.any((s) => s == '..' || s == '.' || s.isEmpty) ||
        !uri.path.endsWith('.dart') ||
        item.key.startsWith('package:flutter/') ||
        item.key == 'package:flutter_riverpod/flutter_riverpod.dart') {
      throw ArgumentError(
        'Package bridges require a non-framework package library URI.',
      );
    }
    final file = File(item.value);
    if (!file.existsSync())
      throw ArgumentError('Package bridge implementation is missing.');
    packageAdapters[item.key] = file.resolveSymbolicLinksSync();
  }
  for (final key in dartDefines.keys) {
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_.]*$').hasMatch(key) ||
        key.startsWith('dart.'))
      throw ArgumentError('Invalid or reserved Dart definition key.');
  }
  final selections = <String, NativeSourceSelection>{};
  if (sourceSelections.length > 50)
    throw ArgumentError('At most 50 source selections are supported.');
  for (final item in sourceSelections.entries) {
    final file = File(p.join(root, item.key));
    if (p.isAbsolute(item.key) ||
        p.normalize(item.key) != item.key ||
        item.key.split(p.separator).contains('..') ||
        !file.existsSync() ||
        !p.isWithin(root, file.resolveSymbolicLinksSync())) {
      throw ArgumentError(
        'Selections require existing normalized project-local paths.',
      );
    }
    final identity = file.resolveSymbolicLinksSync();
    if (bridges.containsKey(identity) || selections.containsKey(identity)) {
      throw ArgumentError(
        'Source selection conflicts with an adapter or duplicate identity.',
      );
    }
    selections[identity] = item.value;
  }
  final usedSelections = <String, NativeSourceSelection>{};
  final usedPackages = <String>{};
  final projectPackages = File(p.join(root, '.dart_tool/package_config.json'));
  final compilerPackages = await Isolate.packageConfig;
  final packagesUri = projectPackages.existsSync()
      ? projectPackages.absolute.uri
      : compilerPackages;
  final riverpodUri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_dom_compiler/src/runtime/riverpod_dom.dart'),
  );
  var checkedRiverpod = false;
  void checkRiverpod() {
    if (checkedRiverpod) return;
    if (packagesUri == null)
      throw StateError('Riverpod package configuration is missing.');
    final config =
        jsonDecode(File.fromUri(packagesUri).readAsStringSync()) as Map;
    final entries = config['packages'] as List;
    final entry = entries
        .cast<Map>()
        .where((item) => item['name'] == 'riverpod')
        .firstOrNull;
    if (entry == null)
      throw UnsupportedError(
        'Native consumers require riverpod 2.6.1 in the package configuration.',
      );
    final packageRoot = Directory.fromUri(
      packagesUri.resolve(entry['rootUri'] as String),
    ).uri;
    final version =
        (loadYaml(
              File.fromUri(
                packageRoot.resolve('pubspec.yaml'),
              ).readAsStringSync(),
            )
            as YamlMap)['version'];
    if (version != '2.6.1')
      throw UnsupportedError(
        'Native consumers currently support riverpod 2.6.1 only.',
      );
    checkedRiverpod = true;
  }

  final usedBridges = <String>[];
  final temporary = Directory.systemTemp.createTempSync('flutter-dom-runtime-');
  final seen = <String, String>{};
  // Resolve the package library rather than depending on the caller's cwd.
  final runtimeUri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_dom_compiler/src/runtime/flutter_dom.dart'),
  );
  if (runtimeUri == null)
    throw StateError('DOM runtime package could not be resolved.');
  final foundationUri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_dom_compiler/src/runtime/foundation_dom.dart'),
  );
  if (foundationUri == null)
    throw StateError('Foundation runtime package could not be resolved.');
  final servicesUri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_dom_compiler/src/runtime/services_dom.dart'),
  );
  if (servicesUri == null)
    throw StateError('Services runtime package could not be resolved.');
  final widgetsUri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_dom_compiler/src/runtime/widgets_dom.dart'),
  );
  if (widgetsUri == null)
    throw StateError('Widgets runtime package could not be resolved.');
  // Resolve annotation metadata from the compiler package, even for fixtures
  // without a project package configuration. Keep widget identities shared.
  final metaUri = await Isolate.resolvePackageUri(
    Uri.parse('package:meta/meta.dart'),
  );
  if (metaUri == null)
    throw StateError('Annotation metadata could not be resolved.');
  Uri annotatedFacade(String name, Uri runtime) {
    final file = File(p.join(temporary.path, '$name.dart'));
    file.writeAsStringSync(
      "export '$runtime';\nexport '$metaUri' show immutable, visibleForTesting;\n",
    );
    return file.uri;
  }

  final materialFacade = annotatedFacade('material', runtimeUri);
  final widgetsFacade = annotatedFacade('widgets', widgetsUri);
  final foundationFacade = annotatedFacade('foundation', foundationUri);
  const webEnvironment = {
    'dart.library.js_interop': true,
    'dart.library.html': true,
    'dart.library.js': true,
    'dart.library.io': false,
    'dart.library.ffi': false,
  };
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
      final implementation = bridges[path] ?? input;
      if (bridges.containsKey(path))
        usedBridges.add(p.relative(path, from: root));
      var text = implementation.readAsStringSync();
      final selection = selections[path];
      if (selection != null) {
        text = selectNativeSource(text, selection);
        usedSelections[p.relative(path, from: root)] = selection;
      }
      final parsed = parseString(content: text, throwIfDiagnostics: false);
      if (parsed.errors.isNotEmpty)
        throw ArgumentError('Native source contains parser errors.');
      final edits = <(int, int, String)>[];
      for (final directive in parsed.unit.directives) {
        if (directive is! UriBasedDirective) continue;
        Never unsupported(String message) => throw UnsupportedError(
          '$message at ${p.relative(path, from: root)}:${parsed.lineInfo.getLocation(directive.offset).lineNumber}',
        );
        var uri = directive.uri.stringValue;
        if (uri == null) throw ArgumentError('Invalid library URI.');
        final configurations = directive is ImportDirective
            ? directive.configurations
            : directive is ExportDirective
            ? directive.configurations
            : <Configuration>[];
        var selected = false;
        for (final configuration in configurations) {
          final name = configuration.name.toSource();
          if (!webEnvironment.containsKey(name)) {
            unsupported('Unsupported conditional environment: $name');
          }
          final expected = configuration.value?.stringValue ?? 'true';
          if (!selected && '${webEnvironment[name]}' == expected) {
            uri = configuration.uri.stringValue;
            selected = true;
          }
        }
        if (uri == null) throw ArgumentError('Invalid selected library URI.');
        if (configurations.isNotEmpty)
          edits.add((
            configurations.first.offset,
            configurations.last.end - configurations.first.offset,
            '',
          ));
        String? replacement = configurations.isNotEmpty ? uri : null;
        if (packageAdapters.containsKey(uri)) {
          usedPackages.add(uri);
          replacement = Uri.file(packageAdapters[uri]!).toString();
        } else if (uri == 'package:flutter_riverpod/flutter_riverpod.dart') {
          checkRiverpod();
          if (riverpodUri == null)
            throw StateError('Consumer bridge could not be resolved.');
          replacement = riverpodUri.toString();
        } else if (uri == 'package:flutter/material.dart') {
          replacement = materialFacade.toString();
        } else if (uri == 'package:flutter/foundation.dart') {
          replacement = foundationFacade.toString();
        } else if (uri == 'package:flutter/services.dart') {
          replacement = servicesUri.toString();
        } else if (uri == 'package:flutter/widgets.dart') {
          replacement = widgetsFacade.toString();
        } else if (uri.startsWith('package:flutter/') || uri == 'dart:ui') {
          unsupported('Unsupported Flutter/engine import: $uri');
        } else if (!Uri.parse(uri).hasScheme) {
          replacement = Uri.file(
            copy(
              File(
                p.join(
                  p.dirname(implementation.resolveSymbolicLinksSync()),
                  uri,
                ),
              ),
            ),
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
      edits.sort((a, b) => b.$1.compareTo(a.$1));
      for (final edit in edits) {
        rewritten = rewritten.replaceRange(edit.$1, edit.$1 + edit.$2, edit.$3);
      }
      final file = File(destination)..parent.createSync(recursive: true);
      file.writeAsStringSync(rewritten);
      return destination;
    }

    final generated = copy(entry);
    if (usedBridges.length != bridges.length)
      throw ArgumentError(
        'A configured library bridge was not reachable from this entry.',
      );
    if (usedPackages.length != packageAdapters.length)
      throw ArgumentError(
        'A package bridge was not reachable from this entry.',
      );
    if (usedSelections.length != selections.length)
      throw ArgumentError(
        'A source selection was not reachable from this entry.',
      );
    final output = p.join(temporary.path, 'app.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--csp',
      '-Ddart.vm.product=true',
      for (final item in dartDefines.entries) '-D${item.key}=${item.value}',
      '--no-source-maps',
      if (packagesUri != null) '--packages=${File.fromUri(packagesUri).path}',
      '-o',
      output,
      generated,
    ]);
    if (result.exitCode != 0)
      throw StateError(
        'Official Dart compilation failed:\n${result.stdout}${result.stderr}',
      );
    return NativeAppBuild(
      File(output).readAsStringSync(),
      seen.length,
      List.unmodifiable(usedBridges),
      sourceSelections: Map.unmodifiable(usedSelections),
      riverpodConsumers: checkedRiverpod,
      packageAdapters: List.unmodifiable(usedPackages),
    );
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

const nativeAppHost = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Native app</title>
<style>html,body{margin:0;min-height:100%;font-family:system-ui,sans-serif}#app{min-height:100vh}button{font:inherit;cursor:pointer}button:disabled{cursor:default}button:focus-visible{outline:2px solid currentColor;outline-offset:3px}</style>
</head><body><div id="app"></div><script defer src="app.js"></script></body></html>''';
