import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rent_request_model.dart';

class RentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all rent requests
  Stream<List<RentRequestModel>> getRentRequestsStream() {
    return _firestore.collection('rentRequests').snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RentRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  // Update rent request status
  Future<void> updateRentRequestStatus(String requestId, String status) async {
    await _firestore.collection('rentRequests').doc(requestId).update({
      'status': status,
    });
  }
}
