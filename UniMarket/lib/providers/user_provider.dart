import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    // Listen to Auth state changes to automatically load/clear user profile
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
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

  // Fetch user profile from Firestore
  Future<void> fetchUserProfile(String uid) async {
    _setLoading(true);
    _setError(null);
    try {
      UserModel? profile = await _userService.getUserProfile(uid);
      if (profile != null) {
        _userProfile = profile;
      } else {
        // Profile does not exist yet (e.g. newly signed up user before doc creation)
        _userProfile = UserModel(
          id: uid,
          name: _auth.currentUser?.displayName ?? '',
          email: _auth.currentUser?.email ?? '',
        );
      }
      // Update online status in Firestore
      await ChatService().updateOnlineStatus(uid, true);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load user profile: $e');
      // Provide a fallback profile so the app does not break entirely
      _userProfile = UserModel(
        id: uid,
        name: _auth.currentUser?.displayName ?? '',
        email: _auth.currentUser?.email ?? '',
      );
      _setLoading(false);
    }
  }

  // Create initial profile (used during signup)
  Future<bool> createInitialProfile(UserModel user) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userService.createUserProfile(user);
      _userProfile = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create profile: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update profile details
  Future<bool> updateProfile({
    required String name,
    required String department,
    required String phoneNumber,
    required String universityEmail,
    File? imageFile,
  }) async {
    if (_userProfile == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      String profilePicUrl = _userProfile!.profilePic;

      // If a new image is provided, upload it first
      if (imageFile != null) {
        profilePicUrl = await _userService.uploadProfileImage(imageFile, _userProfile!.id);
      }

      UserModel updatedProfile = UserModel(
        id: _userProfile!.id,
        name: name,
        email: _userProfile!.email,
        universityEmail: universityEmail,
        department: department,
        phoneNumber: phoneNumber,
        profilePic: profilePicUrl,
      );

      await _userService.updateUserProfile(updatedProfile);
      
      // Also update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(name);
      
      _userProfile = updatedProfile;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      _setLoading(false);
      return false;
    }
  }
}
