import 'dart:io';
import 'compiler.dart';
import 'project.dart';
import 'analysis_environment.dart';
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
    if (!lib.existsSync())
      throw ArgumentError(
        'No lib/ directory at ${project.path}. Use a real Flutter project, e.g. --project examples/catalog.',
      );
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

  /// Dry-run direct widget roots in the entry's resolved web dependency graph.
  /// Syntax inventory remains project-wide and is reported separately.
  Future<Map<String, Object?>> inspectResolved(
    String projectPath, {
    String source = 'lib/main.dart',
  }) async {
    final project = p.normalize(p.absolute(projectPath));
    final ResolvedProject model;
    try {
      model = await ResolvedProject.load(project, p.join(project, source));
    } on ArgumentError catch (error) {
      throw CompileException(error.message.toString());
    }
    final report = inspect(project);
    final entries = <Map<String, Object?>>[];
    for (final entry in model.classes.entries) {
      final node = entry.value;
      if (model.widgetBase(node) == null) continue;
      final unit = model.unitFor(node);
      String? blocker;
      String? code;
      try {
        FlutterDomCompiler().compile(
          model.entry.content,
          {'root': entry.key},
          domOnly: true,
          resolved: model,
        );
      } on CompileException catch (error) {
        blocker = error.message;
        code = error.code;
      } on ArgumentError catch (error) {
        blocker = error.message.toString();
        code = 'unsupported';
      }
      entries.add({
        'file': p.relative(unit.path, from: project),
        'line': unit.lineInfo.getLocation(node.offset).lineNumber,
        'widget': node.name.lexeme,
        'symbol': entry.key,
        'status': blocker == null ? 'native' : 'blocked',
        'category': blocker == null
            ? 'native'
            : code == 'requires-inputs'
            ? 'needs-inputs'
            : 'unsupported',
        if (code != null) 'code': code,
        if (blocker != null) 'blocker': blocker,
      });
    }
    entries.sort(
      (a, b) => (a['symbol'] as String).compareTo(b['symbol'] as String),
    );
    final accepted = entries.where((e) => e['status'] == 'native').length;
    report['schemaVersion'] = 4;
    report['kind'] = 'syntax-inventory-with-resolved-entry-checks';
    report['analysis'] = 'resolved project';
    report['analysisTarget'] = 'web-js';
    report['conditionalEnvironment'] = webAnalysisEnvironment;
    report['conditionalDirectives'] = model.conditionalDirectives;
    report['sourceFiles'] =
        model.units.map((u) => p.relative(u.path, from: project)).toList()
          ..sort();
    report['compatibility'] = {
      'metric': 'resolved-parameterless-widget-entry-dry-run',
      'native': accepted,
      'total': entries.length,
      'percent': entries.isEmpty ? null : 100 * accepted / entries.length,
      'entries': entries,
      'needsInputs': entries
          .where((e) => e['category'] == 'needs-inputs')
          .length,
      'unsupported': entries
          .where((e) => e['category'] == 'unsupported')
          .length,
      'definition':
          'Recognized direct widget subclasses in the selected entry library graph, '
          'including selected web imports and parts, compiled independently without arguments, adapters or islands. '
          'Imports and constants are resolved; required inputs and runtime state remain blockers. '
          'This measures compiler acceptance, not app-wide behavior or runtime reachability.',
    };
    report['limitations'] = [
      'The compatibility denominator covers the selected library graph, not every project file or runtime widget.',
      'Indirect widget subclasses and external-package implementations are excluded from entry checks.',
      'Required constructor data is not invented; rejected roots may work when supplied supported static inputs.',
      'Adapters and islands are disabled; no behavioral or pixel equivalence is established.',
      'Syntax inventory counts remain project-wide and include inactive platform branches; they are not the compatibility score.',
      'Inventory excludes generated files; resolved checks include generated parts needed by selected libraries.',
      'Analyzer errors in selected project libraries block resolution; custom conditional environment variables are unsupported.',
      'No application source is executed, modified or uploaded.',
    ];
    const limit = 1000;
    final calls = model.widgetCalls();
    final sites = <Map<String, Object?>>[];
    for (final call in calls.take(limit)) {
      final unit = model.unitFor(call.expression);
      final location = unit.lineInfo.getLocation(call.expression.offset);
      String? blocker;
      String? code;
      try {
        FlutterDomCompiler().compile(
          model.entry.content,
          {'root': call.symbol},
          domOnly: true,
          resolved: model,
          entryExpression: call.expression,
        );
      } on CompileException catch (error) {
        blocker = error.message;
        code = error.code;
      } on ArgumentError catch (error) {
        blocker = error.message.toString();
        code = 'unsupported';
      }
      sites.add({
        'file': p.relative(unit.path, from: project),
        'line': location.lineNumber,
        'column': location.columnNumber,
        'widget': model.classes[call.symbol]!.name.lexeme,
        'symbol': call.symbol,
        'status': blocker == null
            ? 'native'
            : code == 'requires-context'
            ? 'needs-context'
            : 'unsupported',
        if (code != null) 'code': code,
        if (blocker != null) 'blocker': blocker,
      });
    }
    report['callSites'] = {
      'metric': 'isolated-constructor-call-dry-run',
      'total': calls.length,
      'checked': sites.length,
      'skipped': calls.length - sites.length,
      'limit': limit,
      'native': sites.where((s) => s['status'] == 'native').length,
      'needsContext': sites.where((s) => s['status'] == 'needs-context').length,
      'unsupported': sites.where((s) => s['status'] == 'unsupported').length,
      'entries': sites,
      'definition':
          'Actual constructor expressions of project-local widget classes in selected libraries, '
          'checked independently with supplied arguments. Static constants and literals are evaluated; '
          'enclosing parameters, locals and runtime state are not invented. '
          'A passing call proves only that this isolated subtree emits DOM. Calls can be nested, '
          'inside unused functions or inactive runtime branches; no runtime reachability or app coverage is implied.',
    };
    return report;
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
    if (report.containsKey('callSites')) {
      out.writeln(
        '${coverage['native']} static · ${coverage['needsInputs']} need inputs · '
        '${coverage['unsupported']} unsupported (${coverage['total']} roots).\n',
      );
    } else {
      out.writeln(
        '**${percent?.toStringAsFixed(1) ?? 'N/A'}${percent == null ? '' : '%'}** '
        '(${coverage['native']}/${coverage['total']} widget entry points).\n',
      );
    }
    out.writeln('${coverage['definition']}\n');
    for (final entry in coverage['entries'] as List) {
      out.writeln(
        '- `${entry['file']}:${entry['line']}` **${entry['widget']}**: '
        '${entry['category'] ?? entry['status']}${entry['blocker'] == null ? '' : ' — ${entry['blocker']}'}',
      );
    }
    out.writeln();
    final sites = report['callSites'] as Map<String, Object?>?;
    if (sites != null) {
      out.writeln('## Constructor call sites\n');
      out.writeln(
        '${sites['native']} static · ${sites['needsContext']} need context · '
        '${sites['unsupported']} unsupported (${sites['checked']}/${sites['total']} checked; '
        '${sites['skipped']} skipped).\n',
      );
      out.writeln('${sites['definition']}\n');
      for (final site in sites['entries'] as List) {
        out.writeln(
          '- `${site['file']}:${site['line']}:${site['column']}` **${site['widget']}**: '
          '${site['status']}${site['blocker'] == null ? '' : ' — ${site['blocker']}'}',
        );
      }
      out.writeln();
    }
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
