import 'dart:js_interop';
import 'repository.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString url);
extension type _Response(JSObject _) implements JSObject {
  external bool get ok;
  external JSPromise<JSString> text();
}

class BrowserTransport implements SummaryTransport {
  bool failNext = false;
  @override
  Future<String> read() async {
    final path = failNext ? '/api/summary?fail=1' : '/api/summary';
    failNext = false;
    final response = await _fetch(
      path.toJS,
    ).toDart.timeout(const Duration(seconds: 10));
    if (!response.ok) throw StateError('Service unavailable');
    return (await response.text().toDart).toDart;
  }
}
