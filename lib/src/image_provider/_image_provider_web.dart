import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../optimized_cached_image.dart' show ImageRenderMethodForWeb;
import '_load_async_web.dart';
import 'multi_image_stream_completer.dart';
import 'optimized_cached_image_provider.dart' as image_provider;

/// The dart:html implementation of [image_provider.OptimizedCacheImageProvider].
class OptimizedCacheImageProvider
    extends ImageProvider<image_provider.OptimizedCacheImageProvider>
    implements image_provider.OptimizedCacheImageProvider {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const OptimizedCacheImageProvider(
    this.url, {
    this.maxHeight,
    this.maxWidth,
    this.scale = 1.0,
    this.errorListener,
    this.headers,
    this.cacheManager,
    this.cacheKey,
    ImageRenderMethodForWeb? imageRenderMethodForWeb,
  }) : _imageRenderMethodForWeb =
            imageRenderMethodForWeb ?? ImageRenderMethodForWeb.HtmlImage;

  @override
  final BaseCacheManager? cacheManager;

  @override
  final String url;

  @override
  final String? cacheKey;

  @override
  final double scale;

  /// Listener to be called when images fails to load.
  @override
  final image_provider.ErrorListener? errorListener;

  @override
  final Map<String, String>? headers;

  @override
  final int? maxHeight;

  @override
  final int? maxWidth;

  final ImageRenderMethodForWeb _imageRenderMethodForWeb;

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
        chunkEvents: chunkEvents.stream,
        codec:
            _loadAsync(key as OptimizedCacheImageProvider, chunkEvents, decode),
        scale: key.scale,
        informationCollector: _imageStreamInformationCollector(key));
  }

  InformationCollector? _imageStreamInformationCollector(
      image_provider.OptimizedCacheImageProvider key) {
    InformationCollector? collector;
    assert(() {
      collector = () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<OptimizedCacheImageProvider>(
              'Image key', key as OptimizedCacheImageProvider),
        ];
      };
      return true;
    }());
    return collector;
  }

  Stream<ui.Codec> _loadAsync(
    OptimizedCacheImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) {
    switch (_imageRenderMethodForWeb) {
      case ImageRenderMethodForWeb.HttpGet:
        return _loadAsyncHttpGet(key, chunkEvents, decode);
      case ImageRenderMethodForWeb.HtmlImage:
        return loadAsyncHtmlImage(key, chunkEvents, decode).asStream();
    }
  }

  Stream<ui.Codec> _loadAsyncHttpGet(
    OptimizedCacheImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async* {
    assert(key == this);
    try {
      var mngr = cacheManager ?? DefaultCacheManager();
      await for (var result in mngr.getFileStream(key.url,
          withProgress: true, headers: headers)) {
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
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (other is OptimizedCacheImageProvider) {
      var sameKey = (cacheKey ?? url) == (other.cacheKey ?? other.url);
      return sameKey && scale == other.scale;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(url, scale, cacheKey);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
