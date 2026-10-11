// Analyzer 7 element model is experimental; bounded by the package major version.
// ignore_for_file: experimental_member_use

import 'dart:io';

import 'analysis_environment.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as p;

/// Resolved project declarations retain their library identity and source AST.
/// External packages are resolved by analyzer, but are not expanded as widgets.
class ResolvedProject {
  final units = <ResolvedUnitResult>[];
  final classes = <String, ClassDeclaration>{};
  final constants = <String, Expression>{};
  final functions = <String, FunctionDeclaration>{};
  final enumValues = <String, String>{};
  final conditionalDirectives = <Map<String, Object?>>[];
  final _symbols = <Element2, String>{};
  late ResolvedUnitResult entry;
  late String directory;

  static Future<ResolvedProject> load(String project, String source) async {
    final model = ResolvedProject()
      ..directory = p.normalize(p.absolute(project));
    final entryPath = p.normalize(p.absolute(source));
    final lib = p.join(model.directory, 'lib');
    if (!p.isWithin(lib, entryPath)) {
      throw ArgumentError('Resolved entry must be inside project lib/.');
    }
    if (!File(
      p.join(model.directory, '.dart_tool/package_config.json'),
    ).existsSync()) {
      throw ArgumentError(
        'Resolved analysis needs package configuration. Run flutter pub get in the project first.',
      );
    }
    final collection = webAnalysisContexts(lib);
    try {
      final pending = [entryPath];
      final seen = <String>{};
      while (pending.isNotEmpty) {
        final path = pending.removeLast();
        if (!seen.add(path)) continue;
        final result = await collection
            .contextFor(path)
            .currentSession
            .getResolvedLibrary(path);
        if (result is! ResolvedLibraryResult) {
          throw ArgumentError(
            'Cannot resolve library $path: ${result.runtimeType}.',
          );
        }
        for (final unit in result.units) {
          if (!p.isWithin(lib, unit.path)) {
            throw ArgumentError(
              'Project parts must remain inside lib/: ${unit.path}.',
            );
          }
          if (model.units.any((u) => u.path == unit.path)) continue;
          final errors = unit.errors.where(
            (e) => e.errorCode.errorSeverity == ErrorSeverity.ERROR,
          );
          if (errors.isNotEmpty) {
            final error = errors.first;
            final loc = unit.lineInfo.getLocation(error.offset);
            throw ArgumentError(
              '${p.relative(unit.path, from: model.directory)}:${loc.lineNumber}:${loc.columnNumber}: ${error.message}',
            );
          }
          model.units.add(unit);
          if (unit.path == entryPath) model.entry = unit;
          for (final directive in unit.unit.directives) {
            final configurations = switch (directive) {
              ImportDirective d => d.configurations,
              ExportDirective d => d.configurations,
              _ => <Configuration>[],
            };
            for (final configuration in configurations) {
              final name = configuration.name.toSource();
              if (!webAnalysisEnvironment.containsKey(name)) {
                throw ArgumentError(
                  'Unsupported conditional-import variable $name at '
                  '${p.relative(unit.path, from: model.directory)}:'
                  '${unit.lineInfo.getLocation(configuration.offset).lineNumber}. '
                  'Custom environment definitions are not supported.',
                );
              }
            }
            final library = switch (directive) {
              ImportDirective d => d.libraryImport?.importedLibrary2,
              ExportDirective d => d.libraryExport?.exportedLibrary2,
              _ => null,
            };
            if (configurations.isNotEmpty) {
              model.conditionalDirectives.add({
                'file': p.relative(unit.path, from: model.directory),
                'line': unit.lineInfo.getLocation(directive.offset).lineNumber,
                'kind': directive is ImportDirective ? 'import' : 'export',
                'selectedLibrary': library?.uri.toString(),
              });
            }
            final target = library?.firstFragment.source.fullName;
            if (target != null && p.isWithin(lib, target)) pending.add(target);
          }
          for (final declaration in unit.unit.declarations) {
            if (declaration is ClassDeclaration) {
              final key =
                  '${p.relative(unit.path, from: model.directory)}::${declaration.name.lexeme}';
              model.classes[key] = declaration;
              model._symbols[declaration.declaredFragment!.element] = key;
              for (final field
                  in declaration.members.whereType<FieldDeclaration>()) {
                if (!field.isStatic || !field.fields.isConst) continue;
                for (final variable in field.fields.variables) {
                  if (variable.initializer == null) continue;
                  final fieldKey = '$key.${variable.name.lexeme}';
                  model.constants[fieldKey] = variable.initializer!;
                  model._symbols[variable.declaredFragment!.element] = fieldKey;
                }
              }
            } else if (declaration is FunctionDeclaration &&
                !declaration.isGetter &&
                !declaration.isSetter) {
              final key =
                  '${p.relative(unit.path, from: model.directory)}::${declaration.name.lexeme}';
              model.functions[key] = declaration;
              model._symbols[declaration.declaredFragment!.element] = key;
            } else if (declaration is EnumDeclaration &&
                declaration.members.isEmpty &&
                declaration.constants.every((c) => c.arguments == null)) {
              final key =
                  '${p.relative(unit.path, from: model.directory)}::${declaration.name.lexeme}';
              model._symbols[declaration.declaredFragment!.element] = key;
              for (final constant in declaration.constants) {
                final name = '$key.${constant.name.lexeme}';
                model.enumValues[name] = key;
                model._symbols[constant.declaredFragment!.element] = name;
              }
            } else if (declaration is TopLevelVariableDeclaration &&
                declaration.variables.isConst) {
              for (final variable in declaration.variables.variables) {
                final key =
                    '${p.relative(unit.path, from: model.directory)}::${variable.name.lexeme}';
                model.constants[key] = variable.initializer!;
                model._symbols[variable.declaredFragment!.element] = key;
              }
            }
          }
        }
      }
      return model;
    } finally {
      await collection.dispose();
    }
  }

