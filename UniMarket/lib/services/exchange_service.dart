import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exchange_request_model.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createExchangeRequest(ExchangeRequestModel request) async {
    if (request.productId.isEmpty) throw Exception('Product ID cannot be empty');
    if (request.sellerId.isEmpty) throw Exception('Seller ID cannot be empty');
    if (request.requesterId.isEmpty) throw Exception('Requester ID cannot be empty');

    DocumentReference docRef;
    if (request.requestId.isEmpty) {
      docRef = _firestore.collection('exchangeRequests').doc();
      request = ExchangeRequestModel(
        requestId: docRef.id,
        productId: request.productId,
        productTitle: request.productTitle,
        productImageUrl: request.productImageUrl,
        requesterId: request.requesterId,
        requesterName: request.requesterName,
        sellerId: request.sellerId,
        wantedItem: request.wantedItem,
        message: request.message,
        status: request.status,
        createdAt: request.createdAt,
      );
    } else {
      docRef = _firestore.collection('exchangeRequests').doc(request.requestId);
    }

    await docRef.set(request.toMap());
  }

  Stream<List<ExchangeRequestModel>> getSellerExchangeRequests(String sellerId) {
    if (sellerId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('exchangeRequests')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      var requests = snapshot.docs
          .map((doc) => ExchangeRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Stream<List<ExchangeRequestModel>> getMyExchangeRequests(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('exchangeRequests')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      var requests = snapshot.docs
          .map((doc) => ExchangeRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore
        .collection('exchangeRequests')
        .doc(requestId)
        .update({'status': status});
  }
}
