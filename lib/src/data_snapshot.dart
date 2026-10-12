/// Binds a local JSON snapshot to explicit compiler constructor inputs.
/// No factories, expressions, network requests or files are executed here.
class SnapshotBinding {
  SnapshotBinding(this.config, this.references);
  final Map<String, dynamic> config;
  final int references;
}

SnapshotBinding bindDataSnapshot(Map<String, dynamic> config, Object? data) {
  var budget = 20000;
  var references = 0;
  void consume(int depth) {
    if (--budget < 0 || depth > 32) {
      throw ArgumentError('Snapshot binding exceeds its size/nesting limit.');
    }
  }

  Object? lookup(Object? context, String pointer) {
    if (pointer.isEmpty) return context;
    if (!pointer.startsWith('/')) {
      throw ArgumentError('Snapshot references require JSON Pointer syntax.');
    }
    Object? current = context;
    for (final encoded in pointer.substring(1).split('/')) {
      if (RegExp(r'~(?![01])').hasMatch(encoded)) {
        throw ArgumentError('Invalid JSON Pointer escape.');
      }
      final segment = encoded.replaceAll('~1', '/').replaceAll('~0', '~');
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else if (current is List &&
          RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(segment)) {
        final index = int.tryParse(segment);
        if (index == null || index >= current.length) {
          throw ArgumentError('Snapshot array reference is out of range.');
        }
        current = current[index];
      } else {
        // Deliberately omit values and payload keys from diagnostics.
        throw ArgumentError('Snapshot reference does not exist.');
      }
    }
    return current;
  }

  Object? input(Object? value, int depth) {
    consume(depth);
    if (value == null ||
        value is String ||
        value is bool ||
        value is num && value.isFinite)
      return value;
    if (value is List) return value.map((v) => input(v, depth + 1)).toList();
    if (value is Map && value.keys.every((k) => k is String)) {
      return {
        'map': {
          for (final entry in value.entries)
            entry.key as String: input(entry.value, depth + 1),
        },
      };
    }
    throw ArgumentError('Snapshot values must be finite JSON data.');
  }

  Object? bind(Object? value, Object? context, int depth) {
    consume(depth);
    if (value is List)
      return value.map((v) => bind(v, context, depth + 1)).toList();
    if (value is Map) {
      if (value.containsKey('data')) {
        if (value['data'] is! String ||
            value.keys.any((k) => !['data', 'each'].contains(k))) {
          throw ArgumentError(
            'Snapshot references accept data and optional each only.',
          );
        }
        references++;
        final selected = lookup(context, value['data'] as String);
        if (value.containsKey('each')) {
          if (selected is! List || value['each'] is! Map) {
            throw ArgumentError(
              'Snapshot each requires a list and constructor template.',
            );
          }
          final template = value['each'] as Map;
          if (template['model'] is! String ||
              template.keys.any(
                (k) =>
                    !['model', 'arguments', 'positionalArguments'].contains(k),
              )) {
            throw ArgumentError(
              'Snapshot each requires an explicit model template.',
            );
          }
          return selected
              .map((entry) => bind(template, entry, depth + 1))
              .toList();
        }
        return input(selected, depth + 1);
      }
      if (value.keys.any((k) => k is! String)) {
        throw ArgumentError('Snapshot configuration keys must be strings.');
      }
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key as String:
              ['arguments', 'map'].contains(entry.key) && entry.value is Map
              ? <String, dynamic>{
                  for (final field in (entry.value as Map).entries)
                    field.key as String: bind(field.value, context, depth + 1),
                }
              : bind(entry.value, context, depth + 1),
      };
    }
    return value;
  }

  final bound = bind(config, data, 0) as Map<String, dynamic>;
  if (references == 0)
    throw ArgumentError('No snapshot references were configured.');
  bound['previewLabel'] = 'Supplied JSON data';
  return SnapshotBinding(bound, references);
}