  String? symbol(Element2? element) {
    if (element is PropertyAccessorElement2) element = element.variable3;
    return _symbols[element];
  }

  String root(String name) {
    if (classes.containsKey(name)) return name;
    final pieces = name.split('.');
    final matches = <String>{};
    if (pieces.length == 1) {
      for (final declaration in classes.entries) {
        if (declaration.value.name.lexeme == name &&
            declaration.value.declaredFragment!.element.library2 ==
                entry.libraryElement2) {
          return declaration.key;
        }
      }
      final local = symbol(entry.libraryElement2.exportNamespace.get2(name));
      if (local != null) return local;
    }
    for (final directive
        in entry.unit.directives.whereType<ImportDirective>()) {
      if (directive.prefix?.name != (pieces.length == 2 ? pieces.first : null))
        continue;
      final key = symbol(directive.libraryImport?.namespace.get2(name));
      if (key != null) matches.add(key);
    }
    if (matches.length == 1) return matches.single;
    throw ArgumentError(
      'Root $name is unresolved or ambiguous in the entry library.',
    );
  }

  ResolvedUnitResult unitFor(AstNode node) =>
      units.firstWhere((u) => identical(u.unit, node.root));
  String location(AstNode node) {
    final unit = unitFor(node);
    final loc = unit.lineInfo.getLocation(node.offset);
    return '${p.relative(unit.path, from: directory)}:${loc.lineNumber}:${loc.columnNumber}';
  }

  List<({String symbol, InstanceCreationExpression expression})> widgetCalls() {
    final result = <({String symbol, InstanceCreationExpression expression})>[];
    final visitor = _ConstructorVisitor((node) {
      final key = symbol(node.constructorName.element?.enclosingElement2);
      if (key != null &&
          classes.containsKey(key) &&
          widgetBase(classes[key]!) != null) {
        result.add((symbol: key, expression: node));
      }
    });
    for (final unit in units) {
      unit.unit.accept(visitor);
    }
    result.sort((a, b) {
      final byFile = unitFor(
        a.expression,
      ).path.compareTo(unitFor(b.expression).path);
      return byFile == 0
          ? a.expression.offset.compareTo(b.expression.offset)
          : byFile;
    });
    return result;
  }

  String? widgetBase(ClassDeclaration node) {
    final type = node.declaredFragment?.element.supertype?.element3;
    if (type == null) return null;
    final library = type.library2.uri.toString();
    const packages = [
      'flutter',
      'flutter_riverpod',
      'hooks_riverpod',
      'flutter_hooks',
    ];
    const names = [
      'StatelessWidget',
      'StatefulWidget',
      'ConsumerWidget',
      'ConsumerStatefulWidget',
      'HookWidget',
      'HookConsumerWidget',
    ];
    return packages.any((name) => library.startsWith('package:$name/')) &&
            names.contains(type.name3)
        ? type.name3
        : null;
  }

  String? superclass(ClassDeclaration node) {
    final type = node.declaredFragment?.element.supertype?.element3;
    return type != null &&
            type.library2.uri.toString().startsWith('package:flutter/')
        ? type.name3
        : null;
  }

  String frameworkValue(Expression node) {
    final element = node is Identifier
        ? node.element
        : (node as PropertyAccess).propertyName.element;
    final owner = element?.enclosingElement2;
    if (owner is InterfaceElement2 &&
        (owner.library2.uri.toString().startsWith('package:flutter/') ||
            owner.library2.uri.toString() == 'dart:ui')) {
      return '${owner.name3}.${element!.name3}';
    }
    throw ArgumentError(
      'Unsupported property ${node.toSource()} at ${location(node)}.',
    );
  }

  String constructor(InstanceCreationExpression node) {
    final element = node.constructorName.element;
    if (element == null)
      throw ArgumentError('Unresolved constructor at ${location(node)}.');
    final type = element.enclosingElement2;
    final local = symbol(type);
    final suffix = node.constructorName.name?.name;
    if (local != null) return suffix == null ? local : '$local.$suffix';
    if (type.library2.uri.toString() == 'dart:core' &&
        type.name3 == 'DateTime' &&
        (suffix == null || suffix == 'utc'))
      return suffix == null ? 'DateTime' : 'DateTime.utc';
    if (type.library2.uri.toString().startsWith('package:flutter/') ||
        type.library2.uri.toString() == 'dart:ui' &&
            type.name3 == 'Color' &&
            suffix == null) {
      return '${type.name3}${suffix == null ? '' : '.$suffix'}';
    }
    throw ArgumentError(
      'Unsupported external constructor ${type.name3} at ${location(node)}.',
    );
  }
}

class _ConstructorVisitor extends RecursiveAstVisitor<void> {
  _ConstructorVisitor(this.onConstructor);
  final void Function(InstanceCreationExpression) onConstructor;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    onConstructor(node);
    super.visitInstanceCreationExpression(node);
  }
}
