// Analyzer 7 element model is experimental; bounded by the package major version.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'chart.dart';
import 'icons.dart';
import 'reactivity.dart';
import 'painter.dart';
import 'project.dart';
import 'analysis_environment.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

class CompileException implements Exception {
  CompileException(this.message, {this.code = 'unsupported'});
  final String message;
  final String code;
  @override
  String toString() => 'Compile error: $message';
}

class Compilation {
  Compilation(this.html, this.report, this.island);
  String get nativeRuntime => reactiveRuntime;
  final String html;
  final Map<String, Object?> report;
  final String? island;
}

class _Call {
  _Call(this.name, this.positional, this.named, this.line, [this.origin]);
  final AstNode? origin;
  final String name;
  final List<Object?> positional;
  final Map<String, Object?> named;
  final int line;
}

class _ConditionalList {
  _ConditionalList(this.condition, this.yes, this.no);
  final ReactiveValue condition;
  final List<Object?> yes, no;
}

class _GuardedChildren {
  _GuardedChildren(this.condition, this.children);
  final ReactiveValue condition;
  final List<Object?> children;
}

class _StaticObject {
  _StaticObject(
    this.fields, {
    this.model,
    this.getters = const {},
    this.methods = const {},
  });
  final Map<String, Object?> fields;
  final String? model;
  final Map<String, Expression> getters;
  final Map<String, MethodDeclaration> methods;
}

class _ExternalCallback {
  _ExternalCallback(this.name, [this.routes]);
  final String name;
  final Map<String, String>? routes;
}

class _NativeNavigation {
  _NativeNavigation(this.href);
  final String href;
}

class _StaticContext {}

class _StaticDate {
  _StaticDate(this.year, this.month, this.day);
  final int year, month, day;
}

class _StaticEnum {
  _StaticEnum(this.identity, this.type);
  final String identity, type;
  @override
  bool operator ==(Object other) =>
      other is _StaticEnum && identity == other.identity;
  @override
  int get hashCode => identity.hashCode;
}

class _StaticColor {
  _StaticColor(this.hex, [this.alpha = 1]);
  final String hex;
  final double alpha;
  String get css {
    final n = int.parse(hex.substring(1), radix: 16);
    return 'rgba(${n >> 16},${(n >> 8) & 255},${n & 255},$alpha)';
  }
}

/// Build-time AST evaluation: never executes the input application.
class FlutterDomCompiler {
  Future<Compilation> compileProject(
    String project,
    String source,
    Map<String, dynamic> config, {
    bool domOnly = false,
  }) async {
    try {
      final model = await ResolvedProject.load(project, source);
      return compile(
        File(source).readAsStringSync(),
        config,
        domOnly: domOnly,
        resolved: model,
      );
    } on ArgumentError catch (error) {
      throw CompileException(error.message.toString());
    }
  }

  Compilation compile(
    String source,
    Map<String, dynamic> config, {
    bool domOnly = false,
    ResolvedProject? resolved,
    Expression? entryExpression,
  }) {
    try {
      return _compile(
        source,
        config,
        domOnly: domOnly,
        resolved: resolved,
        entryExpression: entryExpression,
      );
    } on ArgumentError catch (error) {
      throw CompileException(error.message.toString());
    }
  }

  Compilation _compile(
    String source,
    Map<String, dynamic> config, {
    bool domOnly = false,
    ResolvedProject? resolved,
    Expression? entryExpression,
  }) {
    final result = parseString(content: source, throwIfDiagnostics: false);
    if (result.errors.isNotEmpty) {
      throw CompileException(result.errors.first.toString());
    }
    final classes =
        resolved?.classes ??
        <String, ClassDeclaration>{
          for (final node
              in result.unit.declarations.whereType<ClassDeclaration>())
            node.name.lexeme: node,
        };
    final previews = config['preview'] as List?;
    final rootName =
        config['root'] as String? ??
        (previews != null && previews.isNotEmpty
            ? (previews.first as Map)['root'] as String
            : discoverRoot(source));
    final root = resolved?.root(rootName) ?? rootName;
    final islandConfig = Map<String, dynamic>.from(
      config['islands'] as Map? ?? {},
    );
    final headings = Map<String, dynamic>.from(
      config['headings'] as Map? ?? {},
    );
    final counts = <String, int>{};
    final nativeAdapters = Map<String, dynamic>.from(
      config['nativeAdapters'] as Map? ?? {},
    );
    if (resolved != null) {
      for (final mapping in [islandConfig, nativeAdapters]) {
        for (final name in mapping.keys.toList()) {
          final key = resolved.root(name);
          if (!identical(
            resolved.unitFor(classes[key]!).unit,
            resolved.entry.unit,
          )) {
            throw CompileException(
              'Imported adapter/island $name is not supported yet.',
            );
          }
          mapping[key] = mapping.remove(name);
        }
      }
    }
    final assets = <String>{};
    var adapterCount = 0;
    var filterCount = 0;
    var darkTheme = false;
    var reactiveCount = 0;
    var conditionalGroupCount = 0;
    ReactiveFrame? frame;
    var evaluatingState = false;
    var evaluatingStaticHelper = false;
    final stack = <String>[];
    var scope = <String, Object?>{};
    var instanceFields = <String, Object?>{};
    var instanceGetters = <String, Expression>{};
    var instanceMethods = <String, MethodDeclaration>{};
    late Object? Function(MethodDeclaration, List<Expression>, _StaticObject?)
    invokeHelper;
    var helperCount = 0;
    var externalCallbackCount = 0;
    var callbackRouteBridgeCount = 0;
    var navigationLinkCount = 0;
    final evaluatingGetters = <(Map<String, Object?>, String)>[];
    String? island;
    final constants = <String, Expression>{...?resolved?.constants};
    for (final declaration
        in (resolved == null
                ? result.unit.declarations
                : <CompilationUnitMember>[])
            .whereType<TopLevelVariableDeclaration>()) {
      if (!declaration.variables.isConst) continue;
      for (final variable in declaration.variables.variables) {
        if (variable.initializer != null) {
          if (constants.containsKey(variable.name.lexeme)) {
            throw CompileException(
              'Duplicate constant ${variable.name.lexeme}.',
            );
          }
          constants[variable.name.lexeme] = variable.initializer!;
        }
      }
    }
    final constantValues = <String, Object?>{};
    final resolving = <String>[];
    var evaluationBudget = 20000;

    AstNode? currentNode;
    Never fail(String message, [int? line, String code = 'unsupported']) =>
        throw CompileException(
          '${resolved != null && currentNode != null
              ? '${resolved.location(currentNode!)}: '
              : line == null
              ? ''
              : 'Line $line: '}$message',
          code: code,
        );

    var dateCount = 0;
    _StaticDate calendarDate(Object? year, Object? month, Object? day) {
      if (year is! int ||
          month is! int ||
          day is! int ||
          year < 1 ||
          year > 9999 ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31)
        fail('Dates require integer year/month/day within years 1–9999.');
      final date = DateTime.utc(year, month, day);
      if (date.year != year || date.month != month || date.day != day)
        fail('Invalid calendar date.');
      dateCount++;
      return _StaticDate(year, month, day);
    }

    bool dateType(NamedType type) =>
        type.name2.lexeme == 'DateTime' &&
        (resolved == null
            ? !classes.containsKey('DateTime')
            : type.element2?.library2?.uri.toString() == 'dart:core');

    _StaticColor color(Object? input) {
      if (input is _StaticColor) return input;
      if (input is _Call &&
          input.name == 'Color' &&
          input.positional.length == 1 &&
          input.named.isEmpty) {
        final argb = input.positional.single;
        if (argb is! int || argb < 0 || argb > 0xffffffff)
          fail('Color requires a static ARGB integer.');
        return _StaticColor(
          '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}',
          ((argb >> 24) & 255) / 255,
        );
      }
      if (input is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(input)) {
        fail('Static theme colors require six-digit hex values.');
      }
      return _StaticColor(input);
    }

    final themeConfig = config['staticTheme'];
    _StaticObject? staticTheme;
    if (themeConfig != null) {
      if (themeConfig is! Map ||
          themeConfig.keys.any(
            (k) => !['textTheme', 'colorScheme', 'extensions'].contains(k),
          )) {
        fail('staticTheme accepts textTheme, colorScheme and extensions only.');
      }
      if ((themeConfig['colorScheme'] != null &&
              themeConfig['colorScheme'] is! Map) ||
          (themeConfig['textTheme'] != null &&
              themeConfig['textTheme'] is! Map))
        fail('Static theme groups must be maps.');
      final colors = <String, Object?>{};
      final styles = <String, Object?>{};
      for (final entry in (themeConfig['colorScheme'] as Map? ?? {}).entries) {
        colors[entry.key as String] = color(entry.value);
      }
      for (final entry in (themeConfig['textTheme'] as Map? ?? {}).entries) {
        if (entry.value is! Map) fail('Static text styles must be maps.');
        final properties = Map<String, Object?>.from(entry.value as Map);
        if (properties.keys.any(
          (k) => !['fontSize', 'fontWeight', 'color', 'height'].contains(k),
        ))
          fail('Unsupported static text style property.');
        if (properties['color'] != null)
          properties['color'] = color(properties['color']);
        styles[entry.key as String] = _Call('TextStyle', [], properties, 1);
      }
      staticTheme = _StaticObject({
        'textTheme': _StaticObject(styles),
        'colorScheme': _StaticObject(colors),
      });
    }

    late _StaticObject Function(_Call) instantiateModel;
    late _StaticObject Function(_Call) instantiateExtension;
    late Object? Function(_StaticObject, String) modelGetter;
    var modelCount = 0;
    final themeExtensions = <String, _StaticObject>{};
    bool isThemeExtension(ClassDeclaration node) {
      final type = node.extendsClause?.superclass;
      if (type?.name2.lexeme != 'ThemeExtension') return false;
      return resolved == null ||
          type!.element2?.library2?.uri.toString().startsWith(
                'package:flutter/',
              ) ==
              true;
    }

    final enumValues = <String, String>{...?resolved?.enumValues};
    if (resolved == null) {
      for (final e in result.unit.declarations.whereType<EnumDeclaration>()) {
        if (e.members.isNotEmpty || e.constants.any((c) => c.arguments != null))
          continue;
        for (final c in e.constants)
          enumValues['${e.name.lexeme}.${c.name.lexeme}'] = e.name.lexeme;
      }
    }

    _StaticObject staticClass(ClassDeclaration node) => _StaticObject(
      {},
      methods: {
        for (final m in node.members.whereType<MethodDeclaration>())
          if (m.isStatic && !m.isGetter && !m.isSetter) m.name.lexeme: m,
      },
      getters: {
        for (final m in node.members.whereType<MethodDeclaration>())
          if (m.isStatic &&
              m.isGetter &&
              m.typeParameters == null &&
              m.body is ExpressionFunctionBody &&
              !m.body.isAsynchronous)
            m.name.lexeme: (m.body as ExpressionFunctionBody).expression,
        for (final f in node.members.whereType<FieldDeclaration>())
          if (f.isStatic && f.fields.isConst)
            for (final v in f.fields.variables)
              if (v.initializer != null) v.name.lexeme: v.initializer!,
      },
    );

    Object? property(Object? target, String name) {
      if (target is _StaticDate) {
        return switch (name) {
          'year' => target.year,
          'month' => target.month,
          'day' => target.day,
          _ => fail('Unsupported calendar date property $name.'),
        };
      }
      if (target is _StaticObject && target.fields.containsKey(name))
        return target.fields[name];
      if (target is _StaticObject && target.getters.containsKey(name))
        return modelGetter(target, name);
      if (target is List) {
        if (name == 'length') return target.length;
        if (name == 'isEmpty') return target.isEmpty;
        if (name == 'isNotEmpty') return target.isNotEmpty;
        if (name == 'first' || name == 'last') {
          if (target.isEmpty)
            fail('Cannot read $name from an empty static list.');
          return name == 'first' ? target.first : target.last;
        }
      }
      fail('Unsupported or missing static property $name.');
    }

