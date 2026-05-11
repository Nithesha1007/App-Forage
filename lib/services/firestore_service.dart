import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import '../models/template_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Collections ───────────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _projects => _db.collection('projects');

  // ── Get all projects for a user (real-time stream) ────────────────────────
  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _projects
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList(),
        );
  }

  // ── Get a single project ──────────────────────────────────────────────────
  Future<ProjectModel?> getProject(String projectId) async {
    final doc = await _projects.doc(projectId).get();
    if (!doc.exists) return null;
    return ProjectModel.fromFirestore(doc);
  }

  // ── Create project from template ──────────────────────────────────────────
  Future<String> createFromTemplate(
    TemplateModel template,
    String userId,
    String projectName,
    String? userEmail,
  ) async {
    final projectId = _uuid.v4();
    final now = FieldValue.serverTimestamp();

    // Build default screens with empty widget lists
    final screens = template.defaultScreens
        .map(
          (name) => {
            'id': _uuid.v4(),
            'name': name,
            'widgets': <Map>[],
            'backgroundColor': '#FFFFFF',
          },
        )
        .toList();

    // Build default tables
    final tables = template.defaultTables
        .map(
          (t) => {
            'id': _uuid.v4(),
            'name': t.name,
            'fields': ['id', 'created_at', ...t.fields],
          },
        )
        .toList();

    await _projects.doc(projectId).set({
      'id': projectId,
      'name': projectName,
      'userId': userId,
      'userEmail': userEmail, // ✅ FIX 1: Store user email
      'templateId': template.id,
      'templateName': template.name,
      'status': 'draft',
      'publishedUrl': '',
      'theme': {
        'primaryColor': template.primaryHex,
        'secondaryColor': template.secondaryHex,
        'backgroundColor': '#FFFFFF',
        'fontFamily': 'Poppins',
        'borderRadius': 12.0,
        'isDarkMode': false,
      },
      'backendConfig': {
        'tables': tables,
        'emailAuth': template.emailAuth,
        'googleAuth': template.googleAuth,
        'phoneAuth': false,
        'securityRules': '',
      },
      'screens': screens,
      'createdAt': now,
      'updatedAt': now,
    });

    // Increment user project count
    await _users
        .doc(userId)
        .update({'projectCount': FieldValue.increment(1)})
        .catchError((_) {}); // ignore if user doc doesn't exist yet

    return projectId;
  }

  // ── Save / update a project ───────────────────────────────────────────────
  Future<void> updateProject(ProjectModel project) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔄 STEP 2 - BACKEND FIREBASE UPDATE');
    debugPrint('   Project: ${project.name}');
    debugPrint('   Project ID: ${project.id}');
    debugPrint('   User ID: ${project.userId}');
    debugPrint('   SAVE EMAIL: ${project.userEmail ?? "NOT SET"}');

    final data = project.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();

    debugPrint('   Updating Firestore with:');
    debugPrint('     - userEmail: ${data['userEmail']}');
    debugPrint('     - userId: ${data['userId']}');

    await _projects.doc(project.id).update(data);
    debugPrint('✅ STEP 2: Firebase document updated');
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  // ── Publish a project ─────────────────────────────────────────────────────
  Future<void> publishProject(String projectId, String publishedUrl) async {
    await _projects.doc(projectId).update({
      'status': 'published',
      'publishedUrl': publishedUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also store in user_apps collection for public lookup
    await _db.collection('user_apps').doc(projectId).set({
      'projectId': projectId,
      'publishedUrl': publishedUrl,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Delete a project ──────────────────────────────────────────────────────
  Future<void> deleteProject(String projectId, String userId) async {
    await _projects.doc(projectId).delete();

    // Decrement user project count (floor at 0)
    await _users
        .doc(userId)
        .update({'projectCount': FieldValue.increment(-1)})
        .catchError((_) {});

    // Remove from user_apps if published
    await _db
        .collection('user_apps')
        .doc(projectId)
        .delete()
        .catchError((_) {});
  }

  // ── Duplicate a project ───────────────────────────────────────────────────
  Future<String> duplicateProject(String projectId, String userId) async {
    final original = await getProject(projectId);
    if (original == null) throw Exception('Project not found');

    final newId = _uuid.v4();
    final data = original.toFirestore();
    data['id'] = newId;
    data['name'] = '${original.name} (Copy)';
    data['status'] = 'draft';
    data['publishedUrl'] = '';
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _projects.doc(newId).set(data);
    await _users
        .doc(userId)
        .update({'projectCount': FieldValue.increment(1)})
        .catchError((_) {});

    return newId;
  }

  // ── Get user profile ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  // ── Update user profile ───────────────────────────────────────────────────
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _users.doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Runtime data: add a record to a project table ─────────────────────────
  // Stored at: project_data/{projectId}/{tableName}/{autoId}
  Future<void> addRecord(
    String projectId,
    String tableName,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('project_data')
        .doc(projectId)
        .collection(tableName)
        .add({...data, 'createdAt': FieldValue.serverTimestamp()});
  }

  // ── Runtime data: stream records from a project table ─────────────────────
  Stream<List<Map<String, dynamic>>> streamRecords(
    String projectId,
    String tableName,
  ) {
    return _db
        .collection('project_data')
        .doc(projectId)
        .collection(tableName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }
}
