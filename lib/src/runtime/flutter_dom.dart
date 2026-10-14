/// Experimental Flutter-shaped API for a deliberately bounded DOM target.
/// This is not the Flutter framework and does not claim layout parity.
///
/// Widgets inflate into a retained element tree. Elements reconcile by
/// runtime type and key, rebuild individually when marked dirty, and patch
/// the DOM nodes they own instead of replacing the view.
library;

export 'foundation_dom.dart';
export 'services_dom.dart';
export 'visual_metadata.dart';
export 'material_icons_metadata.dart';
export 'material_colors.dart';
export 'painting_ui.dart' hide UiGradient, shaderSpec, replayPath, PathSink;
export 'material_style.dart'
    hide
        borderRadiusCss,
        borderSideCss,
        boxBorderCss,
        boxShadowCss,
        checkedDimension,
        colorCss,
        cssUrl,
        decorationImageCss,
        objectFitCss,
        cssNumber,
        decorationCss,
        edgeInsetsCss,
        elevationCss,
        fontFamilyCss,
        gradientCss,
        px,
        shapeCss,
        textStyleCss;

import 'foundation_dom.dart';
import 'services_dom.dart';
import 'material_icons_metadata.dart';
import 'material_style.dart';
import 'painting_ui.dart';
import 'visual_metadata.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

part 'dom_framework.dart';
part 'dom_widgets.dart';
part 'dom_material.dart';
part 'dom_navigation.dart';
part 'dom_input.dart';
part 'dom_material_navigation.dart';
part 'dom_paint.dart';
