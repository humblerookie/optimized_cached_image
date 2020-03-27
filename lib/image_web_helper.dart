import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/src/cache_object.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/file_fetcher.dart';
import 'package:flutter_cache_manager/src/file_info.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'image_cache_manager.dart';

///
/// A image cache helper that stores and transforms cache on disk as per specified dimensions
///

class ImageWebHelper {
  final ImageCacheConfig imageCacheConfig;
  CacheStore _store;
  FileFetcher _fileFetcher;
  Map<String, Future<FileInfo>> _memCache;

  ImageWebHelper(store, fileFetcher, this.imageCacheConfig) {
    _store = store;
    _memCache = Map();
    if (_fileFetcher == null) {
      _fileFetcher = _defaultHttpGetter;
    }
  }

  ///Download the file from the url
  Future<FileInfo> downloadFile(String url,
      {Map<String, String> authHeaders, bool ignoreMemCache = false}) async {
    if (!_memCache.containsKey(url) || ignoreMemCache) {
      var completer = Completer<FileInfo>();
      () async {
        try {
          final cacheObject =
              await _downloadRemoteFile(url, authHeaders: authHeaders);
          completer.complete(cacheObject);
        } catch (e) {
          completer.completeError(e);
        } finally {
          _memCache.remove(url);
        }
      }();

      _memCache[url] = completer.future;
    }
    return _memCache[url];
  }

  ///Download the file from the url
  Future<FileInfo> _downloadRemoteFile(String url,
      {Map<String, String> authHeaders}) async {
    var cacheObject = await _store.retrieveCacheData(url);
    if (cacheObject == null) {
      cacheObject = CacheObject(url);
    }

    var headers = Map<String, String>();
    if (authHeaders != null) {
      headers.addAll(authHeaders);
    }

    if (cacheObject.eTag != null) {
      headers["If-None-Match"] = cacheObject.eTag;
    }

    var success = false;

    var response = await _fileFetcher(url, headers: headers);
    success = await _handleHttpResponse(response, cacheObject, url);

    if (!success) {
      throw HttpException(
          "No valid statuscode. Statuscode was ${response?.statusCode}");
    }

    _store.putFile(cacheObject);
    var filePath = p.join(await _store.filePath, cacheObject.relativePath);

    return FileInfo(
        File(filePath), FileSource.Online, cacheObject.validTill, url);
  }

  Future<FileFetcherResponse> _defaultHttpGetter(String url,
      {Map<String, String> headers}) async {
    var httpResponse = await http.get(url, headers: headers);
    return HttpFileFetcherResponse(httpResponse);
  }

  Future<bool> _handleHttpResponse(
      FileFetcherResponse response, CacheObject cacheObject, String url) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      var basePath = await _store.filePath;
      _setDataFromHeaders(cacheObject, response);
      var path = p.join(basePath, cacheObject.relativePath);

      var folder = File(path).parent;
      if (!(await folder.exists())) {
        folder.createSync(recursive: true);
      }
      final compressedBytes =
          await getCompressedResponse(response.bodyBytes, url);
      await File(path).writeAsBytes(Uint8List.fromList(compressedBytes));
      return true;
    }
    if (response.statusCode == 304) {
      await _setDataFromHeaders(cacheObject, response);
      return true;
    }
    return false;
  }

  _setDataFromHeaders(
      CacheObject cacheObject, FileFetcherResponse response) async {
    //Without a cache-control header we keep the file for a week
    var ageDuration = Duration(days: 7);

    if (response.hasHeader("cache-control")) {
      var cacheControl = response.header("cache-control");
      var controlSettings = cacheControl.split(", ");
      controlSettings.forEach((setting) {
        if (setting.startsWith("max-age=")) {
          var validSeconds = int.tryParse(setting.split("=")[1]) ?? 0;
          if (validSeconds > 0) {
            ageDuration = Duration(seconds: validSeconds);
          }
        }
      });
    }

    cacheObject.validTill = DateTime.now().add(ageDuration);

    if (response.hasHeader("etag")) {
      cacheObject.eTag = response.header("etag");
    }

    var fileExtension = "";
    if (response.hasHeader("content-type")) {
      var type = response.header("content-type").split("/");
      if (type.length == 2) {
        fileExtension = ".${type[1]}";
      }
    }

    var oldPath = cacheObject.relativePath;
    if (oldPath != null && !oldPath.endsWith(fileExtension)) {
      _removeOldFile(oldPath);
      cacheObject.relativePath = null;
    }

    if (cacheObject.relativePath == null) {
      cacheObject.relativePath = "${Uuid().v1()}$fileExtension";
    }
  }

  _removeOldFile(String relativePath) async {
    var path = p.join(await _store.filePath, relativePath);
    var file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<int>> getCompressedResponse(Uint8List bodyBytes, String url) {
    final uri = Uri.dataFromString(url);
    int height = int.tryParse(uri.queryParameters[imageCacheConfig.heightKey]);
    int width = int.tryParse(uri.queryParameters[imageCacheConfig.widthKey]);
    final data = bodyBytes.toList();
    if (height != null && width != null) {
      return FlutterImageCompress.compressWithList(
        data,
        minHeight: height,
        minWidth: width,
      );
    } else if (height != null) {
      return FlutterImageCompress.compressWithList(
        data,
        minHeight: height,
      );
    } else {
      return FlutterImageCompress.compressWithList(
        data,
        minWidth: width,
      );
    }
  }
}
