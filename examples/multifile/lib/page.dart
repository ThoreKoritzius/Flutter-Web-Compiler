import 'package:flutter/widgets.dart' as ui;
import 'package:dom_multifile_example/content.dart' as content;
import 'components.dart';
import 'platform.dart';

class Page extends ui.StatelessWidget {
  const Page({super.key});

  @override
  ui.Widget build(ui.BuildContext context) => ui.Column(
    children: [
      const Heading(title: content.title),
      const ui.Text(platformLabel),
      if (content.showDetails)
        const ui.Text('Imports, exports and constants resolved by Dart.'),
    ],
  );
}
