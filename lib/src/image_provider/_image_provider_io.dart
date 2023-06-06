import 'dart:async' show Future, StreamController, scheduleMicrotask;
import 'dart:ui' as ui show Codec;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:optimized_cached_image/src/cache/default_image_cache_manager.dart';
import 'package:optimized_cached_image/src/cache/image_cache_manager.dart';

import '../../optimized_cached_image.dart' show ImageRenderMethodForWeb;
import 'multi_image_stream_completer.dart';
import 'optimized_cached_image_provider.dart' as image_provider;

/// IO implementation of the CachedNetworkImageProvider; the ImageProvider to
/// load network images using a cache.
class OptimizedCacheImageProvider
    extends ImageProvider<image_provider.OptimizedCacheImageProvider>
    implements image_provider.OptimizedCacheImageProvider {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const OptimizedCacheImageProvider(
    this.url, {
    this.maxHeight,
    this.maxWidth,
    this.scale = 1.0,
    this.errorListener,
    this.headers,
    this.cacheManager,
    this.cacheKey,
    //ignore: avoid_unused_constructor_parameters
    ImageRenderMethodForWeb? imageRenderMethodForWeb,
  });

  @override
  final BaseCacheManager? cacheManager;

  /// Web url of the image to load
  @override
  final String url;

  /// Cache key of the image to cache
  @override
  final String? cacheKey;

  /// Scale of the image
  @override
  final double scale;

  /// Listener to be called when images fails to load.
  @override
  final image_provider.ErrorListener? errorListener;

  /// Set headers for the image provider, for example for authentication
  @override
  final Map<String, String>? headers;

  @override
  final int? maxHeight;

  @override
  final int? maxWidth;

  @override
  Future<OptimizedCacheImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<OptimizedCacheImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    image_provider.OptimizedCacheImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
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
    image_provider.OptimizedCacheImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async* {
    assert(key == this);
    try {
      var mngr = cacheManager ?? DefaultImageCacheManager();
      assert(
          mngr is OicImageCacheManager ||
              (maxWidth == null && maxHeight == null),
          'To resize the image with a CacheManager the '
          'CacheManager needs to be an ImageCacheManager. maxWidth and '
          'maxHeight will be ignored when a normal CacheManager is used.');

      var stream = mngr is OicImageCacheManager
          ? mngr.getImageFile(key.url,
              maxHeight: maxHeight,
              maxWidth: maxWidth,
              withProgress: true,
              headers: headers,
              key: key.cacheKey)
          : mngr.getFileStream(key.url,
              withProgress: true, headers: headers, key: key.cacheKey);

      await for (var result in stream) {
        if (result is DownloadProgress) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: result.downloaded,
            expectedTotalBytes: result.totalSize,
          ));
        }
        if (result is FileInfo) {
          var file = result.file;
          var bytes =
              await ImmutableBuffer.fromUint8List(await file.readAsBytes());
          var decoded = await decode(bytes);
          yield decoded;
        }
      }
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });

      errorListener?.call();
      rethrow;
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other is OptimizedCacheImageProvider) {
      return ((cacheKey ?? url) == (other.cacheKey ?? other.url)) &&
          scale == other.scale &&
          maxHeight == other.maxHeight &&
          maxWidth == other.maxWidth;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(cacheKey ?? url, scale, maxHeight, maxWidth);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
