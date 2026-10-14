/// An independent implementation of the flutter_markdown /
/// flutter_markdown_plus widget API for the native runtime, rendering the
/// official `markdown` package's AST with runtime widgets. Custom element
/// builders are not supported.
library;

import 'package:markdown/markdown.dart' as md;

import 'flutter_dom.dart';

typedef MarkdownTapLinkCallback =
    void Function(String text, String? href, String title);
typedef MarkdownImageBuilder =
    Widget Function(Uri uri, String? title, String? alt);
typedef MarkdownCheckboxBuilder = Widget Function(bool value);
typedef MarkdownBulletBuilder =
    Widget Function(MarkdownBulletParameters parameters);

enum MarkdownStyleSheetBaseTheme { material, cupertino, platform }

enum MarkdownListItemCrossAxisAlignment { baseline, start }

enum BulletStyle { orderedList, unorderedList }

class MarkdownBulletParameters {
  const MarkdownBulletParameters({
    required this.index,
    required this.style,
    required this.nestLevel,
  });
  final int index, nestLevel;
  final BulletStyle style;
}

/// Formats code blocks; returned spans replace the plain code text.
abstract class SyntaxHighlighter {
  TextSpan format(String source);
}

abstract class MarkdownElementBuilder {}

abstract class MarkdownPaddingBuilder {}

class MarkdownStyleSheet {
  MarkdownStyleSheet({
    this.a,
    this.p,
    this.pPadding,
    this.code,
    this.h1,
    this.h1Padding,
    this.h2,
    this.h2Padding,
    this.h3,
    this.h3Padding,
    this.h4,
    this.h4Padding,
    this.h5,
    this.h5Padding,
    this.h6,
    this.h6Padding,
    this.em,
    this.strong,
    this.del,
    this.blockquote,
    this.img,
    this.checkbox,
    this.blockSpacing,
    this.listIndent,
    this.listBullet,
    this.listBulletPadding,
    this.tableHead,
    this.tableBody,
    this.tableHeadAlign,
    this.tableBorder,
    this.tableColumnWidth,
    this.tableCellsPadding,
    this.tableCellsDecoration,
    this.blockquotePadding,
    this.blockquoteDecoration,
    this.codeblockPadding,
    this.codeblockDecoration,
    this.horizontalRuleDecoration,
    this.textAlign = WrapAlignment.start,
    this.h1Align = WrapAlignment.start,
    this.h2Align = WrapAlignment.start,
    this.h3Align = WrapAlignment.start,
    this.h4Align = WrapAlignment.start,
    this.h5Align = WrapAlignment.start,
    this.h6Align = WrapAlignment.start,
    this.unorderedListAlign = WrapAlignment.start,
    this.orderedListAlign = WrapAlignment.start,
    this.blockquoteAlign = WrapAlignment.start,
    this.codeblockAlign = WrapAlignment.start,
    this.textScaler,
  });

