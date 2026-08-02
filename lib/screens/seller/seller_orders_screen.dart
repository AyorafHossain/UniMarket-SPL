import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/user_provider.dart';
import '../../services/order_service.dart';
import '../../utils/currency_formatter.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sellerId = userProvider.userProfile?.id;

    if (sellerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Orders')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'All Received Orders',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getSellerOrders(sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            );
          }

          final allOrders = snapshot.data ?? [];
          final validStatuses = ['paid', 'success', 'completed', 'verified'];
          final sellerOrders = allOrders.where((order) {
            if (!validStatuses.contains(order.status.toLowerCase())) return false;
            return order.items.any((item) => (item['sellerId'] ?? order.sellerId) == sellerId);
          }).toList();

          if (sellerOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.gray200),
                  const SizedBox(height: 16),
                  Text(
                    'No orders received yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sellerOrders.length,
            itemBuilder: (context, index) {
              final order = sellerOrders[index];
              final sellerItems = order.items.where((item) => (item['sellerId'] ?? order.sellerId) == sellerId).toList();
              
              return _buildOrderCard(order, sellerItems);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, List<Map<String, dynamic>> sellerItems) {
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status == 'completed' ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: order.status == 'completed' ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.buyerName.isNotEmpty ? order.buyerName : 'Unknown Buyer', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.buyerPhone.isNotEmpty ? order.buyerPhone : 'No phone', style: GoogleFonts.inter(color: AppColors.textSecondary))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.buyerEmail.isNotEmpty ? order.buyerEmail : 'No email', style: GoogleFonts.inter(color: AppColors.textSecondary))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Ordered Items:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            ...sellerItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Text('${item['quantity']}x ', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item['productName'] ?? item['productTitle'] ?? 'Product', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(CurrencyFormatter.format((item['price'] as num?)?.toDouble() ?? 0.0), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
