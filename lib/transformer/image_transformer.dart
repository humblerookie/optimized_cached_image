import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:optimized_cached_image/transformer/scale_info.dart';
import 'package:path/path.dart' as p;
import 'package:sprintf/sprintf.dart';

import '../debug_tools.dart';
import '../image_cache_manager.dart';

class DefaultImageTransformer extends ImageTransformer {
  final ImageCacheConfig config;

  DefaultImageTransformer(this.config);

  final tmpFileSuffix = '_w%d_h%d';

  final _compressionFormats = {
    '.jpg': CompressFormat.jpeg,
    '.jpeg': CompressFormat.jpeg,
    '.webp': CompressFormat.webp,
    '.png': CompressFormat.png,
    '.heic': CompressFormat.heic,
  };
  final _extensionFormats = {
    CompressFormat.jpeg: '.jpg',
    CompressFormat.webp: '.webp',
    CompressFormat.png: '.png',
    CompressFormat.heic: '.heic'
  };

  @override
  Future<FileInfo> transform(FileInfo info, String uri) async {
    final value = await _scaleImageFile(info, uri);
    return value;
  }

  List<int> _getDimensionsFromUrl(String url) {
    Uri uri = Uri.parse(url);
    String heightParam = uri.queryParameters[config.heightKey];
    int height = heightParam != null ? int.tryParse(heightParam) : null;
    String widthParam = uri.queryParameters[config.widthKey];
    int width = widthParam != null ? int.tryParse(widthParam) : null;

    final screen = window.physicalSize;
    width = width ?? screen.width.toInt();
    height = height ?? screen.height.toInt();
    if (width == 0) {
      width = screen.width.toInt();
    }
    if (height == 0) {
      height = screen.height.toInt();
    }
    return [width, height];
  }

  Future<FileInfo> _scaleImageFile(FileInfo info, String url) async {
    FileInfo fileInfo = info;
    File file = fileInfo.file;

    log("Scaling file.. ${fileInfo.originalUrl}");
    File resizedFile = file;
    if (file.existsSync()) {
      final scaleInfo = getScaledFileInfo(file, url);
      final srcSize = file.lengthSync();
      log("Dimensions width=${scaleInfo.width}, height=${scaleInfo.height}, format ${scaleInfo.compressFormat}");
      resizedFile = await FlutterImageCompress.compressAndGetFile(
          file.path, scaleInfo.file.path,
          minWidth: scaleInfo.width,
          minHeight: scaleInfo.height,
          format: scaleInfo.compressFormat,
          quality: 90);
      if (resizedFile != null && resizedFile.existsSync()) {
        if (resizedFile.lengthSync() < srcSize) {
          log("Resized success ${fileInfo.originalUrl}");
        } else {
          log("Resized image is bigger, deleting and using original ${fileInfo.originalUrl}");
          resizedFile.deleteSync();
          resizedFile = file;
        }
      } else {
        resizedFile = file;
        log("Resize Failure for ${fileInfo.originalUrl}");
      }
    }
    fileInfo = FileInfo(
        resizedFile, fileInfo.source, fileInfo.validTill, fileInfo.originalUrl);
    return fileInfo;
  }

  @override
  ScaleInfo getScaledFileInfo(File file, String url) {
    final dimens = _getDimensionsFromUrl(url);
    final width = dimens[0];
    final height = dimens[1];

    final format = _getCompressionFormat(file);

    final directory = file.parent;
    final destPath = directory.path +
        "/" +
        p.basenameWithoutExtension(file.path) +
        sprintf(tmpFileSuffix, [width, height]) +
        _extensionFormats[format];
    final scaleFile = File(destPath);
    return ScaleInfo(scaleFile, width, height, format);
  }

  CompressFormat _getCompressionFormat(File file) {
    String extension = p.extension(file.path) ?? '';
    return _compressionFormats[extension] ?? CompressFormat.png;
  }
}
