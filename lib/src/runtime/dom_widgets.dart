part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Text.

class DefaultTextStyle extends InheritedWidget {
  const DefaultTextStyle({
    super.key,
    required this.style,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    required super.child,
  });
  final TextStyle style;
  final TextAlign? textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;

  static Widget merge({
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    bool? softWrap,
    TextOverflow? overflow,
    int? maxLines,
    required Widget child,
  }) => Builder(
    key: key,
    builder: (context) {
      final parent = DefaultTextStyle.of(context);
      return DefaultTextStyle(
        style: parent.style.merge(style),
        textAlign: textAlign ?? parent.textAlign,
        softWrap: softWrap ?? parent.softWrap,
        overflow: overflow ?? parent.overflow,
        maxLines: maxLines ?? parent.maxLines,
        child: child,
      );
    },
  );

  /// Without an ancestor, the current theme's body style is the default.
  static DefaultTextStyle of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<DefaultTextStyle>();
    if (inherited != null) return inherited;
    final theme = Theme.of(context);
    return DefaultTextStyle(
      style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
        color: theme.colorScheme.onSurface,
      ),
      child: const SizedBox(),
    );
  }

  @override
  bool updateShouldNotify(DefaultTextStyle oldWidget) =>
      !identical(oldWidget.style, style) ||
      oldWidget.textAlign != textAlign ||
      oldWidget.softWrap != softWrap ||
      oldWidget.overflow != overflow ||
      oldWidget.maxLines != maxLines;
}

abstract class InlineSpan {
  const InlineSpan({this.style});
  final TextStyle? style;
  String toPlainText();
}

// Gesture recognizers for text spans. Only taps are recognized.
abstract class GestureRecognizer {
  GestureRecognizer({this.debugOwner});
  final Object? debugOwner;
  void dispose() {}
}

abstract class OneSequenceGestureRecognizer extends GestureRecognizer {
  OneSequenceGestureRecognizer({super.debugOwner});
}

class TapGestureRecognizer extends OneSequenceGestureRecognizer {
  TapGestureRecognizer({super.debugOwner});
  VoidCallback? onTap;
  VoidCallback? onTapCancel;
  Object? onTapDown, onTapUp, onSecondaryTap;
}

class TextSpan extends InlineSpan {
  const TextSpan({
    this.text,
    this.children,
    super.style,
    this.recognizer,
    this.mouseCursor,
    this.onEnter,
    this.onExit,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.locale,
    this.spellOut,
  });
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final String? semanticsIdentifier;
  final Locale? locale;
  final bool? spellOut;
  final String? text;
  final List<InlineSpan>? children;
  final GestureRecognizer? recognizer;
  final MouseCursor? mouseCursor;
  final String? semanticsLabel;
  @override
  String toPlainText() =>
      '${text ?? ''}${children?.map((c) => c.toPlainText()).join() ?? ''}';
}

enum PlaceholderAlignment {
  baseline,
  aboveBaseline,
  belowBaseline,
  top,
  bottom,
  middle,
}

class WidgetSpan extends InlineSpan {
  const WidgetSpan({
    required this.child,
    this.alignment = PlaceholderAlignment.bottom,
    this.baseline,
    super.style,
  });
  final Widget child;
  final PlaceholderAlignment alignment;
  final TextBaseline? baseline;
  @override
  String toPlainText() => '￼';
}

String _textAlignCss(TextAlign? align) => align == null
    ? ''
    : 'text-align:${switch (align) {
        TextAlign.left => 'left',
        TextAlign.right => 'right',
        TextAlign.center => 'center',
        TextAlign.justify => 'justify',
        TextAlign.start => 'start',
        TextAlign.end => 'end',
      }};';

class Text extends _DomWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.semanticsLabel,
    this.textScaler,
    this.strutStyle,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;
  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.semanticsLabel,
    this.textScaler,
    this.strutStyle,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;
  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? semanticsLabel;
  final TextScaler? textScaler;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final Locale? locale;
  final double? textScaleFactor;
  final String? semanticsIdentifier;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  String get _tag => 'p';
  @override
  _Fill get _fill => _Fill.none;

  @override
  void _render(_DomBuilder out) {
    final defaults = DefaultTextStyle.of(out.context);
    var effective = defaults.style.merge(style);
    if (effective.color == null) {
      effective = effective.copyWith(
        color: Theme.of(out.context).colorScheme.onSurface,
      );
    }
    final scale = textScaler?.textScaleFactor ?? 1;
    if (scale != 1 && effective.fontSize != null) {
      effective = effective.copyWith(fontSize: effective.fontSize! * scale);
    }
    final lines = maxLines ?? defaults.maxLines;
    if (lines != null && lines < 1)
      throw ArgumentError('maxLines must be positive.');
    final wraps = softWrap ?? defaults.softWrap;
    final clip = overflow ?? effective.overflow ?? defaults.overflow;
    out.css(
      'margin:0;min-width:0;overflow-wrap:break-word;white-space:${wraps ? 'pre-wrap' : 'pre'};',
    );
    out.css(textStyleCss(effective));
    out.css(_textAlignCss(textAlign ?? defaults.textAlign));
    if (clip == TextOverflow.ellipsis && lines != null) {
      out.css(
        'display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:$lines;overflow:hidden;',
      );
    } else if (clip == TextOverflow.ellipsis) {
      out.css('overflow:hidden;text-overflow:ellipsis;');
    } else if (lines != null && clip != TextOverflow.visible) {
      out.css('overflow:hidden;max-height:calc(${lines}lh);');
    } else if (clip != TextOverflow.visible && !wraps) {
      out.css('overflow:hidden;');
    }
    if (semanticsLabel != null) out.attributes['aria-label'] = semanticsLabel!;
    if (data != null) {
      out.text = data;
    } else {
      out.children = [_Span(textSpan!)];
    }
  }
}

class _Span extends _DomWidget {
  const _Span(this.span);
  final InlineSpan span;
  @override
  String get _tag => 'span';
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    final span = this.span;
    out.css(textStyleCss(span.style));
    if (span is WidgetSpan) {
      out.css(
        'display:inline-block;vertical-align:${switch (span.alignment) {
          PlaceholderAlignment.baseline => 'baseline',
          PlaceholderAlignment.aboveBaseline => 'text-bottom',
          PlaceholderAlignment.belowBaseline => 'text-top',
          PlaceholderAlignment.top => 'top',
          PlaceholderAlignment.bottom => 'bottom',
          PlaceholderAlignment.middle => 'middle',
        }};',
      );
      out.child(span.child);
      return;
    }
    if (span is! TextSpan) throw UnsupportedError('Unsupported inline span.');
    if (span.semanticsLabel != null)
      out.attributes['aria-label'] = span.semanticsLabel!;
    final recognizer = span.recognizer;
    if (recognizer is TapGestureRecognizer && recognizer.onTap != null) {
      // Tappable text behaves as a keyboard-accessible link.
      out.attributes['role'] = 'link';
      out.attributes['tabindex'] = '0';
      out.css('cursor:${span.mouseCursor?._css ?? 'pointer'};');
      void activate() => recognizer.onTap?.call();
      out.on('click', (_) => activate());
      out.on('keydown', (event) {
        if (event?.key == 'Enter') {
          event?.preventDefault();
          activate();
        }
      });
    } else if (recognizer != null) {
      throw UnsupportedError('Only tap recognizers are supported on spans.');
    }
    final children = span.children;
    if (children == null || children.isEmpty) {
      out.text = span.text ?? '';
    } else {
      out.children = [
        if (span.text != null) _Span(TextSpan(text: span.text)),
        for (final child in children) _Span(child),
      ];
    }
  }
}

class RichText extends StatelessWidget {
  const RichText({
    super.key,
    required this.text,
    this.textAlign = TextAlign.start,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.textDirection,
    this.textScaleFactor = 1,
    this.textScaler = TextScaler.noScaling,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.selectionRegistrar,
    this.selectionColor,
  });
  final TextDirection? textDirection;
  final double textScaleFactor;
  final TextScaler textScaler;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Object? selectionRegistrar;
  final Color? selectionColor;
  final InlineSpan text;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  @override
  Widget build(BuildContext context) => Text.rich(
    text,
    textAlign: textAlign,
    softWrap: softWrap,
    overflow: overflow,
    maxLines: maxLines,
  );
}

/// Native document text is already selectable.
class SelectableText extends Text {
  const SelectableText(
    super.data, {
    super.key,
    this.focusNode,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.textScaler,
    this.showCursor = false,
    this.autofocus = false,
    this.minLines,
    super.maxLines,
    this.cursorWidth = 2,
    this.cursorColor,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.scrollPhysics,
    super.semanticsLabel,
    super.textHeightBehavior,
    super.textWidthBasis,
    this.onSelectionChanged,
    this.contextMenuBuilder,
  });
  const SelectableText.rich(
    TextSpan super.textSpan, {
    super.key,
    this.focusNode,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.textScaler,
    this.showCursor = false,
    this.autofocus = false,
    this.minLines,
    super.maxLines,
    this.cursorWidth = 2,
    this.cursorColor,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.scrollPhysics,
    super.semanticsLabel,
    super.textHeightBehavior,
    super.textWidthBasis,
    this.onSelectionChanged,
    this.contextMenuBuilder,
  }) : super.rich();
  final FocusNode? focusNode;
  final bool showCursor, autofocus, enableInteractiveSelection;
  final int? minLines;
  final double cursorWidth;
  final Color? cursorColor;
  final VoidCallback? onTap;
  final ScrollPhysics? scrollPhysics;
  final Object? onSelectionChanged, contextMenuBuilder;
}

class SelectionArea extends StatelessWidget {
  const SelectionArea({
    super.key,
    required this.child,
    this.focusNode,
    this.selectionControls,
    this.contextMenuBuilder,
    this.magnifierConfiguration,
    this.onSelectionChanged,
  });
  final FocusNode? focusNode;
  final Object? selectionControls, contextMenuBuilder, magnifierConfiguration;
  final Object? onSelectionChanged;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

// ---------------------------------------------------------------------------
// Icons.

class IconTheme extends InheritedWidget {
  const IconTheme({super.key, required this.data, required super.child});
  final IconThemeData data;

