import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:octo_image/octo_image.dart';
import 'package:optimized_cached_image/image_cache_manager.dart';
import 'package:optimized_cached_image/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:optimized_cached_image/widgets.dart';

typedef ImageWidgetBuilder = Widget Function(
    BuildContext context, ImageProvider imageProvider);
typedef PlaceholderWidgetBuilder = Widget Function(
    BuildContext context, String url);
typedef ProgressIndicatorBuilder = Widget Function(
    BuildContext context, String url, DownloadProgress progress);
typedef LoadingErrorWidgetBuilder = Widget Function(
    BuildContext context, String url, dynamic error);

// ignore: must_be_immutable
class OptimizedCacheImage extends StatelessWidget {
  OptimizedCacheImageProvider _image;

  /// Option to use cachemanager with other settings
  final BaseCacheManager cacheManager;

  /// The target image that is displayed.
  final String imageUrl;

  /// Optional builder to further customize the display of the image.
  final ImageWidgetBuilder imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final PlaceholderWidgetBuilder placeholder;

  /// Widget displayed while the target [imageUrl] is loading.
  final ProgressIndicatorBuilder progressIndicatorBuilder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final LoadingErrorWidgetBuilder errorWidget;

  /// The duration of the fade-in animation for the [placeholder].
  final Duration placeholderFadeInDuration;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [imageUrl].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [imageUrl].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an AlignmentGeometry.
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// children); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with children in right-to-left environments, for
  /// children that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip children with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Optional headers for the http request of the image url
  final Map<String, String> httpHeaders;

  /// When set to true it will animate from the old image to the new image
  /// if the url changes.
  final bool useOldImageOnUrlChange;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode colorBlendMode;

  /// Target the interpolation quality for image scaling.
  ///
  /// If not given a value, defaults to FilterQuality.low.
  final FilterQuality filterQuality;

  /// Use experimental scaleCacheManager.
  final bool useScaleCacheManager;

  int _maxWidth;
  int _maxHeight;
  final ImageRenderMethodForWeb imageRenderMethodForWeb;

  /// CachedNetworkImage shows a network image using a caching mechanism. It also
  /// provides support for a placeholder, showing an error and fading into the
  /// loaded image. Next to that it supports most features of a default Image
  /// widget.

  OptimizedCacheImage({
    Key key,
    @required this.imageUrl,
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
    this.useScaleCacheManager = true,
    this.imageRenderMethodForWeb,
  })  : assert(imageUrl != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(filterQuality != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        assert(useScaleCacheManager != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (width != null || height != null) {
        constraints = BoxConstraints(
            maxWidth: width ?? double.minPositive,
            maxHeight: height ?? double.minPositive);
      } else {
        final ratio = MediaQuery.of(context).devicePixelRatio;
        constraints = BoxConstraints(
          maxWidth: constraints.maxWidth != double.infinity
              ? constraints.maxWidth * ratio
              : constraints.maxWidth,
          maxHeight: constraints.maxHeight != double.infinity
              ? constraints.maxHeight * ratio
              : constraints.maxHeight,
        );
      }
      final _constrainHeight = constraints.maxHeight != double.infinity
          ? constraints.maxHeight.toInt()
          : null;
      final _constrainWidth = constraints.maxWidth != double.infinity
          ? constraints.maxWidth.toInt()
          : null;

      if (_constrainWidth != _maxWidth || _constrainHeight != _maxHeight) {
        _maxWidth = _constrainWidth;
        _maxHeight = _constrainHeight;
        _image = OptimizedCacheImageProvider(
          imageUrl,
          headers: httpHeaders,
          cacheManager: getCacheManager(),
          useScaleCacheManager: useScaleCacheManager,
          cacheHeight: _maxHeight,
          cacheWidth: _maxWidth,
          imageRenderMethodForWeb: imageRenderMethodForWeb,
        );
      }
      return OctoImage(
          image: _image,
          imageBuilder: imageBuilder != null ? _octoImageBuilder : null,
          placeholderBuilder:
              placeholder != null ? _octoPlaceholderBuilder : null,
          progressIndicatorBuilder: progressIndicatorBuilder != null
              ? _octoProgressIndicatorBuilder
              : null,
          errorBuilder: errorWidget != null ? _octoErrorBuilder : null,
          fadeOutDuration: fadeOutDuration,
          fadeOutCurve: fadeOutCurve,
          fadeInDuration: fadeInDuration,
          fadeInCurve: fadeInCurve,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          matchTextDirection: matchTextDirection,
          color: color,
          filterQuality: filterQuality,
          colorBlendMode: colorBlendMode,
          placeholderFadeInDuration: placeholderFadeInDuration,
          gaplessPlayback: useOldImageOnUrlChange);
    });
  }

  Widget _octoImageBuilder(BuildContext context, Widget child) {
    return imageBuilder(context, _image);
  }

  Widget _octoPlaceholderBuilder(BuildContext context) {
    return placeholder(context, imageUrl);
  }

  Widget _octoProgressIndicatorBuilder(
    BuildContext context,
    ImageChunkEvent progress,
  ) {
    int totalSize;
    int downloaded = 0;
    if (progress != null) {
      totalSize = progress.expectedTotalBytes;
      downloaded = progress.cumulativeBytesLoaded;
    }
    return progressIndicatorBuilder(
        context, imageUrl, DownloadProgress(imageUrl, totalSize, downloaded));
  }

  Widget _octoErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    return errorWidget(context, imageUrl, error);
  }

  BaseCacheManager getCacheManager() => useScaleCacheManager
      ? ImageCacheManager()
      : (cacheManager ?? DefaultCacheManager());
}
