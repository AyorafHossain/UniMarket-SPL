import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rent_request_model.dart';

class RentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rentCollection =>
      _firestore.collection('rentRequests');

  // Create a new rent request
  Future<void> createRentRequest(RentRequestModel request) async {
    try {
      final docRef = _rentCollection.doc();
      final requestData = request.toMap();
      requestData['rentRequestId'] = docRef.id;
      
      await docRef.set(requestData);
    } catch (e) {
      debugPrint('RentService: createRentRequest error: $e');
      rethrow;
    }
  }

  // Get stream of rent requests for a specific seller
  Stream<List<RentRequestModel>> getSellerRentRequests(String sellerId) {
    return _rentCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RentRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  // Get stream of rent requests made by a specific renter
  Stream<List<RentRequestModel>> getRenterRequests(String renterId) {
    return _rentCollection
        .where('renterId', isEqualTo: renterId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RentRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  // Update status of a rent request
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _rentCollection.doc(requestId).update({'status': status});
    } catch (e) {
      debugPrint('RentService: updateRequestStatus error: $e');
      rethrow;
    }
  }
}
