import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../native_app_builder.dart' show buildNativeApp;

// The tables below mirror the import substitution performed by
// `buildNativeApp` in lib/native_app_builder.dart. They are read-only copies
// so that inspection can explain a build without running it; when the builder
// gains a bridge or facade, add it here as well.
// `test/runtime_inspection_test.dart` fails when a package URI handled by the
// builder is missing from these tables.

/// Flutter libraries (and `dart:ui`) served by the DOM runtime facades.
const runtimeFrameworkFacades = {
  'dart:ui',
  'package:flutter/material.dart',
  'package:flutter/foundation.dart',
  'package:flutter/services.dart',
  'package:flutter/widgets.dart',
  'package:flutter/painting.dart',
  'package:flutter/animation.dart',
  'package:flutter/scheduler.dart',
  'package:flutter/gestures.dart',
  'package:flutter/rendering.dart',
};

/// Package library URIs replaced by built-in runtime implementations,
/// mapped to the package name reported as the bridge.
const runtimeBuiltInBridges = {
  'package:fl_chart/fl_chart.dart': 'fl_chart',
  'package:go_router/go_router.dart': 'go_router',
  'package:flutter_riverpod/flutter_riverpod.dart': 'flutter_riverpod',
  'package:flutter_localizations/flutter_localizations.dart':
      'flutter_localizations',
  'package:flutter_markdown/flutter_markdown.dart': 'flutter_markdown',
  'package:flutter_markdown_plus/flutter_markdown_plus.dart':
      'flutter_markdown_plus',
  // Plugin bridges (`pluginBridges` in the builder).
  'package:shared_preferences/shared_preferences.dart': 'shared_preferences',
  'package:url_launcher/url_launcher.dart': 'url_launcher',
  'package:url_launcher/url_launcher_string.dart': 'url_launcher',
  'package:url_launcher/link.dart': 'url_launcher',
  'package:flutter_map/flutter_map.dart': 'flutter_map',
};

/// `dart:` libraries dart2js rejects at compile time.
const _webUnavailableLibraries = {'dart:ffi', 'dart:mirrors', 'dart:cli'};

/// `dart:` libraries dart2js accepts but whose APIs throw in a browser.
const _webLimitedLibraries = {'dart:io', 'dart:isolate'};

/// The fixed web environment used by the builder for conditional imports.
const _webEnvironment = {
  'dart.library.js_interop': true,
  'dart.library.html': true,
  'dart.library.js': true,
  'dart.library.io': false,
  'dart.library.ffi': false,
};

const _widgetBases = {
  'StatelessWidget',
  'StatefulWidget',
  'ConsumerWidget',
  'ConsumerStatefulWidget',
  'HookWidget',
  'HookConsumerWidget',
};

const _libraryLimit = 5000;

