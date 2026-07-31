import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
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
                  // Image Gallery
                  if (product.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product.imageUrls[index],
                                height: 180,
                                width: 240,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 240,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow('Listing Type', product.listingType.toUpperCase()),
                  _buildDetailRow('Category', product.category),
                  _buildDetailRow('Condition', product.condition),
                  _buildDetailRow('Price', '৳${product.price.toStringAsFixed(2)}'),
                  if (product.isRentable)
                    _buildDetailRow('Rent Price/Day', '৳${product.rentPricePerDay.toStringAsFixed(2)}'),
                  if (product.listingType == 'exchange') ...[
                    _buildDetailRow('Wanted Item', product.wantedItem),
                    _buildDetailRow('Exchange Notes', product.exchangeNotes),
                  ],
                  _buildDetailRow('Seller Name', product.sellerName),
                  _buildDetailRow('Location', product.location),
                  _buildDetailRow('Description', product.description),
                  _buildDetailRow('Stock Status', product.stockQuantity > 0 ? 'In Stock (${product.stockQuantity})' : 'Out of Stock'),
                  // Approval Status Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            'Approval Status',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: product.approvalStatus == 'approved'
                                ? Colors.green.shade50
                                : product.approvalStatus == 'pending'
                                    ? Colors.orange.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.approvalStatus.toUpperCase(),
                            style: TextStyle(
                              color: product.approvalStatus == 'approved'
                                  ? Colors.green.shade800
                                  : product.approvalStatus == 'pending'
                                      ? Colors.orange.shade800
                                      : Colors.red.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (product.approvalStatus == 'rejected' && product.rejectionReason != null)
                    _buildDetailRow('Rejection Reason', product.rejectionReason!),
                  if (product.approvedBy != null)
                    _buildDetailRow('Reviewed By', product.approvedBy!),
                  if (product.reviewedAt != null)
                    _buildDetailRow('Reviewed At', product.reviewedAt!.toLocal().toString().split('.')[0]),
                  const SizedBox(height: 24),
                  if (product.approvalStatus == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showRejectionReasonDialog(product),
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text('Reject', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
                                await _productService.updateProductApproval(
                                  productId: product.productId,
                                  sellerId: product.sellerId,
                                  approvalStatus: 'approved',
                                  approvedBy: adminUid,
                                  productTitle: product.title,
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Product Approved!'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (product.approvalStatus == 'approved')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRejectionReasonDialog(product),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text('Reject Product', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else if (product.approvalStatus == 'rejected')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
                            await _productService.updateProductApproval(
                              productId: product.productId,
                              sellerId: product.sellerId,
                              approvalStatus: 'approved',
                              approvedBy: adminUid,
                              productTitle: product.title,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product Approved!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text('Approve Now', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRejectionReasonDialog(ProductModel product) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF203A43),
              title: Text(
                'Reject Product',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please enter the reason for rejecting "${product.title}":',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      style: const TextStyle(color: Colors.black87),
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Rejection Reason',
                        labelStyle: const TextStyle(color: Colors.black54),
                        floatingLabelStyle: const TextStyle(color: Color(0xFFD4A017)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD4A017), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Rejection reason is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                          });
                          try {
                            final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
                            await _productService.updateProductApproval(
                              productId: product.productId,
                              sellerId: product.sellerId,
                              approvalStatus: 'rejected',
                              approvedBy: adminUid,
                              productTitle: product.title,
                              rejectionReason: reasonController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(context); // Close reason dialog
                              Navigator.pop(context); // Close details dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product Rejected successfully.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Reject Product', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to permanently delete this product? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _productService.deleteProduct(productId);
      if (mounted) {
        Navigator.pop(context); // Close details dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
              value.isNotEmpty ? value : 'N/A',
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

  Widget _buildProductTable(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products in this category.'));
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
              DataColumn(label: Text('Category', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Price', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Seller', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Type', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            image: product.imageUrls.isNotEmpty
                                ? DecorationImage(image: NetworkImage(product.imageUrls.first), fit: BoxFit.cover)
                                : null,
                          ),
                          child: product.imageUrls.isEmpty ? const Icon(Icons.image, size: 16) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(product.title.length > 25 ? '${product.title.substring(0, 22)}...' : product.title),
                      ],
                    ),
                  ),
                  DataCell(Text(product.category)),
                  DataCell(Text('৳${product.price.toStringAsFixed(2)}')),
                  DataCell(Text(product.sellerName)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.listingType == 'exchange'
                            ? Colors.orange.shade50
                            : product.listingType == 'rent'
                                ? Colors.teal.shade50
                                : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.listingType.toUpperCase(),
                        style: TextStyle(
                          color: product.listingType == 'exchange'
                              ? Colors.orange.shade800
                              : product.listingType == 'rent'
                                  ? Colors.teal.shade800
                                  : Colors.blue.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Color(0xFF1E3A5F)),
                          onPressed: () => _showProductDetails(product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(product.productId),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
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
                  hintText: 'Search by title...',
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
                      'Products Catalog',
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
                      'Products Catalog',
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
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E3A5F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFD4A017),
            tabs: const [
              Tab(text: 'Pending Approval'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var list = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  list = list.where((p) => p.title.toLowerCase().contains(_searchQuery)).toList();
                }

                final pending = list.where((p) => p.approvalStatus == 'pending').toList();
                final approved = list.where((p) => p.approvalStatus == 'approved').toList();
                final rejected = list.where((p) => p.approvalStatus == 'rejected').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductTable(pending),
                    _buildProductTable(approved),
                    _buildProductTable(rejected),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
