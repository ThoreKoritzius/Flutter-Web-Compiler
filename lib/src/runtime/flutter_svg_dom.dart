/// `package:flutter_svg` for the native runtime: SVG pictures render as
/// images the browser decodes natively. A `srcIn`/`srcATop` color filter
/// (or the deprecated `color`) recolors the picture through a CSS mask, the
/// common way icons are tinted.
library;

import 'dart:convert';

import 'flutter_dom.dart';

class SvgTheme {
  const SvgTheme({
    this.currentColor = const Color(0xFF000000),
    this.fontSize = 14,
    this.xHeight,
  });
  final Color currentColor;
  final double fontSize;
  final double? xHeight;
}

abstract class ColorMapper {
  const ColorMapper();
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  );
}

/// Where a picture comes from; resolved to an image the browser can load.
abstract class BytesLoader {
  const BytesLoader();
  ImageProvider get _image;
}

class SvgAssetLoader extends BytesLoader {
  const SvgAssetLoader(
    this.assetName, {
    this.packageName,
    this.assetBundle,
    this.theme,
    this.colorMapper,
  });
  final String assetName;
  final String? packageName;
  final AssetBundle? assetBundle;
  final SvgTheme? theme;
  final ColorMapper? colorMapper;
  @override
  ImageProvider get _image => AssetImage(assetName, package: packageName);
}

class SvgNetworkLoader extends BytesLoader {
  const SvgNetworkLoader(
    this.url, {
    this.headers,
    this.theme,
    this.colorMapper,
    Object? httpClient,
  });
  final String url;
  final Map<String, String>? headers;
  final SvgTheme? theme;
  final ColorMapper? colorMapper;
  @override
  ImageProvider get _image => NetworkImage(url);
}

class SvgStringLoader extends BytesLoader {
  const SvgStringLoader(this.svg, {this.theme, this.colorMapper});
  final String svg;
  final SvgTheme? theme;
  final ColorMapper? colorMapper;
  @override
  ImageProvider get _image => MemoryImage(Uint8List.fromList(utf8.encode(svg)));
}

class SvgBytesLoader extends BytesLoader {
  const SvgBytesLoader(this.bytes, {this.theme, this.colorMapper});
  final Uint8List bytes;
  final SvgTheme? theme;
  final ColorMapper? colorMapper;
  @override
  ImageProvider get _image => MemoryImage(bytes);
}

class SvgPicture extends StatelessWidget {
  const SvgPicture(
    this.bytesLoader, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.clipBehavior = Clip.hardEdge,
    this.colorFilter,
    this.errorBuilder,
    Object? theme,
    this.renderingStrategy,
  });

  SvgPicture.asset(
    String assetName, {
    super.key,
    this.matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.clipBehavior = Clip.hardEdge,
    this.errorBuilder,
    SvgTheme? theme,
    ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    @Deprecated('Use colorFilter') Color? color,
    @Deprecated('Use colorFilter') BlendMode colorBlendMode = BlendMode.srcIn,
    @Deprecated('No-op') bool cacheColorFilter = false,
    this.renderingStrategy,
  }) : bytesLoader = SvgAssetLoader(assetName, packageName: package),
       colorFilter =
           colorFilter ??
           (color == null ? null : ColorFilter.mode(color, colorBlendMode));

  SvgPicture.network(
    String url, {
    super.key,
    Map<String, String>? headers,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.clipBehavior = Clip.hardEdge,
    this.errorBuilder,
    SvgTheme? theme,
    ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    @Deprecated('Use colorFilter') Color? color,
    @Deprecated('Use colorFilter') BlendMode colorBlendMode = BlendMode.srcIn,
    @Deprecated('No-op') bool cacheColorFilter = false,
    Object? httpClient,
    this.renderingStrategy,
  }) : bytesLoader = SvgNetworkLoader(url, headers: headers),
       colorFilter =
           colorFilter ??
           (color == null ? null : ColorFilter.mode(color, colorBlendMode));

  SvgPicture.string(
    String string, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.clipBehavior = Clip.hardEdge,
    this.errorBuilder,
    SvgTheme? theme,
    ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    @Deprecated('Use colorFilter') Color? color,
    @Deprecated('Use colorFilter') BlendMode colorBlendMode = BlendMode.srcIn,
    @Deprecated('No-op') bool cacheColorFilter = false,
    this.renderingStrategy,
  }) : bytesLoader = SvgStringLoader(string),
       colorFilter =
           colorFilter ??
           (color == null ? null : ColorFilter.mode(color, colorBlendMode));

  SvgPicture.memory(
    Uint8List bytes, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.clipBehavior = Clip.hardEdge,
    this.errorBuilder,
    SvgTheme? theme,
    ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    @Deprecated('Use colorFilter') Color? color,
    @Deprecated('Use colorFilter') BlendMode colorBlendMode = BlendMode.srcIn,
    @Deprecated('No-op') bool cacheColorFilter = false,
    this.renderingStrategy,
  }) : bytesLoader = SvgBytesLoader(bytes),
       colorFilter =
           colorFilter ??
           (color == null ? null : ColorFilter.mode(color, colorBlendMode));

  final BytesLoader bytesLoader;
  final double? width, height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool matchTextDirection, allowDrawingOutsideViewBox;
  final bool excludeFromSemantics;
  final WidgetBuilder? placeholderBuilder;
  final String? semanticsLabel;
  final Clip clipBehavior;
  final ColorFilter? colorFilter;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Object? renderingStrategy;

  static final cache = _SvgCache();

  @override
  Widget build(BuildContext context) {
    final image = bytesLoader._image;
    final filter = colorFilter;
    final tint =
        filter != null &&
            filter.color != null &&
            (filter.blendMode == BlendMode.srcIn ||
                filter.blendMode == BlendMode.srcATop ||
                filter.blendMode == BlendMode.modulate)
        ? filter.color
        : null;
    if (tint != null) {
      return Semantics(
        label: excludeFromSemantics ? null : semanticsLabel,
        image: true,
        excludeSemantics: excludeFromSemantics,
        child: NativeMaskedImage(
          url: image.url,
          color: tint,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }
    return Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      matchTextDirection: matchTextDirection,
      errorBuilder: errorBuilder,
      loadingBuilder: placeholderBuilder == null
          ? null
          : (context, child, progress) =>
                progress == null ? child : placeholderBuilder!(context),
    );
  }
}

class _SvgCache {
  void clear() {}
  bool evict(Object key) => false;
  int get maximumSize => 100;
  set maximumSize(int value) {}
}
