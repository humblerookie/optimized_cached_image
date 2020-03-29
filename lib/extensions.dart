import 'image_cache_manager.dart';

// ignore: implementation_imports
import 'package:flutter_cache_manager/src/cache_object.dart';

extension ImageUtil on String {
  String getSizedFormattedUrl(ImageCacheConfig config,
      {int width, int height}) {
    var uri = Uri.tryParse(this);
    if (uri != null) {
      Map<String, String> queryParams =
          Map<String, String>.from(uri.queryParameters);
      if (width != null) {
        queryParams[config.widthKey] = width.toString();
      }
      if (height != null) {
        queryParams[config.heightKey] = height.toString();
      }
      uri = uri.replace(queryParameters: queryParams);
    }
    return uri?.toString() ?? "";
  }
}

extension Constants on CacheObject {
  String tmpFileSuffix() => "_tmp";
}

extension UriUtil on Uri {
  int height(ImageCacheConfig config) {
    String heightParam = this.queryParameters[config.heightKey];
    return heightParam != null ? int.tryParse(heightParam) : null;
  }

  int width(ImageCacheConfig config) {
    String widthParam = this.queryParameters[config.widthKey];
    return widthParam != null ? int.tryParse(widthParam) : null;
  }
}
