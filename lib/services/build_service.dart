import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import '../models/project_model.dart';

// Conditional import for web
import 'dart:html' as html show AnchorElement, document;
import 'dart:async';

/// BuildService handles real APK build requests to backend server
/// ⚠️ IMPORTANT: Backend must be running BEFORE starting a build
/// The app will NOT attempt to auto-start the backend.
/// Start backend manually: cd backend && npm start
class BuildService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// ✅ Verify backend is running before attempting to build
  /// Returns null if connection OK
  /// Returns error message if backend is not reachable
  ///
  /// ⚠️ This does NOT attempt to start the backend automatically.
  /// Backend must be started manually before calling this method.
  ///
  /// Usage:
  /// ```dart
  /// final error = await BuildService.checkBackendConnection();
  /// if (error != null) {
  ///   // Show error to user
  ///   showDialog(...);
  ///   return;
  /// }
  /// // Backend is running, safe to proceed
  /// ```
  static Future<String?> checkBackendConnection({
    void Function(String)? onStatusUpdate,
  }) async {
    try {
      // Use the configured backend base URL from ApiConfig
      final healthUrl = '$_baseUrl/health';

      onStatusUpdate?.call('⏳ Checking backend connection at: $healthUrl');

      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('✅ Backend is running and reachable at: $healthUrl');
        onStatusUpdate?.call('✅ Backend is running!');
        return null; // Connection OK
      }

      // Unexpected status code
      debugPrint(
        '❌ Backend health check returned unexpected status: ${response.statusCode}',
      );
      return _buildBackendNotRunningError();
    } on http.ClientException catch (e) {
      debugPrint('❌ Failed to connect to backend: ${e.message}');
      return _buildBackendNotRunningError();
    } catch (e) {
      debugPrint('❌ Backend connection error: $e');
      return _buildBackendNotRunningError();
    }
  }

  /// Generate a simple error message when backend is not reachable
  static String _buildBackendNotRunningError() {
    final url = _baseUrl;
    return 'Backend server is not running.\n\nExpected at: $url\n\nTo start it:\n1. Open a terminal\n2. cd backend\n3. node build-server.js\n\nKeep that terminal open, then click Build again.';
  }

  /// Export full project configuration as JSON for the build server.
  /// Includes boundTable/boundField so the code generator can wire up
  /// Firestore reads (listview) and writes (button addRecord) in the APK.
  static Map<String, dynamic> exportProjectConfig(ProjectModel project) {
    return {
      'id': project.id,
      'name': project.name,
      'createdAt': project.createdAt.toIso8601String(),
      'theme': project.theme.toMap(),
      'backendConfig': {
        'tables': project.backendConfig.tables
            .map((t) => t.toMap())
            .toList(),
        'emailAuth': project.backendConfig.emailAuth,
        'googleAuth': project.backendConfig.googleAuth,
        'phoneAuth': project.backendConfig.phoneAuth,
      },
      'screens': project.screens
          .map(
            (screen) => {
              'id': screen.id,
              'name': screen.name,
              'widgets': screen.widgets
                  .map((w) => _exportWidget(w))
                  .toList(),
            },
          )
          .toList(),
    };
  }

  static Map<String, dynamic> _exportWidget(dynamic w) => {
    'id': w.id,
    'type': w.type,
    'x': w.x,
    'y': w.y,
    'width': w.width,
    'height': w.height,
    'properties': w.properties,
    'boundTable': w.boundTable,   // which table this widget reads from
    'boundField': w.boundField,   // which field (for single-field widgets)
    'children': (w.children as List).map((c) => _exportWidget(c)).toList(),
  };

  /// Start APK build on backend (non-blocking, returns immediately)
  /// Returns buildId for tracking
  /// ⚠️ IMPORTANT: checkBackendConnection() must be called first and return null
  /// This method does NOT check backend availability - it assumes it's running.
  static Future<String> startApkBuild(
    ProjectModel project, {
    void Function(String)? onStatusUpdate,
  }) async {
    try {
      // ⚠️ CRITICAL: Check if backend is reachable FIRST
      onStatusUpdate?.call('⏳ Checking backend connection...');
      final connectionError = await checkBackendConnection(
        onStatusUpdate: onStatusUpdate,
      );
      if (connectionError != null) {
        throw Exception(connectionError);
      }

      onStatusUpdate?.call('📤 Submitting build request to backend...');
      final config = exportProjectConfig(project);

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/build/submit'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(config),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200 && response.statusCode != 202) {
        throw Exception(
          'Build start failed: ${response.statusCode} ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final buildId = data['buildId'] as String?;
      if (buildId == null) {
        throw Exception('No buildId in response');
      }

      onStatusUpdate?.call('✅ Build queued (ID: $buildId)');
      return buildId;
    } catch (e) {
      rethrow;
    }
  }

  /// Poll build status until completion or failure
  /// Returns download URL when complete
  /// Status values: "pending" | "building" | "complete" | "failed"
  static Future<String> pollBuildStatus(
    String buildId,
    void Function(double) onProgress,
    void Function(String) onLog,
  ) async {
    const maxAttempts = 360; // 30 minutes with 5-second intervals
    const pollInterval = Duration(seconds: 5);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        // Use configured base URL for both web and mobile
        // This respects the IP override and network configuration
        final statusUrl = '$_baseUrl/api/build/status/$buildId';

        final response = await http
            .get(
              Uri.parse(statusUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status'] as String;
          final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
          final logs = List<String>.from(data['logs'] as List? ?? []);

          // Update progress
          onProgress(progress / 100);

          // Add new logs
          for (final log in logs) {
            onLog(log);
          }

          // Build completed successfully (status = "complete")
          if (status == 'complete') {
            final downloadUrl = data['downloadUrl'] as String?;
            if (downloadUrl == null || downloadUrl.isEmpty) {
              throw Exception('Build completed but no download URL provided');
            }
            return downloadUrl;
          }

          // Build failed
          if (status == 'failed') {
            final error = data['error'] as String? ?? 'Unknown error';
            throw Exception('Build failed: $error');
          }
        }

        // Wait before next poll
        await Future.delayed(pollInterval);
      } catch (e) {
        rethrow;
      }
    }

    throw Exception('Build timeout: No response after 30 minutes');
  }

  /// Download APK directly in web browser using dart:html
  /// This is the only way to download files in Flutter web
  /// Safe to call - doesn't throw errors in web context
  static void downloadApkWeb(String downloadUrl) {
    try {
      final anchor = html.AnchorElement()
        ..href = downloadUrl
        ..setAttribute('download', 'app-release.apk')
        ..style.display = 'none';

      html.document.body!.children.add(anchor);
      anchor.click();
      anchor.remove();

      debugPrint('✅ Web download initiated: $downloadUrl');
    } catch (e) {
      debugPrint('❌ Web download error: $e');
      rethrow;
    }
  }

  /// Auto-download APK file and install it automatically
  /// Shows progress and automatically triggers installation
  static Future<void> autoDownloadAndInstall({
    required String downloadUrl,
    required void Function(double progress, String status) onProgress,
    required void Function(String filePath) onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      onProgress(0, '📥 Starting APK download...');

      // Handle web platform differently - use browser download
      if (kIsWeb) {
        try {
          onProgress(0.5, '🌐 Preparing download for web browser...');
          downloadApkWeb(downloadUrl);
          await Future.delayed(const Duration(milliseconds: 500));
          onProgress(1.0, '✅ APK download started!');
          onSuccess('web_download');
          return;
        } catch (e) {
          onError('Web download failed: $e');
          return;
        }
      }

      // Handle mobile/desktop platforms with dio
      final dio = Dio();
      final downloadDir = await getApplicationDocumentsDirectory();
      final fileName = 'app_forge_build.apk';
      final savePath = '${downloadDir.path}/$fileName';

      // Download with progress updates
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final percentage = (progress * 100).toStringAsFixed(0);
            onProgress(progress, '📥 Downloading... $percentage%');
          }
        },
        deleteOnError: true,
      );

      onProgress(1.0, '✅ Download complete!');
      onSuccess(savePath);

      // Auto-trigger installation
      onProgress(1.0, '⚙️ Opening installer...');
      await Future.delayed(const Duration(milliseconds: 500));

      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done) {
        onError(
          'Failed to open APK installer: ${result.message}. File saved at: $savePath',
        );
      } else {
        onProgress(1.0, '🎉 APK installer opened!');
      }
    } catch (e) {
      onError('Download and install failed: $e');
    }
  }

  /// Auto-download APK with retries
  /// Retries up to 3 times on failure
  static Future<void> autoDownloadAndInstallWithRetry({
    required String downloadUrl,
    required void Function(double progress, String status) onProgress,
    required void Function(String filePath) onSuccess,
    required void Function(String error) onError,
  }) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await autoDownloadAndInstall(
          downloadUrl: downloadUrl,
          onProgress: onProgress,
          onSuccess: onSuccess,
          onError: (error) {
            if (attempt < maxRetries) {
              onProgress(0, '🔄 Retry attempt $attempt/$maxRetries...');
            }
          },
        );
        return; // Success
      } catch (e) {
        if (attempt == maxRetries) {
          onError(
            'Download failed after $maxRetries attempts. Last error: $e. Please download manually from: $downloadUrl',
          );
        }
        // Continue to next retry
      }
    }
  }

  /// Cancel an ongoing build
  static Future<void> cancelBuild(String buildId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/build/cancel/$buildId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel build: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get build logs for debugging
  static Future<List<String>> getBuildLogs(String buildId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/build/logs/$buildId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['logs'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
