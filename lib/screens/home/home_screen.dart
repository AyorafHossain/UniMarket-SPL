import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_widget.dart';
import '../../utils/currency_formatter.dart';
import '../../services/product_service.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables for search and filters
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ProductService _productService = ProductService();
  
  Stream<List<ProductModel>>? _productsStream;
  List<ProductModel> _products = [];
  String _selectedCategory = 'All';
  // New filter state
  

  final double _currentMinPrice = 0;
  final double _currentMaxPrice = 50000;
  final String _selectedCondition = 'All';
  // Condition options
  
  String _searchQuery = '';
  String _currentSort = 'newest';
  bool _isLoading = true;
  Timer? _loadingTimer;

  // Modern category definition with icons
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Textbooks', 'icon': Icons.menu_book_rounded},
    {'name': 'Electronics', 'icon': Icons.devices_rounded},
    {'name': 'Dorm & Living', 'icon': Icons.home_work_rounded},
    {'name': 'Fashion & Apparel', 'icon': Icons.checkroom_rounded},
    {'name': 'Bikes & Rides', 'icon': Icons.directions_bike_rounded},
    {'name': 'Exchange', 'icon': Icons.swap_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _products = [];
    
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Home currentUser: ${user?.uid}');
    debugPrint('Home email: ${user?.email}');
    debugPrint('Loading products from collection: products');
    
    _productsStream = _productService.getProductsStream();
    
    _simulateLoading();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _simulateLoading() {
    setState(() {
      _isLoading = true;
    });
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _productsStream = _productService.getProductsStream();
    });
    _simulateLoading();
    return Future.delayed(const Duration(milliseconds: 1500));
  }

  // Filter products based on search, category, price range, and condition
  List<ProductModel> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || 
          (_selectedCategory == 'Exchange' ? product.listingType == 'exchange' : product.category == _selectedCategory);
      final matchesSearch = product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPrice = product.price >= _currentMinPrice && product.price <= _currentMaxPrice;
      final matchesCondition = _selectedCondition == 'All' || product.condition == _selectedCondition;
      return matchesCategory && matchesSearch && matchesPrice && matchesCondition;
    }).toList();
  }

  List<ProductModel> get _featuredProducts {
    // Featured products are filtered by category but not affected by search query for visual interest, 
    // unless search is active.
    return _products.where((product) {
      if (!product.isFeatured) return false;
      return _selectedCategory == 'All' || 
          (_selectedCategory == 'Exchange' ? product.listingType == 'exchange' : product.category == _selectedCategory);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Determine grid columns dynamically based on screen width
    int crossAxisCount = 2;
    if (screenWidth >= 900) {
      crossAxisCount = 5;
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
    }

    // Dynamic child aspect ratio calculation for proper card rendering
    double childAspectRatio = 0.72;
    if (screenWidth >= 1200) {
      childAspectRatio = 0.75;
    } else if (screenWidth >= 600 && screenWidth < 900) {
      childAspectRatio = 0.74;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.white,
          onRefresh: _handleRefresh,
          child: StreamBuilder<List<ProductModel>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final error = snapshot.error;
                if (error is FirebaseException) {
                  debugPrint('Product load error code: ${error.code}');
                  debugPrint('Product load error message: ${error.message}');
                } else {
                  debugPrint('Product load error: $error');
                }
                return _buildErrorState(error.toString());
              }

              final bool isStreamLoading = snapshot.connectionState == ConnectionState.waiting;
              final bool showLoading = _isLoading || isStreamLoading;

              _products = List<ProductModel>.from(snapshot.data ?? []);
              if (_currentSort == 'lowToHigh') {
                _products.sort((a, b) => a.price.compareTo(b.price));
              } else if (_currentSort == 'highToLow') {
                _products.sort((a, b) => b.price.compareTo(a.price));
              }

              return GestureDetector(
                onTap: () => _searchFocusNode.unfocus(),
                child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Modern Header & Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find campus deals',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Welcome back!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Micro-action: Simple notification button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gray200),
                              ),
                              child: Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final userId = authProvider.user?.uid;
                                  if (userId == null) {
                                    return IconButton(
                                      icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                                      onPressed: () {
                                        Navigator.pushNamed(context, AppConstants.notificationsRoute);
                                      },
                                    );
                                  }
                                  
                                  return StreamBuilder<int>(
                                    stream: NotificationService().getUnreadCount(userId),
                                    builder: (context, snapshot) {
                                      final unreadCount = snapshot.data ?? 0;
                                      return IconButton(
                                        icon: unreadCount > 0 
                                            ? Badge(
                                                label: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(fontSize: 9)),
                                                child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                                              )
                                            : const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                                        onPressed: () {
                                          Navigator.pushNamed(context, AppConstants.notificationsRoute);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Search bar layout
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search books, tech, apparel...',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.textLight,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                                _searchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Filter Button
                            GestureDetector(
                              onTap: () {
                                _showFilterBottomSheet();
                              },
                              child: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Categories Section (Horizontal list)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Categories',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _isLoading 
                            ? _buildShimmerCategoryList()
                            : SizedBox(
                                height: 42,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final cat = _categories[index];
                                    final isSelected = _selectedCategory == cat['name'];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: FilterChip(
                                        avatar: Icon(
                                          cat['icon'], 
                                          size: 16,
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                        ),
                                        label: Text(cat['name']),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedCategory = cat['name'];
                                          });
                                        },
                                        backgroundColor: AppColors.white,
                                        selectedColor: AppColors.primary,
                                        labelStyle: GoogleFonts.inter(
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          side: BorderSide(
                                            color: isSelected ? AppColors.primary : AppColors.gray200,
                                            width: 1,
                                          ),
                                        ),
                                        showCheckmark: false,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                // 3. Featured Products Section
                if (_searchQuery.isEmpty && _featuredProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Featured Deals',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = 'All';
                                    });
                                  },
                                  child: Text(
                                    'Clear Filters',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                           showLoading 
                              ? _buildShimmerFeaturedList()
                              : SizedBox(
                                  height: 255,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    itemCount: _featuredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = _featuredProducts[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                        child: SizedBox(
                                          width: 190,
                                          child: ProductCard(
                                            product: product,
                                            onTap: () => _showProductDetailsDialog(product),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                // 4. Recent Products Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                    child: Text(
                      _searchQuery.isNotEmpty 
                          ? 'Search Results (${_filteredProducts.length})'
                          : 'Recent Uploads',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // 5. Recent Products Grid / Loading State / Empty state
                if (showLoading)
                  _buildShimmerRecentGrid(crossAxisCount, childAspectRatio)
                else if (_filteredProducts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your keywords or category filters.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedCategory = 'All';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _filteredProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () => _showProductDetailsDialog(product),
                          );
                        },
                        childCount: _filteredProducts.length,
                      ),
                    ),
                  ),
                
                // Add padding at the bottom of the scroll view
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          );
        },
      ),
    ),
  ),
);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load products. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _productsStream = _productService.getProductsStream();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // SKELETON SHIMMER WIDGETS
  Widget _buildShimmerCategoryList() {
    return Shimmer(
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: ShimmerLoadingPlaceholder(
                width: 100,
                height: 36,
                borderRadius: 18,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerFeaturedList() {
    return Shimmer(
      child: SizedBox(
        height: 255,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, index) {
            return const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: ShimmerLoadingPlaceholder(
                width: 190,
                height: 255,
                borderRadius: 16,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerRecentGrid(int crossAxisCount, double aspectRatio) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: aspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return const Shimmer(
              child: ShimmerLoadingPlaceholder(
                borderRadius: 16,
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  // DIALOG FOR PRODUCT DETAILS (MOCK INTERACTION)
  void _showProductDetailsDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: AppColors.gray200,
                          child: const Icon(Icons.broken_image, size: 64, color: AppColors.textLight),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.category,
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              product.condition,
                              style: GoogleFonts.inter(
                                color: AppColors.success,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.gray200),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                product.sellerName.substring(0, 1),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.sellerName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${product.sellerRating} Seller Rating',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Contacting ${product.sellerName}...', style: GoogleFonts.inter()),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                            label: const Text('Chat with Seller'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
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

  // BOTTOM SHEET FILTER OPTION MOCK
  // Show filter bottom sheet for price and condition
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Options',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sort by Price',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentSort = 'lowToHigh';
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray100,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                  ),
                  child: const Text('Low to High'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentSort = 'highToLow';
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray100,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                  ),
                  child: const Text('High to Low'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sort by Date',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentSort = 'newest';
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gray100,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
              ),
              child: const Text('Recently Added'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
