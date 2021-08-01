import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:optimized_cached_image/src/cache/image_cache_manager.dart';

/// The DefaultCacheManager that can be easily used directly. The code of
/// this implementation can be used as inspiration for more complex cache
/// managers.
class DefaultImageCacheManager extends CacheManager with OicImageCacheManager {
  static const key = 'libCachedImageData';

  static DefaultImageCacheManager? _instance;
  factory DefaultImageCacheManager() {
    _instance ??= DefaultImageCacheManager._();
    return _instance!;
  }
  DefaultImageCacheManager._() : super(Config(key));
}
