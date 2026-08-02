import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/exchange_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/exchange_service.dart';

class MyExchangesScreen extends StatelessWidget {
  const MyExchangesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Exchanges')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Exchanges',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<ExchangeRequestModel>>(
        stream: ExchangeService().getMyExchangeRequests(user.uid),
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

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.autorenew_outlined, size: 64, color: AppColors.gray200),
                  const SizedBox(height: 16),
                  Text(
                    'No exchange requests found',
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
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildExchangeCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildExchangeCard(ExchangeRequestModel request) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(request.createdAt);
    
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
                    request.productTitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Requested on $formattedDate',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 16, color: AppColors.gray200),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.gray100,
                    image: request.productImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(request.productImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: request.productImageUrl.isEmpty
                      ? const Icon(Icons.image_outlined, color: AppColors.gray200)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offering to exchange with:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.wantedItem,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'accepted':
      case 'approved':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'rejected':
      case 'declined':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        bgColor = AppColors.gray100;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
