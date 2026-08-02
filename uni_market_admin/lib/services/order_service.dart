import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all orders
  Stream<List<OrderModel>> getOrdersStream() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  // Verify and mark order as paid + reduce stock in transaction
  Future<void> markOrderPaidAndReduceStock(String orderId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    
    await _firestore.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) throw Exception('Order not found');
      
      final orderData = orderDoc.data()!;
      final bool stockUpdated = orderData['stockUpdated'] ?? false;
      
      if (stockUpdated) {
        transaction.update(orderRef, {
          'status': 'paid',
          'paymentStatus': 'paid',
        });
        return;
      }
      
      final List<dynamic> items = orderData['items'] ?? [];
      
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
      
      Map<String, int> newStocks = {};
      for (var item in items) {
        final productId = item['productId'];
        final int quantity = (item['quantity'] ?? 0).toInt();
        
        if (productId != null && quantity > 0 && productSnapshots.containsKey(productId)) {
          final pDoc = productSnapshots[productId]!;
          if (pDoc.exists) {
            final int currentStock = (pDoc.data() as Map<String, dynamic>)['stockQuantity'] ?? 0;
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
      
      for (var entry in newStocks.entries) {
        transaction.update(productRefs[entry.key]!, {
          'stockQuantity': entry.value,
        });
      }
      
      transaction.update(orderRef, {
        'status': 'paid',
        'stockUpdated': true,
        'paymentStatus': 'paid',
      });
    });
  }
}