  static Widget merge({
    Key? key,
    required IconThemeData data,
    required Widget child,
  }) => Builder(
    key: key,
    builder: (context) =>
        IconTheme(data: IconTheme.of(context).merge(data), child: child),
  );

  static IconThemeData of(BuildContext context) {
    final theme = Theme.of(context).iconTheme;
    final inherited = context.dependOnInheritedWidgetOfExactType<IconTheme>();
    return theme.merge(inherited?.data);
  }

  @override
  bool updateShouldNotify(IconTheme oldWidget) =>
      !identical(oldWidget.data, data);
}

/// Renders a glyph from the icon's font family. The build supplies the font
/// through @font-face; no emoji or substitute glyphs are used.
class Icon extends _DomWidget {
  const Icon(
    this.icon, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
    this.blendMode,
    this.fontWeight,
  });
  final double? fill, weight, grade, opticalSize;
  final List<Shadow>? shadows;
  final bool? applyTextScaling;
  final BlendMode? blendMode;
  final FontWeight? fontWeight;
  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;

  @override
  String get _tag => 'span';
  @override
  _Fill get _fill => _Fill.none;

  @override
  void _render(_DomBuilder out) {
    final theme = IconTheme.of(out.context);
    final iconSize = checkedDimension(size ?? theme.size ?? 24);
    var iconColor =
        color ??
        theme.color ??
        Theme.of(out.context).colorScheme.onSurfaceVariant;
    if (theme.opacity != null && color == null) {
      iconColor = iconColor.withValues(
        alpha: iconColor.alpha / 255 * theme.opacity!,
      );
    }
    out.css(
      'display:inline-flex;align-items:center;justify-content:center;flex-shrink:0;width:${px(iconSize)};height:${px(iconSize)};font-size:${px(iconSize)};line-height:1;color:${colorCss(iconColor)};font-style:normal;font-weight:normal;letter-spacing:normal;text-transform:none;white-space:nowrap;overflow:hidden;user-select:none;-webkit-font-smoothing:antialiased;',
    );
    if (semanticLabel == null) {
      out.attributes['aria-hidden'] = 'true';
    } else {
      out.attributes['role'] = 'img';
      out.attributes['aria-label'] = semanticLabel!;
    }
    final data = icon;
    if (data == null) {
      out.text = '';
      return;
    }
    final family = data.fontFamily;
    if (family == null)
      throw UnsupportedError('Icons require a font family to render.');
    final resolved = data.fontPackage == null
        ? family
        : 'packages/${data.fontPackage}/$family';
    out.css(fontFamilyCss(TextStyle(fontFamily: resolved)));
    // Variable icon fonts (Material Symbols) read these axes.
    final axes = {
      'FILL': fill,
      'wght': weight,
      'GRAD': grade,
      'opsz': opticalSize,
    }..removeWhere((_, value) => value == null);
    if (axes.isNotEmpty) {
      out.css(
        'font-variation-settings:${axes.entries.map((e) => '"${e.key}" ${cssNumber(e.value!)}').join(',')};',
      );
    }
    final iconShadows = shadows;
    if (iconShadows != null && iconShadows.isNotEmpty) {
      out.css(
        'text-shadow:${iconShadows.map((s) => '${cssNumber(s.offset.dx)}px ${cssNumber(s.offset.dy)}px ${cssNumber(s.blurRadius)}px ${colorCss(s.color)}').join(',')};',
      );
    }
    if (data.matchTextDirection && textDirection == TextDirection.rtl)
      out.css('transform:scaleX(-1);');
    out.text = String.fromCharCode(data.codePoint);
  }
}

class ImageIcon extends StatelessWidget {
  const ImageIcon(this.image, {super.key, this.size, this.color});
  final Object? image;
  final double? size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      throw UnsupportedError('ImageIcon is not supported.');
}

// ---------------------------------------------------------------------------
// Flex layout.

enum Axis { horizontal, vertical }

enum MainAxisAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

enum MainAxisSize { min, max }

enum CrossAxisAlignment { start, end, center, stretch, baseline }

enum VerticalDirection { up, down }

enum FlexFit { tight, loose }

String _justifyCss(MainAxisAlignment alignment) => switch (alignment) {
  MainAxisAlignment.start => 'flex-start',
  MainAxisAlignment.end => 'flex-end',
  MainAxisAlignment.center => 'center',
  MainAxisAlignment.spaceBetween => 'space-between',
  MainAxisAlignment.spaceAround => 'space-around',
  MainAxisAlignment.spaceEvenly => 'space-evenly',
};

String _crossCss(CrossAxisAlignment alignment) => switch (alignment) {
  CrossAxisAlignment.start => 'flex-start',
  CrossAxisAlignment.end => 'flex-end',
  CrossAxisAlignment.center => 'center',
  CrossAxisAlignment.stretch => 'stretch',
  CrossAxisAlignment.baseline => 'baseline',
};

class Flex extends _DomWidget {
  const Flex({
    this.clipBehavior,
    super.key,
    required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.spacing = 0,
    this.children = const [],
  });

  /// Accepted for API compatibility; shaped boxes clip through CSS.
  final Clip? clipBehavior;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final double spacing;
  final List<Widget> children;

  bool get _horizontal => direction == Axis.horizontal;
  @override
  _DomLayout get _layout => _horizontal ? _DomLayout.row : _DomLayout.column;

  /// A max-size Row fills the width; a Column fills only when it stretches.
  @override
  _Fill get _fill =>
      (_horizontal && mainAxisSize == MainAxisSize.max) ||
          (!_horizontal && crossAxisAlignment == CrossAxisAlignment.stretch)
      ? _Fill.expand
      : _Fill.child;

  @override
  void _render(_DomBuilder out) {
    final reversed = verticalDirection == VerticalDirection.up && !_horizontal;
    out.css(
      'display:flex;flex-direction:${_horizontal ? 'row' : 'column'}${reversed ? '-reverse' : ''};box-sizing:border-box;min-width:0;min-height:0;',
    );
    if (mainAxisAlignment != MainAxisAlignment.start)
      out.css('justify-content:${_justifyCss(mainAxisAlignment)};');
    out.css('align-items:${_crossCss(crossAxisAlignment)};');
    if (spacing != 0) out.css('gap:${px(spacing)};');
    if (_horizontal && mainAxisSize == MainAxisSize.min)
      out.css('width:fit-content;max-width:100%;');
    out.children = children;
  }
}

class Row extends Flex {
  const Row({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.spacing,
    super.children,
  }) : super(direction: Axis.horizontal);
}

class Column extends Flex {
  const Column({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.spacing,
    super.children,
  }) : super(direction: Axis.vertical);
}

void _requireFlexParent(_DomBuilder out, String name) {
  if (out.context.parentDomWidget is! Flex)
    throw UnsupportedError('$name requires a Row or Column parent.');
}

class Flexible extends _DomWidget {
  const Flexible({
    super.key,
    this.flex = 1,
    this.fit = FlexFit.loose,
    required this.child,
  });
  final int flex;
  final FlexFit fit;
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    _requireFlexParent(out, runtimeType.toString());
    if (flex < 1) throw ArgumentError('Expanded flex must be positive.');
    // A one-cell grid stretches the child across the allocated space.
    out.css(
      fit == FlexFit.tight
          ? 'flex:$flex 1 0;min-width:0;min-height:0;display:grid;grid-template-columns:minmax(0,1fr);'
          : 'flex:0 1 auto;min-width:0;min-height:0;display:grid;grid-template-columns:minmax(0,1fr);',
    );
    out.child(child);
  }
}

class Expanded extends Flexible {
  const Expanded({super.key, super.flex, required super.child})
    : super(fit: FlexFit.tight);
}

class Spacer extends _DomWidget {
  const Spacer({super.key, this.flex = 1});
  final int flex;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    _requireFlexParent(out, 'Spacer');
    if (flex < 1) throw ArgumentError('Spacer flex must be positive.');
    out.css('flex:$flex 1 0;min-width:0;min-height:0;');
  }
}

// ---------------------------------------------------------------------------
// Boxes.

String _dimension(String property, double? value) {
  if (value == null) return '';
  if (value == double.infinity) return '';
  return '$property:${px(value)};';
}

class SizedBox extends _DomWidget {
  const SizedBox({super.key, this.width, this.height, this.child});
  const SizedBox.shrink({super.key, this.child}) : width = 0, height = 0;
  const SizedBox.expand({super.key, this.child})
    : width = double.infinity,
      height = double.infinity;
  const SizedBox.square({super.key, double? dimension, this.child})
    : width = dimension,
      height = dimension;
  SizedBox.fromSize({super.key, Size? size, this.child})
    : width = size?.width,
      height = size?.height;
  final double? width, height;
  final Widget? child;

  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => width == double.infinity
      ? _Fill.expand
      : width == null && child != null
      ? _Fill.child
      : _Fill.none;

  @override
  void _render(_DomBuilder out) {
    for (final size in [width, height]) {
      if (size != null &&
          size != double.infinity &&
          (!size.isFinite || size < 0))
        throw ArgumentError('Invalid size.');
    }
    out.css('flex-shrink:0;');
    out.css(_dimension('height', height));
    out.css(_dimension('width', width));
    if (height == double.infinity) out.css('align-self:stretch;');
    final child = this.child;
    if (child != null) {
      // Tight constraints: the child fills the box, as in Flutter.
      out.css('display:grid;grid-template-columns:minmax(0,1fr);');
      out.child(child);
    }
  }
}

