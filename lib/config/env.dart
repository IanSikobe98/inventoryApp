import 'package:flutter/foundation.dart';

/// Where the Spring Boot API lives.
///
/// Override at run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
///
/// Defaults:
///  - Android emulator -> http://10.0.2.2:8080 (the emulator's alias for your computer)
///  - everything else (Chrome, iOS simulator, desktop) -> http://localhost:8080
class Env {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) { 
      return 'http://10.0.2.2:8080';
    }
    return 'http://10.248.194.45:8056';
  }
}
