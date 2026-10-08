// Analyzer 7 element model is experimental; bounded by the package major version.
// ignore_for_file: experimental_member_use

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as p;

/// Resolved project declarations retain their library identity and source AST.
/// External packages are resolved by analyzer, but are not expanded as widgets.
class ResolvedProject {
  final units = <ResolvedUnitResult>[];
  final classes = <String, ClassDeclaration>{};
  final constants = <String, Expression>{};
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
    final collection = AnalysisContextCollection(includedPaths: [lib]);
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
            if (directive is ImportDirective &&
                    directive.configurations.isNotEmpty ||
                directive is ExportDirective &&
                    directive.configurations.isNotEmpty) {
              throw ArgumentError(
                'Conditional imports/exports are not supported in resolved DOM builds: ${unit.path}.',
              );
            }
            final library = switch (directive) {
              ImportDirective d => d.libraryImport?.importedLibrary2,
              ExportDirective d => d.libraryExport?.exportedLibrary2,
              _ => null,
            };
            final target = library?.firstFragment.source.fullName;
            if (target != null && p.isWithin(lib, target)) pending.add(target);
          }
          for (final declaration in unit.unit.declarations) {
            if (declaration is ClassDeclaration) {
              final key =
                  '${p.relative(unit.path, from: model.directory)}::${declaration.name.lexeme}';
              model.classes[key] = declaration;
              model._symbols[declaration.declaredFragment!.element] = key;
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
    if (type.library2.uri.toString().startsWith('package:flutter/')) {
      return '${type.name3}${suffix == null ? '' : '.$suffix'}';
    }
    throw ArgumentError(
      'Unsupported external constructor ${type.name3} at ${location(node)}.',
    );
  }
}
