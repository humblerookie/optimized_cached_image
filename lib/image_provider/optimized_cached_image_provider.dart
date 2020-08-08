import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:optimized_cached_image/debug_tools.dart';
import '../image_cache_manager.dart';
import '_image_provider_io.dart'
    if (dart.library.html) '_image_provider_web.dart' as image_provider;

typedef ErrorListener = void Function();

/// Currently there are 2 different ways to show an image on the web with both
/// their own pros and cons, using a custom [HttpGet] (the default for this library)
/// or an HTML Image element mentioned [here on a GitHub issue](https://github.com/flutter/flutter/issues/57187#issuecomment-635637494).
///
/// When using HttpGet the image will work on Skia and it will use the [OptimizedCacheImageProvider.headers]
/// when they are provided. In this package it also uses any url transformations that might
/// be executed by the [OptimizedCacheImageProvider.cacheManager]. However, this method does require a CORS
/// handshake and will not just work for every image from the web.
///
/// The [HtmlImage] does not need a CORS handshake, but it also does not use your
/// provided headers and it does not work when using Skia to render the page.
enum ImageRenderMethodForWeb {
  HtmlImage,
  HttpGet,
}

abstract class OptimizedCacheImageProvider
    extends ImageProvider<OptimizedCacheImageProvider> {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const factory OptimizedCacheImageProvider(
    String url, {
    double scale,
    bool useScaleCacheManager,
    @Deprecated('ErrorListener is deprecated, use listeners on the imagestream')
        ErrorListener errorListener,
    Map<String, String> headers,
    BaseCacheManager cacheManager,
    int cacheWidth,
    int cacheHeight,
    ImageRenderMethodForWeb imageRenderMethodForWeb,
  }) = image_provider.OptimizedCacheImageProvider;

  /// Optional cache manager. If no cache manager is defined DefaultCacheManager()
  /// will be used.
  ///
  /// When running flutter on the web, the cacheManager is not used.
  BaseCacheManager get cacheManager;

  @deprecated
  ErrorListener get errorListener;

  /// The URL from which the image will be fetched.
  String get url;

  /// The scale to place in the [ImageInfo] object of the image.
  double get scale;

  /// Flag to switch between default scale cache manager and custom cache manager
  bool get useScaleCacheManager;

  /// Used in conjunction with `useScaleCacheManager` as the cache image width.
  int get cacheWidth;

  /// Used in conjunction with `useScaleCacheManager` as the cache image height.
  int get cacheHeight;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  ///
  /// When running flutter on the web, headers are not used.
  Map<String, String> get headers;

  @override
  ImageStreamCompleter load(
      OptimizedCacheImageProvider key, DecoderCallback decode);
}

///
/// Helper method to transform image urls
///
String getDimensionSuffixedUrl(
    ImageCacheConfig config, String url, int width, int height) {
  Uri uri;
  try {
    uri = Uri.parse(url);
    if (uri != null) {
      Map<String, String> queryParams =
          Map<String, String>.from(uri.queryParameters);
      if (width != null) {
        queryParams[config.widthKey] = width.toString();
      }
      if (height != null) {
        queryParams[config.heightKey] = height.toString();
      }
      uri = uri.replace(queryParameters: queryParams);
    }
  } catch (e) {
    log('Error occurred while parsing url $url, $e');
  }
  return uri?.toString() ?? url;
}

///
/// Helper method to transform image urls
///
String getParentUrl(ImageCacheConfig config, String url) {
  Uri uri;
  try {
    uri = Uri.parse(url);
    if (uri != null) {
      Map<String, String> queryParams =
          Map<String, String>.from(uri.queryParameters);
      queryParams.removeWhere(
          (key, value) => key == config.widthKey || key == config.heightKey);
      uri = uri.replace(queryParameters: queryParams);
    }
  } catch (e) {
    log('Error occurred while parsing url $url, $e');
  }
  var modifiedUrl = uri?.toString();
  if (modifiedUrl != null && modifiedUrl.endsWith("?")) {
    modifiedUrl = modifiedUrl.substring(0, modifiedUrl.length - 1);
  }
  return modifiedUrl ?? url;
}