  /// Defaults derived from [theme], following flutter_markdown.
  factory MarkdownStyleSheet.fromTheme(ThemeData theme) {
    final text = theme.textTheme;
    final body = text.bodyMedium!;
    return MarkdownStyleSheet(
      a: const TextStyle(color: Color(0xff2196f3)),
      p: body,
      pPadding: EdgeInsets.zero,
      code: body.copyWith(
        backgroundColor: theme.cardColor,
        fontFamily: 'monospace',
        fontSize: (body.fontSize ?? 14) * 0.85,
      ),
      h1: text.headlineSmall,
      h1Padding: EdgeInsets.zero,
      h2: text.titleLarge,
      h2Padding: EdgeInsets.zero,
      h3: text.titleMedium,
      h3Padding: EdgeInsets.zero,
      h4: text.bodyLarge,
      h4Padding: EdgeInsets.zero,
      h5: text.bodyLarge,
      h5Padding: EdgeInsets.zero,
      h6: text.bodyLarge,
      h6Padding: EdgeInsets.zero,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      blockquote: body,
      img: body,
      checkbox: body.copyWith(color: theme.colorScheme.primary),
      blockSpacing: 8,
      listIndent: 24,
      listBullet: body,
      listBulletPadding: const EdgeInsets.only(right: 4),
      tableHead: const TextStyle(fontWeight: FontWeight.w600),
      tableBody: body,
      tableHeadAlign: TextAlign.center,
      tableBorder: TableBorder.all(color: theme.dividerColor),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      tableCellsDecoration: const BoxDecoration(),
      blockquotePadding: const EdgeInsets.all(8),
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xffbbdefb),
        borderRadius: BorderRadius.circular(2),
      ),
      codeblockPadding: const EdgeInsets.all(8),
      codeblockDecoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(2),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(width: 5, color: theme.dividerColor)),
      ),
    );
  }

  factory MarkdownStyleSheet.largeFromTheme(ThemeData theme) {
    final text = theme.textTheme;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: text.displayLarge,
      h2: text.displayMedium,
      h3: text.displaySmall,
      h4: text.headlineMedium,
      h5: text.headlineSmall,
      h6: text.titleLarge,
    );
  }

  final TextStyle? a, p, code, h1, h2, h3, h4, h5, h6, em, strong, del;
  final TextStyle? blockquote, img, checkbox, listBullet, tableHead, tableBody;
  final EdgeInsets? pPadding, h1Padding, h2Padding, h3Padding;
  final EdgeInsets? h4Padding, h5Padding, h6Padding, listBulletPadding;
  final EdgeInsets? tableCellsPadding, blockquotePadding, codeblockPadding;
  final double? blockSpacing, listIndent;
  final TextAlign? tableHeadAlign;
  final TableBorder? tableBorder;
  final TableColumnWidth? tableColumnWidth;
  final Decoration? tableCellsDecoration, blockquoteDecoration;
  final Decoration? codeblockDecoration, horizontalRuleDecoration;
  final WrapAlignment textAlign, h1Align, h2Align, h3Align, h4Align;
  final WrapAlignment h5Align, h6Align, unorderedListAlign;
  final WrapAlignment orderedListAlign, blockquoteAlign, codeblockAlign;
  final TextScaler? textScaler;

  MarkdownStyleSheet copyWith({
    TextStyle? a,
    TextStyle? p,
    EdgeInsets? pPadding,
    TextStyle? code,
    TextStyle? h1,
    EdgeInsets? h1Padding,
    TextStyle? h2,
    EdgeInsets? h2Padding,
    TextStyle? h3,
    EdgeInsets? h3Padding,
    TextStyle? h4,
    EdgeInsets? h4Padding,
    TextStyle? h5,
    EdgeInsets? h5Padding,
    TextStyle? h6,
    EdgeInsets? h6Padding,
    TextStyle? em,
    TextStyle? strong,
    TextStyle? del,
    TextStyle? blockquote,
    TextStyle? img,
    TextStyle? checkbox,
    double? blockSpacing,
    double? listIndent,
    TextStyle? listBullet,
    EdgeInsets? listBulletPadding,
    TextStyle? tableHead,
    TextStyle? tableBody,
    TextAlign? tableHeadAlign,
    TableBorder? tableBorder,
    TableColumnWidth? tableColumnWidth,
    EdgeInsets? tableCellsPadding,
    Decoration? tableCellsDecoration,
    EdgeInsets? blockquotePadding,
    Decoration? blockquoteDecoration,
    EdgeInsets? codeblockPadding,
    Decoration? codeblockDecoration,
    Decoration? horizontalRuleDecoration,
    WrapAlignment? textAlign,
    WrapAlignment? h1Align,
    WrapAlignment? h2Align,
    WrapAlignment? h3Align,
    WrapAlignment? h4Align,
    WrapAlignment? h5Align,
    WrapAlignment? h6Align,
    WrapAlignment? unorderedListAlign,
    WrapAlignment? orderedListAlign,
    WrapAlignment? blockquoteAlign,
    WrapAlignment? codeblockAlign,
    TextScaler? textScaler,
  }) => MarkdownStyleSheet(
    a: a ?? this.a,
    p: p ?? this.p,
    pPadding: pPadding ?? this.pPadding,
    code: code ?? this.code,
    h1: h1 ?? this.h1,
    h1Padding: h1Padding ?? this.h1Padding,
    h2: h2 ?? this.h2,
    h2Padding: h2Padding ?? this.h2Padding,
    h3: h3 ?? this.h3,
    h3Padding: h3Padding ?? this.h3Padding,
    h4: h4 ?? this.h4,
    h4Padding: h4Padding ?? this.h4Padding,
    h5: h5 ?? this.h5,
    h5Padding: h5Padding ?? this.h5Padding,
    h6: h6 ?? this.h6,
    h6Padding: h6Padding ?? this.h6Padding,
    em: em ?? this.em,
    strong: strong ?? this.strong,
    del: del ?? this.del,
    blockquote: blockquote ?? this.blockquote,
    img: img ?? this.img,
    checkbox: checkbox ?? this.checkbox,
    blockSpacing: blockSpacing ?? this.blockSpacing,
    listIndent: listIndent ?? this.listIndent,
    listBullet: listBullet ?? this.listBullet,
    listBulletPadding: listBulletPadding ?? this.listBulletPadding,
    tableHead: tableHead ?? this.tableHead,
    tableBody: tableBody ?? this.tableBody,
    tableHeadAlign: tableHeadAlign ?? this.tableHeadAlign,
    tableBorder: tableBorder ?? this.tableBorder,
    tableColumnWidth: tableColumnWidth ?? this.tableColumnWidth,
    tableCellsPadding: tableCellsPadding ?? this.tableCellsPadding,
    tableCellsDecoration: tableCellsDecoration ?? this.tableCellsDecoration,
    blockquotePadding: blockquotePadding ?? this.blockquotePadding,
    blockquoteDecoration: blockquoteDecoration ?? this.blockquoteDecoration,
    codeblockPadding: codeblockPadding ?? this.codeblockPadding,
    codeblockDecoration: codeblockDecoration ?? this.codeblockDecoration,
    horizontalRuleDecoration:
        horizontalRuleDecoration ?? this.horizontalRuleDecoration,
    textAlign: textAlign ?? this.textAlign,
    h1Align: h1Align ?? this.h1Align,
    h2Align: h2Align ?? this.h2Align,
    h3Align: h3Align ?? this.h3Align,
    h4Align: h4Align ?? this.h4Align,
    h5Align: h5Align ?? this.h5Align,
    h6Align: h6Align ?? this.h6Align,
    unorderedListAlign: unorderedListAlign ?? this.unorderedListAlign,
    orderedListAlign: orderedListAlign ?? this.orderedListAlign,
    blockquoteAlign: blockquoteAlign ?? this.blockquoteAlign,
    codeblockAlign: codeblockAlign ?? this.codeblockAlign,
    textScaler: textScaler ?? this.textScaler,
  );

  /// Fields of [other] that are set take precedence; text styles merge.
  MarkdownStyleSheet merge(MarkdownStyleSheet? other) {
    if (other == null) return this;
    TextStyle? m(TextStyle? a, TextStyle? b) => a == null ? b : a.merge(b);
    return copyWith(
      a: m(a, other.a),
      p: m(p, other.p),
      pPadding: other.pPadding,
      code: m(code, other.code),
      h1: m(h1, other.h1),
      h1Padding: other.h1Padding,
      h2: m(h2, other.h2),
      h2Padding: other.h2Padding,
      h3: m(h3, other.h3),
      h3Padding: other.h3Padding,
      h4: m(h4, other.h4),
      h4Padding: other.h4Padding,
      h5: m(h5, other.h5),
      h5Padding: other.h5Padding,
      h6: m(h6, other.h6),
      h6Padding: other.h6Padding,
      em: m(em, other.em),
      strong: m(strong, other.strong),
      del: m(del, other.del),
      blockquote: m(blockquote, other.blockquote),
      img: m(img, other.img),
      checkbox: m(checkbox, other.checkbox),
      blockSpacing: other.blockSpacing,
      listIndent: other.listIndent,
      listBullet: m(listBullet, other.listBullet),
      listBulletPadding: other.listBulletPadding,
      tableHead: m(tableHead, other.tableHead),
      tableBody: m(tableBody, other.tableBody),
      tableHeadAlign: other.tableHeadAlign,
      tableBorder: other.tableBorder,
      tableColumnWidth: other.tableColumnWidth,
      tableCellsPadding: other.tableCellsPadding,
      tableCellsDecoration: other.tableCellsDecoration,
      blockquotePadding: other.blockquotePadding,
      blockquoteDecoration: other.blockquoteDecoration,
      codeblockPadding: other.codeblockPadding,
      codeblockDecoration: other.codeblockDecoration,
      horizontalRuleDecoration: other.horizontalRuleDecoration,
      textAlign: other.textAlign,
      h1Align: other.h1Align,
      h2Align: other.h2Align,
      h3Align: other.h3Align,
      h4Align: other.h4Align,
      h5Align: other.h5Align,
      h6Align: other.h6Align,
      unorderedListAlign: other.unorderedListAlign,
      orderedListAlign: other.orderedListAlign,
      blockquoteAlign: other.blockquoteAlign,
      codeblockAlign: other.codeblockAlign,
      textScaler: other.textScaler,
    );
  }
}

