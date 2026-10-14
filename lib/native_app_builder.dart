library;

export 'src/runtime/source_selection.dart' show NativeSourceSelection;
import 'src/runtime/source_selection.dart';
import 'src/font_subset.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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
    this.assets = const {},
    this.fontFaces = const [],
    this.usesMaterialIcons = false,
    this.materialIconsFont,
    this.generatedAssets = const {},
    this.iconCodePoints,
  });

  /// Output-relative paths of files generated during the build, such as a
  /// subset icon font.
  final Map<String, Uint8List> generatedAssets;

  /// Material icon code points shipped in a subset font; null when the full
  /// font is shipped (tree shaking disabled or usage not statically known).
  final Set<int>? iconCodePoints;

  /// Output-relative asset paths mapped to absolute source files.
  final Map<String, String> assets;
  final List<NativeFontFace> fontFaces;

  /// Whether compiled code retains Material icon metadata.
  final bool usesMaterialIcons;

  /// The resolved MaterialIcons font, when one was found or supplied.
  final String? materialIconsFont;
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
  String? materialIconsFont,
  bool treeShakeIcons = true,
}) async {
  final root = Directory(project).resolveSymbolicLinksSync();
  final resources = readNativeResources(root);
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
  final uiUri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_dom_compiler/src/runtime/ui_dom.dart'),
  );
  if (uiUri == null) throw StateError('dart:ui facade could not be resolved.');
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
        } else if (uri == 'dart:ui') {
          replacement = uiUri.toString();
        } else if (uri == 'package:flutter/widgets.dart' ||
            uri == 'package:flutter/painting.dart') {
          replacement = widgetsFacade.toString();
        } else if (uri.startsWith('package:flutter/')) {
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
    final javascript = File(output).readAsStringSync();
    // dart2js drops unused constants, so the family name survives only when
    // icon metadata is reachable from the compiled program.
    final usesIcons = javascript.contains('MaterialIcons');
    final iconFont = usesIcons
        ? findMaterialIconsFont(materialIconsFont)
        : null;
    Set<int>? iconCodes;
    Uint8List? subsetFont;
    if (iconFont != null && treeShakeIcons) {
      iconCodes = materialIconCodePoints(javascript, [
        for (final file in seen.values) File(file).readAsStringSync(),
      ], await _materialIconNames());
      if (iconCodes != null) {
        try {
          subsetFont = subsetCffFont(
            File(iconFont).readAsBytesSync(),
            iconCodes,
          );
        } on FontSubsetException {
          iconCodes = null;
        }
      }
    }
    return NativeAppBuild(
      javascript,
      seen.length,
      List.unmodifiable(usedBridges),
      sourceSelections: Map.unmodifiable(usedSelections),
      riverpodConsumers: checkedRiverpod,
      packageAdapters: List.unmodifiable(usedPackages),
      assets: Map.unmodifiable({
        ...resources.assets,
        if (iconFont != null && subsetFont == null)
          _materialIconsPath: iconFont,
      }),
      generatedAssets: Map.unmodifiable({
        if (subsetFont != null) _materialIconsPath: subsetFont,
      }),
      iconCodePoints: subsetFont == null ? null : Set.unmodifiable(iconCodes!),
      fontFaces: List.unmodifiable([
        if (iconFont != null)
          const NativeFontFace('MaterialIcons', _materialIconsPath),
        ...resources.fontFaces,
      ]),
      usesMaterialIcons: usesIcons,
      materialIconsFont: iconFont,
    );
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

const _materialIconsPath = 'assets/fonts/MaterialIcons-Regular.otf';

/// Icons the runtime itself may render (back, close, menu, chip delete,
/// expansion chevrons).
const _runtimeIcons = [
  'arrow_back',
  'close',
  'menu',
  'cancel_rounded',
  'expand_more',
  'expand_less',
];

Map<String, int>? _iconNameCache;

Future<Map<String, int>> _materialIconNames() async {
  if (_iconNameCache != null) return _iconNameCache!;
  final uri = await Isolate.resolvePackageUri(
    Uri.parse(
      'package:flutter_dom_compiler/src/runtime/material_icons_metadata.dart',
    ),
  );
  if (uri == null) throw StateError('Icon metadata could not be resolved.');
  final source = File.fromUri(uri).readAsStringSync();
  final names = <String, int>{
    for (final match in RegExp(
      r'static const (\w+) = IconData\(\s*(0x[0-9a-fA-F]+)',
    ).allMatches(source))
      match.group(1)!: int.parse(match.group(2)!),
  };
  for (final match in RegExp(
    r'IconData get (\w+) => Icons\.(\w+);',
  ).allMatches(source)) {
    final code = names[match.group(2)!];
    if (code != null) names['adaptive.${match.group(1)}'] = code;
  }
  return _iconNameCache = names;
}

/// The Material icon code points a compiled app can render, or null when
/// they cannot be determined statically (the full font is then shipped).
///
/// Icon names referenced in the copied project sources identify the
/// minified IconData constructor in the dart2js output; every literal code
/// point it constructs is kept, which also covers icons used by packages.
/// Non-literal construction (computed code points) disables subsetting.
Set<int>? materialIconCodePoints(
  String javascript,
  Iterable<String> sources,
  Map<String, int> names,
) {
  final referenced = <int>{for (final name in _runtimeIcons) ?names[name]};
  final usage = RegExp(r'\bIcons\.((?:adaptive\.)?\w+)');
  final literal = RegExp(
    r'IconData\(\s*(0x[0-9a-fA-F]+|\d+)\s*,\s*fontFamily:\s*[\x27"]MaterialIcons[\x27"]',
  );
  for (final source in sources) {
    for (final match in usage.allMatches(source)) {
      final code = names[match.group(1)!];
      if (code != null) referenced.add(code);
    }
    for (final match in literal.allMatches(source)) {
      referenced.add(int.parse(match.group(1)!));
    }
  }
  final constructions = RegExp(r'new ([\w$.]+)\((\d+),');
  final byClass = <String, Set<int>>{};
  for (final match in constructions.allMatches(javascript)) {
    byClass
        .putIfAbsent(match.group(1)!, () => {})
        .add(int.parse(match.group(2)!));
  }
  final iconClasses = [
    for (final entry in byClass.entries)
      if (entry.value.any(referenced.contains) &&
          entry.value.every((code) => code >= 0xe000 && code <= 0x10ffff))
        entry.key,
  ];
  if (iconClasses.length != 1) return null;
  final iconClass = RegExp.escape(iconClasses.single);
  if (RegExp('new $iconClass\\((?!\\d+,)').hasMatch(javascript)) return null;
  return {...byClass[iconClasses.single]!, ...referenced};
}

class NativeFontFace {
  const NativeFontFace(this.family, this.path, {this.weight, this.style});
  final String family;

  /// Output-relative URL path of the font file.
  final String path;
  final int? weight;
  final String? style;
}

class NativeResources {
  NativeResources(this.assets, this.fontFaces, this.usesMaterialDesign);
  final Map<String, String> assets;
  final List<NativeFontFace> fontFaces;
  final bool usesMaterialDesign;
}

final _safeFamily = RegExp(r'^[A-Za-z0-9 _./-]+$');

/// Reads `flutter: assets/fonts/uses-material-design` from the project
/// pubspec. Assets keep Flutter web's `assets/<key>` URL layout; directory
/// entries include their direct files, as in Flutter.
NativeResources readNativeResources(String root) {
  final pubspec = File(p.join(root, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return NativeResources(const {}, const [], false);
  final yaml = loadYaml(pubspec.readAsStringSync());
  final flutter = yaml is YamlMap ? yaml['flutter'] : null;
  if (flutter is! YamlMap) return NativeResources(const {}, const [], false);
  final assets = <String, String>{};
  void add(String key) {
    final normalized = p.posix.normalize(key);
    if (p.posix.isAbsolute(normalized) || normalized.split('/').contains('..'))
      throw ArgumentError('Asset paths must stay within the project: $key');
    final file = File(p.join(root, normalized));
    if (!file.existsSync() ||
        !p.isWithin(root, file.resolveSymbolicLinksSync()))
      throw ArgumentError('Declared asset is missing: $key');
    assets['assets/$normalized'] = file.resolveSymbolicLinksSync();
  }

  final declared = flutter['assets'];
  if (declared is YamlList) {
    for (final item in declared) {
      final key = item is YamlMap ? item['path'] : item;
      if (key is! String) throw ArgumentError('Invalid asset declaration.');
      if (key.endsWith('/')) {
        final directory = Directory(p.join(root, key));
        if (!directory.existsSync() ||
            !p.isWithin(root, directory.resolveSymbolicLinksSync()))
          throw ArgumentError('Declared asset directory is missing: $key');
        for (final entity
            in directory.listSync()..sort((a, b) => a.path.compareTo(b.path))) {
          if (entity is File) add(p.posix.join(key, p.basename(entity.path)));
        }
      } else {
        add(key);
      }
    }
  }
  final faces = <NativeFontFace>[];
  final fonts = flutter['fonts'];
  if (fonts is YamlList) {
    for (final family in fonts) {
      final name = family is YamlMap ? family['family'] : null;
      final files = family is YamlMap ? family['fonts'] : null;
      if (name is! String || !_safeFamily.hasMatch(name) || files is! YamlList)
        throw ArgumentError('Invalid font family declaration.');
      for (final font in files) {
        final asset = font is YamlMap ? font['asset'] : null;
        if (asset is! String) throw ArgumentError('Invalid font asset.');
        add(asset);
        final weight = font['weight'];
        final style = font['style'];
        if (weight != null && (weight is! int || weight < 100 || weight > 900))
          throw ArgumentError('Invalid font weight for $name.');
        if (style != null && style != 'normal' && style != 'italic')
          throw ArgumentError('Invalid font style for $name.');
        faces.add(
          NativeFontFace(
            name,
            'assets/${p.posix.normalize(asset)}',
            weight: weight as int?,
            style: style as String?,
          ),
        );
      }
    }
  }
  return NativeResources(
    assets,
    faces,
    flutter['uses-material-design'] == true,
  );
}

/// Locates Flutter's MaterialIcons font: an explicit path, `FLUTTER_ROOT`,
/// or the SDK containing the `flutter` executable on `PATH`.
String? findMaterialIconsFont([String? explicit]) {
  if (explicit != null) {
    final file = File(explicit);
    if (!file.existsSync())
      throw ArgumentError('Material icon font is missing: $explicit');
    return file.resolveSymbolicLinksSync();
  }
  final roots = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final root?) root,
  ];
  for (final directory in (Platform.environment['PATH'] ?? '').split(
    Platform.isWindows ? ';' : ':',
  )) {
    if (directory.isEmpty) continue;
    final executable = File(
      p.join(directory, Platform.isWindows ? 'flutter.bat' : 'flutter'),
    );
    if (executable.existsSync()) {
      roots.add(p.dirname(p.dirname(executable.resolveSymbolicLinksSync())));
    }
  }
  for (final root in roots) {
    final font = File(
      p.join(
        root,
        'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
    if (font.existsSync()) return font.resolveSymbolicLinksSync();
  }
  return null;
}

const _runtimeCss = '''
html,body{margin:0;min-height:100%;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-text-size-adjust:100%}
#app{min-height:100vh}
button{font:inherit;color:inherit}
.fd-ink{cursor:pointer;-webkit-tap-highlight-color:transparent;outline:none}
.fd-ink:hover{background-image:linear-gradient(var(--fd-hover),var(--fd-hover))}
.fd-ink:active{background-image:linear-gradient(var(--fd-press),var(--fd-press))}
.fd-ink:focus-visible{outline:2px solid var(--fd-focus,currentColor);outline-offset:2px}
.fd-button:disabled{cursor:default;background-image:none;box-shadow:none}
.fd-linear-indeterminate::after{content:"";position:absolute;top:0;bottom:0;left:0;width:40%;background:var(--fd-indicator);animation:fd-linear 1.8s ease-in-out infinite}
@keyframes fd-linear{0%{transform:translateX(-100%)}100%{transform:translateX(250%)}}
.fd-switch{appearance:none;-webkit-appearance:none;position:relative;flex-shrink:0;box-sizing:border-box;width:52px;height:32px;margin:4px;border-radius:16px;border:2px solid var(--fd-off-border);background:var(--fd-off-track);cursor:pointer;transition:background-color .15s}
.fd-switch::before{content:"";position:absolute;top:50%;left:6px;width:16px;height:16px;border-radius:50%;background:var(--fd-off-thumb);transform:translateY(-50%);transition:left .15s,width .15s,height .15s}
.fd-switch:checked{background:var(--fd-on-track);border-color:var(--fd-on-track)}
.fd-switch:checked::before{left:22px;width:24px;height:24px;background:var(--fd-on-thumb)}
.fd-switch:disabled{opacity:.38;cursor:default}
.fd-switch:focus-visible{outline:2px solid var(--fd-on-track);outline-offset:2px}
.fd-spin{animation:fd-spin 1s linear infinite}
@keyframes fd-spin{to{transform:rotate(360deg)}}
@media (prefers-reduced-motion:reduce){.fd-spin,.fd-linear-indeterminate::after{animation-duration:4s}}
''';

/// Stylesheet for runtime interaction states and declared font faces.
String nativeAppCss(List<NativeFontFace> fontFaces) {
  final out = StringBuffer(_runtimeCss);
  for (final face in fontFaces) {
    final format = face.path.endsWith('.otf')
        ? 'opentype'
        : face.path.endsWith('.woff2')
        ? 'woff2'
        : face.path.endsWith('.woff')
        ? 'woff'
        : 'truetype';
    out.writeln(
      '@font-face{font-family:"${face.family}";src:url("${Uri.encodeFull(face.path)}") format("$format");font-display:block;'
      '${face.weight == null ? '' : 'font-weight:${face.weight};'}${face.style == null ? '' : 'font-style:${face.style};'}}',
    );
  }
  return out.toString();
}

const nativeAppHost = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Native app</title>
<link rel="stylesheet" href="app.css">
</head><body><div id="app"></div><script defer src="app.js"></script></body></html>''';

/// Writes the compiled app, host page, stylesheet and copied assets.
List<String> writeNativeApp(NativeAppBuild app, String outputDirectory) {
  final output = Directory(outputDirectory)..createSync(recursive: true);
  final written = <String>['index.html', 'app.css', 'app.js'];
  File(p.join(output.path, 'app.js')).writeAsStringSync(app.javascript);
  File(p.join(output.path, 'index.html')).writeAsStringSync(nativeAppHost);
  File(
    p.join(output.path, 'app.css'),
  ).writeAsStringSync(nativeAppCss(app.fontFaces));
  for (final asset in app.assets.entries) {
    final target = File(p.join(output.path, asset.key));
    target.parent.createSync(recursive: true);
    File(asset.value).copySync(target.path);
    written.add(asset.key);
  }
  for (final asset in app.generatedAssets.entries) {
    final target = File(p.join(output.path, asset.key));
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(asset.value);
    written.add(asset.key);
  }
  return written;
}
