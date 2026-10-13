import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// An explicit component experiment, not automatic whole-library compatibility.
/// Declaration bodies are retained verbatim, including same-library dependencies.
class NativeSourceSelection {
  const NativeSourceSelection({
    required this.declarations,
    required this.imports,
  });
  final List<String> declarations;
  final List<String> imports;
}

class _Identifiers extends RecursiveAstVisitor<void> {
  final names = <String>{};
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

Set<String> _names(CompilationUnitMember node) => switch (node) {
  ClassDeclaration() => {node.name.lexeme},
  EnumDeclaration() => {node.name.lexeme},
  FunctionDeclaration() => {node.name.lexeme},
  GenericTypeAlias() => {node.name.lexeme},
  TopLevelVariableDeclaration() => {
    for (final variable in node.variables.variables) variable.name.lexeme,
  },
  _ => {},
};

String selectNativeSource(String source, NativeSourceSelection selection) {
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  if (parsed.errors.isNotEmpty)
    throw ArgumentError('Selected source has parser errors.');
  if (selection.declarations.isEmpty ||
      selection.declarations.toSet().length != selection.declarations.length ||
      selection.imports.toSet().length != selection.imports.length) {
    throw ArgumentError(
      'Selection requires nonempty, unique declaration names and unique imports.',
    );
  }
  final unit = parsed.unit;
  // Parts, conditional directives and extensions need resolved library analysis.
  if (unit.directives.any(
        (d) =>
            d is PartDirective ||
            d is PartOfDirective ||
            d is ImportDirective && d.configurations.isNotEmpty,
      ) ||
      unit.declarations.any((d) => _names(d).isEmpty)) {
    throw UnsupportedError(
      'Source selection supports named classes, enums, functions, aliases and variables; no parts, extensions or conditional imports.',
    );
  }
  final available = {for (final d in unit.declarations) ..._names(d)};
  if (!available.containsAll(selection.declarations))
    throw ArgumentError('Selection names a missing declaration.');
  final imports = {
    for (final d in unit.directives.whereType<ImportDirective>())
      d.uri.stringValue,
  };
  if (!imports.containsAll(selection.imports))
    throw ArgumentError('Selection names a missing import.');
  final retained = <CompilationUnitMember>{};
  final referenced = selection.declarations.toSet();
  var changed = true;
  while (changed) {
    changed = false;
    for (final d in unit.declarations) {
      if (!retained.contains(d) && _names(d).any(referenced.contains)) {
        retained.add(d);
        final visitor = _Identifiers();
        d.accept(visitor);
        referenced.addAll(visitor.names);
        changed = true;
      }
    }
  }
  final edits = <(int, int)>[
    for (final d in unit.declarations)
      if (!retained.contains(d)) (d.offset, d.end),
    for (final d in unit.directives)
      if (d is ExportDirective ||
          d is ImportDirective &&
              !selection.imports.contains(d.uri.stringValue))
        (d.offset, d.end),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final edit in edits) result = result.replaceRange(edit.$1, edit.$2, '');
  return result;
}
