import 'dart:convert';
import 'chart.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

class CompileException implements Exception {
  CompileException(this.message);
  final String message;
  @override
  String toString() => 'Compile error: $message';
}

class Compilation {
  Compilation(this.html, this.report, this.island);
  final String html;
  final Map<String, Object?> report;
  final String? island;
}

class _Call {
  _Call(this.name, this.positional, this.named, this.line);
  final String name;
  final List<Object?> positional;
  final Map<String, Object?> named;
  final int line;
}

/// Deliberately static: never executes the input application.
class FlutterDomCompiler {
  Compilation compile(
    String source,
    Map<String, dynamic> config, {
    bool domOnly = false,
  }) {
    final result = parseString(content: source, throwIfDiagnostics: false);
    if (result.errors.isNotEmpty) {
      throw CompileException(result.errors.first.toString());
    }
    final classes = <String, ClassDeclaration>{
      for (final node in result.unit.declarations.whereType<ClassDeclaration>())
        node.name.lexeme: node,
    };
    final root = config['root'] as String? ?? discoverRoot(source);
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
    final assets = <String>{};
    var adapterCount = 0;
    var filterCount = 0;
    var darkTheme = false;
    final stack = <String>[];
    var scope = <String, Object?>{};
    String? island;

    Never fail(String message, [int? line]) =>
        throw CompileException('${line == null ? '' : 'Line $line: '}$message');

    Object? value(Expression expression) {
      final line = result.lineInfo.getLocation(expression.offset).lineNumber;
      if (expression is SimpleStringLiteral) return expression.value;
      if (expression is AdjacentStrings) {
        final parts = expression.strings.map(value).toList();
        if (parts.every((part) => part is String)) return parts.join();
      }
      if (expression is ParenthesizedExpression)
        return value(expression.expression);
      if (expression is ConditionalExpression) {
        final condition = value(expression.condition);
        if (condition is! bool)
          fail('Static condition must be a boolean.', line);
        return value(
          condition ? expression.thenExpression : expression.elseExpression,
        );
      }
      if (expression is StringInterpolation) {
        return expression.elements.map((element) {
          if (element is InterpolationString) return element.value;
          final part = value((element as InterpolationExpression).expression);
          if (part == null || part is String || part is num || part is bool) {
            return part.toString();
          }
          fail('Only static primitive values may be interpolated.', line);
        }).join();
      }
      if (expression is IntegerLiteral) return expression.value;
      if (expression is DoubleLiteral) return expression.value;
      if (expression is BooleanLiteral) return expression.value;
      if (expression is NullLiteral) return null;
      if (expression is SimpleIdentifier &&
          scope.containsKey(expression.name)) {
        return scope[expression.name];
      }
      if (expression is PropertyAccess &&
          expression.target is ThisExpression &&
          scope.containsKey(expression.propertyName.name)) {
        return scope[expression.propertyName.name];
      }
      if (expression is PrefixExpression && expression.operator.lexeme == '-') {
        final operand = value(expression.operand);
        if (operand is num) return -operand;
      }
      if (expression is ListLiteral) {
        return expression.elements.map((element) {
          if (element is! Expression) {
            fail(
              'Collection control flow and spreads are not supported.',
              line,
            );
          }
          return value(element);
        }).toList();
      }
      if (expression is PrefixedIdentifier) return expression.toSource();
      String? name;
      ArgumentList? args;
      if (expression is InstanceCreationExpression) {
        name = expression.constructorName.toSource();
        args = expression.argumentList;
      } else if (expression is MethodInvocation) {
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
        return _Call(name, positional, named, line);
      }
      fail(
        'Expected a static literal or supported constructor; found '
        '`${expression.toSource()}`. Move dynamic UI into an explicit island.',
        line,
      );
    }

    void check(_Call call, Set<String> named, [int positional = 0]) {
      final unknown = call.named.keys.toSet().difference({...named, 'key'});
      if (unknown.isNotEmpty || call.positional.length != positional) {
        fail(
          '${call.name}: unsupported arguments ${unknown.join(', ')} '
          '(expected $positional positional).',
          call.line,
        );
      }
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
      return '${number}px';
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
      check(object, {'fontSize', 'fontWeight'});
      final css = <String>[];
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

    late String Function(Object?) render;
    String buildClass(String name, [_Call? invocation]) {
      final node = classes[name];
      if (node == null)
        fail(
          'Unknown widget $name. Imported widgets are not expanded in v0.1.',
        );
      if (node.extendsClause?.superclass.toSource() != 'StatelessWidget') {
        fail(
          '$name must be a StatelessWidget or an explicitly configured Flutter island.',
        );
      }
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
      final constructors = node.members
          .whereType<ConstructorDeclaration>()
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
            result.lineInfo.getLocation(node.offset).lineNumber,
          );
      if (constructors.isEmpty) {
        check(call, {});
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
        final previous = scope;
        scope = {};
        try {
          for (final wrapped in constructor.parameters.parameters) {
            final parameter = wrapped is DefaultFormalParameter
                ? wrapped.parameter
                : wrapped;
            if (parameter is SuperFormalParameter &&
                parameter.name.lexeme == 'key')
              continue;
            if (parameter is! FieldFormalParameter || !wrapped.isNamed) {
              fail(
                '$name supports only named this.field parameters and super.key.',
              );
            }
            final field = parameter.name.lexeme;
            allowed.add(field);
            if (call.named.containsKey(field)) {
              bindings[field] = call.named[field];
            } else if (wrapped.isRequiredNamed) {
              fail('$name is missing required argument $field.', call.line);
            } else {
              final defaultValue = wrapped is DefaultFormalParameter
                  ? wrapped.defaultValue
                  : null;
              bindings[field] = defaultValue == null
                  ? null
                  : value(defaultValue);
            }
          }
        } finally {
          scope = previous;
        }
        check(call, allowed);
      }
      final declared = fields
          .expand((field) => field.fields.variables.map((v) => v.name.lexeme))
          .toSet();
      if (declared.difference(bindings.keys.toSet()).isNotEmpty) {
        fail(
          '$name has fields not initialized by a supported constructor parameter.',
        );
      }
      if (stack.contains(name))
        fail('Recursive widget expansion: ${[...stack, name].join(' → ')}.');
      final methods = node.members.whereType<MethodDeclaration>().where(
        (method) => method.name.lexeme == 'build',
      );
      if (methods.length != 1) fail('$name needs one build method.');
      final body = methods.single.body;
      Expression? expression;
      if (body is ExpressionFunctionBody) expression = body.expression;
      if (body is BlockFunctionBody && body.block.statements.length == 1) {
        final statement = body.block.statements.single;
        if (statement is ReturnStatement) expression = statement.expression;
      }
      if (expression == null)
        fail('$name.build must contain a single return expression.');
      stack.add(name);
      final previous = scope;
      scope = bindings;
      try {
        return render(value(expression));
      } finally {
        scope = previous;
        stack.removeLast();
      }
    }

    render = (Object? object) {
      if (object is! _Call)
        fail('Expected a widget constructor, found $object.');
      final call = object;
      final n = call.named;
      counts.update(call.name, (count) => count + 1, ifAbsent: () => 1);
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
        island = call.name;
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
        case 'MaterialApp':
          check(call, {'home', 'debugShowCheckedModeBanner', 'title', 'theme'});
          if (n['theme'] != null) {
            final theme = n['theme'];
            if (theme is! _Call || theme.name != 'ThemeData.dark')
              fail('Only ThemeData.dark() is supported.');
            check(theme, {});
            darkTheme = true;
          }
          return render(n['home']);
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
        case 'Text':
          check(call, {'style', 'textAlign'}, 1);
          if (call.positional.single is! String)
            fail('Text requires a literal string.', call.line);
          final key = n['key'];
          final heading = key is _Call ? headings[key.positional.single] : null;
          if (heading != null &&
              (heading is! int || heading < 1 || heading > 6)) {
            fail('Heading level must be an integer from 1 to 6.');
          }
          final tag = heading == null ? 'p' : 'h$heading';
          var style = n['style'] == null ? '' : textStyle(n['style']);
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
          return '<$tag style="$style">${_escape(call.positional.single as String)}</$tag>';
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
              'align-items:$cross;justify-content:$main">${children.map(render).join()}</div>';
        case 'Padding':
        case 'Container':
        case 'SizedBox':
        case 'Center':
          check(call, switch (call.name) {
            'Padding' => {'padding', 'child'},
            'Container' => {'padding', 'width', 'height', 'child'},
            'SizedBox' => {'width', 'height', 'child'},
            _ => {'child'},
          });
          final styles = <String>[];
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

    final body = buildClass(root);
    final title = _escape(config['title'] as String? ?? root);
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
        '${filterCount == 0 ? '' : '<script src="native.js" defer></script>\n'}'
        '${island == null ? '' : '<script src="islands.js" defer></script>\n'}'
        '</body></html>\n';
    return Compilation(html, {
      'root': root,
      'assets': assets.toList(),
      'widgets': counts,
      'island': island,
      'nativeAdapterInstances': adapterCount,
      'nativeFilterInstances': filterCount,
      'initialFlutterBytes': 0,
      'rendering': 'static HTML; approximate CSS layout',
      'limitations': [
        'Single source file',
        'Static data and named constructor fields only',
        'One explicit island',
        'No state bridge',
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
      } else if (argument is MethodInvocation && argument.target == null) {
        roots.add(argument.methodName.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}
