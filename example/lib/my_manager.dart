import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MyManager extends BaseCacheManager {
  static const key = "libCachedImageData";

  static MyManager _instance;

  /// The DefaultCacheManager that can be easily used directly. The code of
  /// this implementation can be used as inspiration for more complex cache
  /// managers.
  factory MyManager() {
    if (_instance == null) {
      _instance = MyManager._();
    }
    return _instance;
  }

  MyManager._() : super(key);

  Future<String> getFilePath() async {
    var directory = await getExternalStorageDirectory();
    return p.join(directory.path, key);
  }
}
