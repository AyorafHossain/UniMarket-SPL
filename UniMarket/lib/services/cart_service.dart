import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time stream of user's cart
  Stream<List<CartItemModel>> getCartStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CartItemModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Add item to cart
  Future<void> addToCart(String userId, CartItemModel item) async {
    final cartRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(item.productId); // Using productId as document ID

    final docSnapshot = await cartRef.get();

    if (docSnapshot.exists) {
      // If product exists, increase quantity
      final existingItem = CartItemModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      await cartRef.update({
        'quantity': existingItem.quantity + 1,
      });
    } else {
      // If product doesn't exist, create it
      await cartRef.set(item.toMap());
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String userId, String productId, int newQuantity) async {
    final cartRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId);

    if (newQuantity <= 0) {
      await removeFromCart(userId, productId);
    } else {
      await cartRef.update({'quantity': newQuantity});
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String userId, String productId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  // Clear entire cart
  Future<void> clearCart(String userId) async {
    final cartRef = _firestore.collection('users').doc(userId).collection('cart');
    final snapshots = await cartRef.get();
    
    // Use a batch to delete all items efficiently
    final batch = _firestore.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
