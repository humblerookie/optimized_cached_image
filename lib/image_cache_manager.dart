import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// ignore: implementation_imports
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:optimized_cached_image/debug_tools.dart';
import 'package:optimized_cached_image/image_provider/optimized_cached_image_provider.dart';
import 'package:optimized_cached_image/transformer/scale_info.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pedantic/pedantic.dart';
import 'transformer/image_transformer.dart';

class ImageCacheManager extends BaseCacheManager {
  final ImageCacheConfig cacheConfig;
  final ImageTransformer transformer;

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

  static ImageCacheManager _instance;

  /// The ScaledCacheManager that can be easily used directly. The code of
  /// this implementation can be used as inspiration for more complex cache
  /// managers.
  factory ImageCacheManager(
      {ImageCacheConfig cacheConfig, ImageTransformer transformer}) {
    if (_instance == null) {
      final config = cacheConfig ?? ImageCacheConfig();
      Logger.enableLogging = config.enableLog;
      _instance = ImageCacheManager._(
          config, transformer ?? DefaultImageTransformer(config));
    }
    return _instance;
  }

  /// A named initializer for when clients wish to initialize the manager with custom config.
  /// This is purely for syntax purposes.
  factory ImageCacheManager.init(ImageCacheConfig cacheConfig,
      {ImageTransformer transformer}) {
    return ImageCacheManager(
        cacheConfig: cacheConfig, transformer: transformer);
  }

  ImageCacheManager._(this.cacheConfig, this.transformer) : super(key);

  ///Download the file and add to cache
  @override
  Future<FileInfo> downloadFile(String url,
      {Map<String, String> authHeaders, bool force = false}) async {
    String parentUrl = getParentUrl(cacheConfig, url);
    log("Attempting to download $url, with headers $authHeaders");
    var response = await super
        .downloadFile(parentUrl, authHeaders: authHeaders, force: force);
    log("Attempting to transform $url");
    return _scaleImage(response, url, parentUrl);
  }

  /// Scale image to dimensions provided
  Future<FileInfo> _scaleImage(
      FileInfo response, String url, String parentUrl) async {
    final scaledResponse = await transformer.transform(response, url);
    if (scaledResponse.file.path != response.file.path) {
      final orgCacheObject = await store.retrieveCacheData(parentUrl);
      store.putFile(CacheObject(url,
          relativePath: p.basename(scaledResponse.file.path),
          validTill: orgCacheObject.validTill,
          eTag: orgCacheObject.eTag));
    }
    return scaledResponse;
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
  ///
  /// We also try and resize the file if it we don't find a file with the resized params.
  @override
  Stream<FileResponse> getFileStream(String url,
      {Map<String, String> headers, bool withProgress}) {
    log("Attempting to get $url, from cache");
    final parentUrl = getParentUrl(cacheConfig, url);
    final upStream = super
        .getFileStream(parentUrl, headers: headers, withProgress: withProgress);
    final downStream = StreamController<FileResponse>();
    var isUpStreamClosed = false;
    var isFileProcessed = false;
    upStream.listen((d) async {
      if (d is FileInfo) {
        FileInfo fileInfo = d;
        final scaledFile = transformer.getScaledFileInfo(fileInfo.file, url);
        if (!scaledFile.file.existsSync()) {
          d = await _scaleImage(fileInfo, url, parentUrl);
        } else {
          d = FileInfo(scaledFile.file, fileInfo.source, fileInfo.validTill,
              fileInfo.originalUrl);
        }
        isFileProcessed = true;
      }
      downStream.add(d);
      if (isUpStreamClosed && isFileProcessed) {
        unawaited(downStream.close());
      }
    }, onError: (e) {
      log("Error occurred when downloading FileStream $url, $e");
      downStream.addError(e);
      downStream.close();
      log("Cache retrieve failed for $url\n due to $e");
    }, onDone: () {
      isUpStreamClosed = true;
      if (isFileProcessed) {
        downStream.close();
      }
    });
    return downStream.stream;
  }
}

abstract class ImageTransformer {
  Future<FileInfo> transform(FileInfo info, String uri);
  ScaleInfo getScaledFileInfo(File file, String url);
}

class ImageCacheConfig {
  ///The url param name which holds the required width value
  final String widthKey;

  ///The url param name which holds the required height value
  final String heightKey;

  /// Storage path for cache
  final Future<Directory> storagePath;

  /// Enable debug logs
  final bool enableLog;

  ImageCacheConfig({
    this.widthKey = DEFAULT_WIDTH_KEY,
    this.heightKey = DEFAULT_HEIGHT_KEY,
    this.storagePath,
    this.enableLog = false,
  });

  static const DEFAULT_WIDTH_KEY = 'oci_width';
  static const DEFAULT_HEIGHT_KEY = 'oci_height';
}
