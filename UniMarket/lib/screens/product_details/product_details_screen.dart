import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../constants/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../services/wishlist_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../providers/user_provider.dart';
import '../chat/chat_room_screen.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../constants/app_constants.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../models/rent_request_model.dart';
import '../../services/rent_service.dart';
import '../../models/exchange_request_model.dart';
import '../../services/exchange_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late ProductModel product;
  int _currentPage = 0;
  bool _productLoaded = false;
  bool _canReview = false;
  bool _isLoadingEligibility = true;
  final ReviewService _reviewService = ReviewService();
  final RentService _rentService = RentService();
  final ExchangeService _exchangeService = ExchangeService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_productLoaded) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is ProductModel) {
        product = args;
      } else {
        // Fallback placeholder product if something went wrong
        product = ProductModel(
          productId: '0',
          sellerId: '',
          title: 'Unknown',
          description: 'No description',
          price: 0,
          category: 'Other',
          condition: 'Good',
          imageUrls: [],
          createdAt: DateTime.now(),
          stockQuantity: 0,
        );
      }
      _productLoaded = true;
      _checkEligibility();
    }
  }

  Future<void> _checkEligibility() async {
    final userProvider = context.read<UserProvider>();
    final uid = userProvider.userProfile?.id;
    if (uid != null) {
      final eligible = await _reviewService.canUserReview(uid, product.productId, product.sellerId);
      if (mounted) {
        setState(() {
          _canReview = eligible;
          _isLoadingEligibility = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _canReview = false;
          _isLoadingEligibility = false;
        });
      }
    }
  }

  Color _conditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
      case 'like new':
        return AppColors.success;
      case 'good':
        return AppColors.primary;
      case 'fair':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReviewDialog() {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.userProfile;
    if (currentUser == null) return;

    int ratingValue = 5;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Write a Review', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < ratingValue ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppColors.warning,
                          size: 32,
                        ),
                        onPressed: () {
                          setModalState(() {
                            ratingValue = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) {
                          _showSnack('Please enter a comment.');
                          return;
                        }

                        Navigator.pop(context);
                        
                        setState(() {
                          _isLoadingEligibility = true; // Show some loading state
                        });

                        try {
                          final review = ReviewModel(
                            reviewId: '',
                            productId: product.productId,
                            userId: currentUser.id,
                            userName: currentUser.name,
                            userProfilePic: currentUser.profilePic,
                            rating: ratingValue.toDouble(),
                            comment: commentController.text.trim(),
                            createdAt: DateTime.now(),
                          );
                          
                          await _reviewService.addReview(review);
                          
                          // Local update for immediate feedback
                          setState(() {
                            product = product.copyWith(
                              averageRating: ((product.averageRating * product.reviewCount) + ratingValue) / (product.reviewCount + 1),
                              reviewCount: product.reviewCount + 1,
                            );
                            _canReview = false;
                            _isLoadingEligibility = false;
                          });
                          
                          if (mounted) _showSnack('Review submitted successfully!');
                        } catch (e) {
                          if (mounted) {
                            setState(() { _isLoadingEligibility = false; });
                            _showSnack('Failed to submit review: $e');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Submit Review', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRentDialog() async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.userProfile;
    if (currentUser == null) {
      _showSnack('Please log in to rent products.');
      return;
    }
    if (product.sellerId == currentUser.id) {
      _showSnack('You cannot rent your own product!');
      return;
    }
    if (product.stockQuantity <= 0) {
      _showSnack('Product is out of stock.');
      return;
    }

    final initialDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 1)),
    );

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final int rentalDays = picked.end.difference(picked.start).inDays;
      if (rentalDays <= 0) {
        _showSnack('Minimum rental period is 1 day.');
        return;
      }

      final double totalAmount = rentalDays * product.rentPricePerDay;

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Rental', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rental Duration: $rentalDays days', style: GoogleFonts.inter()),
              const SizedBox(height: 8),
              Text('Price per Day: ${CurrencyFormatter.format(product.rentPricePerDay)}', style: GoogleFonts.inter()),
              const Divider(height: 24),
              Text('Total Rent: ${CurrencyFormatter.format(totalAmount)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(c);
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final request = RentRequestModel(
                    rentRequestId: '',
                    productId: product.productId,
                    productTitle: product.title,
                    productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    renterId: currentUser.id,
                    renterName: currentUser.name,
                    sellerId: product.sellerId,
                    startDate: picked.start,
                    endDate: picked.end,
                    rentalDays: rentalDays,
                    pricePerDay: product.rentPricePerDay,
                    totalAmount: totalAmount,
                    status: 'pending',
                    createdAt: DateTime.now(),
                  );

                  await _rentService.createRentRequest(request);

                  if (mounted) {
                    Navigator.pop(context); // close loading
                    _showSnack('Rent request sent successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // close loading
                    _showSnack('Failed to send rent request: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm Request'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showExchangeDialog() async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.userProfile;
    if (currentUser == null) {
      _showSnack('Please log in to send exchange requests.');
      return;
    }
    if (product.sellerId == currentUser.id) {
      _showSnack('You cannot exchange your own product!');
      return;
    }

    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Exchange Request', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offering: What do you have to trade?', style: GoogleFonts.inter()),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the item you want to exchange...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) {
                _showSnack('Please describe the item you are offering.');
                return;
              }
              Navigator.pop(c);
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                final request = ExchangeRequestModel(
                  requestId: '',
                  productId: product.productId,
                  productTitle: product.title,
                  productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                  requesterId: currentUser.id,
                  requesterName: currentUser.name,
                  sellerId: product.sellerId,
                  wantedItem: product.wantedItem,
                  message: messageController.text.trim(),
                  status: 'pending',
                  createdAt: DateTime.now(),
                );

                await _exchangeService.createExchangeRequest(request);

                if (mounted) {
                  Navigator.pop(context); // close loading
                  _showSnack('Exchange request sent successfully!');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // close loading
                  _showSnack('Failed to send exchange request: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('products').doc(product.productId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          product = ProductModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
        }

        final bool outOfStock = product.stockQuantity <= 0;
        final size = MediaQuery.of(context).size;
        final bool wide = size.width >= 800;

        Widget carousel = Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: product.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (c, i) {
              final url = product.imageUrls[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, child, prog) => prog == null
                      ? child
                      : Center(child: CircularProgressIndicator()),
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 80),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            product.imageUrls.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 12 : 8,
              height: _currentPage == i ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentPage == i ? AppColors.primary : AppColors.gray200,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );

    Widget details = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              StreamBuilder<List<String>>(
                stream: WishlistService().wishlistIds(),
                builder: (context, snapshot) {
                  final isInWishlist = snapshot.data?.contains(product.productId) ?? false;
                  return IconButton(
                    icon: Icon(
                      isInWishlist ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: isInWishlist ? AppColors.secondary : AppColors.textLight,
                    ),
                    onPressed: () async {
                      await WishlistService().toggleItem(product);
                      if (!mounted) return;
                      _showSnack(
                        isInWishlist
                            ? 'Removed from wishlist!'
                            : 'Added to wishlist!',
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (product.listingType == 'exchange') ...[
            Text(
              'Wants: ${product.wantedItem}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            if (product.exchangeNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${product.exchangeNotes}',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ] else if (product.listingType == 'rent') ...[
            Text(
              '${CurrencyFormatter.format(product.rentPricePerDay)} / day',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ] else if (product.listingType == 'both') ...[
            Text(
              CurrencyFormatter.format(product.price),
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            Text(
              'Rent: ${CurrencyFormatter.format(product.rentPricePerDay)} / day',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ] else ...[
            Text(
              CurrencyFormatter.format(product.price),
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
          if (product.reviewCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _conditionColor(product.condition), borderRadius: BorderRadius.circular(8)),
            child: Text(product.condition, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Text(
            outOfStock ? 'Out of stock' : 'In stock: ${product.stockQuantity}',
            style: GoogleFonts.inter(fontSize: 14, color: outOfStock ? AppColors.error : AppColors.success),
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.gray200),
          Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(product.description, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const Divider(height: 24, thickness: 1, color: AppColors.gray200),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(product.sellerName.isNotEmpty ? product.sellerName[0] : '?', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.sellerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        product.sellerRating > 0 ? product.sellerRating.toStringAsFixed(1) : 'No rating yet',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 2),
              Text(product.location, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Reviews Section
          const Divider(height: 24, thickness: 1, color: AppColors.gray200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reviews', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (_canReview && !_isLoadingEligibility)
                TextButton.icon(
                  onPressed: _showReviewDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.secondary),
                  label: Text('Write a Review', style: GoogleFonts.inter(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                )
              else if (_isLoadingEligibility)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<ReviewModel>>(
            stream: _reviewService.getProductReviews(product.productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                debugPrint('productId: ${product.productId}');
                debugPrint('review collection path: products/${product.productId}/reviews');
                if (snapshot.error is FirebaseException) {
                  final fbError = snapshot.error as FirebaseException;
                  debugPrint('FirebaseException code: ${fbError.code}, message: ${fbError.message}');
                } else {
                  debugPrint('Error: ${snapshot.error}');
                }
                return Center(child: Text('Error loading reviews', style: GoogleFonts.inter(color: AppColors.error)));
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No reviews yet. Be the first to review!', style: GoogleFonts.inter(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: review.userProfilePic.isNotEmpty ? NetworkImage(review.userProfilePic) : null,
                              child: review.userProfilePic.isEmpty
                                  ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(review.userName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            Text('${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}-${review.createdAt.day.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 14,
                              color: AppColors.warning,
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                        Text(review.comment, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final currentUser = userProvider.userProfile;
                  
                  if (currentUser == null) {
                    _showSnack('Please log in to chat with the seller.');
                    return;
                  }

                  if (product.sellerId == currentUser.id) {
                    _showSnack('You cannot chat with yourself about your own product!');
                    return;
                  }

                  try {
                    // Show a simple loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );

                    // Fetch seller profile to ensure we have up-to-date data
                    final sellerProfile = await UserService().getUserProfile(product.sellerId);
                    
                    if (!context.mounted) return;
                    Navigator.pop(context); // Dismiss loading dialog

                    if (sellerProfile == null) {
                      _showSnack('Failed to load seller profile.');
                      return;
                    }

                    // Create or get chat room
                    final chatRoom = await ChatService().createOrGetChatRoom(
                      productId: product.productId,
                      productTitle: product.title,
                      productPrice: product.price,
                      productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                      buyer: currentUser,
                      seller: sellerProfile,
                    );

                    if (!context.mounted) return;
                    
                    // Navigate to the ChatRoomScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
                      ),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      // Attempt to dismiss loading if it is showing
                      try {
                        Navigator.pop(context);
                      } catch (_) {}
                    }
                    if (mounted) _showSnack('Error initiating chat: $e');
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
              if (product.listingType == 'sell' || product.listingType == 'both')
                ElevatedButton.icon(
                  onPressed: outOfStock ? null : () async {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final currentUser = userProvider.userProfile;
                    
                    if (currentUser == null) {
                      _showSnack('Please log in to add to cart.');
                      return;
                    }
                    if (product.sellerId == currentUser.id) {
                      _showSnack('You cannot add your own product to cart!');
                      return;
                    }
                    
                    final existingItems = context.read<CartProvider>().items.where((item) => item.productId == product.productId);
                    final currentQuantity = existingItems.isNotEmpty ? existingItems.first.quantity : 0;
                    if (currentQuantity + 1 > product.stockQuantity) {
                      _showSnack('Only ${product.stockQuantity} items available in stock.');
                      return;
                    }
                    
                    final cartItem = CartItemModel(
                      id: product.productId,
                      productId: product.productId,
                      sellerId: product.sellerId,
                      productName: product.title,
                      price: product.price,
                      quantity: 1,
                      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    );
                    
                    await context.read<CartProvider>().addItem(cartItem);
                    if (!mounted) return;
                    _showSnack('Added to cart!');
                  },
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                ),
            ],
          ),
          if (product.listingType == 'exchange') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: outOfStock ? null : _showExchangeDialog,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Send Exchange Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (product.isRentable && product.listingType != 'exchange') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: outOfStock ? null : _showRentDialog,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text('Rent Now - ${CurrencyFormatter.format(product.rentPricePerDay)} / day'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(product.category, style: GoogleFonts.inter()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, AppConstants.cartRoute),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: AppColors.background,
      body: safeAreaWrapper(
        child: wide
            ? Row(
                children: [
                  Expanded(child: carousel),
                  const VerticalDivider(width: 1, color: AppColors.gray200),
                  Expanded(child: details),
                ],
              )
            : Column(
                children: [
                  Expanded(flex: 4, child: carousel),
                  const Divider(height: 1, color: AppColors.gray200),
                  Expanded(flex: 5, child: details),
                ],
              ),
      ),
    );
      },
    );
  }

  Widget safeAreaWrapper({required Widget child}) {
    return SafeArea(child: child);
  }
}
