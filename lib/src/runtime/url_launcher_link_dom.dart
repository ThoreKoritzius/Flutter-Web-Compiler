/// `package:url_launcher/link.dart` for the native runtime: [Link] hands its
/// builder a callback that opens the URI through [launchUrl].
library;

import 'flutter_dom.dart';
import 'url_launcher_dom.dart';

typedef FollowLink = Future<void> Function();
typedef LinkWidgetBuilder =
    Widget Function(BuildContext context, FollowLink? followLink);

class LinkTarget {
  const LinkTarget._(this._name);
  final String _name;

  static const defaultTarget = LinkTarget._('default');
  static const self = LinkTarget._('_self');
  static const blank = LinkTarget._('_blank');

  @override
  String toString() => 'LinkTarget($_name)';
}

class Link extends StatelessWidget {
  const Link({
    super.key,
    required this.uri,
    this.target = LinkTarget.defaultTarget,
    required this.builder,
  });

  final Uri? uri;
  final LinkTarget target;
  final LinkWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final destination = uri;
    return builder(
      context,
      destination == null
          ? null
          : () async {
              await launchUrl(
                destination,
                webOnlyWindowName: target == LinkTarget.defaultTarget
                    ? null
                    : target._name,
              );
            },
    );
  }
}
