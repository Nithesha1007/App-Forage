import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Conditional import of dart:io for desktop platforms only
import 'dart:io' if (kIsWeb) 'dart:async' show Process, Directory;

/// BackendStartupService handles automatic backend server startup and health checks
class BackendStartupService {
  static const Duration _healthCheckTimeout = Duration(seconds: 5);
  static const Duration _startupWaitTime = Duration(seconds: 3);
  static const int _maxRetries = 5;
  static const String _backendDirectoryPath = 'backend';

  static dynamic _backendProcess;
  static bool _isStartupInProgress = false;

  /// Check if backend server is running by calling the health endpoint
  static Future<bool> isBackendRunning() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.healthEndpoint))
          .timeout(_healthCheckTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get the health status of the backend
  /// Returns { "status": "running" } if healthy
  static Future<Map<String, dynamic>?> getHealthStatus() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.healthEndpoint))
          .timeout(_healthCheckTimeout);

      if (response.statusCode == 200) {
        return {'status': 'running'};
      }
    } catch (e) {
      // Silently fail - backend not responding
    }
    return null;
  }

  /// Start the backend server automatically
  /// Returns true if successful, false otherwise
  /// Note: Only attempts to start backend on desktop platforms
  static Future<bool> startBackendServer() async {
    // Prevent multiple simultaneous startup attempts
    if (_isStartupInProgress) {
      debugPrint('⏳ Backend startup already in progress...');
      return false;
    }

    _isStartupInProgress = true;

    try {
      // Web platforms cannot start processes - skip startup and assume backend is running
      if (kIsWeb) {
        debugPrint('🌐 Running on web platform - skipping backend startup');
        debugPrint(
          '✅ Backend must be started independently (Node/Express server)',
        );
        _isStartupInProgress = false;
        return true;
      }

      // Check if already running
      if (await isBackendRunning()) {
        debugPrint(
          '✅ Backend is already running on port ${ApiConfig.backendPort}',
        );
        _isStartupInProgress = false;
        return true;
      }

      debugPrint('🔄 Backend not responding, attempting to start...');

      // Get the backend directory path
      final backendDir = _getBackendDirectory();
      if (backendDir == null) {
        debugPrint('❌ Could not determine backend directory');
        _isStartupInProgress = false;
        return false;
      }

      debugPrint('📁 Backend directory: $backendDir');

      // Start the backend server process (desktop only)
      try {
        _backendProcess = await Process.start('npm', [
          'start',
        ], workingDirectory: backendDir);

        debugPrint(
          '🚀 Backend server process started (PID: ${_backendProcess?.pid})',
        );

        // Wait for the server to initialize
        await Future.delayed(_startupWaitTime);

        // Retry health checks with exponential backoff
        for (int attempt = 0; attempt < _maxRetries; attempt++) {
          if (await isBackendRunning()) {
            debugPrint('✅ Backend started successfully!');
            _isStartupInProgress = false;
            return true;
          }

          if (attempt < _maxRetries - 1) {
            final waitTime = Duration(seconds: 2 + (attempt * 2));
            debugPrint(
              '⏳ Retry ${attempt + 1}/$_maxRetries in ${waitTime.inSeconds}s...',
            );
            await Future.delayed(waitTime);
          }
        }

        debugPrint(
          '❌ Backend startup failed - server not responding after retries',
        );
      } catch (e) {
        debugPrint('❌ Failed to start backend process: $e');
      }

      _isStartupInProgress = false;
      return false;
    } catch (e) {
      debugPrint('❌ Error starting backend: $e');
      _isStartupInProgress = false;
      return false;
    }
  }

  /// Stop the backend server
  static Future<void> stopBackendServer() async {
    try {
      if (kIsWeb) {
        debugPrint('🌐 Web platform - backend is managed externally');
        return;
      }

      if (_backendProcess != null) {
        debugPrint(
          '⛔ Stopping backend server (PID: ${_backendProcess?.pid})...',
        );
        _backendProcess?.kill();
        _backendProcess = null;
        debugPrint('✅ Backend server stopped');
      }
    } catch (e) {
      debugPrint('❌ Error stopping backend: $e');
    }
  }

  /// Get the backend directory based on fixed configuration
  /// Uses relative path 'backend' from project root
  /// Only works on desktop platforms
  static String? _getBackendDirectory() {
    // Web platform cannot access file system
    if (kIsWeb) {
      return null;
    }

    try {
      // Try to use dart:io (only on non-web)
      // First check relative to current working directory
      final dir1 = Directory(_backendDirectoryPath);
      if (dir1.existsSync()) {
        debugPrint('✅ Found backend at: ${dir1.absolute.path}');
        return dir1.absolute.path;
      }

      // Try parent directory
      final dir2 = Directory('../$_backendDirectoryPath');
      if (dir2.existsSync()) {
        debugPrint('✅ Found backend at: ${dir2.absolute.path}');
        return dir2.absolute.path;
      }

      // Try two levels up
      final dir3 = Directory('../../$_backendDirectoryPath');
      if (dir3.existsSync()) {
        debugPrint('✅ Found backend at: ${dir3.absolute.path}');
        return dir3.absolute.path;
      }

      debugPrint('⚠️ Backend directory not found in expected locations');
      return null;
    } catch (e) {
      debugPrint('❌ Error finding backend directory: $e');
      return null;
    }
  }

  /// Check if backend process is still running
  static bool isBackendProcessRunning() {
    if (kIsWeb) {
      return false; // Web doesn't manage backend process
    }
    try {
      return _backendProcess != null && !_backendProcess!.kill();
    } catch (e) {
      return false;
    }
  }

  /// Get backend process info (for monitoring)
  static Map<String, dynamic> getBackendProcessInfo() {
    return {
      'isRunning': isBackendProcessRunning(),
      'pid': _backendProcess?.pid,
      'isStartupInProgress': _isStartupInProgress,
      'isWeb': kIsWeb,
    };
  }
}
