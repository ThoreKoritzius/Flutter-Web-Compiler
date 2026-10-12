import 'dart:js_interop';

import '../../../lib/runtime.dart';
import 'repository.dart';

@JS('document')
external Document get document;
@JS('fetch')
external JSPromise<Response> fetch(JSString url);

extension type Document(JSObject _) implements JSObject {
  external Element querySelector(String selector);
  external Element createElement(String tag);
}
extension type Element(JSObject _) implements JSObject {
  external set textContent(String value);
  external void appendChild(Element child);
  external void replaceChildren();
  external void setAttribute(String name, String value);
  external void addEventListener(String event, JSFunction callback);
}
extension type Response(JSObject _) implements JSObject {
  external bool get ok;
  external JSPromise<JSString> text();
}

class BrowserTransport implements SummaryTransport {
  bool failNext = false;
  @override
  Future<String> read() async {
    final path = failNext ? '/api/summary?fail=1' : '/api/summary';
    failNext = false;
    final response = await fetch(
      path.toJS,
    ).toDart.timeout(const Duration(seconds: 10));
    if (!response.ok) throw StateError('Service unavailable');
    return (await response.text().toDart).toDart;
  }
}

void main() {
  final transport = BrowserTransport();
  final repository = SummaryRepository(transport);
  final resource = AsyncResource(repository.fetch);
  final status = document.querySelector('#status');
  final content = document.querySelector('#activities');
  final total = document.querySelector('#total');
  final panel = document.querySelector('#panel');
  resource.listen((state) {
    panel.setAttribute('aria-busy', '${state.phase == ResourcePhase.loading}');
    status.textContent = switch (state.phase) {
      ResourcePhase.idle => 'Ready',
      ResourcePhase.loading => 'Loading…',
      ResourcePhase.data => 'Updated from local API',
      ResourcePhase.error => 'Request failed. Retry to recover.',
    };
    if (state.phase != ResourcePhase.data) return;
    final summary = state.value!;
    total.textContent = '${summary.totalMinutes.toStringAsFixed(0)} min';
    content.replaceChildren();
    for (final activity in summary.activities) {
      final row = document.createElement('li');
      final label = document.createElement('span');
      label.textContent = activity.name;
      final value = document.createElement('strong');
      value.textContent = '${activity.minutes.toStringAsFixed(0)} min';
      row.appendChild(label);
      row.appendChild(value);
      content.appendChild(row);
    }
  });
  document
      .querySelector('#refresh')
      .addEventListener(
        'click',
        (() {
          resource.refresh();
        }).toJS,
      );
  document
      .querySelector('#fail')
      .addEventListener(
        'click',
        (() {
          transport.failNext = true;
          resource.refresh();
        }).toJS,
      );
  resource.refresh();
}