class Padding extends _DomWidget {
  const Padding({super.key, required this.padding, this.child});
  final EdgeInsetsGeometry padding;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    final p = padding.resolve(TextDirection.ltr);
    out.css(
      'box-sizing:border-box;min-width:0;min-height:0;display:grid;grid-template-columns:minmax(0,1fr);padding:${px(p.top)} ${px(p.right)} ${px(p.bottom)} ${px(p.left)};',
    );
    if (child != null) out.child(child!);
  }
}

String _alignCss(AlignmentGeometry alignment) {
  final a = alignment.resolve(TextDirection.ltr);
  String axis(double v) => v < 0
      ? 'flex-start'
      : v > 0
      ? 'flex-end'
      : 'center';
  return 'display:flex;justify-content:${axis(a.x)};align-items:${axis(a.y)};';
}

class Align extends _DomWidget {
  const Align({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    this.child,
  });
  final AlignmentGeometry alignment;
  final double? widthFactor, heightFactor;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.align;
  @override
  _Fill get _fill => widthFactor == null ? _Fill.expand : _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('box-sizing:border-box;min-width:0;${_alignCss(alignment)}');
    if (heightFactor == null) out.css('align-self:stretch;');
    if (child != null) out.child(child!);
  }
}

class Center extends Align {
  const Center({super.key, super.widthFactor, super.heightFactor, super.child});
}

class ColoredBox extends _DomWidget {
  const ColoredBox({super.key, required this.color, this.child});
  final Color color;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    out.css('background-color:${colorCss(color)};');
    if (child != null) out.child(child!);
  }
}

enum DecorationPosition { background, foreground }

class DecoratedBox extends _DomWidget {
  const DecoratedBox({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    this.child,
  });
  final Decoration decoration;
  final DecorationPosition position;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    out.css('box-sizing:border-box;${decorationCss(decoration)}');
    if (child != null) out.child(child!);
  }
}

String _constraintsCss(BoxConstraints? c) {
  if (c == null) return '';
  final out = StringBuffer();
  if (c.minWidth > 0 && c.minWidth.isFinite)
    out.write('min-width:${px(c.minWidth)};');
  if (c.maxWidth.isFinite) out.write('max-width:${px(c.maxWidth)};');
  if (c.minHeight > 0 && c.minHeight.isFinite)
    out.write('min-height:${px(c.minHeight)};');
  if (c.maxHeight.isFinite) out.write('max-height:${px(c.maxHeight)};');
  if (c.minWidth.isFinite && c.minWidth == c.maxWidth)
    out.write('width:${px(c.maxWidth)};');
  if (c.minHeight.isFinite && c.minHeight == c.maxHeight)
    out.write('height:${px(c.maxHeight)};');
  return out.toString();
}

class ConstrainedBox extends _DomWidget {
  const ConstrainedBox({super.key, required this.constraints, this.child});
  final BoxConstraints constraints;
  final Widget? child;
  @override
  _Fill get _fill =>
      constraints.minWidth == double.infinity ? _Fill.expand : _Fill.child;
  @override
  void _render(_DomBuilder out) {
    out.css('box-sizing:border-box;${_constraintsCss(constraints)}');
    if (constraints.minHeight == double.infinity)
      out.css('align-self:stretch;');
    if (child != null) out.child(child!);
  }
}

/// Only applies when the incoming constraints are unbounded, which this
/// document-flow runtime does not model; the child is returned unchanged.
class LimitedBox extends StatelessWidget {
  const LimitedBox({
    super.key,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    this.child,
  });
  final double maxWidth, maxHeight;
  final Widget? child;
  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

/// Flutter's Container composition collapsed into one DOM element.
class Container extends _DomWidget {
  Container({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.clipBehavior = Clip.none,
    this.child,
  }) : constraints = (width != null || height != null)
           ? _tighten(constraints, width, height)
           : constraints {
    if (color != null && decoration != null)
      throw ArgumentError(
        'Cannot provide both a color and a decoration; use decoration.color.',
      );
  }
  static BoxConstraints _tighten(
    BoxConstraints? constraints,
    double? width,
    double? height,
  ) {
    final base = constraints ?? const BoxConstraints();
    return BoxConstraints(
      minWidth: width ?? base.minWidth,
      maxWidth: width ?? base.maxWidth,
      minHeight: height ?? base.minHeight,
      maxHeight: height ?? base.maxHeight,
    );
  }

  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding, margin;
  final Color? color;
  final Decoration? decoration, foregroundDecoration;
  final BoxConstraints? constraints;
  final Clip clipBehavior;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Widget? child;

  bool get _tightWidth =>
      constraints != null &&
      constraints!.minWidth == constraints!.maxWidth &&
      constraints!.maxWidth.isFinite;

  @override
  _DomLayout get _layout =>
      alignment != null ? _DomLayout.align : _DomLayout.grid;

  @override
  _Fill get _fill {
    if (constraints?.maxWidth == double.infinity &&
        constraints?.minWidth == double.infinity)
      return _Fill.expand;
    if (_tightWidth) return _Fill.none;
    if (child == null || alignment != null) return _Fill.expand;
    return _Fill.child;
  }

  @override
  void _render(_DomBuilder out) {
    out.css('box-sizing:border-box;min-width:0;flex-shrink:0;');
    out.css(edgeInsetsCss('margin', margin));
    out.css(_constraintsCss(constraints));
    if (color != null) out.css('background-color:${colorCss(color!)};');
    out.css(decorationCss(decoration));
    out.css(edgeInsetsCss('padding', padding));
    if (clipBehavior != Clip.none) out.css('overflow:hidden;');
    final matrix = transform;
    if (matrix != null) {
      final a = (transformAlignment ?? Alignment.topLeft).resolve(
        TextDirection.ltr,
      );
      out.css(
        'transform-origin:${cssNumber((a.x + 1) * 50)}% ${cssNumber((a.y + 1) * 50)}%;transform:matrix3d(${matrix.storage.map(cssNumber).join(',')});',
      );
    }
    if (alignment != null) {
      out.css(_alignCss(alignment!));
    } else if (child != null) {
      // A one-cell grid passes tight constraints to the child.
      out.css('display:grid;grid-template-columns:minmax(0,1fr);');
    }
    if (child != null) out.child(child!);
    if (foregroundDecoration case final foreground?) {
      // The foreground decoration paints over the content as an overlay.
      out.css('position:relative;');
      out.children = [
        ...out.children,
        _Box(
          css:
              'position:absolute;inset:0;pointer-events:none;${decorationCss(foreground)}',
          fill: _Fill.none,
        ),
      ];
    }
  }
}

class Opacity extends _DomWidget {
  const Opacity({
    super.key,
    required this.opacity,
    this.alwaysIncludeSemantics = false,
    this.child,
  });
  final double opacity;
  final bool alwaysIncludeSemantics;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    if (!(opacity >= 0 && opacity <= 1))
      throw ArgumentError('Opacity must be between zero and one.');
    out.css('opacity:${cssNumber(opacity)};');
    if (child != null) out.child(child!);
  }
}

class Offstage extends _DomWidget {
  const Offstage({super.key, this.offstage = true, this.child});
  final bool offstage;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    if (offstage) {
      out.css('display:none;');
      out.attributes['aria-hidden'] = 'true';
    }
    if (child != null) out.child(child!);
  }
}

class Visibility extends StatelessWidget {
  const Visibility({
    super.key,
    required this.child,
    this.replacement = const SizedBox.shrink(),
    this.visible = true,
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
  });
  const Visibility.maintain({
    super.key,
    required this.child,
    this.visible = true,
  }) : replacement = const SizedBox.shrink(),
       maintainState = true,
       maintainAnimation = true,
       maintainSize = true;
  final Widget child, replacement;
  final bool visible, maintainState, maintainAnimation, maintainSize;
  @override
  Widget build(BuildContext context) {
    if (maintainSize)
      return _VisibilityBox(hidden: !visible, keepSize: true, child: child);
    if (maintainState)
      return _VisibilityBox(hidden: !visible, keepSize: false, child: child);
    return visible ? child : replacement;
  }
}

class _VisibilityBox extends _DomWidget {
  const _VisibilityBox({
    required this.hidden,
    required this.keepSize,
    required this.child,
  });
  final bool hidden, keepSize;
  final Widget child;
  @override
  void _render(_DomBuilder out) {
    if (hidden) {
      out.css(keepSize ? 'visibility:hidden;' : 'display:none;');
      out.attributes['aria-hidden'] = 'true';
    }
    out.child(child);
  }
}

class ClipRRect extends _DomWidget {
  const ClipRRect({
    super.key,
    this.borderRadius = BorderRadius.zero,
    this.clipBehavior = Clip.antiAlias,
    this.child,
  });
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    out.css('overflow:hidden;${borderRadiusCss(borderRadius)}');
    if (child != null) out.child(child!);
  }
}

class ClipOval extends _DomWidget {
  const ClipOval({super.key, this.clipBehavior = Clip.antiAlias, this.child});
  final Clip clipBehavior;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    out.css('overflow:hidden;border-radius:50%;');
    if (child != null) out.child(child!);
  }
}

class ClipRect extends _DomWidget {
  const ClipRect({super.key, this.clipBehavior = Clip.hardEdge, this.child});
  final Clip clipBehavior;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    out.css('overflow:hidden;');
    if (child != null) out.child(child!);
  }
}

class AspectRatio extends _DomWidget {
  const AspectRatio({super.key, required this.aspectRatio, this.child});
  final double aspectRatio;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) {
    if (!(aspectRatio > 0) || !aspectRatio.isFinite)
      throw ArgumentError('Aspect ratio must be positive and finite.');
    out.css(
      'aspect-ratio:${cssNumber(aspectRatio)};display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
    );
    if (child != null) out.child(child!);
  }
}