    bool staticReceiver(Expression? node) {
      if (node is Identifier) {
        final key =
            resolved?.symbol(node.element) ??
            (node is SimpleIdentifier ? node.name : node.toSource());
        if (constants.containsKey(key) || classes.containsKey(key)) return true;
      }
      return switch (node) {
        SimpleIdentifier n => scope.containsKey(n.name),
        PrefixedIdentifier n => scope.containsKey(n.prefix.name),
        PropertyAccess n => staticReceiver(n.target),
        IndexExpression n => staticReceiver(n.target),
        PostfixExpression n =>
          n.operator.lexeme == '!' && staticReceiver(n.operand),
        MethodInvocation n =>
          resolved == null &&
                  !classes.containsKey('DateTime') &&
                  (n.target == null && n.methodName.name == 'DateTime' ||
                      n.target?.toSource() == 'DateTime' &&
                          n.methodName.name == 'utc') ||
              n.methodName.name == 'of' ||
              staticReceiver(n.target) ||
              n.target == null &&
                  (instanceMethods.containsKey(n.methodName.name) ||
                      classes[n.methodName.name]?.extendsClause == null &&
                          classes.containsKey(n.methodName.name)),
        InstanceCreationExpression n =>
          classes.containsKey(
                resolved?.constructor(n) ?? n.constructorName.toSource(),
              ) ||
              ['DateTime', 'DateTime.utc'].contains(
                resolved?.constructor(n) ?? n.constructorName.toSource(),
              ),
        ParenthesizedExpression n => staticReceiver(n.expression),
        ListLiteral _ => true,
        _ => false,
      };
    }

