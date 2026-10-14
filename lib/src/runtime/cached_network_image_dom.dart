/// `package:cached_network_image` for the native runtime. Browsers cache
/// network images themselves (HTTP cache), so images load as plain `<img>`
/// elements; placeholders, progress and error builders keep working.
library;

import 'dart:async';

import 'flutter_dom.dart';

enum ImageRenderMethodForWeb { HtmlImage, HttpGet }

class DownloadProgress {
  DownloadProgress(this.originalUrl, this.totalSize, this.downloaded);
  final String originalUrl;
  final int? totalSize;
  final int downloaded;
  double? get progress =>
      totalSize == null || totalSize == 0 ? null : downloaded / totalSize!;
}

typedef PlaceholderWidgetBuilder =
    Widget Function(BuildContext context, String url);
typedef ProgressIndicatorBuilder =
    Widget Function(
      BuildContext context,
      String url,
      DownloadProgress progress,
    );
typedef LoadingErrorWidgetBuilder =
    Widget Function(BuildContext context, String url, Object error);
typedef ImageWidgetBuilder =
    Widget Function(BuildContext context, ImageProvider imageProvider);
typedef ErrorListener = void Function(Object value);

class CachedNetworkImageProvider extends NetworkImage {
  const CachedNetworkImageProvider(
    super.url, {
    this.maxHeight,
    this.maxWidth,
    super.scale,
    this.errorListener,
    super.headers,
    this.cacheManager,
    this.cacheKey,
    this.imageRenderMethodForWeb = ImageRenderMethodForWeb.HtmlImage,
  });
  final int? maxHeight, maxWidth;
  final ErrorListener? errorListener;
  final Object? cacheManager;
  final String? cacheKey;
  final ImageRenderMethodForWeb imageRenderMethodForWeb;

  /// The browser owns the cache; eviction is reported as done.
  static Future<bool> evictFromCache(
    String url, {
    String? cacheKey,
    Object? cacheManager,
    double scale = 1,
  }) async => true;
}

class CachedNetworkImage extends StatelessWidget {
  CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.httpHeaders,
    this.imageBuilder,
    this.placeholder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.cacheManager,
    this.useOldImageOnUrlChange = false,
    this.color,
    this.filterQuality = FilterQuality.low,
    this.colorBlendMode,
    this.placeholderFadeInDuration,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.errorListener,
    this.imageRenderMethodForWeb = ImageRenderMethodForWeb.HtmlImage,
  });
  final String imageUrl;
  final Map<String, String>? httpHeaders;
  final ImageWidgetBuilder? imageBuilder;
  final PlaceholderWidgetBuilder? placeholder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final Duration fadeOutDuration, fadeInDuration;
  final Duration? placeholderFadeInDuration;
  final Curve fadeOutCurve, fadeInCurve;
  final double? width, height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final bool matchTextDirection, useOldImageOnUrlChange;
  final Object? cacheManager;
  final Color? color;
  final FilterQuality filterQuality;
  final BlendMode? colorBlendMode;
  final int? memCacheWidth, memCacheHeight;
  final int? maxWidthDiskCache, maxHeightDiskCache;
  final String? cacheKey;
  final ErrorListener? errorListener;
  final ImageRenderMethodForWeb imageRenderMethodForWeb;

  static Future<bool> evictFromCache(
    String url, {
    String? cacheKey,
    Object? cacheManager,
    double scale = 1,
  }) async => true;

  @override
  Widget build(BuildContext context) {
    final provider = CachedNetworkImageProvider(imageUrl);
    final builder = imageBuilder;
    if (builder != null) return builder(context, provider);
    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: filterQuality,
      gaplessPlayback: useOldImageOnUrlChange,
      loadingBuilder: placeholder == null && progressIndicatorBuilder == null
          ? null
          : (context, child, progress) {
              if (progress == null) return child;
              final waiting =
                  placeholder?.call(context, imageUrl) ??
                  progressIndicatorBuilder!(
                    context,
                    imageUrl,
                    DownloadProgress(
                      imageUrl,
                      progress.expectedTotalBytes,
                      progress.cumulativeBytesLoaded,
                    ),
                  );
              // The image keeps loading underneath the placeholder.
              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: 0, child: child),
                  waiting,
                ],
              );
            },
      errorBuilder: errorWidget == null && errorListener == null
          ? null
          : (context, error, stackTrace) {
              errorListener?.call(error);
              return errorWidget?.call(context, imageUrl, error) ??
                  SizedBox(width: width, height: height);
            },
    );
  }
}