class FractionallySizedBox extends _DomWidget {
  const FractionallySizedBox({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    this.child,
  });
  final AlignmentGeometry alignment;
  final double? widthFactor, heightFactor;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    if (widthFactor != null)
      out.css('width:${cssNumber(checkedDimension(widthFactor!) * 100)}%;');
    if (heightFactor != null)
      out.css('height:${cssNumber(checkedDimension(heightFactor!) * 100)}%;');
    final a = alignment.resolve(TextDirection.ltr);
    if (a.x == 0) out.css('margin-left:auto;margin-right:auto;');
    if (a.x > 0) out.css('margin-left:auto;');
    out.css('display:grid;grid-template-columns:minmax(0,1fr);');
    if (child != null) out.child(child!);
  }
}

/// Document padding for notches and system bars is zero in browsers.
class SafeArea extends StatelessWidget {
  const SafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
    required this.child,
  });
  final bool left, top, right, bottom, maintainBottomViewPadding;
  final EdgeInsets minimum;
  final Widget child;
  @override
  Widget build(BuildContext context) => minimum == EdgeInsets.zero
      ? child
      : Padding(padding: minimum, child: child);
}

class Directionality extends InheritedWidget {
  const Directionality({
    super.key,
    required this.textDirection,
    required super.child,
  });
  final TextDirection textDirection;
  static TextDirection of(BuildContext context) =>
      maybeOf(context) ?? TextDirection.ltr;
  static TextDirection? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<Directionality>()
      ?.textDirection;
  @override
  bool updateShouldNotify(Directionality oldWidget) =>
      oldWidget.textDirection != textDirection;
}

class Placeholder extends _DomWidget {
  const Placeholder({
    super.key,
    this.color = const Color(0xff455a64),
    this.fallbackWidth = 400,
    this.fallbackHeight = 400,
  });
  final Color color;
  final double fallbackWidth, fallbackHeight;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) => out.css(
    'box-sizing:border-box;border:2px solid ${colorCss(color)};min-height:${px(math.min(fallbackHeight, 100))};',
  );
}

// ---------------------------------------------------------------------------
// Wrap and Stack.

enum WrapAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

enum WrapCrossAlignment { start, end, center }

class Wrap extends _DomWidget {
  const Wrap({
    this.clipBehavior,
    super.key,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.children = const [],
  });

  /// Accepted for API compatibility; shaped boxes clip through CSS.
  final Clip? clipBehavior;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final Axis direction;
  final WrapAlignment alignment, runAlignment;
  final double spacing, runSpacing;
  final WrapCrossAlignment crossAxisAlignment;
  final List<Widget> children;
  @override
  _DomLayout get _layout => _DomLayout.wrap;
  @override
  void _render(_DomBuilder out) {
    final horizontal = direction == Axis.horizontal;
    String justify(WrapAlignment a) => switch (a) {
      WrapAlignment.start => 'flex-start',
      WrapAlignment.end => 'flex-end',
      WrapAlignment.center => 'center',
      WrapAlignment.spaceBetween => 'space-between',
      WrapAlignment.spaceAround => 'space-around',
      WrapAlignment.spaceEvenly => 'space-evenly',
    };
    out.css(
      'display:flex;flex-direction:${horizontal ? 'row' : 'column'};flex-wrap:wrap;align-items:${switch (crossAxisAlignment) {
        WrapCrossAlignment.start => 'flex-start',
        WrapCrossAlignment.end => 'flex-end',
        WrapCrossAlignment.center => 'center',
      }};column-gap:${px(horizontal ? spacing : runSpacing)};row-gap:${px(horizontal ? runSpacing : spacing)};',
    );
    if (alignment != WrapAlignment.start)
      out.css('justify-content:${justify(alignment)};');
    if (runAlignment != WrapAlignment.start)
      out.css('align-content:${justify(runAlignment)};');
    out.children = children;
  }
}

enum StackFit { loose, expand, passthrough }

class Stack extends _DomWidget {
  const Stack({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
    this.children = const [],
  });
  final AlignmentGeometry alignment;
  final StackFit fit;
  final Clip clipBehavior;
  final List<Widget> children;
  @override
  _DomLayout get _layout => _DomLayout.stack;
  @override
  _Fill get _fill => fit == StackFit.expand ? _Fill.expand : _Fill.child;
  @override
  void _render(_DomBuilder out) {
    // Positioned children have no intrinsic height. Expand both axes so a
    // bounded parent also supplies the paint and hit-test area's height.
    out.css(
      'position:relative;display:grid;grid-template-columns:minmax(0,1fr);min-width:0;${fit == StackFit.expand ? 'height:100%;min-height:0;' : ''}',
    );
    if (clipBehavior != Clip.none) out.css('overflow:hidden;');
    out.children = [
      for (final child in children)
        child is Positioned
            ? child
            : _StackSlot(
                key: child.key == null ? null : ValueKey<Key>(child.key!),
                alignment: alignment,
                expand: fit == StackFit.expand,
                child: child,
              ),
    ];
  }
}

class _StackSlot extends _DomWidget {
  const _StackSlot({
    super.key,
    required this.alignment,
    required this.expand,
    required this.child,
  });
  final AlignmentGeometry alignment;
  final bool expand;
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.stack;
  @override
  void _render(_DomBuilder out) {
    final a = alignment.resolve(TextDirection.ltr);
    String axis(double v) => v < 0
        ? 'start'
        : v > 0
        ? 'end'
        : 'center';
    out.css(
      expand
          ? 'grid-area:1/1;display:grid;grid-template-columns:minmax(0,1fr);'
          : 'grid-area:1/1;justify-self:${axis(a.x)};align-self:${axis(a.y)};min-width:0;',
    );
    out.child(child);
  }
}

/// Shows one child; the others stay mounted (keeping their state) but are
/// removed from rendering and the accessibility tree.
class IndexedStack extends StatelessWidget {
  const IndexedStack({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.sizing = StackFit.loose,
    this.index = 0,
    this.children = const [],
  });
  final AlignmentGeometry alignment;
  final StackFit sizing;
  final int? index;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: alignment,
    fit: sizing,
    children: [
      for (var i = 0; i < children.length; i++)
        Offstage(
          key: children[i].key == null
              ? ValueKey(i)
              : ValueKey<Key>(children[i].key!),
          offstage: i != index,
          child: children[i],
        ),
    ],
  );
}

class Positioned extends _DomWidget {
  const Positioned({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });
  const Positioned.fill({
    super.key,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    required this.child,
  }) : width = null,
       height = null;
  Positioned.fromRect({super.key, required Rect rect, required this.child})
    : left = rect.left,
      top = rect.top,
      width = rect.width,
      height = rect.height,
      right = null,
      bottom = null;
  Positioned.fromRelativeRect({
    super.key,
    required RelativeRect rect,
    required this.child,
  }) : left = rect.left,
       top = rect.top,
       right = rect.right,
       bottom = rect.bottom,
       width = null,
       height = null;
  factory Positioned.directional({
    Key? key,
    required TextDirection textDirection,
    double? start,
    double? top,
    double? end,
    double? bottom,
    double? width,
    double? height,
    required Widget child,
  }) {
    final rtl = textDirection == TextDirection.rtl;
    return Positioned(
      key: key,
      left: rtl ? end : start,
      top: top,
      right: rtl ? start : end,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }
  final double? left, top, right, bottom, width, height;
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    if (out.context.parentDomWidget is! Stack)
      throw UnsupportedError('Positioned requires a Stack parent.');
    String offset(String property, double? value) {
      if (value == null) return '';
      if (!value.isFinite) throw ArgumentError('Invalid position.');
      return '$property:${cssNumber(value)}px;';
    }

    out.css(
      'position:absolute;display:grid;grid-template-columns:minmax(0,1fr);${offset('left', left)}${offset('top', top)}${offset('right', right)}${offset('bottom', bottom)}${_dimension('width', width)}${_dimension('height', height)}',
    );
    out.child(child);
  }
}

// ---------------------------------------------------------------------------
// Scrolling. Content is built eagerly; scroll physics, controllers and
// slivers are not modeled. Vertical scroll views grow with the document
// unless an ancestor bounds their height.

class ScrollPhysics {
  const ScrollPhysics();
}

class NeverScrollableScrollPhysics extends ScrollPhysics {
  const NeverScrollableScrollPhysics();
}

class AlwaysScrollableScrollPhysics extends ScrollPhysics {
  const AlwaysScrollableScrollPhysics();
}

class BouncingScrollPhysics extends ScrollPhysics {
  const BouncingScrollPhysics();
}

class ClampingScrollPhysics extends ScrollPhysics {
  const ClampingScrollPhysics();
}

const _eagerItemLimit = 10000;

class _ScrollList extends _DomWidget {
  const _ScrollList({
    required this.axis,
    required this.padding,
    required this.scrolls,
    required this.children,
    this.overflowVisible = false,
    this.pageFraction,
  });

  /// Children are pages snapping at this fraction of the viewport.
  final double? pageFraction;
  final Axis axis;
  final EdgeInsetsGeometry? padding;
  final bool scrolls;

  /// The page scrolls instead (no ancestor bounds this view), so pinned
  /// descendants stick to the viewport.
  final bool overflowVisible;
  final List<Widget> children;
  @override
  _DomLayout get _layout =>
      axis == Axis.vertical ? _DomLayout.column : _DomLayout.row;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) {
    final vertical = axis == Axis.vertical;
    out.css(
      'display:flex;flex-direction:${vertical ? 'column' : 'row'};align-items:stretch;box-sizing:border-box;min-width:0;min-height:0;',
    );
    if (scrolls && !overflowVisible)
      out.css(
        vertical ? 'overflow-y:auto;' : 'overflow-x:auto;overflow-y:hidden;',
      );
    out.css(edgeInsetsCss('padding', padding));
    final fraction = pageFraction;
    if (fraction != null) {
      out.css(
        '${vertical ? 'scroll-snap-type:y mandatory;height:100%;' : 'scroll-snap-type:x mandatory;'}scrollbar-width:none;',
      );
      out.children = [
        for (final child in children)
          _Box(
            key: child.key,
            css:
                'flex:0 0 ${cssNumber(fraction * 100)}%;${vertical ? 'min-height:0;' : 'min-width:0;'}scroll-snap-align:center;scroll-snap-stop:always;display:grid;grid-template-columns:minmax(0,1fr);',
            layout: _DomLayout.grid,
            fill: _Fill.expand,
            children: [child],
          ),
      ];
      return;
    }
    out.children = vertical
        ? children
        : [
            for (final child in children)
              _NoShrink(key: child.key, child: child),
          ];
  }
}

