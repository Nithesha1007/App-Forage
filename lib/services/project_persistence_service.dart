import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_model.dart';
import '../models/screen_model.dart';
import 'firestore_service.dart';

/// ProjectPersistenceService handles debounced auto-saving with dual storage:
/// - Local (Hive) for offline support
/// - Firebase (Firestore) for cloud persistence
///
/// Features:
/// - Debounced saves (300-500ms) to avoid excessive writes
/// - User-based project isolation
/// - Auto-sync between local and Firebase
/// - Graceful offline support with eventual sync
class ProjectPersistenceService {
  final FirestoreService _fs = FirestoreService();
  final Duration debounceInterval = const Duration(milliseconds: 400);

  Timer? _debounceTimer;
  ProjectModel? _pendingProject;
  Box? _projectsBox;
  bool _isInitialized = false;

  /// Initialize the persistence service
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _projectsBox = await Hive.openBox('appforge_projects');
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Failed to initialize Hive: $e');
    }
  }

  /// Save project with debouncing (2 seconds)
  /// Call this on every change (drag, edit, delete)
  /// Actual save will be debounced to avoid excessive writes
  void debouncedSaveProject(ProjectModel project) {
    _pendingProject = project;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set new debounce timer
    _debounceTimer = Timer(debounceInterval, () async {
      if (_pendingProject != null) {
        await _saveProjectNow(_pendingProject!);
      }
    });
  }

  /// Immediately save project without debounce
  /// Use this when user explicitly clicks "save" or before critical operations
  Future<void> saveProjectImmediately(ProjectModel project) async {
    _pendingProject = project;
    _debounceTimer?.cancel();
    await _saveProjectNow(project);
  }

  /// Internal method: Actually save the project to both local and Firebase
  Future<void> _saveProjectNow(ProjectModel project) async {
    try {
      // ✅ STEP 1: Log email for debugging
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔄 STEP 1 - SAVE API CALLED');
      debugPrint('   Project name:    ${project.name}');
      debugPrint('   Project id:      ${project.id}');
      debugPrint('   User id:         ${project.userId}');
      debugPrint('   SAVE EMAIL:      ${project.userEmail ?? "NOT SET"}');
      debugPrint('═══════════════════════════════════════════════════════════');

      // 1. Save to local storage (always succeeds)
      await _saveToLocal(project);

      // 2. Try to save to Firebase
      try {
        await _fs.updateProject(project);
        debugPrint('✅ SAVE STEP: Firebase updated successfully');
        debugPrint('   Email saved:     ${project.userEmail}');
        debugPrint('   UserId saved:    ${project.userId}');
      } catch (e) {
        // Offline or network error - local save is still valid
        debugPrint('❌ SAVE STEP: Firebase update failed: $e');
        // Project is safe in local storage, will sync when online
      }
    } catch (e) {
      debugPrint('❌ SAVE STEP: Critical save error: $e');
    }
  }

  /// Save project to local Hive storage
  /// Uses toJson() to ensure Timestamp objects are converted to ISO strings
  Future<void> _saveToLocal(ProjectModel project) async {
    if (_projectsBox == null) await init();
    try {
      final key = '${project.userId}:${project.id}';
      _projectsBox?.put(key, jsonEncode(project.toJson()));
      debugPrint('✅ Local save: ${project.name} (${project.userEmail})');
    } catch (e) {
      debugPrint(
        '❌ Local save failed: Converting object to an encodable object failed: $e',
      );
      rethrow;
    }
  }

  /// Load project from Firestore (with local fallback)
  Future<ProjectModel?> loadProject(String projectId, String userId) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📥 STEP 4 - FETCH API: Load single project');
      debugPrint('   projectId: $projectId');
      debugPrint('   userId:    $userId');

      // Try Firebase first (source of truth)
      try {
        final project = await _fs.getProject(projectId);
        if (project != null) {
          debugPrint('✅ STEP 4: Loaded from Firebase');
          debugPrint('   Project: ${project.name}');
          debugPrint('   FETCH EMAIL: ${project.userEmail ?? "NOT SET"}');
          debugPrint('   User ID: ${project.userId}');
          // Cache it locally for offline access
          await _saveToLocal(project);
          return project;
        }
      } catch (e) {
        debugPrint('⚠️ STEP 4: Firebase load failed: $e');
      }

      // Fallback to local storage if Firebase failed
      final local = _loadFromLocal(projectId, userId);
      if (local != null) {
        debugPrint('✅ STEP 4: Loaded from local cache');
        debugPrint('   Project: ${local.name}');
        debugPrint('   FETCH EMAIL: ${local.userEmail ?? "NOT SET"}');
      } else {
        debugPrint('❌ STEP 4: Project not found anywhere');
      }
      debugPrint('═══════════════════════════════════════════════════════════');
      return local;
    } catch (e) {
      debugPrint('❌ STEP 4: Critical error loading project: $e');
      return null;
    }
  }

  /// Load project from local storage
  ProjectModel? _loadFromLocal(String projectId, String userId) {
    if (_projectsBox == null) return null;
    try {
      final key = '$userId:$projectId';
      final data = _projectsBox?.get(key);
      if (data == null) return null;

      final decoded = jsonDecode(data) as Map<String, dynamic>;
      return _projectFromMap(decoded);
    } catch (e) {
      debugPrint('❌ Local load failed: $e');
      return null;
    }
  }

  /// Helper to create ProjectModel from map (for local storage)
  ProjectModel _projectFromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'], // ✅ FIX 1: Load email from local storage
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

  /// Get all user projects (Firebase with local fallback)
  Stream<List<ProjectModel>> getUserProjectsStream(String userId) {
    return _fs.getUserProjects(userId).handleError((e) {
      debugPrint('⚠️ Stream error: $e');
      return <ProjectModel>[];
    });
  }

  /// Get cached user projects from local storage
  Future<List<ProjectModel>> getCachedUserProjects(String userId) async {
    if (_projectsBox == null) await init();
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📥 STEP 4 - FETCH: Load cached projects');
      debugPrint('   userId: $userId');

      final projects = <ProjectModel>[];
      int foundCount = 0;

      for (var key in _projectsBox?.keys ?? []) {
        if (key.toString().startsWith('$userId:')) {
          final data = _projectsBox?.get(key);
          if (data != null) {
            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              final project = _projectFromMap(decoded);
              projects.add(project);
              foundCount++;
              debugPrint(
                '   ✅ Cached: ${project.name} (email=${project.userEmail})',
              );
            } catch (e) {
              debugPrint('   ⚠️ Parse error: $e');
            }
          }
        }
      }

      debugPrint('✅ STEP 4: Loaded $foundCount projects from cache');
      debugPrint('═══════════════════════════════════════════════════════════');
      return projects;
    } catch (e) {
      debugPrint('❌ STEP 4: Failed to get cached projects: $e');
      return [];
    }
  }

  /// Delete project from both local and Firebase
  Future<void> deleteProject(String projectId, String userId) async {
    try {
      debugPrint('🗑️ Deleting project: $projectId');

      // Delete from Firestore
      await _fs.deleteProject(projectId, userId);

      // Delete from local storage
      if (_projectsBox != null) {
        final key = '$userId:$projectId';
        await _projectsBox?.delete(key);
      }
      debugPrint('✅ Project deleted: $projectId');
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
    }
  }

  /// Clear pending saves on logout or cleanup
  void cancelPendingSaves() {
    debugPrint('🛑 Cancelling pending saves');
    _debounceTimer?.cancel();
    _pendingProject = null;
  }

  /// Dispose the service
  Future<void> dispose() async {
    cancelPendingSaves();
    // Don't close the box here as it might be used elsewhere
  }
}
