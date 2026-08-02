import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeRequestModel {
  final String requestId;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final String requesterId;
  final String requesterName;
  final String sellerId;
  final String wantedItem;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled', 'completed'
  final DateTime createdAt;

  ExchangeRequestModel({
    required this.requestId,
    required this.productId,
    required this.productTitle,
    this.productImageUrl = '',
    required this.requesterId,
    required this.requesterName,
    required this.sellerId,
    required this.wantedItem,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'sellerId': sellerId,
      'wantedItem': wantedItem,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExchangeRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return ExchangeRequestModel(
      requestId: documentId,
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? 'Anonymous',
      sellerId: map['sellerId'] ?? map['ownerId'] ?? '',
      wantedItem: map['wantedItem'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
