import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/exchange_request_model.dart';
import '../../services/exchange_service.dart';
import '../../theme/app_colors.dart';

class MyExchangesScreen extends StatefulWidget {
  const MyExchangesScreen({Key? key}) : super(key: key);

  @override
  State<MyExchangesScreen> createState() => _MyExchangesScreenState();
}

class _MyExchangesScreenState extends State<MyExchangesScreen> {
  final ExchangeService _exchangeService = ExchangeService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Exchanges',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Please login to view your exchanges'))
          : StreamBuilder<List<ExchangeRequestModel>>(
              stream: _exchangeService.getMyExchangeRequests(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading exchanges',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  );
                }

                final exchanges = snapshot.data ?? [];

                if (exchanges.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz_outlined,
                            size: 64, color: AppColors.gray400),
                        const SizedBox(height: 16),
                        Text(
                          'No exchange requests yet',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When you request an exchange, it will appear here.',
                          style: GoogleFonts.inter(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exchanges.length,
                  itemBuilder: (context, index) {
                    final exchange = exchanges[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.gray200),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Requested: ${exchange.requestedProductName}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  margin: const EdgeInsets.left(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(exchange.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    exchange.status.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: _getStatusColor(exchange.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              'Offered Item Details:',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exchange.offeredProductDetails,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${DateFormat('MMM dd, yyyy').format(exchange.createdAt)}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.gray500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
