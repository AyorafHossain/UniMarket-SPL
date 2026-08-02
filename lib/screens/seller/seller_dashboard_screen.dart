import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../providers/user_provider.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../constants/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../models/rent_request_model.dart';
import '../../services/rent_service.dart';
import '../../models/exchange_request_model.dart';
import '../../services/exchange_service.dart';
import 'edit_product_screen.dart';
import 'seller_orders_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final RentService _rentService = RentService();
  final ExchangeService _exchangeService = ExchangeService();

  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  String? _sellerId;
  bool _isLoading = true;
  String? _error;

  StreamSubscription? _productsSub;
  StreamSubscription? _ordersSub;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final uid = userProvider.userProfile?.id;

      if (uid == null) {
        throw Exception('User not logged in');
      }
      
      _sellerId = uid;

      _productsSub?.cancel();
      _ordersSub?.cancel();

      // Listen to products
      _productsSub = _productService.getProductsBySellerStream(uid).listen((products) {
        if (mounted) {
          setState(() {
            _products = products;
            if (_orders.isNotEmpty || _ordersSub != null) _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      });

      // Listen to orders
      _ordersSub = _orderService.getSellerOrders(uid).listen((orders) {
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      });

    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('failed-precondition')) {
        errorMessage = 'Database index is currently building. Please try again in a few minutes.';
      }
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete "${product.title}"? This cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _productService.deleteProduct(product.productId);
        await _fetchDashboardData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete product: $e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEdit(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProductScreen(product: product)),
    );
    if (result == true) {
      _fetchDashboardData();
    }
  }

  int get _activeListings => _products.where((p) => p.stockQuantity > 0).length;

  int get _soldItems {
    int count = 0;
    const validStatuses = ['paid', 'success', 'completed', 'verified'];
    
    for (var order in _orders) {
      if (validStatuses.contains(order.status.toLowerCase())) {
        for (var item in order.items) {
          final itemSellerId = item['sellerId'] ?? order.sellerId;
          if (itemSellerId == _sellerId) {
            count += (item['quantity'] as num).toInt();
          }
        }
      }
    }
    
    debugPrint('Seller: $_sellerId, Calculated Sold Items: $count');
    return count;
  }

  double get _totalEarnings {
    double total = 0.0;
    const validStatuses = ['paid', 'success', 'completed', 'verified'];
    
    for (var order in _orders) {
      if (validStatuses.contains(order.status.toLowerCase())) {
        for (var item in order.items) {
          final itemSellerId = item['sellerId'] ?? order.sellerId;
          if (itemSellerId == _sellerId) {
            final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            total += (price * quantity);
            
            debugPrint('Matching item: ${item['productName'] ?? item['productTitle']} | Price: $price | Qty: $quantity');
          }
        }
      }
    }
    
    debugPrint('Seller: $_sellerId, Calculated Total Earnings: $total');
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Seller Dashboard', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Error loading dashboard', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_error!, style: GoogleFonts.inter(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Analytics Grid
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard('Total Products', _products.length.toString(), Icons.inventory_2_outlined, AppColors.primary),
                            _buildStatCard('Active Listings', _activeListings.toString(), Icons.local_offer_outlined, AppColors.success),
                            _buildStatCard('Sold Items', _soldItems.toString(), Icons.shopping_bag_outlined, AppColors.secondary),
                            _buildStatCard('Total Earnings', CurrencyFormatter.format(_totalEarnings), Icons.account_balance_wallet_outlined, AppColors.warning),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'My Listings',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _products.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_outlined, size: 64, color: AppColors.gray200),
                                      const SizedBox(height: 16),
                                      Text('You have no listings yet.', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  final product = _products[index];
                                  return _buildProductCard(product);
                                },
                              ),
                        if (_sellerId != null) _buildRentRequests(_sellerId!),
                        if (_sellerId != null) _buildExchangeRequests(_sellerId!),
                        if (_sellerId != null) _buildReceivedOrders(_sellerId!),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRentRequests(String sellerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Rent Requests', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        StreamBuilder<List<RentRequestModel>>(
          stream: _rentService.getSellerRentRequests(sellerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return Text('Error loading requests', style: GoogleFonts.inter(color: AppColors.error));
            }
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('No rent requests yet.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.gray200)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(request.productTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: request.status == 'pending' ? AppColors.warning.withValues(alpha: 0.1) : AppColors.gray200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(request.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: request.status == 'pending' ? AppColors.warning : AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Renter: ${request.renterName}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                        Text('Dates: ${request.startDate.year}-${request.startDate.month.toString().padLeft(2, '0')}-${request.startDate.day.toString().padLeft(2, '0')} to ${request.endDate.year}-${request.endDate.month.toString().padLeft(2, '0')}-${request.endDate.day.toString().padLeft(2, '0')} (${request.rentalDays} days)', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        Text('Total: ${CurrencyFormatter.format(request.totalAmount)}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        if (request.status == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _rentService.updateRequestStatus(request.rentRequestId, 'rejected'),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _rentService.updateRequestStatus(request.rentRequestId, 'accepted'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ],
                          ),
                        ] else if (request.status == 'accepted') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _rentService.updateRequestStatus(request.rentRequestId, 'completed'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                              child: const Text('Mark Completed'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildExchangeRequests(String sellerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Exchange Requests', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        StreamBuilder<List<ExchangeRequestModel>>(
          stream: _exchangeService.getSellerExchangeRequests(sellerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              debugPrint('ExchangeRequests error: ${snapshot.error}');
              return Text('Unable to load exchange requests. Please try again.', style: GoogleFonts.inter(color: AppColors.error));
            }
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('No exchange requests yet.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.gray200)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(request.productTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: request.status == 'pending' ? AppColors.warning.withValues(alpha: 0.1) : AppColors.gray200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(request.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: request.status == 'pending' ? AppColors.warning : AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Requester: ${request.requesterName}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                        Text('Offering: ${request.message}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        if (request.status == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _exchangeService.updateRequestStatus(request.requestId, 'rejected'),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _exchangeService.updateRequestStatus(request.requestId, 'accepted'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ],
                          ),
                        ] else if (request.status == 'accepted') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _exchangeService.updateRequestStatus(request.requestId, 'completed'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                              child: const Text('Mark Completed'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedOrders(String sellerId) {
    // Filter orders where the seller is involved and it's paid/completed
    final validStatuses = ['paid', 'success', 'completed', 'verified'];
    final sellerOrders = _orders.where((order) {
      if (!validStatuses.contains(order.status.toLowerCase())) return false;
      return order.items.any((item) => (item['sellerId'] ?? order.sellerId) == sellerId);
    }).toList();

    final recentOrders = sellerOrders.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Orders Received', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            if (sellerOrders.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SellerOrdersScreen(),
                    ),
                  );
                },
                child: Text('View All', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (sellerOrders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text('No orders received yet.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentOrders.length,
            itemBuilder: (context, index) {
              final order = recentOrders[index];
              // Filter items specific to this seller
              final sellerItems = order.items.where((item) => (item['sellerId'] ?? order.sellerId) == sellerId).toList();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.gray200)),
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
                              'Order #${order.id.substring(0, 8)}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
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
            },
          ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.gray200,
                  child: const Icon(Icons.image_not_supported, color: AppColors.textLight),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.listingType == 'exchange')
                    Text(
                      'Wants: ${product.wantedItem}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.stockQuantity > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.stockQuantity > 0 ? 'Stock: ${product.stockQuantity}' : 'Out of Stock',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.stockQuantity > 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 20),
                  onPressed: () => _navigateToEdit(product),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _deleteProduct(product),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
