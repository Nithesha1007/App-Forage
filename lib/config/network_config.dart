import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class NetworkConfig {
  static const int _backendPort = 3001;

  static String getBackendBaseUrl({String? overrideIp}) {
    if (overrideIp != null) {
      return 'http://$overrideIp:$_backendPort';
    }

    // Web app in browser → always localhost (backend runs on same PC)
    if (kIsWeb) {
      return 'http://localhost:$_backendPort';
    }

    // Android emulator → 10.0.2.2 maps to host machine localhost
    // Android real device → also try localhost via adb reverse, or use PC IP
    if (!kIsWeb && _isAndroid()) {
      return 'http://10.0.2.2:$_backendPort';
    }

    // Windows / macOS / Linux desktop → localhost
    return 'http://localhost:$_backendPort';
  }

  static bool _isAndroid() {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }
}
