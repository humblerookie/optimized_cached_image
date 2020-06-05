import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:path/path.dart' as p;

import '../cache_manager/resize_cache_manager.dart';
import '../image_cache_manager.dart';

class ResizeImageTransformer extends ImageTransformer {
  static const SIZE_PARAM = 'size';
  final _TAG = (ResizeImageTransformer).toString();
  final ResizeImageCacheConfig config;

  final tmpFileSuffix = '.tmp';

  ResizeImageTransformer(this.config);

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
  Future<FileInfo> transform(FileInfo info, Map params) async {
    log('transform', name: _TAG);

    BoxConstraints constraints = params[SIZE_PARAM];

    File file = info.file;
    if (file.existsSync()) {
      ImageProperties imageProperties =
          await FlutterNativeImage.getImageProperties(file.path);

      log('transform, src dimension width: ${imageProperties.width} and height: ${imageProperties.height}',
          name: _TAG);

      var width = constraints.maxWidth;
      var height = constraints.maxHeight;

      await _scaleImageFile(info, width?.toInt(), height?.toInt());
    }
    return info;
  }

  Future<FileInfo> _scaleImageFile(FileInfo info, int width, int height) async {
    File file = info.file;
    String extension = p.extension(file.path) ?? '';
    final format = _compressionFormats[extension] ?? CompressFormat.png;
    final destPath = file.path + tmpFileSuffix + _extensionFormats[format];
    final tmpFile = File(destPath);
    final srcSize = file.lengthSync();
    final screen = window.physicalSize;
    File resizedFile = await FlutterImageCompress.compressAndGetFile(
        file.path, tmpFile.path,
        minWidth: width ?? screen.width.toInt(),
        minHeight: height ?? screen.height.toInt(),
        format: format,
        quality: 75);

    if (resizedFile == null) return info;

    ImageProperties imageProperties =
        await FlutterNativeImage.getImageProperties(resizedFile.path);

    log('_scaleImageFile, scaled to a dimension, width: ${imageProperties.width} and height: ${imageProperties.height}',
        name: _TAG);
    if (resizedFile.lengthSync() < srcSize) {
      resizedFile.renameSync(file.path);
    } else {
      resizedFile.deleteSync();
    }

    return info;
  }
}
