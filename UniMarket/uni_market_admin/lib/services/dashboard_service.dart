import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardStats {
  final int totalUsers;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final int totalRentRequests;
  final int totalExchangeRequests;
  final Map<String, int> productsByCategory;
  final Map<String, int> ordersStatus;
  final Map<String, int> rentRequestsStatus;
  final Map<String, int> exchangeRequestsStatus;

  DashboardStats({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalRentRequests,
    required this.totalExchangeRequests,
    required this.productsByCategory,
    required this.ordersStatus,
    required this.rentRequestsStatus,
    required this.exchangeRequestsStatus,
  });
}

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DashboardStats> getDashboardStats() async {
    // Fetch users count
    final usersSnap = await _firestore.collection('users').get();
    final totalUsers = usersSnap.docs.length;

    // Fetch products
    final productsSnap = await _firestore.collection('products').get();
    final totalProducts = productsSnap.docs.length;

    // Count products by category
    Map<String, int> productsByCategory = {};
    for (var doc in productsSnap.docs) {
      final category = doc.data()['category']?.toString() ?? 'Other';
      productsByCategory[category] = (productsByCategory[category] ?? 0) + 1;
    }

    // Fetch orders
    final ordersSnap = await _firestore.collection('orders').get();
    final totalOrders = ordersSnap.docs.length;

    double totalRevenue = 0;
    Map<String, int> ordersStatus = {};
    for (var doc in ordersSnap.docs) {
      final data = doc.data();
      final status = data['status']?.toString() ?? 'pending';
      ordersStatus[status] = (ordersStatus[status] ?? 0) + 1;

      if (status == 'paid') {
        final amount = (data['totalAmount'] ?? 0.0) as num;
        totalRevenue += amount.toDouble();
      }
    }

    // Fetch rent requests
    final rentSnap = await _firestore.collection('rentRequests').get();
    final totalRentRequests = rentSnap.docs.length;

    Map<String, int> rentRequestsStatus = {};
    for (var doc in rentSnap.docs) {
      final status = doc.data()['status']?.toString() ?? 'pending';
      rentRequestsStatus[status] = (rentRequestsStatus[status] ?? 0) + 1;
    }

    // Fetch exchange requests
    final exchangeSnap = await _firestore.collection('exchangeRequests').get();
    final totalExchangeRequests = exchangeSnap.docs.length;

    Map<String, int> exchangeRequestsStatus = {};
    for (var doc in exchangeSnap.docs) {
      final status = doc.data()['status']?.toString() ?? 'pending';
      exchangeRequestsStatus[status] = (exchangeRequestsStatus[status] ?? 0) + 1;
    }

    return DashboardStats(
      totalUsers: totalUsers,
      totalProducts: totalProducts,
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      totalRentRequests: totalRentRequests,
      totalExchangeRequests: totalExchangeRequests,
      productsByCategory: productsByCategory,
      ordersStatus: ordersStatus,
      rentRequestsStatus: rentRequestsStatus,
      exchangeRequestsStatus: exchangeRequestsStatus,
    );
  }
}
