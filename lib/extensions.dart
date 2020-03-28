import 'image_cache_manager.dart';

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
