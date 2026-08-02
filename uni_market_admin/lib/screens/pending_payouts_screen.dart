import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class PendingPayoutsScreen extends StatefulWidget {
  const PendingPayoutsScreen({super.key});

  @override
  State<PendingPayoutsScreen> createState() => _PendingPayoutsScreenState();
}

class _PendingPayoutsScreenState extends State<PendingPayoutsScreen> {
  final OrderService _orderService = OrderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Payouts',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders received by buyers. Pay the seller and mark as paid.',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _orderService.getOrdersStream(),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (orderSnapshot.hasError) {
                  return Center(child: Text('Error loading orders: ${orderSnapshot.error}'));
                }

                // Get all users to map seller details
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error loading users: ${userSnapshot.error}'));
                    }

                    // Create user maps
                    final Map<String, String> userNames = {};
                    final Map<String, String> userPhones = {};
                    for (var doc in userSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      userNames[doc.id] = data['name'] ?? 'Unknown Seller';
                      userPhones[doc.id] = data['phoneNumber'] ?? 'No Phone';
                    }

                    final allOrders = orderSnapshot.data ?? [];
                    // We only want orders where the buyer has received the product (completed)
                    final pendingPayouts = allOrders.where((o) => o.status.toLowerCase() == 'completed').toList();

                    if (pendingPayouts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No pending payouts right now! 🎉',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A5F).withValues(alpha: 0.05)),
                            columns: [
                              DataColumn(label: Text('Order ID', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Seller Name', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Seller Phone / bKash', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Amount to Pay', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                            ],
                            rows: pendingPayouts.map((order) {
                              // Get the seller from the first item or order.sellerId
                              final String sellerId = order.items.isNotEmpty 
                                  ? (order.items.first['sellerId'] ?? order.sellerId) 
                                  : order.sellerId;
                                  
                              final sellerName = userNames[sellerId] ?? 'Unknown Seller';
                              final sellerPhone = userPhones[sellerId] ?? 'No Phone';

                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    order.id.length > 8 ? '${order.id.substring(0, 8)}...' : order.id,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  )),
                                  DataCell(Text(sellerName)),
                                  DataCell(Text(sellerPhone)),
                                  DataCell(Text(
                                    '৳${order.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                  )),
                                  DataCell(
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        // Confirm dialog
                                        bool confirm = await showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Confirm Payment'),
                                            content: Text('Did you pay ৳${order.totalAmount.toStringAsFixed(2)} to $sellerName ($sellerPhone)?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                child: const Text('Yes, Paid', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ) ?? false;

                                        if (confirm && context.mounted) {
                                          await _orderService.updateOrderStatus(order.id, 'settled');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Marked as Settled!'), backgroundColor: Colors.green),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                      label: const Text('Mark as Paid', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
