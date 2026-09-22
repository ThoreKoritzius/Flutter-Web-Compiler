import 'dart:convert';
import 'package:analyzer/dart/ast/ast.dart';

/// Bounded interpretation of a deliberately small Canvas/Dart subset.
/// Never executes application code or falls back to guessed geometry.
class SvgPainter {
  int _budget = 20000;
  final _canvas = _Canvas();
  late Map<String, Object?> _scope;

  String compile(ClassDeclaration declaration, Map<String, Object?> fields) {
    _scope = {
      ...fields,
      'canvas': _canvas,
      'size': {'width': 320.0, 'height': 110.0},
    };
    final methods = declaration.members
        .whereType<MethodDeclaration>()
        .where((m) => m.name.lexeme == 'paint')
        .toList();
    if (methods.length != 1 || methods.single.body is! BlockFunctionBody)
      throw ArgumentError('Painter needs one block-bodied paint method.');
    final parameters = methods.single.parameters?.parameters;
    if (parameters == null || parameters.length != 2)
      throw ArgumentError('Painter requires Canvas and Size parameters.');
    _scope[parameters[0].name!.lexeme] = _canvas;
    _scope[parameters[1].name!.lexeme] = _scope['size'];
    statement((methods.single.body as BlockFunctionBody).block);
    return _canvas.shapes.join();
  }

  Never unsupported(AstNode node) => throw ArgumentError(
    'Unsupported painter operation at offset ${node.offset}: ${node.toSource()}',
  );
  void tick() {
    if (--_budget < 0)
      throw ArgumentError('Painter exceeded the static operation budget.');
  }

  num number(Object? value) {
    if (value is! num || !value.isFinite)
      throw ArgumentError('Painter arithmetic must remain finite.');
    return value;
  }

  Object? property(Object? target, String name) {
    if (target is Map<String, Object?> && target.containsKey(name))
      return target[name];
    if (target is List && name == 'length') return target.length;
    if (target is _Paint) return target.fields[name];
    throw ArgumentError('Unsupported painter property $name.');
  }

  void assign(Expression left, Object? value, [Object? cascade]) {
    if (left is SimpleIdentifier && _scope.containsKey(left.name)) {
      _scope[left.name] = value;
      return;
    }
    if (left is PropertyAccess) {
      final target = left.target == null ? cascade : expression(left.target!);
      final name = left.propertyName.name;
      if (target is _Paint &&
          ['color', 'style', 'strokeWidth'].contains(name)) {
        target.fields[name] = value;
        return;
      }
    }
    unsupported(left);
  }

  Object? expression(Expression node, [Object? cascade]) {
    tick();
    if (node is IntegerLiteral) return node.value;
    if (node is DoubleLiteral) return node.value;
    if (node is SimpleStringLiteral) return node.value;
    if (node is BooleanLiteral) return node.value;
    if (node is ParenthesizedExpression) return expression(node.expression);
    if (node is SimpleIdentifier && _scope.containsKey(node.name))
      return _scope[node.name];
    if (node is PrefixedIdentifier) {
      if (node.prefix.name == 'PaintingStyle' &&
          ['stroke', 'fill'].contains(node.identifier.name))
        return node.identifier.name;
      return property(expression(node.prefix), node.identifier.name);
    }
    if (node is PropertyAccess)
      return property(
        node.target == null ? cascade : expression(node.target!),
        node.propertyName.name,
      );
    if (node is IndexExpression) {
      final list = expression(node.target!);
      final index = expression(node.index);
      if (list is! List || index is! int || index < 0 || index >= list.length)
        unsupported(node);
      return list[index];
    }
    if (node is ConditionalExpression) {
      final condition = expression(node.condition);
      if (condition is! bool) unsupported(node);
      return expression(condition ? node.thenExpression : node.elseExpression);
    }
    if (node is BinaryExpression) {
      final a = expression(node.leftOperand), b = expression(node.rightOperand);
      return switch (node.operator.lexeme) {
        '+' => number(a) + number(b),
        '-' => number(a) - number(b),
        '*' => number(a) * number(b),
        '/' => number(a) / number(b),
        '<' => number(a) < number(b),
        '>' => number(a) > number(b),
        '<=' => number(a) <= number(b),
        '>=' => number(a) >= number(b),
        '==' => a == b,
        '!=' => a != b,
        _ => unsupported(node),
      };
    }
    if (node is PrefixExpression && node.operator.lexeme == '-')
      return -number(expression(node.operand));
    if (node is PostfixExpression && node.operator.lexeme == '++') {
      final previous = number(expression(node.operand));
      assign(node.operand, previous + 1);
      return previous;
    }
    if (node is AssignmentExpression && node.operator.lexeme == '=') {
      final value = expression(node.rightHandSide);
      assign(node.leftHandSide, value, cascade);
      return value;
    }
    if (node is CascadeExpression) {
      final target = expression(node.target);
      for (final section in node.cascadeSections) {
        expression(section, target);
      }
      return target;
    }
    if (node is MethodInvocation) {
      final name = node.methodName.name;
      if (node.target == null &&
          !node.isCascaded &&
          node.argumentList.arguments.isEmpty) {
        if (name == 'Paint') return _Paint();
        if (name == 'Path') return _Path();
      }
      if (node.target?.toSource() == 'Rect' && name == 'fromLTWH') {
        final args = node.argumentList.arguments
            .map(expression)
            .map(number)
            .toList();
        if (args.length != 4 || args[2] < 0 || args[3] < 0) unsupported(node);
        return _Rect(args);
      }
      final target = node.isCascaded
          ? cascade
          : node.target == null
          ? null
          : expression(node.target!);
      if (target is List && name == 'fold') {
        final args = node.argumentList.arguments;
        if (args.length != 2 || args[1] is! FunctionExpression)
          unsupported(node);
        final closure = args[1] as FunctionExpression;
        if (closure.body is! ExpressionFunctionBody ||
            closure.parameters?.parameters.length != 2)
          unsupported(node);
        final previous = _scope;
        var result = expression(args[0]);
        try {
          for (final item in target) {
            _scope = {
              ...previous,
              closure.parameters!.parameters[0].name!.lexeme: result,
              closure.parameters!.parameters[1].name!.lexeme: item,
            };
            result = expression(
              (closure.body as ExpressionFunctionBody).expression,
            );
          }
        } finally {
          _scope = previous;
        }
        return result;
      }
      final args = node.argumentList.arguments
          .map((a) => expression(a))
          .toList();
      if (target is _Path &&
          ['moveTo', 'lineTo'].contains(name) &&
          args.length == 2) {
        target.commands.add(
          '${name == 'moveTo' ? 'M' : 'L'}${number(args[0])} ${number(args[1])}',
        );
        return null;
      }
      if (target is _Canvas) {
        if (name == 'scale' && args.length == 2) {
          target.transform += ' scale(${number(args[0])} ${number(args[1])})';
          return null;
        }
        if (name == 'drawRect' &&
            args.length == 2 &&
            args[0] is _Rect &&
            args[1] is _Paint) {
          final r = (args[0] as _Rect).values;
          target.add(
            '<rect x="${r[0]}" y="${r[1]}" width="${r[2]}" height="${r[3]}"',
            args[1] as _Paint,
          );
          return null;
        }
        if (name == 'drawPath' &&
            args.length == 2 &&
            args[0] is _Path &&
            args[1] is _Paint) {
          target.add(
            '<path d="${(args[0] as _Path).commands.join(' ')}"',
            args[1] as _Paint,
          );
          return null;
        }
      }
      unsupported(node);
    }
    unsupported(node);
  }

