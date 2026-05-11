import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

// ══════════════════════════════════════════════════════════════════════════════
// AuthProvider — updated to include role-based access
// Added: userRole, isAdmin, _loadRole()
// Everything else unchanged from original
// ══════════════════════════════════════════════════════════════════════════════
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  String _userRole = 'user'; // 'user' | 'admin'
  bool _roleLoaded = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoggedIn => _user != null; // kept for compatibility
  String? get errorMessage => _errorMessage;
  String get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin';
  bool get roleLoaded => _roleLoaded;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _user = user;
    if (user != null) {
      _status = AuthStatus.authenticated;
      _roleLoaded = false;
      // Load role from Firestore after auth
      await _loadRole(user.uid);
    } else {
      _status = AuthStatus.unauthenticated;
      _userRole = 'user';
      _roleLoaded = false;
      notifyListeners();
    }
  }

  /// Fetch role from Firestore users/{uid} document
  Future<void> _loadRole(String uid) async {
    try {
      final admin = await _adminService.isAdmin(uid);
      _userRole = admin ? 'admin' : 'user';
    } catch (_) {
      _userRole = 'user';
    }
    _roleLoaded = true;
    notifyListeners();
  }

  // ── Sign in ────────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _errorMessage = null;
    try {
      await _authService.signIn(email, password);
      // ✅ STEP 7: Log email for comparison
      if (_user != null) {
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        debugPrint('✅ STEP 7 - LOGIN: SUCCESS');
        debugPrint('   LOGIN EMAIL: ${_user!.email}');
        debugPrint('   User ID: ${_user!.uid}');
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        // Projects will be loaded by HomeScreen on navigation
      }
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ── Sign up ────────────────────────────────────────────────────────────────
  Future<bool> signUp(String email, String password, String name) async {
    _errorMessage = null;
    try {
      await _authService.signUp(email, password, name);
      // ✅ FIX 1 & 8: Log email and load user's projects immediately after signup
      if (_user != null) {
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        debugPrint('✅ SIGNUP SUCCESS');
        debugPrint('   LOGIN EMAIL: ${_user!.email}');
        debugPrint('   User ID: ${_user!.uid}');
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        // Projects will be loaded by HomeScreen on navigation
      }
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ── Google sign in ─────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    try {
      await _authService.signInWithGoogle();
      // ✅ FIX 1 & 8: Log email and load user's projects immediately after Google sign-in
      if (_user != null) {
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        debugPrint('✅ GOOGLE SIGNIN SUCCESS');
        debugPrint('   LOGIN EMAIL: ${_user!.email}');
        debugPrint('   User ID: ${_user!.uid}');
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        // Projects will be loaded by HomeScreen on navigation
      }
      return true;
    } catch (e) {
      _errorMessage = 'Google sign-in failed';
      notifyListeners();
      return false;
    }
  }

  // ── Password reset ─────────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🚪 SIGNING OUT USER');
    debugPrint('═══════════════════════════════════════════════════════════');

    // ✅ NOTE: We intentionally do NOT delete projects from storage
    // Projects belong to the user and should persist in cache
    // Next login will reload them from Firebase
    await _authService.signOut();
    _userRole = 'user';
    _roleLoaded = false;

    debugPrint('✅ LOGOUT: Complete. Projects remain safe in local cache');
    debugPrint('═══════════════════════════════════════════════════════════');
    notifyListeners();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
