
class CartItemModel {
  final String id;
  final String productId;
  final String sellerId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sellerId': sellerId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CartItemModel(
      id: documentId,
      productId: map['productId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity']?.toInt() ?? 1,
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
