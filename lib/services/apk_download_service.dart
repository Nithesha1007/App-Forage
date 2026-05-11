import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
// Import dart:html for web download functionality
import 'dart:html' as html;

class ApkDownloadService {
  static Future<void> downloadApk({
    required String downloadUrl,
    required Function(double) onProgress,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (kIsWeb) {
      // Web-specific download using dart:html
      try {
        _downloadApkWeb(downloadUrl, onProgress, onSuccess, onError);
      } catch (e) {
        onError('Web download failed: $e');
      }
      return;
    }

    // Mobile/Desktop download using Dio
    _downloadApkMobile(downloadUrl, onProgress, onSuccess, onError);
  }

  /// Download APK on web using dart:html
  static void _downloadApkWeb(
    String downloadUrl,
    Function(double) onProgress,
    Function(String) onSuccess,
    Function(String) onError,
  ) {
    try {
      // Create an anchor element for web download
      final anchor = html.AnchorElement(href: downloadUrl)
        ..setAttribute('download', 'app-release.apk')
        ..style.display = 'none';

      // Simulate progress (web downloads don't provide real progress)
      onProgress(0.5);

      // Add to document, click, and remove
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      onProgress(1.0);
      onSuccess('app-release.apk');
    } catch (e) {
      onError('Failed to download APK on web: $e');
    }
  }

  /// Download APK on mobile/desktop using Dio
  static Future<void> _downloadApkMobile(
    String downloadUrl,
    Function(double) onProgress,
    Function(String) onSuccess,
    Function(String) onError,
  ) async {
    try {
      // Request storage permission
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        onError('Storage permission denied');
        return;
      }

      // Request install packages permission (Android 12+)
      final installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        onError('Install packages permission denied');
        return;
      }

      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/app-release.apk';
      final dio = Dio();

      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) onProgress(received / total);
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/vnd.android.package-archive'},
        ),
      );
      onSuccess(savePath);
      await OpenFile.open(savePath);
    } catch (e) {
      onError('Download failed: $e');
    }
  }
}
