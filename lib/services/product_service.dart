import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import 'cloudinary_service.dart';
import 'notification_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for products in Firestore
  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  // Create - Add a new product to Firestore
  Future<void> createProduct(ProductModel product) async {
    try {
      debugPrint('Firestore Query: set -> /products/${product.productId}');
      await _productsCollection.doc(product.productId).set(product.toMap());
    } catch (e) {
      debugPrint('ProductService: createProduct error: $e');
      rethrow;
    }
  }

  // Read - Fetch a single product by productId
  Future<ProductModel?> getProduct(String productId) async {
    try {
      debugPrint('Firestore Query: get -> /products/$productId');
      final doc = await _productsCollection.doc(productId).get();
      if (doc.exists && doc.data() != null) {
        return ProductModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('ProductService: getProduct error: $e');
      rethrow;
    }
  }

  // Update - Modify an existing product in Firestore
  Future<void> updateProduct(ProductModel product) async {
    try {
      debugPrint('Firestore Query: update -> /products/${product.productId}');
      await _productsCollection.doc(product.productId).update(product.toMap());
    } catch (e) {
      debugPrint('ProductService: updateProduct error: $e');
      rethrow;
    }
  }

  // Delete - Remove a product from Firestore
  Future<void> deleteProduct(String productId) async {
    try {
      debugPrint('Firestore Query: delete -> /products/$productId');
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      debugPrint('ProductService: deleteProduct error: $e');
      rethrow;
    }
  }

  // Fetch all products ordered by creation date descending (newest first)
  Future<List<ProductModel>> getAllProducts() async {
    try {
      debugPrint('Firestore Query: get -> /products (orderBy createdAt)');
      final snapshot = await _productsCollection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('ProductService: getAllProducts error: $e');
      rethrow;
    }
  }

  // Fetch products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      debugPrint('Firestore Query: get -> /products (where category=$category)');
      final snapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('ProductService: getProductsByCategory error: $e');
      rethrow;
    }
  }

  // Fetch products posted by a specific seller (user)
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    try {
      debugPrint('Firestore Query: get -> /products (where sellerId=$sellerId)');
      final snapshot = await _productsCollection
          .where('sellerId', isEqualTo: sellerId)
          .get();
      
      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
          
      // Sort client-side to avoid requiring a composite index
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return products;
    } catch (e) {
      debugPrint('ProductService: getProductsBySeller error: $e');
      rethrow;
    }
  }
  // Fetch products posted by a specific seller (user) (Stream)
  Stream<List<ProductModel>> getProductsBySellerStream(String sellerId) {
    debugPrint('Firestore Query: snapshot -> /products (where sellerId=$sellerId)');
    return _productsCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
      // Sort client-side to avoid requiring a composite index
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // Upload a product image to Cloudinary and return secure URL
  Future<String> uploadProductImage(File image, String uid, int index) async {
    try {
      debugPrint("uploadProductImage: image local path: ${image.path}");

      final file = File(image.path);
      final bool fileExists = await file.exists();
      debugPrint("uploadProductImage: file exists: $fileExists");

      if (!fileExists) {
        throw Exception("Selected image file does not exist");
      }

      final cloudinaryService = CloudinaryService();
      final downloadUrl = await cloudinaryService.uploadImage(
        imageFile: file,
        folder: 'product_images/$uid',
      );
      return downloadUrl;
    } catch (e) {
      debugPrint('ProductService: uploadProductImage error: $e');
      rethrow;
    }
  }

  // Get a real-time stream of all products, ordered by newest first
  Stream<List<ProductModel>> getProductsStream() {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('=== FIRESTORE QUERY DEBUG ===');
    debugPrint('User UID: ${user?.uid}');
    debugPrint('User Email: ${user?.email}');
    debugPrint('User Email Verified: ${user?.emailVerified}');
    debugPrint('Collection: /products');
    debugPrint('Filters: orderBy(createdAt, descending: true)');
    debugPrint('=============================');
    
    return _productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Notify users when a product price drops
  Future<void> notifyWishlistUsersForPriceDrop(ProductModel product, double oldPrice, double newPrice) async {
    try {
      int notifiedCount = 0;
      Set<String> notifiedUsers = {};

      // 1. Query root wishlistItems collection (scalable approach)
      try {
        debugPrint('Firestore Query: get -> /wishlistItems (where productId=${product.productId})');
        final wishlistItemsSnap = await _firestore
            .collection('wishlistItems')
            .where('productId', isEqualTo: product.productId)
            .get();

        for (var doc in wishlistItemsSnap.docs) {
          final userId = doc.data()['userId'] as String?;
          if (userId != null && userId != product.sellerId && !notifiedUsers.contains(userId)) {
            await NotificationService().createNotification(
              userId: userId,
              type: 'wishlist_price_drop',
              title: 'Price Drop Alert',
              body: '${product.title} price dropped from ৳$oldPrice to ৳$newPrice',
              data: {
                'productId': product.productId,
                'productTitle': product.title,
                'oldPrice': oldPrice,
                'newPrice': newPrice,
              },
            );
            notifiedUsers.add(userId);
            notifiedCount++;
          }
        }
      } catch (e) {
        debugPrint('Error querying wishlistItems: $e');
      }

      // 2. Query all users as a fallback for old wishlists (satisfies "query all users carefully")
      debugPrint('Firestore Query: get -> /users');
      final usersSnap = await _firestore.collection('users').get();
      for (var userDoc in usersSnap.docs) {
        final userId = userDoc.id;
        
        // Skip if seller or already notified
        if (userId == product.sellerId || notifiedUsers.contains(userId)) continue;
        
        debugPrint('Firestore Query: get -> /users/$userId/wishlist/${product.productId}');
        final wishDoc = await userDoc.reference.collection('wishlist').doc(product.productId).get();
        if (wishDoc.exists) {
          await NotificationService().createNotification(
            userId: userId,
            type: 'wishlist_price_drop',
            title: 'Price Drop Alert',
            body: '${product.title} price dropped from ৳$oldPrice to ৳$newPrice',
            data: {
              'productId': product.productId,
              'productTitle': product.title,
              'oldPrice': oldPrice,
              'newPrice': newPrice,
            },
          );
          notifiedUsers.add(userId);
          notifiedCount++;
        }
      }
      
      debugPrint('Wishlist users found: ${notifiedUsers.length}');
      debugPrint('Notifications created: $notifiedCount');
      debugPrint('OldPrice: $oldPrice, NewPrice: $newPrice, ProductID: ${product.productId}');
    } catch (e) {
      debugPrint('Error sending price drop notifications: $e');
    }
  }
}
