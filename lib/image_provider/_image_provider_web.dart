// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:optimized_cached_image/image_provider/multi_image_stream_completer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../widgets.dart' show ImageRenderMethodForWeb;
import '_load_async_web.dart';
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
    this.scale = 1.0,
    this.useScaleCacheManager,
    this.errorListener,
    this.headers,
    this.cacheManager,
    this.cacheWidth,
    this.cacheHeight,
    ImageRenderMethodForWeb imageRenderMethodForWeb,
  })  : _imageRenderMethodForWeb =
            imageRenderMethodForWeb ?? ImageRenderMethodForWeb.HtmlImage,
        assert(url != null),
        assert(scale != null);

  @override
  final BaseCacheManager cacheManager;

  @override
  final bool useScaleCacheManager;

  @override
  final String url;

  @override
  final double scale;

  /// Listener to be called when images fails to load.
  @override
  final image_provider.ErrorListener errorListener;

  @override
  final Map<String, String> headers;

  /// Used in conjunction with `useScaleCacheManager` as the cache image width.
  @override
  final int cacheWidth;

  /// Used in conjunction with `useScaleCacheManager` as the cache image height.
  @override
  final int cacheHeight;

  final ImageRenderMethodForWeb _imageRenderMethodForWeb;

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
        chunkEvents: chunkEvents.stream,
        codec:
            _loadAsync(key as OptimizedCacheImageProvider, chunkEvents, decode),
        scale: key.scale,
        informationCollector: _imageStreamInformationCollector(key));
  }

  InformationCollector _imageStreamInformationCollector(
      image_provider.OptimizedCacheImageProvider key) {
    InformationCollector collector;
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
    DecoderCallback decode,
  ) {
    switch (_imageRenderMethodForWeb) {
      case ImageRenderMethodForWeb.HttpGet:
        return _loadAsyncHttpGet(key, chunkEvents, decode);
      case ImageRenderMethodForWeb.HtmlImage:
        return loadAsyncHtmlImage(key, chunkEvents, decode).asStream();
    }
    throw UnsupportedError(
        'ImageRenderMethod $_imageRenderMethodForWeb is not supported');
  }

  Stream<ui.Codec> _loadAsyncHttpGet(
    OptimizedCacheImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
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
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is OptimizedCacheImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => ui.hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
