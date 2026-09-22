import 'dart:io';
import 'compiler.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Source inventory plus conservative dry-run coverage of widget entry points.
class ProjectInspector {
  Map<String, Object?> inspect(String projectPath) {
    final project = Directory(p.absolute(projectPath));
    final lib = Directory(p.join(project.path, 'lib'));
    if (!lib.existsSync()) throw ArgumentError('Project must contain lib/.');
    final files =
        lib
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('.dart') &&
                  !f.path.endsWith('.g.dart') &&
                  !f.path.endsWith('.freezed.dart'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final bases = <String, int>{},
        calls = <String, int>{},
        signals = <String, int>{};
    final findings = <Map<String, Object?>>[];
    final entries = <Map<String, Object?>>[];
    var lines = 0, diagnostics = 0;
    for (final file in files) {
      final source = file.readAsStringSync();
      lines += '\n'.allMatches(source).length + (source.endsWith('\n') ? 0 : 1);
      final parsed = parseString(content: source, throwIfDiagnostics: false);
      diagnostics += parsed.errors.length;
      for (final node
          in parsed.unit.declarations.whereType<ClassDeclaration>()) {
        final base = node.extendsClause?.superclass.toSource().split('<').first;
        if (![
          'StatelessWidget',
          'StatefulWidget',
          'ConsumerWidget',
          'ConsumerStatefulWidget',
          'HookWidget',
          'HookConsumerWidget',
        ].contains(base))
          continue;
        String? blocker;
        try {
          FlutterDomCompiler().compile(source, {
            'root': node.name.lexeme,
          }, domOnly: true);
        } on CompileException catch (error) {
          blocker = error.message;
        }
        entries.add({
          'file': p.relative(file.path, from: project.path),
          'line': parsed.lineInfo.getLocation(node.offset).lineNumber,
          'widget': node.name.lexeme,
          'status': blocker == null ? 'native' : 'blocked',
          if (blocker != null) 'blocker': blocker,
        });
      }
      final visitor = _InventoryVisitor();
      parsed.unit.accept(visitor);
      for (final (target, values) in [
        (bases, visitor.bases),
        (calls, visitor.calls),
        (signals, visitor.signals),
      ]) {
        for (final entry in values.entries) {
          target.update(
            entry.key,
            (v) => v + entry.value,
            ifAbsent: () => entry.value,
          );
        }
      }
      if (visitor.signals.isNotEmpty || parsed.errors.isNotEmpty) {
        findings.add({
          'file': p.relative(file.path, from: project.path),
          'signals': _sort(visitor.signals),
          'parserDiagnostics': parsed.errors.length,
        });
      }
    }
    final pubspec = File(p.join(project.path, 'pubspec.yaml'));
    final yaml = pubspec.existsSync()
        ? loadYaml(pubspec.readAsStringSync())
        : null;
    final dependencies = <String>[];
    if (yaml is YamlMap && yaml['dependencies'] is YamlMap) {
      dependencies.addAll(
        (yaml['dependencies'] as YamlMap).keys.map((key) => key.toString()),
      );
      dependencies.sort();
    }
    return {
      'schemaVersion': 2,
      'compatibility': {
        'metric': 'parameterless-widget-entry-dry-run',
        'native': entries.where((e) => e['status'] == 'native').length,
        'total': entries.length,
        'percent': entries.isEmpty
            ? null
            : 100 *
                  entries.where((e) => e['status'] == 'native').length /
                  entries.length,
        'entries': entries,
        'definition':
            'Each recognized direct widget subclass is compiled as a parameterless root, '
            'with no islands or adapters. Required inputs, imported widgets and runtime state '
            'are conservatively blocked. This is compiler acceptance, not verified app behavior.',
      },
      'kind': 'syntax-inventory-not-conversion-coverage',
      'project': project.path,
      'dartFiles': files.length,
      'sourceLines': lines,
      'parserDiagnostics': diagnostics,
      'dependencies': dependencies,
      'classBases': _sort(bases),
      'constructorLikeCalls': _sort(calls),
      'signals': _sort(signals),
      'files': findings,
      'limitations': [
        'Syntactic names are not resolved types; aliases and shadowing can change their meaning.',
        'Counts describe source sites, not rendered instances or reachable runtime code.',
        'Generated files, dependencies and symlinks are excluded.',
        'Recognized names do not imply supported arguments, state, layout or data flow.',
        'All conditional source branches are scanned, including non-web branches.',
        'No source code is executed, modified or uploaded.',
        'Coverage only includes recognized direct widget subclasses; indirect inheritance and aliases are unresolved.',
        'Each entry uses its own source file; required constructor data and imported definitions are not inferred.',
        'The score is not a percentage of screens, pixels, runtime behavior or total app code.',
      ],
    };
  }

  String markdown(Map<String, Object?> report) {
    final out = StringBuffer('# Flutter DOM project inspection\n\n')
      ..writeln(
        'A local syntax inventory, **not a DOM-conversion estimate**.\n',
      )
      ..writeln('- Dart files: ${report['dartFiles']}')
      ..writeln('- Source lines: ${report['sourceLines']}')
      ..writeln('- Parser diagnostics: ${report['parserDiagnostics']}\n');
    final coverage = report['compatibility'] as Map<String, Object?>;
    final percent = coverage['percent'] as num?;
    out.writeln('## Native compiler compatibility\n');
    out.writeln(
      '**${percent?.toStringAsFixed(1) ?? 'N/A'}${percent == null ? '' : '%'}** '
      '(${coverage['native']}/${coverage['total']} widget entry points).\n',
    );
    out.writeln('${coverage['definition']}\n');
    for (final entry in coverage['entries'] as List) {
      out.writeln(
        '- `${entry['file']}:${entry['line']}` **${entry['widget']}**: '
        '${entry['status']}${entry['blocker'] == null ? '' : ' — ${entry['blocker']}'}',
      );
    }
    out.writeln();
    for (final section in ['classBases', 'signals']) {
      out.writeln('## $section\n\n| Signal | Source sites |\n| --- | ---: |');
      for (final entry in (report[section] as Map<String, int>).entries) {
        out.writeln('| `${entry.key}` | ${entry.value} |');
      }
      out.writeln();
    }
    out.writeln(
      '## Dependencies\n\n${(report['dependencies'] as List).join(', ')}\n',
    );
    out.writeln('## Files with review signals\n');
    for (final file in report['files'] as List<Map<String, Object?>>) {
      out.writeln(
        '- `${file['file']}`: ${file['signals']}; parser diagnostics: ${file['parserDiagnostics']}',
      );
    }
    out.writeln('\n## Interpretation limits\n');
    for (final limit in report['limitations'] as List) {
      out.writeln('- $limit');
    }
    return out.toString();
  }
}

Map<String, int> _sort(Map<String, int> values) => Map.fromEntries(
  values.entries.toList()..sort((a, b) {
    final byCount = b.value.compareTo(a.value);
    return byCount == 0 ? a.key.compareTo(b.key) : byCount;
  }),
);

class _InventoryVisitor extends RecursiveAstVisitor<void> {
  final bases = <String, int>{},
      calls = <String, int>{},
      signals = <String, int>{};
  void add(Map<String, int> target, String key) =>
      target.update(key, (v) => v + 1, ifAbsent: () => 1);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final base = node.extendsClause?.superclass.toSource().split('<').first;
    if (base != null) {
      add(bases, base);
      if (base.contains('Consumer')) add(signals, 'riverpod-class');
      if (base == 'StatefulWidget' || base == 'ConsumerStatefulWidget')
        add(signals, 'stateful-widget');
      if (base.contains('Painter') || base.startsWith('Render'))
        add(signals, 'custom-rendering-class');
    }
    super.visitClassDeclaration(node);
  }

