import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../constants/app_colors.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _imageUrlController;
  late TextEditingController _rentPriceController;
  late TextEditingController _wantedItemController;
  late TextEditingController _exchangeNotesController;

  String _category = 'Electronics';
  String _condition = 'Good';
  bool _isLoading = false;
  String _listingType = 'Sell Only';

  final List<String> _listingTypes = ['Sell Only', 'Rent Only', 'Sell & Rent', 'Exchange Only'];

  final List<String> _categories = [
    'Electronics',
    'Textbooks',
    'Dorm & Living',
    'Fashion & Apparel',
    'Bikes & Rides',
    'Other'
  ];

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _quantityController = TextEditingController(text: widget.product.stockQuantity.toString());
    _imageUrlController = TextEditingController(text: widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : '');
    _rentPriceController = TextEditingController(text: widget.product.rentPricePerDay > 0 ? widget.product.rentPricePerDay.toString() : '');
    _wantedItemController = TextEditingController(text: widget.product.wantedItem);
    _exchangeNotesController = TextEditingController(text: widget.product.exchangeNotes);
    
    _category = _categories.contains(widget.product.category) ? widget.product.category : 'Other';
    _condition = _conditions.contains(widget.product.condition) ? widget.product.condition : 'Good';
    
    if (widget.product.listingType == 'rent') {
      _listingType = 'Rent Only';
    } else if (widget.product.listingType == 'both') {
      _listingType = 'Sell & Rent';
    } else if (widget.product.listingType == 'exchange') {
      _listingType = 'Exchange Only';
    } else {
      _listingType = 'Sell Only';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose();
    _rentPriceController.dispose();
    _wantedItemController.dispose();
    _exchangeNotesController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProduct = widget.product.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: (_listingType == 'Exchange Only') ? 0.0 : (double.tryParse(_priceController.text.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim()) ?? 0.0),
        category: _category,
        condition: _condition,
        stockQuantity: int.tryParse(_quantityController.text) ?? 1,
        imageUrls: [_imageUrlController.text.trim()], // For simplicity, just one image URL here
        listingType: _getListingTypeCode(_listingType),
        rentPricePerDay: (_listingType == 'Rent Only' || _listingType == 'Sell & Rent') 
            ? (double.tryParse(_rentPriceController.text.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim()) ?? 0.0) 
            : 0.0,
        wantedItem: _listingType == 'Exchange Only' ? _wantedItemController.text.trim() : '',
        exchangeNotes: _listingType == 'Exchange Only' ? _exchangeNotesController.text.trim() : '',
      );

      await _productService.updateProduct(updatedProduct);

      // Check for price drop and notify wishlist users
      if (updatedProduct.price < widget.product.price) {
        await _productService.notifyWishlistUsersForPriceDrop(
          updatedProduct,
          widget.product.price,
          updatedProduct.price,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Product', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Product Title',
                      validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 4,
                      validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown('Listing Type', _listingTypes, _listingType, (val) => setState(() => _listingType = val!)),
                    const SizedBox(height: 16),
                    if (_listingType == 'Sell Only' || _listingType == 'Sell & Rent') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Sell Price (BDT)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixText: '৳ ',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Invalid price';
                                String sanitized = v.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim();
                                return double.tryParse(sanitized) == null ? 'Invalid price' : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityController,
                              label: 'Quantity/Stock',
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid quantity' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_listingType == 'Rent Only' || _listingType == 'Sell & Rent') ...[
                      _buildTextField(
                        controller: _rentPriceController,
                        label: 'Daily Rent Price (BDT)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixText: '৳ ',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Invalid rent price';
                          String sanitized = v.replaceAll('৳', '').replaceAll(',', '').replaceAll(' ', '').trim();
                          return double.tryParse(sanitized) == null ? 'Invalid rent price' : null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_listingType == 'Rent Only') ...[
                      _buildTextField(
                        controller: _quantityController,
                        label: 'Quantity/Stock',
                        keyboardType: TextInputType.number,
                        validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid quantity' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_listingType == 'Exchange Only') ...[
                      _buildTextField(
                        controller: _wantedItemController,
                        label: 'Wanted Item',
                        validator: (v) => v == null || v.isEmpty ? 'Please enter what you want' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _exchangeNotesController,
                        label: 'Exchange Notes (Optional)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _quantityController,
                        label: 'Quantity/Stock',
                        keyboardType: TextInputType.number,
                        validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid quantity' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDropdown('Category', _categories, _category, (val) => setState(() => _category = val!)),
                    const SizedBox(height: 16),
                    _buildDropdown('Condition', _conditions, _condition, (val) => setState(() => _condition = val!)),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _imageUrlController,
                      label: 'Image URL',
                      validator: (v) => v == null || v.isEmpty ? 'Image URL is required' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Save Changes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter()))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        filled: true,
        fillColor: Colors.white,
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
