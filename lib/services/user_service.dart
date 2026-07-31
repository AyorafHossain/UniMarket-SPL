import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'cloudinary_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user profile in Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      debugPrint('UserService: createUserProfile error: $e');
      rethrow;
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('UserService: getUserProfile error: $e');
      rethrow;
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      debugPrint('UserService: updateUserProfile error: $e');
      rethrow;
    }
  }

  // Update a specific field in the user profile
  Future<void> updateUserProfileField(String uid, String field, dynamic value) async {
    try {
      await _firestore.collection('users').doc(uid).update({field: value});
    } catch (e) {
      debugPrint('UserService: updateUserProfileField error: $e');
      rethrow;
    }
  }

  // Upload profile image to Cloudinary and return secure URL
  Future<String> uploadProfileImage(File imageFile, String uid) async {
    try {
      final cloudinaryService = CloudinaryService();
      final downloadUrl = await cloudinaryService.uploadImage(
        imageFile: imageFile,
        folder: 'profile_images/$uid',
      );
      return downloadUrl;
    } catch (e) {
      debugPrint('UserService: uploadProfileImage error: $e');
      rethrow;
    }
  }
}
