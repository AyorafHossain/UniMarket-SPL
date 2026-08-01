import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> _statusOptions = [
    'All',
    'pending_payment',
    'paid',
    'failed',
    'cancelled',
    'completed'
  ];

  void _showOrderDetails(OrderModel order) {
    String currentStatus = order.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order.id}',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A5F),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Buyer Information',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Buyer Name', order.buyerName),
                      _buildDetailRow('Buyer Email', order.buyerEmail),
                      _buildDetailRow('Buyer Phone', order.buyerPhone),
                      _buildDetailRow('Created At', order.createdAt.toLocal().toString()),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Items Ordered',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // List of items
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        item['imageUrl'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image, size: 50),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.image, size: 50),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['productName'] ?? 'Product',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text('Quantity: ${item['quantity']} | Price: ৳${item['price']}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildDetailRow('Total Amount', '৳${order.totalAmount.toStringAsFixed(2)}'),
                      _buildDetailRow('Payment Method', order.paymentMethod.toUpperCase()),
                      _buildDetailRow('Current Status', order.status.toUpperCase(),
                          valueColor: order.status == 'paid'
                              ? Colors.green
                              : order.status == 'pending_payment'
                                  ? Colors.amber
                                  : Colors.red),
                      const SizedBox(height: 24),
                      // Dropdown to update order status
                      Row(
                        children: [
                          const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: currentStatus,
                              items: _statusOptions.where((s) => s != 'All').map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase(), overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    currentStatus = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _orderService.updateOrderStatus(order.id, currentStatus);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Order status updated!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                              child: const Text('Update Status', textAlign: TextAlign.center),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: valueColor ?? const Color(0xFF1E3A5F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              final isNarrow = constraints.maxWidth < 650;
              final statusDropdown = DropdownButtonFormField<String>(
                initialValue: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter Status',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: _statusOptions.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _statusFilter = val;
                    });
                  }
                },
              );

              final searchField = TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search buyer name...',
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
                      'Orders List',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    statusDropdown,
                    const SizedBox(height: 12),
                    searchField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Orders List',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 150, child: statusDropdown),
                  const SizedBox(width: 16),
                  SizedBox(width: 250, child: searchField),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _orderService.getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading orders: ${snapshot.error}'));
                }

                var list = snapshot.data ?? [];
                if (_statusFilter != 'All') {
                  list = list.where((o) => o.status == _statusFilter).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  list = list.where((o) => o.buyerName.toLowerCase().contains(_searchQuery)).toList();
                }

                if (list.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }

                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A5F).withValues(alpha: 0.05)),
                        columns: [
                          DataColumn(label: Text('ID', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Buyer', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Date', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                        ],
                        rows: list.map((order) {
                          return DataRow(
                            cells: [
                              DataCell(Text(order.id.length > 8 ? '${order.id.substring(0, 8)}...' : order.id)),
                              DataCell(Text(order.buyerName)),
                              DataCell(Text(order.createdAt.toLocal().toString().split(' ')[0])),
                              DataCell(Text('৳${order.totalAmount.toStringAsFixed(2)}')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order.status == 'paid'
                                        ? Colors.green.shade50
                                        : order.status == 'pending_payment'
                                            ? Colors.amber.shade50
                                            : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(
                                      color: order.status == 'paid'
                                          ? Colors.green.shade800
                                          : order.status == 'pending_payment'
                                              ? Colors.amber.shade800
                                              : Colors.red.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF1E3A5F)),
                                  onPressed: () => _showOrderDetails(order),
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
            ),
          ),
        ],
      ),
    );
  }
}
