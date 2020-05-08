// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../widgets.dart' as image_provider;

/// The dart:html implementation of [test_image.TestImage].
///
/// TestImage on the web does not support decoding to a specified size.
class OptimizedCacheImageProvider
    extends ImageProvider<image_provider.OptimizedCacheImageProvider>
    implements image_provider.OptimizedCacheImageProvider {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const OptimizedCacheImageProvider(this.url,
      {this.scale = 1.0,
      this.useScaleCacheManager,
      this.errorListener,
      this.headers,
      this.cacheManager,
      this.cacheWidth,
      this.cacheHeight})
      : assert(url != null),
        assert(scale != null);

  @override
  final BaseCacheManager cacheManager;

  @override
  final String url;

  @override
  final double scale;

  /// Listener to be called when images fails to load.
  @override
  final image_provider.ErrorListener errorListener;

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
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
        chunkEvents: chunkEvents.stream,
        codec:
            _loadAsync(key as OptimizedCacheImageProvider, decode, chunkEvents),
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

  // TODO(garyq): We should eventually support custom decoding of network images on Web as
  // well, see https://github.com/flutter/flutter/issues/42789.
  //
  // Web does not support decoding network images to a specified size. The decode parameter
  // here is ignored and the web-only `ui.webOnlyInstantiateImageCodecFromUrl` will be used
  // directly in place of the typical `instantiateImageCodec` method.
  Future<ui.Codec> _loadAsync(OptimizedCacheImageProvider key,
      DecoderCallback decode, StreamController<ImageChunkEvent> chunkEvents) {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);
    // This API only exists in the web engine implementation and is not
    // contained in the analyzer summary for Flutter.
    // ignore: undefined_function
    return ui.webOnlyInstantiateImageCodecFromUrl(
        resolved, // ignore: undefined_function
        chunkCallback: (int bytes, int total) {
      chunkEvents.add(ImageChunkEvent(
          cumulativeBytesLoaded: bytes, expectedTotalBytes: total));
    }) as Future<ui.Codec>; // ignore: undefined_function
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
