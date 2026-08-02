import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String sellerId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status; // pending_payment, paid, failed, cancelled
  final String paymentMethod;
  final DateTime createdAt;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final bool stockUpdated;

  OrderModel({
    required this.id,
    required this.userId,
    required this.sellerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    this.stockUpdated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sellerId': sellerId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'stockUpdated': stockUpdated,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending_payment',
      paymentMethod: map['paymentMethod'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      buyerName: map['buyerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      stockUpdated: map['stockUpdated'] ?? false,
    );
  }
}
