import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exchange_request_model.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all exchange requests
  Stream<List<ExchangeRequestModel>> getExchangeRequestsStream() {
    return _firestore.collection('exchangeRequests').snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => ExchangeRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  // Update exchange request status
  Future<void> updateExchangeRequestStatus(String requestId, String status) async {
    await _firestore.collection('exchangeRequests').doc(requestId).update({
      'status': status,
    });
  }
}
