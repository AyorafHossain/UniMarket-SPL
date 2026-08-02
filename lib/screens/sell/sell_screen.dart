import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/nav_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/product_service.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(text: '1');
  final TextEditingController _rentPriceController = TextEditingController();
  final TextEditingController _wantedItemController = TextEditingController();
  final TextEditingController _exchangeNotesController = TextEditingController();

  // Dropdown States
  String? _selectedCategory;
  String? _selectedCondition;
  String _listingType = 'Sell Only';
  
  final List<String> _listingTypes = ['Sell Only', 'Rent Only', 'Sell & Rent', 'Exchange Only'];
  
  // Selected Images
  final List<File> _selectedImages = [];
  String? _imageError;

  // Upload state
  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;

  // Categories list matching HomeScreen
  final List<String> _categories = [
    'Textbooks',
    'Electronics',
    'Dorm & Living',
    'Fashion & Apparel',
    'Bikes & Rides',
  ];

  // Conditions list
  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _rentPriceController.dispose();
    _wantedItemController.dispose();
    _exchangeNotesController.dispose();
    super.dispose();
  }

  // Pick multiple images from device gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
          _imageError = null; // Clear error if images are selected
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  // Remove selected image before posting
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Main post operation
  Future<void> _postProduct() async {
    // 1. Validate Form Fields
    final isFormValid = _formKey.currentState?.validate() ?? false;
    
    // 2. Validate Images (at least one image required)
    if (_selectedImages.isEmpty) {
      setState(() {
        _imageError = 'Please select at least one image of your product';
      });
      return;
    } else {
      setState(() {
        _imageError = null;
      });
    }

    if (!isFormValid) return;

    // Set uploading state
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Initializing upload...';
      _uploadProgress = 0.0;
    });

    try {
      // Get current user information
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      
      final String sellerId = userProvider.userProfile?.id ?? currentUser?.uid ?? 'anonymous';
      final String sellerName = userProvider.userProfile?.name ?? currentUser?.displayName ?? 'Anonymous';

      // Generate a new Firestore unique document ID
      final String productId = FirebaseFirestore.instance.collection('products').doc().id;

      // 3. Upload Images to Firebase Storage
      final List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadStatus = 'Uploading image ${i + 1} of ${_selectedImages.length}...';
          _uploadProgress = i / _selectedImages.length;
        });

        final downloadUrl = await _productService.uploadProductImage(
          _selectedImages[i],
          sellerId,
          i,
        );
        imageUrls.add(downloadUrl);
      }

      setState(() {
        _uploadStatus = 'Saving product details...';
        _uploadProgress = 0.9;
      });

      // 4. Create and Save Product Document to Firestore
      final newProduct = ProductModel(
        productId: productId,
        sellerId: sellerId,
        sellerName: sellerName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: (_listingType == 'Exchange Only') ? 0.0 : (double.tryParse(_priceController.text.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim()) ?? 0.0),
        category: _selectedCategory!,
        condition: _selectedCondition!,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        stockQuantity: int.parse(_stockController.text.trim()),
        location: userProvider.userProfile?.department.isNotEmpty == true 
            ? userProvider.userProfile!.department 
            : 'Campus Common Area',
        sellerRating: 5.0,
        isFeatured: false,
        isFavorite: false,
        listingType: _getListingTypeCode(_listingType),
        rentPricePerDay: (_listingType == 'Rent Only' || _listingType == 'Sell & Rent') 
            ? (double.tryParse(_rentPriceController.text.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim()) ?? 0.0) 
            : 0.0,
        wantedItem: _listingType == 'Exchange Only' ? _wantedItemController.text.trim() : '',
        exchangeNotes: _listingType == 'Exchange Only' ? _exchangeNotesController.text.trim() : '',
        approvalStatus: 'pending',
      );

      await _productService.createProduct(newProduct);

      setState(() {
        _isUploading = false;
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product posted successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 5. Clear Form and Navigate to HomeScreen
        _clearForm();
        
        // Switch index to 0 (Home)
        Provider.of<NavProvider>(context, listen: false).setSelectedIndex(0);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      debugPrint('Error uploading product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Clear Form inputs
  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.text = '1';
    _rentPriceController.clear();
    _wantedItemController.clear();
    _exchangeNotesController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedCondition = null;
      _listingType = 'Sell Only';
      _selectedImages.clear();
      _imageError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Post an Item',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _clearForm,
            tooltip: 'Clear fields',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Input Form
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image upload header
                  Text(
                    'Product Images',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Image Picking Area
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _imageError != null ? AppColors.error : AppColors.gray300,
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photos',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Image Validation Error Message
                  if (_imageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        _imageError!,
                        style: GoogleFonts.inter(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  
                  // Horizontal Picked Images List
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12, top: 8),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Details Header
                  Text(
                    'Item Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title Input
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. MacBook Air M1',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.trim().length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 16),

                  // Condition and Stock row
                  Row(
                    children: [
                      // Condition
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCondition,
                          decoration: InputDecoration(
                            labelText: 'Condition',
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _conditions.map((cond) {
                            return DropdownMenuItem<String>(
                              value: cond,
                              child: Text(cond),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCondition = val;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a condition' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Listing Type Selection
                  DropdownButtonFormField<String>(
                    initialValue: _listingType,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    decoration: InputDecoration(
                      labelText: 'Listing Type',
                      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: _listingTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: GoogleFonts.inter(color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _listingType = newValue!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Conditional Price Section
                  if (_listingType == 'Sell Only' || _listingType == 'Sell & Rent') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Sell Price',
                              hintText: '0.00',
                              prefixText: '৳ ',
                              filled: true,
                              fillColor: AppColors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              String sanitized = value.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim();
                              if (double.tryParse(sanitized) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Stock',
                              filled: true,
                              fillColor: AppColors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (int.tryParse(value) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_listingType == 'Rent Only' || _listingType == 'Sell & Rent') ...[
                    TextFormField(
                      controller: _rentPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Daily Rent Price',
                        hintText: '0.00',
                        prefixText: '৳ ',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a rent price';
                        }
                        String sanitized = value.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim();
                        final price = double.tryParse(sanitized);
                        if (price == null || price <= 0) {
                          return 'Invalid rent price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_listingType == 'Exchange Only') ...[
                    TextFormField(
                      controller: _wantedItemController,
                      decoration: InputDecoration(
                        labelText: 'Wanted Item',
                        hintText: 'What do you want in exchange?',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter what you want';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _exchangeNotesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Exchange Notes (Optional)',
                        hintText: 'Any specific details about the exchange?',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description Input
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the condition, features, usage, etc...',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 15) {
                        return 'Description must be at least 15 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _postProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Post Item',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Progress Loading Overlay
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Uploading product...',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _uploadStatus,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          color: AppColors.primary,
                          backgroundColor: AppColors.gray200,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getListingTypeCode(String uiSelection) {
    if (uiSelection == 'Rent Only') return 'rent';
    if (uiSelection == 'Sell & Rent') return 'both';
    if (uiSelection == 'Exchange Only') return 'exchange';
    return 'sell';
  }
}
