import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../models/order_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a review using a transaction to update product aggregates
  Future<void> addReview(ReviewModel review) async {
    try {
      final productRef = _firestore.collection('products').doc(review.productId);
      final reviewRef = productRef.collection('reviews').doc();

      // Ensure the generated document ID is stored in the model
      final reviewData = review.toMap();
      reviewData['reviewId'] = reviewRef.id;

      await _firestore.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);
        if (!productDoc.exists) {
          throw Exception("Product not found");
        }

        final data = productDoc.data()!;
        final currentAvg = (data['averageRating'] ?? 0.0).toDouble();
        final currentCount = (data['reviewCount'] ?? 0).toInt();

        final newCount = currentCount + 1;
        final newAvg = ((currentAvg * currentCount) + review.rating) / newCount;

        transaction.set(reviewRef, reviewData);
        transaction.update(productRef, {
          'averageRating': newAvg,
          'reviewCount': newCount,
        });
      });
    } catch (e) {
      debugPrint('ReviewService: addReview error: $e');
      rethrow;
    }
  }

  // Get stream of reviews for a product
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Check if a user is eligible to review a product
  Future<bool> canUserReview(String userId, String productId, String sellerId) async {
    try {
      // 1. Seller cannot review their own product
      if (userId == sellerId) return false;

      // 2. User cannot review multiple times
      final existingReviews = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      if (existingReviews.docs.isNotEmpty) return false;

      // 3. User must have a paid order containing this product
      // We fetch the user's orders and check client-side to avoid composite index requirements
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      for (final order in orders) {
        if (order.status == 'paid') {
          // Check if any item in this paid order matches the productId
          final hasProduct = order.items.any((item) => item['productId'] == productId);
          if (hasProduct) return true;
        }
      }

      return false; // Did not purchase or order is not paid
    } catch (e) {
      debugPrint('ReviewService: canUserReview error: $e');
      return false;
    }
  }
}