    late bool Function(GuardedPattern, Object?) bindPattern;
    Object? value(Expression expression) {
      currentNode = expression;
      if (evaluatingStaticHelper &&
          (expression is ThisExpression ||
              expression is PropertyAccess &&
                  expression.target is ThisExpression))
        fail('Static helpers cannot access this.');
      final line = (resolved?.unitFor(expression).lineInfo ?? result.lineInfo)
          .getLocation(expression.offset)
          .lineNumber;
      final enumName = resolved != null && expression is Identifier
          ? resolved.symbol(expression.element)
          : resolved != null && expression is PropertyAccess
          ? resolved.symbol(expression.propertyName.element)
          : expression.toSource();
      if (enumValues.containsKey(enumName))
        return _StaticEnum(enumName!, enumValues[enumName]!);
      if (expression is IndexExpression) {
        final target = value(expression.target!);
        final index = value(expression.index);
        if (target is Map) return target[index];
        if (target is List &&
            index is int &&
            index >= 0 &&
            index < target.length)
          return target[index];
        if (target is _StaticObject && target.methods.containsKey('[]')) {
          return invokeHelper(target.methods['[]']!, [
            expression.index,
          ], target);
        }
        fail('Unsupported static index target or out-of-range index.', line);
      }
      if (expression is SetOrMapLiteral) {
        if (expression.elements.length > 20000)
          fail('Static map size limit exceeded.', line);
        if (expression.elements.any((e) => e is! MapLiteralEntry))
          fail('Only plain static map entries are supported.', line);
        final map = <Object?, Object?>{};
        for (final entry in expression.elements.cast<MapLiteralEntry>()) {
          final key = value(entry.key);
          if (key is! String && key is! int && key is! _StaticEnum)
            fail('Unsupported static map key.', line);
          if (map.containsKey(key)) fail('Duplicate static map key.', line);
          map[key] = value(entry.value);
        }
        return map;
      }
      if (--evaluationBudget < 0)
        fail('Static evaluation budget exceeded.', line);
      if (expression is FunctionExpression) {
        final outer = expression.body;
        if (expression.parameters?.parameters.isEmpty != false &&
            outer is ExpressionFunctionBody &&
            !outer.isAsynchronous) {
          final body = outer.expression;
          Object? callback;
          ArgumentList? callbackArguments;
          if (body is MethodInvocation) {
            callbackArguments = body.argumentList;
            if (body.target == null)
              callback = scope[body.methodName.name];
            else if (staticReceiver(body.target)) {
              final target = value(body.target!);
              if (target is _StaticObject)
                callback = target.fields[body.methodName.name];
            }
          } else if (body is FunctionExpressionInvocation) {
            callback = value(body.function);
            callbackArguments = body.argumentList;
          }
          if (callback is _ExternalCallback) {
            if (callback.routes == null)
              fail(
                'External callback ${callback.name} has no native event bridge.',
              );
            final args = callbackArguments!.arguments;
            if (args.length != 1 || args.single is NamedExpression)
              fail('Route callbacks require one static string argument.');
            final argument = value(args.single);
            if (argument is! String || !callback.routes!.containsKey(argument))
              fail('No explicit route for callback argument $argument.');
            return _NativeNavigation(callback.routes![argument]!);
          }
        }
        if (frame == null ||
            !evaluatingState ||
            expression.parameters?.parameters.isNotEmpty == true ||
            outer is! ExpressionFunctionBody ||
            outer.isAsynchronous)
          fail('Unsupported event callback.');
        final call = outer.expression;
        if (call is! MethodInvocation ||
            call.target != null ||
            call.methodName.name != 'setState' ||
            call.argumentList.arguments.length != 1)
          fail('Events require () => setState(() => state update).');
        final callback = call.argumentList.arguments.single;
        if (callback is! FunctionExpression ||
            callback.parameters?.parameters.isNotEmpty == true ||
            callback.body is! ExpressionFunctionBody ||
            callback.body.isAsynchronous)
          fail('Unsupported setState body.');
        final update = (callback.body as ExpressionFunctionBody).expression;
        Expression? target;
        Object? rhs;
        if (update is AssignmentExpression) {
          target = update.leftHandSide;
          final op = update.operator.lexeme;
          if (!['=', '+=', '-='].contains(op))
            fail('Unsupported state assignment $op.');
          rhs = value(update.rightHandSide);
          if (op != '=')
            rhs = ReactiveValue.operation(op[0], [value(target), rhs]);
        } else if (update is PostfixExpression || update is PrefixExpression) {
          final operand = update is PostfixExpression
              ? update.operand
              : (update as PrefixExpression).operand;
          final op = update is PostfixExpression
              ? update.operator.lexeme
              : (update as PrefixExpression).operator.lexeme;
          if (!['++', '--'].contains(op)) fail('Unsupported state update $op.');
          target = operand;
          rhs = ReactiveValue.operation(op[0], [value(operand), 1]);
        }
        if (target is! SimpleIdentifier ||
            !frame!.initial.containsKey(target.name))
          fail('setState must assign a declared local state field.');
        final expressionValue = ReactiveValue.of(rhs);
        if (expressionValue.type !=
            ReactiveValue.literal(frame!.initial[target.name]).type)
          fail('State assignment type does not match ${target.name}.');
        return ReactiveAction(target.name, expressionValue);
      }
      if (expression is SimpleStringLiteral) return expression.value;
      if (expression is AdjacentStrings) {
        final parts = expression.strings.map(value).toList();
        if (parts.every((part) => part is String)) return parts.join();
      }
      if (expression is ParenthesizedExpression)
        return value(expression.expression);
      if (expression is ConditionalExpression) {
        final condition = value(expression.condition);
        if (condition is ReactiveValue) {
          final yes = value(expression.thenExpression),
              no = value(expression.elseExpression);
          if (condition.type != 'bool')
            fail('Reactive conditions require bool.');
          if ((yes is ReactiveAction && no == null) ||
              (yes == null && no is ReactiveAction)) {
            final action = (yes ?? no) as ReactiveAction;
            final enabled = yes == null
                ? ReactiveValue.operation('!', [condition])
                : condition;
            return ReactiveAction(
              action.field,
              action.value,
              enabled: ReactiveValue.operation('&&', [enabled, action.enabled]),
            );
          }
          if (yes is List && no is List)
            return _ConditionalList(condition, yes, no);
          return ReactiveValue.operation('choose', [condition, yes, no]);
        }
        if (condition is! bool)
          fail('Static condition must be a boolean.', line);
        return value(
          condition ? expression.thenExpression : expression.elseExpression,
        );
      }
      if (expression is StringInterpolation) {
        final parts = expression.elements.map((element) {
          if (element is InterpolationString) return element.value;
          final part = value((element as InterpolationExpression).expression);
          if (part is ReactiveValue)
            return ReactiveValue.operation('string', [part]);
          if (part == null || part is String || part is num || part is bool)
            return part.toString();
          fail('Only primitive values may be interpolated.', line);
        }).toList();
        if (parts.any((part) => part is ReactiveValue)) {
          return parts.fold<ReactiveValue>(
            ReactiveValue.literal(''),
            (result, part) => ReactiveValue.operation('+', [result, part]),
          );
        }
        return parts.join();
      }
      if (expression is BinaryExpression) {
        final op = expression.operator.lexeme;
        final a = value(expression.leftOperand);
        if (op == '??') {
          if (a is ReactiveValue)
            fail('Reactive null coalescing is unsupported.', line);
          return a ?? value(expression.rightOperand);
        }
        if (a is ReactiveValue)
          return ReactiveValue.operation(op, [
            a,
            value(expression.rightOperand),
          ]);
        if (op == '&&' || op == '||') {
          if (a is! bool) fail('Boolean operator requires booleans.', line);
          if (op == '&&' && !a || op == '||' && a) return a;
          final b = value(expression.rightOperand);
          if (b is ReactiveValue) return ReactiveValue.operation(op, [a, b]);
          if (b is! bool) fail('Boolean operator requires booleans.', line);
          return b;
        }
        final b = value(expression.rightOperand);
        if (b is ReactiveValue) return ReactiveValue.operation(op, [a, b]);
        if (op == '==' || op == '!=') {
          bool primitive(Object? v) =>
              v == null || v is num || v is String || v is bool;
          if (a != null && b != null && (!primitive(a) || !primitive(b)))
            fail(
              'Equality between non-primitive objects is unsupported.',
              line,
            );
          return op == '==' ? a == b : a != b;
        }
        if (op == '+' && a is String && b is String) return a + b;
        if (a is! num || b is! num)
          fail('Arithmetic requires static numbers.', line);
        if (['/', '~/', '%'].contains(op) && b == 0)
          fail('Division by zero.', line);
        final Object number = switch (op) {
          '+' => a + b,
          '-' => a - b,
          '*' => a * b,
          '/' => a / b,
          '~/' => a ~/ b,
          '%' => a % b,
          '<' => a < b,
          '>' => a > b,
          '<=' => a <= b,
          '>=' => a >= b,
          '==' => a == b,
          '!=' => a != b,
          _ => fail('Unsupported static operator $op.', line),
        };
        if (number is num && !number.isFinite)
          fail('Arithmetic must remain finite.', line);
        return number;
      }
      if (expression is IntegerLiteral) return expression.value;
      if (expression is DoubleLiteral) return expression.value;
      if (expression is BooleanLiteral) return expression.value;
      if (expression is NullLiteral) return null;
      if (expression is SimpleIdentifier &&
          scope.containsKey(expression.name)) {
        return scope[expression.name];
      }
      final className = expression is Identifier
          ? resolved?.symbol(expression.element) ?? expression.toSource()
          : expression is PropertyAccess && resolved != null
          ? resolved.symbol(expression.propertyName.element)
          : null;
      if (className != null && classes.containsKey(className))
        return staticClass(classes[className]!);
      final getterName = expression is SimpleIdentifier
          ? expression.name
          : expression is PropertyAccess && expression.target is ThisExpression
          ? expression.propertyName.name
          : null;
      if (getterName != null && instanceGetters.containsKey(getterName)) {
        final getterKey = (instanceFields, getterName);
        if (evaluatingGetters.contains(getterKey) ||
            evaluatingGetters.length >= 64)
          fail('Recursive or excessively nested getter $getterName.', line);
        final previous = scope;
        scope = {
          ...instanceFields,
        }; // Getters cannot capture build-local variables.
        evaluatingGetters.add(getterKey);
        try {
          return value(instanceGetters[getterName]!);
        } finally {
          scope = previous;
          evaluatingGetters.removeLast();
        }
      }
      if (expression is PostfixExpression &&
          expression.operator.lexeme == '!') {
        final operand = value(expression.operand);
        if (operand == null)
          fail('Null assertion failed in the compiled branch.', line);
        return operand;
      }
      final constantName = resolved != null && expression is Identifier
          ? resolved.symbol(expression.element)
          : resolved != null && expression is PropertyAccess
          ? resolved.symbol(expression.propertyName.element)
          : expression is SimpleIdentifier
          ? expression.name
          : null;
      if (constantName != null && constants.containsKey(constantName)) {
        final name = constantName;
        if (constantValues.containsKey(name)) return constantValues[name];
        if (resolving.contains(name)) {
          fail('Cyclic constant: ${[...resolving, name].join(' → ')}.', line);
        }
        if (resolving.length >= 128)
          fail('Constant nesting limit exceeded.', line);
        resolving.add(name);
        final previous = scope;
        final previousFields = instanceFields;
        final previousGetters = instanceGetters;
        final previousMethods = instanceMethods;
        instanceGetters = {};
        instanceMethods = {};
        instanceFields = {};
        scope = {}; // Top-level initializers cannot capture widget fields.
        try {
          return constantValues[name] = value(constants[name]!);
        } finally {
          scope = previous;
          instanceFields = previousFields;
          instanceGetters = previousGetters;
          instanceMethods = previousMethods;
          resolving.removeLast();
        }
      }
      if (expression is PrefixExpression && expression.operator.lexeme == '!') {
        final operand = value(expression.operand);
        if (operand is ReactiveValue)
          return ReactiveValue.operation('!', [operand]);
        if (operand is bool) return !operand;
        fail('Static ! requires a boolean.', line);
      }
      if (expression is PropertyAccess &&
          expression.target is ThisExpression &&
          instanceFields.containsKey(expression.propertyName.name)) {
        return instanceFields[expression.propertyName.name];
      }
      if (expression is PrefixExpression && expression.operator.lexeme == '-') {
        final operand = value(expression.operand);
        if (operand is ReactiveValue)
          return ReactiveValue.operation('negate', [operand]);
        if (operand is num) return -operand;
      }
      if (expression is ListLiteral) {
        final items = <Object?>[];
        late void Function(CollectionElement) append;
        void guarded(ReactiveValue condition, void Function() generate) {
          final start = items.length;
          generate();
          final children = items.sublist(start);
          items.removeRange(start, items.length);
          items.add(_GuardedChildren(condition, children));
        }

        append = (CollectionElement element) {
          if (--evaluationBudget < 0)
            fail('Static evaluation budget exceeded.', line);
          if (element is Expression) {
            items.add(value(element));
          } else if (element is IfElement) {
            if (element.caseClause != null) {
              final input = value(element.expression);
              final previous = scope;
              scope = {...previous};
              try {
                if (bindPattern(element.caseClause!.guardedPattern, input)) {
                  append(element.thenElement);
                  return;
                }
              } finally {
                scope = previous;
              }
              if (element.elseElement != null) append(element.elseElement!);
              return;
            }
            final condition = value(element.expression);
            if (condition is ReactiveValue && condition.type == 'bool') {
              guarded(condition, () => append(element.thenElement));
              if (element.elseElement != null)
                guarded(
                  ReactiveValue.operation('!', [condition]),
                  () => append(element.elseElement!),
                );
              return;
            }
            if (condition is! bool)
              fail('Collection condition must be a boolean.', line);
            if (condition) {
              append(element.thenElement);
            } else if (element.elseElement != null) {
              append(element.elseElement!);
            }
          } else if (element is ForElement) {
            final parts = element.forLoopParts;
            if (element.awaitKeyword != null ||
                parts is! ForEachPartsWithDeclaration)
              fail(
                'Collections support synchronous for-in with a declared variable only.',
                line,
              );
            final iterable = value(parts.iterable);
            void iterate(List<Object?> input) {
              final previous = scope;
              try {
                for (final item in input) {
                  scope = {...previous, parts.loopVariable.name.lexeme: item};
                  append(element.body);
                }
              } finally {
                scope = previous;
              }
            }

            if (iterable is _ConditionalList) {
              var shared = 0;
              while (shared < iterable.yes.length &&
                  shared < iterable.no.length) {
                final a = iterable.yes[shared], b = iterable.no[shared];
                if (!identical(a, b) &&
                    !(a.runtimeType == b.runtimeType &&
                        (a == null || a is String || a is num || a is bool) &&
                        a == b))
                  break;
                shared++;
              }
              iterate(iterable.yes.take(shared).toList());
              if (shared < iterable.yes.length)
                guarded(
                  iterable.condition,
                  () => iterate(iterable.yes.skip(shared).toList()),
                );
              if (shared < iterable.no.length)
                guarded(
                  ReactiveValue.operation('!', [iterable.condition]),
                  () => iterate(iterable.no.skip(shared).toList()),
                );
            } else if (iterable is List) {
              iterate(iterable);
            } else
              fail(
                'Collection for-in requires a static or conditionally selected static list.',
                line,
              );
          } else if (element is SpreadElement) {
            final spread = value(element.expression);
            if (spread == null && element.isNullAware) return;
            if (spread is! List) fail('Static spread requires a list.', line);
            if (items.length + spread.length > 20000) {
              fail('Static collection size limit exceeded.', line);
            }
            items.addAll(spread);
          } else {
            fail(
              'Unsupported static collection element: ${element.toSource()}.',
              line,
            );
          }
        };

        for (final element in expression.elements) {
          append(element);
        }
        return items;
      }
      Object? cachedMethodTarget;
      var methodTargetKnown = false;
      Object? methodTarget(Expression target) {
        if (!methodTargetKnown) {
          cachedMethodTarget = value(target);
          methodTargetKnown = true;
        }
        return cachedMethodTarget;
      }

      if (expression is MethodInvocation) {
        final name = expression.methodName.name;
        if ((expression.target == null ||
                expression.target is ThisExpression) &&
            (expression.target is ThisExpression || !scope.containsKey(name)) &&
            instanceMethods.containsKey(name)) {
          final method = instanceMethods[name]!;
          if (resolved != null &&
              expression.methodName.element != method.declaredFragment?.element)
            fail('Helper call must resolve to the current instance method.');
          return invokeHelper(method, expression.argumentList.arguments, null);
        }
        if (expression.target != null && staticReceiver(expression.target)) {
          final target = methodTarget(expression.target!);
          if (target is _StaticObject &&
              target.fields[name] is _ExternalCallback)
            fail('External callback $name has no native event bridge.');
          if (target is _StaticObject && target.methods.containsKey(name)) {
            final method = target.methods[name]!;
            if (resolved != null &&
                expression.methodName.element !=
                    method.declaredFragment?.element)
              fail('Helper call must resolve to the model instance method.');
            return invokeHelper(
              method,
              expression.argumentList.arguments,
              target,
            );
          }
        }
      }
      if (expression is MethodInvocation &&
          expression.target != null &&
          staticReceiver(expression.target)) {
        final method = expression.methodName.name;
        if (['take', 'skip', 'toList', 'join'].contains(method)) {
          final target = methodTarget(expression.target!);
          if (target is! List) fail('Static $method requires a list.', line);
          final args = expression.argumentList.arguments;
          if (method == 'toList') {
            if (args.length > 1 ||
                args.any(
                  (a) =>
                      a is! NamedExpression ||
                      a.name.label.name != 'growable' ||
                      value(a.expression) is! bool,
                ))
              fail('toList supports optional static growable only.', line);
            return List<Object?>.of(target);
          }
          if (method == 'join') {
            if (args.length > 1 || args.any((a) => a is NamedExpression))
              fail('join accepts one static separator.', line);
            final separator = args.isEmpty ? '' : value(args.single);
            if (separator is! String ||
                target.any(
                  (v) => v != null && v is! String && v is! num && v is! bool,
                ))
              fail(
                'join requires primitive data and a static string separator.',
                line,
              );
            return target.join(separator);
          }
          if (args.length != 1 || args.single is NamedExpression)
            fail('$method needs a static count.', line);
          final count = value(args.single);
          if (count is! int || count < 0)
            fail('$method count must be a nonnegative static integer.', line);
          return (method == 'take' ? target.take(count) : target.skip(count))
              .toList();
        }
      }
      if (expression is MethodInvocation) {
        final method = expression.methodName.name;
        final element = expression.methodName.element;
        final frameworkTheme = resolved == null
            ? expression.target?.toSource() == 'Theme'
            : element?.enclosingElement2?.name3 == 'Theme' &&
                  element?.library2?.uri.toString().startsWith(
                        'package:flutter/',
                      ) ==
                      true;
        if (method == 'of' && frameworkTheme) {
          if (staticTheme == null)
            fail(
              'Theme.of requires an explicit staticTheme snapshot; inherited themes are not inferred.',
              line,
            );
          if (expression.argumentList.arguments.length != 1)
            fail('Theme.of expects context.', line);
          return staticTheme;
        }
        if (method == 'extension' &&
            expression.target != null &&
            identical(methodTarget(expression.target!), staticTheme)) {
          final types = expression.typeArguments?.arguments;
          if (types?.length != 1 ||
              types!.single is! NamedType ||
              expression.argumentList.arguments.isNotEmpty)
            fail('Theme.extension requires one named type and no arguments.');
          final type = types.single as NamedType;
          final identity = resolved?.symbol(type.element2) ?? type.name2.lexeme;
          if (!themeExtensions.containsKey(identity))
            fail(
              'Theme extension $identity requires an explicit constant snapshot.',
            );
          return themeExtensions[identity];
        }
        if (expression.target != null &&
            ['copyWith', 'withValues'].contains(method)) {
          final target = methodTarget(expression.target!);
          final args = <String, Object?>{};
          for (final arg in expression.argumentList.arguments) {
            if (arg is! NamedExpression)
              fail('$method requires named arguments.', line);
            args[arg.name.label.name] = value(arg.expression);
          }
          if (method == 'copyWith' &&
              target is _Call &&
              target.name == 'TextStyle') {
            return _Call(
              'TextStyle',
              [],
              {
                ...target.named,
                for (final entry in args.entries)
                  if (entry.value != null) entry.key: entry.value,
              },
              line,
              expression,
            );
          }
          if (method == 'withValues' &&
              target is _StaticColor &&
              args.keys.every((k) => k == 'alpha')) {
            final alpha = args['alpha'] ?? target.alpha;
            if (alpha is! num || !alpha.isFinite || alpha < 0 || alpha > 1)
              fail('Color alpha must be between zero and one.', line);
            return _StaticColor(target.hex, alpha.toDouble());
          }
          fail('Unsupported static $method target.', line);
        }
      }
      if (expression is PrefixedIdentifier &&
          staticReceiver(expression.prefix)) {
        return property(value(expression.prefix), expression.identifier.name);
      }
      if (expression is PropertyAccess &&
          expression.target is! ThisExpression &&
          staticReceiver(expression.target)) {
        return property(
          value(expression.target!),
          expression.propertyName.name,
        );
      }
      if (expression is PrefixedIdentifier || expression is PropertyAccess) {
        if (resolved != null) return resolved.frameworkValue(expression);
        if (expression is PrefixedIdentifier) return expression.toSource();
      }
      String? name;
      ArgumentList? args;
      if (expression is InstanceCreationExpression) {
        name =
            resolved?.constructor(expression) ??
            expression.constructorName.toSource();
        args = expression.argumentList;
      } else if (expression is MethodInvocation) {
        if (resolved != null) {
          fail(
            'Function/method calls are not static widget constructors: ${expression.toSource()}.',
            line,
          );
        }
        name = expression.target == null
            ? expression.methodName.name
            : '${expression.target!.toSource()}.${expression.methodName.name}';
        args = expression.argumentList;
      }
      if (name != null && args != null) {
        final named = <String, Object?>{};
        final positional = <Object?>[];
        for (final argument in args.arguments) {
          if (argument is NamedExpression) {
            named[argument.name.label.name] = value(argument.expression);
          } else {
            positional.add(value(argument));
          }
        }
        final call = _Call(name, positional, named, line, expression);
        if (['DateTime', 'DateTime.utc'].contains(name) &&
            !classes.containsKey('DateTime')) {
          if (named.isNotEmpty || positional.isEmpty || positional.length > 3)
            fail(
              'Calendar DateTime constructors accept year and optional month/day only.',
            );
          return calendarDate(
            positional[0],
            positional.length > 1 ? positional[1] : 1,
            positional.length > 2 ? positional[2] : 1,
          );
        }
        if (name == 'Color') return color(call);
        if (classes[name] case final node?) {
          if (isThemeExtension(node)) return instantiateExtension(call);
          if (node.extendsClause == null) return instantiateModel(call);
        }
        return call;
      }
      fail(
        'Expected a static literal or supported constructor; found '
        '`${expression.toSource()}`. Move dynamic UI into an explicit island.',
        line,
        expression is SimpleIdentifier || expression is ThisExpression
            ? 'requires-context'
            : 'unsupported',
      );
    }