/// Inspects the library graph `buildNativeApp` would compile for an entry:
/// which libraries are original source compiled as-is, which imports are
/// replaced by runtime facades or bridges, which third-party packages are
/// recompiled against the runtime, and which imports block the build.
///
/// No source is executed or modified. With [compile], the actual build is
/// attempted and the first official compiler errors are reported.
Future<Map<String, Object?>> inspectDartRuntime(
  String projectPath, {
  String source = 'lib/main.dart',
  Map<String, String> libraryBridges = const {},
  Map<String, String> packageBridges = const {},
  Map<String, String> dartDefines = const {},
  bool compile = false,
}) async {
  final root = Directory(p.absolute(projectPath)).resolveSymbolicLinksSync();
  final entry = File(p.join(root, source));
  if (!entry.existsSync())
    throw ArgumentError('Dart runtime inspection entry is missing: $source');

  // Package configuration, resolved the same way as the builder.
  final projectConfig = File(p.join(root, '.dart_tool/package_config.json'));
  final packagesUri = projectConfig.existsSync()
      ? projectConfig.absolute.uri
      : await Isolate.packageConfig;
  final packageLibs = <String, String>{};
  final packageRoots = <String, Uri>{};
  if (packagesUri != null) {
    final config =
        jsonDecode(File.fromUri(packagesUri).readAsStringSync()) as Map;
    for (final item in (config['packages'] as List).cast<Map>()) {
      final rootUri = item['rootUri'] as String;
      final rootDir = packagesUri.resolve(
        rootUri.endsWith('/') ? rootUri : '$rootUri/',
      );
      packageRoots[item['name'] as String] = rootDir;
      packageLibs[item['name'] as String] = p.normalize(
        Directory.fromUri(
          rootDir.resolve((item['packageUri'] as String?) ?? 'lib/'),
        ).path,
      );
    }
  }

  final bridges = <String, String>{
    for (final item in libraryBridges.entries)
      File(p.join(root, item.key)).absolute.resolveSymbolicLinksSync():
          item.value,
  };

  String? riverpodProblem() {
    final rootDir = packageRoots['riverpod'];
    if (rootDir == null)
      return 'flutter_riverpod is bridged only with riverpod 2.6.1 in the package configuration.';
    final pubspec = File.fromUri(rootDir.resolve('pubspec.yaml'));
    final version = pubspec.existsSync()
        ? (loadYaml(pubspec.readAsStringSync()) as YamlMap)['version']
        : null;
    return version == '2.6.1'
        ? null
        : 'flutter_riverpod is bridged only with riverpod 2.6.1 (found ${version ?? 'unknown'}).';
  }

  String? packageOf(String path) {
    for (final item in packageLibs.entries) {
      if (p.isWithin(item.value, path)) return item.key;
    }
    return null;
  }

  // Project files are labelled relative to the project; package files with
  // their package URI.
  final projectPackage = packageRoots.entries
      .where(
        (e) => p.equals(p.normalize(Directory.fromUri(e.value).path), root),
      )
      .map((e) => e.key)
      .firstOrNull;
  String label(String path) {
    final package = packageOf(path);
    if (package != null && package != projectPackage)
      return 'package:$package/${p.posix.joinAll(p.split(p.relative(path, from: packageLibs[package]!)))}';
    if (p.isWithin(root, path) || p.equals(root, path))
      return p.posix.joinAll(p.split(p.relative(path, from: root)));
    return path;
  }

  File? packageFile(String uri) {
    final parsed = Uri.parse(uri);
    if (parsed.scheme != 'package' || parsed.pathSegments.length < 2)
      return null;
    final lib = packageLibs[parsed.pathSegments.first];
    if (lib == null) return null;
    final file = File(p.joinAll([lib, ...parsed.pathSegments.skip(1)]));
    return file.existsSync() ? file : null;
  }

  // Selected web URI of a directive, or null with the unknown condition name.
  (String?, String?) selectUri(UriBasedDirective directive) {
    var uri = directive.uri.stringValue;
    final configurations = directive is ImportDirective
        ? directive.configurations
        : directive is ExportDirective
        ? directive.configurations
        : <Configuration>[];
    var selected = false;
    for (final configuration in configurations) {
      final name = configuration.name.toSource();
      if (!_webEnvironment.containsKey(name)) return (null, name);
      final expected = configuration.value?.stringValue ?? 'true';
      if (!selected && '${_webEnvironment[name]}' == expected) {
        uri = configuration.uri.stringValue;
        selected = true;
      }
    }
    return (uri, null);
  }

  bool replaced(String uri) =>
      packageBridges.containsKey(uri) ||
      uri == 'dart:ui' ||
      uri.startsWith('package:flutter/') ||
      runtimeBuiltInBridges.containsKey(uri);

  final parsedCache = <String, CompilationUnit?>{};
  CompilationUnit? parse(String path) => parsedCache.putIfAbsent(path, () {
    final result = parseString(
      content: File(path).readAsStringSync(),
      throwIfDiagnostics: false,
    );
    return result.errors.isEmpty ? result.unit : null;
  });

  // Whether a package library reaches Flutter, as decided by the builder.
  final facts = <String, (bool, List<String>)>{};
  (bool, List<String>) factsFor(String path) {
    final cached = facts[path];
    if (cached != null) return cached;
    facts[path] = (false, const []);
    final unit = parseString(
      content: File(path).readAsStringSync(),
      throwIfDiagnostics: false,
    ).unit;
    var direct = false;
    final deps = <String>[];
    for (final directive in unit.directives.whereType<UriBasedDirective>()) {
      final (uri, _) = selectUri(directive);
      if (uri == null) continue;
      if (uri == 'dart:ui' || uri.startsWith('package:flutter/')) {
        direct = true;
        continue;
      }
      if (replaced(uri)) continue;
      final file = Uri.parse(uri).hasScheme
          ? packageFile(uri)
          : File(p.normalize(p.join(p.dirname(path), uri)));
      if (file != null && file.existsSync()) deps.add(file.path);
    }
    return facts[path] = (direct, deps);
  }

  final reach = <String, bool>{};
  bool reachesFlutter(String path) {
    final known = reach[path];
    if (known != null) return known;
    final graph = <String>{};
    final pending = [path];
    while (pending.isNotEmpty) {
      final next = pending.removeLast();
      if (!graph.add(next) || reach.containsKey(next)) continue;
      pending.addAll(factsFor(next).$2);
    }
    final result = {
      for (final node in graph) node: reach[node] ?? factsFor(node).$1,
    };
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in graph) {
        if (result[node]!) continue;
        if (factsFor(node).$2.any((dep) => result[dep] ?? false)) {
          result[node] = true;
          changed = true;
        }
      }
    }
    reach.addAll(result);
    return result[path]!;
  }

  final libraries = <String, Map<String, Object?>>{};
  final parents = <String, String?>{};
  final replacements = <String, Map<String, Object?>>{};
  final unsupported = <Map<String, Object?>>[];
  final rewrittenPackages = <String, Set<String>>{};
  final purePackages = <String>{};
  var truncated = false;

  List<String> chain(String from, [String? last]) {
    final result = <String>[if (last != null) last];
    String? current = from;
    while (current != null) {
      result.add(current);
      current = parents[current];
    }
    return result.reversed.toList();
  }

  void addReplacement(String uri, String kind, String bridge, String by) {
    final record = replacements.putIfAbsent(
      uri,
      () => {'import': uri, 'kind': kind, 'bridge': bridge, 'importedBy': []},
    );
    final importers = record['importedBy'] as List;
    if (!importers.contains(by)) importers.add(by);
  }

  void addUnsupported(
    String library,
    int? line,
    String feature,
    String severity,
    String reason,
  ) {
    unsupported.add({
      'feature': feature,
      'severity': severity,
      'reason': reason,
      'library': library,
      if (line != null) 'line': line,
      'chain': chain(library, feature),
    });
    if (severity == 'blocking') {
      final record = libraries[library];
      if (record != null) {
        record['status'] = 'blocked';
        (record['blockers'] as List).add(feature);
      }
    }
  }

  // Pure Dart libraries (no Flutter) compiled unchanged by dart2js: scan only
  // for web-unavailable platform libraries.
  final pureSeen = <String>{};
  void scanPure(String path, String parent) {
    final pending = [(path, parent)];
    while (pending.isNotEmpty) {
      final (next, from) = pending.removeLast();
      if (!pureSeen.add(next)) continue;
      if (pureSeen.length + libraries.length > _libraryLimit) {
        truncated = true;
        return;
      }
      final package = packageOf(next);
      if (package != null && package != projectPackage)
        purePackages.add(package);
      final name = label(next);
      parents.putIfAbsent(name, () => from);
      final unit = parse(next);
      if (unit == null) continue;
      for (final directive in unit.directives.whereType<UriBasedDirective>()) {
        final (uri, _) = selectUri(directive);
        if (uri == null) continue;
        if (_webUnavailableLibraries.contains(uri) ||
            _webLimitedLibraries.contains(uri)) {
          final blocking = _webUnavailableLibraries.contains(uri);
          unsupported.add({
            'feature': uri,
            'severity': blocking ? 'blocking' : 'runtime-risk',
            'reason': blocking
                ? 'dart2js rejects $uri.'
                : '$uri compiles for the web, but its APIs throw in a browser.',
            'library': name,
            'chain': chain(name, uri),
          });
          continue;
        }
        if (uri.startsWith('dart:') || replaced(uri)) continue;
        final file = Uri.parse(uri).hasScheme
            ? packageFile(uri)
            : File(p.normalize(p.join(p.dirname(next), uri)));
        if (file != null && file.existsSync()) pending.add((file.path, name));
      }
    }
  }

  void visit(String path, String? parent, {String? package}) {
    final name = label(path);
    if (libraries.containsKey(name)) return;
    if (libraries.length + pureSeen.length >= _libraryLimit) {
      truncated = true;
      return;
    }
    parents[name] = parent;
    final bridge = bridges[path];
    final origin = package == null ? 'project' : 'package';
    final record = libraries[name] = {
      'library': name,
      'origin': origin,
      if (package != null) 'package': package,
      'status': bridge != null
          ? 'replaced-by-library-bridge'
          : package == null
          ? 'original'
          : 'rewritten-package',
      'widgets': <String>[],
      'blockers': <String>[],
    };
    if (package != null)
      rewrittenPackages.putIfAbsent(package, () => {}).add(name);
    if (bridge != null) {
      addReplacement(name, 'library-bridge', label(bridge), parent ?? name);
    }
    final implementation = bridge ?? path;
    final parsed = parseString(
      content: File(implementation).readAsStringSync(),
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      addUnsupported(
        name,
        parsed.lineInfo.getLocation(parsed.errors.first.offset).lineNumber,
        'parser error',
        'blocking',
        parsed.errors.first.message,
      );
      return;
    }
    for (final node in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      final base = node.extendsClause?.superclass.name2.lexeme;
      if (_widgetBases.contains(base))
        (record['widgets'] as List).add(node.name.lexeme);
    }
    for (final directive
        in parsed.unit.directives.whereType<UriBasedDirective>()) {
      final line = parsed.lineInfo.getLocation(directive.offset).lineNumber;
      final (uri, unknownCondition) = selectUri(directive);
      if (unknownCondition != null) {
        addUnsupported(
          name,
          line,
          'if ($unknownCondition)',
          'blocking',
          'Unsupported conditional environment: $unknownCondition.',
        );
        continue;
      }
      if (uri == null) continue;
      if (packageBridges.containsKey(uri)) {
        addReplacement(
          uri,
          'package-adapter',
          label(packageBridges[uri]!),
          name,
        );
      } else if (runtimeBuiltInBridges.containsKey(uri)) {
        final problem = uri == 'package:flutter_riverpod/flutter_riverpod.dart'
            ? riverpodProblem()
            : null;
        if (problem != null) {
          addUnsupported(name, line, uri, 'blocking', problem);
        } else {
          addReplacement(
            uri,
            'built-in-bridge',
            runtimeBuiltInBridges[uri]!,
            name,
          );
        }
      } else if (runtimeFrameworkFacades.contains(uri)) {
        addReplacement(uri, 'flutter-facade', 'flutter_dom runtime', name);
      } else if (uri.startsWith('package:flutter/')) {
        addUnsupported(
          name,
          line,
          uri,
          'blocking',
          'The DOM runtime has no facade for this Flutter/engine library.',
        );
      } else if (_webUnavailableLibraries.contains(uri)) {
        addUnsupported(name, line, uri, 'blocking', 'dart2js rejects $uri.');
      } else if (_webLimitedLibraries.contains(uri)) {
        addUnsupported(
          name,
          line,
          uri,
          'runtime-risk',
          '$uri compiles for the web, but its APIs throw in a browser.',
        );
      } else if (uri.startsWith('dart:')) {
        continue;
      } else if (!Uri.parse(uri).hasScheme) {
        final target = p.normalize(p.join(p.dirname(implementation), uri));
        if (!File(target).existsSync()) {
          addUnsupported(
            name,
            line,
            uri,
            'blocking',
            'Imported file is missing.',
          );
        } else if (package != null &&
            directive is! PartDirective &&
            !reachesFlutter(target)) {
          scanPure(target, name);
        } else {
          visit(
            File(target).resolveSymbolicLinksSync(),
            name,
            package: package,
          );
        }
      } else {
        final scheme = Uri.parse(uri).scheme;
        if (scheme != 'package') continue;
        final packageName = Uri.parse(uri).pathSegments.first;
        final file = packageFile(uri);
        if (file == null) {
          addUnsupported(
            name,
            line,
            uri,
            'blocking',
            packageLibs.containsKey(packageName)
                ? 'Library is missing from package $packageName.'
                : 'Package $packageName is not in the package configuration; run `flutter pub get`.',
          );
          continue;
        }
        final resolved = file.resolveSymbolicLinksSync();
        if (packageName == projectPackage) {
          // The project's own package: original source.
          visit(resolved, name);
        } else if (reachesFlutter(file.path)) {
          visit(resolved, name, package: packageName);
        } else {
          scanPure(file.path, name);
        }
      }
    }
  }

  visit(entry.resolveSymbolicLinksSync(), null);

  final records = libraries.values.toList()
    ..sort((a, b) {
      final byOrigin = (a['origin'] as String).compareTo(b['origin'] as String);
      return byOrigin != 0
          ? -byOrigin
          : (a['library'] as String).compareTo(b['library'] as String);
    });
  final blocking = unsupported
      .where((u) => u['severity'] == 'blocking')
      .toList();
  final original = records
      .where(
        (r) =>
            r['origin'] == 'project' &&
            r['status'] != 'replaced-by-library-bridge',
      )
      .toList();
  final replacementList = replacements.values.toList()
    ..sort((a, b) {
      final byKind = (a['kind'] as String).compareTo(b['kind'] as String);
      return byKind != 0
          ? byKind
          : (a['import'] as String).compareTo(b['import'] as String);
    });
  final report = <String, Object?>{
    'target': 'dart-runtime',
    'label': 'DOM runtime (--dart-runtime): entry dependency graph',
    'entry': p.posix.joinAll(p.split(source)),
    'packageConfiguration': projectConfig.existsSync()
        ? 'project'
        : 'compiler-fallback',
    'status': blocking.isNotEmpty
        ? 'blocked'
        : truncated
        ? 'incomplete'
        : 'graph-ready',
    'summary': {
      'libraries': libraries.length,
      'originalLibraries': original.length,
      'blockedLibraries': records.where((r) => r['status'] == 'blocked').length,
      'originalWidgets': original.fold<int>(
        0,
        (sum, r) => sum + (r['widgets'] as List).length,
      ),
      'libraryBridges': records
          .where((r) => r['status'] == 'replaced-by-library-bridge')
          .length,
      'builtInBridges': replacementList
          .where((r) => r['kind'] == 'built-in-bridge')
          .map((r) => r['bridge'])
          .toSet()
          .length,
      'rewrittenPackages': rewrittenPackages.length,
      'purePackages': purePackages.length,
      'blockingImports': blocking.length,
      'runtimeRisks': unsupported.length - blocking.length,
    },
    'libraries': records,
    'original': [
      for (final record in original)
        {
          'library': record['library'],
          'status': record['status'],
          'widgets': record['widgets'],
          if ((record['blockers'] as List).isNotEmpty)
            'blockers': record['blockers'],
        },
    ],
    'replacements': replacementList,
    'rewrittenPackages': {
      for (final name in rewrittenPackages.keys.toList()..sort())
        name: rewrittenPackages[name]!.toList()..sort(),
    },
    'purePackages': purePackages.toList()..sort(),
    'unsupported': unsupported,
    'truncated': truncated,
    'compile': compile
        ? await _compile(
            root,
            source,
            libraryBridges,
            packageBridges,
            dartDefines,
          )
        : {
            'attempted': false,
            'hint':
                'Pass --compile to run the official compiler; graph readiness does not prove every API is implemented.',
          },
    'definition':
        'Every library the --dart-runtime build would compile from this entry, '
        'classified by how its imports reach the browser: original project source compiled as-is, '
        'Flutter libraries served by runtime facades, packages replaced by built-in bridges, '
        'third-party packages recompiled unchanged against the runtime, and imports without a runtime path. '
        'Graph readiness is an import-level check; APIs the runtime facades do not implement are reported only by the compile check.',
    'notes': [
      'Runtime-rendered DOM is created by JavaScript in the browser. It has no prerendered HTML, '
          'so it has no SEO or first-paint advantage over Flutter web unless the page is prerendered separately.',
      'Original widgets are not checked individually: they run with real constructor arguments and state, as in Flutter.',
      'A replaced import is an explicit substitute implementation, not translated package code.',
    ],
  };
  return report;
}

