import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:optimized_cached_image/image_transformer/resize_image_transformer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quiver/collection.dart';

import '../image_cache_manager.dart';

class ResizeImageCacheManager extends BaseCacheManager {
  final ResizeImageCacheConfig cacheConfig;
  final ImageTransformer transformer;
  final _TAG = (ResizeImageCacheManager).toString();

  final LruMap<int, Uint8List> _lruMemoryCache = new LruMap(maximumSize: 500);

  @override
  Future<String> getFilePath() async {
    if (cacheConfig.storagePath != null) {
      final Directory directory = await cacheConfig.storagePath;
      return directory.path;
    } else {
      final Directory directory = await getTemporaryDirectory();
      return p.join(directory.path, key);
    }
  }

  static const key = 'libCachedImageData';

  static ResizeImageCacheManager _instance;

  /// The ScaledCacheManager that can be easily used directly. The code of
  /// this implementation can be used as inspiration for more complex cache
  /// managers.
  factory ResizeImageCacheManager(
      {ResizeImageCacheConfig cacheConfig, ImageTransformer transformer}) {
    final config = cacheConfig ?? ResizeImageCacheConfig();
    _instance ??= ResizeImageCacheManager._(
        config, transformer ?? ResizeImageTransformer(config));
    return _instance;
  }

  /// A named initializer for when clients wish to initialize the manager with custom config.
  /// This is purely for syntax purposes.
  factory ResizeImageCacheManager.init(
      {ResizeImageCacheConfig cacheConfig, ImageTransformer transformer}) {
    return ResizeImageCacheManager(
        cacheConfig: cacheConfig, transformer: transformer);
  }

  ResizeImageCacheManager._(this.cacheConfig, this.transformer) : super(key);

  ///Download the file and add to cache
  @override
  Future<FileInfo> downloadFile(String url,
      {Map<String, String> authHeaders,
      bool force = false,
      BoxConstraints constraints}) async {
    log('downloadFile, with url: $url', name: _TAG);
    var response =
        await super.downloadFile(url, authHeaders: authHeaders, force: force);
    response = constraints != null
        ? await transformer.transform(
            response, {ResizeImageTransformer.SIZE_PARAM: constraints})
        : response;
    return response;
  }

  /// Get the file from the cache and/or online, depending on availability and age.
  /// Downloaded form [url], [headers] can be used for example for authentication.
  /// The files are returned as stream. First the cached file if available, when the
  /// cached file is too old the newly downloaded file is returned afterwards.
  ///
  /// The [FileResponse] is either a [FileInfo] object for fully downloaded files
  /// or a [DownloadProgress] object for when a file is being downloaded.
  /// The [DownloadProgress] objects are only dispatched when [withProgress] is
  /// set on true and the file is not available in the cache. When the file is
  /// returned from the cache there will be no progress given, although the file
  /// might be outdated and a new file is being downloaded in the background.
  @override
  Stream<FileResponse> getFileStream(String url,
      {Map<String, String> headers,
      bool withProgress,
      Constraints constraints}) {
    final downStream = StreamController<FileResponse>();
    if (_lruMemoryCache.containsKey(url.hashCode)) {
      log('getFileStream, memory cached, $url', name: _TAG);
      downStream.add(ImageMemoryResponse(_lruMemoryCache[url.hashCode], url));
    } else {
      fileStream(downStream, url, headers, withProgress, constraints);
    }

    return downStream.stream;
  }

  void fileStream(
      StreamController<FileResponse> downStream,
      String url,
      Map<String, String> headers,
      bool withProgress,
      BoxConstraints constraints) {
    final upStream =
        super.getFileStream(url, headers: headers, withProgress: withProgress);

    var isUpStreamClosed = false;
    upStream.listen((info) async {
      if (info is FileInfo) {
        log('getFileStream, with $url', name: _TAG);
        File file = (info as FileInfo).file;
        if (file.existsSync()) {
          ImageProperties imageProperties =
              await FlutterNativeImage.getImageProperties(file.path);

          if (constraints != null) {
            var targetWidth = constraints.maxWidth;
            var targetHeight = constraints.maxHeight;
            if (targetHeight == double.infinity &&
                targetWidth != double.infinity) {
              targetHeight = imageProperties.height /
                  (imageProperties.width / targetWidth);

              constraints = BoxConstraints(
                  maxWidth: targetWidth, maxHeight: targetHeight);
            }
          }

          if (constraints != null &&
              math.min(imageProperties.width, imageProperties.height) >
                  math.min(constraints.maxWidth, constraints.maxHeight)) {
            log('getFileStream, srs dimension width: ${imageProperties.width} and height: ${imageProperties.height}',
                name: _TAG);

            info = await transformer.transform(
                info, {ResizeImageTransformer.SIZE_PARAM: constraints});
          } else {
            log('getFileStream, use cached file', name: _TAG);
          }

          Uint8List bytes = file.readAsBytesSync();
          _lruMemoryCache[url.hashCode] = bytes;
        }
      }
      downStream.add(info);
      if (isUpStreamClosed) {
        unawaited(downStream.close());
      }
    }, onError: (e) {
      downStream.addError(e);
      downStream.close();
    }, onDone: () {
      isUpStreamClosed = true;
    });
  }

  bool containsMemoryCache(String url) {
    return _lruMemoryCache.containsKey(url.hashCode);
  }

  Uint8List getMemoryCache(String url) {
    return _lruMemoryCache[url.hashCode];
  }
}

class ResizeImageCacheConfig {
  /// Storage path for cache
  final Future<Directory> storagePath;

  ResizeImageCacheConfig({this.storagePath});
}

class ImageMemoryResponse extends FileResponse {
  ImageMemoryResponse(this.imageBytes, String originalUrl) : super(originalUrl);

  final Uint8List imageBytes;
}
