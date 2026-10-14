/// The `dart:ui` facade for the native runtime: geometry, colors, text enums
/// and painting values. Window, isolate, image and paragraph APIs are not
/// provided and fail official compilation.
library;

import 'painting_ui.dart';

export 'foundation_dom.dart' show VoidCallback;
export 'material_style.dart'
    show
        Offset,
        Size,
        Rect,
        RRect,
        Radius,
        TextDirection,
        TextAlign,
        TextBaseline,
        TextDecoration,
        FontWeight,
        FontStyle,
        FontFeature,
        Brightness,
        Clip;
export 'painting_ui.dart' hide UiGradient, shaderSpec, replayPath, PathSink;
export 'visual_metadata.dart' show Color;

/// `ui.Gradient.linear` / `ui.Gradient.radial`.
typedef Gradient = UiGradient;
