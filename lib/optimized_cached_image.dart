/// A flutter library for loading images from network, resizing and caching them
/// for memory sensitivity. This resizes and stores the images in cache based on
/// parent container constraints and hence loads images of lower size into
/// memory. This is heavily inspired by cached_network_image library.
library optimized_cached_image;

export 'package:flutter_cache_manager/src/result/download_progress.dart';
export 'src/oci_widget.dart';
export 'src/image_provider/optimized_cached_image_provider.dart';
export 'src/image_provider/multi_image_stream_completer.dart';
export 'src/debug_tools.dart';
