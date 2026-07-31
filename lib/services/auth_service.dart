import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Helper to validate NSTU student email
  bool isNstuStudentEmail(String email) {
    return email.trim().toLowerCase().endsWith('@student.nstu.edu.bd');
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: signUpWithEmail error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: signUpWithEmail unexpected error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: signInWithEmail error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: signInWithEmail unexpected error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      debugPrint('Opening Google account picker...');
      // Clear any cached Google account so the account picker always shows
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user.');
        // User cancelled the sign-in flow
        return null;
      }

      debugPrint('Selected Google email: ${googleUser.email}');
      debugPrint('Selected Google displayName: ${googleUser.displayName}');

      final email = googleUser.email.trim().toLowerCase();
      if (!email.endsWith('@student.nstu.edu.bd')) {
        debugPrint('NSTU email validation failed for Google Sign-In: $email');
        await googleSignIn.signOut();
        throw Exception('invalid_domain');
      }
      
      debugPrint('NSTU email validation passed for Google Sign-In.');
      debugPrint('Fetching GoogleSignInAuthentication token...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('Received GoogleSignInAuthentication token successfully.');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Signing into FirebaseAuth with Google credential...');
      final result = await _auth.signInWithCredential(credential);
      debugPrint('FirebaseAuth signInWithCredential success for UID: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google Sign-In: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('PlatformException/Unexpected Error during Google Sign-In: $e');
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint('AuthService: sendEmailVerification error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear Google session as well
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      try {
        await googleSignIn.disconnect();
      } catch (_) {
        // Disconnect may fail if no active session
      }
    } catch (e) {
      debugPrint('AuthService: signOut error: $e');
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('AuthService: sendPasswordResetEmail error: $e');
      rethrow;
    }
  }
}
