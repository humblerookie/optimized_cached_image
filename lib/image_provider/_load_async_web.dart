import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import '../widgets.dart';

Future<ui.Codec> loadAsyncHtmlImage(
  OptimizedCacheImageProvider key,
  StreamController<ImageChunkEvent> chunkEvents,
  DecoderCallback decode,
) {
  final Uri resolved = Uri.base.resolve(key.url);

  // ignore: undefined_function
  return ui.webOnlyInstantiateImageCodecFromUrl(
    resolved,
    chunkCallback: (int bytes, int total) {
      chunkEvents.add(ImageChunkEvent(
          cumulativeBytesLoaded: bytes, expectedTotalBytes: total));
    },
  ) as Future<ui.Codec>; // ignore: undefined_function
}
