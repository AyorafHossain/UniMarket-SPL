import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all products
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Update product approval status
  Future<void> updateProductApproval({
    required String productId,
    required String sellerId,
    required String approvalStatus,
    required String approvedBy,
    required String productTitle,
    String? rejectionReason,
  }) async {
    final updateData = {
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    
    await _firestore.collection('products').doc(productId).update(updateData);

    // Send notification
    String title;
    String body;
    if (approvalStatus == 'approved') {
      title = 'Product Approved';
      body = 'Your product "$productTitle" has been approved and is now visible to all users.';
    } else {
      title = 'Product Rejected';
      body = 'Your product "$productTitle" has been rejected.\n\nReason:\n$rejectionReason';
    }

    await sendNotification(
      userId: sellerId,
      type: 'product_approval',
      title: title,
      body: body,
      data: {
        'productId': productId,
        'status': approvalStatus,
      },
    );
  }

  // Create notification helper
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      await docRef.set({
        'id': docRef.id,
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-fatal logging
    }
  }

  // Update full product info
  Future<void> updateProduct(ProductModel product) async {
    await _firestore.collection('products').doc(product.productId).update(product.toMap());
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // Get products by seller
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList();
  }
}
