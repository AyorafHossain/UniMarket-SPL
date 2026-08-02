import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exchange_request_model.dart';
import '../services/exchange_service.dart';

class ExchangeRequestsScreen extends StatefulWidget {
  const ExchangeRequestsScreen({super.key});

  @override
  State<ExchangeRequestsScreen> createState() => _ExchangeRequestsScreenState();
}

class _ExchangeRequestsScreenState extends State<ExchangeRequestsScreen> {
  final ExchangeService _exchangeService = ExchangeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showExchangeDetails(ExchangeRequestModel request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Exchange Request Details',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Request ID', request.requestId),
                _buildDetailRow('Product ID', request.productId),
                _buildDetailRow('Product Title', request.productTitle),
                _buildDetailRow('Requester Name', request.requesterName),
                _buildDetailRow('Offered Item', request.wantedItem),
                _buildDetailRow('Message', request.message),
                _buildDetailRow('Status', request.status.toUpperCase(),
                    valueColor: request.status == 'accepted'
                        ? Colors.green
                        : request.status == 'pending'
                            ? Colors.amber
                            : Colors.red),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (request.status == 'pending') ...[
              ElevatedButton(
                onPressed: () async {
                  await _exchangeService.updateExchangeRequestStatus(request.requestId, 'rejected');
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exchange Request Rejected'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _exchangeService.updateExchangeRequestStatus(request.requestId, 'accepted');
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exchange Request Approved!'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve', style: TextStyle(color: Colors.white)),
              ),
            ]
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: valueColor ?? const Color(0xFF1E3A5F)),
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
              final isNarrow = constraints.maxWidth < 600;
              final searchField = TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by requester name...',
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
                      'Exchange Requests Management',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    searchField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Exchange Requests Management',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 300, child: searchField),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<ExchangeRequestModel>>(
              stream: _exchangeService.getExchangeRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading exchange requests: ${snapshot.error}'));
                }

                var list = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  list = list.where((r) => r.requesterName.toLowerCase().contains(_searchQuery)).toList();
                }

                if (list.isEmpty) {
                  return const Center(child: Text('No exchange requests found.'));
                }

                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A5F).withValues(alpha: 0.05)),
                        columns: [
                          DataColumn(label: Text('Product', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Requester', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Offered Item', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Action', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                        ],
                        rows: list.map((request) {
                          return DataRow(
                            cells: [
                              DataCell(Text(request.productTitle.length > 25 ? '${request.productTitle.substring(0, 22)}...' : request.productTitle)),
                              DataCell(Text(request.requesterName)),
                              DataCell(Text(request.wantedItem)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: request.status == 'accepted'
                                        ? Colors.green.shade50
                                        : request.status == 'pending'
                                            ? Colors.amber.shade50
                                            : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    request.status.toUpperCase(),
                                    style: TextStyle(
                                      color: request.status == 'accepted'
                                          ? Colors.green.shade800
                                          : request.status == 'pending'
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
                                  onPressed: () => _showExchangeDetails(request),
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