class _NoShrink extends _DomWidget {
  const _NoShrink({super.key, required this.child});
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    out.css('flex-shrink:0;display:grid;');
    out.child(child);
  }
}

class SingleChildScrollView extends StatelessWidget {
  const SingleChildScrollView({
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.clipBehavior,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    this.controller,
    this.child,
  });

  /// Accepted for API compatibility; shaped boxes clip through CSS.
  final Object? dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final String? restorationId;
  final HitTestBehavior? hitTestBehavior;
  final Clip? clipBehavior;
  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsetsGeometry? padding;
  final bool? primary;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Widget? child;
  @override
  Widget build(BuildContext context) => _Scrollable(
    axis: scrollDirection,
    padding: padding,
    scrolls: physics is! NeverScrollableScrollPhysics,
    controller: controller,
    children: [?child],
  );
}

class ListView extends StatelessWidget {
  ListView({
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.prototypeItem,
    this.findChildIndexCallback,
    this.addAutomaticKeepAlives,
    this.addRepaintBoundaries,
    this.addSemanticIndexes,
    this.clipBehavior,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    List<Widget> children = const [],
  }) : _children = children,
       _itemCount = null,
       _itemBuilder = null,
       _separatorBuilder = null;
  ListView.builder({
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.prototypeItem,
    this.findChildIndexCallback,
    this.addAutomaticKeepAlives,
    this.addRepaintBoundaries,
    this.addSemanticIndexes,
    this.clipBehavior,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
  }) : _children = null,
       _itemCount = itemCount,
       _itemBuilder = itemBuilder,
       _separatorBuilder = null;
  ListView.separated({
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.prototypeItem,
    this.findChildIndexCallback,
    this.addAutomaticKeepAlives,
    this.addRepaintBoundaries,
    this.addSemanticIndexes,
    this.clipBehavior,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required NullableIndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
  }) : _children = null,
       itemExtent = null,
       _itemCount = itemCount,
       _itemBuilder = itemBuilder,
       _separatorBuilder = separatorBuilder;

  /// Accepted for API compatibility; shaped boxes clip through CSS.
  final double? cacheExtent;
  final int? semanticChildCount;
  final Object? dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final String? restorationId;
  final HitTestBehavior? hitTestBehavior;
  final Widget? prototypeItem;
  final int? Function(Key key)? findChildIndexCallback;
  final bool? addAutomaticKeepAlives;
  final bool? addRepaintBoundaries;
  final bool? addSemanticIndexes;
  final Clip? clipBehavior;
  final Axis scrollDirection;
  final bool reverse, shrinkWrap;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final List<Widget>? _children;
  final int? _itemCount;
  final NullableIndexedWidgetBuilder? _itemBuilder;
  final IndexedWidgetBuilder? _separatorBuilder;

  @override
  Widget build(BuildContext context) {
    var items = _children;
    if (items == null) {
      final count = _itemCount;
      if (count == null)
        throw UnsupportedError(
          'Unbounded lazy lists are unsupported; provide itemCount.',
        );
      if (count < 0 || count > _eagerItemLimit)
        throw ArgumentError('List item count exceeds the native limit.');
      items = [];
      for (var i = 0; i < count; i++) {
        final item = _itemBuilder!(context, i);
        if (item == null) break;
        items.add(item);
        if (_separatorBuilder != null && i < count - 1)
          items.add(_separatorBuilder(context, i));
      }
    }
    if (itemExtent != null) {
      items = [
        for (final item in items)
          SizedBox(
            key: item.key,
            height: scrollDirection == Axis.vertical ? itemExtent : null,
            width: scrollDirection == Axis.horizontal ? itemExtent : null,
            child: item,
          ),
      ];
    }
    return _Scrollable(
      axis: scrollDirection,
      padding: padding,
      scrolls: physics is! NeverScrollableScrollPhysics,
      controller: controller,
      reverse: reverse,
      children: items,
    );
  }
}

abstract class SliverGridDelegate {
  const SliverGridDelegate();
}

class SliverGridDelegateWithFixedCrossAxisCount extends SliverGridDelegate {
  const SliverGridDelegateWithFixedCrossAxisCount({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.childAspectRatio = 1,
    this.mainAxisExtent,
  });
  final int crossAxisCount;
  final double mainAxisSpacing, crossAxisSpacing, childAspectRatio;
  final double? mainAxisExtent;
}

class SliverGridDelegateWithMaxCrossAxisExtent extends SliverGridDelegate {
  const SliverGridDelegateWithMaxCrossAxisExtent({
    required this.maxCrossAxisExtent,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.childAspectRatio = 1,
    this.mainAxisExtent,
  });
  final double maxCrossAxisExtent;
  final double mainAxisSpacing, crossAxisSpacing, childAspectRatio;
  final double? mainAxisExtent;
}

class GridView extends StatelessWidget {
  GridView({
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.addAutomaticKeepAlives,
    this.addRepaintBoundaries,
    this.addSemanticIndexes,
    this.clipBehavior,
    super.key,
    required this.gridDelegate,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.primary,
    this.scrollDirection = Axis.vertical,
    List<Widget> children = const [],
  }) : _children = children,
       _itemBuilder = null,
       _itemCount = null;
  GridView.builder({
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.addAutomaticKeepAlives,
    this.addRepaintBoundaries,
    this.addSemanticIndexes,
    this.clipBehavior,
    super.key,
    required this.gridDelegate,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.primary,
    this.scrollDirection = Axis.vertical,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
  }) : _children = null,
       _itemBuilder = itemBuilder,
       _itemCount = itemCount;
  GridView.count({
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.addAutomaticKeepAlives,
    this.addRepaintBoundaries,
    this.addSemanticIndexes,
    this.clipBehavior,
    super.key,
    required int crossAxisCount,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    double childAspectRatio = 1,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.primary,
    this.scrollDirection = Axis.vertical,
    List<Widget> children = const [],
  }) : gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       _children = children,
       _itemBuilder = null,
       _itemCount = null;
  GridView.extent({
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.hitTestBehavior,
    this.addAutomaticKeepAlives,
    this.addRepaintBoundaries,
    this.addSemanticIndexes,
    this.clipBehavior,
    super.key,
    required double maxCrossAxisExtent,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    double childAspectRatio = 1,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.primary,
    this.scrollDirection = Axis.vertical,
    List<Widget> children = const [],
  }) : gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
         maxCrossAxisExtent: maxCrossAxisExtent,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       _children = children,
       _itemBuilder = null,
       _itemCount = null;

  /// Accepted for API compatibility; shaped boxes clip through CSS.
  final double? cacheExtent;
  final int? semanticChildCount;
  final Object? dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final String? restorationId;
  final HitTestBehavior? hitTestBehavior;
  final bool? addAutomaticKeepAlives;
  final bool? addRepaintBoundaries;
  final bool? addSemanticIndexes;
  final Clip? clipBehavior;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool? primary;
  final Axis scrollDirection;
  final List<Widget>? _children;
  final NullableIndexedWidgetBuilder? _itemBuilder;
  final int? _itemCount;

  @override
  Widget build(BuildContext context) {
    if (scrollDirection != Axis.vertical)
      throw UnsupportedError('Horizontal grids are unsupported.');
    var items = _children;
    if (items == null) {
      final count = _itemCount;
      if (count == null)
        throw UnsupportedError(
          'Unbounded lazy grids are unsupported; provide itemCount.',
        );
      if (count < 0 || count > _eagerItemLimit)
        throw ArgumentError('Grid item count exceeds the native limit.');
      items = [];
      for (var i = 0; i < count; i++) {
        final item = _itemBuilder!(context, i);
        if (item == null) break;
        items.add(item);
      }
    }
    return _Grid(delegate: gridDelegate, padding: padding, children: items);
  }
}

class _Grid extends _DomWidget {
  const _Grid({
    required this.delegate,
    required this.padding,
    required this.children,
  });
  final SliverGridDelegate delegate;
  final EdgeInsetsGeometry? padding;
  final List<Widget> children;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) {
    final d = delegate;
    final double rowGap, columnGap, ratio;
    final double? extent;
    if (d is SliverGridDelegateWithFixedCrossAxisCount) {
      if (d.crossAxisCount < 1 || d.crossAxisCount > 64)
        throw ArgumentError('Invalid grid column count.');
      out.css(
        'grid-template-columns:repeat(${d.crossAxisCount},minmax(0,1fr));',
      );
      (rowGap, columnGap, ratio, extent) = (
        d.mainAxisSpacing,
        d.crossAxisSpacing,
        d.childAspectRatio,
        d.mainAxisExtent,
      );
    } else if (d is SliverGridDelegateWithMaxCrossAxisExtent) {
      out.css(
        'grid-template-columns:repeat(auto-fill,minmax(min(100%,${px(d.maxCrossAxisExtent)}),1fr));',
      );
      (rowGap, columnGap, ratio, extent) = (
        d.mainAxisSpacing,
        d.crossAxisSpacing,
        d.childAspectRatio,
        d.mainAxisExtent,
      );
    } else {
      throw UnsupportedError('Unsupported grid delegate.');
    }
    if (!(ratio > 0) || !ratio.isFinite)
      throw ArgumentError('Grid aspect ratio must be positive.');
    out.css(
      'display:grid;row-gap:${px(rowGap)};column-gap:${px(columnGap)};box-sizing:border-box;min-width:0;',
    );
    out.css(edgeInsetsCss('padding', padding));
    out.children = [
      for (final child in children)
        _GridCell(
          key: child.key == null ? null : ValueKey<Key>(child.key!),
          aspectRatio: extent == null ? ratio : null,
          height: extent,
          child: child,
        ),
    ];
  }
}

