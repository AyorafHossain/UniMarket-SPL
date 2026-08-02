import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/rent_request_model.dart';
import '../../providers/user_provider.dart';
import '../../services/rent_service.dart';
import '../../utils/currency_formatter.dart';

class RenterDashboardScreen extends StatefulWidget {
  const RenterDashboardScreen({super.key});

  @override
  State<RenterDashboardScreen> createState() => _RenterDashboardScreenState();
}

class _RenterDashboardScreenState extends State<RenterDashboardScreen> {
  final RentService _rentService = RentService();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
        return AppColors.success;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.userProfile;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Rentals')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Rentals', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<RentRequestModel>>(
        stream: _rentService.getRenterRequests(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading rentals: ${snapshot.error}', style: GoogleFonts.inter(color: AppColors.error)));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 80, color: AppColors.gray300),
                  const SizedBox(height: 16),
                  Text('No rentals yet', style: GoogleFonts.poppins(fontSize: 18, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.gray200),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.gray100,
                              image: request.productImageUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(request.productImageUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: request.productImageUrl.isEmpty
                                ? const Icon(Icons.image_not_supported, color: AppColors.gray300)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(request.productTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Total: ${CurrencyFormatter.format(request.totalAmount)}', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(request.status)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.gray200),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            '${request.startDate.year}-${request.startDate.month.toString().padLeft(2, '0')}-${request.startDate.day.toString().padLeft(2, '0')} to ${request.endDate.year}-${request.endDate.month.toString().padLeft(2, '0')}-${request.endDate.day.toString().padLeft(2, '0')} (${request.rentalDays} days)',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
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
