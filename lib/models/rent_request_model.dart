import 'package:cloud_firestore/cloud_firestore.dart';

class RentRequestModel {
  final String rentRequestId;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final String renterId;
  final String renterName;
  final String sellerId;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final double pricePerDay;
  final double totalAmount;
  final String status; // 'pending', 'accepted', 'rejected', 'completed', 'cancelled'
  final DateTime createdAt;

  RentRequestModel({
    required this.rentRequestId,
    required this.productId,
    required this.productTitle,
    this.productImageUrl = '',
    required this.renterId,
    required this.renterName,
    required this.sellerId,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.pricePerDay,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rentRequestId': rentRequestId,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'renterId': renterId,
      'renterName': renterName,
      'sellerId': sellerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'rentalDays': rentalDays,
      'pricePerDay': pricePerDay,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RentRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return RentRequestModel(
      rentRequestId: documentId,
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      renterId: map['renterId'] ?? '',
      renterName: map['renterName'] ?? 'Anonymous',
      sellerId: map['sellerId'] ?? '',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      rentalDays: map['rentalDays'] ?? 1,
      pricePerDay: (map['pricePerDay'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
