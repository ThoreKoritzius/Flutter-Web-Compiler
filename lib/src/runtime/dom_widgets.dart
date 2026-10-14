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

class TextSpan extends InlineSpan {
  const TextSpan({this.text, this.children, super.style, this.semanticsLabel});
  final String? text;
  final List<InlineSpan>? children;
  final String? semanticsLabel;
  @override
  String toPlainText() =>
      '${text ?? ''}${children?.map((c) => c.toPlainText()).join() ?? ''}';
}

class WidgetSpan extends InlineSpan {
  const WidgetSpan({required this.child, super.style});
  final Widget child;
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
      out.css('display:inline-block;vertical-align:middle;');
      out.child(span.child);
      return;
    }
    if (span is! TextSpan) throw UnsupportedError('Unsupported inline span.');
    if (span.semanticsLabel != null)
      out.attributes['aria-label'] = span.semanticsLabel!;
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
  });
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
    super.style,
    super.textAlign,
    super.maxLines,
  });
}

class SelectionArea extends StatelessWidget {
  const SelectionArea({super.key, required this.child});
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
    this.color,
    this.semanticLabel,
    this.textDirection,
  });
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
      'display:flex;flex-direction:${_horizontal ? 'row' : 'column'}${reversed ? '-reverse' : ''};box-sizing:border-box;min-width:0;',
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
      'box-sizing:border-box;min-width:0;padding:${px(p.top)} ${px(p.right)} ${px(p.bottom)} ${px(p.left)};',
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
    if (alignment != null) {
      out.css(_alignCss(alignment!));
    } else if (child != null) {
      // A one-cell grid passes tight constraints to the child.
      out.css('display:grid;grid-template-columns:minmax(0,1fr);');
    }
    if (foregroundDecoration != null)
      throw UnsupportedError('Container foregroundDecoration is unsupported.');
    if (child != null) out.child(child!);
  }
}

class Opacity extends _DomWidget {
  const Opacity({super.key, required this.opacity, this.child});
  final double opacity;
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
    required this.child,
  });
  final bool left, top, right, bottom;
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
    super.key,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.children = const [],
  });
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
    out.css(
      'position:relative;display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
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

class ScrollController extends ChangeNotifier {
  ScrollController({this.initialScrollOffset = 0});
  final double initialScrollOffset;
}

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
  });
  final Axis axis;
  final EdgeInsetsGeometry? padding;
  final bool scrolls;
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
    if (scrolls)
      out.css(
        vertical ? 'overflow-y:auto;' : 'overflow-x:auto;overflow-y:hidden;',
      );
    out.css(edgeInsetsCss('padding', padding));
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
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    this.controller,
    this.child,
  });
  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsetsGeometry? padding;
  final bool? primary;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Widget? child;
  @override
  Widget build(BuildContext context) => _ScrollList(
    axis: scrollDirection,
    padding: padding,
    scrolls: physics is! NeverScrollableScrollPhysics,
    children: [?child],
  );
}

class ListView extends StatelessWidget {
  ListView({
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
    if (reverse) items = items.reversed.toList();
    return _ScrollList(
      axis: scrollDirection,
      padding: padding,
      scrolls: physics is! NeverScrollableScrollPhysics,
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
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.behavior,
    this.child,
  });
  final VoidCallback? onTap, onDoubleTap, onLongPress, onSecondaryTap;
  final HitTestBehavior? behavior;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    if (onTap != null) out.on('click', (_) => onTap!());
    if (onDoubleTap != null) out.on('dblclick', (_) => onDoubleTap!());
    if (onSecondaryTap != null) {
      out.on('contextmenu', (event) {
        event?.preventDefault();
        onSecondaryTap!();
      });
    }
    if (onLongPress != null)
      throw UnsupportedError('Long-press gestures are unsupported.');
    if (child != null) out.child(child!);
  }
}

class MouseRegion extends _DomWidget {
  const MouseRegion({
    super.key,
    this.cursor = SystemMouseCursors.basic,
    this.onEnter,
    this.onExit,
    this.child,
  });
  final MouseCursor cursor;
  final void Function(Object event)? onEnter, onExit;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    if (cursor != SystemMouseCursors.basic) out.css('cursor:${cursor._css};');
    if (onEnter != null) out.on('mouseenter', (e) => onEnter!(e ?? Object()));
    if (onExit != null) out.on('mouseleave', (e) => onExit!(e ?? Object()));
    if (child != null) out.child(child!);
  }
}

class Semantics extends _DomWidget {
  const Semantics({
    super.key,
    this.label,
    this.header,
    this.button,
    this.container = false,
    this.excludeSemantics = false,
    this.child,
  });
  final String? label;
  final bool? header, button;
  final bool container, excludeSemantics;
  final Widget? child;
  @override
  void _render(_DomBuilder out) {
    if (header == true) {
      out.attributes['role'] = 'heading';
      out.attributes['aria-level'] = '2';
    } else if (button == true) {
      out.attributes['role'] = 'button';
    }
    if (label != null) out.attributes['aria-label'] = label!;
    if (excludeSemantics) out.attributes['aria-hidden'] = 'true';
    if (child != null) out.child(child!);
  }
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

typedef ImageErrorWidgetBuilder =
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

class Image extends StatefulWidget {
  const Image({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.errorBuilder,
  });
  Image.asset(
    String name, {
    super.key,
    String? package,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.errorBuilder,
  }) : image = AssetImage(name, package: package);
  Image.network(
    String src, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.errorBuilder,
    Map<String, String>? headers,
  }) : image = NetworkImage(src, headers: headers);
  final ImageProvider image;
  final double? width, height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final ImageErrorWidgetBuilder? errorBuilder;
  @override
  State<Image> createState() => _ImageState();
}

class _ImageState extends State<Image> {
  bool _failed = false;
  @override
  void didUpdateWidget(Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.url != widget.image.url) _failed = false;
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
    return _Img(
      widget: widget,
      onError: widget.errorBuilder == null
          ? null
          : () {
              if (mounted) setState(() => _failed = true);
            },
    );
  }
}

class _Img extends _DomWidget {
  const _Img({required this.widget, required this.onError});
  final Image widget;
  final VoidCallback? onError;
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
    final a = image.alignment.resolve(TextDirection.ltr);
    if (a.x != 0 || a.y != 0)
      out.css(
        'object-position:${cssNumber((a.x + 1) * 50)}% ${cssNumber((a.y + 1) * 50)}%;',
      );
    if (onError != null) out.on('error', (_) => onError!());
  }
}