  void call(String name) {
    if (RegExp(r'^[A-Z]').hasMatch(name)) add(calls, name);
    final base = name.split('.').first.split('<').first;
    if (['CustomPaint', 'ShaderMask', 'BackdropFilter'].contains(base))
      add(signals, 'custom-paint-or-effects');
    if ([
      'HtmlElementView',
      'WebViewWidget',
      'AndroidView',
      'UiKitView',
    ].contains(base))
      add(signals, 'platform-view');
    if (['GlobalKey', 'GlobalObjectKey'].contains(base))
      add(signals, 'global-key');
    if (['TextField', 'TextFormField', 'EditableText'].contains(base))
      add(signals, 'editable-text');
    if (base == 'LayoutBuilder' || base.startsWith('Intrinsic'))
      add(signals, 'layout-dependent-builder');
    if (base.startsWith('Sliver') || base == 'CustomScrollView')
      add(signals, 'sliver-layout');
    if (base == 'GoRoute' || base == 'GoRouter' || base == 'Navigator')
      add(signals, 'routing');
    if (name == 'Theme.of') add(signals, 'runtime-theme');
    if (name == 'ref.watch' || name == 'ref.read')
      add(signals, 'riverpod-access');
    if (name == 'setState') add(signals, 'set-state');
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    call(node.constructorName.toSource());
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    call(
      node.target == null
          ? node.methodName.name
          : '${node.target!.toSource()}.${node.methodName.name}',
    );
    super.visitMethodInvocation(node);
  }
}
