import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ NO google_sign_in package import needed.
// Google Sign-In is handled entirely through Firebase Auth's
// built-in GoogleAuthProvider — works on Android, iOS & Web.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user stream ───────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Current user snapshot ─────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Email / Password Sign In ──────────────────────────────────────────────
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // For backwards compatibility
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return signIn(email, password);
  }

  // ── Email / Password Register ─────────────────────────────────────────────
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    if (credential.user != null) {
      await _createUserProfile(
        uid: credential.user!.uid,
        email: email.trim(),
        displayName: name,
        photoUrl: null,
      );
    }
    return credential;
  }

  // For backwards compatibility
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    return signUp(email, password, displayName);
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  // Uses Firebase's built-in GoogleAuthProvider.
  // On Android/iOS → opens native Google account picker.
  // On Web        → opens a popup.
  // No google_sign_in package required.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add required scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Force account selection every time (optional but good UX)
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      UserCredential userCredential;

      // signInWithPopup works on Web; signInWithProvider works on mobile
      try {
        userCredential = await _auth.signInWithProvider(googleProvider);
      } catch (_) {
        // Fallback for older Firebase SDK versions
        userCredential = await _auth.signInWithPopup(googleProvider);
      }

      // Create Firestore profile on first sign-in
      if (userCredential.additionalUserInfo?.isNewUser == true &&
          userCredential.user != null) {
        await _createUserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? '',
          photoUrl: userCredential.user!.photoURL,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // User closed the popup — treat as cancelled
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // ── Send Password Reset Email ─────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Delete Account ────────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  // ── Update Display Name ───────────────────────────────────────────────────
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Update Photo URL ──────────────────────────────────────────────────────
  Future<void> updatePhotoUrl(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Internal: create Firestore user document ──────────────────────────────
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    await _db.collection('users').doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl ?? '',
        'plan': 'free',
        'projectCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}