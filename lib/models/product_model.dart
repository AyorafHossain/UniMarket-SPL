import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int stockQuantity;
  
  // Supplementary fields to support the premium campus UI
  final String location;
  final String sellerName;
  final double sellerRating;
  final bool isFeatured;
  final bool isFavorite;
  final double averageRating;
  final int reviewCount;
  
  // Listing & Rent fields
  final String listingType; // 'sell', 'rent', 'both', 'exchange'
  bool get isRentable => listingType == 'rent' || listingType == 'both';
  final double rentPricePerDay;
  final String rentStatus; // 'available', 'rented'
  
  // Exchange fields
  final String wantedItem;
  final String exchangeNotes;
  
  // Admin field
  final String approvalStatus; // 'pending', 'approved', 'rejected'

  ProductModel({
    required this.productId,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.createdAt,
    required this.stockQuantity,
    this.location = 'Campus',
    this.sellerName = 'Seller',
    this.sellerRating = 5.0,
    this.isFeatured = false,
    this.isFavorite = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.listingType = 'sell',
    this.rentPricePerDay = 0.0,
    this.rentStatus = 'available',
    this.wantedItem = '',
    this.exchangeNotes = '',
    this.approvalStatus = 'pending',
  });

  // Convert ProductModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'stockQuantity': stockQuantity,
      'location': location,
      'sellerName': sellerName,
      'sellerRating': sellerRating,
      'isFeatured': isFeatured,
      'isFavorite': isFavorite,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'listingType': listingType,
      'isRentable': isRentable,
      'rentPricePerDay': rentPricePerDay,
      'rentStatus': rentStatus,
      'wantedItem': wantedItem,
      'exchangeNotes': exchangeNotes,
      'approvalStatus': approvalStatus,
    };
  }

  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Create a ProductModel from Firestore Document Data
  factory ProductModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return ProductModel(
        productId: '', sellerId: '', title: 'Unknown', description: '', price: 0.0, category: '', condition: '', imageUrls: [], createdAt: DateTime.now(), stockQuantity: 1,
      );
    }
    
    DateTime date;
    if (map['createdAt'] is Timestamp) {
      date = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      date = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    // Migration for older items that used isRentable instead of listingType
    String? type = map['listingType']?.toString();
    if (type == null) {
      bool rent = map['isRentable'] == true;
      type = rent ? 'rent' : 'sell';
    }

    return ProductModel(
      productId: map['productId']?.toString() ?? '',
      sellerId: map['sellerId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: _parseDouble(map['price']),
      category: map['category']?.toString() ?? '',
      condition: map['condition']?.toString() ?? 'Good',
      imageUrls: map['imageUrls'] is List ? List<String>.from(map['imageUrls']) : [],
      createdAt: date,
      stockQuantity: _parseInt(map['stockQuantity'], 1),
      location: map['location']?.toString() ?? 'Campus',
      sellerName: map['sellerName']?.toString() ?? 'Anonymous',
      sellerRating: _parseDouble(map['sellerRating'], 5.0),
      isFeatured: map['isFeatured'] == true,
      isFavorite: map['isFavorite'] == true,
      averageRating: _parseDouble(map['averageRating']),
      reviewCount: _parseInt(map['reviewCount']),
      listingType: type,
      rentPricePerDay: _parseDouble(map['rentPricePerDay']),
      rentStatus: map['rentStatus']?.toString() ?? 'available',
      wantedItem: map['wantedItem']?.toString() ?? '',
      exchangeNotes: map['exchangeNotes']?.toString() ?? '',
      approvalStatus: map['approvalStatus']?.toString() ?? 'pending',
    );
  }

  // Helper method to copy/clone a product model
  ProductModel copyWith({
    String? productId,
    String? sellerId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? imageUrls,
    DateTime? createdAt,
    int? stockQuantity,
    String? location,
    String? sellerName,
    double? sellerRating,
    bool? isFeatured,
    bool? isFavorite,
    double? averageRating,
    int? reviewCount,
    String? listingType,
    double? rentPricePerDay,
    String? rentStatus,
    String? wantedItem,
    String? exchangeNotes,
    String? approvalStatus,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      location: location ?? this.location,
      sellerName: sellerName ?? this.sellerName,
      sellerRating: sellerRating ?? this.sellerRating,
      isFeatured: isFeatured ?? this.isFeatured,
      isFavorite: isFavorite ?? this.isFavorite,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      listingType: listingType ?? this.listingType,
      rentPricePerDay: rentPricePerDay ?? this.rentPricePerDay,
      rentStatus: rentStatus ?? this.rentStatus,
      wantedItem: wantedItem ?? this.wantedItem,
      exchangeNotes: exchangeNotes ?? this.exchangeNotes,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  // Static list of updated mock products conforming to the new schema
  static List<ProductModel> get mockProducts {
    return [
      ProductModel(
        productId: '1',
        sellerId: 'user_alex',
        title: 'MacBook Pro 13" (M1, 2020)',
        description: 'Perfect condition MacBook Pro with M1 chip, 8GB RAM, and 256GB SSD. Used for CS courses. Includes original charger and box.',
        price: 650.00,
        imageUrls: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Electronics',
        condition: 'Like New',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        stockQuantity: 1,
        location: 'Library Common Area',
        sellerName: 'Alex Rivera',
        sellerRating: 4.9,
        isFeatured: true,
        isFavorite: false,
      ),
      ProductModel(
        productId: '2',
        sellerId: 'user_sarah',
        title: 'Calculus: Early Transcendentals',
        description: 'Stewart Calculus 8th Edition. Minimal highlighting, clean pages. Essential for MATH 151/152.',
        price: 45.00,
        imageUrls: ['https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Textbooks',
        condition: 'Good',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        stockQuantity: 2,
        location: 'Student Union',
        sellerName: 'Sarah Jenkins',
        sellerRating: 4.8,
        isFeatured: true,
        isFavorite: true,
      ),
      ProductModel(
        productId: '3',
        sellerId: 'user_marcus',
        title: 'Giant Escape 3 Road Bike',
        description: 'Perfect campus commuter bike. Medium frame, 21-speed. Shift cables and brake pads replaced last month. Includes lock.',
        price: 180.00,
        imageUrls: ['https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Bikes & Rides',
        condition: 'Good',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        stockQuantity: 1,
        location: 'West Dorm Bike Racks',
        sellerName: 'Marcus Chen',
        sellerRating: 4.7,
        isFeatured: true,
        isFavorite: false,
      ),
      ProductModel(
        productId: '4',
        sellerId: 'user_liam',
        title: 'Sony WH-1000XM4 Headphones',
        description: 'Industry leading noise canceling headphones. Great for studying in noisy dorms. Battery life is still amazing.',
        price: 140.00,
        imageUrls: ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Electronics',
        condition: 'Like New',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        stockQuantity: 1,
        location: 'Engineering Hall',
        sellerName: 'Liam O\'Connor',
        sellerRating: 5.0,
        isFeatured: false,
        isFavorite: false,
      ),
      ProductModel(
        productId: '5',
        sellerId: 'user_emily',
        title: 'Dorm Mini Fridge & Microwave',
        description: 'Black & Decker compact mini fridge with small freezer section and 700W microwave. Clean and in perfect working order.',
        price: 90.00,
        imageUrls: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Dorm & Living',
        condition: 'Fair',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        stockQuantity: 1,
        location: 'North Hall Lobby',
        sellerName: 'Emily Taylor',
        sellerRating: 4.5,
        isFeatured: false,
        isFavorite: false,
      ),
      ProductModel(
        productId: '6',
        sellerId: 'user_jordan',
        title: 'Patagonia Synchilla Fleece',
        description: 'Unisex Medium. Classic gray and blue colorway. Super warm and soft, no tears or stains.',
        price: 55.00,
        imageUrls: ['https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Fashion & Apparel',
        condition: 'Good',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        stockQuantity: 1,
        location: 'Quad / Central Green',
        sellerName: 'Jordan Vance',
        sellerRating: 4.9,
        isFeatured: false,
        isFavorite: false,
      ),
      ProductModel(
        productId: '7',
        sellerId: 'user_chloe',
        title: 'Ergonomic Desk Chair',
        description: 'Adjustable height, lumbar support, and breathable mesh back. Perfect upgrade for long study sessions.',
        price: 40.00,
        imageUrls: ['https://images.unsplash.com/photo-1589384267710-7a259678a59a?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Dorm & Living',
        condition: 'Good',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        stockQuantity: 1,
        location: 'East Campus Apartments',
        sellerName: 'Chloe Bennett',
        sellerRating: 4.6,
        isFeatured: false,
        isFavorite: false,
      ),
      ProductModel(
        productId: '8',
        sellerId: 'user_sarah',
        title: 'iPad Air 4th Gen + Apple Pencil',
        description: '64GB Wi-Fi, Space Gray. Includes Apple Pencil 2nd Gen. The perfect combination for note-taking in lectures.',
        price: 380.00,
        imageUrls: ['https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3'],
        category: 'Electronics',
        condition: 'Like New',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        stockQuantity: 1,
        location: 'Library Common Area',
        sellerName: 'Sarah Jenkins',
        sellerRating: 4.8,
        isFeatured: false,
        isFavorite: false,
      )
    ];
  }
}
