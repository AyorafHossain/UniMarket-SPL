import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Email and Password
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw Exception('User authentication failed.');
      }

      // Read user document from Firestore
      final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('User record not found in database.');
      }

      final data = doc.data() as Map<String, dynamic>;
      final UserModel userModel = UserModel.fromMap(data, doc.id);

      // Check role
      if (userModel.role != 'admin') {
        await _auth.signOut();
        throw Exception('Access Denied: Only admin accounts can log in.');
      }

      if (!userModel.isActive) {
        await _auth.signOut();
        throw Exception('Access Denied: Your admin account has been deactivated.');
      }

      // Update last login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isOnline': true,
      });

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
        });
      } catch (_) {}
    }
    await _auth.signOut();
  }

  // Check if current user is admin (used during splash/resume)
  Future<UserModel?> getCurrentAdminModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(data, doc.id);
        if (userModel.role == 'admin' && userModel.isActive) {
          return userModel;
        }
      }
    } catch (_) {}
    
    await _auth.signOut();
    return null;
  }

  // Update password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user currently logged in.');

    try {
      // Re-authenticate user
      final email = user.email!;
      final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }
}