class _GridCell extends _DomWidget {
  const _GridCell({
    super.key,
    required this.aspectRatio,
    required this.height,
    required this.child,
  });
  final double? aspectRatio, height;
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    out.css('display:grid;grid-template-columns:minmax(0,1fr);min-width:0;');
    if (aspectRatio != null)
      out.css('aspect-ratio:${cssNumber(aspectRatio!)};');
    if (height != null) out.css('height:${px(height!)};');
    out.child(child);
  }
}

class Scrollbar extends StatelessWidget {
  const Scrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbVisibility,
  });
  final Widget child;
  final ScrollController? controller;
  final bool? thumbVisibility;
  @override
  Widget build(BuildContext context) => child;
}

// ---------------------------------------------------------------------------
// Gestures and semantics.

enum HitTestBehavior { deferToChild, opaque, translucent }

class MouseCursor {
  const MouseCursor._(this._css);
  final String _css;
}

abstract final class SystemMouseCursors {
  static const basic = MouseCursor._('default');
  static const click = MouseCursor._('pointer');
  static const text = MouseCursor._('text');
  static const forbidden = MouseCursor._('not-allowed');
  static const grab = MouseCursor._('grab');
  static const grabbing = MouseCursor._('grabbing');
  static const help = MouseCursor._('help');
  static const move = MouseCursor._('move');
  static const none = MouseCursor._('none');
  static const wait = MouseCursor._('wait');
  static const progress = MouseCursor._('progress');
  static const precise = MouseCursor._('crosshair');
  static const resizeColumn = MouseCursor._('col-resize');
  static const resizeRow = MouseCursor._('row-resize');
}

/// Pointer-only, like Flutter's GestureDetector: it is not focusable.
class GestureDetector extends _DomWidget {
  const GestureDetector({
    super.key,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onSecondaryTap,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.behavior,
    this.excludeFromSemantics = false,
    this.child,
  });
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTap, onTapCancel, onDoubleTap, onSecondaryTap;
  final GestureLongPressCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;
  final GestureDragDownCallback? onVerticalDragDown,
      onHorizontalDragDown,
      onPanDown;
  final GestureDragStartCallback? onVerticalDragStart,
      onHorizontalDragStart,
      onPanStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate,
      onHorizontalDragUpdate,
      onPanUpdate;
  final GestureDragEndCallback? onVerticalDragEnd,
      onHorizontalDragEnd,
      onPanEnd;
  final GestureDragCancelCallback? onVerticalDragCancel,
      onHorizontalDragCancel,
      onPanCancel;
  final HitTestBehavior? behavior;
  final bool excludeFromSemantics;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    final drags = {
      _DragAxis.vertical: _DragCallbacks(
        onDown: onVerticalDragDown,
        onStart: onVerticalDragStart,
        onUpdate: onVerticalDragUpdate,
        onEnd: onVerticalDragEnd,
        onCancel: onVerticalDragCancel,
      ),
      _DragAxis.horizontal: _DragCallbacks(
        onDown: onHorizontalDragDown,
        onStart: onHorizontalDragStart,
        onUpdate: onHorizontalDragUpdate,
        onEnd: onHorizontalDragEnd,
        onCancel: onHorizontalDragCancel,
      ),
      _DragAxis.free: _DragCallbacks(
        onDown: onPanDown,
        onStart: onPanStart,
        onUpdate: onPanUpdate,
        onEnd: onPanEnd,
        onCancel: onPanCancel,
      ),
    }..removeWhere((_, callbacks) => callbacks.isEmpty);
    _installGestures(
      out,
      _GestureCallbacks(
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onLongPress: onLongPress,
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
        drags: drags,
      ),
    );
    if (onTap != null) {
      out.on('click', (event) {
        if (!_clickSuppressed(event)) onTap!();
      });
    }
    if (onDoubleTap != null) out.on('dblclick', (_) => onDoubleTap!());
    if (onSecondaryTap != null) {
      out.on('contextmenu', (event) {
        event?.preventDefault();
        onSecondaryTap!();
      });
    }
    if (child != null) out.child(child!);
  }
}

typedef PointerEnterEventListener = void Function(PointerEnterEvent event);
typedef PointerExitEventListener = void Function(PointerExitEvent event);

class PointerEnterEvent extends PointerEvent {
  const PointerEnterEvent({
    super.kind = PointerDeviceKind.mouse,
    super.position,
    super.localPosition,
    super.timeStamp,
  });
}

class PointerExitEvent extends PointerEvent {
  const PointerExitEvent({
    super.kind = PointerDeviceKind.mouse,
    super.position,
    super.localPosition,
    super.timeStamp,
  });
}

class MouseRegion extends _DomWidget {
  const MouseRegion({
    super.key,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor = SystemMouseCursors.basic,
    this.opaque = true,
    this.hitTestBehavior,
    this.child,
  });
  final MouseCursor cursor;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final PointerHoverEventListener? onHover;
  final bool opaque;
  final HitTestBehavior? hitTestBehavior;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    if (cursor != SystemMouseCursors.basic) out.css('cursor:${cursor._css};');
    (Offset, Offset) at(_Event? e) =>
        e == null ? (Offset.zero, Offset.zero) : _pointerPositions(e);
    if (onEnter != null) {
      out.on('mouseenter', (e) {
        final (global, local) = at(e);
        onEnter!(PointerEnterEvent(position: global, localPosition: local));
      });
    }
    if (onExit != null) {
      out.on('mouseleave', (e) {
        final (global, local) = at(e);
        onExit!(PointerExitEvent(position: global, localPosition: local));
      });
    }
    if (onHover != null) {
      out.on('mousemove', (e) {
        final (global, local) = at(e);
        onHover!(PointerHoverEvent(position: global, localPosition: local));
      });
    }
    if (child != null) out.child(child!);
  }
}

class Semantics extends _DomWidget {
  const Semantics({
    super.key,
    this.container = false,
    this.explicitChildNodes = false,
    this.excludeSemantics = false,
    this.blockUserActions = false,
    this.enabled,
    this.checked,
    this.mixed,
    this.selected,
    this.toggled,
    this.button,
    this.slider,
    this.keyboardKey,
    this.link,
    this.linkUrl,
    this.header,
    this.headingLevel,
    this.textField,
    this.readOnly,
    this.focusable,
    this.focused,
    this.inMutuallyExclusiveGroup,
    this.obscured,
    this.multiline,
    this.scopesRoute,
    this.namesRoute,
    this.hidden,
    this.image,
    this.liveRegion,
    this.expanded,
    this.maxValueLength,
    this.currentValueLength,
    this.identifier,
    this.label,
    this.attributedLabel,
    this.value,
    this.increasedValue,
    this.decreasedValue,
    this.hint,
    this.tooltip,
    this.onTapHint,
    this.onLongPressHint,
    this.textDirection,
    this.sortKey,
    this.tagForChildren,
    this.onTap,
    this.onLongPress,
    this.onScrollLeft,
    this.onScrollRight,
    this.onScrollUp,
    this.onScrollDown,
    this.onIncrease,
    this.onDecrease,
    this.onCopy,
    this.onCut,
    this.onPaste,
    this.onDismiss,
    this.onMoveCursorForwardByCharacter,
    this.onMoveCursorBackwardByCharacter,
    this.onSetSelection,
    this.onSetText,
    this.onDidGainAccessibilityFocus,
    this.onDidLoseAccessibilityFocus,
    this.onFocus,
    this.customSemanticsActions,
    this.role,
    this.controlsNodes,
    this.validationResult,
    this.inputType,
    this.child,
  });
  final bool container, explicitChildNodes, excludeSemantics, blockUserActions;
  final bool? enabled, checked, mixed, selected, toggled, button, slider;
  final bool? keyboardKey, link, header, textField, readOnly, focusable;
  final bool? focused, inMutuallyExclusiveGroup, obscured, multiline;
  final bool? scopesRoute, namesRoute, hidden, image, liveRegion, expanded;
  final int? maxValueLength, currentValueLength, headingLevel;
  final Uri? linkUrl;
  final String? identifier, label, value, increasedValue, decreasedValue;
  final String? hint, tooltip, onTapHint, onLongPressHint;
  final Object? attributedLabel, sortKey, tagForChildren;
  final Object? customSemanticsActions, role, controlsNodes;
  final Object? validationResult, inputType;
  final TextDirection? textDirection;
  final VoidCallback? onTap, onLongPress, onScrollLeft, onScrollRight;
  final VoidCallback? onScrollUp, onScrollDown, onIncrease, onDecrease;
  final VoidCallback? onCopy, onCut, onPaste, onDismiss;
  final VoidCallback? onDidGainAccessibilityFocus, onDidLoseAccessibilityFocus;
  final VoidCallback? onFocus;
  final Object? onMoveCursorForwardByCharacter, onMoveCursorBackwardByCharacter;
  final Object? onSetSelection, onSetText;
  final Widget? child;

  @override
  _Fill get _fill => _Fill.child;

