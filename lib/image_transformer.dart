import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

import 'image_cache_manager.dart';

class DefaultImageTransformer extends ImageTransformer {
  final ImageCacheConfig config;

  DefaultImageTransformer(this.config);

  final tmpFileSuffix = '_tmp';

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
    final dimens = _getDimensionsFromUrl(uri);
    await _scaleImageFile(info, dimens[0], dimens[1]);
    return info;
  }

  List<int> _getDimensionsFromUrl(String url) {
    Uri uri = Uri.parse(url);
    String heightParam = uri.queryParameters[config.heightKey];
    int height = heightParam != null ? int.tryParse(heightParam) : null;
    String widthParam = uri.queryParameters[config.widthKey];
    int width = widthParam != null ? int.tryParse(widthParam) : null;
    return [width, height];
  }

  Future<FileInfo> _scaleImageFile(FileInfo info, int width, int height) async {
    File file = info.file;
    final screen = window.physicalSize;
    var minWidth = width ?? screen.width.toInt();
    var minHeight = height ?? screen.height.toInt();
    if (minWidth == 0) {
      minWidth = screen.width.toInt();
    }
    if (minHeight == 0) {
      minHeight = screen.height.toInt();
    }
    if (file.existsSync()) {
      String extension = p.extension(file.path) ?? '';
      final format = _compressionFormats[extension] ?? CompressFormat.png;
      final tmpFile = getTempFile(file, format);
      final srcSize = file.lengthSync();
      File resizedFile = await FlutterImageCompress.compressAndGetFile(file.path, tmpFile.path,
          minWidth: minWidth, minHeight: minHeight, format: format);
      if (resizedFile != null && resizedFile.existsSync()) {
        if (resizedFile.lengthSync() < srcSize) {
          resizedFile.renameSync(file.path);
        } else {
          resizedFile.deleteSync();
        }
      }
    }
    return info;
  }

  File getTempFile(File file, CompressFormat format) {
    final directory = file.parent;
    final destPath = directory.path +
        "/" +
        p.basenameWithoutExtension(file.path) +
        tmpFileSuffix +
        _extensionFormats[format];
    return File(destPath);
  }
}
