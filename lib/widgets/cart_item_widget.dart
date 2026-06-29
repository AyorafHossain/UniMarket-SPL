import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemWidget extends StatelessWidget {
  final CartItemModel item;

  const CartItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: AppColors.gray200,
                child: const Icon(Icons.broken_image, color: AppColors.textLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(item.price),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () {
                  context.read<CartProvider>().removeItem(item.productId);
                },
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').doc(item.productId).snapshots(),
                  builder: (context, snapshot) {
                    int maxStock = 9999;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      maxStock = (snapshot.data!.data() as Map<String, dynamic>)['stockQuantity'] ?? 0;
                    }

                    return Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (item.quantity > 1) {
                              context.read<CartProvider>().updateQuantity(item.productId, item.quantity - 1);
                            } else {
                              context.read<CartProvider>().removeItem(item.productId);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${item.quantity}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (item.quantity >= maxStock) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Only $maxStock items available in stock.')),
                              );
                            } else {
                              context.read<CartProvider>().updateQuantity(item.productId, item.quantity + 1);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.add, 
                              size: 16, 
                              color: item.quantity >= maxStock && snapshot.hasData ? AppColors.textLight : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
