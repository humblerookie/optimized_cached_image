import 'dart:async';
import 'dart:io';

import 'package:file/local.dart' as fileIo;
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show FileInfo;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:sprintf/sprintf.dart';

import '../debug_tools.dart';
import 'scale_info.dart';

class DefaultImageTransformer extends ImageTransformer {
  DefaultImageTransformer();

  final tmpFileSuffix = '_w%d_h%d';

  final _compressionFormats = {
    '.jpg': CompressFormat.jpeg,
    '.jpeg': CompressFormat.jpeg,
    '.webp': CompressFormat.webp,
    '.gif': CompressFormat.webp,
    '.png': CompressFormat.png,
    '.heic': CompressFormat.heic
  };
  final _extensionFormats = {
    CompressFormat.jpeg: '.jpg',
    CompressFormat.webp: '.webp',
    CompressFormat.png: '.png',
    CompressFormat.heic: '.heic'
  };

  @override
  Future<FileInfo> transform(FileInfo info, int? width, int? height) async {
    final value = await _scaleImageFile(info, width, height);
    return value;
  }

  Future<FileInfo> _scaleImageFile(
      FileInfo info, int? width, int? height) async {
    FileInfo fileInfo = info;
    final file = fileInfo.file;
    log("Scaling file.. ${fileInfo.originalUrl}");
    var resizedFile = file;
    final canResize = file.existsSync() && (width != null || height != null);
    if (canResize) {
      final scaleInfo = getScaledFileInfo(file, width, height);
      final srcSize = file.lengthSync();
      log("Dimensions width=${scaleInfo.width}, height=${scaleInfo.height}, format ${scaleInfo.compressFormat}");
      await FlutterImageCompress.compressAndGetFile(
          file.path, scaleInfo.file.path,
          minWidth: scaleInfo.width,
          minHeight: scaleInfo.height,
          format: scaleInfo.compressFormat,
          quality: 90);
      final localFileSystem = fileIo.LocalFileSystem();
      resizedFile = localFileSystem.file(scaleInfo.file.path);

      if (resizedFile.existsSync()) {
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
  ScaleInfo getScaledFileInfo(File file, int? width, int? height) {
    final format = _getCompressionFormat(file);

    final directory = file.parent;
    final destPath = directory.path +
        "/" +
        p.basenameWithoutExtension(file.path) +
        sprintf(tmpFileSuffix, [width ?? 1, height ?? 1]) +
        _extensionFormats[format]!;
    final scaleFile = File(destPath);
    return ScaleInfo(scaleFile, width ?? 1, height ?? 1, format);
  }

  CompressFormat _getCompressionFormat(File file) {
    String extension = p.extension(file.path);
    return _compressionFormats[extension] ?? CompressFormat.png;
  }
}

abstract class ImageTransformer {
  Future<FileInfo> transform(FileInfo info, int? width, int? height);
  ScaleInfo getScaledFileInfo(File file, int width, int height);
}
