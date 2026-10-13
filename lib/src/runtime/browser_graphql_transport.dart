import 'dart:async';
import 'dart:js_interop';

import 'graphql_client.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString path, _Options options);
@JS('AbortController')
extension type _AbortController._(JSObject _) implements JSObject {
  external factory _AbortController();
  external JSObject get signal;
  external void abort();
}
extension type _Options._(JSObject _) implements JSObject {
  external factory _Options({
    JSString method,
    JSString body,
    JSObject headers,
    JSString credentials,
    JSString redirect,
    JSObject signal,
  });
}
extension type _Response(JSObject _) implements JSObject {
  external int get status;
  external JSPromise<JSString> text();
}

/// Root-relative, same-origin POST transport. No token storage or auth refresh.
/// Timeout covers both headers and body, and aborts the underlying fetch.
class BrowserGraphqlTransport implements GraphqlTransport {
  BrowserGraphqlTransport(
    this.endpoint, {
    this.timeout = const Duration(seconds: 15),
  }) {
    final uri = Uri.parse(endpoint);
    if (!endpoint.startsWith('/') ||
        endpoint.startsWith('//') ||
        endpoint.contains('\\') ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(endpoint) ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment) {
      throw ArgumentError('GraphQL endpoint must be root-relative.');
    }
    if (timeout <= Duration.zero)
      throw ArgumentError('Timeout must be positive.');
  }
  final String endpoint;
  final Duration timeout;

  @override
  Future<GraphqlHttpResponse> post(String body) async {
    final controller = _AbortController();
    var timedOut = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      controller.abort();
    });
    try {
      final response = await _fetch(
        endpoint.toJS,
        _Options(
          method: 'POST'.toJS,
          body: body.toJS,
          headers:
              {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  }.jsify()!
                  as JSObject,
          credentials: 'same-origin'.toJS,
          redirect: 'error'.toJS,
          signal: controller.signal,
        ),
      ).toDart;
      final text = (await response.text().toDart).toDart;
      return GraphqlHttpResponse(response.status, text);
    } catch (_) {
      throw GraphqlRequestException(timedOut ? 'timeout' : 'network');
    } finally {
      timer.cancel();
    }
  }
}