    void check(
      _Call call,
      Set<String> named, [
      int positional = 0,
      bool widgetKeys = true,
    ]) {
      if (call.origin != null) currentNode = call.origin;
      final unknown = call.named.keys.toSet().difference({
        ...named,
        if (widgetKeys) 'key',
      });
      if (unknown.isNotEmpty || call.positional.length != positional) {
        fail(
          '${call.name}: unsupported arguments ${unknown.join(', ')} '
          '(expected $positional positional).',
          call.line,
        );
      }
      if (!widgetKeys) return;
      if (call.named['key'] case final _Call key) {
        if (key.name != 'ValueKey' ||
            key.positional.length != 1 ||
            key.named.isNotEmpty) {
          fail('Only a literal ValueKey is supported.', call.line);
        }
      } else if (call.named['key'] != null) {
        fail('Only a literal ValueKey is supported.', call.line);
      }
    }

    String pixels(Object? number) {
      if (number is! num || !number.isFinite || number < 0) {
        fail('Expected a finite non-negative layout number; found $number.');
      }
      return '${number % 1 == 0 ? number.toStringAsFixed(0) : number}px';
    }

    String padding(Object? object) {
      if (object is! _Call) fail('Expected an EdgeInsets constructor.');
      if (object.name == 'EdgeInsets.all') {
        check(object, {}, 1);
        return pixels(object.positional.single);
      }
      if (object.name == 'EdgeInsets.symmetric') {
        check(object, {'horizontal', 'vertical'});
        return '${pixels(object.named['vertical'] ?? 0)} ${pixels(object.named['horizontal'] ?? 0)}';
      }
      fail('Unsupported padding: ${object.name}.', object.line);
    }

    String textStyle(Object? object) {
      if (object is! _Call || object.name != 'TextStyle') {
        fail('Expected a TextStyle constructor.');
      }
      check(object, {'fontSize', 'fontWeight', 'color', 'height'});
      final css = <String>[];
      if (object.named['height'] != null) {
        final height = object.named['height'];
        if (height is! num || !height.isFinite || height <= 0)
          fail('Text height must be finite and positive.');
        css.add('line-height:$height');
      }
      if (object.named['color'] != null)
        css.add('color:${color(object.named['color']).css}');
      if (object.named.containsKey('fontSize')) {
        css.add('font-size:${pixels(object.named['fontSize'])}');
      }
      if (object.named.containsKey('fontWeight')) {
        final weight = object.named['fontWeight'];
        final mapped = {
          'FontWeight.bold': '700',
          'FontWeight.normal': '400',
          for (var i = 1; i <= 9; i++) 'FontWeight.w${i}00': '${i}00',
        }[weight];
        if (mapped == null) fail('Unsupported font weight: $weight.');
        css.add('font-weight:$mapped');
      }
      return css.join(';');
    }

    void validateInput(
      TypeAnnotation? annotation,
      Object? input,
      String label,
    ) {
      if (annotation is! NamedType) return;
      if (input == null && annotation.question != null) return;
      if (dateType(annotation) && input is! _StaticDate)
        fail('$label requires a calendar date snapshot.');
      final primitiveType = annotation.name2.lexeme;
      if (primitiveType == 'BuildContext' && input is! _StaticContext)
        fail('$label requires the static build context.');
      if (input is ReactiveValue && input.type != primitiveType)
        fail('$label requires ${annotation.toSource()}.');
      if (input is! ReactiveValue &&
          (primitiveType == 'String' && input is! String ||
              primitiveType == 'int' && input is! int ||
              primitiveType == 'bool' && input is! bool ||
              ['double', 'num'].contains(primitiveType) && input is! num))
        fail('$label requires ${annotation.toSource()}.');
      if (primitiveType == 'Map') {
        final types = annotation.typeArguments?.arguments;
        if (input is! Map || types?.length != 2)
          fail('$label requires an explicitly typed static map.');
        for (final entry in input.entries) {
          validateInput(types![0], entry.key, '$label key');
          validateInput(types[1], entry.value, '$label value');
        }
        return;
      }
      if (primitiveType == 'List' && input is! List)
        fail('$label requires a list.');
      if (annotation.name2.lexeme == 'List' &&
          annotation.typeArguments?.arguments.length == 1 &&
          input is List) {
        for (final entry in input) {
          validateInput(
            annotation.typeArguments!.arguments.single,
            entry,
            label,
          );
        }
        return;
      }
      final identity = resolved == null
          ? annotation.name2.lexeme
          : resolved.symbol(annotation.element2);
      if (enumValues.values.contains(identity) &&
          (input is! _StaticEnum || input.type != identity))
        fail('$label requires enum ${annotation.toSource()}.');
      final model = classes[identity];
      if (model != null &&
          model.extendsClause == null &&
          (input is! _StaticObject || input.model != identity))
        fail('$label requires model ${annotation.toSource()}.');
    }

    bindPattern = (guarded, input) {
      if (input is ReactiveValue) fail('Pattern inputs must be static.');
      var pattern = guarded.pattern;
      final nullable = pattern is NullCheckPattern;
      if (pattern is NullCheckPattern) pattern = pattern.pattern;
      if (pattern is! DeclaredVariablePattern ||
          pattern.keyword?.lexeme != 'final' ||
          pattern.type != null)
        fail(
          'Patterns support final untyped variable bindings with optional null checks only.',
        );
      if (nullable && input == null) return false;
      scope[pattern.name.lexeme] = input;
      final guard = guarded.whenClause;
      if (guard == null) return true;
      final condition = value(guard.expression);
      if (condition is! bool) fail('Pattern guard must be a static boolean.');
      return condition;
    };

    Map<String, Object?> bindFields(
      ClassDeclaration node,
      String name,
      _Call? invocation,
    ) {
      final fields = node.members
          .whereType<FieldDeclaration>()
          .where((field) => !field.isStatic)
          .toList();
      for (final field in fields) {
        if (!field.fields.isFinal ||
            field.fields.variables.any((v) => v.initializer != null)) {
          fail(
            '$name only supports final fields initialized by constructor parameters.',
          );
        }
      }
      // Named factories are declarations only; snapshot construction never calls them.
      final constructors = node.members
          .whereType<ConstructorDeclaration>()
          .where((c) => !(c.name != null && c.factoryKeyword != null))
          .toList();
      if (constructors.length > 1)
        fail('$name supports only one unnamed constructor.');
      final bindings = <String, Object?>{};
      final call =
          invocation ??
          _Call(
            name,
            [],
            {},
            (resolved?.unitFor(node).lineInfo ?? result.lineInfo)
                .getLocation(node.offset)
                .lineNumber,
          );
      if (constructors.isEmpty) {
        check(call, {}, 0, node.extendsClause != null);
      } else {
        final constructor = constructors.single;
        if (constructor.name != null ||
            constructor.factoryKeyword != null ||
            constructor.initializers.isNotEmpty ||
            constructor.body is! EmptyFunctionBody ||
            constructor.redirectedConstructor != null) {
          fail(
            '$name needs an unnamed constructor without a body or initializer list.',
          );
        }
        final allowed = <String>{};
        var position = 0;
        final previous = scope;
        final defaultFields = instanceFields;
        final defaultGetters = instanceGetters;
        final defaultMethods = instanceMethods;
        instanceFields = {};
        instanceGetters = {};
        instanceMethods = {};
        scope = {};
        try {
          for (final wrapped in constructor.parameters.parameters) {
            final parameter = wrapped is DefaultFormalParameter
                ? wrapped.parameter
                : wrapped;
            if (parameter is SuperFormalParameter &&
                parameter.name.lexeme == 'key')
              continue;
            if (parameter is! FieldFormalParameter) {
              fail('$name supports only this.field parameters and super.key.');
            }
            final field = parameter.name.lexeme;
            final named = wrapped.isNamed;
            if (named) allowed.add(field);
            final provided = named
                ? call.named.containsKey(field)
                : position < call.positional.length;
            if (provided) {
              bindings[field] = named
                  ? call.named[field]
                  : call.positional[position];
            } else if (wrapped.isRequiredNamed ||
                wrapped.isRequiredPositional) {
              fail(
                '$name is missing required argument $field.',
                call.line,
                'requires-inputs',
              );
            } else {
              final defaultValue = wrapped is DefaultFormalParameter
                  ? wrapped.defaultValue
                  : null;
              bindings[field] = defaultValue == null
                  ? null
                  : value(defaultValue);
            }
            if (!named) position++;
          }
        } finally {
          scope = previous;
          instanceFields = defaultFields;
          instanceGetters = defaultGetters;
          instanceMethods = defaultMethods;
        }
        if (call.positional.length > position)
          fail('$name has too many positional arguments.', call.line);
        check(
          call,
          allowed,
          call.positional.length,
          node.extendsClause != null,
        );
      }
      for (final declaration in fields) {
        final declaredType = declaration.fields.type?.toSource();
        for (final field in declaration.fields.variables) {
          final name = field.name.lexeme;
          if (!bindings.containsKey(name) || declaredType == null) continue;
          final item = bindings[name];
          validateInput(
            declaration.fields.type,
            item,
            'Constructor field $name',
          );
          if (item == null && declaredType.endsWith('?')) continue;
          final type = declaredType.replaceAll('?', '');
          if (type.startsWith('List<')) {
            if (item is! List)
              fail('Constructor field $name requires $declaredType.');
            final elementType = type.substring(5, type.length - 1);
            if (elementType == 'String' && item.any((v) => v is! String) ||
                elementType == 'int' && item.any((v) => v is! int) ||
                elementType == 'bool' && item.any((v) => v is! bool))
              fail('Constructor field $name requires $declaredType elements.');
          }
          if (item is ReactiveValue) {
            if (item.type != type)
              fail('Constructor field $name requires $declaredType.');
          } else if (type == 'double' && item is num) {
            bindings[name] = item.toDouble();
          } else if (type == 'double' ||
              type == 'int' && item is! int ||
              type == 'String' && item is! String ||
              type == 'bool' && item is! bool) {
            fail('Constructor field $name requires $declaredType.');
          }
        }
      }
      final declared = fields
          .expand((field) => field.fields.variables.map((v) => v.name.lexeme))
          .toSet();
      if (declared.difference(bindings.keys.toSet()).isNotEmpty) {
        fail(
          '$name has fields not initialized by a supported constructor parameter.',
        );
      }
      return bindings;
    }