Future<Map<String, Object?>> _compile(
  String root,
  String source,
  Map<String, String> libraryBridges,
  Map<String, String> packageBridges,
  Map<String, String> dartDefines,
) async {
  final watch = Stopwatch()..start();
  try {
    final app = await buildNativeApp(
      root,
      source,
      libraryBridges: libraryBridges,
      packageBridges: packageBridges,
      dartDefines: dartDefines,
      treeShakeIcons: false,
    );
    return {
      'attempted': true,
      'succeeded': true,
      'seconds': watch.elapsed.inMilliseconds / 1000,
      'libraries': app.libraries,
      'javascriptBytes': utf8.encode(app.javascript).length,
      'builtInBridges': app.builtInBridges,
      'rewrittenPackages': app.rewrittenPackages,
    };
  } on Object catch (error) {
    return {
      'attempted': true,
      'succeeded': false,
      'seconds': watch.elapsed.inMilliseconds / 1000,
      'errors': compileErrors('$error'),
    };
  }
}

/// The first official compiler errors in [output], with temporary build
/// paths mapped back to project paths and package URIs.
List<Map<String, Object?>> compileErrors(String output, {int limit = 10}) {
  String clean(String text) => text
      .replaceAll(
        RegExp(r'(?:file://)?\S*flutter-dom-runtime-[^/\\\s]+[/\\]source[/\\]'),
        '',
      )
      .replaceAllMapped(
        RegExp(
          r'(?:file://)?\S*flutter-dom-runtime-[^/\\\s]+[/\\]packages[/\\]([^/\\\s]+)[/\\]',
        ),
        (m) => 'package:${m[1]}/',
      )
      .replaceAll(
        RegExp(r'(?:file://)?\S*flutter-dom-runtime-[^/\\\s]+[/\\]'),
        '(runtime facade) ',
      );
  final lines = output.split('\n');
  final errors = <Map<String, Object?>>[];
  for (var i = 0; i < lines.length && errors.length < limit; i++) {
    final line = lines[i];
    if (!line.startsWith('Error: ')) continue;
    final location = i > 0
        ? RegExp(r'^(.*):(\d+):(\d+):$').firstMatch(lines[i - 1].trim())
        : null;
    errors.add({
      if (location != null)
        'location': clean('${location[1]}:${location[2]}:${location[3]}'),
      'message': clean(line.substring('Error: '.length)),
    });
  }
  if (errors.isEmpty) {
    final message = output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(3)
        .join(' ');
    errors.add({'message': clean(message)});
  }
  return errors;
}
