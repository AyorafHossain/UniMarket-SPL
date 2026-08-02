import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final String type;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final int? duration;
  final List<String>? deletedFor;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.deletedFor,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'deletedFor': deletedFor,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime time = DateTime.now();
    if (map['timestamp'] != null) {
      if (map['timestamp'] is Timestamp) {
        time = (map['timestamp'] as Timestamp).toDate();
      } else if (map['timestamp'] is String) {
        time = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
      }
    }

    DateTime? deletedTime;
    if (map['deletedAt'] != null) {
      if (map['deletedAt'] is Timestamp) {
        deletedTime = (map['deletedAt'] as Timestamp).toDate();
      } else if (map['deletedAt'] is String) {
        deletedTime = DateTime.tryParse(map['deletedAt']);
      }
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: time,
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      duration: map['duration'],
      deletedFor: map['deletedFor'] != null ? List<String>.from(map['deletedFor']) : null,
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: deletedTime,
      deletedBy: map['deletedBy'],
    );
  }
}
