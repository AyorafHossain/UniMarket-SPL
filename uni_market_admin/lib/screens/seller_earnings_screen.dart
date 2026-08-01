import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class SellerEarningsScreen extends StatefulWidget {
  const SellerEarningsScreen({super.key});

  @override
  State<SellerEarningsScreen> createState() => _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends State<SellerEarningsScreen> {
  final OrderService _orderService = OrderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              
              final searchField = TextField(
                decoration: InputDecoration(
                  hintText: 'Search seller...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller Earnings & Payouts',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    searchField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seller Earnings & Payouts',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 250, child: searchField),
                ],
              );
            }
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

                // Get all users to map sellerId to name
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error loading users: ${userSnapshot.error}'));
                    }

                    // Create user map
                    final Map<String, String> userNames = {};
                    for (var doc in userSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      userNames[doc.id] = data['name'] ?? 'Unknown User';
                    }

                    final orders = orderSnapshot.data ?? [];
                    
                    // Calculate earnings per seller
                    final Map<String, double> sellerEarnings = {};
                    final Map<String, int> sellerItemsSold = {};

                    const validStatuses = ['paid', 'success', 'completed', 'verified'];

                    for (var order in orders) {
                      if (validStatuses.contains(order.status.toLowerCase())) {
                        for (var item in order.items) {
                          // The seller of this specific item
                          final sellerId = item['sellerId'] ?? order.sellerId;
                          if (sellerId != null && sellerId.toString().isNotEmpty) {
                            final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                            final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                            
                            sellerEarnings[sellerId] = (sellerEarnings[sellerId] ?? 0.0) + (price * quantity);
                            sellerItemsSold[sellerId] = (sellerItemsSold[sellerId] ?? 0) + quantity;
                          }
                        }
                      }
                    }

                    // Convert to list for display
                    var earningsList = sellerEarnings.entries.map((e) {
                      final sId = e.key;
                      final sName = userNames[sId] ?? 'Unknown Seller';
                      return {
                        'sellerId': sId,
                        'sellerName': sName,
                        'earnings': e.value,
                        'itemsSold': sellerItemsSold[sId] ?? 0,
                      };
                    }).where((seller) => seller['sellerName'] != 'Unknown Seller').toList();

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      earningsList = earningsList.where((s) {
                        return s['sellerName'].toString().toLowerCase().contains(_searchQuery) ||
                               s['sellerId'].toString().toLowerCase().contains(_searchQuery);
                      }).toList();
                    }

                    // Sort by highest earnings
                    earningsList.sort((a, b) => (b['earnings'] as double).compareTo(a['earnings'] as double));

                    if (earningsList.isEmpty) {
                      return const Center(child: Text('No seller earnings found.'));
                    }

                    return Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A5F).withValues(alpha: 0.05)),
                            columns: [
                              DataColumn(label: Text('Seller Name', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Seller ID', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Items Sold', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Total Earnings', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                            ],
                            rows: earningsList.map((seller) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    seller['sellerName'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  )),
                                  DataCell(Text(
                                    seller['sellerId'].toString().length > 10 
                                      ? '${seller['sellerId'].toString().substring(0, 10)}...' 
                                      : seller['sellerId'].toString(),
                                    style: TextStyle(color: Colors.grey.shade600),
                                  )),
                                  DataCell(Text(seller['itemsSold'].toString())),
                                  DataCell(Text(
                                    '৳${(seller['earnings'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  )),
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
