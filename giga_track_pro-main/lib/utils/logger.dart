// utils/logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static final bool _isDebugMode = kDebugMode;

  static void info(String message) {
    if (_isDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  static void success(String message) {
    if (_isDebugMode) {
      debugPrint('✅ $message');
    }
  }

  static void warning(String message) {
    if (_isDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      debugPrint('❌ $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack trace: $stackTrace');
      }
    }
  }
}