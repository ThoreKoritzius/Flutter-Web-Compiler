import 'package:flutter_dom_compiler/flutter_dom_compiler.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  const source =
      r'''class Entry { const Entry({required this.title,required this.minutes}); final String title; final double minutes; }
class Page extends StatelessWidget { const Page({required this.items}); final List<Entry> items;
 Widget build(BuildContext context)=>Column(children:[for(final item in items)Text('${item.title}: ${item.minutes.round()}m')]); }''';
  final config = <String, dynamic>{
    'preview': [
      {
        'root': 'Page',
        'arguments': {
          'items': {
            'data': '/response/entries',
            'each': {
              'model': 'Entry',
              'arguments': {
                'title': {'data': '/title'},
                'minutes': {'data': '/minutes'},
              },
            },
          },
        },
      },
    ],
  };
  test(
    'JSON lists bind explicit original model constructors without factories',
    () {
      final binding = bindDataSnapshot(config, {
        'response': {
          'entries': [
            {'title': 'Run', 'minutes': 23.6},
            {'title': '<script>', 'minutes': 4},
          ],
        },
      });
      final result = FlutterDomCompiler().compile(source, binding.config);
      expect(
        parse(
          result.html,
        ).querySelectorAll('.dom-preview-card p').map((p) => p.text),
        ['Run: 24m', '<script>: 4m'],
      );
      expect(result.html, isNot(contains('<script>')));
      expect(binding.references, 5);
      expect(config['previewLabel'], isNull);
      expect(result.html, contains('Supplied JSON data'));
    },
  );
  test(
    'JSON pointer escapes, array indexes and raw descriptor-like keys stay data',
    () {
      final result = bindDataSnapshot(
        {
          'arguments': {
            'data': {'data': '/a~1b/~0key/0'},
            'payload': {'data': '/payload'},
          },
        },
        {
          'a/b': {
            '~key': [7],
          },
          'payload': {
            'widget': 'NoExecution',
            'data': 'literal',
            'date': 'not a date',
          },
        },
      ).config;
      final args = result['arguments'] as Map;
      expect(args['data'], 7);
      expect(args['payload'], {
        'map': {
          'widget': 'NoExecution',
          'data': 'literal',
          'date': 'not a date',
        },
      });
    },
  );
  test('literal map keys named data are not interpreted as references', () {
    final result = bindDataSnapshot(
      {
        'arguments': {
          'fields': {
            'map': {
              'data': 'literal',
              'other': {'data': '/value'},
            },
          },
        },
      },
      {'value': true},
    ).config;
    expect((result['arguments'] as Map)['fields'], {
      'map': {'data': 'literal', 'other': true},
    });
  });
  test(
    'missing refs, bad pointers, invalid each and unsupported values fail clearly',
    () {
      for (final input in [
        {'data': '/missing'},
        {'data': 'bad'},
        {'data': '/~9'},
        {'data': '/rows/01'},
        {
          'data': '/rows',
          'each': {'widget': 'Page'},
        },
        {
          'data': '/value',
          'each': {'model': 'Entry'},
        },
        {'data': '/value', 'extra': true},
      ]) {
        expect(
          () => bindDataSnapshot(
            {
              'arguments': {'item': input},
            },
            {
              'rows': [1],
              'value': 2,
            },
          ),
          throwsArgumentError,
        );
      }
      expect(() => bindDataSnapshot({'root': 'Page'}, {}), throwsArgumentError);
      expect(
        () => bindDataSnapshot(
          {
            'arguments': {
              'item': {'data': '/value'},
            },
          },
          {'value': double.infinity},
        ),
        throwsArgumentError,
      );
    },
  );
  test('snapshot expansion has a shared size budget', () {
    expect(
      () => bindDataSnapshot({
        'arguments': {
          'item': {'data': ''},
        },
      }, List.filled(20001, 1)),
      throwsArgumentError,
    );
  });
}
