import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// ignore: implementation_imports
import 'package:flutter_cache_manager/src/cache_object.dart';

// ignore: implementation_imports
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'image_web_helper.dart';
export 'package:optimized_cached_image/image_cache_manager.dart';

///
/// A cache manager that uses ImageWebHelper to store and transform images into cache
/// @author humblerookie
///
class ImageCacheManager {
  static ImageCacheManager _instance;
  final ImageCacheConfig cacheConfig;
  Future<String> _fileBasePath;
  final String _cacheKey = "libCachedImageData";
  Duration _maxAgeCacheObject;
  int _maxNrOfCacheObjects;

  ImageCacheManager._(this.cacheConfig, Duration maxAgeCacheObject,
      int maxNrOfCacheObjects, FileFetcher fileFetcher) {
    _fileBasePath = getFilePath();
    _maxAgeCacheObject = maxAgeCacheObject;
    _maxNrOfCacheObjects = maxNrOfCacheObjects;
    store = CacheStore(
        _fileBasePath, _cacheKey, _maxNrOfCacheObjects, _maxAgeCacheObject);
    webHelper = ImageWebHelper(store, null, cacheConfig);
  }

  factory ImageCacheManager(
      {ImageCacheConfig cacheConfig,
      Duration maxAgeCacheObject = const Duration(days: 30),
      int maxNrOfCacheObjects = 200,
      FileFetcher fileFetcher}) {
    if (_instance == null) {
      _instance = ImageCacheManager._(cacheConfig ?? ImageCacheConfig(),
          maxAgeCacheObject, maxNrOfCacheObjects, fileFetcher);
    }
    return _instance;
  }

  /// Store helper for cached files
  CacheStore store;

  /// Webhelper to download and store files
  ImageWebHelper webHelper;

  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, _cacheKey);
  }

  /// Get the file from the cache and/or online, depending on availability and age.
  /// Downloaded form [url], [headers] can be used for example for authentication.
  /// When a file is cached it is return directly, when it is too old the file is
  /// downloaded in the background. When a cached file is not available the
  /// newly downloaded file is returned.
  Future<File> getSingleFile(String url, {Map<String, String> headers}) async {
    var cacheFile = await getFileFromCache(url);
    if (cacheFile != null) {
      if (cacheFile.validTill.isBefore(DateTime.now())) {
        webHelper.downloadFile(url, authHeaders: headers);
      }
      return cacheFile.file;
    }
    try {
      var download = await webHelper.downloadFile(url, authHeaders: headers);
      return download.file;
    } catch (e) {
      return null;
    }
  }

  /// Get the file from the cache and/or online, depending on availability and age.
  /// Downloaded form [url], [headers] can be used for example for authentication.
  /// The files are returned as stream. First the cached file if available, when the
  /// cached file is too old the newly downloaded file is returned afterwards.
  Stream<FileInfo> getFile(String url, {Map<String, String> headers}) {
    var streamController = StreamController<FileInfo>();
    _pushFileToStream(streamController, url, headers);
    return streamController.stream;
  }

  _pushFileToStream(StreamController streamController, String url,
      Map<String, String> headers) async {
    FileInfo cacheFile;
    try {
      cacheFile = await getFileFromCache(url);
      if (cacheFile != null) {
        streamController.add(cacheFile);
      }
    } catch (e) {
      print(
          "CacheManager: Failed to load cached file for $url with error:\n$e");
    }
    if (cacheFile == null || cacheFile.validTill.isBefore(DateTime.now())) {
      try {
        var webFile = await webHelper.downloadFile(url, authHeaders: headers);
        if (webFile != null) {
          streamController.add(webFile);
        }
      } catch (e) {
        assert(() {
          print(
              "CacheManager: Failed to download file from $url with error:\n$e");
          return true;
        }());
        if (cacheFile == null && streamController.hasListener) {
          streamController.addError(e);
        }
      }
    }
    streamController.close();
  }

  ///Download the file and add to cache
  Future<FileInfo> downloadFile(String url,
      {Map<String, String> authHeaders, bool force = false}) async {
    return await webHelper.downloadFile(url,
        authHeaders: authHeaders, ignoreMemCache: force);
  }

  ///Get the file from the cache
  Future<FileInfo> getFileFromCache(String url) async {
    return await store.getFile(url);
  }

  ///Returns the file from memory if it has already been fetched
  FileInfo getFileFromMemory(String url) {
    return store.getFileFromMemory(url);
  }

  /// Put a file in the cache. It is recommended to specify the [eTag] and the
  /// [maxAge]. When [maxAge] is passed and the eTag is not set the file will
  /// always be downloaded again. The [fileExtension] should be without a dot,
  /// for example "jpg". When cache info is available for the url that path
  /// is re-used.
  /// The returned [File] is saved on disk.
  Future<File> putFile(String url, Uint8List fileBytes,
      {String eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = "file"}) async {
    var cacheObject = await store.retrieveCacheData(url);
    if (cacheObject == null) {
      var relativePath = "${Uuid().v1()}.$fileExtension";
      cacheObject = CacheObject(url, relativePath: relativePath);
    }
    cacheObject.validTill = DateTime.now().add(maxAge);
    cacheObject.eTag = eTag;

    var path = p.join(await getFilePath(), cacheObject.relativePath);
    var folder = File(path).parent;
    if (!(await folder.exists())) {
      folder.createSync(recursive: true);
    }
    var file = await File(path).writeAsBytes(fileBytes);

    store.putFile(cacheObject);

    return file;
  }

  /// Remove a file from the cache
  removeFile(String url) async {
    var cacheObject = await store.retrieveCacheData(url);
    if (cacheObject != null) {
      await store.removeCachedFile(cacheObject);
    }
  }

  /// Removes all files from the cache
  emptyCache() async {
    await store.emptyCache();
  }
}

///
/// This class is contains configuration information
/// for the meta params mapped as query params in the url being used.
///
class ImageCacheConfig {
  ///The url param name which holds the required width value
  final String widthKey;

  ///The url param name which holds the required height value
  final String heightKey;

  ImageCacheConfig(
      {this.widthKey = DEFAULT_WIDTH_KEY, this.heightKey = DEFAULT_HEIGHT_KEY});

  static const DEFAULT_WIDTH_KEY = "oci_width";
  static const DEFAULT_HEIGHT_KEY = "oci_height";
}