    final constructingModels = <String>[];
    instantiateExtension = (call) {
      final node = classes[call.name]!;
      if (!isThemeExtension(node) ||
          node.withClause != null ||
          node.implementsClause != null)
        fail('Theme snapshots require a direct ThemeExtension subclass.');
      final fields = bindFields(node, call.name, call);
      bool data(Object? v) =>
          v == null ||
          v is String ||
          v is bool ||
          v is num && v.isFinite ||
          v is _StaticColor ||
          v is _StaticEnum ||
          v is List && v.every(data) ||
          v is Map && v.entries.every((e) => data(e.key) && data(e.value));
      if (!fields.values.every(data))
        fail('Theme extension snapshots require static data fields.');
      return _StaticObject(
        fields,
        model: call.name,
        methods: {
          for (final m in node.members.whereType<MethodDeclaration>())
            if (!m.isStatic && !m.isGetter && !m.isSetter) m.name.lexeme: m,
        },
        getters: {
          for (final m in node.members.whereType<MethodDeclaration>())
            if (!m.isStatic &&
                m.isGetter &&
                m.body is ExpressionFunctionBody &&
                !m.body.isAsynchronous)
              m.name.lexeme: (m.body as ExpressionFunctionBody).expression,
        },
      );
    };
    instantiateModel = (_Call call) {
      final node = classes[call.name]!;
      currentNode = node;
      if (--evaluationBudget < 0 ||
          constructingModels.length >= 64 ||
          constructingModels.contains(call.name))
        fail('Recursive or excessive model construction.');
      if (node.extendsClause != null ||
          node.withClause != null ||
          node.implementsClause != null ||
          node.typeParameters != null ||
          node.members.any(
            (m) =>
                m is! FieldDeclaration &&
                m is! ConstructorDeclaration &&
                m is! MethodDeclaration,
          ) ||
          node.members.whereType<MethodDeclaration>().any(
            (m) =>
                !m.isStatic &&
                (m.isSetter ||
                    m.typeParameters != null ||
                    m.body is! ExpressionFunctionBody ||
                    m.body.isAsynchronous),
          ) ||
          node.members.whereType<FieldDeclaration>().any((m) => m.isStatic))
        fail(
          'Models support plain final fields and pure expression getters/helpers only.',
        );
      constructingModels.add(call.name);
      try {
        bool supportedData(Object? item) =>
            item == null ||
            item is String ||
            item is bool ||
            item is num && item.isFinite ||
            item is _StaticDate ||
            item is _StaticObject && item.model != null ||
            item is List && item.every(supportedData) ||
            item is Map &&
                item.entries.every(
                  (e) =>
                      (e.key is String ||
                          e.key is int ||
                          e.key is _StaticEnum) &&
                      supportedData(e.value),
                );
        bool supportedType(TypeAnnotation? type) {
          if (type is! NamedType) return false;
          if (dateType(type)) return true;
          if ([
            'String',
            'int',
            'double',
            'bool',
            'num',
          ].contains(type.name2.lexeme))
            return true;
          if (type.name2.lexeme == 'Map') {
            final types = type.typeArguments?.arguments;
            return types?.length == 2 &&
                types![0] is NamedType &&
                (['String', 'int'].contains(types[0].toSource()) ||
                    enumValues.values.contains(
                      resolved?.symbol((types[0] as NamedType).element2) ??
                          types[0].toSource(),
                    )) &&
                (types[1].toSource() == 'dynamic' || supportedType(types[1]));
          }
          if (type.name2.lexeme == 'List')
            return type.typeArguments?.arguments.length == 1 &&
                supportedType(type.typeArguments!.arguments.single);
          final identity = resolved == null
              ? type.name2.lexeme
              : resolved.symbol(type.element2);
          return classes[identity]?.extendsClause == null &&
              classes.containsKey(identity);
        }

        final fields = bindFields(node, call.name, call);
        if (node.members.whereType<FieldDeclaration>().any(
          (f) =>
              !supportedType(f.fields.type) &&
              !(f.fields.type is NamedType &&
                  (f.fields.type as NamedType).question != null &&
                  f.fields.variables.every(
                    (v) => fields[v.name.lexeme] == null,
                  )),
        ))
          fail(
            'Model fields require explicit supported primitive, list, map or local model types.',
          );
        if (!fields.values.every(supportedData))
          fail('Model inputs require static primitive/list/map/model values.');
        if (fields.values.any((v) => v is ReactiveValue || v is ReactiveAction))
          fail('Model inputs must be static.');
        modelCount++;
        return _StaticObject(
          fields,
          model: call.name,
          methods: {
            for (final m in node.members.whereType<MethodDeclaration>())
              if (!m.isGetter && !m.isStatic) m.name.lexeme: m,
          },
          getters: {
            for (final m in node.members.whereType<MethodDeclaration>())
              if (m.isGetter && !m.isStatic)
                m.name.lexeme: (m.body as ExpressionFunctionBody).expression,
          },
        );
      } finally {
        constructingModels.removeLast();
      }
    };
    final activeModelGetters = <(_StaticObject, String)>[];
    modelGetter = (object, name) {
      final key = (object, name);
      if (activeModelGetters.contains(key) || activeModelGetters.length >= 64)
        fail('Recursive or excessively nested model getter $name.');
      final previous = scope;
      final previousFields = instanceFields;
      final previousGetters = instanceGetters;
      final previousMethods = instanceMethods;
      final previousState = evaluatingState;
      activeModelGetters.add(key);
      scope = {...object.fields};
      instanceFields = object.fields;
      instanceGetters = object.getters;
      instanceMethods = object.methods;
      evaluatingState = false;
      try {
        return value(object.getters[name]!);
      } finally {
        scope = previous;
        instanceFields = previousFields;
        instanceGetters = previousGetters;
        instanceMethods = previousMethods;
        evaluatingState = previousState;
        activeModelGetters.removeLast();
      }
    };

    final activeHelpers = <(Map<String, Object?>, MethodDeclaration)>[];
    invokeHelper = (method, arguments, receiver) {
      if (method.isSetter ||
          method.typeParameters != null ||
          method.body is! ExpressionFunctionBody ||
          method.body.isAsynchronous)
        fail('Helpers require synchronous non-generic expression bodies.');
      final fields = receiver?.fields ?? instanceFields;
      final key = (fields, method);
      if (activeHelpers.contains(key) ||
          activeHelpers.length >= 64 ||
          --evaluationBudget < 0)
        fail('Recursive or excessive helper invocation.');
      final positional = <Object?>[];
      final named = <String, Object?>{};
      for (final argument in arguments) {
        if (argument is NamedExpression) {
          final name = argument.name.label.name;
          if (named.containsKey(name)) fail('Duplicate helper argument $name.');
          named[name] = value(argument.expression);
        } else
          positional.add(value(argument));
      }
      final previous = scope;
      final previousFields = instanceFields;
      final previousGetters = instanceGetters;
      final previousMethods = instanceMethods;
      final previousState = evaluatingState;
      final previousStaticHelper = evaluatingStaticHelper;
      activeHelpers.add(key);
      try {
        final parameters = <String, Object?>{};
        final allowed = <String>{};
        var index = 0;
        // Defaults cannot capture a caller or instance.
        scope = {};
        instanceFields = {};
        instanceGetters = {};
        instanceMethods = {};
        evaluatingState = false;
        for (final wrapped in method.parameters!.parameters) {
          final parameter = wrapped is DefaultFormalParameter
              ? wrapped.parameter
              : wrapped;
          if (parameter is! SimpleFormalParameter || parameter.name == null)
            fail('Helpers support simple parameters only.');
          final name = parameter.name!.lexeme;
          if (wrapped.isNamed) allowed.add(name);
          final provided = wrapped.isNamed
              ? named.containsKey(name)
              : index < positional.length;
          final Object? input;
          if (provided)
            input = wrapped.isNamed ? named[name] : positional[index];
          else if (wrapped.isRequiredNamed || wrapped.isRequiredPositional)
            fail('Missing helper argument $name.');
          else
            input =
                wrapped is DefaultFormalParameter &&
                    wrapped.defaultValue != null
                ? value(wrapped.defaultValue!)
                : null;
          if (!wrapped.isNamed) index++;
          validateInput(parameter.type, input, 'Helper argument $name');
          parameters[name] =
              parameter.type is NamedType &&
                  (parameter.type as NamedType).name2.lexeme == 'double' &&
                  input is num
              ? input.toDouble()
              : input;
        }
        if (positional.length > index ||
            named.keys.any((name) => !allowed.contains(name)))
          fail('Unsupported helper arguments.');
        instanceFields = fields;
        instanceGetters = receiver?.getters ?? previousGetters;
        instanceMethods = receiver?.methods ?? previousMethods;
        scope = {...fields, ...parameters};
        evaluatingStaticHelper = method.isStatic;
        helperCount++;
        return value((method.body as ExpressionFunctionBody).expression);
      } finally {
        scope = previous;
        instanceFields = previousFields;
        instanceGetters = previousGetters;
        instanceMethods = previousMethods;
        evaluatingState = previousState;
        evaluatingStaticHelper = previousStaticHelper;
        activeHelpers.removeLast();
      }
    };

    Object? evaluateBuild(FunctionBody body) {
      if (body.isAsynchronous) fail('Native build must be synchronous.');
      if (body is ExpressionFunctionBody) return value(body.expression);
      if (body is! BlockFunctionBody)
        fail('Build requires an expression or bounded block.');
      var localNames = <String>{};
      ({bool returned, Object? value}) execute(Statement statement) {
        currentNode = statement;
        if (--evaluationBudget < 0) fail('Static statement budget exceeded.');
        if (statement is ReturnStatement) {
          if (statement.expression == null) fail('Build must return a widget.');
          return (returned: true, value: value(statement.expression!));
        }
        if (statement is VariableDeclarationStatement) {
          final variables = statement.variables;
          if (!(variables.isFinal || variables.isConst) ||
              variables.lateKeyword != null)
            fail('Build locals must be initialized final/const values.');
          for (final variable in variables.variables) {
            if (variable.initializer == null ||
                !localNames.add(variable.name.lexeme) ||
                frame?.initial.containsKey(variable.name.lexeme) == true)
              fail(
                'Build locals must be initialized and cannot duplicate locals or shadow state fields.',
              );
            scope[variable.name.lexeme] = value(variable.initializer!);
          }
          return (returned: false, value: null);
        }
        if (statement is IfStatement) {
          if (statement.caseClause != null)
            fail('Statement patterns are unsupported.');
          final condition = value(statement.expression);
          if (condition is! bool)
            fail('Statement if requires a static boolean.');
          final selected = condition
              ? statement.thenStatement
              : statement.elseStatement;
          return selected == null
              ? (returned: false, value: null)
              : execute(selected);
        }
        if (statement is Block) {
          final previous = scope;
          final previousNames = localNames;
          localNames = {};
          scope = {...previous};
          try {
            for (final child in statement.statements) {
              final result = execute(child);
              if (result.returned) return result;
            }
            return (returned: false, value: null);
          } finally {
            scope = previous;
            localNames = previousNames;
          }
        }
        fail('Unsupported build statement: ${statement.runtimeType}.');
      }

      final result = execute(body.block);
      if (!result.returned) fail('Build did not return a widget.');
      return result.value;
    }

