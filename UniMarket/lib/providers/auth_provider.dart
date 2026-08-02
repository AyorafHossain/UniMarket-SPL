import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  User? _user;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen to auth state changes and update user
    _authService.authStateChanges.listen((User? user) async {
      debugPrint('Auth state changed. User exists: ${user != null}');
      if (user != null) {
        debugPrint('App Startup User UID: ${user.uid}');
        debugPrint('App Startup User Email: ${user.email}');
        debugPrint('App Startup User DisplayName: ${user.displayName}');
        debugPrint('App Startup User Email Verified: ${user.emailVerified}');
        
        // Enforce NSTU email restriction for existing users as well
        if (user.email == null || !_authService.isNstuStudentEmail(user.email!)) {
          debugPrint('Blocked invalid existing user session: ${user.email}');
          await _authService.signOut();
          _setError('Only NSTU student accounts are allowed.');
          _user = null;
          _isCheckingAuth = false;
          notifyListeners();
          return;
        }
        
        // Ensure user document exists in Firestore
        try {
          UserModel? existingUser = await _userService.getUserProfile(user.uid);
          if (existingUser == null) {
            debugPrint('Firestore user doc does NOT exist. Creating one...');
            UserModel newUser = UserModel(
              id: user.uid,
              name: user.displayName ?? user.email?.split('@')[0] ?? '',
              email: user.email ?? '',
              universityEmail: user.email ?? '',
              profilePic: user.photoURL ?? '',
              department: '',
              phoneNumber: '',
              university: 'NSTU',
              role: 'student',
              isEmailVerified: user.emailVerified,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
              authProvider: 'firebase',
            );
            await _userService.createUserProfile(newUser);
            debugPrint('Created missing user document in Firestore.');
          } else {
            debugPrint('Firestore user doc exists for ${user.uid}');
          }
        } catch (e) {
          debugPrint('Firestore profile sync failed in auth state listener: $e');
          // Non-fatal error, do not sign out the user
        }

        _user = user;
        _isCheckingAuth = false;
        notifyListeners();
      } else {
        _user = null;
        _isCheckingAuth = false;
        notifyListeners();
      }
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign up
  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    _setError(null);
    try {
      if (!_authService.isNstuStudentEmail(email)) {
        _setError('Only NSTU student email addresses are allowed.');
        return false;
      }

      UserCredential? credential = await _authService.signUpWithEmail(email: email, password: password, name: name);
      if (credential != null && credential.user != null) {
        // Create Firestore profile document
        UserModel newUser = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          universityEmail: email, // Default to registration email
          university: 'NSTU',
          role: 'student',
          isEmailVerified: false,
        );
        await _userService.createUserProfile(newUser);
      }
      await _authService.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    
    final formattedEmail = email.trim().toLowerCase();
    debugPrint('Attempting login with email: $formattedEmail');
    
    try {
      if (!_authService.isNstuStudentEmail(formattedEmail)) {
        debugPrint('Domain validation failed for: $formattedEmail');
        _setError('Only NSTU student email addresses are allowed to use UniMarket.');
        return false;
      }

      UserCredential? credential = await _authService.signInWithEmail(email: formattedEmail, password: password);
      
      if (credential != null && credential.user != null) {
        final user = credential.user!;
        debugPrint('Firebase login successful for: ${user.uid}');
        debugPrint('Email verified: ${user.emailVerified}');
        
        // Ensure user document exists in Firestore
        try {
          UserModel? existingUser = await _userService.getUserProfile(user.uid);
          if (existingUser == null) {
            UserModel newUser = UserModel(
              id: user.uid,
              name: user.displayName ?? 'Student',
              email: user.email ?? formattedEmail,
              universityEmail: user.email ?? formattedEmail,
              university: 'NSTU',
              role: 'student',
              isEmailVerified: user.emailVerified,
              lastLoginAt: DateTime.now(),
              createdAt: DateTime.now(),
              authProvider: 'email',
            );
            await _userService.createUserProfile(newUser);
            debugPrint('Created missing user document in Firestore.');
          } else {
            // Update lastLoginAt
            UserModel updatedUser = UserModel(
              id: existingUser.id,
              name: existingUser.name,
              email: existingUser.email,
              universityEmail: existingUser.universityEmail,
              department: existingUser.department,
              phoneNumber: existingUser.phoneNumber,
              profilePic: existingUser.profilePic,
              isOnline: existingUser.isOnline,
              createdAt: existingUser.createdAt,
              authProvider: existingUser.authProvider,
              lastLoginAt: DateTime.now(),
              university: existingUser.university,
              role: existingUser.role,
              isEmailVerified: user.emailVerified,
            );
            await _userService.updateUserProfile(updatedUser);
          }
        } catch (e) {
          debugPrint('Firestore profile sync failed during email login: $e');
          // Non-fatal error
        }
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login failure: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      debugPrint('Unexpected login failure: $e');
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      UserCredential? credential = await _authService.signInWithGoogle();
      
      if (credential == null) {
        _setError('Google sign-in cancelled.');
        return false;
      }

      if (credential.user != null) {
        final user = credential.user!;
        
        if (user.email == null || !_authService.isNstuStudentEmail(user.email!)) {
          await logout();
          _setError('Only NSTU student email accounts are allowed.');
          return false;
        }
        
        try {
          UserModel? existingUser = await _userService.getUserProfile(user.uid);
          
          if (existingUser == null) {
            UserModel newUser = UserModel(
              id: user.uid,
              name: user.displayName ?? 'New User',
              email: user.email ?? '',
              profilePic: user.photoURL ?? '',
              createdAt: DateTime.now(),
              authProvider: 'google',
              lastLoginAt: DateTime.now(),
              universityEmail: user.email ?? '',
              university: 'NSTU',
              role: 'student',
              isEmailVerified: user.emailVerified,
            );
            await _userService.createUserProfile(newUser);
          } else {
            UserModel updatedUser = UserModel(
              id: existingUser.id,
              name: existingUser.name,
              email: existingUser.email,
              universityEmail: existingUser.universityEmail,
              department: existingUser.department,
              phoneNumber: existingUser.phoneNumber,
              profilePic: existingUser.profilePic,
              isOnline: existingUser.isOnline,
              createdAt: existingUser.createdAt,
              authProvider: existingUser.authProvider,
              lastLoginAt: DateTime.now(),
              university: existingUser.university,
              role: existingUser.role,
              isEmailVerified: user.emailVerified,
            );
            await _userService.updateUserProfile(updatedUser);
          }
        } catch (e) {
          debugPrint('Firestore profile sync failed during Google login: $e');
          // Non-fatal error, login succeeds
        }
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      if (e.toString().contains('invalid_domain')) {
        await logout();
        _setError('Only NSTU student email accounts are allowed.');
      } else if (e.toString().contains('PlatformException') || e.toString().contains('network_error')) {
        _setError('Network error. Please check your internet connection.');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('ApiException')) {
        // --- Android Configuration Check ---
        // Reminder for Firebase setup:
        // 1. Google provider must be enabled in Firebase Authentication
        // 2. Support email must be set in Firebase Project Settings
        // 3. SHA-1 and SHA-256 must be added for Android in Firebase settings
        // 4. Updated google-services.json must be downloaded and placed in android/app/google-services.json
        // 5. Run flutter clean && flutter pub get
        debugPrint('Google Sign-In failed due to missing SHA-1/SHA-256 or Google provider not being enabled in Firebase.');
        _setError('Google Sign-In configuration error. Please check Firebase SHA and google-services.json.');
      } else {
        _setError('Google sign-in failed. Please try again.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    if (_user != null) {
      await ChatService().updateOnlineStatus(_user!.uid, false);
    }
    await _authService.signOut();
  }

  // Helper to map Firebase errors to user-friendly messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