TextAlign _textAlign(WrapAlignment alignment) => switch (alignment) {
  WrapAlignment.center => TextAlign.center,
  WrapAlignment.end => TextAlign.end,
  WrapAlignment.spaceBetween ||
  WrapAlignment.spaceAround ||
  WrapAlignment.spaceEvenly => TextAlign.justify,
  WrapAlignment.start => TextAlign.start,
};

abstract class MarkdownWidget extends StatelessWidget {
  const MarkdownWidget({
    super.key,
    required this.data,
    this.selectable = false,
    this.styleSheet,
    this.styleSheetTheme = MarkdownStyleSheetBaseTheme.material,
    this.syntaxHighlighter,
    this.onSelectionChanged,
    this.onTapLink,
    this.onTapText,
    this.contextMenuBuilder,
    this.imageDirectory,
    this.blockSyntaxes,
    this.inlineSyntaxes,
    this.extensionSet,
    this.imageBuilder,
    this.checkboxBuilder,
    this.bulletBuilder,
    this.builders = const <String, MarkdownElementBuilder>{},
    this.paddingBuilders = const <String, MarkdownPaddingBuilder>{},
    this.fitContent = false,
    this.listItemCrossAxisAlignment =
        MarkdownListItemCrossAxisAlignment.baseline,
    this.softLineBreak = false,
  });
  final String data;
  final bool selectable, fitContent, softLineBreak;
  final MarkdownStyleSheet? styleSheet;
  final MarkdownStyleSheetBaseTheme? styleSheetTheme;
  final SyntaxHighlighter? syntaxHighlighter;
  final Object? onSelectionChanged, contextMenuBuilder;
  final MarkdownTapLinkCallback? onTapLink;
  final VoidCallback? onTapText;
  final String? imageDirectory;
  final List<md.BlockSyntax>? blockSyntaxes;
  final List<md.InlineSyntax>? inlineSyntaxes;
  final md.ExtensionSet? extensionSet;
  final MarkdownImageBuilder? imageBuilder;
  final MarkdownCheckboxBuilder? checkboxBuilder;
  final MarkdownBulletBuilder? bulletBuilder;
  final Map<String, MarkdownElementBuilder> builders;
  final Map<String, MarkdownPaddingBuilder> paddingBuilders;
  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;