  void declarations(VariableDeclarationList declarations) {
    for (final variable in declarations.variables) {
      if (variable.initializer == null) unsupported(variable);
      _scope[variable.name.lexeme] = expression(variable.initializer!);
    }
  }

  void statement(Statement node) {
    tick();
    if (node is Block) {
      final previous = _scope;
      _scope = {...previous};
      try {
        for (final child in node.statements) {
          statement(child);
        }
      } finally {
        final locals = node.statements
            .whereType<VariableDeclarationStatement>()
            .expand((s) => s.variables.variables)
            .map((v) => v.name.lexeme)
            .toSet();
        for (final key in previous.keys.toList()) {
          if (!locals.contains(key)) previous[key] = _scope[key];
        }
        _scope = previous;
      }
    } else if (node is VariableDeclarationStatement) {
      declarations(node.variables);
    } else if (node is ExpressionStatement) {
      expression(node.expression);
    } else if (node is IfStatement) {
      final condition = expression(node.expression);
      if (condition is! bool) unsupported(node);
      if (condition) {
        statement(node.thenStatement);
      } else if (node.elseStatement != null) {
        statement(node.elseStatement!);
      }
    } else if (node is ForStatement &&
        node.forLoopParts is ForPartsWithDeclarations) {
      final parts = node.forLoopParts as ForPartsWithDeclarations;
      if (parts.condition == null) unsupported(node);
      if (parts.variables.variables.any(
        (v) => _scope.containsKey(v.name.lexeme),
      ))
        unsupported(node);
      declarations(parts.variables);
      while (true) {
        tick();
        final condition = expression(parts.condition!);
        if (condition is! bool) unsupported(node);
        if (!condition) break;
        statement(node.body);
        for (final update in parts.updaters) {
          expression(update);
        }
      }
    } else {
      unsupported(node);
    }
  }
}

class _Paint {
  final fields = <String, Object?>{
    'style': 'fill',
    'strokeWidth': 1,
    'color': '#000000',
  };
}

class _Rect {
  _Rect(this.values);
  final List<num> values;
}

class _Path {
  final commands = <String>[];
}

class _Canvas {
  String transform = '';
  final shapes = <String>[];
  void add(String shape, _Paint paint) {
    final color = paint.fields['color'], width = paint.fields['strokeWidth'];
    if (color is! String ||
        !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color) ||
        width is! num ||
        !width.isFinite ||
        width < 0 ||
        !['fill', 'stroke'].contains(paint.fields['style']))
      throw ArgumentError('Unsupported paint settings.');
    final style = paint.fields['style'] == 'stroke'
        ? 'fill="none" stroke="$color" stroke-width="$width"'
        : 'fill="$color"';
    shapes.add(
      '$shape $style transform="${const HtmlEscape().convert(transform)}"/>',
    );
  }
}