    late String Function(Object?) render;
    String buildClass(
      String name, [
      _Call? invocation,
      Map<String, Object?>? stateBindings,
    ]) {
      final node = classes[name];
      if (node != null) currentNode = node;
      if (node == null)
        fail('Unknown widget $name or unsupported declaration.');
      final base = resolved == null
          ? node.extendsClause?.superclass.name2.lexeme
          : resolved.superclass(node);
      if (base == 'StatefulWidget' && stateBindings == null) {
        if (frame != null) fail('Nested native state is not supported yet.');
        if (node.withClause != null ||
            node.implementsClause != null ||
            node.members.whereType<MethodDeclaration>().any(
              (m) => m.name.lexeme != 'createState',
            ))
          fail(
            'Native stateful widgets support constructor inputs and createState only.',
          );
        final widgetInputs = bindFields(node, name, invocation);
        final creators = node.members.whereType<MethodDeclaration>().toList();
        if (creators.length != 1 ||
            creators.single.body is! ExpressionFunctionBody)
          fail('createState must directly return a State constructor.');
        final creation =
            (creators.single.body as ExpressionFunctionBody).expression;
        final stateCall = value(creation);
        if (stateCall is! _Call ||
            stateCall.named.isNotEmpty ||
            stateCall.positional.isNotEmpty ||
            !classes.containsKey(stateCall.name))
          fail(
            'createState must directly return a zero-argument State constructor.',
          );
        final stateName = stateCall.name;
        final state = classes[stateName];
        if (state == null ||
            state.withClause != null ||
            state.implementsClause != null ||
            (resolved == null
                    ? state.extendsClause?.superclass.name2.lexeme
                    : resolved.superclass(state)) !=
                'State' ||
            state.members.any(
              (m) => m is! FieldDeclaration && m is! MethodDeclaration,
            ) ||
            state.members.whereType<MethodDeclaration>().any(
              (m) =>
                  m.name.lexeme != 'build' &&
                  (m.isGetter ||
                      m.isSetter ||
                      m.isStatic ||
                      m.typeParameters != null ||
                      m.body is! ExpressionFunctionBody ||
                      m.body.isAsynchronous ||
                      [
                        'initState',
                        'dispose',
                        'didUpdateWidget',
                        'didChangeDependencies',
                        'deactivate',
                        'activate',
                        'reassemble',
                      ].contains(m.name.lexeme)),
            )) {
          fail(
            'Native State supports build and pure expression helpers; lifecycle and mixins require an island.',
          );
        }
        final initial = <String, Object>{};
        final previousScope = scope;
        final previousFields = instanceFields;
        final previousGetters = instanceGetters;
        final previousMethods = instanceMethods;
        scope = {'widget': _StaticObject(widgetInputs)};
        instanceFields = {};
        instanceGetters = {};
        instanceMethods = {};
        try {
          for (final declaration
              in state.members.whereType<FieldDeclaration>()) {
            final type = declaration.fields.type?.toSource();
            if (declaration.isStatic ||
                declaration.fields.isFinal ||
                !['bool', 'int'].contains(type))
              fail(
                'Native state fields must be mutable bool/int with pure initialized values.',
              );
            for (final field in declaration.fields.variables) {
              if (field.initializer == null)
                fail('Native state needs explicit initializers.');
              final item = value(field.initializer!);
              if (item is ReactiveValue ||
                  ReactiveValue.literal(item).type != type)
                fail('State initializer must be a static value of type $type.');
              initial[field.name.lexeme] = item as Object;
            }
          }
        } finally {
          scope = previousScope;
          instanceFields = previousFields;
          instanceGetters = previousGetters;
          instanceMethods = previousMethods;
        }
        if (initial.isEmpty || initial.length > 16)
          fail('Native state requires 1–16 bool/int fields.');
        final id = reactiveCount++;
        frame = ReactiveFrame(initial);
        try {
          final html = buildClass(stateName, null, {
            'widget': _StaticObject(widgetInputs),
            for (final entry in initial.entries)
              entry.key: ReactiveValue.field(entry.key, entry.value),
          });
          return frame!.wrap(html, id);
        } finally {
          frame = null;
        }
      }
      if (stateBindings == null && base != 'StatelessWidget') {
        fail(
          '$name must be a StatelessWidget or an explicitly configured Flutter island.',
        );
      }
      final bindings = stateBindings ?? bindFields(node, name, invocation);
      if (stack.contains(name))
        fail('Recursive widget expansion: ${[...stack, name].join(' → ')}.');
      final methods = node.members.whereType<MethodDeclaration>().where(
        (method) => method.name.lexeme == 'build',
      );
      if (methods.length != 1) fail('$name needs one build method.');
      final body = methods.single.body;
      stack.add(name);
      final previous = scope;
      final previousFields = instanceFields;
      final previousEvaluation = evaluatingState;
      final previousGetters = instanceGetters;
      final previousMethods = instanceMethods;
      instanceGetters = {
        for (final method in node.members.whereType<MethodDeclaration>())
          if (method.isGetter &&
              !method.isStatic &&
              method.body is ExpressionFunctionBody &&
              !method.body.isAsynchronous)
            method.name.lexeme:
                (method.body as ExpressionFunctionBody).expression,
      };
      instanceMethods = {
        for (final method in node.members.whereType<MethodDeclaration>())
          if (!method.isGetter &&
              !method.isSetter &&
              !method.isStatic &&
              method.name.lexeme != 'build')
            method.name.lexeme: method,
      };
      evaluatingState = stateBindings != null;
      scope = {...bindings};
      final context = _StaticContext();
      for (final parameter
          in methods.single.parameters?.parameters ?? <FormalParameter>[]) {
        if (parameter is SimpleFormalParameter &&
            parameter.type is NamedType &&
            (parameter.type as NamedType).name2.lexeme == 'BuildContext')
          scope[parameter.name!.lexeme] = context;
      }
      instanceFields = {
        ...bindings,
        if (stateBindings != null) 'context': context,
      };
      try {
        return render(evaluateBuild(body));
      } finally {
        scope = previous;
        instanceFields = previousFields;
        evaluatingState = previousEvaluation;
        instanceGetters = previousGetters;
        instanceMethods = previousMethods;
        stack.removeLast();
      }
    }

