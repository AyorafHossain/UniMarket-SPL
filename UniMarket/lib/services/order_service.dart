import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new order with pending payment status
  Future<String> createOrder(OrderModel order) async {
    // Generate a unique document ID
    final docRef = _firestore.collection('orders').doc();
    
    // We use the document ID as the transaction/order ID
    final newOrder = OrderModel(
      id: docRef.id,
      userId: order.userId,
      sellerId: order.sellerId,
      items: order.items,
      totalAmount: order.totalAmount,
      status: 'pending_payment',
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      buyerName: order.buyerName,
      buyerEmail: order.buyerEmail,
      buyerPhone: order.buyerPhone,
    );

    await docRef.set(newOrder.toMap());
    return docRef.id;
  }

  // Update order status after payment attempt (for failed/cancelled)
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  // Mark order as paid and reduce product stock safely using a transaction
  Future<void> markOrderPaidAndReduceStock(String orderId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    
    await _firestore.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) throw Exception('Order not found');
      
      final orderData = orderDoc.data()!;
      final bool stockUpdated = orderData['stockUpdated'] ?? false;
      
      if (stockUpdated) {
        // Stock already updated, just ensure status is paid
        transaction.update(orderRef, {'status': 'paid'});
        return;
      }
      
      final List<dynamic> items = orderData['items'] ?? [];
      
      // Firestore transactions require all reads to happen before writes.
      // So we collect all product references and read them first.
      Map<String, DocumentReference> productRefs = {};
      Map<String, DocumentSnapshot> productSnapshots = {};
      
      for (var item in items) {
        final productId = item['productId'];
        if (productId != null && productId.toString().isNotEmpty) {
          final pRef = _firestore.collection('products').doc(productId);
          productRefs[productId] = pRef;
          productSnapshots[productId] = await transaction.get(pRef);
        }
      }
      
      // Calculate new stocks
      Map<String, int> newStocks = {};
      for (var item in items) {
        final productId = item['productId'];
        final int quantity = (item['quantity'] ?? 0).toInt();
        
        if (productId != null && quantity > 0 && productSnapshots.containsKey(productId)) {
          final pDoc = productSnapshots[productId]!;
          if (pDoc.exists) {
            final int currentStock = (pDoc.data() as Map<String, dynamic>)['stockQuantity'] ?? 0;
            
            // If multiple of the same item exist in cart, accumulate reduction
            final int stockToReduceFrom = newStocks.containsKey(productId) 
                ? newStocks[productId]! 
                : currentStock;
                
            if (stockToReduceFrom < quantity) {
              throw Exception('Not enough stock available for ${item['productName']}');
            }
            
            newStocks[productId] = stockToReduceFrom - quantity;
          }
        }
      }
      
      // Perform all writes
      for (var entry in newStocks.entries) {
        transaction.update(productRefs[entry.key]!, {
          'stockQuantity': entry.value,
        });
      }
      
      transaction.update(orderRef, {
        'status': 'paid',
        'stockUpdated': true,
      });
    });
  }

  // Get order stream for a specific user
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  // Get order stream for a specific seller
  Stream<List<OrderModel>> getSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }
}