  @override
  void _render(_DomBuilder out) {
    final attributes = out.attributes;
    if (header == true) {
      attributes['role'] = 'heading';
      attributes['aria-level'] = '${headingLevel ?? 2}';
    } else if (button == true) {
      attributes['role'] = 'button';
    } else if (link == true) {
      attributes['role'] = 'link';
    } else if (image == true) {
      attributes['role'] = 'img';
    } else if (slider == true) {
      attributes['role'] = 'slider';
    } else if (textField == true) {
      attributes['role'] = 'textbox';
    } else if (toggled != null) {
      attributes['role'] = 'switch';
    } else if (checked != null) {
      attributes['role'] = inMutuallyExclusiveGroup == true
          ? 'radio'
          : 'checkbox';
    }
    final description = [?label, if (value != null && label == null) value!];
    if (description.isNotEmpty)
      attributes['aria-label'] = description.join(' ');
    if (value != null && slider == true) attributes['aria-valuetext'] = value!;
    if (hint != null || tooltip != null) {
      attributes['title'] = [?hint, ?tooltip].join(' ');
    }
    if (enabled == false) attributes['aria-disabled'] = 'true';
    if (selected != null) attributes['aria-selected'] = '$selected';
    if (checked != null) {
      attributes['aria-checked'] = mixed == true ? 'mixed' : '$checked';
    }
    if (toggled != null) attributes['aria-checked'] = '$toggled';
    if (expanded != null) attributes['aria-expanded'] = '$expanded';
    if (readOnly == true) attributes['aria-readonly'] = 'true';
    if (liveRegion == true) attributes['aria-live'] = 'polite';
    if (identifier != null)
      attributes['data-semantics-identifier'] = identifier!;
    if (excludeSemantics || hidden == true) attributes['aria-hidden'] = 'true';
    if (focusable == true || onTap != null) attributes['tabindex'] = '0';
    final tap = onTap;
    if (tap != null) {
      out.on('click', (_) => tap());
      out.on('keydown', (event) {
        final key = event?.key;
        if (key == 'Enter' || key == ' ') {
          event?.preventDefault();
          tap();
        }
      });
    }
    if (child != null) out.child(child!);
  }
}

class BlockSemantics extends StatelessWidget {
  const BlockSemantics({super.key, this.blocking = true, this.child});
  final bool blocking;
  final Widget? child;
  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class IndexedSemantics extends StatelessWidget {
  const IndexedSemantics({super.key, required this.index, this.child});
  final int index;
  final Widget? child;
  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class ExcludeSemantics extends _DomWidget {
  const ExcludeSemantics({super.key, this.excluding = true, this.child});
  final bool excluding;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    if (excluding) out.attributes['aria-hidden'] = 'true';
    if (child != null) out.child(child!);
  }
}

class MergeSemantics extends StatelessWidget {
  const MergeSemantics({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

// ---------------------------------------------------------------------------
// Images. The browser fetches and decodes; asset keys map to `assets/<key>`,
// which the native build copies from the pubspec asset list.

/// Flutter's decoded-image cache. Browsers cache network and asset images
/// themselves, so the counters stay at zero and clearing is a no-op.
class ImageCache {
  int maximumSize = 1000;
  int maximumSizeBytes = 100 << 20;
  int get currentSize => 0;
  int get currentSizeBytes => 0;
  int get liveImageCount => 0;
  int get pendingImageCount => 0;
  void clear() {}
  void clearLiveImages() {}
  bool evict(Object key, {bool includeLive = true}) => false;
  bool containsKey(Object key) => false;
}

class PaintingBinding {
  PaintingBinding._();
  static final instance = PaintingBinding._();
  final imageCache = ImageCache();
}

typedef ImageErrorWidgetBuilder =
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

typedef ImageLoadingBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      ImageChunkEvent? loadingProgress,
    );
typedef ImageFrameBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      int? frame,
      bool wasSynchronouslyLoaded,
    );

class Image extends StatefulWidget {
  const Image({
    super.key,
    required this.image,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.isAntiAlias = false,
    this.filterQuality = FilterQuality.medium,
  });
  Image.asset(
    String name, {
    super.key,
    AssetBundle? bundle,
    this.frameBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    double? scale,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.isAntiAlias = false,
    String? package,
    this.filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) : image = AssetImage(name, package: package),
       loadingBuilder = null;
  Image.network(
    String src, {
    super.key,
    double scale = 1.0,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    Map<String, String>? headers,
    int? cacheWidth,
    int? cacheHeight,
    Object? webHtmlElementStrategy,
  }) : image = NetworkImage(src, scale: scale, headers: headers);
  Image.memory(
    Uint8List bytes, {
    super.key,
    double scale = 1.0,
    this.frameBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.isAntiAlias = false,
    this.filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) : image = MemoryImage(bytes, scale: scale),
       loadingBuilder = null;
  final ImageProvider image;
  final ImageFrameBuilder? frameBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final double? width, height;
  final Color? color;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection, gaplessPlayback, isAntiAlias;
  final FilterQuality filterQuality;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final ImageErrorWidgetBuilder? errorBuilder;
  @override
  State<Image> createState() => _ImageState();
}

class _ImageState extends State<Image> {
  bool _failed = false, _loaded = false;
  @override
  void didUpdateWidget(Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.url != widget.image.url) {
      _failed = false;
      if (!widget.gaplessPlayback) _loaded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed && widget.errorBuilder != null) {
      return widget.errorBuilder!(
        context,
        StateError('Image failed to load.'),
        null,
      );
    }
    final observe =
        widget.loadingBuilder != null || widget.frameBuilder != null;
    Widget result = _Img(
      widget: widget,
      onError: widget.errorBuilder == null
          ? null
          : () {
              if (mounted) setState(() => _failed = true);
            },
      onLoad: !observe || _loaded
          ? null
          : () {
              if (mounted) setState(() => _loaded = true);
            },
    );
    if (widget.opacity != null) {
      result = FadeTransition(opacity: widget.opacity!, child: result);
    }
    if (widget.frameBuilder != null) {
      result = widget.frameBuilder!(context, result, _loaded ? 0 : null, false);
    }
    if (widget.loadingBuilder != null) {
      result = widget.loadingBuilder!(
        context,
        result,
        _loaded
            ? null
            : const ImageChunkEvent(
                cumulativeBytesLoaded: 0,
                expectedTotalBytes: null,
              ),
      );
    }
    return result;
  }
}

class _Img extends _DomWidget {
  const _Img({required this.widget, required this.onError, this.onLoad});
  final Image widget;
  final VoidCallback? onError, onLoad;
  @override
  String get _tag => 'img';
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    final image = widget;
    out.attributes['src'] = image.image.url;
    out.attributes['decoding'] = 'async';
    if (image.excludeFromSemantics || image.semanticLabel == null) {
      out.attributes['alt'] = '';
    } else {
      out.attributes['alt'] = image.semanticLabel!;
    }
    out.css('display:block;max-width:100%;flex-shrink:0;');
    out.css(_dimension('width', image.width));
    out.css(_dimension('height', image.height));
    out.css(objectFitCss(image.fit));
    if (image.filterQuality == FilterQuality.none) {
      out.css('image-rendering:pixelated;');
    }
    final a = image.alignment.resolve(TextDirection.ltr);
    if (a.x != 0 || a.y != 0)
      out.css(
        'object-position:${cssNumber((a.x + 1) * 50)}% ${cssNumber((a.y + 1) * 50)}%;',
      );
    if (onError != null) out.on('error', (_) => onError!());
    if (onLoad != null) {
      out.on('load', (_) => onLoad!());
      // Cached images may already be complete when the listener attaches.
      final element = out.context;
      scheduleMicrotask(() {
        final node = element.mounted ? element.node as JSObject : null;
        if (node != null &&
            node.getProperty<JSBoolean?>('complete'.toJS)?.toDart == true &&
            _jsNumber(node, 'naturalWidth') > 0) {
          onLoad!();
        }
      });
    }
  }
}

/// Shows [placeholder] until [image] loads, then fades the image in.
class FadeInImage extends StatefulWidget {
  const FadeInImage({
    super.key,
    required this.placeholder,
    this.placeholderErrorBuilder,
    required this.image,
    this.imageErrorBuilder,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.placeholderFit,
    this.filterQuality = FilterQuality.medium,
    this.placeholderFilterQuality,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.placeholderColor,
    this.placeholderColorBlendMode,
  });
  FadeInImage.memoryNetwork({
    super.key,
    required Uint8List placeholder,
    this.placeholderErrorBuilder,
    required String image,
    this.imageErrorBuilder,
    double placeholderScale = 1.0,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.placeholderFit,
    this.filterQuality = FilterQuality.medium,
    this.placeholderFilterQuality,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.placeholderColor,
    this.placeholderColorBlendMode,
    int? placeholderCacheWidth,
    int? placeholderCacheHeight,
    int? imageCacheWidth,
    int? imageCacheHeight,
  }) : placeholder = MemoryImage(placeholder, scale: placeholderScale),
       image = NetworkImage(image, scale: imageScale);
  FadeInImage.assetNetwork({
    super.key,
    required String placeholder,
    this.placeholderErrorBuilder,
    required String image,
    this.imageErrorBuilder,
    AssetBundle? bundle,
    double? placeholderScale,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.placeholderFit,
    this.filterQuality = FilterQuality.medium,
    this.placeholderFilterQuality,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.placeholderColor,
    this.placeholderColorBlendMode,
    int? placeholderCacheWidth,
    int? placeholderCacheHeight,
    int? imageCacheWidth,
    int? imageCacheHeight,
  }) : placeholder = AssetImage(placeholder),
       image = NetworkImage(image, scale: imageScale);
  final ImageProvider placeholder, image;
  final ImageErrorWidgetBuilder? placeholderErrorBuilder, imageErrorBuilder;
  final bool excludeFromSemantics, matchTextDirection;
  final String? imageSemanticLabel;
  final Duration fadeOutDuration, fadeInDuration;
  final Curve fadeOutCurve, fadeInCurve;
  final double? width, height;
  final BoxFit? fit, placeholderFit;
  final FilterQuality filterQuality;
  final FilterQuality? placeholderFilterQuality;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Color? placeholderColor;
  final BlendMode? placeholderColorBlendMode;
  @override
  State<FadeInImage> createState() => _FadeInImageState();
}

class _FadeInImageState extends State<FadeInImage> {
  bool _loaded = false;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      if (!_loaded)
        Image(
          image: widget.placeholder,
          width: widget.width,
          height: widget.height,
          fit: widget.placeholderFit ?? widget.fit,
          alignment: widget.alignment,
          excludeFromSemantics: true,
          errorBuilder: widget.placeholderErrorBuilder,
        ),
      _Box(
        css:
            'transition:opacity ${widget.fadeInDuration.inMilliseconds}ms ease-in;opacity:${_loaded ? 1 : 0};${_loaded ? '' : 'position:absolute;inset:0;'}',
        fill: _Fill.none,
        children: [
          Image(
            image: widget.image,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            semanticLabel: widget.imageSemanticLabel,
            excludeFromSemantics: widget.excludeFromSemantics,
            errorBuilder: widget.imageErrorBuilder,
            frameBuilder: (context, child, frame, sync) {
              if (frame != null && !_loaded) {
                scheduleMicrotask(() {
                  if (mounted) setState(() => _loaded = true);
                });
              }
              return child;
            },
          ),
        ],
      ),
    ],
  );
}

