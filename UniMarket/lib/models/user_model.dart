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
  });

  // Convert to Map for Firebase
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
    };
  }

  // Create from Map from Firebase
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      universityEmail: map['universityEmail'] ?? '',
      department: map['department'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePic: map['profilePic'] ?? '',
      isOnline: map['isOnline'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      authProvider: map['authProvider'] ?? 'email',
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.tryParse(map['lastLoginAt']) : null,
      university: map['university'] ?? '',
      role: map['role'] ?? 'student',
      isEmailVerified: map['isEmailVerified'] ?? false,
    );
  }
}
