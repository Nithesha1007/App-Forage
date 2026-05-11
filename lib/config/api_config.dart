import 'package:flutter/foundation.dart';
import 'network_config.dart';

/// Central API configuration for the entire application
/// This ensures all HTTP calls use a consistent base URL across the app
///
/// ⚠️ IMPORTANT: Backend Connection Troubleshooting
/// If you see "Failed to fetch" errors, the app cannot reach the backend.
/// See NetworkConfig.getBackendConnectionGuide() for detailed setup instructions.
class ApiConfig {
  static const int backendPort = 3001;

  // Optional: Override IP for development/testing
  // Set this if auto-detection fails or you need a specific IP
  static String? _overrideIp;

  /// Set a manual override IP for the backend
  /// Useful if auto-detection fails or you need to test with a specific IP
  static void setBackendIpOverride(String ip) {
    _overrideIp = ip;
    debugPrint('✅ Backend IP override set to: $ip');
  }

  /// Clear the manual override and return to auto-detection
  static void clearBackendIpOverride() {
    _overrideIp = null;
    debugPrint('✅ Backend IP override cleared, using auto-detection');
  }

  /// Smart base URL selector that adapts to platform
  /// For web: Uses localhost or window.location.host
  /// For Android emulator: Uses 10.0.2.2 (special emulator bridge)
  /// For real devices: Uses detected system IP or override
  static String get baseUrl {
    return NetworkConfig.getBackendBaseUrl(overrideIp: _overrideIp);
  }

  // Specific endpoints (unified and normalized)
  static String get buildEndpoint => '$baseUrl/api/build/submit';
  static String get healthEndpoint => '$baseUrl/health';
  static String get buildStatusEndpoint => '$baseUrl/api/build/status';
  static String get downloadEndpoint => '$baseUrl/api/download';

  // Legacy: Keep emulator URLs for backwards compatibility
  static const String emulatorBaseUrl = 'http://10.0.2.2:3001';
  static const String emulatorHealthUrl = '$emulatorBaseUrl/health';
}