  Widget buildFromChildren(BuildContext context, List<Widget> children);

  @override
  Widget build(BuildContext context) {
    if (builders.isNotEmpty || paddingBuilders.isNotEmpty)
      throw UnsupportedError(
        'Custom markdown element builders are unsupported.',
      );
    final sheet = MarkdownStyleSheet.fromTheme(
      Theme.of(context),
    ).merge(styleSheet);
    final document = md.Document(
      extensionSet: extensionSet ?? md.ExtensionSet.gitHubFlavored,
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      encodeHtml: false,
    );
    final nodes = document.parseLines(
      data.replaceAll('\r\n', '\n').split('\n'),
    );
    final renderer = _Renderer(this, sheet);
    return buildFromChildren(context, renderer.blocks(nodes, 0));
  }
}

class MarkdownBody extends MarkdownWidget {
  const MarkdownBody({
    super.key,
    required super.data,
    super.selectable,
    super.styleSheet,
    super.styleSheetTheme = null,
    super.syntaxHighlighter,
    super.onSelectionChanged,
    super.onTapLink,
    super.onTapText,
    super.contextMenuBuilder,
    super.imageDirectory,
    super.blockSyntaxes,
    super.inlineSyntaxes,
    super.extensionSet,
    super.imageBuilder,
    super.checkboxBuilder,
    super.bulletBuilder,
    super.builders,
    super.paddingBuilders,
    super.listItemCrossAxisAlignment,
    this.shrinkWrap = true,
    super.fitContent = true,
    super.softLineBreak,
  });
  final bool shrinkWrap;
  @override
  Widget buildFromChildren(BuildContext context, List<Widget> children) =>
      Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: fitContent
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: children,
      );
}

