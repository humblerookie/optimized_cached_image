import 'dart:async' show Future, StreamController;
import 'dart:ui' as ui show Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../image_cache_manager.dart';
import '../widgets.dart' as image_provider;
import 'multi_image_stream_completer.dart';
import 'optimized_cached_image_provider.dart';

class OptimizedCacheImageProvider
    extends ImageProvider<image_provider.OptimizedCacheImageProvider>
    implements image_provider.OptimizedCacheImageProvider {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const OptimizedCacheImageProvider(
    this.url, {
    this.scale = 1.0,
    this.useScaleCacheManager = true,
    this.errorListener,
    this.headers,
    this.cacheManager,
    this.cacheWidth,
    this.cacheHeight,
    //ignore: avoid_unused_constructor_parameters
    ImageRenderMethodForWeb imageRenderMethodForWeb,
  })  : assert(url != null),
        assert(scale != null),
        assert(useScaleCacheManager != null);

  @override
  final BaseCacheManager cacheManager;

  /// Web url of the image to load
  @override
  final String url;

  /// Scale of the image
  @override
  final double scale;

  /// Listener to be called when images fails to load.
  @override
  final image_provider.ErrorListener errorListener;

  // Set headers for the image provider, for example for authentication
  @override
  final Map<String, String> headers;

  /// Use experimental scaleCacheManager.
  @override
  final bool useScaleCacheManager;

  /// Used in conjunction with `useScaleCacheManager` as the cache image width.
  @override
  final int cacheWidth;

  /// Used in conjunction with `useScaleCacheManager` as the cache image height.
  @override
  final int cacheHeight;

  @override
  Future<OptimizedCacheImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<OptimizedCacheImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(
      image_provider.OptimizedCacheImageProvider key, DecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();
    return MultiImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  Stream<ui.Codec> _loadAsync(
    OptimizedCacheImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) async* {
    assert(key == this);
    try {
      final mngr = getCacheManager();
      final modifiedUrl = getTransformedUrl();
      await for (var result in mngr.getFileStream(modifiedUrl,
          withProgress: true, headers: headers)) {
        if (result is DownloadProgress) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: result.downloaded,
            expectedTotalBytes: result.totalSize,
          ));
        }
        if (result is FileInfo) {
          var file = result.file;
          var bytes = await file.readAsBytes();
          var decoded = await decode(bytes);
          yield decoded;
        }
      }
    } catch (e) {
      errorListener?.call();
      rethrow;
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other is OptimizedCacheImageProvider) {
      return other.getTransformedUrl() == getTransformedUrl() &&
          scale == other.scale;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';

  String getTransformedUrl() {
    if (cacheManager is ImageCacheManager) {
      return getDimensionSuffixedUrl(
          (cacheManager as ImageCacheManager).cacheConfig,
          url,
          cacheWidth,
          cacheHeight);
    } else {
      return url;
    }
  }

  BaseCacheManager getCacheManager() => useScaleCacheManager
      ? ImageCacheManager()
      : (cacheManager ?? DefaultCacheManager());
}
