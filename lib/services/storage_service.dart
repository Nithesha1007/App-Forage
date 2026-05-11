import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
// Conditional import of dart:io (only used on non-web platforms)
import 'dart:io' if (kIsWeb) 'dart:async' show File;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Upload a file from disk ───────────────────────────────────────────────
  Future<String> uploadFile({
    required String userId,
    required File file,
    required String folder,
    String? customFileName,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('File upload from disk not supported on web');
    }
    final ext = p.extension(file.path);
    final fileName =
        customFileName ?? '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = _storage.ref('users/$userId/$folder/$fileName');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: _contentType(ext)),
    );
    return await task.ref.getDownloadURL();
  }

  // ── Upload raw bytes (e.g. from image_picker on web) ─────────────────────
  Future<String> uploadBytes({
    required String userId,
    required Uint8List bytes,
    required String folder,
    required String extension,
    String? customFileName,
  }) async {
    final fileName =
        customFileName ?? '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref('users/$userId/$folder/$fileName');

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentType('.$extension')),
    );
    return await task.ref.getDownloadURL();
  }

  // ── Upload a published app export ─────────────────────────────────────────
  Future<String> uploadAppExport({
    required String projectId,
    required File file,
    required String platform,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('File upload from disk not supported on web');
    }
    final ext = p.extension(file.path);
    final ref = _storage.ref('apps/$projectId/${platform}_export$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'application/octet-stream'),
    );
    return await task.ref.getDownloadURL();
  }

  // ── Upload a user profile photo ───────────────────────────────────────────
  Future<String> uploadProfilePhoto({
    required String userId,
    required File file,
  }) async {
    return uploadFile(
      userId: userId,
      file: file,
      folder: 'profile',
      customFileName: 'avatar.jpg',
    );
  }

  // ── Delete a file by its download URL ────────────────────────────────────
  Future<void> deleteByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // File may already be deleted — ignore
    }
  }

  // ── Delete all files in a folder ─────────────────────────────────────────
  Future<void> deleteFolder({
    required String userId,
    required String folder,
  }) async {
    try {
      final ref = _storage.ref('users/$userId/$folder');
      final result = await ref.listAll();
      await Future.wait(result.items.map((item) => item.delete()));
    } catch (_) {}
  }

  // ── Get download URL for a storage path ──────────────────────────────────
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ── Upload with progress callback ─────────────────────────────────────────
  Stream<double> uploadFileWithProgress({
    required String userId,
    required File file,
    required String folder,
    String? customFileName,
    required void Function(String downloadUrl) onComplete,
  }) async* {
    final ext = p.extension(file.path);
    final fileName =
        customFileName ?? '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = _storage.ref('users/$userId/$folder/$fileName');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: _contentType(ext)),
    );

    await for (final snapshot in task.snapshotEvents) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      yield progress;
      if (snapshot.state == TaskState.success) {
        final url = await snapshot.ref.getDownloadURL();
        onComplete(url);
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _contentType(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.zip':
        return 'application/zip';
      case '.json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }
}