class Markdown extends MarkdownWidget {
  const Markdown({
    super.key,
    required super.data,
    super.selectable,
    super.styleSheet,
    super.styleSheetTheme = null,
    super.syntaxHighlighter,
    super.onSelectionChanged,
    super.onTapLink,
    super.onTapText,
    super.contextMenuBuilder,
    super.imageDirectory,
    super.blockSyntaxes,
    super.inlineSyntaxes,
    super.extensionSet,
    super.imageBuilder,
    super.checkboxBuilder,
    super.bulletBuilder,
    super.builders,
    super.paddingBuilders,
    super.listItemCrossAxisAlignment,
    this.padding = const EdgeInsets.all(16.0),
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.noScroll = false,
    super.softLineBreak,
  });
  final EdgeInsets padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap, noScroll;
  @override
  Widget buildFromChildren(BuildContext context, List<Widget> children) {
    if (noScroll) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }
    return ListView(
      padding: padding,
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}

/// Converts the markdown AST to widgets.
class _Renderer {
  _Renderer(this.widget, this.sheet);
  final MarkdownWidget widget;
  final MarkdownStyleSheet sheet;

  List<Widget> blocks(List<md.Node> nodes, int listDepth) {
    final out = <Widget>[];
    for (final node in nodes) {
      final block = _block(node, listDepth);
      if (block == null) continue;
      if (out.isNotEmpty) out.add(SizedBox(height: sheet.blockSpacing ?? 8));
      out.add(block);
    }
    return out;
  }