    render = (Object? object) {
      if (object is _GuardedChildren) {
        conditionalGroupCount++;
        if (frame == null)
          fail('Conditional DOM content requires a native state owner.');
        final id = frame!.bind('visible', object.condition);
        final visible = object.condition.evaluate(frame!.initial) == true;
        return '<div class="dom-branch" data-dom-visible="$id" ${visible ? '' : 'hidden'}>${object.children.map(render).join()}</div>';
      }
      if (object is! _Call)
        fail('Expected a widget constructor, found $object.');
      final call = object;
      if (call.origin != null) currentNode = call.origin;
      final n = call.named;
      counts.update(call.name, (count) => count + 1, ifAbsent: () => 1);
      if (frame != null &&
          (nativeAdapters.containsKey(call.name) ||
              islandConfig.containsKey(call.name)))
        fail('Native state cannot contain adapters or islands yet.');
      if (nativeAdapters.containsKey(call.name)) {
        if (!classes.containsKey(call.name))
          fail('Adapter widget must exist in the source file.');
        if (nativeAdapters[call.name] == 'responsive-grid') {
          check(call, {'children'});
          if (n['children'] is! List)
            fail('responsive-grid requires static children.');
          adapterCount++;
          return '<div class="responsive-grid">${(n['children'] as List).map(render).join()}</div>';
        }
        final adapter = nativeAdapters[call.name];
        if (adapter is Map && adapter['type'] == 'paint-chart') {
          check(call, {'label', 'display', 'values', 'color', 'kind'});
          final painter =
              classes[resolved == null
                  ? adapter['painter']
                  : resolved.root(adapter['painter'] as String)];
          if (painter == null ||
              painter.extendsClause?.superclass.toSource() != 'CustomPainter')
            fail('paint-chart requires a local CustomPainter class.');
          try {
            // The surrounding widget/interaction contract remains explicit.
            final geometry = SvgPainter().compile(painter, {
              'values': n['values'],
              'color': n['color'] ?? '#8b9dff',
              'kind': n['kind'] ?? 'bar',
            });
            final html = nativeChart(n, geometry: geometry);
            adapterCount++;
            return html;
          } on ArgumentError catch (error) {
            fail('${error.message}', call.line);
          }
        }
        if (nativeAdapters[call.name] == 'metric-chart') {
          check(call, {'label', 'display', 'values', 'color', 'kind'});
          try {
            final theme = config['theme'] ?? (darkTheme ? 'dark' : 'light');
            if (!['light', 'dark'].contains(theme))
              fail('Theme must be light or dark.');
            final html = nativeChart(n);
            adapterCount++;
            return html;
          } on ArgumentError catch (error) {
            fail('${error.message}', call.line);
          }
        }
        if (nativeAdapters[call.name] != 'filter-list')
          fail('Unknown native adapter for ${call.name}.');
        if (!classes.containsKey(call.name))
          fail('Adapter widget must exist in the source file.');
        check(call, {'items', 'label', 'hintText'});
        final items = n['items'];
        if (items is! List || items.any((item) => item is! String)) {
          fail(
            'filter-list requires a static List<String> items argument.',
            call.line,
          );
        }
        final label = n['label'] ?? 'Search items';
        final hint = n['hintText'] ?? 'Type to filter';
        if (label is! String || hint is! String)
          fail('filter-list labels must be strings.');
        final id = 'dom-filter-${filterCount++}';
        adapterCount++;
        return '<section class="dom-filter" data-filter-list>'
            '<label for="$id">${_escape(label)}</label>'
            '<input id="$id" type="search" placeholder="${_escape(hint)}" '
            'aria-controls="$id-results" autocomplete="off">'
            '<p class="filter-status" role="status">${items.length} of ${items.length} features</p>'
            '<ul id="$id-results">${items.map((item) => '<li>${_escape(item as String)}</li>').join()}</ul>'
            '</section>';
      }
      if (islandConfig.containsKey(call.name)) {
        check(call, {});
        if (domOnly)
          fail(
            'DOM-only build forbids Flutter island ${call.name}.',
            call.line,
          );
        if (island != null) fail('v0.1 supports one island instance per page.');
        if (!classes.containsKey(call.name))
          fail('Island must be declared in the input file.');
        island = resolved == null ? call.name : classes[call.name]!.name.lexeme;
        final options = Map<String, dynamic>.from(
          islandConfig[call.name] as Map,
        );
        final height = pixels(options['height'] ?? 240);
        final label = options['label'] as String? ?? 'Load interactive content';
        return '<section class="island-shell" style="height:$height" aria-label="${_escape(label)}">'
            '<div id="flutter-island" style="height:$height"></div>'
            '<div class="island-placeholder"><button id="load-island" type="button">${_escape(label)}</button>'
            '<p id="island-status" role="status">Flutter loads only when you activate this panel.</p></div>'
            '</section>';
      }
      switch (call.name) {
        case 'TextButton':
        case 'ElevatedButton':
        case 'OutlinedButton':
          check(call, {'onPressed', 'child'});
          final action = n['onPressed'];
          if (action is _NativeNavigation) {
            navigationLinkCount++;
            return '<a href="${_escape(action.href)}">${render(n['child'])}</a>';
          }
          if (frame == null || action != null && action is! ReactiveAction)
            fail('Buttons require a supported native state callback.');
          if (action == null)
            return '<button type="button" disabled>${render(n['child'])}</button>';
          final nativeAction = action as ReactiveAction;
          final actionId = frame!.action(nativeAction);
          final enabledId = frame!.bind('enabled', nativeAction.enabled);
          final enabled = nativeAction.enabled.evaluate(frame!.initial) == true;
          return '<button type="button" data-dom-action="$actionId" data-dom-enabled="$enabledId" ${enabled ? '' : 'disabled'}>${render(n['child'])}</button>';
        case 'MaterialApp':
          if (frame != null)
            fail(
              'Native state cannot rebuild MaterialApp theme or application context.',
            );
          check(call, {'home', 'debugShowCheckedModeBanner', 'title', 'theme'});
          if (n['theme'] != null) {
            final theme = n['theme'];
            if (theme is! _Call || theme.name != 'ThemeData.dark')
              fail('Only ThemeData.dark() is supported.');
            check(theme, {});
            darkTheme = true;
          }
          return render(n['home']);
        case 'InkWell':
          check(call, {'child', 'onTap', 'borderRadius'});
          final action = n['onTap'];
          final radius = n['borderRadius'];
          if (radius != null) {
            if (radius is! _Call || radius.name != 'BorderRadius.circular')
              fail('Unsupported InkWell border radius.');
            check(radius, {}, 1);
            pixels(radius.positional.single);
          }
          if (action == null) return render(n['child']);
          if (action is! _NativeNavigation)
            fail('InkWell requires an explicit native route callback.');
          navigationLinkCount++;
          return '<a href="${_escape(action.href)}" style="display:block;color:inherit;text-decoration:none;${radius == null ? '' : 'border-radius:${pixels((radius as _Call).positional.single)};'}">${render(n['child'])}</a>';
        case 'Scaffold':
          check(call, {'body'});
          return '<main>${render(n['body'])}</main>';
        case 'SingleChildScrollView':
          check(call, {'child', 'scrollDirection'});
          final direction = n['scrollDirection'] ?? 'Axis.vertical';
          if (direction != 'Axis.vertical' && direction != 'Axis.horizontal')
            fail('Unsupported scroll direction.');
          return '<div class="dom-scroll" style="${direction == 'Axis.horizontal' ? 'overflow-x:auto;max-width:100%' : ''}">${render(n['child'])}</div>';
        case 'Image.asset':
          check(call, {'width', 'height', 'fit', 'semanticLabel'}, 1);
          final asset = call.positional.single;
          if (asset is! String ||
              !RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(asset) ||
              asset.startsWith('/') ||
              asset.split('/').contains('..')) {
            fail(
              'Image.asset requires a safe project-relative asset path.',
              call.line,
            );
          }
          final fit = {
            'BoxFit.cover': 'cover',
            'BoxFit.contain': 'contain',
            'BoxFit.fill': 'fill',
          }[n['fit'] ?? 'BoxFit.contain'];
          if (fit == null) fail('Unsupported image fit.', call.line);
          final label = n['semanticLabel'] ?? '';
          if (label is! String)
            fail('Image label must be static text.', call.line);
          assets.add(asset);
          return '<img src="${_escape(asset)}" alt="${_escape(label)}" '
              'style="max-width:100%;object-fit:$fit;'
              '${n['width'] == null ? '' : 'width:${pixels(n['width'])};'}'
              '${n['height'] == null ? '' : 'height:${pixels(n['height'])};'}">';
        case 'DataTable':
          check(call, {'columns', 'rows'});
          final columns = n['columns'], rows = n['rows'];
          if (columns is! List || rows is! List)
            fail('DataTable requires static columns and rows.', call.line);
          final header = columns.map((column) {
            if (column is! _Call || column.name != 'DataColumn')
              fail('Expected DataColumn.');
            check(column, {'label'});
            return '<th scope="col">${render(column.named['label'])}</th>';
          }).join();
          final body = rows.map((row) {
            if (row is! _Call || row.name != 'DataRow')
              fail('Expected DataRow.');
            check(row, {'cells'});
            final cells = row.named['cells'];
            if (cells is! List || cells.length != columns.length)
              fail('DataRow cells must match column count.');
            return '<tr>${cells.map((cell) {
              if (cell is! _Call || cell.name != 'DataCell') fail('Expected DataCell.');
              check(cell, {}, 1);
              return '<td>${render(cell.positional.single)}</td>';
            }).join()}</tr>';
          }).join();
          return '<div class="table-scroll"><table><thead><tr>$header</tr></thead><tbody>$body</tbody></table></div>';
        case 'Icon':
          check(call, {'size', 'color', 'semanticLabel'}, 1);
          final icon = call.positional.single;
          final name = icon is String && icon.startsWith('Icons.')
              ? icon.substring(6)
              : null;
          final shape = nativeIconShapes[name];
          if (shape == null) fail('Unsupported native icon $icon.');
          final size = pixels(n['size'] ?? 24);
          final label = n['semanticLabel'];
          if (label != null && label is! String)
            fail('Icon label must be static text.');
          final cssColor = n['color'] == null
              ? 'currentColor'
              : color(n['color']).css;
          return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
              '${label == null ? 'aria-hidden="true"' : 'role="img" aria-label="${_escape(label as String)}"'} '
              'style="width:$size;height:$size;flex-shrink:0;color:$cssColor" fill="currentColor">$shape</svg>';
        case 'Text':
          check(call, {'style', 'textAlign', 'maxLines', 'overflow'}, 1);
          if (n['overflow'] != null && n['overflow'] != 'TextOverflow.ellipsis')
            fail('Only TextOverflow.ellipsis is supported.');
          final text = call.positional.single;
          if (text is! String &&
              !(text is ReactiveValue && text.type == 'String'))
            fail('Text requires a string.', call.line);
          final textId = text is ReactiveValue
              ? frame!.bind('text', text)
              : null;
          final initialText = text is ReactiveValue
              ? text.evaluate(frame!.initial) as String
              : text as String;
          final key = n['key'];
          final heading = key is _Call ? headings[key.positional.single] : null;
          if (heading != null &&
              (heading is! int || heading < 1 || heading > 6)) {
            fail('Heading level must be an integer from 1 to 6.');
          }
          final tag = heading == null ? 'p' : 'h$heading';
          var style = n['style'] == null ? '' : textStyle(n['style']);
          if (n['maxLines'] != null) {
            final lines = n['maxLines'];
            if (lines is! int || lines < 1)
              fail('Text maxLines must be a positive integer.');
            style +=
                ';display:-webkit-box;-webkit-line-clamp:$lines;-webkit-box-orient:vertical;overflow:hidden';
          }
          if (n['textAlign'] != null) {
            final align = {
              'TextAlign.left': 'left',
              'TextAlign.right': 'right',
              'TextAlign.center': 'center',
              'TextAlign.start': 'start',
              'TextAlign.end': 'end',
              'TextAlign.justify': 'justify',
            }[n['textAlign']];
            if (align == null) fail('Unsupported text alignment.');
            style += ';text-align:$align';
          }
          return '<$tag${textId == null ? "" : ' data-dom-text="$textId"'} style="$style">${_escape(initialText)}</$tag>';
        case 'Column':
        case 'Row':
          check(call, {
            'children',
            'crossAxisAlignment',
            'mainAxisAlignment',
            'mainAxisSize',
          });
          final children = n['children'] ?? <Object?>[];
          if (children is! List)
            fail('${call.name}.children must be a literal list.');
          final cross = {
            'CrossAxisAlignment.start': 'flex-start',
            'CrossAxisAlignment.end': 'flex-end',
            'CrossAxisAlignment.center': 'center',
            'CrossAxisAlignment.stretch': 'stretch',
          }[n['crossAxisAlignment'] ?? 'CrossAxisAlignment.center'];
          final main = {
            'MainAxisAlignment.start': 'flex-start',
            'MainAxisAlignment.end': 'flex-end',
            'MainAxisAlignment.center': 'center',
            'MainAxisAlignment.spaceBetween': 'space-between',
            'MainAxisAlignment.spaceAround': 'space-around',
            'MainAxisAlignment.spaceEvenly': 'space-evenly',
          }[n['mainAxisAlignment'] ?? 'MainAxisAlignment.start'];
          if (cross == null || main == null)
            fail('Unsupported flex alignment.', call.line);
          if (n['mainAxisSize'] != null &&
              n['mainAxisSize'] != 'MainAxisSize.min') {
            fail('Only explicit MainAxisSize.min is supported.', call.line);
          }
          return '<div style="display:flex;flex-direction:${call.name == 'Column' ? 'column' : 'row'};'
              '${call.name == 'Column' && cross == 'stretch' ? 'width:100%;' : ''}'
              'align-items:$cross;justify-content:$main">${children.map(render).join()}</div>';
        case 'Align':
          check(call, {'alignment', 'child'});
          final alignment = n['alignment'] ?? 'Alignment.center';
          final justify = {
            'Alignment.center': 'center',
            'Alignment.centerLeft': 'flex-start',
            'Alignment.centerRight': 'flex-end',
          }[alignment];
          if (justify == null) fail('Unsupported Align alignment.');
          return '<div style="display:flex;align-items:center;justify-content:$justify">${render(n['child'])}</div>';
        case 'Expanded':
          check(call, {'child', 'flex'});
          final flex = n['flex'] ?? 1;
          if (flex is! int || flex <= 0)
            fail('Expanded flex must be a positive static integer.');
          return '<div style="flex:$flex 1 0%;min-width:0;min-height:0">${render(n['child'])}</div>';
        case 'Card':
          check(call, {'child', 'shape', 'margin', 'color'});
          final styles = <String>[];
          if (n['margin'] != null) styles.add('margin:${padding(n['margin'])}');
          if (n['color'] != null)
            styles.add('background:${color(n['color']).css}');
          final shape = n['shape'];
          if (shape != null) {
            if (shape is! _Call || shape.name != 'RoundedRectangleBorder')
              fail('Card supports RoundedRectangleBorder only.');
            check(shape, {'borderRadius', 'side'});
            final radius = shape.named['borderRadius'];
            if (radius == null) styles.add('border-radius:0');
            if (radius != null) {
              if (radius is! _Call || radius.name != 'BorderRadius.circular')
                fail('Card radius must use BorderRadius.circular.');
              check(radius, {}, 1);
              styles.add('border-radius:${pixels(radius.positional.single)}');
            }
            final side = shape.named['side'];
            if (side != null) {
              if (side is! _Call || side.name != 'BorderSide')
                fail('Card side requires BorderSide.');
              check(side, {'color', 'width'});
              final width = side.named['width'] ?? 1;
              styles.add(
                'border:${pixels(width)} solid ${color(side.named['color']).css}',
              );
            }
          }
          return '<div class="dom-card" style="${styles.join(';')}">${render(n['child'])}</div>';
        case 'Padding':
        case 'Container':
        case 'SizedBox':
        case 'Center':
        case 'Material':
          check(call, switch (call.name) {
            'Padding' => {'padding', 'child'},
            'Container' => {
              'padding',
              'width',
              'height',
              'child',
              'decoration',
              'constraints',
            },
            'Material' => {'color', 'borderRadius', 'child'},
            'SizedBox' => {'width', 'height', 'child'},
            _ => {'child'},
          });
          final styles = <String>[];
          if (n['constraints'] != null) {
            final constraints = n['constraints'];
            if (constraints is! _Call || constraints.name != 'BoxConstraints')
              fail('Expected BoxConstraints.');
            check(constraints, {
              'minHeight',
              'minWidth',
              'maxHeight',
              'maxWidth',
            });
            for (final entry in constraints.named.entries) {
              final css = {
                'minHeight': 'min-height',
                'minWidth': 'min-width',
                'maxHeight': 'max-height',
                'maxWidth': 'max-width',
              }[entry.key]!;
              styles.add('$css:${pixels(entry.value)}');
            }
          }
          if (call.name == 'Material') {
            if (n['color'] != null)
              styles.add('background:${color(n['color']).css}');
            final radius = n['borderRadius'];
            if (radius != null) {
              if (radius is! _Call || radius.name != 'BorderRadius.circular')
                fail('Unsupported Material border radius.');
              check(radius, {}, 1);
              styles.add('border-radius:${pixels(radius.positional.single)}');
            }
          }
          if (n['decoration'] != null) {
            final decoration = n['decoration'];
            if (decoration is! _Call || decoration.name != 'BoxDecoration')
              fail('Expected BoxDecoration.');
            check(decoration, {'color', 'borderRadius', 'border'});
            final border = decoration.named['border'];
            if (border != null) {
              if (border is! _Call || border.name != 'Border.all')
                fail('Only Border.all is supported.');
              check(border, {'color', 'width'});
              styles.add(
                'border:${pixels(border.named['width'] ?? 1)} solid ${color(border.named['color']).css}',
              );
            }
            if (decoration.named['color'] != null)
              styles.add('background:${color(decoration.named['color']).css}');
            final radius = decoration.named['borderRadius'];
            if (radius != null) {
              if (radius is! _Call || radius.name != 'BorderRadius.circular')
                fail('Only circular border radius is supported.');
              check(radius, {}, 1);
              styles.add('border-radius:${pixels(radius.positional.single)}');
            }
          }
          if (call.name == 'Padding' && n['padding'] == null)
            fail('Padding requires padding.');
          if (n['padding'] != null)
            styles.add('padding:${padding(n['padding'])}');
          for (final size in ['width', 'height']) {
            if (n[size] != null) styles.add('$size:${pixels(n[size])}');
          }
          if (call.name == 'Center')
            styles.add(
              'display:flex;align-items:center;justify-content:center',
            );
          return '<div style="${styles.join(';')}">${n['child'] == null ? '' : render(n['child'])}</div>';
        default:
          return buildClass(call.name, call);
      }
    };

    final extensionConfig = themeConfig is Map
        ? themeConfig['extensions']
        : null;
    if (extensionConfig != null) {
      if (extensionConfig is! Map)
        fail('Static theme extensions must be a map.');
      for (final entry in extensionConfig.entries) {
        if (entry.key is! String || entry.value is! String)
          fail('Theme extensions map class selectors to constant selectors.');
        final name = resolved?.root(entry.key as String) ?? entry.key as String;
        final constant = entry.value as String;
        final expression = constants[constant];
        if (expression == null)
          fail('Unknown theme extension constant $constant.');
        final snapshot = value(expression);
        if (snapshot is! _StaticObject ||
            snapshot.model != name ||
            !isThemeExtension(classes[name]!))
          fail('Theme extension constant must match its declared class.');
        themeExtensions[name] = snapshot;
      }
    }

    var previewInputBudget = 2000;
    late _Call Function(String, Map, int) configuredCall;
    Object? configuredValue(Object? input, int depth) {
      if (--previewInputBudget < 0 || depth > 16)
        fail('Preview input nesting/size limit exceeded.');
      if (input == null ||
          input is String ||
          input is bool ||
          input is num && input.isFinite)
        return input;
      if (input is Map && input.keys.length == 1 && input['date'] is String) {
        final match = RegExp(
          r'^(\d{4})-(\d{2})-(\d{2})$',
        ).firstMatch(input['date'] as String);
        if (match == null)
          fail('Date snapshots require YYYY-MM-DD without time or timezone.');
        return calendarDate(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
      if (input is Map &&
          input['callback'] is String &&
          input.keys.every((k) => ['callback', 'routes'].contains(k))) {
        final name = input['callback'] as String;
        if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name))
          fail('Invalid callback input name.');
        externalCallbackCount++;
        Map<String, String>? routes;
        if (input.containsKey('routes')) {
          final configured = input['routes'];
          if (configured is! Map ||
              configured.isEmpty ||
              configured.length > 2000)
            fail('Callback routes require a nonempty string map.');
          routes = {};
          for (final entry in configured.entries) {
            if (entry.key is! String || entry.value is! String)
              fail('Callback routes require strings.');
            final href = entry.value as String;
            if (!RegExp(
                  r'^[a-zA-Z0-9_./-]+(?:#[a-zA-Z0-9_-]+)?$',
                ).hasMatch(href) ||
                href.startsWith('/') ||
                href.split('#').first.split('/').contains('..'))
              fail('Callback routes require safe relative local paths.');
            routes[entry.key as String] = href;
          }
          callbackRouteBridgeCount++;
        }
        return _ExternalCallback(name, routes);
      }
      if (input is Map && input.keys.length == 1 && input['color'] is String)
        return color(input['color']);
      if (input is Map && input.keys.length == 1 && input['icon'] is String) {
        if (!nativeIconShapes.containsKey(input['icon']))
          fail('Unsupported configured icon.');
        return 'Icons.${input['icon']}';
      }
      if (input is Map && input.keys.length == 1 && input['map'] is Map) {
        final entries = input['map'] as Map;
        if (entries.keys.any((k) => k is! String))
          fail('Map snapshots require string keys.');
        return <String, Object?>{
          for (final entry in entries.entries)
            entry.key as String: configuredValue(entry.value, depth + 1),
        };
      }
      if (input is List)
        return input.map((v) => configuredValue(v, depth + 1)).toList();
      if (input is Map &&
          (input['widget'] is String || input['model'] is String) &&
          !(input.containsKey('widget') && input.containsKey('model')) &&
          input.keys.every(
            (key) => [
              'widget',
              'model',
              'arguments',
              'positionalArguments',
            ].contains(key),
          )) {
        final reference = (input['model'] ?? input['widget']) as String;
        final name = resolved?.root(reference) ?? reference;
        if (!classes.containsKey(name))
          fail('Preview widget must name a project-local class.');
        final call = configuredCall(name, input, depth + 1);
        if (input.containsKey('model')) return instantiateModel(call);
        if (classes[name]!.extendsClause == null)
          fail('Widget descriptors must reference widget classes.');
        return call;
      }
      fail(
        'Preview inputs require finite primitives, lists or explicit project-local widget/model descriptors.',
      );
    }

    configuredCall = (String name, Map item, int depth) {
      final named = Map<String, Object?>.from(item['arguments'] as Map? ?? {});
      final positional = List<Object?>.from(
        item['positionalArguments'] as List? ?? [],
      );
      return _Call(
        name,
        positional.map((v) => configuredValue(v, depth + 1)).toList(),
        {
          for (final entry in named.entries)
            entry.key: configuredValue(entry.value, depth + 1),
        },
        1,
      );
    };

    final String body;
    if (previews != null) {
      if (previews.isEmpty || previews.length > 60 || entryExpression != null)
        fail('Preview requires 1–60 component entries.');
      final cards = previews.map((item) {
        if (item is! Map || item['root'] is! String)
          fail('Preview entries require a root.');
        final name =
            resolved?.root(item['root'] as String) ?? item['root'] as String;
        return '<section class="dom-preview-card">${buildClass(name, configuredCall(name, item, 0))}</section>';
      }).join();
      body =
          '<main class="dom-preview"><h1>${_escape(config['title'] as String? ?? 'Component preview')}</h1>'
          '<p>Mock data</p><div class="dom-preview-grid">$cards</div></main>';
    } else {
      body = entryExpression == null
          ? buildClass(root, configuredCall(root, config, 0))
          : render(value(entryExpression));
    }
    final title = _escape(config['title'] as String? ?? rootName);
    final description = _escape(config['description'] as String? ?? '');
    final lang = _escape(config['lang'] as String? ?? 'en');
    final theme = config['theme'] ?? (darkTheme ? 'dark' : 'light');
    if (!['light', 'dark'].contains(theme))
      fail('Theme must be light or dark.');
    final html =
        '<!doctype html>\n<html lang="$lang"><head>\n'
        '<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">\n'
        '<title>$title</title><meta name="description" content="$description">\n'
        '<link rel="stylesheet" href="styles.css">\n</head><body class="theme-$theme">\n$body\n'
        '${filterCount == 0 && reactiveCount == 0 ? '' : '<script src="native.js" defer></script>\n'}'
        '${island == null ? '' : '<script src="islands.js" defer></script>\n'}'
        '</body></html>\n';
    return Compilation(html, {
      'root': rootName,
      'componentPreview': previews != null,
      'staticThemeProvided': staticTheme != null,
      'staticThemeExtensionSnapshots': themeExtensions.length,
      'analysis': resolved == null ? 'single-file syntax' : 'resolved project',
      if (resolved != null)
        'sourceFiles': resolved.units
            .map((u) => p.relative(u.path, from: resolved.directory))
            .toList(),
      if (resolved != null) 'analysisTarget': 'web-js',
      if (resolved != null) 'conditionalEnvironment': webAnalysisEnvironment,
      if (resolved != null)
        'conditionalDirectives': resolved.conditionalDirectives,
      'assets': assets.toList(),
      'widgets': counts,
      'island': island,
      'nativeAdapterInstances': adapterCount,
      'nativeFilterInstances': filterCount,
      'nativeStateInstances': reactiveCount,
      'nativeConditionalGroups': conditionalGroupCount,
      'staticModelInstances': modelCount,
      'staticDateValues': dateCount,
      'pureHelperInvocations': helperCount,
      'externalCallbackInputs': externalCallbackCount,
      'nativeCallbackRouteBridges': callbackRouteBridgeCount,
      'nativeNavigationLinks': navigationLinkCount,
      'stateStrategy':
          'Typed reactive expressions; single build; dependency-based DOM updates',
      'initialFlutterBytes': 0,
      'rendering': reactiveCount == 0
          ? 'static HTML; approximate CSS layout'
          : 'HTML with reactive expression bindings; approximate CSS layout',
      'limitations': [
        if (resolved == null)
          'Single source file'
        else
          'Project-local declarations; external widget packages unsupported',
        'Local bool/int state and typed expression subset only',
        if (externalCallbackCount > 0)
          'Opaque callback inputs supplied; invocation requires a native event bridge',
        if (callbackRouteBridgeCount > 0)
          'Explicit callback route adapters replace host navigation; original async callback bodies are not compiled',
        if (reactiveCount > 0)
          'State tree compiled once; bounded conditional static collections retained in hidden DOM groups',
        'One explicit island',
        'No state bridge to Flutter islands',
        'No Flutter layout parity guarantee',
      ],
    }, island);
  }
}

