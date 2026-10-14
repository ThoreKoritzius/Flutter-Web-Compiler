/// url_launcher for browsers: links open through `window.open`, like the
/// official web plugin. `javascript:` URLs are refused.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

enum LaunchMode {
  platformDefault,
  inAppWebView,
  inAppBrowserView,
  externalApplication,
  externalNonBrowserApplication,
}

class WebViewConfiguration {
  const WebViewConfiguration({
    this.enableJavaScript = true,
    this.enableDomStorage = true,
    this.headers = const {},
  });
  final bool enableJavaScript, enableDomStorage;
  final Map<String, String> headers;
}

class BrowserConfiguration {
  const BrowserConfiguration({this.showTitle = false});
  final bool showTitle;
}

const _allowedSchemes = {'http', 'https', 'mailto', 'tel', 'sms'};

bool _launchable(Uri url) =>
    _allowedSchemes.contains(url.scheme.toLowerCase()) ||
    (!url.hasScheme && url.path.isNotEmpty);

Future<bool> canLaunchUrl(Uri url) async => _launchable(url);

Future<bool> launchUrl(
  Uri url, {
  LaunchMode mode = LaunchMode.platformDefault,
  WebViewConfiguration webViewConfiguration = const WebViewConfiguration(),
  BrowserConfiguration browserConfiguration = const BrowserConfiguration(),
  String? webOnlyWindowName,
}) async {
  if (!_launchable(url)) return false;
  final window = globalContext.getProperty<JSObject?>('window'.toJS);
  if (window == null || !window.has('open')) return false;
  // Protocol handlers (mailto:, tel:) open in place; other links in a new
  // browsing context unless a target is given.
  final inPlace = const {'mailto', 'tel', 'sms'}.contains(url.scheme);
  final target = webOnlyWindowName ?? (inPlace ? '_top' : '_blank');
  final opened = window.callMethod<JSAny?>(
    'open'.toJS,
    url.toString().toJS,
    target.toJS,
    (target == '_blank' ? 'noopener,noreferrer' : '').toJS,
  );
  return opened != null || target != '_blank';
}

Future<bool> canLaunchUrlString(String urlString) =>
    canLaunchUrl(Uri.parse(urlString));

Future<bool> launchUrlString(
  String urlString, {
  LaunchMode mode = LaunchMode.platformDefault,
  WebViewConfiguration webViewConfiguration = const WebViewConfiguration(),
  BrowserConfiguration browserConfiguration = const BrowserConfiguration(),
  String? webOnlyWindowName,
}) => launchUrl(
  Uri.parse(urlString),
  mode: mode,
  webViewConfiguration: webViewConfiguration,
  browserConfiguration: browserConfiguration,
  webOnlyWindowName: webOnlyWindowName,
);

Future<bool> supportsLaunchMode(LaunchMode mode) async =>
    mode == LaunchMode.platformDefault ||
    mode == LaunchMode.externalApplication;

Future<bool> supportsCloseForLaunchMode(LaunchMode mode) async => false;

Future<void> closeInAppWebView() async {}

@Deprecated('Use canLaunchUrl instead.')
Future<bool> canLaunch(String urlString) => canLaunchUrlString(urlString);

@Deprecated('Use launchUrl instead.')
Future<bool> launch(
  String urlString, {
  bool? forceSafariVC,
  bool forceWebView = false,
  bool enableJavaScript = false,
  bool enableDomStorage = false,
  bool universalLinksOnly = false,
  Map<String, String> headers = const {},
  String? webOnlyWindowName,
}) => launchUrlString(urlString, webOnlyWindowName: webOnlyWindowName);
