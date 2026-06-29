import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_market/models/product_model.dart';

class WishlistService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the user's wishlist subcollection
  CollectionReference<Map<String, dynamic>> _wishlistItemsRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in');
    return _firestore.collection('users').doc(uid).collection('wishlist');
  }

  // Stream of product IDs in the current user's wishlist
  Stream<List<String>> wishlistIds() {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Stream.empty();
      return _wishlistItemsRef().snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => doc.id).toList());
    } catch (e) {
      return const Stream.empty();
    }
  }

  // Stream of full ProductModel objects from the user's wishlist subcollection
  Stream<List<ProductModel>> wishlistProductsStream() {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Stream.empty();
      return _wishlistItemsRef().snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      return const Stream.empty();
    }
  }

  // Stream of full ProductModel objects (requires all products list) - kept for backward compatibility
  Stream<List<ProductModel>> wishlistProducts(Stream<List<ProductModel>> allProductsStream) {
    return wishlistIds().asyncMap((ids) async {
      final allProducts = await allProductsStream.first;
      return allProducts.where((p) => ids.contains(p.productId)).toList();
    });
  }

  // Add or remove a product from the wishlist
  Future<void> toggleItem(ProductModel product) async {
    final coll = _wishlistItemsRef();
    final docRef = coll.doc(product.productId);
    final rootDocRef = _firestore.collection('wishlistItems').doc('${_auth.currentUser?.uid}_${product.productId}');

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      // Remove
      await docRef.delete();
      await rootDocRef.delete();
    } else {
      // Add with timestamp and entire product data
      final data = product.toMap();
      data['addedAt'] = FieldValue.serverTimestamp();
      await docRef.set(data);

      // Add to root collection for scalable querying
      await rootDocRef.set({
        'userId': _auth.currentUser?.uid,
        'productId': product.productId,
        'productTitle': product.title,
        'productImageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