/// Starts loading [provider] in the browser; completes when it has loaded or
/// failed (failures go to [onError] when given).
Future<void> precacheImage(
  ImageProvider provider,
  BuildContext context, {
  Size? size,
  void Function(Object exception, StackTrace? stackTrace)? onError,
}) {
  final completer = Completer<void>();
  final window = _window as JSObject;
  if (!window.has('Image')) return Future.value();
  final image = window
      .getProperty<JSFunction>('Image'.toJS)
      .callAsConstructor<JSObject>();
  image.setProperty('onload'.toJS, ((JSAny? _) => completer.complete()).toJS);
  image.setProperty(
    'onerror'.toJS,
    ((JSAny? _) {
      onError?.call(StateError('Image failed to load.'), null);
      completer.complete();
    }).toJS,
  );
  image.setProperty('src'.toJS, provider.url.toJS);
  return completer.future;
}

// ---------------------------------------------------------------------------
// Tables, laid out with CSS grid.

abstract class TableColumnWidth {
  const TableColumnWidth();
  String get _css;
}

class FixedColumnWidth extends TableColumnWidth {
  const FixedColumnWidth(this.value);
  final double value;
  @override
  String get _css => px(value);
}

class FlexColumnWidth extends TableColumnWidth {
  const FlexColumnWidth([this.value = 1]);
  final double value;
  @override
  String get _css => 'minmax(0,${cssNumber(value)}fr)';
}

class FractionColumnWidth extends TableColumnWidth {
  const FractionColumnWidth(this.value);
  final double value;
  @override
  String get _css => '${cssNumber(value * 100)}%';
}

class IntrinsicColumnWidth extends TableColumnWidth {
  const IntrinsicColumnWidth({this.flex});
  final double? flex;
  @override
  String get _css => flex == null
      ? 'max-content'
      : 'minmax(max-content,${cssNumber(flex!)}fr)';
}

class MaxColumnWidth extends TableColumnWidth {
  const MaxColumnWidth(this.a, this.b);
  final TableColumnWidth a, b;
  @override
  String get _css => 'max(${a._css},${b._css})';
}

class MinColumnWidth extends TableColumnWidth {
  const MinColumnWidth(this.a, this.b);
  final TableColumnWidth a, b;
  @override
  String get _css => 'min(${a._css},${b._css})';
}

enum TableCellVerticalAlignment {
  top,
  middle,
  bottom,
  baseline,
  fill,
  intrinsicHeight,
}

class TableBorder {
  const TableBorder({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
    this.horizontalInside = BorderSide.none,
    this.verticalInside = BorderSide.none,
    this.borderRadius = BorderRadius.zero,
  });
  factory TableBorder.all({
    Color color = const Color(0xff000000),
    double width = 1,
    BorderStyle style = BorderStyle.solid,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    final side = BorderSide(color: color, width: width, style: style);
    return TableBorder(
      top: side,
      right: side,
      bottom: side,
      left: side,
      horizontalInside: side,
      verticalInside: side,
      borderRadius: borderRadius,
    );
  }
  factory TableBorder.symmetric({
    BorderSide inside = BorderSide.none,
    BorderSide outside = BorderSide.none,
  }) => TableBorder(
    top: outside,
    right: outside,
    bottom: outside,
    left: outside,
    horizontalInside: inside,
    verticalInside: inside,
  );
  final BorderSide top, right, bottom, left;
  final BorderSide horizontalInside, verticalInside;
  final BorderRadius borderRadius;
}

class TableRow {
  const TableRow({this.key, this.decoration, this.children = const []});
  final LocalKey? key;
  final Decoration? decoration;
  final List<Widget> children;
}

class TableCell extends StatelessWidget {
  const TableCell({super.key, this.verticalAlignment, required this.child});
  final TableCellVerticalAlignment? verticalAlignment;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class Table extends _DomWidget {
  const Table({
    super.key,
    this.children = const [],
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(),
    this.textDirection,
    this.border,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.textBaseline,
  });
  final List<TableRow> children;
  final Map<int, TableColumnWidth>? columnWidths;
  final TableColumnWidth defaultColumnWidth;
  final TextDirection? textDirection;
  final TableBorder? border;
  final TableCellVerticalAlignment defaultVerticalAlignment;
  final TextBaseline? textBaseline;
  @override
  String get _tag => 'div';
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) {
    final columns = children.isEmpty ? 0 : children.first.children.length;
    for (final row in children) {
      if (row.children.length != columns)
        throw ArgumentError(
          'Every TableRow must have the same number of cells.',
        );
    }
    final template = [
      for (var i = 0; i < columns; i++)
        (columnWidths?[i] ?? defaultColumnWidth)._css,
    ].join(' ');
    final b = border;
    out.attributes['role'] = 'table';
    out.css(
      'display:grid;grid-template-columns:$template;box-sizing:border-box;min-width:0;overflow:hidden;',
    );
    if (b != null) {
      out.css(
        borderSideCss('border-top', b.top) +
            borderSideCss('border-right', b.right) +
            borderSideCss('border-bottom', b.bottom) +
            borderSideCss('border-left', b.left) +
            borderRadiusCss(b.borderRadius),
      );
    }
    final cells = <Widget>[];
    for (var r = 0; r < children.length; r++) {
      final row = children[r];
      for (var c = 0; c < row.children.length; c++) {
        final cell = row.children[c];
        final alignment = cell is TableCell && cell.verticalAlignment != null
            ? cell.verticalAlignment!
            : defaultVerticalAlignment;
        cells.add(
          _TableCellBox(
            key: ValueKey('${row.key ?? r}/$c'),
            alignment: alignment,
            decoration: row.decoration,
            borderTop: r > 0 ? b?.horizontalInside : null,
            borderLeft: c > 0 ? b?.verticalInside : null,
            child: cell,
          ),
        );
      }
    }
    out.children = cells;
  }
}

class _TableCellBox extends _DomWidget {
  const _TableCellBox({
    super.key,
    required this.alignment,
    required this.decoration,
    required this.borderTop,
    required this.borderLeft,
    required this.child,
  });
  final TableCellVerticalAlignment alignment;
  final Decoration? decoration;
  final BorderSide? borderTop, borderLeft;
  final Widget child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    out.attributes['role'] = 'cell';
    out.css(
      'display:grid;grid-template-columns:minmax(0,1fr);box-sizing:border-box;min-width:0;align-content:${switch (alignment) {
        TableCellVerticalAlignment.middle => 'center',
        TableCellVerticalAlignment.bottom => 'end',
        TableCellVerticalAlignment.fill => 'stretch',
        _ => 'start',
      }};',
    );
    out.css(decorationCss(decoration));
    if (borderTop != null) out.css(borderSideCss('border-top', borderTop!));
    if (borderLeft != null) out.css(borderSideCss('border-left', borderLeft!));
    out.child(child);
  }
}

enum ScrollViewKeyboardDismissBehavior { manual, onDrag }

/// Lets the child size itself; the browser does so by default.
class UnconstrainedBox extends _DomWidget {
  const UnconstrainedBox({
    super.key,
    this.child,
    this.textDirection,
    this.alignment = Alignment.center,
    this.constrainedAxis,
    this.clipBehavior = Clip.none,
  });
  final Widget? child;
  final TextDirection? textDirection;
  final AlignmentGeometry alignment;
  final Axis? constrainedAxis;
  final Clip clipBehavior;
  @override
  _DomLayout get _layout => _DomLayout.align;
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) {
    out.css(_alignCss(alignment));
    if (clipBehavior != Clip.none) out.css('overflow:hidden;');
    if (child != null) {
      out.child(
        constrainedAxis == Axis.horizontal
            ? child!
            : _Box(
                css: 'width:max-content;',
                fill: _Fill.none,
                children: [child!],
              ),
      );
    }
  }
}

/// A shape with elevation shadow and clipping.
class PhysicalModel extends StatelessWidget {
  const PhysicalModel({
    super.key,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    this.elevation = 0,
    required this.color,
    this.shadowColor = const Color(0xFF000000),
    this.child,
  });
  final BoxShape shape;
  final Clip clipBehavior;
  final BorderRadius? borderRadius;
  final double elevation;
  final Color color, shadowColor;
  final Widget? child;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'box-sizing:border-box;background-color:${colorCss(color)};${shape == BoxShape.circle ? 'border-radius:50%;' : borderRadiusCss(borderRadius)}${elevationCss(elevation, shadowColor)}${clipBehavior == Clip.none ? '' : 'overflow:hidden;'}display:grid;grid-template-columns:minmax(0,1fr);',
    layout: _DomLayout.grid,
    fill: _Fill.child,
    children: [?child],
  );
}

class PhysicalShape extends StatelessWidget {
  const PhysicalShape({
    super.key,
    required this.clipper,
    this.clipBehavior = Clip.none,
    this.elevation = 0,
    required this.color,
    this.shadowColor = const Color(0xFF000000),
    this.child,
  });
  final CustomClipper<Path> clipper;
  final Clip clipBehavior;
  final double elevation;
  final Color color, shadowColor;
  final Widget? child;
  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: clipper,
    clipBehavior: clipBehavior == Clip.none ? Clip.antiAlias : clipBehavior,
    child: ColoredBox(color: color, child: child),
  );
}
