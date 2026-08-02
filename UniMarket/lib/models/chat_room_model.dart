import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPic;
  final String sellerId;
  final String sellerName;
  final String sellerPic;
  final String productId;
  final String productTitle;
  final double productPrice;
  final String productImageUrl;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTime;
  final String lastMessageType;
  final List<String> participantIds;
  final List<String> deletedFor;

  ChatRoomModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPic,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPic,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.productImageUrl,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageTime,
    this.lastMessageType = 'text',
    required this.participantIds,
    this.deletedFor = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPic': buyerPic,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPic': sellerPic,
      'productId': productId,
      'productTitle': productTitle,
      'productPrice': productPrice,
      'productImageUrl': productImageUrl,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageType': lastMessageType,
      'participantIds': participantIds,
      'deletedFor': deletedFor,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    DateTime? msgTime;
    if (map['lastMessageTime'] != null) {
      if (map['lastMessageTime'] is Timestamp) {
        msgTime = (map['lastMessageTime'] as Timestamp).toDate();
      } else if (map['lastMessageTime'] is String) {
        msgTime = DateTime.tryParse(map['lastMessageTime']);
      }
    }

    return ChatRoomModel(
      id: map['id'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPic: map['buyerPic'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPic: map['sellerPic'] ?? '',
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productPrice: (map['productPrice'] as num?)?.toDouble() ?? 0.0,
      productImageUrl: map['productImageUrl'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTime: msgTime,
      lastMessageType: map['lastMessageType'] ?? 'text',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
    );
  }
}
