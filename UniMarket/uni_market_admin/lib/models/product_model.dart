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

  // Admin fields
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final String? approvedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

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
    this.approvedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

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
      'approvedBy': approvedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
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
      approvedBy: map['approvedBy']?.toString(),
      reviewedAt: map['reviewedAt'] != null 
          ? (map['reviewedAt'] is Timestamp 
              ? (map['reviewedAt'] as Timestamp).toDate() 
              : DateTime.tryParse(map['reviewedAt'].toString()))
          : null,
      rejectionReason: map['rejectionReason']?.toString(),
    );
  }

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
    String? approvedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
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
      approvedBy: approvedBy ?? this.approvedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