String _escape(String value) => const HtmlEscape().convert(value);

/// Infer only the normal direct runApp(MyApp()) entry point; never execute Dart.
String discoverRoot(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final visitor = _RunAppVisitor();
  for (final function in unit.declarations.whereType<FunctionDeclaration>()) {
    if (function.name.lexeme == 'main') {
      final body = function.functionExpression.body;
      if (body is BlockFunctionBody &&
          (body.block.statements.length != 1 ||
              body.block.statements.single is! ExpressionStatement)) {
        throw CompileException(
          'main contains startup logic. Set an explicit root in flutter_dom.json; startup logic is not compiled to DOM.',
        );
      }
      body.accept(visitor);
    }
  }
  if (visitor.roots.length == 1) return visitor.roots.single;
  if (unit.declarations.whereType<ClassDeclaration>().any(
    (c) => c.name.lexeme == 'App',
  ))
    return 'App';
  throw CompileException(
    'Cannot infer the root. Use main() => runApp(MyApp()) or set root in flutter_dom.json.',
  );
}

class _RunAppVisitor extends RecursiveAstVisitor<void> {
  final roots = <String>[];
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'runApp' &&
        node.argumentList.arguments.length == 1) {
      final argument = node.argumentList.arguments.single;
      if (argument is InstanceCreationExpression &&
          argument.constructorName.name == null) {
        roots.add(argument.constructorName.type.toSource());
      } else if (argument is MethodInvocation &&
          (argument.target == null || argument.target is SimpleIdentifier)) {
        roots.add(
          '${argument.target == null ? '' : '${argument.target!.toSource()}.'}${argument.methodName.name}',
        );
      }
    }
    super.visitMethodInvocation(node);
  }
}
