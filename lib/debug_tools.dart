import 'dart:developer' as developer;

abstract class Logger {
  static bool enableLogging = false;
  static const TAG = "optimized_image_cache";
}

void log(String message) {
  if (Logger.enableLogging) {
    developer.log(message, name: Logger.TAG);
  }
}
