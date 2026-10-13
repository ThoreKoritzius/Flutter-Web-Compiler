/// Only the supported core widget API; Material-only widgets are not exported.
library;

export 'flutter_dom.dart'
    show
        Widget,
        StatelessWidget,
        StatefulWidget,
        State,
        BuildContext,
        Key,
        runApp,
        Column,
        Row,
        SizedBox,
        Padding,
        Expanded,
        Text,
        CrossAxisAlignment;
export 'visual_metadata.dart' show Color, IconData;
export 'material_style.dart'
    show EdgeInsets, TextStyle, FontWeight, BorderRadius, BorderSide;
