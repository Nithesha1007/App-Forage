import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AdminService — all Firestore reads/writes for the admin dashboard
// ══════════════════════════════════════════════════════════════════════════════
class AdminService {
  final _db = FirebaseFirestore.instance;

  // ── Role check ─────────────────────────────────────────────────────────────
  /// Returns true if the current uid has role == 'admin' in Firestore users collection
  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  /// Set a user's role in Firestore
  Future<void> setRole(String uid, String role) =>
      _db.collection('users').doc(uid).update({'role': role});

  // ── Analytics ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAnalytics() async {
    final usersSnap = await _db.collection('users').get();
    final appsSnap = await _db.collection('projects').get();
    final publishedSnap = await _db
        .collection('projects')
        .where('status', isEqualTo: 'published')
        .get();

    // Active users = logged in within last 7 days
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 7)),
    );
    final activeSnap = await _db
        .collection('users')
        .where('lastSeen', isGreaterThan: cutoff)
        .get();

    final adminSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    return {
      'totalUsers': usersSnap.size,
      'totalApps': appsSnap.size,
      'publishedApps': publishedSnap.size,
      'activeUsers': activeSnap.size,
      'adminCount': adminSnap.size,
    };
  }

  // ── User Management ────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> deleteUser(String uid) =>
      _db.collection('users').doc(uid).delete();

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── App Management ─────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamAllApps() {
    return _db
        .collection('projects')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> approveApp(String appId) =>
      _db.collection('projects').doc(appId).update({'status': 'approved'});

  Future<void> rejectApp(String appId) =>
      _db.collection('projects').doc(appId).update({'status': 'rejected'});

  Future<void> deleteApp(String appId) =>
      _db.collection('projects').doc(appId).delete();

  // ── Template Management ────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamTemplates() {
    return _db
        .collection('templates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> createTemplate(Map<String, dynamic> data) => _db
      .collection('templates')
      .add({...data, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateTemplate(String id, Map<String, dynamic> data) =>
      _db.collection('templates').doc(id).update(data);

  Future<void> deleteTemplate(String id) =>
      _db.collection('templates').doc(id).delete();

  // ── Component Management ───────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamComponents() {
    return _db
        .collection('components')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> createComponent(Map<String, dynamic> data) => _db
      .collection('components')
      .add({...data, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateComponent(String id, Map<String, dynamic> data) =>
      _db.collection('components').doc(id).update(data);

  Future<void> deleteComponent(String id) =>
      _db.collection('components').doc(id).delete();

  // ── Deployment Management ──────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamDeployments() {
    return _db
        .collection('deployments')
        .orderBy('deployedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> updateDeploymentStatus(String id, String status) =>
      _db.collection('deployments').doc(id).update({'status': status});

  // ── AI Module ──────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamAiLogs() {
    return _db
        .collection('ai_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> deleteAiLog(String id) =>
      _db.collection('ai_logs').doc(id).delete();
}
