import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_model.dart';
import '../models/screen_model.dart';

/// DraftStorage manages draft project storage separately from main projects
/// Provides:
/// - Isolated storage for draft projects
/// - Version tracking and recovery
/// - Automatic cleanup of old drafts
/// - Quick access to recent drafts
class DraftStorage {
  static const String _draftBoxName = 'appforge_drafts';
  static const String _draftMetadataBoxName = 'appforge_draft_metadata';
  static const int _maxDraftsPerProject = 10;
  static const Duration _maxDraftAge = Duration(days: 30);

  Box? _draftBox;
  Box? _metadataBox;
  bool _isInitialized = false;

  /// Initialize draft storage
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _draftBox = await Hive.openBox(_draftBoxName);
      _metadataBox = await Hive.openBox(_draftMetadataBoxName);
      _isInitialized = true;
      debugPrint('✅ Draft storage initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize draft storage: $e');
      rethrow;
    }
  }

  /// Save a draft version of a project
  /// Returns the draft ID
  Future<String> saveDraft(ProjectModel project) async {
    if (_draftBox == null) await init();

    try {
      final draftId = '${project.id}_${DateTime.now().millisecondsSinceEpoch}';
      final key = '${project.userId}:$draftId';

      // Save draft data
      final draftData = {
        'id': draftId,
        'projectId': project.id,
        'userId': project.userId,
        'projectName': project.name,
        'savedAt': DateTime.now().toIso8601String(),
        'data': project.toJson(),
      };

      await _draftBox?.put(key, jsonEncode(draftData));

      // Update metadata
      await _updateDraftMetadata(project.userId, project.id, draftId);

      debugPrint('✅ Draft saved: $draftId');
      return draftId;
    } catch (e) {
      debugPrint('❌ Failed to save draft: $e');
      rethrow;
    }
  }

  /// Get all drafts for a specific project
  Future<List<DraftInfo>> getDraftsForProject(
    String projectId,
    String userId,
  ) async {
    if (_draftBox == null) await init();

    try {
      final drafts = <DraftInfo>[];

      for (var key in _draftBox?.keys ?? []) {
        final keyStr = key.toString();
        if (keyStr.startsWith('$userId:')) {
          final data = _draftBox?.get(key);
          if (data != null) {
            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              if (decoded['projectId'] == projectId) {
                drafts.add(DraftInfo.fromMap(decoded));
              }
            } catch (e) {
              debugPrint('⚠️ Failed to parse draft: $e');
            }
          }
        }
      }

      // Sort by saved date (newest first)
      drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      // Clean up old drafts beyond max limit
      if (drafts.length > _maxDraftsPerProject) {
        final toDelete = drafts.sublist(_maxDraftsPerProject);
        for (var draft in toDelete) {
          await deleteDraft(draft.draftId, userId);
        }
        return drafts.sublist(0, _maxDraftsPerProject);
      }

      return drafts;
    } catch (e) {
      debugPrint('❌ Failed to get drafts: $e');
      return [];
    }
  }

  /// Get the most recent draft for a project
  Future<DraftInfo?> getLatestDraft(String projectId, String userId) async {
    final drafts = await getDraftsForProject(projectId, userId);
    return drafts.isNotEmpty ? drafts.first : null;
  }

  /// Restore a project from a draft
  Future<ProjectModel?> restoreDraft(String draftId, String userId) async {
    if (_draftBox == null) await init();

    try {
      final key = '$userId:$draftId';
      final data = _draftBox?.get(key);

      if (data == null) {
        debugPrint('⚠️ Draft not found: $draftId');
        return null;
      }

      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final projectData = decoded['data'] as Map<String, dynamic>;

      return _projectFromJson(projectData);
    } catch (e) {
      debugPrint('❌ Failed to restore draft: $e');
      return null;
    }
  }

  /// Delete a specific draft
  Future<void> deleteDraft(String draftId, String userId) async {
    if (_draftBox == null) await init();

    try {
      final key = '$userId:$draftId';
      await _draftBox?.delete(key);
      debugPrint('✅ Draft deleted: $draftId');
    } catch (e) {
      debugPrint('❌ Failed to delete draft: $e');
    }
  }

  /// Delete all drafts for a project
  Future<void> deleteProjectDrafts(String projectId, String userId) async {
    try {
      final drafts = await getDraftsForProject(projectId, userId);
      for (var draft in drafts) {
        await deleteDraft(draft.draftId, userId);
      }
      debugPrint('✅ All drafts deleted for project: $projectId');
    } catch (e) {
      debugPrint('❌ Failed to delete project drafts: $e');
    }
  }

  /// Get all drafts for a user (across all projects)
  Future<List<DraftInfo>> getAllUserDrafts(String userId) async {
    if (_draftBox == null) await init();

    try {
      final drafts = <DraftInfo>[];

      for (var key in _draftBox?.keys ?? []) {
        final keyStr = key.toString();
        if (keyStr.startsWith('$userId:')) {
          final data = _draftBox?.get(key);
          if (data != null) {
            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              drafts.add(DraftInfo.fromMap(decoded));
            } catch (e) {
              debugPrint('⚠️ Failed to parse draft: $e');
            }
          }
        }
      }

      // Sort by saved date (newest first)
      drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return drafts;
    } catch (e) {
      debugPrint('❌ Failed to get all drafts: $e');
      return [];
    }
  }

  /// Clean up expired drafts (older than 30 days)
  Future<void> cleanupExpiredDrafts() async {
    try {
      final now = DateTime.now();
      final expiredCutoff = now.subtract(_maxDraftAge);

      final allDrafts = <String, DraftInfo>{};

      // Collect all drafts
      for (var key in _draftBox?.keys ?? []) {
        final data = _draftBox?.get(key);
        if (data != null) {
          try {
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            final draft = DraftInfo.fromMap(decoded);
            allDrafts[key.toString()] = draft;
          } catch (e) {
            debugPrint('⚠️ Failed to parse draft: $e');
          }
        }
      }

      // Delete expired drafts
      int deleted = 0;
      for (var entry in allDrafts.entries) {
        if (entry.value.savedAt.isBefore(expiredCutoff)) {
          await _draftBox?.delete(entry.key);
          deleted++;
        }
      }

      if (deleted > 0) {
        debugPrint('✅ Cleaned up $deleted expired drafts');
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup expired drafts: $e');
    }
  }

  /// Update draft metadata for quick access
  Future<void> _updateDraftMetadata(
    String userId,
    String projectId,
    String draftId,
  ) async {
    if (_metadataBox == null) return;

    try {
      final metaKey = '$userId:$projectId';
      final metadata = {
        'lastDraftId': draftId,
        'lastDraftTime': DateTime.now().toIso8601String(),
        'projectId': projectId,
        'userId': userId,
      };
      await _metadataBox?.put(metaKey, jsonEncode(metadata));
    } catch (e) {
      debugPrint('⚠️ Failed to update draft metadata: $e');
    }
  }

  /// Convert JSON map to ProjectModel
  ProjectModel _projectFromJson(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled',
      userId: map['userId'] ?? '',
      templateId: map['templateId'] ?? 'blank',
      templateName: map['templateName'] ?? '',
      screens: (map['screens'] as List? ?? [])
          .map((s) => AppScreen.fromMap(s as Map<String, dynamic>))
          .toList(),
      theme: ProjectTheme.fromMap(map['theme'] ?? {}),
      backendConfig: BackendConfig.fromMap(map['backendConfig'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'].toString())
          : DateTime.now(),
      status: map['status'] ?? 'draft',
      publishedUrl: map['publishedUrl'],
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    // Don't close boxes - Hive manages them
    _isInitialized = false;
  }
}

/// Model for draft information
class DraftInfo {
  final String draftId;
  final String projectId;
  final String userId;
  final String projectName;
  final DateTime savedAt;

  DraftInfo({
    required this.draftId,
    required this.projectId,
    required this.userId,
    required this.projectName,
    required this.savedAt,
  });

  factory DraftInfo.fromMap(Map<String, dynamic> map) => DraftInfo(
    draftId: map['id'] ?? '',
    projectId: map['projectId'] ?? '',
    userId: map['userId'] ?? '',
    projectName: map['projectName'] ?? 'Untitled',
    savedAt: map['savedAt'] != null
        ? DateTime.parse(map['savedAt'].toString())
        : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': draftId,
    'projectId': projectId,
    'userId': userId,
    'projectName': projectName,
    'savedAt': savedAt.toIso8601String(),
  };

  /// Get time difference from now (e.g., "2 hours ago")
  String getTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(savedAt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