  Widget? _block(md.Node node, int listDepth) {
    if (node is md.Text) {
      if (node.text.trim().isEmpty) return null;
      return _paragraph([node], sheet.p, sheet.textAlign, sheet.pPadding);
    }
    if (node is! md.Element) return null;
    final children = node.children ?? const <md.Node>[];
    switch (node.tag) {
      case 'p':
        return _paragraph(children, sheet.p, sheet.textAlign, sheet.pPadding);
      case 'h1':
        return _heading(node, sheet.h1, sheet.h1Align, sheet.h1Padding, 1);
      case 'h2':
        return _heading(node, sheet.h2, sheet.h2Align, sheet.h2Padding, 2);
      case 'h3':
        return _heading(node, sheet.h3, sheet.h3Align, sheet.h3Padding, 3);
      case 'h4':
        return _heading(node, sheet.h4, sheet.h4Align, sheet.h4Padding, 4);
      case 'h5':
        return _heading(node, sheet.h5, sheet.h5Align, sheet.h5Padding, 5);
      case 'h6':
        return _heading(node, sheet.h6, sheet.h6Align, sheet.h6Padding, 6);
      case 'hr':
        return Container(height: 0, decoration: sheet.horizontalRuleDecoration);
      case 'blockquote':
        return Container(
          padding: sheet.blockquotePadding,
          decoration: sheet.blockquoteDecoration,
          child: DefaultTextStyle.merge(
            style: sheet.blockquote,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: blocks(children, listDepth),
            ),
          ),
        );
      case 'pre':
        final code = children.isNotEmpty && children.first is md.Element
            ? (children.first as md.Element).textContent
            : node.textContent;
        final trimmed = code.endsWith('\n')
            ? code.substring(0, code.length - 1)
            : code;
        final highlighted = widget.syntaxHighlighter?.format(trimmed);
        return Container(
          padding: sheet.codeblockPadding,
          decoration: sheet.codeblockDecoration,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text.rich(
              highlighted ?? TextSpan(text: trimmed),
              style: sheet.code?.copyWith(
                backgroundColor: const Color(0x00000000),
              ),
              softWrap: false,
            ),
          ),
        );
      case 'ul':
      case 'ol':
        return _list(node, listDepth);
      case 'table':
        return _table(node);
      default:
        // Inline content at block level (for example a lone image).
        return _paragraph([node], sheet.p, sheet.textAlign, sheet.pPadding);
    }
  }

  Widget _heading(
    md.Element node,
    TextStyle? style,
    WrapAlignment align,
    EdgeInsets? padding,
    int level,
  ) => Semantics(
    header: true,
    child: _paragraph(node.children ?? const [], style, align, padding),
  );

  Widget _paragraph(
    List<md.Node> nodes,
    TextStyle? style,
    WrapAlignment align,
    EdgeInsets? padding,
  ) {
    final spans = _inlines(nodes, const TextStyle(), null);
    Widget text = Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: _textAlign(align),
    );
    if (widget.onTapText != null) {
      text = GestureDetector(onTap: widget.onTapText, child: text);
    }
    return padding == null || padding == EdgeInsets.zero
        ? text
        : Padding(padding: padding, child: text);
  }

  List<InlineSpan> _inlines(
    List<md.Node> nodes,
    TextStyle style,
    (String, String?, String)? link,
  ) {
    final out = <InlineSpan>[];
    for (final node in nodes) {
      if (node is md.Text) {
        var text = node.text;
        if (!widget.softLineBreak) text = text.replaceAll('\n', ' ');
        out.add(_textSpan(text, style, link));
        continue;
      }
      if (node is! md.Element) continue;
      final children = node.children ?? const <md.Node>[];
      switch (node.tag) {
        case 'em':
          out.addAll(_inlines(children, style.merge(sheet.em), link));
        case 'strong':
          out.addAll(_inlines(children, style.merge(sheet.strong), link));
        case 'del':
          out.addAll(_inlines(children, style.merge(sheet.del), link));
        case 'code':
          out.add(_textSpan(node.textContent, style.merge(sheet.code), link));
        case 'br':
          out.add(const TextSpan(text: '\n'));
        case 'a':
          final href = node.attributes['href'];
          final title = node.attributes['title'] ?? '';
          out.addAll(
            _inlines(children, style.merge(sheet.a), (
              node.textContent,
              href,
              title,
            )),
          );
        case 'img':
          out.add(WidgetSpan(child: _image(node)));
        case 'input':
          if (node.attributes['type'] == 'checkbox') {
            final checked = node.attributes.containsKey('checked');
            out.add(
              WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child:
                      widget.checkboxBuilder?.call(checked) ??
                      Icon(
                        checked
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: (sheet.checkbox?.fontSize ?? 14) * 1.25,
                        color: sheet.checkbox?.color,
                      ),
                ),
              ),
            );
          }
        default:
          out.addAll(_inlines(children, style, link));
      }
    }
    return out;
  }

  TextSpan _textSpan(
    String text,
    TextStyle style,
    (String, String?, String)? link,
  ) {
    if (link == null || widget.onTapLink == null) {
      return TextSpan(text: text, style: style);
    }
    final (label, href, title) = link;
    return TextSpan(
      text: text,
      style: style,
      recognizer: TapGestureRecognizer()
        ..onTap = () => widget.onTapLink!(label, href, title),
    );
  }

  Widget _image(md.Element node) {
    final src = node.attributes['src'] ?? '';
    final title = node.attributes['title'];
    final alt = node.attributes['alt'];
    final uri = Uri.parse(src);
    final builder = widget.imageBuilder;
    if (builder != null) return builder(uri, title, alt);
    if (uri.scheme == 'http' || uri.scheme == 'https')
      return Image.network(src, semanticLabel: alt);
    if (uri.scheme == 'resource')
      return Image.asset(uri.path, semanticLabel: alt);
    final directory = widget.imageDirectory;
    final path = directory == null ? src : '$directory/$src';
    return Image.network(path, semanticLabel: alt);
  }

  Widget _list(md.Element node, int depth) {
    final ordered = node.tag == 'ol';
    final start = int.tryParse(node.attributes['start'] ?? '') ?? 1;
    final items = [
      for (final child in node.children ?? const <md.Node>[])
        if (child is md.Element && child.tag == 'li') child,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: sheet.listIndent ?? 24,
                child: Padding(
                  padding: sheet.listBulletPadding ?? EdgeInsets.zero,
                  child: Align(
                    alignment: Alignment.topRight,
                    child:
                        widget.bulletBuilder?.call(
                          MarkdownBulletParameters(
                            index: i,
                            style: ordered
                                ? BulletStyle.orderedList
                                : BulletStyle.unorderedList,
                            nestLevel: depth,
                          ),
                        ) ??
                        Text(
                          ordered ? '${start + i}.' : '•',
                          style: sheet.listBullet,
                        ),
                  ),
                ),
              ),
              Expanded(child: _listItem(items[i], depth)),
            ],
          ),
      ],
    );
  }

  Widget _listItem(md.Element item, int depth) {
    final children = item.children ?? const <md.Node>[];
    final hasBlocks = children.any(
      (child) =>
          child is md.Element &&
          const {
            'p',
            'ul',
            'ol',
            'blockquote',
            'pre',
            'table',
          }.contains(child.tag),
    );
    if (!hasBlocks) {
      return _paragraph(children, sheet.p, sheet.textAlign, null);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks(children, depth + 1),
    );
  }

  Widget _table(md.Element node) {
    final rows = <TableRow>[];
    void collect(md.Element element, bool head) {
      for (final child in element.children ?? const <md.Node>[]) {
        if (child is! md.Element) continue;
        if (child.tag == 'thead') {
          collect(child, true);
        } else if (child.tag == 'tbody') {
          collect(child, false);
        } else if (child.tag == 'tr') {
          rows.add(
            TableRow(
              decoration: sheet.tableCellsDecoration,
              children: [
                for (final cell in child.children ?? const <md.Node>[])
                  if (cell is md.Element)
                    Padding(
                      padding: sheet.tableCellsPadding ?? EdgeInsets.zero,
                      child: Text.rich(
                        TextSpan(
                          children: _inlines(
                            cell.children ?? const [],
                            const TextStyle(),
                            null,
                          ),
                        ),
                        style: head || cell.tag == 'th'
                            ? sheet.tableBody?.merge(sheet.tableHead) ??
                                  sheet.tableHead
                            : sheet.tableBody,
                        textAlign: switch (cell.attributes['align']) {
                          'center' => TextAlign.center,
                          'right' => TextAlign.right,
                          'left' => TextAlign.left,
                          _ =>
                            head || cell.tag == 'th'
                                ? sheet.tableHeadAlign ?? TextAlign.center
                                : TextAlign.start,
                        },
                      ),
                    ),
              ],
            ),
          );
        }
      }
    }

    collect(node, false);
    return Table(
      border: sheet.tableBorder,
      defaultColumnWidth: sheet.tableColumnWidth ?? const FlexColumnWidth(),
      children: rows,
    );
  }
}
