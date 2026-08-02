import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String universityEmail;
  final String department;
  final String phoneNumber;
  final String profilePic;
  final bool isOnline;
  final DateTime? createdAt;
  final String authProvider;
  final DateTime? lastLoginAt;
  final String university;
  final String role;
  final bool isEmailVerified;
  final bool isActive; // Admin field to ban/deactivate user

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.universityEmail = '',
    this.department = '',
    this.phoneNumber = '',
    this.profilePic = '',
    this.isOnline = false,
    this.createdAt,
    this.authProvider = 'email',
    this.lastLoginAt,
    this.university = 'NSTU',
    this.role = 'student',
    this.isEmailVerified = false,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'universityEmail': universityEmail,
      'department': department,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'isOnline': isOnline,
      'createdAt': createdAt?.toIso8601String(),
      'authProvider': authProvider,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'university': university,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      universityEmail: map['universityEmail'] ?? '',
      department: map['department'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePic: map['profilePic'] ?? '',
      isOnline: map['isOnline'] ?? false,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
      authProvider: map['authProvider'] ?? 'email',
      lastLoginAt: map['lastLoginAt'] is Timestamp 
          ? (map['lastLoginAt'] as Timestamp).toDate() 
          : (map['lastLoginAt'] != null ? DateTime.tryParse(map['lastLoginAt'].toString()) : null),
      university: map['university'] ?? 'NSTU',
      role: map['role'] ?? 'student',
      isEmailVerified: map['isEmailVerified'] ?? false,
      isActive: map['isActive'] ?? true,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? universityEmail,
    String? department,
    String? phoneNumber,
    String? profilePic,
    bool? isOnline,
    DateTime? createdAt,
    String? authProvider,
    DateTime? lastLoginAt,
    String? university,
    String? role,
    bool? isEmailVerified,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      universityEmail: universityEmail ?? this.universityEmail,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePic: profilePic ?? this.profilePic,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      authProvider: authProvider ?? this.authProvider,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      university: university ?? this.university,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
    );
  }
}
